import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Web platformu için PremiumService - in_app_purchase desteklenmediği için
/// sadece Firestore üzerinden premium durumunu kontrol eder.
class PremiumService extends ChangeNotifier {
  static final PremiumService _instance = PremiumService._internal();
  factory PremiumService() => _instance;
  PremiumService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isAvailable = false;
  bool _isPremium = false;
  bool _isPurchasePending = false;
  bool _isLoading = true;
  String? _errorMessage;
  String? _userId;

  static const double premiumPrice = 59.90;

  bool get isAvailable => _isAvailable;
  bool get isPremium => _isPremium;
  bool get isPurchasePending => _isPurchasePending;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<dynamic> get products => [];
  dynamic get premiumProduct => null;

  Future<void> initialize({String? userId}) async {
    _userId = userId;
    _isLoading = true;
    _isAvailable = false; // Web'de satın alma yok
    notifyListeners();

    try {
      if (_userId != null) {
        await _checkFirestorePremiumStatus();
      }
    } catch (e) {
      debugPrint('PremiumService initialize error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _checkFirestorePremiumStatus() async {
    if (_userId == null) return;
    try {
      final doc = await _firestore.collection('users').doc(_userId).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        final isPremium = data['isPremium'] ?? false;
        final expiresAt = data['premiumExpiresAt'];
        if (isPremium && expiresAt != null) {
          final expiryDate = DateTime.parse(expiresAt);
          _isPremium = expiryDate.isAfter(DateTime.now());
        } else {
          _isPremium = isPremium;
        }
      }
    } catch (e) {
      debugPrint('Firestore premium kontrol hatası: $e');
    }
  }

  Future<bool> buyPremium() async {
    _errorMessage = 'Web\'de uygulama içi satın alma desteklenmiyor';
    notifyListeners();
    return false;
  }

  Future<bool> restorePurchases() async {
    if (_userId != null) {
      await _checkFirestorePremiumStatus();
      notifyListeners();
    }
    return _isPremium;
  }

  Future<void> updateUser(String? userId) async {
    _userId = userId;
    if (userId != null) {
      await _checkFirestorePremiumStatus();
    } else {
      _isPremium = false;
    }
    notifyListeners();
  }

  Future<void> checkSubscriptionValidity() async {
    if (_userId != null) {
      await _checkFirestorePremiumStatus();
    }
    notifyListeners();
  }
}
