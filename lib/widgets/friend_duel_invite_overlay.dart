import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_navigator.dart';
import '../localization/app_localizations.dart';
import '../providers/locale_provider.dart';
import '../services/friend_duel_service.dart';
import '../utils/constants.dart';
import '../models/friend_duel_invite.dart';
import '../screens/friend_duel_invite_screen.dart';
import '../utils/friend_duel_invite_flow.dart';

/// Gelen arkadaş düello daveti — 90 sn ekranda kalır.
class FriendDuelInviteOverlay extends StatefulWidget {
  const FriendDuelInviteOverlay({
    super.key,
    required this.userId,
  });

  final String userId;

  @override
  State<FriendDuelInviteOverlay> createState() => _FriendDuelInviteOverlayState();
}

class _FriendDuelInviteOverlayState extends State<FriendDuelInviteOverlay>
    with WidgetsBindingObserver {
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sub;
  Timer? _poll;
  QuerySnapshot<Map<String, dynamic>>? _latest;
  final Set<String> _expiredHandled = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _sub = context.read<FriendDuelService>().pendingInvitesStream(widget.userId).listen(_onSnap);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _sub?.cancel();
    _poll?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      setState(() {});
    }
  }

  void _onSnap(QuerySnapshot<Map<String, dynamic>> snap) {
    _latest = snap;
    _adjustPoll(snap);
    if (mounted) setState(() {});
  }

  void _adjustPoll(QuerySnapshot<Map<String, dynamic>> snap) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final needs = snap.docs.any((d) {
      final m = d.data();
      if (m['status'] != 'pending') return false;
      final exp = (m['expiresAtMs'] as num?)?.toInt() ?? 0;
      return exp > now;
    });
    if (needs) {
      _poll ??= Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() {});
      });
    } else {
      _poll?.cancel();
      _poll = null;
    }
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _visibleInvites() {
    final snap = _latest;
    if (snap == null) return [];
    final now = DateTime.now().millisecondsSinceEpoch;
    return snap.docs.where((d) {
      final m = d.data();
      if (m['status'] != 'pending') return false;
      final exp = (m['expiresAtMs'] as num?)?.toInt() ?? 0;
      if (exp > 0 && now > exp) {
        if (!_expiredHandled.contains(d.id)) {
          _expiredHandled.add(d.id);
          unawaited(context.read<FriendDuelService>().expirePendingInvite(d.id));
        }
        return false;
      }
      return true;
    }).toList();
  }

  Future<void> _openInviteScreen(QueryDocumentSnapshot<Map<String, dynamic>> doc) async {
    final invite = FriendDuelInvite.fromFirestore(doc);
    final nav = appRootNavigatorKey.currentState;
    if (nav == null || !mounted) return;
    await FriendDuelInviteFlow.openInviteeScreen(
      nav.context,
      invite: invite,
    );
  }

  Future<void> _decline(String inviteId) async {
    await context.read<FriendDuelService>().declineInvite(inviteId, widget.userId);
  }

  @override
  Widget build(BuildContext context) {
    final invites = _visibleInvites();
    if (invites.isEmpty) return const SizedBox.shrink();

    final loc = AppLocalizations(context.watch<LocaleProvider>().locale);
    final doc = invites.first;
    final m = doc.data();
    final fromName = m['fromDisplayName'] as String? ?? '';
    final sessionId = m['sessionId'] as String? ?? '';
    final exp = (m['expiresAtMs'] as num?)?.toInt() ?? 0;
    final secondsLeft = exp <= 0
        ? 0
        : ((exp - DateTime.now().millisecondsSinceEpoch) / 1000).ceil().clamp(0, 90);

    return Positioned(
      left: 12,
      right: 12,
      top: MediaQuery.paddingOf(context).top + 8,
      child: Material(
        elevation: 12,
        borderRadius: BorderRadius.circular(16),
        color: const Color(0xFF1a237e),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Text('⚔️', style: TextStyle(fontSize: 28)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      loc.get('friend_duel_invite_banner')
                          .replaceAll('{name}', fromName),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Text(
                    '${secondsLeft}s',
                    style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _decline(doc.id),
                      style: OutlinedButton.styleFrom(foregroundColor: Colors.white70),
                      child: Text(loc.get('decline')),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton(
                      onPressed: sessionId.isEmpty || secondsLeft <= 0
                          ? null
                          : () => _openInviteScreen(doc),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.amber,
                        foregroundColor: Colors.black87,
                      ),
                      child: Text(loc.get('accept')),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
