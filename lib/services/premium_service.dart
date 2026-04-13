import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Platform-specific imports (conditional)
import 'premium_service_stub.dart'
    if (dart.library.io) 'premium_service_io.dart';

class PremiumService extends ChangeNotifier {
  // Singleton instance
  static final PremiumService _instance = PremiumService._internal();
  factory PremiumService() => _instance;
  PremiumService._internal();

  // In-App Purchase instance (web'de null)
  InAppPurchase? _inAppPurchase;
  
  // Firestore instance
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Ürün ID'leri
  static const String _premiumMonthlyId = 'premium_aylik_5990';
  static const Set<String> _productIds = {_premiumMonthlyId};

  // Premium fiyat (TL)
  static const double premiumPrice = 59.90;

  // State değişkenleri
  bool _isAvailable = false;
  bool _isPremium = false;
  bool _isPurchasePending = false;
  bool _isLoading = true;
  String? _errorMessage;
  List<ProductDetails> _products = [];
  List<PurchaseDetails> _purchases = [];
  
  // Stream subscription
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  // Getters
  bool get isAvailable => _isAvailable;
  bool get isPremium => _isPremium;
  bool get isPurchasePending => _isPurchasePending;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<ProductDetails> get products => _products;
  ProductDetails? get premiumProduct => 
      _products.isNotEmpty ? _products.first : null;

  // Kullanıcı ID'si (AuthService'den gelecek)
  String? _userId;

  // SharedPreferences key
  static const String _premiumKey = 'is_premium';
  static const String _premiumExpiresKey = 'premium_expires_at';

