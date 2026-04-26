import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_user.dart';

/// Firebase Android uygulamasında imza (SHA-1) kayıtlı değilse Google Sign-In ApiException: 10 verir.
class GoogleSignInShaNotRegisteredException implements Exception {
  const GoogleSignInShaNotRegisteredException();
}

class AuthService extends ChangeNotifier {
  /// Firebase’de “Web client” OAuth kimliği (google-services.json → client_type: 3).
  /// Android’de `serverClientId` verilmezse sık sık `ApiException: 10` ve boş idToken olur.
  static const String _googleOAuthWebClientId =
      '728773599076-u14ibdhvt7nii1b22rqen7p288q4blnh.apps.googleusercontent.com';

  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;
  
  // Web için oturum kalıcılığı - uygulama kapatılsa bile oturum açık kalsın
  static Future<void> initializePersistence() async {
    if (kIsWeb) {
      try {
        await firebase_auth.FirebaseAuth.instance
            .setPersistence(firebase_auth.Persistence.LOCAL);
        debugPrint('Firebase Auth persistence: LOCAL (kalıcı)');
      } catch (e) {
        debugPrint('Firebase Auth persistence ayarlanamadı: $e');
      }
    }
  }
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    clientId: kIsWeb ? _googleOAuthWebClientId : null,
    // Mobil: Web client ID → Google, Firebase Auth için idToken üretir
    serverClientId: kIsWeb ? null : _googleOAuthWebClientId,
  );

  // Local storage keys
  static const String _languageKey = 'user_language';
  static const String _userIdKey = 'current_user_id';
  static const String _guestIdKey = 'guest_user_id';
  static const String _isGuestKey = 'is_guest_user';

  // Current user
  AppUser? _currentUser;

  // Stream kontrolü
  Stream<AppUser?>? _userStream;

  // Getter
  AppUser? get currentUser => _currentUser;

  // User stream getter
  Stream<AppUser?> get userStream {
    if (_userStream == null) {
      _userStream = _createUserStream();
    }
    return _userStream!;
  }

  /// Profilde "Hesap Oluştur" tıklandığında true yapılır; WelcomeScreen giriş sayfasına (index 1) başlar
  bool showLoginOptionsOnWelcome = false;

  void setShowLoginOptionsOnWelcome(bool value) {
    if (showLoginOptionsOnWelcome != value) {
      showLoginOptionsOnWelcome = value;
      notifyListeners();
    }
  }

  // Constructor
  AuthService() {
    _initializeGuestUser();
  }

  // Initialize guest user
  Future<void> _initializeGuestUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isGuest = prefs.getBool(_isGuestKey) ?? false;

      if (isGuest) {
        final guestId = prefs.getString(_guestIdKey);
        final language = prefs.getString(_languageKey) ?? 'tr';

        if (guestId != null) {
          _currentUser = AppUser(
            uid: guestId,
            selectedLanguage: language,
            isGuest: true,
            guestId: guestId,
            createdAt: DateTime.now(),
          );
          notifyListeners();
        }
      } else {
        // Firebase user kontrolü
        final firebaseUser = _auth.currentUser;
        if (firebaseUser != null) {
          await _handleFirebaseUser(firebaseUser);
        }
      }
    } catch (e) {
      debugPrint("Initialize guest user error: $e");
    }
  }

  // Handle Firebase user
  Future<void> _handleFirebaseUser(firebase_auth.User firebaseUser) async {
    try {
      final appUserFromFirestore = await getUserFromFirestore(firebaseUser.uid);

      if (appUserFromFirestore != null) {
        _currentUser = appUserFromFirestore;
        if (!AppUser.isValidAssignedUserCode(_currentUser!.userCode)) {
          await _saveOrUpdateUserInFirestore(_currentUser!);
        }
      } else {
        // Create new user
        _currentUser = AppUser.fromFirebaseUser(firebaseUser);
        await _saveOrUpdateUserInFirestore(_currentUser!);
      }

      // Clear guest flag
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_isGuestKey, false);

      notifyListeners();
    } catch (e) {
      debugPrint("Handle Firebase user error: $e");
    }
  }

  // Create user stream
  Stream<AppUser?> _createUserStream() {
    return _auth.authStateChanges().asyncMap((firebaseUser) async {
      if (firebaseUser == null) {
        // Check for guest user
        final prefs = await SharedPreferences.getInstance();
        final isGuest = prefs.getBool(_isGuestKey) ?? false;

        if (isGuest) {
          final guestId = prefs.getString(_guestIdKey);
          final language = prefs.getString(_languageKey) ?? 'tr';

          if (guestId != null) {
            _currentUser = AppUser(
              uid: guestId,
              selectedLanguage: language,
              isGuest: true,
              guestId: guestId,
              createdAt: DateTime.now(),
            );
            return _currentUser;
          }
        }
        _currentUser = null;
        return null;
      }

      // Firebase user exists
      return await _handleFirebaseUserForStream(firebaseUser);
    });
  }

  // Handle Firebase user for stream
  Future<AppUser?> _handleFirebaseUserForStream(firebase_auth.User firebaseUser) async {
    try {
      final appUserFromFirestore = await getUserFromFirestore(firebaseUser.uid);

      if (appUserFromFirestore != null) {
        _currentUser = appUserFromFirestore;
        if (!AppUser.isValidAssignedUserCode(_currentUser!.userCode)) {
          await _saveOrUpdateUserInFirestore(_currentUser!);
        }
      } else {
        _currentUser = AppUser.fromFirebaseUser(firebaseUser);
        await _saveOrUpdateUserInFirestore(_currentUser!);
      }

      // Clear guest flag
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_isGuestKey, false);

      return _currentUser;
    } catch (e) {
      debugPrint("Handle Firebase user for stream error: $e");
      return null;
    }
  }

  // ------------- MISAFİR KULLANICI İŞLEMLERİ -------------

  // Misafir olarak giriş yap
  Future<AppUser?> signInAsGuest() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Check if guest already exists
      final existingGuestId = prefs.getString(_guestIdKey);

      if (existingGuestId != null) {
        final language = prefs.getString(_languageKey) ?? 'tr';
        final appUser = AppUser(
          uid: existingGuestId,
          selectedLanguage: language,
          isGuest: true,
          guestId: existingGuestId,
          createdAt: DateTime.now(),
        );

        _currentUser = appUser;
        await prefs.setBool(_isGuestKey, true);
        notifyListeners();

        return appUser;
      } else {
        // Create new guest
        final guestId = _generateUniqueGuestId();
        final language = prefs.getString(_languageKey) ?? 'tr';

        final appUser = AppUser(
          uid: guestId,
          selectedLanguage: language,
          isGuest: true,
          guestId: guestId,
          createdAt: DateTime.now(),
        );

        _currentUser = appUser;

        // Save to preferences
        await prefs.setString(_guestIdKey, guestId);
        await prefs.setBool(_isGuestKey, true);
        await prefs.setString(_languageKey, language);

        // Create in Firestore for statistics
        await _createGuestInFirestore(appUser);

        notifyListeners();
        return appUser;
      }
    } catch (e) {
      debugPrint("Guest sign-in error: $e");
      return null;
    }
  }

  // Benzersiz misafir ID (kayıtlı oyuncu kodu ile aynı biçim: MTN + 10 rakam)
  String _generateUniqueGuestId() => AppUser.generatePlayerUserCode();

  // Misafir kullanıcıyı Firestore'a kaydet
  Future<void> _createGuestInFirestore(AppUser guestUser) async {
    try {
      final guestData = {
        'uid': guestUser.uid,
        'guestId': guestUser.guestId,
        'selectedLanguage': guestUser.selectedLanguage,
        'isGuest': true,
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
        'deviceInfo': {
          'platform': defaultTargetPlatform.toString(),
          'isWeb': kIsWeb,
        }
      };

      await _firestore.collection('guests').doc(guestUser.uid).set(guestData);
    } catch (e) {
      debugPrint("Create guest in Firestore error: $e");
    }
  }

  // ------------- GOOGLE İLE GİRİŞ -------------

