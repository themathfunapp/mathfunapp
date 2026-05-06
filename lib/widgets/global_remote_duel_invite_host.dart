import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_navigator.dart';
import '../screens/family_remote_duel_play_screen.dart';
import '../screens/family_remote_duel_waiting_screen.dart';
import '../services/auth_service.dart';
import '../services/family_remote_duel_service.dart';
import '../services/push_notification_service.dart';
import 'family_remote_duel_invite_overlay.dart';
import 'family_story_invite_listen_bars.dart';

/// Tüm rotaların üstünde aile hikâye daveti (üst bant), uzaktan düello daveti ve push kuyruğunu işler.
class GlobalRemoteDuelInviteHost extends StatefulWidget {
  const GlobalRemoteDuelInviteHost({super.key, required this.child});

  final Widget child;

  @override
  State<GlobalRemoteDuelInviteHost> createState() => _GlobalRemoteDuelInviteHostState();
}

class _GlobalRemoteDuelInviteHostState extends State<GlobalRemoteDuelInviteHost> {
  late final VoidCallback _queueListener;

  @override
  void initState() {
    super.initState();
    _queueListener = _consumeRemoteDuelNotificationQueue;
    PushNotificationService.instance.remoteDuelInviteQueueVersion.addListener(_queueListener);
    WidgetsBinding.instance.addPostFrameCallback((_) => _consumeRemoteDuelNotificationQueue());
  }

  @override
  void dispose() {
    PushNotificationService.instance.remoteDuelInviteQueueVersion.removeListener(_queueListener);
    super.dispose();
  }

  void _consumeRemoteDuelNotificationQueue() {
    if (!mounted) return;
    final items = PushNotificationService.instance.drainRemoteDuelInvites();
    for (final p in items) {
      unawaited(_openRemoteDuelFromNotification(p));
    }
  }

  Future<void> _openRemoteDuelFromNotification(RemoteDuelInvitePayload payload) async {
    final auth = context.read<AuthService>();
    final uid = auth.currentUser?.uid;
    if (uid == null || uid.isEmpty || auth.currentUser?.isGuest == true) {
      if (!mounted) return;
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        const SnackBar(content: Text('Davet için hesap ile giriş yapın.')),
      );
      return;
    }
    final svc = context.read<FamilyRemoteDuelService>();
    final ok = await svc.acceptInvite(
      inviteId: payload.inviteId,
      acceptingUserId: uid,
      acceptingUserCode: auth.currentUser?.userCode,
    );
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        const SnackBar(
          content: Text(
            'Kabul edilemedi. Premium veya ağ/Firestore kurallarını kontrol edin.',
          ),
        ),
      );
      return;
    }
    await _openRemoteDuelAfterAccept(payload.sessionId);
  }

  Future<void> _openRemoteDuelAfterAccept(String sessionId) async {
    if (sessionId.isEmpty) return;
    final svc = context.read<FamilyRemoteDuelService>();
    final status = await svc.readSessionStatus(sessionId);
    if (!mounted) return;

    NavigatorState? nav = appRootNavigatorKey.currentState;
    if (nav == null) {
      final c = Completer<void>();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!c.isCompleted) c.complete();
      });
      await c.future;
      if (!mounted) return;
      nav = appRootNavigatorKey.currentState;
    }
    if (nav == null) return;

    await _pushRemoteDuelRoute(nav, sessionId, status);
  }

  Future<void> _pushRemoteDuelRoute(
    NavigatorState nav,
    String sessionId,
    String? status,
  ) async {
    if (status == 'active') {
      await nav.push<void>(
        MaterialPageRoute<void>(
          builder: (ctx) => FamilyRemoteDuelPlayScreen(
            sessionId: sessionId,
            onDone: () {
              appRootNavigatorKey.currentState?.popUntil((r) => r.isFirst);
            },
          ),
        ),
      );
    } else {
      await nav.push<void>(
        MaterialPageRoute<void>(
          builder: (ctx) => FamilyRemoteDuelWaitingScreen(
            sessionId: sessionId,
            isHost: false,
            onBack: () => Navigator.of(ctx).pop(),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final user = auth.currentUser;

    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        if (user != null && user.isGuest != true) ...[
          Positioned(
            left: 8,
            right: 8,
            top: MediaQuery.paddingOf(context).top + 2,
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(12),
              clipBehavior: Clip.antiAlias,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FamilyStoryInviteIncomingBar(userId: user.uid),
                  FamilyStoryInviteSenderInfoBar(userId: user.uid),
                ],
              ),
            ),
          ),
          FamilyRemoteDuelInviteOverlay(
            userId: user.uid,
            onAcceptNavigate: _openRemoteDuelAfterAccept,
          ),
        ],
      ],
    );
  }
}
