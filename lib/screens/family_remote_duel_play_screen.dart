import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../services/family_remote_duel_service.dart';
import '../services/family_service.dart';
import '../utils/family_duel_question_utils.dart';

/// İki cihaz: Firestore oturumundan aynı sorular; skorlar belgede tutulur.
class FamilyRemoteDuelPlayScreen extends StatefulWidget {
  final String sessionId;
  final VoidCallback onDone;

  const FamilyRemoteDuelPlayScreen({
    super.key,
    required this.sessionId,
    required this.onDone,
  });

  @override
  State<FamilyRemoteDuelPlayScreen> createState() => _FamilyRemoteDuelPlayScreenState();
}

class _FamilyRemoteDuelPlayScreenState extends State<FamilyRemoteDuelPlayScreen> {
  bool _busy = false;
  bool _summaryShown = false;
  bool _leaderboardSyncAttempted = false;
  bool _leaderboardSyncing = false;

  Future<void> _maybeSyncLeaderboard(Map<String, dynamic> d) async {
    if (_leaderboardSyncAttempted || _leaderboardSyncing) return;
    if (d['status'] != 'finished') return;
    if (d['leaderboardSynced'] == true) {
      _leaderboardSyncAttempted = true;
      return;
    }

    final auth = context.read<AuthService>();
    final uid = auth.currentUser?.uid;
    final hostUid = d['hostUserId'] as String? ?? '';
    if (uid == null || uid != hostUid) return;

    _leaderboardSyncing = true;
    try {
      final topicKey = d['topicKey'] as String? ?? 'addition';
      final rounds = (decodeQuestionsList(d['questions']).length).clamp(1, 100);
      final rawCounts = (d['correctCounts'] as Map?) ?? const {};
      final counts = <String, int>{
        for (final e in rawCounts.entries) e.key.toString(): (e.value as num?)?.toInt() ?? 0,
      };
      final invitedUserIds = (d['invitedUserIds'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .where((e) => e.isNotEmpty)
          .toList();

      await context.read<FamilyService>().recordRemoteFamilyDuelGroupResult(
            parentUserId: hostUid,
            participantCorrectByUser: counts,
            childUserIds: invitedUserIds,
            topicKey: topicKey,
            rounds: rounds,
          );
      await context.read<FamilyRemoteDuelService>().markLeaderboardSynced(widget.sessionId);
      _leaderboardSyncAttempted = true;
    } catch (e) {
      debugPrint('FamilyRemoteDuelPlayScreen leaderboard sync: $e');
    } finally {
      _leaderboardSyncing = false;
    }
  }

  void _maybeShowSummary(Map<String, dynamic> d) {
    if (_summaryShown) return;
    if (d['status'] != 'finished') return;
    _summaryShown = true;

    final hostName = d['hostDisplayName'] as String? ?? 'Ebeveyn';
    final namesRaw = (d['participantDisplayNames'] as Map?) ?? const {};
    final names = <String, String>{for (final e in namesRaw.entries) e.key.toString(): e.value?.toString() ?? 'Oyuncu'};
    final countsRaw = (d['correctCounts'] as Map?) ?? const {};
    final counts = <String, int>{for (final e in countsRaw.entries) e.key.toString(): (e.value as num?)?.toInt() ?? 0};
    final top = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topScore = top.isEmpty ? 0 : top.first.value;
    final winners = top.where((e) => e.value == topScore).map((e) => names[e.key] ?? 'Oyuncu').toList();
    final winner = winners.length > 1 ? 'Berabere: ${winners.join(', ')}' : 'Kazanan: ${winners.first}';
    final scoreLines = top.map((e) => '${names[e.key] ?? e.key}: ${e.value}').join('\n');

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Text('Düello bitti'),
          content: Text(
            '$winner\n\nDoğru cevaplar\n$scoreLines',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                widget.onDone();
              },
              child: const Text('Tamam'),
            ),
          ],
        ),
      );
    });
  }

  Future<void> _pick(dynamic value, String uid, Map<String, dynamic> d) async {
    if (_busy) return;
    final status = d['status'] as String?;
    if (status != 'active') return;

    final answered = (d['roundAnsweredUserIds'] as List<dynamic>? ?? const [])
        .map((e) => e.toString())
        .toSet();
    if (answered.contains(uid)) return;

    setState(() => _busy = true);
    final ok = await context.read<FamilyRemoteDuelService>().submitAnswer(
          sessionId: widget.sessionId,
          userId: uid,
          pickedValue: value,
        );
    if (mounted) setState(() => _busy = false);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cevap kaydedilemedi. Tekrar deneyin.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final uid = auth.currentUser?.uid ?? '';
    final svc = context.read<FamilyRemoteDuelService>();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF232526), Color(0xFF414345)],
          ),
        ),
        child: SafeArea(
          child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: svc.sessionStream(widget.sessionId),
            builder: (context, snap) {
              final doc = snap.data;
              final d = doc?.data();
              if (d == null) {
                return const Center(
                  child: CircularProgressIndicator(color: Colors.white54),
                );
              }

              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                _maybeSyncLeaderboard(d);
                _maybeShowSummary(d);
              });

              final status = d['status'] as String? ?? '';
              if (status == 'cancelled') {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Oturum iptal edildi.',
                          style: TextStyle(color: Colors.white, fontSize: 18),
                        ),
                        const SizedBox(height: 20),
                        FilledButton(onPressed: widget.onDone, child: const Text('Çıkış')),
                      ],
                    ),
                  ),
                );
              }

              final hostName = d['hostDisplayName'] as String? ?? 'Ebeveyn';
              final namesRaw = (d['participantDisplayNames'] as Map?) ?? const {};
              final names = <String, String>{
                for (final e in namesRaw.entries) e.key.toString(): e.value?.toString() ?? 'Oyuncu',
              };
              final hostUid = d['hostUserId'] as String? ?? '';
              final invitedUserIds = (d['invitedUserIds'] as List<dynamic>? ?? const [])
                  .map((e) => e.toString())
                  .where((e) => e.isNotEmpty)
                  .toList();
              final participantUserIds = <String>[hostUid, ...invitedUserIds];
              final isHost = uid == hostUid;
              final roundIdx = (d['currentRoundIndex'] as num?)?.toInt() ?? 0;
              final questions = decodeQuestionsList(d['questions']);
              final q = questions.isNotEmpty && roundIdx < questions.length
                  ? questions[roundIdx]
                  : null;

              final countsRaw = (d['correctCounts'] as Map?) ?? const {};
              final counts = <String, int>{
                for (final e in countsRaw.entries) e.key.toString(): (e.value as num?)?.toInt() ?? 0,
              };
              final answeredSet = (d['roundAnsweredUserIds'] as List<dynamic>? ?? const [])
                  .map((e) => e.toString())
                  .toSet();
              final myTurnDone = answeredSet.contains(uid);
              final waitingOther =
                  status == 'active' && myTurnDone && answeredSet.length < participantUserIds.length;

              final line = familyDuelQuestionLine(q);
              final opts = familyDuelOptionList(q);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white70),
                          onPressed: widget.onDone,
                        ),
                        Expanded(
                          child: Text(
                            status == 'finished' ? 'Özet' : 'Uzaktan düello',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 48),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Tur ${roundIdx + 1} / ${questions.length}',
                          style: const TextStyle(color: Colors.white70),
                        ),
                        Text(
                          participantUserIds
                              .map((id) => '${names[id] ?? id} ${counts[id] ?? 0}')
                              .join('  ·  '),
                          style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  if (status == 'active') ...[
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.black26,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          waitingOther
                              ? 'Cevabın kaydedildi; diğer aile üyeleri bekleniyor.'
                              : 'Sıra sende — şıkkını seç.',
                          style: const TextStyle(color: Colors.white, fontSize: 15),
                        ),
                      ),
                    ),
                  ],
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(20),
                      children: [
                        Text(
                          line,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 20),
                        if (status == 'active' && !myTurnDone)
                          ...opts.map(
                            (o) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: FilledButton(
                                onPressed: _busy ? null : () => _pick(o, uid, d),
                                style: FilledButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  backgroundColor: Colors.white.withValues(alpha: 0.18),
                                  foregroundColor: Colors.white,
                                ),
                                child: Text('$o', style: const TextStyle(fontSize: 18)),
                              ),
                            ),
                          ),
                        if (status == 'active' && myTurnDone && waitingOther)
                          const Padding(
                            padding: EdgeInsets.all(24),
                            child: Center(
                              child: CircularProgressIndicator(color: Colors.white54),
                            ),
                          ),
                        if (status == 'finished')
                          Padding(
                            padding: const EdgeInsets.only(top: 32),
                            child: Center(
                              child: FilledButton(
                                onPressed: widget.onDone,
                                child: const Text('Kapat'),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