  /// Servisi başlat
  Future<void> initialize({String? userId}) async {
    _userId = userId;
    _isLoading = true;
    notifyListeners();

    try {
      // Web'de In-App Purchase desteklenmez
      if (kIsWeb) {
        _isAvailable = false;
        _isLoading = false;
        notifyListeners();
        return;
      }

      _inAppPurchase ??= InAppPurchase.instance;

      // Mağaza bağlantısını kontrol et
      _isAvailable = await _inAppPurchase!.isAvailable();
      
      if (!_isAvailable) {
        debugPrint('PremiumService: Mağaza kullanılamıyor');
        _isLoading = false;
        notifyListeners();
        return;
      }

      // Platform-specific yapılandırma (iOS delegate)
      if (!kIsWeb && _inAppPurchase != null) {
        await setupIOSDelegate(_inAppPurchase!);
      }

      // Purchase stream'i dinle
      _subscription = _inAppPurchase!.purchaseStream.listen(
        _onPurchaseUpdate,
        onDone: _onPurchaseStreamDone,
        onError: _onPurchaseStreamError,
      );

      // Ürünleri yükle
      await _loadProducts();

      // Yerel premium durumunu kontrol et
      await _loadLocalPremiumStatus();

      // Firestore'dan premium durumunu kontrol et
      if (_userId != null) {
        await _checkFirestorePremiumStatus();
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('PremiumService initialize error: $e');
      _errorMessage = 'Mağaza bağlantısı kurulamadı';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Ürünleri mağazadan yükle
  Future<void> _loadProducts() async {
    if (_inAppPurchase == null) return;
    try {
      final ProductDetailsResponse response = 
          await _inAppPurchase!.queryProductDetails(_productIds);
      
      if (response.notFoundIDs.isNotEmpty && kDebugMode) {
        debugPrint(
          'PremiumService: Mağazada bu ID yok (Play Console / imza): '
          '${response.notFoundIDs.join(", ")}',
        );
      }

      if (response.error != null) {
        debugPrint('Ürün yükleme hatası: ${response.error}');
        _errorMessage = 'Ürünler yüklenemedi';
        return;
      }

      _products = response.productDetails;
      debugPrint('Yüklenen ürünler: ${_products.length}');
      
      for (var product in _products) {
        debugPrint('Ürün: ${product.id} - ${product.title} - ${product.price}');
      }
    } catch (e) {
      debugPrint('Ürün yükleme exception: $e');
      _errorMessage = 'Ürünler yüklenirken hata oluştu';
    }
  }

  /// Yerel premium durumunu yükle
  Future<void> _loadLocalPremiumStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isPremium = prefs.getBool(_premiumKey) ?? false;
      
      // Süre kontrolü
      final expiresAt = prefs.getString(_premiumExpiresKey);
      if (expiresAt != null) {
        final expiryDate = DateTime.parse(expiresAt);
        if (expiryDate.isBefore(DateTime.now())) {
          _isPremium = false;
          await prefs.setBool(_premiumKey, false);
        }
      }
      
      debugPrint('Yerel premium durumu: $_isPremium');
    } catch (e) {
      debugPrint('Yerel premium yükleme hatası: $e');
    }
  }

  /// Firestore'dan premium durumunu kontrol et
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
          if (expiryDate.isAfter(DateTime.now())) {
            _isPremium = true;
            await _savePremiumLocally(true, expiryDate);
          } else {
            _isPremium = false;
            await _savePremiumLocally(false, null);
            await _updateFirestorePremiumStatus(false, null);
          }
        } else {
          _isPremium = isPremium;
        }
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Firestore premium kontrol hatası: $e');
    }
  }

  /// Premium durumunu yerel olarak kaydet
  Future<void> _savePremiumLocally(bool isPremium, DateTime? expiresAt) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_premiumKey, isPremium);
      if (expiresAt != null) {
        await prefs.setString(_premiumExpiresKey, expiresAt.toIso8601String());
      } else {
        await prefs.remove(_premiumExpiresKey);
      }
    } catch (e) {
      debugPrint('Yerel kayıt hatası: $e');
    }
  }

  /// Firestore'da premium durumunu güncelle
  Future<void> _updateFirestorePremiumStatus(bool isPremium, DateTime? expiresAt) async {
    if (_userId == null) return;

    try {
      await _firestore.collection('users').doc(_userId).set({
        'isPremium': isPremium,
        'premiumExpiresAt': expiresAt?.toIso8601String(),
        'premiumUpdatedAt': DateTime.now().toIso8601String(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Firestore güncelleme hatası: $e');
    }
  }

  /// Premium satın al
  Future<bool> buyPremium() async {
    if (!_isAvailable) {
      _errorMessage = 'Mağaza kullanılamıyor';
      notifyListeners();
      return false;
    }

    if (_products.isEmpty) {
      _errorMessage = 'Ürün bulunamadı';
      notifyListeners();
      return false;
    }

    if (_isPremium) {
      _errorMessage = 'Zaten Premium üyesiniz';
      notifyListeners();
      return false;
    }

    try {
      _isPurchasePending = true;
      _errorMessage = null;
      notifyListeners();

      final ProductDetails product = _products.first;
      
      // Abonelik parametreleri - tüm platformlarda standart PurchaseParam kullan
      final PurchaseParam purchaseParam = PurchaseParam(
        productDetails: product,
      );

      // Satın alma işlemini başlat
      if (_inAppPurchase == null) return false;
      final bool success = await _inAppPurchase!.buyNonConsumable(
        purchaseParam: purchaseParam,
      );

      if (!success) {
        _isPurchasePending = false;
        _errorMessage = 'Satın alma başlatılamadı';
        notifyListeners();
        return false;
      }

      return true;
    } catch (e) {
      debugPrint('Satın alma hatası: $e');
      _isPurchasePending = false;
      _errorMessage = 'Satın alma sırasında hata oluştu';
      notifyListeners();
      return false;
    }
  }

  /// Satın almaları geri yükle
  Future<bool> restorePurchases() async {
    if (!_isAvailable) {
      _errorMessage = 'Mağaza kullanılamıyor';
      notifyListeners();
      return false;
    }

    try {
      _isPurchasePending = true;
      _errorMessage = null;
      notifyListeners();

      if (_inAppPurchase == null) return false;
      await _inAppPurchase!.restorePurchases();
      return true;
    } catch (e) {
      debugPrint('Geri yükleme hatası: $e');
      _isPurchasePending = false;
      _errorMessage = 'Satın almalar geri yüklenemedi';
      notifyListeners();
      return false;
    }
  }

  /// Purchase stream güncellemelerini işle
  void _onPurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) {
    _purchases = purchaseDetailsList;

    for (final PurchaseDetails purchaseDetails in purchaseDetailsList) {
      debugPrint('Purchase update: ${purchaseDetails.productID} - ${purchaseDetails.status}');

      switch (purchaseDetails.status) {
        case PurchaseStatus.pending:
          _isPurchasePending = true;
          _errorMessage = null;
          notifyListeners();
          break;

        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          _handleSuccessfulPurchase(purchaseDetails);
          break;

        case PurchaseStatus.error:
          _isPurchasePending = false;
          _errorMessage = purchaseDetails.error?.message ?? 'Satın alma hatası';
          notifyListeners();
          break;

        case PurchaseStatus.canceled:
          _isPurchasePending = false;
          _errorMessage = 'Satın alma iptal edildi';
          notifyListeners();
          break;
      }

      // İşlemi tamamla
      if (purchaseDetails.pendingCompletePurchase && _inAppPurchase != null) {
        _inAppPurchase!.completePurchase(purchaseDetails);
      }
    }
  }

  /// Başarılı satın almayı işle
  Future<void> _handleSuccessfulPurchase(PurchaseDetails purchaseDetails) async {
    // Makbuz doğrulaması (yerel)
    final isValid = await _verifyPurchase(purchaseDetails);

    if (isValid) {
      // Abonelik süresi (1 ay)
      final expiryDate = DateTime.now().add(const Duration(days: 30));

      _isPremium = true;
      _isPurchasePending = false;
      _errorMessage = null;

      // Yerel kaydet
      await _savePremiumLocally(true, expiryDate);

      // Firestore'a kaydet
      await _updateFirestorePremiumStatus(true, expiryDate);

      // Satın alma kaydı oluştur
      await _savePurchaseRecord(purchaseDetails, expiryDate);

      notifyListeners();
      debugPrint('Premium aktivasyonu başarılı!');
    } else {
      _isPurchasePending = false;
      _errorMessage = 'Satın alma doğrulanamadı';
      notifyListeners();
    }
  }

  /// Satın alma kaydını Firestore'a kaydet
  Future<void> _savePurchaseRecord(PurchaseDetails purchaseDetails, DateTime expiryDate) async {
    if (_userId == null) return;

    try {
      await _firestore.collection('purchases').add({
        'userId': _userId,
        'productId': purchaseDetails.productID,
        'purchaseId': purchaseDetails.purchaseID,
        'transactionDate': purchaseDetails.transactionDate,
        'status': purchaseDetails.status.toString(),
        'expiryDate': expiryDate.toIso8601String(),
        'createdAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Satın alma kaydı hatası: $e');
    }
  }

  /// Makbuz doğrulaması (yerel)
  Future<bool> _verifyPurchase(PurchaseDetails purchaseDetails) async {
    // Basit yerel doğrulama
    // Gerçek uygulamada sunucu taraflı doğrulama yapılmalı
    
    if (purchaseDetails.verificationData.localVerificationData.isEmpty) {
      debugPrint('Doğrulama verisi boş');
      return false;
    }

    // Product ID kontrolü
    if (purchaseDetails.productID != _premiumMonthlyId) {
      debugPrint('Ürün ID uyuşmuyor');
      return false;
    }

    // Platform-specific doğrulama (Android)
    if (!kIsWeb && isAndroidPlatform()) {
      final androidDetails = getAndroidPurchaseDetails(purchaseDetails);
      if (androidDetails != null) {
        // Signature kontrolü
        if (androidDetails.billingClientPurchase.purchaseState != 1) {
          debugPrint('Android satın alma durumu geçersiz');
          return false;
        }
      }
    }

    debugPrint('Satın alma doğrulandı');
    return true;
  }

  void _onPurchaseStreamDone() {
    debugPrint('Purchase stream tamamlandı');
    _subscription?.cancel();
  }

  void _onPurchaseStreamError(dynamic error) {
    debugPrint('Purchase stream hatası: $error');
    _errorMessage = 'Satın alma akışı hatası';
    notifyListeners();
  }

  /// Kullanıcı değiştiğinde çağır
  Future<void> updateUser(String? userId) async {
    _userId = userId;
    if (userId != null) {
      await _checkFirestorePremiumStatus();
    } else {
      _isPremium = false;
      notifyListeners();
    }
  }

  /// Premium süresini kontrol et
  Future<void> checkSubscriptionValidity() async {
    await _loadLocalPremiumStatus();
    if (_userId != null) {
      await _checkFirestorePremiumStatus();
    }
    notifyListeners();
  }

  /// Servisi temizle
  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
