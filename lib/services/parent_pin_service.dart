import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:crypto/crypto.dart';

/// Ebeveyn paneli PIN ve güvenlik yönetimi
/// - Secure storage ile PIN saklama
/// - Biyometrik doğrulama
/// - 3 yanlış denemede 5 dk kilit
/// - Güvenlik sorusu ile PIN sıfırlama
class ParentPinService extends ChangeNotifier {
  static const int _maxAttempts = 3;
  static const int _lockoutMinutes = 5;
  static const int _sessionTimeoutMinutes = 5;

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  final LocalAuthentication _localAuth = LocalAuthentication();

  String? _userId;
  int _failedAttempts = 0;
  DateTime? _lockoutUntil;
  DateTime? _lastActivityAt;
  bool _sessionActive = false;

  static const String _keyPrefix = 'parent_pin_';
  String get _pinKey => '${_keyPrefix}pin_$_userId';
  String get _securityQuestionKey => '${_keyPrefix}sq_$_userId';
  String get _securityAnswerKey => '${_keyPrefix}sa_$_userId';
  String get _failedAttemptsKey => '${_keyPrefix}attempts_$_userId';
  String get _lockoutUntilKey => '${_keyPrefix}lockout_$_userId';

  void initialize(String? userId) {
    _userId = userId;
    _sessionActive = false;
    _loadLockoutState();
  }

  Future<void> _loadLockoutState() async {
    if (_userId == null) return;
    try {
      final attemptsStr = await _storage.read(key: _failedAttemptsKey);
      final lockoutStr = await _storage.read(key: _lockoutUntilKey);
      _failedAttempts = int.tryParse(attemptsStr ?? '') ?? 0;
      if (lockoutStr != null) {
        _lockoutUntil = DateTime.tryParse(lockoutStr);
        if (_lockoutUntil != null && DateTime.now().isAfter(_lockoutUntil!)) {
          _lockoutUntil = null;
          _failedAttempts = 0;
          await _storage.delete(key: _lockoutUntilKey);
          await _storage.write(key: _failedAttemptsKey, value: '0');
        }
      }
      notifyListeners();
    } catch (_) {}
  }

  /// PIN tanımlı mı?
  Future<bool> hasPin() async {
    if (_userId == null) return false;
    final pin = await _storage.read(key: _pinKey);
    return pin != null && pin.isNotEmpty;
  }

