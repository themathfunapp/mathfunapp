import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_navigator.dart';
import '../localization/app_localizations.dart';
import '../models/friend_duel_invite.dart';
import '../providers/locale_provider.dart';
import '../utils/friend_duel_invite_flow.dart';
import '../services/auth_service.dart';
import '../services/friend_duel_service.dart';

/// Ana sayfa üstü — bekleyen düello daveti (Firestore, Blaze gerekmez).
class FriendDuelIncomingBar extends StatefulWidget {
  const FriendDuelIncomingBar({super.key});

  @override
  State<FriendDuelIncomingBar> createState() => _FriendDuelIncomingBarState();
}

class _FriendDuelIncomingBarState extends State<FriendDuelIncomingBar> {
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  Future<void> _accept(FriendDuelInvite invite) async {
    await FriendDuelInviteFlow.openInviteeScreen(context, invite: invite);
  }

  Future<void> _decline(FriendDuelInvite invite) async {
    final uid = context.read<AuthService>().currentUser?.uid;
    if (uid == null) return;
    await context.read<FriendDuelService>().declineInvite(invite.id, uid);
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().currentUser;
    if (user == null || user.isGuest) return const SizedBox.shrink();

    final loc = AppLocalizations(context.watch<LocaleProvider>().locale);
    final svc = context.read<FriendDuelService>();

    return StreamBuilder<List<FriendDuelInvite>>(
      stream: svc.incomingInvitesStream(user.uid),
      builder: (context, snap) {
        final invites = snap.data ?? [];
        if (invites.isEmpty) return const SizedBox.shrink();

        final invite = invites.first;
        final sec = invite.secondsRemaining;

        return Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(12),
          color: const Color(0xFFE65100),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                const Text('⚔️', style: TextStyle(fontSize: 24)),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        loc.get('friend_duel_invite_banner')
                            .replaceAll('{name}', invite.fromDisplayName),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        '${loc.get('friend_duel_invite_timer')}: ${sec}s',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 11),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => _decline(invite),
                  child: Text(loc.get('decline'), style: const TextStyle(color: Colors.white70)),
                ),
                FilledButton(
                  onPressed: sec > 0 ? () => _accept(invite) : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.black87,
                  ),
                  child: Text(loc.get('accept')),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
