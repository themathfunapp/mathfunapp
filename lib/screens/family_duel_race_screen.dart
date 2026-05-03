import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/family_member.dart';
import '../models/game_mechanics.dart';
import '../services/auth_service.dart';
import '../services/family_service.dart';
import 'family_remote_duel_setup_screen.dart';
import '../models/age_group_selection.dart';
import '../utils/family_duel_question_utils.dart';

/// Tek cihazda: ebeveyn ve çocuk sırayla aynı soruyu cevaplar; skor aile liderliğine yansır.
/// İki telefon için: [FamilyRemoteDuelSetupScreen] (Premium, Firestore).
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
  bool _answerLocked = false;
  bool _showAnswerFeedback = false;
  bool _lastAnswerCorrect = false;

  void _handleBackPress() {
    if (_step == 3) {
      setState(() => _step = 1);
      return;
    }
    if (_step == 2) {
      setState(() {
        _question = null;
        _parentPick = null;
        _childPick = null;
        _step = 1;
      });
      return;
    }
    if (_step == 1) {
      widget.onBack();
      return;
    }
    widget.onBack();
  }

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

  String _topicEmoji(TopicType t) {
    switch (t) {
      case TopicType.counting:
        return '🔢';
      case TopicType.addition:
        return '➕';
      case TopicType.subtraction:
        return '➖';
      case TopicType.multiplication:
        return '✖️';
      case TopicType.division:
        return '➗';
      case TopicType.geometry:
        return '📐';
      case TopicType.fractions:
        return '🍰';
      case TopicType.time:
        return '⏰';
      default:
        return '🧠';
    }
  }

  Future<void> _onTopicTap(TopicType topic) async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: const Color(0xFF2A2D5A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        final color = _topicColor(topic);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_topicEmoji(topic)} ${_topicLabel(topic)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Nasıl oynamak istersiniz?',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.82),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 14),
                FilledButton.icon(
                  onPressed: () => Navigator.of(sheetContext).pop('local'),
                  style: FilledButton.styleFrom(
                    backgroundColor: color.withValues(alpha: 0.9),
                    minimumSize: const Size.fromHeight(44),
                  ),
                  icon: const Icon(Icons.phone_android),
                  label: const Text('Bu cihazda birebir başlat'),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () => Navigator.of(sheetContext).pop('remote'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(color: color.withValues(alpha: 0.75)),
                    minimumSize: const Size.fromHeight(44),
                  ),
                  icon: const Icon(Icons.group_add),
                  label: const Text('Aileyi davet et (uzaktan, 10 soru)'),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (!mounted || choice == null) return;
    if (choice == 'local') {
      setState(() {
        _topic = topic;
        _roundIndex = 0;
        _parentCorrect = 0;
        _childCorrect = 0;
        _step = 2;
      });
      _nextQuestion();
      return;
    }

    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (ctx) => FamilyRemoteDuelSetupScreen(
          onBack: () => Navigator.of(ctx).pop(),
          initialTopic: topic,
        ),
      ),
    );
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

  bool _isCorrect(dynamic pick) => familyDuelIsCorrect(_question, pick);

  String _questionLine() => familyDuelQuestionLine(_question);

  List<dynamic> _optionList() => familyDuelOptionList(_question);

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

  Future<void> _onOptionTap(dynamic value) async {
    if (_question == null || _answerLocked || _saving) return;
    final isCorrect = _isCorrect(value);
    final parentTurnNow = _parentTurn;

    setState(() {
      _answerLocked = true;
      _showAnswerFeedback = true;
      _lastAnswerCorrect = isCorrect;
      if (parentTurnNow) {
        _parentPick = value;
      } else {
        _childPick = value;
      }
    });

    await Future<void>.delayed(const Duration(milliseconds: 320));
    if (!mounted) return;

    if (parentTurnNow) {
      setState(() {
        if (isCorrect) _parentCorrect++;
        _parentTurn = false;
        _showAnswerFeedback = false;
        _answerLocked = false;
      });
      return;
    }

    if (isCorrect) {
      _childCorrect++;
    }
    _roundIndex++;
    if (_roundIndex >= _totalRounds) {
      setState(() {
        _showAnswerFeedback = false;
      });
      await _finishGame();
      if (!mounted) return;
      setState(() => _answerLocked = false);
      return;
    }

    setState(() {
      _showAnswerFeedback = false;
      _answerLocked = false;
    });
    _nextQuestion();
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
                      onPressed: _handleBackPress,
                    ),
                    Expanded(
                      child: Text(
                        _step == 2 && _topic != null
                            ? 'Yarış · ${_topicLabel(_topic!)}'
                            : 'Birebir yarış',
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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

                    // Çocuk seçimi adımı kaldırıldı: doğrudan konu seçimine geç.
                    if (_step == 0 && kids.isNotEmpty) {
                      if (_child == null) {
                        _child = kids.first;
                      }
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (!mounted || _step != 0) return;
                        setState(() => _step = 1);
                      });
                      return const Center(
                        child: CircularProgressIndicator(color: Colors.white54),
                      );
                    }

                    Widget page;
                    if (_step == 1) {
                      page = _buildTopicPicker();
                    } else if (_step == 2) {
                      page = _buildPlayArea(parentName);
                    } else {
                      page = _buildSummary(parentName);
                    }
                    return AnimatedSwitcher(
                      duration: const Duration(milliseconds: 280),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      transitionBuilder: (child, animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0.04, 0),
                              end: Offset.zero,
                            ).animate(animation),
                            child: child,
                          ),
                        );
                      },
                      child: KeyedSubtree(
                        key: ValueKey<int>(_step),
                        child: page,
                      ),
            );
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
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white24),
          ),
          child: Text(
            'Merhaba $parentName\nYarışacağınız çocuğu seçin.',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              height: 1.3,
            ),
          ),
        ),
        const SizedBox(height: 20),
        ...kids.asMap().entries.map(
          (entry) => TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: Duration(milliseconds: 260 + (entry.key * 70)),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) => Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, (1 - value) * 10),
                child: child,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Material(
                color: Colors.white.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => setState(() {
                    final c = entry.value;
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
                        Container(
                          width: 42,
                          height: 42,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.22),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            (entry.value.profileEmoji?.trim().isNotEmpty ?? false)
                                ? entry.value.profileEmoji!
                                : '🧒',
                            style: const TextStyle(fontSize: 24),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            entry.value.displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: Colors.white70),
                      ],
                    ),
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
    final childName = _child?.displayName ?? 'Çocuk';
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.2),
                Colors.white.withValues(alpha: 0.08),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white30),
            boxShadow: const [
              BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4)),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Text('🎯', style: TextStyle(fontSize: 26)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$childName ile hangi konuda yarışacaksınız?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Bir konu seç, yarış hemen başlasın!',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Konu Kartları',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.95),
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final crossAxisCount = width < 520 ? 1 : 2;
            final ratio = crossAxisCount == 1 ? 5.0 : 2.8;
            return GridView.builder(
              itemCount: _duelTopics.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: ratio,
              ),
              itemBuilder: (context, index) {
                final t = _duelTopics[index];
                final col = _topicColor(t);
                return TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: Duration(milliseconds: 220 + (index * 70)),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) => Opacity(
                    opacity: value,
                    child: Transform.translate(
                      offset: Offset(0, (1 - value) * 14),
                      child: child,
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => _onTopicTap(t),
                      child: Ink(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              col.withValues(alpha: 0.8),
                              col.withValues(alpha: 0.55),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.55)),
                          boxShadow: [
                            BoxShadow(
                              color: col.withValues(alpha: 0.35),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          child: Row(
                            children: [
                              Container(
                                width: 28,
                                height: 28,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.25),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(_topicEmoji(t), style: const TextStyle(fontSize: 16)),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _topicLabel(t),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white24),
          ),
          child: Text(
            '✨ İpucu: Çocuğun en sevdiği konudan başlarsan yarış daha eğlenceli olur.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.88),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
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
    final progress = (_roundIndex + 1) / _totalRounds;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white24),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Tur ${_roundIndex + 1} / $_totalRounds',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    '👑 $_parentCorrect  ·  🧒 $_childCorrect',
                    style: const TextStyle(
                      color: Colors.amber,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  minHeight: 8,
                  value: progress.clamp(0, 1),
                  backgroundColor: Colors.white24,
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFFD166)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
          decoration: BoxDecoration(
            color: _parentTurn
                ? const Color(0xFF6A4C93).withValues(alpha: 0.55)
                : const Color(0xFF118AB2).withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white24),
          ),
          child: Text(
            'Sıra: $turnLabel',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.16),
                Colors.white.withValues(alpha: 0.08),
              ],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white24),
          ),
          child: Text(
            _questionLine(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(height: 18),
        ...opts.asMap().entries.map((entry) {
          final idx = entry.key;
          final o = entry.value;
          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: Duration(milliseconds: 220 + (idx * 70)),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) => Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, (1 - value) * 10),
                child: child,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.white.withValues(alpha: 0.18),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: const BorderSide(color: Colors.white30),
                    ),
                  ),
                  onPressed: () => unawaited(_onOptionTap(o)),
                  child: Text(
                    '$o',
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
        const SizedBox(height: 8),
        AnimatedOpacity(
          duration: const Duration(milliseconds: 180),
          opacity: _showAnswerFeedback ? 1 : 0,
          child: IgnorePointer(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              decoration: BoxDecoration(
                color: (_lastAnswerCorrect
                        ? const Color(0xFF22C55E)
                        : const Color(0xFFEF4444))
                    .withValues(alpha: 0.28),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: (_lastAnswerCorrect
                          ? const Color(0xFF86EFAC)
                          : const Color(0xFFFCA5A5))
                      .withValues(alpha: 0.85),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _lastAnswerCorrect ? Icons.check_circle : Icons.cancel,
                    color: Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _lastAnswerCorrect ? 'Doğru cevap!' : 'Yanlış cevap',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
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
