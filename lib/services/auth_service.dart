import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_user.dart';

class AuthService extends ChangeNotifier {
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    clientId: kIsWeb
        ? '728773599076-u14ibdhvt7nii1b22rqen7p288q4blnh.apps.googleusercontent.com'
        : null,
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
        // Use existing guest
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

  // Benzersiz guest ID oluştur
  String _generateUniqueGuestId() {
    const String prefix = 'RKN';
    final random = Random();

    // 10 haneli random sayı oluştur
    String generateNumbers() {
      return List.generate(10, (_) => random.nextInt(10)).join();
    }

    final numbers = generateNumbers();
    return '$prefix$numbers';
  }

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

  Future<AppUser?> signInWithGoogle() async {
    try {
      debugPrint('Google Sign-In başlıyor...');

      if (kIsWeb) {
        // Web için
        final googleProvider = firebase_auth.GoogleAuthProvider();
        googleProvider.addScope('email');
        googleProvider.addScope('profile');

        final userCredential = await _auth.signInWithPopup(googleProvider);

        if (userCredential.user != null) {
          return await _handleGoogleSignInSuccess(userCredential.user!);
        }
      } else {
        // Android/iOS için
        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

        if (googleUser == null) {
          debugPrint('Kullanıcı Google hesabı seçmedi');
          return null;
        }

        debugPrint('Google kullanıcısı alındı: ${googleUser.email}');

        final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

        debugPrint('Google auth token alındı');

        final credential = firebase_auth.GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        debugPrint('Firebase credential oluşturuldu');

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
      rethrow;
    }
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
    _currentUser = appUser;

    // Clear guest flag
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isGuestKey, false);

    notifyListeners();
    return appUser;
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

        final appUser = AppUser(
          uid: userCredential.user!.uid,
          email: email,
          displayName: email.split('@').first,
          selectedLanguage: await getSavedLanguage(),
          isGuest: false,
          guestId: userCredential.user!.uid,
          createdAt: DateTime.now(),
        );

        await _saveOrUpdateUserInFirestore(appUser);
        _currentUser = appUser;

        // Guest flag'ini temizle
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_isGuestKey, false);

        notifyListeners();
        return appUser;
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
        if (appUserFromFirestore != null) {
          appUser = appUserFromFirestore;
        } else {
          appUser = AppUser(
            uid: userCredential.user!.uid,
            email: email,
            displayName: userCredential.user!.displayName ?? email.split('@').first,
            selectedLanguage: await getSavedLanguage(),
            isGuest: false,
            guestId: userCredential.user!.uid,
            createdAt: DateTime.now(),
          );
        }

        await _saveOrUpdateUserInFirestore(appUser);
        _currentUser = appUser;

        // Guest flag'ini temizle
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_isGuestKey, false);

        notifyListeners();
        return appUser;
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
      final userData = user.toMap();
      await _firestore.collection('users').doc(user.uid).set(userData);
      await saveUserId(user.uid);
    } catch (e) {
      debugPrint("Save user to Firestore error: $e");
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      await _googleSignIn.signOut();
      _currentUser = null;

      // Keep guest status if it was a guest
      final prefs = await SharedPreferences.getInstance();
      final isGuest = prefs.getBool(_isGuestKey) ?? false;

      if (!isGuest) {
        await prefs.remove(_userIdKey);
      }

      notifyListeners();
    } catch (e) {
      debugPrint("Sign out error: $e");
    }
  }

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
  Future<void> updateProfile({String? displayName}) async {
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

      await _firestore.collection('users').doc(_currentUser!.uid).set(
        updateData,
        SetOptions(merge: true),
      );

      // Update current user
      _currentUser = _currentUser!.copyWith(displayName: displayName);
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

      // Create new AppUser
      final newUser = AppUser(
        uid: userCredential.user!.uid,
        email: email,
        displayName: displayName ?? email.split('@').first,
        selectedLanguage: savedLanguage,
        isGuest: false,
        guestId: oldGuestId,
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