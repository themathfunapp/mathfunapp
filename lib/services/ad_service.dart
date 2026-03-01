import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// AdMob Reklam Yönetim Servisi (Singleton)
/// Banner, Interstitial ve Rewarded reklamları yönetir
class AdService extends ChangeNotifier {
  // Singleton instance
  static final AdService _instance = AdService._internal();
  factory AdService() => _instance;
  AdService._internal();

  // ================== AD UNIT IDs ==================
  
  // Production Ad Unit IDs - Canlı Reklamlar
  static const String _rewardedAdUnitId = 'ca-app-pub-6873365802729244/9037844504';
  static const String _bannerAdUnitId = 'ca-app-pub-6873365802729244/1636702911';
  static const String _interstitialAdUnitId = 'ca-app-pub-6873365802729244/3649311098';
  
  // Test Ad Unit IDs (Debug mode için - kDebugMode true olduğunda kullanılır)
  static const String _testRewardedAdUnitId = 'ca-app-pub-3940256099942544/5224354917';
  static const String _testBannerAdUnitId = 'ca-app-pub-3940256099942544/6300978111';
  static const String _testInterstitialAdUnitId = 'ca-app-pub-3940256099942544/1033173712';

  // ================== AD INSTANCES ==================
  
  RewardedAd? _rewardedAd;
  InterstitialAd? _interstitialAd;
  
  // ================== STATE VARIABLES ==================
  
  bool _isInitialized = false;
  bool _isRewardedAdLoaded = false;
  bool _isRewardedAdLoading = false;
  bool _isInterstitialAdLoaded = false;
  bool _isInterstitialAdLoading = false;
  
  // Premium durumu - reklamları devre dışı bırakmak için
  bool _isPremiumUser = false;
  
  // Interstitial gösterim sayacı (her 2-3 bölümde bir göstermek için)
  int _interstitialCounter = 0;
  static const int _interstitialFrequency = 3; // Her 3 bölümde bir

  // ================== GETTERS ==================
  
  bool get isInitialized => _isInitialized;
  bool get isRewardedAdLoaded => _isRewardedAdLoaded;
  bool get isInterstitialAdLoaded => _isInterstitialAdLoaded;
  bool get isPremiumUser => _isPremiumUser;
  
  // Debug modda test reklamları kullan
  String get _rewardedId => kDebugMode ? _testRewardedAdUnitId : _rewardedAdUnitId;
  String get _bannerId => kDebugMode ? _testBannerAdUnitId : _bannerAdUnitId;
  String get _interstitialId => kDebugMode ? _testInterstitialAdUnitId : _interstitialAdUnitId;

  // ================== INITIALIZATION ==================

  /// Servisi başlat
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      debugPrint('AdService: MobileAds başlatılıyor...');
      await MobileAds.instance.initialize();
      _isInitialized = true;
      debugPrint('AdService: MobileAds başlatıldı');

