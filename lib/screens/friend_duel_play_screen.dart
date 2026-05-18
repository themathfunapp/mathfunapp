import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../localization/app_localizations.dart';
import '../providers/locale_provider.dart';
import '../services/auth_service.dart';
import '../services/friend_duel_service.dart';
import '../utils/family_duel_question_utils.dart';
import 'friend_duel_topic_screen.dart';

/// İki cihaz: aynı sorular, eşzamanlı rauntlar.
class FriendDuelPlayScreen extends StatefulWidget {
  const FriendDuelPlayScreen({
    super.key,
    required this.sessionId,
    required this.onExit,
  });

  final String sessionId;
  final VoidCallback onExit;

  @override
  State<FriendDuelPlayScreen> createState() => _FriendDuelPlayScreenState();
}

class _FriendDuelPlayScreenState extends State<FriendDuelPlayScreen> {
  Map<String, dynamic>? _lastData;
  bool _submitting = false;
  Timer? _uiTimer;
  Timer? _timeoutPoll;

  @override
  void initState() {
    super.initState();
    _uiTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
    _timeoutPoll = Timer.periodic(const Duration(milliseconds: 800), (_) {
      unawaited(_tickTimeout());
    });
  }

  @override
  void dispose() {
    _uiTimer?.cancel();
    _timeoutPoll?.cancel();
    super.dispose();
  }

  Future<void> _tickTimeout() async {
    if (!mounted || _submitting) return;
    final d = _lastData;
    if (d == null || d['status'] != 'playing') return;
    final uid = context.read<AuthService>().currentUser?.uid;
    if (uid == null) return;
    await context.read<FriendDuelService>().applyRoundTimeoutIfNeeded(
          sessionId: widget.sessionId,
          actingUserId: uid,
        );
  }

  String _myUid() => context.read<AuthService>().currentUser?.uid ?? '';

  bool _isHost(Map<String, dynamic> d) => d['hostUserId'] == _myUid();

  int _myScore(Map<String, dynamic> d) =>
      _isHost(d) ? (d['hostScore'] as num?)?.toInt() ?? 0 : (d['guestScore'] as num?)?.toInt() ?? 0;

  int _theirScore(Map<String, dynamic> d) =>
      _isHost(d) ? (d['guestScore'] as num?)?.toInt() ?? 0 : (d['hostScore'] as num?)?.toInt() ?? 0;

  String _theirName(Map<String, dynamic> d) =>
      _isHost(d)
          ? d['guestDisplayName'] as String? ?? ''
          : d['hostDisplayName'] as String? ?? '';

  bool _alreadyAnswered(Map<String, dynamic> d, int round) {
    final uid = _myUid();
    final answers = d['roundAnswers'] as Map<String, dynamic>? ?? {};
    final roundMap = answers['$round'] as Map<String, dynamic>? ?? {};
    return roundMap.containsKey(uid);
  }

  Future<void> _submit(dynamic pick) async {
    if (_submitting) return;
    final d = _lastData;
    if (d == null || d['status'] != 'playing') return;
    final round = (d['currentRoundIndex'] as num?)?.toInt() ?? 0;
    if (_alreadyAnswered(d, round)) return;

    setState(() => _submitting = true);
    await context.read<FriendDuelService>().submitRoundAnswer(
          sessionId: widget.sessionId,
          userId: _myUid(),
          roundIndex: round,
          pick: pick,
        );
    if (mounted) setState(() => _submitting = false);
  }

  String _prompt(Map<String, dynamic> q, AppLocalizations loc) {
    final key = q['questionKey'] as String?;
    if (key != null) {
      var text = loc.get(key);
      final params = q['questionParams'] as Map<String, dynamic>?;
      if (params != null) {
        for (final e in params.entries) {
          text = text.replaceAll('{${e.key}}', '${e.value}');
        }
      }
      return text;
    }
    if (q['type'] == 'basic_math') {
      return '${q['num1']} ${q['operator']} ${q['num2']} = ?';
    }
    return familyDuelQuestionLine(q, loc);
  }

