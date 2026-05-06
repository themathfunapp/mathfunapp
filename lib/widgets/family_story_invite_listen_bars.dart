import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_navigator.dart';
import '../localization/app_localizations.dart';
import '../screens/story_mode_screen.dart';
import '../services/family_story_invite_service.dart';

/// Gelen aile hikâye daveti — uygulama genelinde üst bant (MaterialApp builder içinde kullanın).
class FamilyStoryInviteIncomingBar extends StatefulWidget {
  const FamilyStoryInviteIncomingBar({super.key, required this.userId});

  final String userId;

  @override
  State<FamilyStoryInviteIncomingBar> createState() =>
      _FamilyStoryInviteIncomingBarState();
}

class _FamilyStoryInviteIncomingBarState extends State<FamilyStoryInviteIncomingBar> {
  int _countdown = 5;
  bool _countdownVisible = false;
  final Set<String> _openedInviteIds = <String>{};

  bool _isInviteExpired(Map<String, dynamic> m) {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final expiresAtMs = (m['expiresAtMs'] as num?)?.toInt() ?? 0;
    if (expiresAtMs <= 0) {
      final createdAt = m['createdAt'];
      if (createdAt is Timestamp) {
        final fallback =
            createdAt.millisecondsSinceEpoch + FamilyStoryInviteService.inviteTtlMs;
        return fallback <= nowMs;
      }
      return false;
    }
    return expiresAtMs <= nowMs;
  }

  Future<void> _startCountdownAndOpenStory(
    String inviteId, {
    int from = 5,
    String? worldId,
    String? chapterId,
  }) async {
    if (_openedInviteIds.contains(inviteId)) return;
    _openedInviteIds.add(inviteId);
    _countdown = from;
    _countdownVisible = true;
    if (mounted) setState(() {});
    while (_countdown > 0 && mounted) {
      await Future<void>.delayed(const Duration(seconds: 1));
      if (!mounted) return;
      _countdown -= 1;
      if (_countdown > 0) {
        setState(() {});
      }
    }
    _countdownVisible = false;
    if (mounted) setState(() {});
    if (!mounted) return;
    final nav = appRootNavigatorKey.currentState;
    if (nav == null) return;
    await nav.push<void>(
      MaterialPageRoute<void>(
        builder: (ctx) => StoryModeScreen(
          initialWorldId: worldId,
          initialChapterId: chapterId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final svc = Provider.of<FamilyStoryInviteService>(context, listen: false);
    final loc = AppLocalizations.of(context);
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: svc.recipientInvitesStream(widget.userId),
      builder: (context, snap) {
        if (!snap.hasData) return const SizedBox.shrink();
        final pending = snap.data!.docs
            .where((d) {
              final m = d.data();
              final status = (m['status'] as String?) ?? '';
              if (status != 'pending' && status != 'accepted') return false;
              final expired = _isInviteExpired(m);
              if (status == 'pending' && expired) {
                unawaited(svc.expireInviteIfNeeded(d.id));
              }
              return !expired;
            })
            .toList();
        if (pending.isEmpty) return const SizedBox.shrink();

        final doc = pending.first;
        final m = doc.data();
        final from = m['fromDisplayName'] as String? ?? 'Ailen';
        final wKey = m['worldNameKey'] as String? ?? '';
        final cKey = m['chapterNameKey'] as String? ?? '';
        final worldId = m['worldId'] as String?;
        final chapterId = m['chapterId'] as String?;
        final place = (wKey.isNotEmpty && cKey.isNotEmpty)
            ? '${loc.get(wKey)} · ${loc.get(cKey)}'
            : '';
        final line = place.isEmpty
            ? loc.get('family_story_invite_incoming_short').replaceAll('{0}', from)
            : loc
                .get('family_story_invite_incoming')
                .replaceAll('{0}', from)
                .replaceAll('{1}', place);
        final sessionId = (m['sessionId'] as String?) ?? '';

        Widget buildBar({String sessionStatus = 'pending', int? sessionStartAtMs}) {
          final inviteStatus = (m['status'] as String?) ?? 'pending';
          if ((sessionStatus == 'cancelled' || sessionStatus == 'expired') &&
              (inviteStatus == 'pending' || inviteStatus == 'accepted')) {
            unawaited(svc.cancelInviteForUser(
              inviteId: doc.id,
              actingUserId: widget.userId,
            ));
            return const SizedBox.shrink();
          }
          final startAtMs = ((m['startAtMs'] as num?)?.toInt()) ?? sessionStartAtMs;
          if (inviteStatus == 'accepted' && startAtMs != null) {
            final left =
                ((startAtMs - DateTime.now().millisecondsSinceEpoch) / 1000).ceil();
            if (left <= 0) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                unawaited(_startCountdownAndOpenStory(
                  doc.id,
                  from: 1,
                  worldId: worldId,
                  chapterId: chapterId,
                ));
              });
            } else if (!_countdownVisible) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                unawaited(_startCountdownAndOpenStory(
                  doc.id,
                  from: left.clamp(1, 5),
                  worldId: worldId,
                  chapterId: chapterId,
                ));
              });
            }
          }

