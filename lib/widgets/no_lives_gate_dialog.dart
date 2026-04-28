import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../localization/app_localizations.dart';
import '../services/game_mechanics_service.dart';
import '../services/premium_service_export.dart';
import 'watch_ad_dialog.dart';

/// Duolingo tarzı: sonraki can süresi + reklam ile +1 can.
Future<void> showNoLivesGateDialog(BuildContext context) {
  final loc = AppLocalizations.of(context);
  return showDialog<void>(
    context: context,
    builder: (ctx) => _NoLivesGateDialog(loc: loc),
  );
}

String _formatCountdown(Duration d) {
  if (d.isNegative || d == Duration.zero) return '0:00';
  final m = d.inMinutes;
  final s = d.inSeconds.remainder(60);
  return '$m:${s.toString().padLeft(2, '0')}';
}

class _NoLivesGateDialog extends StatefulWidget {
  final AppLocalizations loc;

  const _NoLivesGateDialog({required this.loc});

  @override
  State<_NoLivesGateDialog> createState() => _NoLivesGateDialogState();
}

class _NoLivesGateDialogState extends State<_NoLivesGateDialog> {
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<GameMechanicsService>().tickLifeRegeneration();
      _tick = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        context.read<GameMechanicsService>().tickLifeRegeneration();
        setState(() {});
      });
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = widget.loc;
    final mechanics = context.watch<GameMechanicsService>();
    final premium = context.watch<PremiumService>().isPremium;
    final until = mechanics.timeUntilNextLife;
    final countdown = until != null ? _formatCountdown(until) : null;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.9, end: 1),
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutBack,
        builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFFF0F5), Color(0xFFE9F0FF)],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.purple.withOpacity(0.16),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.85, end: 1.0),
                    duration: const Duration(milliseconds: 900),
                    curve: Curves.easeInOut,
                    builder: (context, value, _) => Transform.scale(
                      scale: value,
                      child: const Text('💖', style: TextStyle(fontSize: 30)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      loc.get('lives_finished'),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF6A1B9A),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                loc.get('no_lives_message'),
                style: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFF37474F),
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (!mechanics.isFullLives && countdown != null) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6C63FF).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.timer_rounded, color: Color(0xFF6C63FF), size: 21),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          loc.get('life_next_countdown').replaceAll('{time}', countdown),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF4A148C),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (premium) ...[
                const SizedBox(height: 10),
                Text(
                  loc.get('premium_unlimited_lives'),
                  style: const TextStyle(
                    color: Color(0xFF7B1FA2),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ] else if (mechanics.isFullLives) ...[
                const SizedBox(height: 10),
                Text(
                  loc.get('life_full_message'),
                  style: const TextStyle(
                    color: Color(0xFF2E7D32),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF8E99F3), width: 1.5),
                        foregroundColor: const Color(0xFF5C6BC0),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 11),
                      ),
                      child: Text(loc.get('ok')),
                    ),
                  ),
                  if (!premium && !mechanics.isFullLives) ...[
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          final nav = Navigator.of(context, rootNavigator: true);
                          Navigator.pop(context);
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (!nav.context.mounted) return;
                            showWatchAdForLifeDialog(
                              nav.context,
                              onLifeEarned: () {
                                if (!nav.context.mounted) return;
                                ScaffoldMessenger.of(nav.context).showSnackBar(
                                  SnackBar(
                                    content: Text(loc.get('life_ad_reward_snackbar')),
                                    backgroundColor: Colors.green,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              },
                            );
                          });
                        },
                        icon: const Icon(Icons.play_circle_fill_rounded, size: 20),
                        label: Text(
                          loc.get('watch_ad_gain_life'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6C63FF),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 10),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
