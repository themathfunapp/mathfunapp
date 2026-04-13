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

    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          const Icon(Icons.favorite_border, color: Colors.red, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              loc.get('lives_finished'),
              style: const TextStyle(fontSize: 18),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              loc.get('no_lives_message'),
              style: const TextStyle(fontSize: 15, color: Colors.black87, height: 1.35),
            ),
            if (!mechanics.isFullLives && countdown != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF667eea).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.timer_outlined, color: Color(0xFF667eea), size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        loc.get('life_next_countdown').replaceAll('{time}', countdown),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF667eea),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (premium) ...[
              const SizedBox(height: 12),
              Text(
                loc.get('premium_unlimited_lives'),
                style: const TextStyle(color: Colors.deepPurple, fontWeight: FontWeight.w600),
              ),
            ] else if (mechanics.isFullLives) ...[
              const SizedBox(height: 12),
              Text(
                loc.get('life_full_message'),
                style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w600),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(loc.get('ok')),
        ),
        if (!premium && !mechanics.isFullLives)
          TextButton.icon(
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
            icon: const Icon(Icons.play_circle_outline, color: Color(0xFF667eea)),
            label: Text(
              loc.get('watch_ad_gain_life'),
              style: const TextStyle(color: Color(0xFF667eea), fontWeight: FontWeight.w600),
            ),
          ),
      ],
    );
  }
}
