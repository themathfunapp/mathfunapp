import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../localization/app_localizations.dart';
import '../providers/locale_provider.dart';

/// Çocuklara uygun animasyonlu çıkış diyaloğu
class ChildExitDialog extends StatefulWidget {
  final VoidCallback onStay;
  final VoidCallback onSectionSelect;
  final VoidCallback onExit;
  final Color themeColor;

  const ChildExitDialog({
    Key? key,
    required this.onStay,
    required this.onSectionSelect,
    required this.onExit,
    this.themeColor = Colors.orange,
  }) : super(key: key);

  static Future<void> show(
    BuildContext context, {
    required VoidCallback onStay,
    required VoidCallback onSectionSelect,
    required VoidCallback onExit,
    Color themeColor = Colors.orange,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => ChildExitDialog(
        onStay: () {
          Navigator.pop(ctx);
          onStay();
        },
        onSectionSelect: () {
          Navigator.pop(ctx);
          onSectionSelect();
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
  State<ChildExitDialog> createState() => _ChildExitDialogState();
}

class _ChildExitDialogState extends State<ChildExitDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _scaleAnim = Tween<double>(begin: 0.5, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
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
    final loc = AppLocalizations(Provider.of<LocaleProvider>(context, listen: false).locale);
    final color = widget.themeColor;
    return FadeTransition(
      opacity: _fadeAnim,
      child: ScaleTransition(
        scale: _scaleAnim,
        child: Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.8, end: 1),
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.elasticOut,
                  builder: (_, value, __) => Transform.scale(
                    scale: value,
                    child: Text('🚪', style: GoogleFonts.quicksand(fontSize: 48)),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  loc.exitConfirm,
                  style: GoogleFonts.quicksand(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  loc.whatToDo,
                  style: GoogleFonts.quicksand(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildOptionButton(
                      emoji: '🎮',
                      label: loc.stayBtn,
                      color: Colors.green,
                      onTap: widget.onStay,
                    ),
                    _buildOptionButton(
                      emoji: '📋',
                      label: loc.sectionSelect,
                      color: color,
                      onTap: widget.onSectionSelect,
                    ),
                    _buildOptionButton(
                      emoji: '👋',
                      label: loc.exitBtn,
                      color: Colors.red.shade400,
                      onTap: widget.onExit,
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

  Widget _buildOptionButton({
    required String emoji,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.5), width: 2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(height: 4),
              Text(
                label,
                style: GoogleFonts.quicksand(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