  /// Biyometrik doğrulama mevcut mu?
  Future<bool> canUseBiometrics() async {
    try {
      if (!await _localAuth.isDeviceSupported()) return false;
      final biometrics = await _localAuth.getAvailableBiometrics();
      return biometrics.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Biyometrik türü (parmak izi / yüz tanıma)
  Future<String> getBiometricType() async {
    try {
      final biometrics = await _localAuth.getAvailableBiometrics();
      if (biometrics.contains(BiometricType.face)) return 'Yüz Tanıma';
      if (biometrics.contains(BiometricType.fingerprint)) return 'Parmak İzi';
      if (biometrics.contains(BiometricType.iris)) return 'İris';
      return 'Biyometrik';
    } catch (_) {
      return 'Biyometrik';
    }
  }

  /// Kilitli mi?
  bool get isLocked {
    if (_lockoutUntil == null) return false;
    return DateTime.now().isBefore(_lockoutUntil!);
  }

  /// Kalan kilit süresi (saniye)
  int get remainingLockoutSeconds {
    if (_lockoutUntil == null) return 0;
    final diff = _lockoutUntil!.difference(DateTime.now());
    return diff.isNegative ? 0 : diff.inSeconds;
  }

  /// Oturum aktif mi? (zaman aşımı kontrolü)
  bool get isSessionActive => _sessionActive;

  /// Son aktiviteden bu yana geçen süre (dakika)
  int get minutesSinceLastActivity {
    if (_lastActivityAt == null) return _sessionTimeoutMinutes;
    return DateTime.now().difference(_lastActivityAt!).inMinutes;
  }

  static const int sessionTimeoutMinutes = 5;

  /// Aktivite kaydet (oturum zaman aşımı için)
  void recordActivity() {
    _lastActivityAt = DateTime.now();
    _sessionActive = true;
    notifyListeners();
  }

  /// Oturum zaman aşımına uğradı mı?
  bool get isSessionExpired =>
      _sessionActive &&
      _lastActivityAt != null &&
      DateTime.now().difference(_lastActivityAt!).inMinutes >= sessionTimeoutMinutes;

  /// Oturumu sonlandır
  void endSession() {
    _sessionActive = false;
    _lastActivityAt = null;
    notifyListeners();
  }

  String _hashPin(String pin) {
    final bytes = utf8.encode(pin);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// İlk PIN kurulumu veya güncelleme
  /// [preserveSecurityQuestion] true ise mevcut güvenlik sorusu korunur
  Future<bool> setPin(
    String pin, {
    String? securityQuestion,
    String? securityAnswer,
    bool preserveSecurityQuestion = false,
  }) async {
    if (_userId == null || pin.length != 4) return false;
    try {
      await _storage.write(key: _pinKey, value: _hashPin(pin));
      if (securityQuestion != null && securityAnswer != null &&
          securityQuestion.isNotEmpty && securityAnswer.isNotEmpty) {
        await _storage.write(key: _securityQuestionKey, value: securityQuestion);
        await _storage.write(key: _securityAnswerKey, value: _hashPin(securityAnswer.toLowerCase().trim()));
      } else if (!preserveSecurityQuestion) {
        await _storage.delete(key: _securityQuestionKey);
        await _storage.delete(key: _securityAnswerKey);
      }
      _failedAttempts = 0;
      await _storage.write(key: _failedAttemptsKey, value: '0');
      await _storage.delete(key: _lockoutUntilKey);
      _lockoutUntil = null;
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// PIN değiştir (mevcut PIN ile doğrulama gerekli)
  Future<bool> changePin(String currentPin, String newPin) async {
    if (_userId == null || newPin.length != 4) return false;
    final ok = await verifyPin(currentPin);
    if (!ok) return false;
    return setPin(newPin, preserveSecurityQuestion: true);
  }

  /// PIN doğrula
  Future<bool> verifyPin(String pin) async {
    if (_userId == null || isLocked) return false;
    try {
      final stored = await _storage.read(key: _pinKey);
      if (stored == null) return false;
      if (stored == _hashPin(pin)) {
        _failedAttempts = 0;
        await _storage.write(key: _failedAttemptsKey, value: '0');
        await _storage.delete(key: _lockoutUntilKey);
        _lockoutUntil = null;
        recordActivity();
        notifyListeners();
        return true;
      }
      _failedAttempts++;
      await _storage.write(key: _failedAttemptsKey, value: '$_failedAttempts');
      if (_failedAttempts >= _maxAttempts) {
        _lockoutUntil = DateTime.now().add(const Duration(minutes: _lockoutMinutes));
        await _storage.write(key: _lockoutUntilKey, value: _lockoutUntil!.toIso8601String());
      }
      notifyListeners();
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Biyometrik doğrulama
  Future<bool> authenticateWithBiometrics() async {
    if (_userId == null || isLocked) return false;
    if (!await hasPin()) return false;
    try {
      final ok = await _localAuth.authenticate(
        localizedReason: 'Ebeveyn paneline erişim için doğrulama yapın',
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
        ),
      );
      if (ok) {
        _failedAttempts = 0;
        await _storage.write(key: _failedAttemptsKey, value: '0');
        await _storage.delete(key: _lockoutUntilKey);
        _lockoutUntil = null;
        recordActivity();
        notifyListeners();
      }
      return ok;
    } catch (_) {
      return false;
    }
  }

  /// Güvenlik sorusu tanımlı mı?
  Future<bool> hasSecurityQuestion() async {
    if (_userId == null) return false;
    final q = await _storage.read(key: _securityQuestionKey);
    final a = await _storage.read(key: _securityAnswerKey);
    return q != null && a != null && q.isNotEmpty && a.isNotEmpty;
  }

  /// Güvenlik sorusunu getir (sadece soru metni)
  Future<String?> getSecurityQuestion() async {
    if (_userId == null) return null;
    return _storage.read(key: _securityQuestionKey);
  }

  /// Güvenlik sorusu cevabı ile doğrula (PIN sıfırlama için)
  Future<bool> verifySecurityAnswer(String answer) async {
    if (_userId == null) return false;
    try {
      final stored = await _storage.read(key: _securityAnswerKey);
      if (stored == null) return false;
      final hashed = _hashPin(answer.toLowerCase().trim());
      if (stored == hashed) {
        _failedAttempts = 0;
        await _storage.write(key: _failedAttemptsKey, value: '0');
        await _storage.delete(key: _lockoutUntilKey);
        _lockoutUntil = null;
        notifyListeners();
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Güvenlik sorusu ile PIN sıfırlama
  Future<bool> resetPinWithSecurityQuestion(String answer, String newPin) async {
    if (_userId == null || newPin.length != 4) return false;
    final ok = await verifySecurityAnswer(answer);
    if (!ok) return false;
    return setPin(newPin);
  }

  /// E-posta doğrulama sonrası PIN sıfırlama (Cloud Function ile doğrulama yapıldıktan sonra)
  Future<bool> resetPinAfterEmailVerification(String newPin) async {
    if (_userId == null || newPin.length != 4) return false;
    return setPin(newPin);
  }

  /// PIN'i tamamen kaldır
  Future<void> removePin() async {
    if (_userId == null) return;
    await _storage.delete(key: _pinKey);
    await _storage.delete(key: _securityQuestionKey);
    await _storage.delete(key: _securityAnswerKey);
    await _storage.delete(key: _failedAttemptsKey);
    await _storage.delete(key: _lockoutUntilKey);
    _failedAttempts = 0;
    _lockoutUntil = null;
    _sessionActive = false;
    _lastActivityAt = null;
    notifyListeners();
  }

  int get failedAttempts => _failedAttempts;
  int get maxAttempts => _maxAttempts;
  int get lockoutMinutes => _lockoutMinutes;
}