// AuthService.dart içindeki signInWithGoogle metodunu güncelle

  Future<AppUser?> signInWithGoogle() async {
    try {
      debugPrint('Google Sign-In başlıyor...');

      if (kIsWeb) {
        // Web için - önce mevcut oturumu temizle
        try {
          await _auth.signOut();
        } catch (e) {
          debugPrint('Önceki oturum temizleme: $e');
        }

        // Web için - popup ile hesap seçimi
        final googleProvider = firebase_auth.GoogleAuthProvider();
        googleProvider.addScope('email');
        googleProvider.addScope('profile');

        // Her zaman hesap seçme ekranını göster ve şifre isteme
        googleProvider.setCustomParameters({
          'prompt': 'select_account',  // Hesap seçim ekranını göster
          'access_type': 'offline',     // Refresh token al
          'include_granted_scopes': 'true',
        });

        final userCredential = await _auth.signInWithPopup(googleProvider);

        if (userCredential.user != null) {
          return await _handleGoogleSignInSuccess(userCredential.user!);
        }
      } else {
        // Android/iOS için - her zaman hesap seçme ekranını göster
        await _googleSignIn.signOut(); // Önce çıkış yap (eski hesabı unut)
        
        // Ayrıca Firebase Auth'dan da çıkış yap
        try {
          await _auth.signOut();
        } catch (e) {
          debugPrint('Firebase signOut: $e');
        }

        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

        if (googleUser == null) {
          debugPrint('Kullanıcı Google hesabı seçmedi');
          return null;
        }

        debugPrint('Google kullanıcısı alındı: ${googleUser.email}');

        final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

        final credential = firebase_auth.GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        final userCredential = await _auth.signInWithCredential(credential);

        debugPrint('Firebase sign-in başarılı: ${userCredential.user?.email}');

        if (userCredential.user != null) {
          return await _handleGoogleSignInSuccess(userCredential.user!);
        }
      }

      return null;
    } catch (e) {
      debugPrint('Google Sign-In hatası: $e');
      debugPrint('Hata detayı: ${e.toString()}');
      if (_isGoogleSignInDeveloperConfigError(e)) {
        throw const GoogleSignInShaNotRegisteredException();
      }
      rethrow;
    }
  }

  /// ApiException: 10 = DEVELOPER_ERROR; çoğunlukla Firebase’de eksik/yanlış SHA-1.
  static bool _isGoogleSignInDeveloperConfigError(Object e) {
    if (e is! PlatformException) return false;
    final msg = e.message ?? '';
    if (e.code != 'sign_in_failed') return false;
    return msg.contains('ApiException: 10') || msg.contains('DEVELOPER_ERROR');
  }

  // Google girişi başarılı olduğunda
  Future<AppUser> _handleGoogleSignInSuccess(firebase_auth.User firebaseUser) async {
    final appUserFromFirestore = await getUserFromFirestore(firebaseUser.uid);

    AppUser appUser;
    if (appUserFromFirestore != null) {
      appUser = appUserFromFirestore;
    } else {
      appUser = AppUser.fromFirebaseUser(firebaseUser);
    }

    await _saveOrUpdateUserInFirestore(appUser);
    if (_currentUser?.uid != appUser.uid) {
      _currentUser = appUser;
    }

    // Clear guest flag
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isGuestKey, false);

    notifyListeners();
    return _currentUser ?? appUser;
  }

  // ------------- EMAIL/PASSWORD İLE GİRİŞ -------------

  Future<AppUser?> signUpWithEmail(String email, String password) async {
    try {
      debugPrint('Email signup başlıyor: $email');

      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        debugPrint('Email signup başarılı: ${userCredential.user!.email}');

        final fu = userCredential.user!;
        var appUser = AppUser.fromFirebaseUser(fu).copyWith(
          displayName: fu.displayName ?? email.split('@').first,
          selectedLanguage: await getSavedLanguage(),
        );

        await _saveOrUpdateUserInFirestore(appUser);

        // Guest flag'ini temizle
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_isGuestKey, false);

        notifyListeners();
        return _currentUser ?? appUser;
      }
      return null;
    } catch (e) {
      debugPrint("Email signup error: $e");
      rethrow;
    }
  }

  Future<AppUser?> signInWithEmail(String email, String password) async {
    try {
      debugPrint('Email login başlıyor: $email');

      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        debugPrint('Email login başarılı: ${userCredential.user!.email}');

        final appUserFromFirestore = await getUserFromFirestore(userCredential.user!.uid);

        AppUser appUser;
        final fu = userCredential.user!;
        if (appUserFromFirestore != null) {
          appUser = appUserFromFirestore;
        } else {
          appUser = AppUser.fromFirebaseUser(fu).copyWith(
            displayName: fu.displayName ?? email.split('@').first,
            selectedLanguage: await getSavedLanguage(),
          );
        }

        await _saveOrUpdateUserInFirestore(appUser);

        // Guest flag'ini temizle
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_isGuestKey, false);

        notifyListeners();
        return _currentUser ?? appUser;
      }
      return null;
    } catch (e) {
      debugPrint("Email login error: $e");
      rethrow;
    }
  }

  // ------------- DİĞER METOTLAR -------------

  // Get current user
  Future<AppUser?> getCurrentUser() async {
    if (_currentUser != null) {
      return _currentUser;
    }

    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) {
      // Check for guest
      final prefs = await SharedPreferences.getInstance();
      final isGuest = prefs.getBool(_isGuestKey) ?? false;

      if (isGuest) {
        final guestId = prefs.getString(_guestIdKey);
        final language = prefs.getString(_languageKey) ?? 'tr';

        if (guestId != null) {
          _currentUser = AppUser(
            uid: guestId,
            selectedLanguage: language,
            isGuest: true,
            guestId: guestId,
            createdAt: DateTime.now(),
          );
          return _currentUser;
        }
      }
      return null;
    }

    final appUserFromFirestore = await getUserFromFirestore(firebaseUser.uid);
    if (appUserFromFirestore != null) {
      _currentUser = appUserFromFirestore;
      return _currentUser;
    }

    _currentUser = AppUser.fromFirebaseUser(firebaseUser);
    return _currentUser;
  }

  /// Firestore’da başka kullanıcıda olmayan MTN + 10 rakam kodu üretir (ilk rakam 1–9).
  Future<String> _allocateUniquePlayerCode(String forUid) async {
    for (var attempt = 0; attempt < 32; attempt++) {
      var candidate = AppUser.generatePlayerUserCode();
      if (!AppUser.isValidAssignedUserCode(candidate)) continue;
      try {
        final snap = await _firestore
            .collection('users')
            .where('userCode', isEqualTo: candidate)
            .limit(1)
            .get();
        if (snap.docs.isEmpty) return candidate;
        if (snap.docs.length == 1 && snap.docs.first.id == forUid) {
          return candidate;
        }
      } catch (e) {
        debugPrint('allocateUniquePlayerCode query error: $e');
        break;
      }
    }
    return AppUser.generatePlayerUserCode();
  }

  // Get user from Firestore
  Future<AppUser?> getUserFromFirestore(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists && doc.data() != null) {
        return AppUser.fromMap(doc.data()!);
      }
    } catch (e) {
      debugPrint("Get user from Firestore error: $e");
    }
    return null;
  }

  // Save or update user in Firestore
  Future<void> _saveOrUpdateUserInFirestore(AppUser user) async {
    try {
      AppUser toSave = user;
      if (!toSave.isGuest && toSave.uid.isNotEmpty) {
        if (!AppUser.isValidAssignedUserCode(toSave.userCode)) {
          final code = await _allocateUniquePlayerCode(toSave.uid);
          toSave = toSave.copyWith(userCode: code);
        }
      }
      final userData = toSave.toMap();
      await _firestore.collection('users').doc(toSave.uid).set(userData);
      await saveUserId(toSave.uid);
      if (!toSave.isGuest &&
          toSave.uid.isNotEmpty &&
          _auth.currentUser?.uid == toSave.uid) {
        _currentUser = toSave;
      }
    } catch (e) {
      debugPrint("Save user to Firestore error: $e");
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isGuest = prefs.getBool(_isGuestKey) ?? false;

      await _auth.signOut();
      await _googleSignIn.signOut();
      _currentUser = null;

      if (isGuest) {
        // Misafir çıkışında tüm misafir verilerini temizle
        await _clearGuestData(prefs);
        await prefs.remove(_guestIdKey);
        await prefs.setBool(_isGuestKey, false);
      } else {
        await prefs.remove(_userIdKey);
      }

      notifyListeners();
    } catch (e) {
      debugPrint("Sign out error: $e");
    }
  }

  /// Misafir kullanıcı verilerini temizle (çıkış veya uygulama yeniden başlatıldığında)
  Future<void> _clearGuestData(SharedPreferences prefs) async {
    try {
      await prefs.remove(_guestMechanicsKey);
    } catch (e) {
      debugPrint("Clear guest data error: $e");
    }
  }

  static const String _guestMechanicsKey = 'guest_mechanics';

  // Save user ID locally
  Future<void> saveUserId(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userIdKey, userId);
    } catch (e) {
      debugPrint("Save user ID error: $e");
    }
  }

  // Get saved language
  Future<String> getSavedLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_languageKey) ?? 'tr';
    } catch (e) {
      debugPrint("Get saved language error: $e");
      return 'tr';
    }
  }

  // Save language locally
  Future<void> saveLanguageLocally(String languageCode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_languageKey, languageCode);
    } catch (e) {
      debugPrint("Save language error: $e");
    }
  }

  // Get user language
  Future<String> getUserLanguage(String? userId) async {
    if (userId == null || _currentUser?.isGuest == true) {
      return await getSavedLanguage();
    }

    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        final lang = doc.data()?['selectedLanguage'] as String?;
        if (lang != null) {
          await saveLanguageLocally(lang);
          return lang;
        }
      }
    } catch (e) {
      debugPrint("Get user language error: $e");
    }

    return await getSavedLanguage();
  }

  // Update user language
  Future<void> updateUserLanguage(String languageCode) async {
    if (_currentUser != null) {
      if (!_currentUser!.isGuest) {
        // Save to Firestore for registered users
        try {
          await _firestore.collection('users').doc(_currentUser!.uid).set(
            {
              'selectedLanguage': languageCode,
              'updatedAt': Timestamp.now(),
            },
            SetOptions(merge: true),
          );
        } catch (e) {
          debugPrint("Update language in Firestore error: $e");
        }
      }

      // Update current user
      _currentUser = _currentUser!.copyWith(selectedLanguage: languageCode);
    }

    // Always save locally
    await saveLanguageLocally(languageCode);
    notifyListeners();
  }

  // Supported languages
  List<Map<String, dynamic>> get supportedLanguages => [
    {'code': 'tr', 'name': 'Türkçe', 'flag': '🇹🇷'},
    {'code': 'en', 'name': 'English', 'flag': '🇺🇸'},
    {'code': 'de', 'name': 'Deutsch', 'flag': '🇩🇪'},
  ];

  // ------------- DİĞER YARDIMCI METOTLAR -------------

  // Check if user is authenticated
  bool get isAuthenticated => _currentUser != null;

  // Check if user is guest
  bool get isGuest => _currentUser?.isGuest == true;

  // Check if user is premium
  bool get isPremium {
    if (_currentUser == null) return false;
    if (!_currentUser!.isPremium) return false;
    if (_currentUser!.premiumExpiresAt != null) {
      return _currentUser!.premiumExpiresAt!.isAfter(DateTime.now());
    }
    return true;
  }

  // Update premium status (called from PremiumService)
  Future<void> updatePremiumStatus(bool isPremium, DateTime? expiresAt) async {
    if (_currentUser == null) return;

    try {
      // Update in Firestore
      await _firestore.collection('users').doc(_currentUser!.uid).set({
        'isPremium': isPremium,
        'premiumExpiresAt': expiresAt?.toIso8601String(),
        'premiumUpdatedAt': DateTime.now().toIso8601String(),
      }, SetOptions(merge: true));

      // Update current user
      _currentUser = _currentUser!.copyWith(
        isPremium: isPremium,
        premiumExpiresAt: expiresAt,
      );
      notifyListeners();
    } catch (e) {
      debugPrint("Update premium status error: $e");
    }
  }

  // Get user display name
  String get displayName {
    if (_currentUser == null) return 'Misafir';
    if (_currentUser!.displayName != null && _currentUser!.displayName!.isNotEmpty) {
      return _currentUser!.displayName!;
    }
    if (_currentUser!.email != null) {
      return _currentUser!.email!.split('@').first;
    }
    return _currentUser!.guestId ?? 'Misafir';
  }

  // Get user email
  String? get email => _currentUser?.email;

  // Get user ID
  String? get userId => _currentUser?.uid;

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      debugPrint("Reset password error: $e");
      rethrow;
    }
  }

  // Update user profile
  Future<void> updateProfile({String? displayName, String? profileEmoji}) async {
    if (_currentUser == null || _currentUser!.isGuest) return;

    try {
      // Update in Firebase Auth
      if (displayName != null && displayName.isNotEmpty) {
        await _auth.currentUser!.updateDisplayName(displayName);
      }

      // Update in Firestore
      final updateData = <String, dynamic>{
        'updatedAt': Timestamp.now(),
      };

      if (displayName != null && displayName.isNotEmpty) {
        updateData['displayName'] = displayName;
      }
      if (profileEmoji != null && profileEmoji.isNotEmpty) {
        updateData['profileEmoji'] = profileEmoji;
      }

      await _firestore.collection('users').doc(_currentUser!.uid).set(
        updateData,
        SetOptions(merge: true),
      );

      // Update current user
      _currentUser = _currentUser!.copyWith(
        displayName: displayName,
        profileEmoji: profileEmoji,
      );
      notifyListeners();
    } catch (e) {
      debugPrint("Update profile error: $e");
      rethrow;
    }
  }

  // Delete account
  Future<void> deleteAccount() async {
    if (_currentUser == null || _currentUser!.isGuest) return;

    try {
      // Delete from Firestore
      await _firestore.collection('users').doc(_currentUser!.uid).delete();

      // Delete from Firebase Auth
      await _auth.currentUser!.delete();

      // Clear local data
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userIdKey);
      await prefs.remove(_guestIdKey);
      await prefs.setBool(_isGuestKey, false);

      _currentUser = null;
      notifyListeners();
    } catch (e) {
      debugPrint("Delete account error: $e");
      rethrow;
    }
  }

  // Convert guest to registered user
  Future<AppUser?> convertGuestToUser({
    required String email,
    required String password,
    String? displayName,
  }) async {
    if (_currentUser == null || !_currentUser!.isGuest) {
      throw Exception('No guest user to convert');
    }

    try {
      final oldGuestId = _currentUser!.guestId;
      final savedLanguage = _currentUser!.selectedLanguage ?? await getSavedLanguage();

      // Create new Firebase user with email/password
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user == null) {
        throw Exception('Failed to create user');
      }

      // Update display name if provided
      if (displayName != null && displayName.isNotEmpty) {
        await userCredential.user!.updateDisplayName(displayName);
      }

      // Misafir MTN kodunu kayıtlı hesapta koru
      final preservedCode = AppUser.playerCodeDerivedFromGuestId(oldGuestId) ??
          AppUser.resolveUserCodeForRegistered(existing: null);

      final newUser = AppUser(
        uid: userCredential.user!.uid,
        email: email,
        displayName: displayName ?? email.split('@').first,
        selectedLanguage: savedLanguage,
        isGuest: false,
        guestId: null,
        userCode: preservedCode,
        createdAt: DateTime.now(),
      );

      // Save to Firestore
      await _saveOrUpdateUserInFirestore(newUser);

      // Transfer guest data if exists
      if (oldGuestId != null) {
        try {
          final guestDoc = await _firestore.collection('guests').doc(oldGuestId).get();
          if (guestDoc.exists) {
            // You can transfer any guest data here if needed
            await _firestore.collection('guests').doc(oldGuestId).delete();
          }
        } catch (e) {
          debugPrint("Transfer guest data error: $e");
        }
      }

      // Clear guest flags
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_isGuestKey, false);
      await prefs.remove(_guestIdKey);
      await prefs.setString(_userIdKey, newUser.uid);

      _currentUser = newUser;
      notifyListeners();

      return newUser;
    } catch (e) {
      debugPrint("Convert guest to user error: $e");
      rethrow;
    }
  }
}