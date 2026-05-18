import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../localization/app_localizations.dart';
import '../models/friend_duel_invite.dart';
import '../models/friendship.dart';
import '../screens/friend_duel_invite_screen.dart';
import '../screens/friend_duel_waiting_screen.dart';
import '../services/auth_service.dart';
import '../services/friend_duel_service.dart';

/// Blaze gerekmez — Firestore davet + bekleme ekranı.
class FriendDuelInviteFlow {
  FriendDuelInviteFlow._();

  static Future<void> showSendInviteDialog(
    BuildContext context, {
    required Friendship friend,
  }) async {
    final loc = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Text('⚔️ '),
            Expanded(child: Text(loc.get('friend_duel_invite_screen_title'))),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.orange, Colors.deepOrange],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Text('🥊', style: TextStyle(fontSize: 48)),
                  const SizedBox(height: 12),
                  Text(
                    loc
                        .get('friend_duel_invite_confirm_body')
                        .replaceAll('{name}', friend.friendName),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              loc.get('friend_duel_invite_confirm_hint'),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(loc.get('cancel')),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.send),
            label: Text(loc.get('friend_duel_send_invite')),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;
    await sendInviteAndWait(context, friend: friend);
  }

  static Future<void> sendInviteAndWait(
    BuildContext context, {
    required Friendship friend,
  }) async {
    final loc = AppLocalizations.of(context);
    final auth = context.read<AuthService>();
    final user = auth.currentUser;
    if (user == null || user.isGuest) {
      _snack(context, loc.get('friend_duel_requires_account'));
      return;
    }

    final result = await context.read<FriendDuelService>().createInvite(
          hostUserId: user.uid,
          hostDisplayName: user.displayName ?? loc.get('default_player_name'),
          hostUserCode: user.userCode,
          guestUserId: friend.friendId,
          guestDisplayName: friend.friendName,
        );

    if (!context.mounted) return;
    if (result == null) {
      _snack(context, loc.get('friend_duel_invite_send_failed'));
      return;
    }

    _snack(
      context,
      loc
          .get('friend_duel_invite_sent_waiting')
          .replaceAll('{name}', friend.friendName),
    );

    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (ctx) => FriendDuelWaitingScreen(
          sessionId: result.sessionId,
          opponentName: friend.friendName,
          onBack: () => Navigator.of(ctx).pop(),
        ),
      ),
    );
  }

  static Future<void> openInviteeScreen(
    BuildContext context, {
    required FriendDuelInvite invite,
  }) async {
    final loc = AppLocalizations.of(context);
    if (invite.sessionId.isEmpty) {
      _snack(context, loc.get('friend_duel_invite_invalid'));
      return;
    }
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (ctx) => FriendDuelInviteScreen(invite: invite),
      ),
    );
  }

  static void _snack(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }
}