  List<int> _options(Map<String, dynamic> q) {
    final opts = familyDuelOptionList(q).whereType<int>().toList();
    if (opts.length >= 4) return opts.take(4).toList();
    final answer = q['correctAnswer'] as int? ?? 0;
    final set = <int>{...opts, answer};
    while (set.length < 4) {
      set.add(answer + set.length);
    }
    return set.toList();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations(context.watch<LocaleProvider>().locale);
    final svc = context.read<FriendDuelService>();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1a2980), Color(0xFF26d0ce)],
          ),
        ),
        child: SafeArea(
          child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: svc.sessionStream(widget.sessionId),
            builder: (context, snap) {
              final d = snap.data?.data();
              _lastData = d;
              if (d == null) {
                return const Center(child: CircularProgressIndicator(color: Colors.white));
              }

              final status = d['status'] as String? ?? '';
              if (status == 'finished') {
                return _buildFinished(d, loc);
              }
              if (status == 'topic_pick' || status == 'prep') {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!mounted) return;
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute<void>(
                      builder: (ctx) => FriendDuelTopicScreen(
                        sessionId: widget.sessionId,
                        onBack: () => Navigator.of(ctx).pop(),
                      ),
                    ),
                  );
                });
                return const Center(child: CircularProgressIndicator(color: Colors.white));
              }
              if (status != 'playing') {
                return Center(
                  child: Text(
                    loc.get('friend_duel_session_ended'),
                    style: const TextStyle(color: Colors.white),
                  ),
                );
              }

              final questions = decodeQuestionsList(d['questions']);
              final round = (d['currentRoundIndex'] as num?)?.toInt() ?? 0;
              if (round >= questions.length) {
                return const Center(child: CircularProgressIndicator(color: Colors.white));
              }

              final q = questions[round];
              final deadline = (d['roundDeadlineAtMs'] as num?)?.toInt() ?? 0;
              final timeLeft = deadline <= 0
                  ? 0
                  : ((deadline - DateTime.now().millisecondsSinceEpoch) / 1000)
                      .ceil()
                      .clamp(0, 99);
              final answered = _alreadyAnswered(d, round);
              final options = _options(q);

              return Column(
                children: [
                  _buildHeader(d, round, timeLeft, loc),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF7C4DFF),
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: Text(
                        '🤔 ${_prompt(q, loc)}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.6,
                      physics: const NeverScrollableScrollPhysics(),
                      children: options.map((opt) {
                        return ElevatedButton(
                          onPressed: answered || _submitting ? null : () => _submit(opt),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF1a2980),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(
                            '$opt',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  if (answered)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        loc.get('friend_duel_waiting_opponent'),
                        style: const TextStyle(color: Colors.white70),
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

  Widget _buildHeader(Map<String, dynamic> d, int round, int timeLeft, AppLocalizations loc) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _scoreChip(loc.get('you'), _myScore(d), '👑'),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.amber,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  loc.get('friend_duel_vs_badge'),
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                ),
              ),
              Expanded(
                child: _scoreChip(_theirName(d), _theirScore(d), '🦸'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                '${loc.get('friend_duel_round')} ${round + 1}/${FriendDuelService.roundCount}',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.timer, size: 18, color: Colors.white),
                    const SizedBox(width: 4),
                    Text(
                      '$timeLeft',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _scoreChip(String name, int score, String emoji) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          Text(name, style: const TextStyle(color: Colors.white70, fontSize: 11)),
          Text(
            '$score',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinished(Map<String, dynamic> d, AppLocalizations loc) {
    final my = _myScore(d);
    final their = _theirScore(d);
    final String resultText;
    if (my > their) {
      resultText = loc.get('friend_duel_you_won');
    } else if (my < their) {
      resultText = loc.get('friend_duel_you_lost');
    } else {
      resultText = loc.get('friend_duel_draw');
    }

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              my > their ? '🏆' : (my < their ? '😢' : '🤝'),
              style: const TextStyle(fontSize: 64),
            ),
            const SizedBox(height: 16),
            Text(
              resultText,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _scoreChip(loc.get('you'), my, '👑'),
                _scoreChip(_theirName(d), their, '🦸'),
              ],
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: widget.onExit,
                icon: const Icon(Icons.exit_to_app, color: Colors.white),
                label: Text(
                  loc.get('exit_button'),
                  style: const TextStyle(color: Colors.white),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white54),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => _showRematchDialog(d, loc),
                icon: const Icon(Icons.sports_mma),
                label: Text(loc.get('friend_duel_rematch')),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.black87,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showRematchDialog(Map<String, dynamic> d, AppLocalizations loc) async {
    final choice = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.get('friend_duel_rematch')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.play_arrow, color: Colors.green),
              title: Text(loc.get('friend_duel_continue_game')),
              onTap: () => Navigator.pop(ctx, 'continue'),
            ),
            ListTile(
              leading: const Icon(Icons.category, color: Colors.blue),
              title: Text(loc.get('choose_topic')),
              onTap: () => Navigator.pop(ctx, 'topic'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(loc.get('cancel')),
          ),
        ],
      ),
    );
    if (!mounted || choice == null) return;
    final svc = context.read<FriendDuelService>();
    final uid = _myUid();
    if (choice == 'continue') {
      final ok = await svc.rematchContinue(sessionId: widget.sessionId, userId: uid);
      if (!mounted) return;
      if (ok) setState(() {});
    } else if (choice == 'topic') {
      final ok = await svc.rematchNewTopic(sessionId: widget.sessionId, userId: uid);
      if (!mounted) return;
      if (ok) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(
            builder: (ctx) => FriendDuelTopicScreen(
              sessionId: widget.sessionId,
              onBack: () => Navigator.of(ctx).pop(),
            ),
          ),
        );
      }
    }
  }
}