      // Reklamları önceden yükle
      await Future.wait([
        loadRewardedAd(),
        loadInterstitialAd(),
      ]);
    } catch (e) {
      debugPrint('AdService initialize error: $e');
    }
  }

  /// Premium durumunu güncelle
  void setPremiumUser(bool isPremium) {
    _isPremiumUser = isPremium;
    notifyListeners();
    debugPrint('AdService: Premium durumu güncellendi: $isPremium');
  }

  /// Premium kullanıcı için reklamları göstermemeli
  bool shouldShowAds() {
    return !_isPremiumUser;
  }

  // ================== REWARDED ADS ==================

  /// Ödüllü reklamı yükle
  Future<void> loadRewardedAd() async {
    if (_isRewardedAdLoading || _isRewardedAdLoaded || _isPremiumUser) {
      return;
    }

    _isRewardedAdLoading = true;
    notifyListeners();

    debugPrint('AdService: Ödüllü reklam yükleniyor...');

    await RewardedAd.load(
      adUnitId: _rewardedId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (RewardedAd ad) {
          debugPrint('AdService: Ödüllü reklam yüklendi');
          _rewardedAd = ad;
          _isRewardedAdLoaded = true;
          _isRewardedAdLoading = false;
          
          _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              debugPrint('AdService: Ödüllü reklam kapatıldı');
              ad.dispose();
              _rewardedAd = null;
              _isRewardedAdLoaded = false;
              loadRewardedAd();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              debugPrint('AdService: Ödüllü reklam gösterilemedi: $error');
              ad.dispose();
              _rewardedAd = null;
              _isRewardedAdLoaded = false;
              loadRewardedAd();
            },
          );
          
          notifyListeners();
        },
        onAdFailedToLoad: (LoadAdError error) {
          debugPrint('AdService: Ödüllü reklam yüklenemedi: $error');
          _isRewardedAdLoaded = false;
          _isRewardedAdLoading = false;
          _rewardedAd = null;
          notifyListeners();

          Future.delayed(const Duration(seconds: 30), loadRewardedAd);
        },
      ),
    );
  }

  /// Ödüllü reklamı göster
  Future<bool> showRewardedAd({
    required Function(int amount) onRewardEarned,
    VoidCallback? onAdClosed,
  }) async {
    if (_isPremiumUser) {
      debugPrint('AdService: Premium kullanıcı, reklam gösterilmiyor');
      return false;
    }

    if (!_isRewardedAdLoaded || _rewardedAd == null) {
      debugPrint('AdService: Ödüllü reklam henüz yüklenmedi');
      loadRewardedAd();
      return false;
    }

    try {
      await _rewardedAd!.show(
        onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
          debugPrint('AdService: Ödül kazanıldı! Miktar: ${reward.amount}');
          onRewardEarned(reward.amount.toInt());
        },
      );

      if (onAdClosed != null) {
        Future.delayed(const Duration(milliseconds: 500), onAdClosed);
      }

      return true;
    } catch (e) {
      debugPrint('AdService showRewardedAd error: $e');
      return false;
    }
  }

  /// Reklam izleyerek can kazanma
  Future<bool> watchAdForLife({
    required VoidCallback onLifeEarned,
    VoidCallback? onAdClosed,
  }) async {
    return await showRewardedAd(
      onRewardEarned: (amount) {
        debugPrint('AdService: Can kazanıldı!');
        onLifeEarned();
      },
      onAdClosed: onAdClosed,
    );
  }

  // ================== INTERSTITIAL ADS ==================

  /// Geçiş reklamını yükle
  Future<void> loadInterstitialAd() async {
    if (_isInterstitialAdLoading || _isInterstitialAdLoaded || _isPremiumUser) {
      return;
    }

    _isInterstitialAdLoading = true;

    debugPrint('AdService: Geçiş reklamı yükleniyor...');

    await InterstitialAd.load(
      adUnitId: _interstitialId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          debugPrint('AdService: Geçiş reklamı yüklendi');
          _interstitialAd = ad;
          _isInterstitialAdLoaded = true;
          _isInterstitialAdLoading = false;

          _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              debugPrint('AdService: Geçiş reklamı kapatıldı');
              ad.dispose();
              _interstitialAd = null;
              _isInterstitialAdLoaded = false;
              loadInterstitialAd();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              debugPrint('AdService: Geçiş reklamı gösterilemedi: $error');
              ad.dispose();
              _interstitialAd = null;
              _isInterstitialAdLoaded = false;
              loadInterstitialAd();
            },
          );

          notifyListeners();
        },
        onAdFailedToLoad: (LoadAdError error) {
          debugPrint('AdService: Geçiş reklamı yüklenemedi: $error');
          _isInterstitialAdLoaded = false;
          _isInterstitialAdLoading = false;
          _interstitialAd = null;

          Future.delayed(const Duration(seconds: 30), loadInterstitialAd);
        },
      ),
    );
  }

  /// Geçiş reklamını göster (bölüm/seviye tamamlandığında)
  /// Her [_interstitialFrequency] bölümde bir gösterir
  Future<bool> showInterstitialAd({bool forceShow = false}) async {
    if (_isPremiumUser) {
      debugPrint('AdService: Premium kullanıcı, geçiş reklamı gösterilmiyor');
      return false;
    }

    _interstitialCounter++;
    
    // Her 3 bölümde bir göster (veya force ise hemen göster)
    if (!forceShow && _interstitialCounter % _interstitialFrequency != 0) {
      debugPrint('AdService: Geçiş reklamı atlandı (sayaç: $_interstitialCounter)');
      return false;
    }

    if (!_isInterstitialAdLoaded || _interstitialAd == null) {
      debugPrint('AdService: Geçiş reklamı henüz yüklenmedi');
      loadInterstitialAd();
      return false;
    }

    try {
      debugPrint('AdService: Geçiş reklamı gösteriliyor...');
      await _interstitialAd!.show();
      return true;
    } catch (e) {
      debugPrint('AdService showInterstitialAd error: $e');
      return false;
    }
  }

  /// Sayacı sıfırla
  void resetInterstitialCounter() {
    _interstitialCounter = 0;
  }

  // ================== BANNER ADS ==================

  /// Banner reklam oluştur
  BannerAd? createBannerAd({
    AdSize size = AdSize.banner,
    Function(Ad)? onAdLoaded,
    Function(Ad, LoadAdError)? onAdFailedToLoad,
  }) {
    if (_isPremiumUser) {
      debugPrint('AdService: Premium kullanıcı, banner oluşturulmuyor');
      return null;
    }

    return BannerAd(
      adUnitId: _bannerId,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          debugPrint('AdService: Banner reklam yüklendi');
          onAdLoaded?.call(ad);
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('AdService: Banner yüklenemedi: $error');
          ad.dispose();
          onAdFailedToLoad?.call(ad, error);
        },
        onAdOpened: (ad) => debugPrint('AdService: Banner açıldı'),
        onAdClosed: (ad) => debugPrint('AdService: Banner kapatıldı'),
      ),
    );
  }

  // ================== UTILITY METHODS ==================

  /// Tüm reklamları yükle
  void preloadAllAds() {
    if (_isPremiumUser) return;
    
    if (!_isRewardedAdLoaded && !_isRewardedAdLoading) {
      loadRewardedAd();
    }
    if (!_isInterstitialAdLoaded && !_isInterstitialAdLoading) {
      loadInterstitialAd();
    }
  }

  /// Servisi temizle
  @override
  void dispose() {
    _rewardedAd?.dispose();
    _interstitialAd?.dispose();
    super.dispose();
  }
}

