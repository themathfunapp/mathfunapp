import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/family_member.dart';
import '../models/game_mechanics.dart';
import '../services/auth_service.dart';
import '../services/family_service.dart';
import '../models/age_group_selection.dart';

/// Tek cihazda: ebeveyn ve çocuk sırayla aynı soruyu cevaplar; skor aile liderliğine yansır.
class FamilyDuelRaceScreen extends StatefulWidget {
  final VoidCallback onBack;

  /// Harita / bölge seçiminde dolu gelirse konu ekranı atlanır.
  final TopicType? presetTopic;

  const FamilyDuelRaceScreen({
    super.key,
    required this.onBack,
    this.presetTopic,
  });

  @override
  State<FamilyDuelRaceScreen> createState() => _FamilyDuelRaceScreenState();
}

class _FamilyDuelRaceScreenState extends State<FamilyDuelRaceScreen> {
  static const int _totalRounds = 5;
  static const AgeGroupSelection _ageGroup = AgeGroupSelection.elementary;

  final math.Random _random = math.Random();

  int _step = 0; // 0 çocuk, 1 konu, 2 oyun, 3 özet
  FamilyMember? _child;
  TopicType? _topic;

  Map<String, dynamic>? _question;
  int _roundIndex = 0;
  bool _parentTurn = true;
  dynamic _parentPick;
  dynamic _childPick;
  int _parentCorrect = 0;
  int _childCorrect = 0;
  bool _saving = false;

  static const List<TopicType> _duelTopics = [
    TopicType.counting,
    TopicType.addition,
    TopicType.subtraction,
    TopicType.multiplication,
    TopicType.division,
    TopicType.geometry,
    TopicType.fractions,
    TopicType.time,
  ];

  String _topicLabel(TopicType t) {
    switch (t) {
      case TopicType.counting:
        return 'Sayma';
      case TopicType.addition:
        return 'Toplama';
      case TopicType.subtraction:
        return 'Çıkarma';
      case TopicType.multiplication:
        return 'Çarpma';
      case TopicType.division:
        return 'Bölme';
      case TopicType.geometry:
        return 'Geometri';
      case TopicType.fractions:
        return 'Kesirler';
      case TopicType.time:
        return 'Saat';
      default:
        return t.name;
    }
  }

  Color _topicColor(TopicType t) {
    final settings = TopicGameManager.getTopicSettings()[t];
    return settings?.color ?? Colors.deepPurple;
  }

  List<FamilyMember> _children(FamilyService f) =>
      f.members.where((m) => !m.isParent).toList();

  void _nextQuestion() {
    if (_topic == null) return;
    setState(() {
      _question = TopicGameManager.generateTopicQuestion(
        _topic!,
        _ageGroup,
        _random,
      );
      _parentTurn = true;
      _parentPick = null;
      _childPick = null;
    });
  }

  bool _isCorrect(dynamic pick) {
    final c = _question?['correctAnswer'];
    if (pick == null || c == null) return false;
    if (pick == c) return true;
    if (pick is num && c is num) {
      return pick.toDouble() == c.toDouble();
    }
    return pick.toString() == c.toString();
  }

  String _questionLine() {
    final q = _question;
    if (q == null) return '';
    final text = q['question'];
    if (text is String && text.isNotEmpty) return text;

    final type = q['type'] as String?;
    switch (type) {
      case 'count_objects':
        final emoji = q['emoji'] as String? ?? '🎯';
        final cnt = ((q['count'] as int?) ?? 3).clamp(1, 16);
        return '${List.filled(cnt, emoji).join(' ')}\nKaç tane?';
      case 'find_missing':
        final seq = q['sequence'] as String? ?? '';
        return 'Hangi sayı eksik: $seq';
      case 'whats_next':
        final seq = q['sequence'] as String? ?? '';
        return 'Sonraki sayı: $seq';
      case 'before_after':
        final params = q['questionParams'];
        final n = params is Map ? '${params['number'] ?? '?'}' : '?';
        final key = q['questionKey'] as String? ?? '';
        if (key == 'question_before_number') {
          return "$n'den önce hangi sayı gelir?";
        }
        return "$n'den sonra hangi sayı gelir?";
      default:
        break;
    }
    return 'Soru';
  }

  List<dynamic> _optionList() {
    final o = _question?['options'];
    if (o is List) return o;
    return [];
  }

  Future<void> _finishGame() async {
    if (_child == null || _topic == null) return;
    setState(() => _saving = true);
    final family = context.read<FamilyService>();
    await family.recordFamilyDuelResult(
      childUserId: _child!.userId,
      topicKey: _topic!.name,
      parentCorrect: _parentCorrect,
      childCorrect: _childCorrect,
      rounds: _totalRounds,
    );
    if (!mounted) return;
    setState(() {
      _saving = false;
      _step = 3;
    });
  }

