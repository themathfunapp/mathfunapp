import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../localization/app_localizations.dart';
import '../providers/locale_provider.dart';

/// Çocuklara yönelik animasyonlu oyun çıkış onay diyaloğu.
/// "Oyundan Çıkılsın Mı?" / "İlerleme kaydedilmeyecek" + Hayır/Evet butonları.
class GameExitConfirmDialog extends StatefulWidget {
  final VoidCallback onStay;
  final VoidCallback onExit;
  final Color? themeColor;

  const GameExitConfirmDialog({
    Key? key,
    required this.onStay,
    required this.onExit,
    this.themeColor,
  }) : super(key: key);

  static Future<void> show(
    BuildContext context, {
    required VoidCallback onStay,
    required VoidCallback onExit,
    Color? themeColor,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => GameExitConfirmDialog(
        onStay: () {
          Navigator.pop(ctx);
          onStay();
        },
        onExit: () {
          Navigator.pop(ctx);
          onExit();
        },
        themeColor: themeColor,
      ),
    );
  }

  @override
  State<GameExitConfirmDialog> createState() => _GameExitConfirmDialogState();
}

class _GameExitConfirmDialogState extends State<GameExitConfirmDialog>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;
  late Animation<double> _iconBounceAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _scaleAnim = Tween<double>(begin: 0.3, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    // Keep this animation in a safe [0,1] curve path to avoid web assert
    // in TweenSequence transform with overshooting curves.
    _iconBounceAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.8, end: 1.08), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.08, end: 1), weight: 50),
    ]).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations(
        Provider.of<LocaleProvider>(context, listen: false).locale);
    final color = widget.themeColor ??
        Color.lerp(Colors.orange.shade400, Colors.amber.shade300, 0.5)!;

    return FadeTransition(
      opacity: _fadeAnim,
      child: ScaleTransition(
        scale: _scaleAnim,
        child: Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 28),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color,
                  color.withOpacity(0.85),
                  Color.lerp(color, Colors.orange.shade400, 0.3)!,
                ],
              ),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.5),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Sevimli animasyonlu ikon
                AnimatedBuilder(
                  animation: _iconBounceAnim,
                  builder: (_, __) => Transform.scale(
                    scale: _iconBounceAnim.value,
                    child: Text(
                      '🦊',
                      style: const TextStyle(fontSize: 56),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  loc.get('exit_game_confirm'),
                  style: GoogleFonts.quicksand(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  loc.get('progress_not_saved'),
                  style: GoogleFonts.quicksand(
                    fontSize: 15,
                    color: Colors.white.withOpacity(0.95),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: _buildButton(
                        label: loc.get('no'),
                        emoji: '🎮',
                        isPrimary: true,
                        onTap: widget.onStay,
                        color: color,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildButton(
                        label: loc.get('yes'),
                        emoji: '👋',
                        isPrimary: false,
                        onTap: widget.onExit,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildButton({
    required String label,
    required String emoji,
    required bool isPrimary,
    required VoidCallback onTap,
    required Color color,
  }) {
    return _AnimatedButton(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isPrimary
              ? Colors.white.withOpacity(0.25)
              : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isPrimary ? Colors.white.withOpacity(0.6) : Colors.white,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.quicksand(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isPrimary ? Colors.white : color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnimatedButton extends StatefulWidget {
  final VoidCallback onTap;
  final Widget child;

  const _AnimatedButton({required this.onTap, required this.child});

  @override
  State<_AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<_AnimatedButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnim = Tween<double>(begin: 1, end: 0.92).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTap() {
    _controller.forward();
    Future.delayed(const Duration(milliseconds: 120), () {
      if (mounted) {
        widget.onTap();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _onTap,
      child: AnimatedBuilder(
        animation: _scaleAnim,
        builder: (_, child) => Transform.scale(
          scale: _scaleAnim.value,
          child: child,
        ),
        child: widget.child,
      ),
    );
  }
}