          return Container(
            color: const Color(0xFF2d4a3e),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              children: [
                const Icon(Icons.menu_book, color: Colors.lightGreenAccent, size: 22),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        line,
                        style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.2),
                      ),
                      if (_countdownVisible)
                        Text(
                          'Başlıyor: $_countdown',
                          style: const TextStyle(
                            color: Colors.lightGreenAccent,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        )
                      else if (inviteStatus == 'accepted' && startAtMs == null)
                        const Text(
                          'Diğer aile üyeleri bekleniyor...',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: inviteStatus == 'pending'
                      ? () async {
                          final ok = await svc.acceptInvite(doc.id, widget.userId);
                          if (!context.mounted) return;
                          if (!ok) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Davet süresi doldu veya artık geçerli değil.'),
                              ),
                            );
                            return;
                          }
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Kabul edildi. Diğer üyeler bekleniyor...'),
                            ),
                          );
                        }
                      : null,
                  child: Text(
                    loc.get('family_story_invite_open'),
                    style: const TextStyle(color: Colors.lightGreenAccent),
                  ),
                ),
                TextButton(
                  onPressed: inviteStatus == 'pending'
                      ? () => svc.declineInvite(doc.id, widget.userId)
                      : null,
                  child: Text(loc.get('reject'), style: const TextStyle(color: Colors.white70)),
                ),
              ],
            ),
          );
        }

        if (sessionId.isEmpty) return buildBar();
        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: svc.sessionStream(sessionId),
          builder: (context, sessionSnap) {
            if (!sessionSnap.hasData || !sessionSnap.data!.exists) {
              return buildBar();
            }
            final s = sessionSnap.data!.data()!;
            final sessionStatus = (s['status'] as String?) ?? 'pending';
            final sessionStartAtMs = (s['startAtMs'] as num?)?.toInt();
            return buildBar(
              sessionStatus: sessionStatus,
              sessionStartAtMs: sessionStartAtMs,
            );
          },
        );
      },
    );
  }
}

/// Gönderen için hikâye daveti geri bildirimi (reddetme / zaman aşımı).
class FamilyStoryInviteSenderInfoBar extends StatelessWidget {
  const FamilyStoryInviteSenderInfoBar({super.key, required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context) {
    final svc = Provider.of<FamilyStoryInviteService>(context, listen: false);
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: svc.senderUpdatesStream(userId),
      builder: (context, snap) {
        if (!snap.hasData) return const SizedBox.shrink();
        final docs = snap.data!.docs.where((d) {
          final m = d.data();
          final acked = m['senderAckAt'] != null;
          return !acked;
        }).toList()
          ..sort((a, b) {
            final am = a.data();
            final bm = b.data();
            final at = (am['updatedAt'] as Timestamp?)?.millisecondsSinceEpoch ??
                (am['createdAt'] as Timestamp?)?.millisecondsSinceEpoch ??
                0;
            final bt = (bm['updatedAt'] as Timestamp?)?.millisecondsSinceEpoch ??
                (bm['createdAt'] as Timestamp?)?.millisecondsSinceEpoch ??
                0;
            return bt.compareTo(at);
          });
        if (docs.isEmpty) return const SizedBox.shrink();
        final doc = docs.first;
        final m = doc.data();
        final to = m['toDisplayName'] as String? ?? 'Aile üyesi';
        final status = (m['status'] as String?) ?? '';
        final text = status == 'declined'
            ? '$to daveti reddetti.'
            : '$to davetine 90 sn içinde cevap vermedi.';
        return Container(
          color: const Color(0xFF5B2C2C),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.orangeAccent, size: 20),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  text,
                  style: const TextStyle(color: Colors.white, fontSize: 12.5),
                ),
              ),
              TextButton(
                onPressed: () => svc.acknowledgeSenderUpdate(
                  inviteId: doc.id,
                  actingUserId: userId,
                ),
                child: const Text('Tamam', style: TextStyle(color: Colors.white70)),
              ),
            ],
          ),
        );
      },
    );
  }
}
