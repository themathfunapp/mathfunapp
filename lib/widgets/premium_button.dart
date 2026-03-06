import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/premium_service_export.dart';
import '../localization/app_localizations.dart';

class PremiumButton extends StatelessWidget {
  final VoidCallback onPressed;
  final double? width;
  final double? height;

  const PremiumButton({
    super.key,
    required this.onPressed,
    this.width,
    this.height = 60,
  });

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    
    return Consumer<PremiumService>(
      builder: (context, premiumService, child) {
        final isPremium = premiumService.isPremium;

        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isPremium
                  ? [
                      const Color(0xFF4CAF50),
                      const Color(0xFF2E7D32),
                    ]
                  : [
                      const Color(0xFFFFD700),
                      const Color(0xFFFFA500),
                    ],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: (isPremium ? Colors.green : Colors.amber).withValues(alpha: 0.4),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onPressed,
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      isPremium ? '✓' : '👑',
                      style: const TextStyle(fontSize: 20),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      isPremium ? localizations.premiumMember : localizations.upgradeToPremium,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isPremium ? Colors.white : const Color(0xFF8B4513),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      isPremium ? '👑' : '🚀',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}