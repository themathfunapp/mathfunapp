import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../localization/app_localizations.dart';
import '../models/friend_duel_invite.dart';
import '../providers/locale_provider.dart';
import '../services/auth_service.dart';
import '../services/friend_duel_service.dart';
import 'friend_duel_topic_screen.dart';

/// Davet edilen oyuncunun tam ekran davet ekranı (90 sn).
class FriendDuelInviteScreen extends StatefulWidget {
  const FriendDuelInviteScreen({
    super.key,
    required this.invite,
  });

  final FriendDuelInvite invite;

  @override
  State<FriendDuelInviteScreen> createState() => _FriendDuelInviteScreenState();
}

class _FriendDuelInviteScreenState extends State<FriendDuelInviteScreen> {
  Timer? _tick;
  bool _busy = false;
  bool _expireTriggered = false;

  void _expireIfNeeded() {
    if (_expireTriggered) return;
    if (!widget.invite.isExpired && widget.invite.secondsRemaining > 0) {
      return;
    }
    _expireTriggered = true;
    unawaited(
      context.read<FriendDuelService>().expirePendingInvite(widget.invite.id),
    );
  }

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      _expireIfNeeded();
      setState(() {});
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _expireIfNeeded());
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  Future<void> _decline() async {
    final uid = context.read<AuthService>().currentUser?.uid;
    if (uid == null) return;
    await context.read<FriendDuelService>().declineInvite(widget.invite.id, uid);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _accept() async {
    if (_busy || widget.invite.sessionId.isEmpty) return;
    final uid = context.read<AuthService>().currentUser?.uid;
    if (uid == null) return;

    setState(() => _busy = true);
    final ok = await context.read<FriendDuelService>().acceptInvite(
          inviteId: widget.invite.id,
          acceptingUserId: uid,
        );
    if (!mounted) return;
    setState(() => _busy = false);

    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).get('friend_duel_accept_failed')),
        ),
      );
      return;
    }

    await Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (ctx) => FriendDuelTopicScreen(
          sessionId: widget.invite.sessionId,
          onBack: () => Navigator.of(ctx).pop(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations(context.watch<LocaleProvider>().locale);
    final sec = widget.invite.secondsRemaining;
    final expired = sec <= 0 || widget.invite.isExpired;

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1a237e), Color(0xFF3949ab), Color(0xFF26d0ce)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ),
                const Spacer(),
                const Text('⚔️', style: TextStyle(fontSize: 80)),
                const SizedBox(height: 24),
                Text(
                  loc.get('friend_duel_invite_screen_title'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  loc.get('friend_duel_invite_banner')
                      .replaceAll('{name}', widget.invite.fromDisplayName),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Text(
                    expired
                        ? loc.get('friend_duel_expired')
                        : '${loc.get('friend_duel_invite_timer')}: ${sec}s',
                    style: TextStyle(
                      color: expired ? Colors.white70 : Colors.amber,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(flex: 2),
                if (!expired) ...[
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _busy ? null : _accept,
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.amber,
                        foregroundColor: Colors.black87,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        _busy ? '...' : loc.get('accept'),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _decline,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white70,
                      side: const BorderSide(color: Colors.white38),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(loc.get('decline')),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
