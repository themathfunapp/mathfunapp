import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../services/family_remote_duel_service.dart';

/// Gelen uzaktan düello daveti — [Stack] içinde [Positioned.fill] ile kullanın.
/// Süre dolunca (sunucu [expiresAtMs]) kart istemcide gizlenir ve tek seferlik süre sonu işlemi tetiklenir.
class FamilyRemoteDuelInviteOverlay extends StatefulWidget {
  final String userId;
  final Future<void> Function(String sessionId) onAcceptNavigate;

  const FamilyRemoteDuelInviteOverlay({
    super.key,
    required this.userId,
    required this.onAcceptNavigate,
  });

  static const double _squareBtn = 88;

  @override
  State<FamilyRemoteDuelInviteOverlay> createState() =>
      _FamilyRemoteDuelInviteOverlayState();
}

class _FamilyRemoteDuelInviteOverlayState extends State<FamilyRemoteDuelInviteOverlay>
    with WidgetsBindingObserver {
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sub;
  Timer? _poll;
  QuerySnapshot<Map<String, dynamic>>? _latest;
  final Set<String> _handledExpireIds = {};
  final Set<String> _expireInFlight = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final svc = context.read<FamilyRemoteDuelService>();
    _sub = svc.pendingInvitesStream(widget.userId).listen(_onInvites);
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
    if (state == AppLifecycleState.resumed) {
      final s = _latest;
      if (s != null) {
        _processExpired(s);
        if (mounted) setState(() {});
      }
    }
  }

  void _onInvites(QuerySnapshot<Map<String, dynamic>> snap) {
    _latest = snap;
    _processExpired(snap);
    _adjustPollTimer(snap);
    if (mounted) setState(() {});
  }

  void _processExpired(QuerySnapshot<Map<String, dynamic>> snap) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final svc = context.read<FamilyRemoteDuelService>();
    for (final d in snap.docs) {
      final m = d.data();
      if ((m['status'] as String?) != 'pending') continue;
      final exp = (m['expiresAtMs'] as num?)?.toInt() ?? 0;
      if (exp <= 0 || now <= exp) continue;
      if (_handledExpireIds.contains(d.id)) continue;
      if (_expireInFlight.contains(d.id)) continue;
      _expireInFlight.add(d.id);
      final name = m['toDisplayName'] as String? ?? '';
      unawaited(_runExpireOnce(svc, d.id, name));
    }
  }

  Future<void> _runExpireOnce(
    FamilyRemoteDuelService svc,
    String inviteId,
    String inviteeDisplayName,
  ) async {
    try {
      final ok = await svc.expirePendingInviteDueToTimeout(
        inviteId: inviteId,
        inviteeUserId: widget.userId,
        inviteeDisplayName: inviteeDisplayName,
      );
      if (!mounted) return;
      if (ok) {
        _handledExpireIds.add(inviteId);
      }
    } finally {
      _expireInFlight.remove(inviteId);
      if (mounted) setState(() {});
    }
  }

  void _adjustPollTimer(QuerySnapshot<Map<String, dynamic>> snap) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final needsPoll = snap.docs.any((d) {
      final m = d.data();
      if ((m['status'] as String?) != 'pending') return false;
      final exp = (m['expiresAtMs'] as num?)?.toInt() ?? 0;
      return exp > 0 && now < exp;
    });
    if (needsPoll) {
      _poll ??= Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        final s = _latest;
        if (s != null) _processExpired(s);
        if (mounted) setState(() {});
      });
    } else {
      _poll?.cancel();
      _poll = null;
    }
  }

  bool _docStillShown(QueryDocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data();
    if ((m['status'] as String?) != 'pending') return false;
    final exp = (m['expiresAtMs'] as num?)?.toInt() ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    if (exp > 0 && now > exp) return false;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final svc = context.read<FamilyRemoteDuelService>();
    final snap = _latest;
    if (snap == null) {
      return const IgnorePointer(
        ignoring: true,
        child: SizedBox.expand(),
      );
    }
    final pending = snap.docs.where(_docStillShown).toList();
    if (pending.isEmpty) {
      return const IgnorePointer(
        ignoring: true,
        child: SizedBox.expand(),
      );
    }

    final doc = pending.first;
    final m = doc.data();
    final from = m['fromDisplayName'] as String? ?? 'Ailen';
    final sessionId = m['sessionId'] as String? ?? '';
    final exp = (m['expiresAtMs'] as num?)?.toInt() ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    final secsLeft = exp > 0 ? ((exp - now) / 1000).ceil().clamp(0, 9999) : null;

    return Positioned.fill(
      child: Material(
        type: MaterialType.transparency,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {},
                child: ColoredBox(
                  color: Colors.black.withValues(alpha: 0.45),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Card(
                  elevation: 14,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.sports_martial_arts,
                            size: 44, color: Color(0xFF5C6BC0)),
                        const SizedBox(height: 12),
                        Text(
                          '$from seni uzaktan düelloya davet etti.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            height: 1.35,
                          ),
                        ),
                        if (secsLeft != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Kalan süre: ~$secsLeft sn',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                        const SizedBox(height: 22),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: FamilyRemoteDuelInviteOverlay._squareBtn,
                              height: FamilyRemoteDuelInviteOverlay._squareBtn,
                              child: FilledButton(
                                onPressed: () async {
                                  final auth = Provider.of<AuthService>(
                                    context,
                                    listen: false,
                                  );
                                  final ok = await svc.acceptInvite(
                                    inviteId: doc.id,
                                    acceptingUserId: widget.userId,
                                    acceptingUserCode:
                                        auth.currentUser?.userCode,
                                  );
                                  if (!context.mounted) return;
                                  if (!ok) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Kabul edilemedi. Premium veya ağ/Firestore kurallarını kontrol edin.',
                                        ),
                                      ),
                                    );
                                    return;
                                  }
                                  if (sessionId.isEmpty) return;
                                  await widget.onAcceptNavigate(sessionId);
                                },
                                style: FilledButton.styleFrom(
                                  backgroundColor: Colors.green.shade600,
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.zero,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: const Text(
                                  'Kabul',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 18),
                            SizedBox(
                              width: FamilyRemoteDuelInviteOverlay._squareBtn,
                              height: FamilyRemoteDuelInviteOverlay._squareBtn,
                              child: OutlinedButton(
                                onPressed: () =>
                                    svc.declineInvite(doc.id, widget.userId),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.red.shade800,
                                  side: BorderSide(
                                      color: Colors.red.shade400, width: 2),
                                  padding: EdgeInsets.zero,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: Text(
                                  'Reddet',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.red.shade800,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