  void _onOptionTap(dynamic value) {
    if (_question == null) return;
    setState(() {
      if (_parentTurn) {
        _parentPick = value;
        if (_isCorrect(value)) _parentCorrect++;
        _parentTurn = false;
      } else {
        _childPick = value;
        if (_isCorrect(value)) _childCorrect++;
        _roundIndex++;
        if (_roundIndex >= _totalRounds) {
          _finishGame();
        } else {
          _nextQuestion();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final parentName =
        auth.currentUser?.displayName ?? auth.currentUser?.username ?? 'Ebeveyn';

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2C3E50), Color(0xFF6C3483)],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: widget.onBack,
                    ),
                    Expanded(
                      child: Text(
                        _step == 2 && _topic != null
                            ? 'Yarış · ${_topicLabel(_topic!)}'
                            : 'Birebir yarış',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
              Expanded(
                child: Consumer<FamilyService>(
                  builder: (context, family, _) {
                    final kids = _children(family);
                    if (kids.isEmpty && _step < 2) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.child_care,
                                  size: 64, color: Colors.white54),
                              const SizedBox(height: 16),
                              const Text(
                                'Önce Ebeveyn Paneli → Aile Oyunu sekmesinden çocuğunuzu ekleyin.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.white70, fontSize: 16),
                              ),
                              const SizedBox(height: 24),
                              FilledButton(
                                onPressed: widget.onBack,
                                child: const Text('Geri'),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    if (_step == 0) {
                      return _buildChildPicker(kids, parentName);
                    }
                    if (_step == 1) {
                      return _buildTopicPicker();
                    }
                    if (_step == 2) {
                      return _buildPlayArea(parentName);
                    }
                    return _buildSummary(parentName);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChildPicker(List<FamilyMember> kids, String parentName) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Merhaba $parentName — yarışacağınız çocuğu seçin.',
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
        const SizedBox(height: 20),
        ...kids.map(
          (c) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Material(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => setState(() {
                  _child = c;
                  final preset = widget.presetTopic;
                  if (preset != null) {
                    _topic = preset;
                    _roundIndex = 0;
                    _parentCorrect = 0;
                    _childCorrect = 0;
                    _step = 2;
                    _nextQuestion();
                  } else {
                    _step = 1;
                  }
                }),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Text('🧒', style: TextStyle(fontSize: 28)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          c.displayName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: Colors.white54),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTopicPicker() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          '${_child?.displayName ?? 'Çocuk'} ile hangi konuda yarışacaksınız?',
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _duelTopics.map((t) {
            final col = _topicColor(t);
            return ActionChip(
              label: Text(_topicLabel(t)),
              backgroundColor: col.withValues(alpha: 0.35),
              labelStyle: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
              side: BorderSide(color: col.withValues(alpha: 0.8)),
              onPressed: () {
                setState(() {
                  _topic = t;
                  _roundIndex = 0;
                  _parentCorrect = 0;
                  _childCorrect = 0;
                  _step = 2;
                });
                _nextQuestion();
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPlayArea(String parentName) {
    if (_saving) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 16),
            Text(
              'Sonuçlar kaydediliyor…',
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
      );
    }

    final childName = _child?.displayName ?? 'Çocuk';
    final turnLabel = _parentTurn ? '👑 $parentName' : '🧒 $childName';
    final opts = _optionList();

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Tur ${_roundIndex + 1} / $_totalRounds',
              style: const TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              'Ebeveyn $_parentCorrect  ·  Çocuk $_childCorrect',
              style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.black26,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'Sıra: $turnLabel',
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          _questionLine(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 24),
        ...opts.map((o) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  foregroundColor: Colors.white,
                ),
                onPressed: () => _onOptionTap(o),
                child: Text(
                  '$o',
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildSummary(String parentName) {
    final winner = _parentCorrect == _childCorrect
        ? 'Berabere!'
        : (_parentCorrect > _childCorrect ? parentName : _child?.displayName ?? 'Çocuk');
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🎉', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 16),
          Text(
            winner == 'Berabere!' ? winner : 'Kazanan: $winner',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Doğru cevaplar — $parentName: $_parentCorrect, ${_child?.displayName ?? ''}: $_childCorrect\n'
            'Aile düello puanları (+10/doğru) liderlik tablosuna eklendi.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, height: 1.4),
          ),
          const SizedBox(height: 32),
          FilledButton(
            onPressed: widget.onBack,
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }
}
