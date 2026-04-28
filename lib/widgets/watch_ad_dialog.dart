import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/ad_service.dart';
import '../services/game_mechanics_service.dart';

/// Reklam izleyerek can kazanma dialogu
class WatchAdForLifeDialog extends StatelessWidget {
  final VoidCallback? onLifeEarned;
  final VoidCallback? onCancel;

  const WatchAdForLifeDialog({
    super.key,
    this.onLifeEarned,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AdService>(
      builder: (context, adService, child) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2D1B69),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Text('❤️', style: TextStyle(fontSize: 24)),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Canların Bitti!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    const Text(
                      '🎬',
                      style: TextStyle(fontSize: 40),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Kısa bir reklam izleyerek\n1 can kazanabilirsin!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          adService.isRewardedAdLoaded
                              ? Icons.check_circle
                              : Icons.hourglass_empty,
                          color: adService.isRewardedAdLoaded
                              ? Colors.green
                              : Colors.orange,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          adService.isRewardedAdLoaded
                              ? 'Reklam hazır'
                              : 'Reklam yükleniyor...',
                          style: TextStyle(
                            color: adService.isRewardedAdLoaded
                                ? Colors.green
                                : Colors.orange,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                onCancel?.call();
              },
              child: Text(
                'Vazgeç',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
            ),
            ElevatedButton.icon(
              onPressed: adService.isRewardedAdLoaded
                  ? () => _watchAd(context)
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              icon: adService.isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('🎬', style: TextStyle(fontSize: 16)),
              label: const Text(
                'Reklam İzle',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  void _watchAd(BuildContext context) async {
    final adService = Provider.of<AdService>(context, listen: false);
    final mechanicsService = Provider.of<GameMechanicsService>(context, listen: false);

    final success = await adService.watchAdForLife(
      onLifeEarned: () {
        mechanicsService.earnLifeFromAd();
        onLifeEarned?.call();
      },
      onAdClosed: () {
        if (context.mounted) {
          Navigator.pop(context);
        }
      },
    );

    if (!success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Reklam şu anda yüklenemiyor. Lütfen daha sonra tekrar deneyin.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }
}

/// Can bittiğinde dialog göster
Future<void> showWatchAdForLifeDialog(
  BuildContext context, {
  VoidCallback? onLifeEarned,
  VoidCallback? onCancel,
}) async {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => WatchAdForLifeDialog(
      onLifeEarned: onLifeEarned,
      onCancel: onCancel,
    ),
  );
}

/// Can durumunu kontrol eden ve gerekirse dialog gösteren widget
class LifeCheckWrapper extends StatelessWidget {
  final Widget child;
  final VoidCallback? onNoLives;

  const LifeCheckWrapper({
    super.key,
    required this.child,
    this.onNoLives,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<GameMechanicsService>(
      builder: (context, mechanicsService, _) {
        return child;
      },
    );
  }
}

/// Can göstergesi widget'ı
class LivesIndicator extends StatelessWidget {
  final bool showWatchAdButton;
  final VoidCallback? onWatchAd;

  const LivesIndicator({
    super.key,
    this.showWatchAdButton = true,
    this.onWatchAd,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<GameMechanicsService>(
      builder: (context, mechanicsService, child) {
        final currentLives = mechanicsService.currentLives;
        final maxLives = mechanicsService.maxLives;
        final hasLives = mechanicsService.hasLives;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: hasLives
                ? Colors.red.withValues(alpha: 0.2)
                : Colors.grey.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: hasLives ? Colors.red : Colors.grey,
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Can kalpleri
              ...List.generate(maxLives, (index) {
                final isFilled = index < currentLives;
                return Padding(
                  padding: const EdgeInsets.only(right: 2),
                  child: Icon(
                    isFilled ? Icons.favorite : Icons.favorite_border,
                    color: isFilled ? Colors.red : Colors.grey,
                    size: 18,
                  ),
                );
              }),
              const SizedBox(width: 4),
              Text(
                '$currentLives/$maxLives',
                style: TextStyle(
                  color: hasLives ? Colors.white : Colors.grey,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              // Reklam izle butonu
              if (showWatchAdButton && !mechanicsService.isFullLives) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    if (onWatchAd != null) {
                      onWatchAd!();
                    } else {
                      showWatchAdForLifeDialog(context);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('🎬', style: TextStyle(fontSize: 12)),
                        SizedBox(width: 4),
                        Text(
                          '+1',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
