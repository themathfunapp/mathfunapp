import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mathfun/localization/app_supported_locales.dart';
import 'package:mathfun/services/auth_service.dart';

class LocaleProvider extends ChangeNotifier {
  Locale _locale = resolveAppLocale('en');
  bool _isLoading = true;
  final Completer<void> _initialLoadDone = Completer<void>();
  String? _lastSyncedAuthSignature;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>?
      _userLanguageSubscription;
  StreamSubscription<firebase_auth.User?>? _firebaseAuthSubscription;
  String? _listeningUserId;
  Timer? _languagePollTimer;

  Locale get locale => _locale;
  bool get isLoading => _isLoading;

  LocaleProvider() {
    _loadSavedLocale();
    _bindFirebaseAuthLanguageSync();
  }

  Future<void> _loadSavedLocale() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? savedLanguage = prefs.getString('user_language');

      if (savedLanguage != null && kSupportedLanguageCodes.contains(savedLanguage)) {
        _locale = resolveAppLocale(savedLanguage);
      } else {
        // İlk açılış: varsayılan İngilizce (dil seçiciden değiştirilebilir)
        _locale = resolveAppLocale('en');
        await prefs.setString('user_language', 'en');
      }
    } catch (e) {
      _locale = resolveAppLocale('en');
    }
    _isLoading = false;
    if (!_initialLoadDone.isCompleted) {
      _initialLoadDone.complete();
    }
    notifyListeners();
  }

  void _bindFirebaseAuthLanguageSync() {
    _firebaseAuthSubscription =
        firebase_auth.FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user == null) {
        _stopUserLanguageListener();
        _stopLanguagePolling();
        return;
      }
      _ensureUserLanguageListener(user.uid, false);
      // ignore: discarded_futures
      _syncLanguageFromUserDoc(user.uid);
    });
  }

  Future<void> _syncLanguageFromUserDoc(String userId) async {
    if (_isLoading) {
      await _initialLoadDone.future;
    }
    if (userId.isEmpty) return;
    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .get(const GetOptions(source: Source.server));
      final code = doc.data()?['selectedLanguage'] as String?;
      if (code == null || code.isEmpty) return;
      if (!kSupportedLanguageCodes.contains(code)) return;
      if (_locale.languageCode == code) return;

      _locale = resolveAppLocale(code);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_language', code);
      notifyListeners();
    } catch (e) {
      debugPrint('Kullanici dil dokumani senkron hatasi: $e');
    }
  }

  /// AuthService üzerinden hesap dilini bu cihaza uygular.
  /// Böylece web/mobil arasında aynı hesapta son seçilen dil senkron kalır.
  Future<void> syncWithAuth(AuthService authService) async {
    if (_isLoading) {
      await _initialLoadDone.future;
    }

    final user = authService.currentUser;
    if (user == null) {
      _lastSyncedAuthSignature = null;
      _stopUserLanguageListener();
      _stopLanguagePolling();
      return;
    }

    _ensureUserLanguageListener(user.uid, user.isGuest);
    _ensureLanguagePolling(authService, user.uid, user.isGuest);
    if (!user.isGuest) {
      // ignore: discarded_futures
      _syncLanguageFromUserDoc(user.uid);
    }

    final signature = '${user.uid}:${user.selectedLanguage ?? ''}:${user.isGuest}';
    if (_lastSyncedAuthSignature == signature) return;
    _lastSyncedAuthSignature = signature;

    String? incomingCode = user.selectedLanguage;
    if ((incomingCode == null || incomingCode.isEmpty) && !user.isGuest) {
      incomingCode = await authService.getUserLanguage(user.uid);
    }
    if (incomingCode == null || incomingCode.isEmpty) return;
    if (!kSupportedLanguageCodes.contains(incomingCode)) return;
    if (_locale.languageCode == incomingCode) return;

    _locale = resolveAppLocale(incomingCode);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_language', incomingCode);
    } catch (e) {
      debugPrint('Dil senkron kaydı hatası: $e');
    }
    notifyListeners();
  }

  void _ensureUserLanguageListener(String userId, bool isGuest) {
    if (isGuest || userId.isEmpty) {
      _stopUserLanguageListener();
      return;
    }
    if (_listeningUserId == userId && _userLanguageSubscription != null) return;

    _stopUserLanguageListener();
    _listeningUserId = userId;
    _userLanguageSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .snapshots()
        .listen((snapshot) async {
      final code = snapshot.data()?['selectedLanguage'] as String?;
      if (code == null || code.isEmpty) return;
      if (!kSupportedLanguageCodes.contains(code)) return;
      if (_locale.languageCode == code) return;

      _locale = resolveAppLocale(code);
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_language', code);
      } catch (e) {
        debugPrint('Canli dil senkron kaydi hatasi: $e');
      }
      notifyListeners();
    }, onError: (error) {
      debugPrint('Canli dil dinleyicisi hatasi: $error');
    });
  }

  void _stopUserLanguageListener() {
    _userLanguageSubscription?.cancel();
    _userLanguageSubscription = null;
    _listeningUserId = null;
  }

  void _ensureLanguagePolling(
    AuthService authService,
    String userId,
    bool isGuest,
  ) {
    if (isGuest || userId.isEmpty) {
      _stopLanguagePolling();
      return;
    }
    if (_languagePollTimer != null) return;

    _languagePollTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      final activeUser = authService.currentUser;
      if (activeUser == null || activeUser.isGuest || activeUser.uid != userId) {
        return;
      }
      final code = await authService.getUserLanguage(userId);
      if (!kSupportedLanguageCodes.contains(code)) return;
      if (_locale.languageCode == code) return;

      _locale = resolveAppLocale(code);
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_language', code);
      } catch (e) {
        debugPrint('Poll dil senkron kaydi hatasi: $e');
      }
      notifyListeners();
    });
  }

  void _stopLanguagePolling() {
    _languagePollTimer?.cancel();
    _languagePollTimer = null;
  }

  @override
  void dispose() {
    _stopUserLanguageListener();
    _stopLanguagePolling();
    _firebaseAuthSubscription?.cancel();
    super.dispose();
  }

  Future<void> changeLanguage(Locale newLocale) async {
    final resolved =
        kSupportedLanguageCodes.contains(newLocale.languageCode)
            ? resolveAppLocale(newLocale.languageCode)
            : newLocale;
    if (_locale != resolved) {
      _locale = resolved;
      notifyListeners();
      
      // Dil tercihini kaydet
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_language', resolved.languageCode);
      } catch (e) {
        debugPrint('Dil kaydedilirken hata: $e');
      }
    }
  }
}
