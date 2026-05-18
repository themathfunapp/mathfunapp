import 'dart:async';

import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_navigator.dart';
import '../localization/app_localizations.dart';
import '../models/friend_duel_invite.dart';
import '../utils/friend_duel_invite_flow.dart';
import '../services/app_local_notifications.dart';
import '../services/auth_service.dart';
import '../services/friend_duel_service.dart';
import '../services/push_notification_service.dart';
import '../utils/constants.dart';
import 'friend_duel_invite_overlay.dart';

/// Uygulama içi 90 sn davet (Firestore). Push isteğe bağlı (Blaze + Function).
class GlobalFriendDuelInviteHost extends StatefulWidget {
  const GlobalFriendDuelInviteHost({super.key, required this.child});

  final Widget child;

  @override
  State<GlobalFriendDuelInviteHost> createState() => _GlobalFriendDuelInviteHostState();
}

class _GlobalFriendDuelInviteHostState extends State<GlobalFriendDuelInviteHost> {
  late final VoidCallback _queueListener;
  StreamSubscription? _inviteSub;
  final Set<String> _localNotifiedInviteIds = {};
  final Set<String> _autoOpenedInviteIds = {};

  @override
  void initState() {
    super.initState();
    _queueListener = _consumeQueue;
    PushNotificationService.instance.friendDuelInviteQueueVersion
        .addListener(_queueListener);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _consumeQueue();
      _listenInAppInvites();
    });
  }

  @override
  void dispose() {
    PushNotificationService.instance.friendDuelInviteQueueVersion
        .removeListener(_queueListener);
    _inviteSub?.cancel();
    super.dispose();
  }

  void _listenInAppInvites() {
    final uid = context.read<AuthService>().currentUser?.uid;
    if (uid == null || uid.isEmpty) return;
    _inviteSub?.cancel();
    _inviteSub = context.read<FriendDuelService>().incomingInvitesStream(uid).listen(
      (invites) {
        if (invites.isEmpty || kIsWeb) return;
        final first = invites.first;
        if (!_localNotifiedInviteIds.contains(first.id)) {
          _localNotifiedInviteIds.add(first.id);
          unawaited(_showLocalInviteNotification(
            first.fromDisplayName,
            first.id,
            first.sessionId,
          ));
        }
        if (!_autoOpenedInviteIds.contains(first.id)) {
          _autoOpenedInviteIds.add(first.id);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            unawaited(_openInviteScreenForInvitee(first));
          });
        }
      },
    );
  }

  Future<void> _openInviteScreenForInvitee(FriendDuelInvite invite) async {
    final nav = appRootNavigatorKey.currentState;
    if (nav == null) return;
    await FriendDuelInviteFlow.openInviteeScreen(nav.context, invite: invite);
  }

  Future<void> _showLocalInviteNotification(
    String fromName,
    String inviteId,
    String sessionId,
  ) async {
    if (!await PushNotificationService.instance.notificationsEnabled()) return;
    if (sessionId.isEmpty) return;
    final nav = appRootNavigatorKey.currentState;
    final loc = nav != null ? AppLocalizations.of(nav.context) : null;
    final body = fromName.isEmpty
        ? (loc?.get('friend_duel_notif_body_anonymous') ??
            'A friend invited you to a duel.')
        : (loc
                ?.get('friend_duel_notif_body_named')
                .replaceAll('{name}', fromName) ??
            '$fromName invited you to a duel.');
    final title =
        loc?.get('friend_duel_notif_title') ?? 'MathFun — Duel';
    try {
      await AppLocalNotifications.plugin.show(
        91003 + inviteId.hashCode.abs() % 1000,
        title,
        body,
        AppLocalNotifications.friendDuelForegroundDetails(body),
        payload: 'fdd|$inviteId|$sessionId',
      );
    } catch (e) {
      debugPrint('FriendDuel local notification: $e');
    }
  }

  void _consumeQueue() {
    if (!mounted) return;
    final items = PushNotificationService.instance.drainFriendDuelInvites();
    for (final p in items) {
      unawaited(_openFromPush(p));
    }
  }

  Future<void> _openFromPush(FriendDuelInvitePayload payload) async {
    if (payload.sessionId.isEmpty) return;
    final nav = appRootNavigatorKey.currentState;
    if (nav == null) return;
    final invite = FriendDuelInvite(
      id: payload.inviteId,
      fromUserId: '',
      fromDisplayName: '',
      toUserId: '',
      createdAt: DateTime.now(),
      sessionId: payload.sessionId,
      expiresAtMs: DateTime.now().millisecondsSinceEpoch + 90000,
    );
    await FriendDuelInviteFlow.openInviteeScreen(nav.context, invite: invite);
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().currentUser;

    return Stack(
      fit: StackFit.expand,
      clipBehavior: Clip.none,
      children: [
        widget.child,
        if (user != null && user.isGuest != true)
          FriendDuelInviteOverlay(userId: user.uid),
      ],
    );
  }
}
