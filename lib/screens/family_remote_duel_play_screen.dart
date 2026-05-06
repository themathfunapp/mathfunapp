import 'dart:async';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../localization/app_localizations.dart';
import '../providers/locale_provider.dart';
import '../services/auth_service.dart';
import '../services/family_remote_duel_service.dart';
import '../services/family_service.dart';
import '../services/game_mechanics_service.dart';
import '../utils/family_duel_question_utils.dart';

/// İki cihaz: Firestore oturumundan aynı sorular; sırayla cevap (önce host, sonra davetliler).
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

class _FamilyRemoteDuelPlayScreenState extends State<FamilyRemoteDuelPlayScreen>
    with SingleTickerProviderStateMixin {
  bool _busy = false;
  bool _summaryShown = false;
  bool _leaderboardSyncAttempted = false;
  bool _leaderboardSyncing = false;

  Timer? _uiClock;
  Timer? _staleTurnPoll;
  Timer? _answerDeadlineTimer;
  String _answerDeadlineKey = '';

  Map<String, dynamic>? _lastSessionData;
  bool _staleApplying = false;

  late final AnimationController _waitPulse;

  static const List<Color> _optColors = [
    Color(0xFF7C4DFF),
    Color(0xFF26C6DA),
    Color(0xFFFF7043),
    Color(0xFFAB47BC),
    Color(0xFF66BB6A),
    Color(0xFFFFCA28),
  ];

  @override
  void initState() {
    super.initState();
    _waitPulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _uiClock = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
    _staleTurnPoll = Timer.periodic(const Duration(milliseconds: 750), (_) {
      unawaited(_tickStaleTurnIfNeeded());
    });
  }

  @override
  void dispose() {
    _waitPulse.dispose();
    _uiClock?.cancel();
    _staleTurnPoll?.cancel();
    _answerDeadlineTimer?.cancel();
    super.dispose();
  }

  String _sessionPlayerUid(Map<String, dynamic> d, AuthService auth) {
    final parts = FamilyRemoteDuelService.duelParticipantIds(d).toSet();
    final fb = (FirebaseAuth.instance.currentUser?.uid ?? '').trim();
    final app = (auth.currentUser?.uid ?? '').trim();
    if (fb.isNotEmpty && parts.contains(fb)) return fb;
    if (app.isNotEmpty && parts.contains(app)) return app;
    return fb.isNotEmpty ? fb : app;
  }

  Future<void> _tickStaleTurnIfNeeded() async {
    if (!mounted || _staleApplying || _busy) return;
    final d = _lastSessionData;
    if (d == null || d['status'] != 'active') return;
    final auth = context.read<AuthService>();
    final uid = _sessionPlayerUid(d, auth);
    if (uid.isEmpty) return;
    final parts = FamilyRemoteDuelService.duelParticipantIds(d);
    if (!parts.contains(uid)) return;
    final deadline = (d['turnDeadlineAtMs'] as num?)?.toInt() ?? 0;
    if (deadline <= 0 || DateTime.now().millisecondsSinceEpoch <= deadline) return;

    _staleApplying = true;
    try {
      await context.read<FamilyRemoteDuelService>().applyOverdueAnswerIfNeeded(
            sessionId: widget.sessionId,
            actingUserId: uid,
          );
    } finally {
      if (mounted) _staleApplying = false;
    }
  }

  Future<bool> _confirmQuitDuel() async {
    final loc = AppLocalizations(Provider.of<LocaleProvider>(context, listen: false).locale);
    final r = await showDialog<bool>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (ctx) => _RemoteDuelQuitConfirmDialog(loc: loc),
    );
    return r == true;
  }

  Future<void> _handleClosePressed() async {
    if (!await _confirmQuitDuel()) return;

    final d = _lastSessionData;
    final status = d?['status'] as String? ?? '';
    final auth = context.read<AuthService>();
    final fb = (FirebaseAuth.instance.currentUser?.uid ?? '').trim();
    final app = (auth.currentUser?.uid ?? '').trim();
    String? leavingId;
    if (d != null) {
      final parts = FamilyRemoteDuelService.duelParticipantIds(d).toSet();
      if (fb.isNotEmpty && parts.contains(fb)) {
        leavingId = fb;
      } else if (app.isNotEmpty && parts.contains(app)) {
        leavingId = app;
      } else if (fb.isNotEmpty) {
        leavingId = fb;
      } else if (app.isNotEmpty) {
        leavingId = app;
      }
    } else {
      leavingId = fb.isNotEmpty ? fb : (app.isNotEmpty ? app : null);
    }

    if (status == 'active' && leavingId != null && leavingId.isNotEmpty) {
      final ok = await context.read<FamilyRemoteDuelService>().markSessionForfeited(
            sessionId: widget.sessionId,
            leavingUserId: leavingId,
          );
      if (!ok) {
        if (mounted) {
          final loc = AppLocalizations(Provider.of<LocaleProvider>(context, listen: false).locale);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(loc.get('family_remote_duel_forfeit_failed')),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.deepOrange.shade800,
            ),
          );
        }
        return;
      }
    }
    if (!mounted) return;
    widget.onDone();
  }

  List<String> _answerOrder(Map<String, dynamic> d) {
    final host = d['hostUserId'] as String? ?? '';
    final invited = (d['invitedUserIds'] as List<dynamic>? ?? const [])
        .map((e) => e.toString())
        .where((e) => e.isNotEmpty)
        .toList();
    final out = <String>[];
    final seen = <String>{};
    for (final id in <String>[host, ...invited]) {
      if (id.isEmpty || seen.contains(id)) continue;
      seen.add(id);
      out.add(id);
    }
    return out;
  }

  String? _expectedAnswerer(Map<String, dynamic> d) {
    final order = _answerOrder(d);
    final answered = (d['roundAnsweredUserIds'] as List<dynamic>? ?? const [])
        .map((e) => e.toString())
        .toSet();
    for (final id in order) {
      if (!answered.contains(id)) return id;
    }
    return null;
  }

  void _syncAnswerDeadlineTimer(Map<String, dynamic> d, String uid) {
    final status = d['status'] as String? ?? '';
    if (status != 'active') {
      _answerDeadlineTimer?.cancel();
      _answerDeadlineTimer = null;
      _answerDeadlineKey = '';
      return;
    }
    final expected = _expectedAnswerer(d);
    final myTurn = expected != null && expected == uid && uid.isNotEmpty;
    final deadline = (d['turnDeadlineAtMs'] as num?)?.toInt() ?? 0;

    if (!myTurn || deadline <= 0) {
      _answerDeadlineTimer?.cancel();
      _answerDeadlineTimer = null;
      _answerDeadlineKey = '';
      return;
    }

    final answered = (d['roundAnsweredUserIds'] as List<dynamic>? ?? const [])
        .map((e) => e.toString())
        .join(',');
    final key = '${d['currentRoundIndex']}|$answered|$deadline|$expected';
    if (key == _answerDeadlineKey && _answerDeadlineTimer != null) return;
    _answerDeadlineKey = key;
    _answerDeadlineTimer?.cancel();

    final ms = deadline - DateTime.now().millisecondsSinceEpoch;
    if (ms <= 0) {
      _answerDeadlineTimer = null;
      unawaited(_submitPick(FamilyRemoteDuelService.timeoutWrongPick, uid, d));
      return;
    }
    _answerDeadlineTimer = Timer(Duration(milliseconds: ms + 100), () {
      if (mounted) {
        unawaited(_submitPick(FamilyRemoteDuelService.timeoutWrongPick, uid, d));
      }
    });
  }

  Future<void> _maybeSyncLeaderboard(Map<String, dynamic> d) async {
    if (_leaderboardSyncAttempted || _leaderboardSyncing) return;
    if (d['status'] != 'finished') return;
    if (d['forfeit'] == true) {
      _leaderboardSyncAttempted = true;
      return;
    }
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

    final namesRaw = (d['participantDisplayNames'] as Map?) ?? const {};
    final names = <String, String>{
      for (final e in namesRaw.entries) e.key.toString(): e.value?.toString() ?? 'Oyuncu',
    };
    final countsRaw = (d['correctCounts'] as Map?) ?? const {};
    final counts = <String, int>{
      for (final e in countsRaw.entries) e.key.toString(): (e.value as num?)?.toInt() ?? 0,
    };
    final forfeitedBy = d['forfeitedByUserId'] as String? ?? '';
    final isForfeit = d['forfeit'] == true && forfeitedBy.isNotEmpty;

    final top = counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final topScore = top.isEmpty ? 0 : top.first.value;
    final winners =
        top.where((e) => e.value == topScore).map((e) => names[e.key] ?? 'Oyuncu').toList();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final loc = AppLocalizations(Provider.of<LocaleProvider>(context, listen: false).locale);
      final myUid = context.read<AuthService>().currentUser?.uid ?? '';
      var goldGranted = 0;
      if (myUid.isNotEmpty) {
        goldGranted = await context.read<FamilyRemoteDuelService>().claimRemoteDuelWinnerGold(
              sessionId: widget.sessionId,
              userId: myUid,
            );
        if (goldGranted > 0 && mounted) {
          context.read<GameMechanicsService>().addCoins(goldGranted);
        }
      }

      if (!mounted) return;

      String headline;
      if (isForfeit && myUid.isNotEmpty && myUid != forfeitedBy) {
        headline = loc.get('family_remote_duel_forfeit_win');
      } else if (isForfeit && myUid == forfeitedBy) {
        headline = loc.get('family_remote_duel_forfeit_you_left');
      } else if (winners.length > 1) {
        headline = loc.get('family_remote_duel_summary_tie').replaceAll('{names}', winners.join(', '));
      } else {
        headline = loc.get('family_remote_duel_summary_winner').replaceAll('{name}', winners.first);
      }
      String scoreLine(String uidKey, int value) {
        if (value < 0) {
          return '${names[uidKey] ?? uidKey}: —';
        }
        return '${names[uidKey] ?? uidKey}: $value';
      }

      final scoreLines = top.map((e) => scoreLine(e.key, e.value)).join('\n');
      final goldLine = goldGranted > 0
          ? '\n\n${loc.get('family_remote_duel_summary_gold').replaceAll('{n}', '$goldGranted')}'
          : '';

      final isForfeitWin = isForfeit && myUid.isNotEmpty && myUid != forfeitedBy;

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        barrierColor: Colors.black.withValues(alpha: 0.35),
        builder: (ctx) {
          if (isForfeitWin) {
            return _RemoteDuelForfeitWinKidDialog(
              headline: headline,
              summaryTitle: loc.get('family_remote_duel_summary_title'),
              scoresHeading: loc.get('family_remote_duel_summary_scores'),
              scoreLines: scoreLines,
              goldLineText: goldGranted > 0
                  ? loc.get('family_remote_duel_summary_gold').replaceAll('{n}', '$goldGranted')
                  : null,
              okLabel: loc.get('family_remote_duel_summary_ok'),
              onOk: () {
                Navigator.of(ctx).pop();
                widget.onDone();
              },
            );
          }
          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 24, 22, 18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🏆', style: TextStyle(fontSize: 48)),
                    const SizedBox(height: 8),
                    Text(
                      loc.get('family_remote_duel_summary_title'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF5E35B1),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      '$headline\n\n${loc.get('family_remote_duel_summary_scores')}\n$scoreLines$goldLine',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.4,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 22),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF7C4DFF),
                        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        widget.onDone();
                      },
                      child: Text(
                        loc.get('family_remote_duel_summary_ok'),
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    });
  }

  Future<void> _submitPick(dynamic value, String uid, Map<String, dynamic> d) async {
    if (_busy) return;
    final status = d['status'] as String?;
    if (status != 'active') return;

    final expected = _expectedAnswerer(d);
    if (expected != uid) return;

    _answerDeadlineTimer?.cancel();
    _answerDeadlineTimer = null;

    setState(() => _busy = true);
    final ok = await context.read<FamilyRemoteDuelService>().submitAnswer(
          sessionId: widget.sessionId,
          userId: uid,
          pickedValue: value,
        );
    if (mounted) setState(() => _busy = false);
    if (!ok && mounted) {
      final loc = AppLocalizations(Provider.of<LocaleProvider>(context, listen: false).locale);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loc.get('family_remote_duel_answer_failed')),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.deepPurple,
        ),
      );
    }
  }

  int _secondsLeftOnDeadline(Map<String, dynamic> d) {
    final deadline = (d['turnDeadlineAtMs'] as num?)?.toInt() ?? 0;
    if (deadline <= 0) return 0;
    final s = ((deadline - DateTime.now().millisecondsSinceEpoch) / 1000).ceil();
    return s.clamp(0, 60);
  }

  Widget _buildBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF5E35B1),
            Color(0xFFE91E63),
            Color(0xFFFF6F00),
            Color(0xFF00ACC1),
          ],
          stops: [0.0, 0.35, 0.7, 1.0],
        ),
      ),
    );
  }

  Widget _buildTopBar({
    required AppLocalizations loc,
    required String status,
    required int roundIdx,
    required int totalRounds,
    required int myCorrect,
    required VoidCallback onClosePressed,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 4, 12, 8),
      child: Row(
        children: [
          Material(
            color: Colors.white.withValues(alpha: 0.22),
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            child: IconButton(
              icon: const Icon(Icons.close_rounded, color: Colors.white),
              onPressed: onClosePressed,
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('⚔️', style: TextStyle(fontSize: 20)),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        status == 'finished'
                            ? loc.get('family_remote_duel_play_summary')
                            : loc.get('family_remote_duel_play_ribbon'),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          shadows: [
                            Shadow(
                              color: Colors.black.withValues(alpha: 0.25),
                              offset: const Offset(0, 2),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _pill(
                      child: Text(
                        loc
                            .get('family_remote_duel_round')
                            .replaceAll('{current}', '${roundIdx + 1}')
                            .replaceAll('{total}', '$totalRounds'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                    const SizedBox(width: 10),
                    _pill(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('⭐', style: TextStyle(fontSize: 14)),
                          const SizedBox(width: 4),
                          Text(
                            loc.get('family_remote_duel_your_correct').replaceAll('{n}', '$myCorrect'),
                            style: const TextStyle(
                              color: Color(0xFFFFF59D),
                              fontWeight: FontWeight.w900,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      color: Colors.black.withValues(alpha: 0.18),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _pill({required Widget child, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
      ),
      child: child,
    );
  }

  Widget _statusCard({
    required AppLocalizations loc,
    required bool myTurn,
    required String actingName,
    required int secs,
  }) {
    final urgent = secs <= 3 && secs > 0;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.98, end: 1),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeInOut,
      builder: (context, scale, child) {
        return Transform.scale(scale: scale, child: child);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: myTurn
                ? [const Color(0xFF00C853), const Color(0xFF69F0AE)]
                : [const Color(0xFFFF6D00), const Color(0xFFFFE082)],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.22),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Text(
              myTurn ? '🎯' : '⏳',
              style: const TextStyle(fontSize: 28),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                myTurn
                    ? loc.get('family_remote_duel_turn_you')
                    : loc
                        .get('family_remote_duel_turn_opponent')
                        .replaceAll('{name}', actingName)
                        .replaceAll('{n}', '$secs'),
                style: TextStyle(
                  color: myTurn ? Colors.white : const Color(0xFF4E342E),
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  height: 1.25,
                ),
              ),
            ),
            if (secs > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: urgent ? Colors.red.shade700 : Colors.black.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${secs}s',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: urgent ? 18 : 15,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _waitingForTurn({
    required AppLocalizations loc,
    required String actingName,
    required int secs,
  }) {
    final urgent = secs <= 3 && secs > 0;
    return Column(
      children: [
        AnimatedBuilder(
          animation: _waitPulse,
          builder: (context, child) {
            final t = _waitPulse.value;
            final rot = math.sin(t * math.pi * 2) * 0.08;
            final sc = 0.92 + 0.08 * t;
            return Transform.rotate(
              angle: rot,
              child: Transform.scale(
                scale: sc,
                child: child,
              ),
            );
          },
          child: Container(
            width: 120,
            height: 120,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  Colors.white.withValues(alpha: 0.35),
                  Colors.white.withValues(alpha: 0.12),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.purple.shade900.withValues(alpha: 0.35),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Text('⏳', style: TextStyle(fontSize: 56)),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          loc.get('family_remote_duel_wait_your_turn'),
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w700,
            height: 1.4,
            shadows: [
              Shadow(color: Colors.black26, offset: Offset(0, 1), blurRadius: 4),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
          ),
          child: Text(
            loc
                .get('family_remote_duel_turn_opponent')
                .replaceAll('{name}', actingName)
                .replaceAll('{n}', '$secs'),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: urgent ? const Color(0xFFFFEB3B) : Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final svc = context.read<FamilyRemoteDuelService>();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (didPop) return;
        unawaited(_handleClosePressed());
      },
      child: Scaffold(
      body: Stack(
        children: [
          _buildBackground(),
          SafeArea(
            child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: svc.sessionStream(widget.sessionId),
              builder: (context, snap) {
                final doc = snap.data;
                final d = doc?.data();
                if (d == null) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('🎮', style: TextStyle(fontSize: 48)),
                        const SizedBox(height: 16),
                        const CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        ),
                      ],
                    ),
                  );
                }

                final uid = _sessionPlayerUid(d, auth);

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!mounted) return;
                  _lastSessionData = d;
                  _syncAnswerDeadlineTimer(d, uid);
                  _maybeSyncLeaderboard(d);
                  _maybeShowSummary(d);
                });

                final status = d['status'] as String? ?? '';
                final loc = AppLocalizations(
                  Provider.of<LocaleProvider>(context, listen: false).locale,
                );

                if (status == 'cancelled') {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 20,
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('😢', style: TextStyle(fontSize: 48)),
                            const SizedBox(height: 12),
                            Text(
                              loc.get('family_remote_duel_waiting_cancelled'),
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 20),
                            FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFF7C4DFF),
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                              ),
                              onPressed: widget.onDone,
                              child: Text(loc.get('family_remote_duel_summary_ok')),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                final namesRaw = (d['participantDisplayNames'] as Map?) ?? const {};
                final names = <String, String>{
                  for (final e in namesRaw.entries) e.key.toString(): e.value?.toString() ?? '',
                };

                final roundIdx = (d['currentRoundIndex'] as num?)?.toInt() ?? 0;
                final questions = decodeQuestionsList(d['questions']);
                final q = questions.isNotEmpty && roundIdx < questions.length
                    ? questions[roundIdx]
                    : null;

                final countsRaw = (d['correctCounts'] as Map?) ?? const {};
                final counts = <String, int>{
                  for (final e in countsRaw.entries) e.key.toString(): (e.value as num?)?.toInt() ?? 0,
                };

                final expected = _expectedAnswerer(d);
                final myTurn =
                    status == 'active' && expected != null && expected == uid && uid.isNotEmpty;
                final actingName = expected != null &&
                        (names[expected]?.trim().isNotEmpty ?? false)
                    ? names[expected]!.trim()
                    : '…';

                final line = familyDuelQuestionLine(q, loc);
                final opts = familyDuelOptionList(q);
                final secs = _secondsLeftOnDeadline(d);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildTopBar(
                      loc: loc,
                      status: status,
                      roundIdx: roundIdx,
                      totalRounds: questions.length,
                      myCorrect: counts[uid] ?? 0,
                      onClosePressed: () => unawaited(_handleClosePressed()),
                    ),
                    if (status == 'active')
                      _statusCard(
                        loc: loc,
                        myTurn: myTurn,
                        actingName: actingName,
                        secs: secs,
                      ),
                    if (status == 'active') const SizedBox(height: 12),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                        child: Container(
                          color: Colors.white.withValues(alpha: 0.12),
                          child: ListView(
                            padding: const EdgeInsets.fromLTRB(20, 22, 20, 28),
                            children: [
                              if (status == 'active' && myTurn) ...[
                                Container(
                                  padding: const EdgeInsets.all(18),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(22),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.deepPurple.withValues(alpha: 0.2),
                                        blurRadius: 16,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      Text(
                                        line,
                                        style: const TextStyle(
                                          color: Color(0xFF4A148C),
                                          fontSize: 21,
                                          fontWeight: FontWeight.w900,
                                          height: 1.3,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          const Text('⏱️', style: TextStyle(fontSize: 22)),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              loc
                                                  .get('family_remote_duel_seconds_hint')
                                                  .replaceAll('{n}', '$secs'),
                                              style: TextStyle(
                                                color: secs <= 3
                                                    ? Colors.red.shade700
                                                    : const Color(0xFF6A1B9A),
                                                fontSize: 17,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 20),
                                ...opts.asMap().entries.map((e) {
                                  final i = e.key;
                                  final o = e.value;
                                  final col = _optColors[i % _optColors.length];
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: Material(
                                      elevation: 6,
                                      shadowColor: col.withValues(alpha: 0.55),
                                      borderRadius: BorderRadius.circular(18),
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(18),
                                        onTap: _busy ? null : () => _submitPick(o, uid, d),
                                        child: Ink(
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                col,
                                                Color.lerp(col, Colors.white, 0.15)!,
                                              ],
                                            ),
                                            borderRadius: BorderRadius.circular(18),
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(vertical: 18),
                                            child: Center(
                                              child: Text(
                                                '$o',
                                                style: const TextStyle(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.w900,
                                                  color: Colors.white,
                                                  shadows: [
                                                    Shadow(
                                                      offset: Offset(0, 1),
                                                      blurRadius: 2,
                                                      color: Colors.black26,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                              ] else if (status == 'active' && !myTurn) ...[
                                _waitingForTurn(
                                  loc: loc,
                                  actingName: actingName,
                                  secs: secs,
                                ),
                              ],
                              if (status == 'finished')
                                Padding(
                                  padding: const EdgeInsets.only(top: 40),
                                  child: Center(
                                    child: FilledButton.icon(
                                      style: FilledButton.styleFrom(
                                        backgroundColor: Colors.white,
                                        foregroundColor: const Color(0xFF5E35B1),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 28,
                                          vertical: 16,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                      ),
                                      onPressed: widget.onDone,
                                      icon: const Icon(Icons.check_circle_rounded),
                                      label: Text(
                                        loc.get('family_remote_duel_summary_ok'),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      ),
    );
  }
}

/// Rakip ayrılınca kazanan çocuk için kutlama diyaloğu (animasyon + renkli arka plan).
class _RemoteDuelForfeitWinKidDialog extends StatefulWidget {
  const _RemoteDuelForfeitWinKidDialog({
    required this.headline,
    required this.summaryTitle,
    required this.scoresHeading,
    required this.scoreLines,
    required this.goldLineText,
    required this.okLabel,
    required this.onOk,
  });

  final String headline;
  final String summaryTitle;
  final String scoresHeading;
  final String scoreLines;
  final String? goldLineText;
  final String okLabel;
  final VoidCallback onOk;

  @override
  State<_RemoteDuelForfeitWinKidDialog> createState() => _RemoteDuelForfeitWinKidDialogState();
}

class _RemoteDuelForfeitWinKidDialogState extends State<_RemoteDuelForfeitWinKidDialog>
    with TickerProviderStateMixin {
  late final AnimationController _party;
  late final AnimationController _bounce;
  late final Animation<double> _entryScale;
  late final Animation<double> _entryFade;

  static const List<String> _floatEmojis = ['🎉', '⭐', '✨', '🌈', '🎈', '💫'];

  @override
  void initState() {
    super.initState();
    _party = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _bounce = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );

    _entryScale = CurvedAnimation(
      parent: _bounce,
      curve: Curves.elasticOut,
    );
    _entryFade = CurvedAnimation(
      parent: _bounce,
      curve: const Interval(0, 0.65, curve: Curves.easeOut),
    );

    _bounce.forward();
  }

  @override
  void dispose() {
    _party.dispose();
    _bounce.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      child: AnimatedBuilder(
        animation: Listenable.merge([_party, _bounce]),
        builder: (context, child) {
          final t = _party.value;
          final hue = (t * 2 * math.pi);
          final c1 = Color.lerp(
            const Color(0xFFFF6EC7),
            const Color(0xFF7C4DFF),
            (math.sin(hue) + 1) / 2,
          )!;
          final c2 = Color.lerp(
            const Color(0xFF00E5FF),
            const Color(0xFFFFEA00),
            (math.cos(hue * 0.9) + 1) / 2,
          )!;
          final c3 = Color.lerp(
            const Color(0xFF76FF03),
            const Color(0xFFFF4081),
            (math.sin(hue * 0.7 + 1) + 1) / 2,
          )!;

          return FadeTransition(
            opacity: _entryFade,
            child: ScaleTransition(
              scale: _entryScale,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 420, maxHeight: size.height * 0.88),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(32),
                  child: Stack(
                    clipBehavior: Clip.hardEdge,
                    children: [
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment(math.sin(hue * 0.4), -1),
                              end: Alignment(-math.cos(hue * 0.35), 1.2),
                              colors: [c1, c2, c3, c1],
                              stops: const [0, 0.35, 0.7, 1],
                            ),
                          ),
                        ),
                      ),
                      Positioned.fill(
                        child: IgnorePointer(
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: List<Widget>.generate(18, (i) {
                              final phase = (i * 0.37) % 1.0;
                              final y = (t + phase) % 1.0;
                              final x = (math.sin((t + i) * math.pi * 2 * 0.15 + i) + 1) / 2;
                              final emoji = _floatEmojis[i % _floatEmojis.length];
                              return Positioned(
                                left: 8 + x * (size.width.clamp(280, 900) - 56),
                                top: -20 + y * 420,
                                child: Opacity(
                                  opacity: (0.35 +
                                          0.4 * math.sin((t + phase) * math.pi * 2))
                                      .clamp(0.0, 1.0),
                                  child: Transform.rotate(
                                    angle: (t + phase) * math.pi * 0.5,
                                    child: Text(emoji, style: const TextStyle(fontSize: 22)),
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),
                      ),
                      Positioned.fill(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(20, 26, 20, 22),
                          child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0.85, end: 1),
                              duration: const Duration(milliseconds: 900),
                              curve: Curves.elasticOut,
                              builder: (context, scale, child) {
                                return Transform.scale(
                                  scale: scale,
                                  child: child,
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withValues(alpha: 0.35),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.amber.withValues(alpha: 0.6),
                                      blurRadius: 24,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: const Text('🏆', style: TextStyle(fontSize: 64)),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              widget.summaryTitle,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: Colors.white.withValues(alpha: 0.95),
                                letterSpacing: 0.5,
                                shadows: const [
                                  Shadow(
                                    color: Colors.black26,
                                    offset: Offset(0, 2),
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(22),
                                border: Border.all(
                                  color: const Color(0xFFFFEA00),
                                  width: 3,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.deepPurple.withValues(alpha: 0.25),
                                    blurRadius: 18,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  ShaderMask(
                                    shaderCallback: (bounds) {
                                      return LinearGradient(
                                        colors: [
                                          const Color(0xFFE040FB),
                                          const Color(0xFF00B0FF),
                                          const Color(0xFF00E676),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ).createShader(bounds);
                                    },
                                    blendMode: BlendMode.srcIn,
                                    child: Text(
                                      widget.headline,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w900,
                                        height: 1.35,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      widget.scoresHeading,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.deepPurple.shade700,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    widget.scoreLines,
                                    textAlign: TextAlign.left,
                                    style: TextStyle(
                                      fontSize: 16,
                                      height: 1.45,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.grey.shade800,
                                    ),
                                  ),
                                  if (widget.goldLineText != null) ...[
                                    const SizedBox(height: 12),
                                    TweenAnimationBuilder<double>(
                                      tween: Tween(begin: 0, end: 1),
                                      duration: const Duration(milliseconds: 700),
                                      curve: Curves.easeOutBack,
                                      builder: (context, v, child) {
                                        final o = v.clamp(0.0, 1.0);
                                        final s = (0.92 + 0.08 * o).clamp(0.85, 1.15);
                                        return Transform.scale(
                                          scale: s,
                                          child: Opacity(opacity: o, child: child),
                                        );
                                      },
                                      child: Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 10,
                                          horizontal: 12,
                                        ),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              Colors.amber.shade400,
                                              Colors.orange.shade400,
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(14),
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              '🪙 ',
                                              style: TextStyle(
                                                fontSize: 22,
                                                shadows: [
                                                  Shadow(
                                                    blurRadius: 4,
                                                    color: Colors.brown.withValues(alpha: 0.4),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Flexible(
                                              child: Text(
                                                widget.goldLineText!,
                                                textAlign: TextAlign.center,
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w900,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            Material(
                              elevation: 8,
                              borderRadius: BorderRadius.circular(22),
                              shadowColor: Colors.purple.shade400,
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(22),
                                  gradient: LinearGradient(
                                    colors: [
                                      const Color(0xFFFF6D00),
                                      const Color(0xFFFFEA00),
                                      const Color(0xFF00E676),
                                    ],
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                  ),
                                ),
                                child: FilledButton(
                                  style: FilledButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 36,
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(22),
                                    ),
                                  ),
                                  onPressed: widget.onOk,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text('🎊', style: TextStyle(fontSize: 22)),
                                      const SizedBox(width: 10),
                                      Text(
                                        widget.okLabel,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w900,
                                          fontSize: 17,
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Çarpı / geri — renkli animasyonlu çıkış onayı.
class _RemoteDuelQuitConfirmDialog extends StatefulWidget {
  const _RemoteDuelQuitConfirmDialog({required this.loc});

  final AppLocalizations loc;

  @override
  State<_RemoteDuelQuitConfirmDialog> createState() => _RemoteDuelQuitConfirmDialogState();
}

class _RemoteDuelQuitConfirmDialogState extends State<_RemoteDuelQuitConfirmDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    _scale = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack);
    _fade = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0, 0.55, curve: Curves.easeOut),
    );
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = widget.loc;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 26, vertical: 24),
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, child) {
          return FadeTransition(
            opacity: _fade,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.86, end: 1).animate(_scale),
              child: child,
            ),
          );
        },
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF7C4DFF),
                Color(0xFFE91E63),
                Color(0xFFFF9800),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.deepPurple.withValues(alpha: 0.45),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(3),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(23),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: 1),
                      duration: const Duration(milliseconds: 700),
                      curve: Curves.elasticOut,
                      builder: (context, bounce, child) {
                        return Transform.scale(
                          scale: 0.9 + 0.1 * bounce.clamp(0.0, 1.0),
                          child: child,
                        );
                      },
                      child: const Text('🤔', style: TextStyle(fontSize: 48)),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      loc.get('family_remote_duel_quit_confirm_title'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF4A148C),
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      loc.get('family_remote_duel_quit_confirm_body'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.4,
                        color: Colors.grey.shade800,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF6A1B9A),
                              side: const BorderSide(color: Color(0xFF7C4DFF), width: 2),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            onPressed: () => Navigator.of(context, rootNavigator: true).pop(false),
                            child: Text(
                              loc.get('family_remote_duel_quit_confirm_stay'),
                              style: const TextStyle(fontWeight: FontWeight.w800),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFF6D00), Color(0xFFFF4081)],
                              ),
                            ),
                            child: FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              onPressed: () => Navigator.of(context, rootNavigator: true).pop(true),
                              child: Text(
                                loc.get('family_remote_duel_quit_confirm_leave'),
                                style: const TextStyle(fontWeight: FontWeight.w900),
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
      ),
    );
  }
}
