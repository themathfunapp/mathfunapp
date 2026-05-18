import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../localization/app_localizations.dart';
import '../providers/locale_provider.dart';
import '../services/friend_duel_service.dart';
import 'friend_duel_topic_screen.dart';

/// Davet gönderen: arkadaşın kabulünü bekler.
class FriendDuelWaitingScreen extends StatefulWidget {
  const FriendDuelWaitingScreen({
    super.key,
    required this.sessionId,
    required this.opponentName,
    required this.onBack,
  });

  final String sessionId;
  final String opponentName;
  final VoidCallback onBack;

  @override
  State<FriendDuelWaitingScreen> createState() => _FriendDuelWaitingScreenState();
}

class _FriendDuelWaitingScreenState extends State<FriendDuelWaitingScreen>
    with SingleTickerProviderStateMixin {
  bool _navigated = false;
  bool _expireTriggered = false;
  Timer? _ticker;
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _pulse.dispose();
    super.dispose();
  }

  void _maybeNavigate(String? status) {
    if (_navigated || status == null) return;
    // Yalnızca karşı taraf kabul edince konu seçimine geç (oyun başlamasın).
    if (status == 'topic_pick') {
      _navigated = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(
            builder: (ctx) => FriendDuelTopicScreen(
              sessionId: widget.sessionId,
              onBack: () => Navigator.of(ctx).pop(),
            ),
          ),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations(context.watch<LocaleProvider>().locale);
    final svc = context.read<FriendDuelService>();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1a237e), Color(0xFF3949ab)],
          ),
        ),
        child: SafeArea(
          child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: svc.sessionStream(widget.sessionId),
            builder: (context, snap) {
              final data = snap.data?.data();
              final status = data?['status'] as String?;
              final expiresAtMs = (data?['expiresAtMs'] as num?)?.toInt() ?? 0;
              final secondsLeft = expiresAtMs <= 0
                  ? 0
                  : ((expiresAtMs - DateTime.now().millisecondsSinceEpoch) / 1000)
                      .ceil()
                      .clamp(0, FriendDuelService.inviteTtlSeconds);

              _maybeNavigate(status);

              final inviteId = data?['inviteId'] as String? ?? '';
              if (!_expireTriggered &&
                  secondsLeft <= 0 &&
                  (status == 'waiting_accept' || status == null)) {
                _expireTriggered = true;
                if (inviteId.isNotEmpty) {
                  unawaited(svc.expirePendingInvite(inviteId));
                }
              }

              if (status == 'cancelled' ||
                  status == 'expired' ||
                  status == 'declined' ||
                  (secondsLeft <= 0 && status == 'waiting_accept')) {
                return _buildMessage(
                  loc,
                  status == 'declined'
                      ? loc.get('friend_duel_declined')
                      : loc.get('friend_duel_expired'),
                  Icons.info_outline,
                );
              }

              return Column(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      onPressed: widget.onBack,
                      icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                    ),
                  ),
                  const Spacer(),
                  ScaleTransition(
                    scale: Tween<double>(begin: 0.92, end: 1.08).animate(
                      CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
                    ),
                    child: const Text('⚔️', style: TextStyle(fontSize: 72)),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    loc.get('friend_duel_waiting_title'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.opponentName,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    loc.get('friend_duel_waiting_hint'),
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                  ),
                  if (secondsLeft > 0) ...[
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${loc.get('friend_duel_invite_timer')}: $secondsLeft s',
                        style: const TextStyle(
                          color: Colors.amber,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                  const Spacer(flex: 2),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildMessage(AppLocalizations loc, String text, IconData icon) {
    return Column(
      children: [
        IconButton(
          onPressed: widget.onBack,
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
        ),
        const Spacer(),
        Icon(icon, color: Colors.white70, size: 56),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 18),
          ),
        ),
        const Spacer(flex: 2),
        Padding(
          padding: const EdgeInsets.all(24),
          child: FilledButton(
            onPressed: widget.onBack,
            child: Text(loc.get('ok')),
          ),
        ),
      ],
    );
  }
}
