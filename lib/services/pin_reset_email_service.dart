import 'package:cloud_functions/cloud_functions.dart';

/// E-posta doğrulama kodu ile PIN sıfırlama servisi
/// Cloud Functions: requestPinResetCode, verifyPinResetCode
class PinResetEmailService {
  final _functions = FirebaseFunctions.instance;

  /// E-posta adresine 6 haneli doğrulama kodu gönderir
  Future<void> requestPinResetCode() async {
    final callable = _functions.httpsCallable('requestPinResetCode');
    await callable.call();
  }

  /// Girilen kodu doğrular
  Future<void> verifyPinResetCode(String code) async {
    final callable = _functions.httpsCallable('verifyPinResetCode');
    await callable.call({'code': code.trim()});
  }
}