// ================== BANNER AD WIDGET ==================

/// Kolay kullanım için Banner reklam widget'ı
class BannerAdWidget extends StatefulWidget {
  final AdSize adSize;
  final EdgeInsetsGeometry? padding;

  const BannerAdWidget({
    super.key,
    this.adSize = AdSize.banner,
    this.padding,
  });

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() {
    final adService = AdService();
    
    if (!adService.shouldShowAds()) {
      return;
    }

    _bannerAd = adService.createBannerAd(
      size: widget.adSize,
      onAdLoaded: (ad) {
        if (mounted) {
          setState(() => _isLoaded = true);
        }
      },
      onAdFailedToLoad: (ad, error) {
        if (mounted) {
          setState(() => _isLoaded = false);
        }
      },
    );

    _bannerAd?.load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final adService = AdService();
    
    // Premium kullanıcıya reklam gösterme
    if (!adService.shouldShowAds()) {
      return const SizedBox.shrink();
    }

    if (!_isLoaded || _bannerAd == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: widget.padding,
      width: widget.adSize.width.toDouble(),
      height: widget.adSize.height.toDouble(),
      alignment: Alignment.center,
      child: AdWidget(ad: _bannerAd!),
    );
  }
}

// ================== AD-AWARE WRAPPER ==================

/// Premium olmayan kullanıcılara reklam gösteren wrapper
class AdAwareWidget extends StatelessWidget {
  final Widget child;
  final Widget? adWidget;
  final bool showAdOnTop;

  const AdAwareWidget({
    super.key,
    required this.child,
    this.adWidget,
    this.showAdOnTop = false,
  });

  @override
  Widget build(BuildContext context) {
    final adService = AdService();
    
    if (!adService.shouldShowAds() || adWidget == null) {
      return child;
    }

    return Column(
      children: showAdOnTop
          ? [adWidget!, Expanded(child: child)]
          : [Expanded(child: child), adWidget!],
    );
  }
}
