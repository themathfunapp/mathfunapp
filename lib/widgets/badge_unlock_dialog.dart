import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/badge.dart';
import '../localization/app_localizations.dart';
import '../providers/locale_provider.dart';

class BadgeUnlockDialog extends StatefulWidget {
  final List<BadgeDefinition> badges;
  final VoidCallback onDismiss;

  const BadgeUnlockDialog({
    super.key,
    required this.badges,
    required this.onDismiss,
  });

  @override
  State<BadgeUnlockDialog> createState() => _BadgeUnlockDialogState();

  /// Rozet kazanıldığında dialog göster
  static void show(BuildContext context, List<BadgeDefinition> badges) {
    if (badges.isEmpty) return;

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Badge Unlock',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, animation, secondaryAnimation) {
        return BadgeUnlockDialog(
          badges: badges,
          onDismiss: () => Navigator.of(context).pop(),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return ScaleTransition(
          scale: CurvedAnimation(
            parent: animation,
            curve: Curves.elasticOut,
          ),
          child: child,
        );
      },
    );
  }
}

class _BadgeUnlockDialogState extends State<BadgeUnlockDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;
  int _currentBadgeIndex = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _glowAnimation = Tween<double>(begin: 10, end: 25).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _nextBadge() {
    if (_currentBadgeIndex < widget.badges.length - 1) {
      setState(() {
        _currentBadgeIndex++;
      });
    } else {
      widget.onDismiss();
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = Provider.of<LocaleProvider>(context).locale;
    final localizations = AppLocalizations(locale);
    final badge = widget.badges[_currentBadgeIndex];
    final colors = badge.colors;
    final hasMore = _currentBadgeIndex < widget.badges.length - 1;

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.85,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(colors['primary'] as int).withOpacity(0.95),
                Color(colors['secondary'] as int).withOpacity(0.95),
              ],
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Color(colors['primary'] as int).withOpacity(0.5),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Badge counter
              if (widget.badges.length > 1)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_currentBadgeIndex + 1} / ${widget.badges.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

              const SizedBox(height: 16),

              // Başlık
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('🎉', style: TextStyle(fontSize: 24)),
                  const SizedBox(width: 8),
                  Text(
                    localizations.get('new_badge_unlocked'),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text('🎉', style: TextStyle(fontSize: 24)),
                ],
              ),

              const SizedBox(height: 24),

              // Rozet
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withOpacity(0.5),
                            blurRadius: _glowAnimation.value,
                            spreadRadius: _glowAnimation.value / 3,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          badge.emoji,
                          style: const TextStyle(fontSize: 60),
                        ),
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 24),

              // Rozet adı
              Text(
                localizations.get(badge.nameKey),
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 8),

              // Yıldızlar
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  badge.starCount,
                  (i) => const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 2),
                    child: Icon(Icons.star, color: Colors.white, size: 24),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Açıklama
              Text(
                localizations.get(badge.descriptionKey),
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.9),
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 24),

              // Buton
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _nextBadge,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Color(colors['primary'] as int),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    hasMore 
                        ? '${localizations.get("continue_button")} →'
                        : localizations.get('congratulations'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

