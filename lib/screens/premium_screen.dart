import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:mathfun/config/legal_urls.dart';
import 'package:mathfun/localization/app_localizations.dart';
import 'package:mathfun/services/premium_service_export.dart';

class PremiumScreen extends StatefulWidget {
  final VoidCallback? onBack;

  const PremiumScreen({
    super.key,
    this.onBack,
  });

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    
    return Consumer<PremiumService>(
      builder: (context, premiumService, child) {
        return Scaffold(
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF1a1a2e),
                  Color(0xFF16213e),
                  Color(0xFF0f3460),
                ],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  _buildAppBar(localizations),
                  Expanded(
                    child: premiumService.isLoading
                        ? _buildLoadingState(localizations)
                        : SingleChildScrollView(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              children: [
                                _buildPremiumHeader(premiumService, localizations),
                                const SizedBox(height: 24),
                                _buildFeaturesList(localizations),
                                const SizedBox(height: 24),
                                _buildPricingCard(premiumService, localizations),
                                const SizedBox(height: 16),
                                _buildSubscribeButton(premiumService, localizations),
                                const SizedBox(height: 12),
                                _buildRestoreButton(premiumService, localizations),
                                const SizedBox(height: 20),
                                _buildTermsText(localizations),
                              ],
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAppBar(AppLocalizations localizations) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          GestureDetector(
            onTap: widget.onBack ?? () => Navigator.pop(context),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.2),
                ),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
          Expanded(
            child: Text(
              localizations.premiumTitle,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 44),
        ],
      ),
    );
  }

  Widget _buildLoadingState(AppLocalizations localizations) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.amber),
          ),
          const SizedBox(height: 16),
          Text(
            localizations.premiumLoading,
            style: const TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumHeader(PremiumService premiumService, AppLocalizations localizations) {
    return Column(
      children: [
        ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.amber.withValues(alpha: 0.5),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: const Center(
              child: Text(
                '👑',
                style: TextStyle(fontSize: 50),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          premiumService.isPremium
              ? localizations.premiumMember
              : localizations.upgradeToPremium,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          premiumService.isPremium
              ? localizations.allFeaturesAccess
              : localizations.unlimitedLearning,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 16,
          ),
        ),
        if (premiumService.isPremium)
          Container(
            margin: const EdgeInsets.only(top: 16),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.green),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 20),
                const SizedBox(width: 8),
                Text(
                  localizations.activePremium,
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildFeaturesList(AppLocalizations localizations) {
    final features = [
      _PremiumFeature(
        icon: '🧩',
        title: localizations.intelligenceGames,
        description: localizations.intelligenceGamesDesc,
      ),
      _PremiumFeature(
        icon: '🎨',
        title: localizations.colorfulMath,
        description: localizations.colorfulMathDesc,
      ),
      _PremiumFeature(
        icon: '📊',
        title: localizations.detailedStats,
        description: localizations.detailedStatsDesc,
      ),
      _PremiumFeature(
        icon: '🚫',
        title: localizations.adFreeExperience,
        description: localizations.adFreeExperienceDesc,
      ),
      _PremiumFeature(
        icon: '🎮',
        title: localizations.specialGameModes,
        description: localizations.specialGameModesDesc,
      ),
      _PremiumFeature(
        icon: '👨‍👩‍👧',
        title: localizations.parentPanel,
        description: localizations.parentPanelDesc,
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('✨', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Text(
                localizations.premiumFeatures,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...features.map((feature) => _buildFeatureItem(feature)),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(_PremiumFeature feature) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                feature.icon,
                style: const TextStyle(fontSize: 22),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  feature.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  feature.description,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.check_circle,
            color: Colors.amber,
            size: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildPricingCard(PremiumService premiumService, AppLocalizations localizations) {
    final product = premiumService.premiumProduct;
    final priceText = product?.price ?? '₺59,90';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.amber.withValues(alpha: 0.3),
            Colors.orange.withValues(alpha: 0.2),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.amber.withValues(alpha: 0.5),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('👑', style: TextStyle(fontSize: 24)),
              const SizedBox(width: 8),
              Text(
                localizations.monthlyPremium,
                style: const TextStyle(
                  color: Colors.amber,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                priceText,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 8, left: 4),
                child: Text(
                  localizations.perMonth,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              localizations.firstMonthDiscount,
              style: const TextStyle(
                color: Colors.greenAccent,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscribeButton(PremiumService premiumService, AppLocalizations localizations) {
    final isPremium = premiumService.isPremium;
    final isPending = premiumService.isPurchasePending;

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: isPremium || isPending
            ? null
            : () async {
                final success = await premiumService.buyPremium();
                if (!success && mounted) {
                  _showErrorSnackBar(
                    premiumService.errorMessage ?? localizations.errorOccurred,
                  );
                } else if (success && premiumService.isPremium && mounted) {
                  _showSuccessSnackBar(localizations.premiumActivated);
                }
              },
        style: ElevatedButton.styleFrom(
          backgroundColor: isPremium ? Colors.grey : Colors.amber,
          foregroundColor: isPremium ? Colors.white : const Color(0xFF8B4513),
          disabledBackgroundColor: isPremium ? Colors.green : Colors.grey,
          disabledForegroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: isPremium ? 0 : 8,
        ),
        child: isPending
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    isPremium ? '✓' : '👑',
                    style: const TextStyle(fontSize: 20),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isPremium ? localizations.alreadyPremium : localizations.subscribeNow,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildRestoreButton(PremiumService premiumService, AppLocalizations localizations) {
    return TextButton(
      onPressed: premiumService.isPurchasePending
          ? null
          : () async {
              final success = await premiumService.restorePurchases();
              if (mounted) {
                if (success) {
                  _showInfoSnackBar(localizations.checkingPurchases);
                } else {
                  _showErrorSnackBar(
                    premiumService.errorMessage ?? localizations.restoreFailed,
                  );
                }
              }
            },
      child: Text(
        localizations.restorePurchases,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 14,
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }

  Widget _buildTermsText(AppLocalizations localizations) {
    return Column(
      children: [
        Text(
          localizations.subscriptionAutoRenews,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          localizations.cancelAnytime,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: () => _showTermsDialog(localizations),
              child: Text(
                localizations.termsOfUse,
                style: TextStyle(
                  color: Colors.amber.withValues(alpha: 0.7),
                  fontSize: 11,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
            Text(
              ' • ',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
              ),
            ),
            GestureDetector(
              onTap: () => _showPrivacyDialog(localizations),
              child: Text(
                localizations.privacyPolicy,
                style: TextStyle(
                  color: Colors.amber.withValues(alpha: 0.7),
                  fontSize: 11,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showInfoSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.blue,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showTermsDialog(AppLocalizations localizations) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2D1B69),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          localizations.termsOfUse,
          style: const TextStyle(color: Colors.white),
        ),
        content: SingleChildScrollView(
          child: Text(
            localizations.termsContent,
            style: const TextStyle(color: Colors.white70),
          ),
        ),
        actions: [
          if (hasConfiguredTermsOfUseUrl)
            TextButton(
              onPressed: () async {
                Navigator.pop(ctx);
                await LegalUrls.launchTermsInBrowserFromDialog(context, localizations);
              },
              child: Text(
                localizations.get('legal_open_in_browser'),
                style: const TextStyle(color: Colors.amber),
              ),
            ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(localizations.close, style: const TextStyle(color: Colors.amber)),
          ),
        ],
      ),
    );
  }

  void _showPrivacyDialog(AppLocalizations localizations) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2D1B69),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          localizations.privacyPolicy,
          style: const TextStyle(color: Colors.white),
        ),
        content: SingleChildScrollView(
          child: Text(
            localizations.privacyContent,
            style: const TextStyle(color: Colors.white70),
          ),
        ),
        actions: [
          if (hasConfiguredPrivacyPolicyUrl)
            TextButton(
              onPressed: () async {
                Navigator.pop(ctx);
                await LegalUrls.launchPrivacyInBrowserFromDialog(context, localizations);
              },
              child: Text(
                localizations.get('legal_open_in_browser'),
                style: const TextStyle(color: Colors.amber),
              ),
            ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(localizations.close, style: const TextStyle(color: Colors.amber)),
          ),
        ],
      ),
    );
  }
}

class _PremiumFeature {
  final String icon;
  final String title;
  final String description;

  _PremiumFeature({
    required this.icon,
    required this.title,
    required this.description,
  });
}
