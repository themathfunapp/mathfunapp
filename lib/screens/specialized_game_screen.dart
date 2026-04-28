import 'dart:async';
import 'dart:math' as math;
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../localization/app_localizations.dart';
import '../providers/locale_provider.dart';
import '../models/game_mechanics.dart';
import '../models/game_mechanics.dart' as GameMechanics;
import '../audio/section_soundscape.dart';
import '../services/audio_service.dart';
import '../services/game_session_report.dart';
import '../services/game_mechanics_service.dart';
import '../services/daily_reward_service.dart';
import 'game_start_screen.dart';
import '../widgets/game_exit_confirm_dialog.dart';

class SpecializedGameScreen extends StatefulWidget {
  final TopicGameSettings topicSettings;
  final AgeGroupSelection ageGroup;
  final String difficulty;
  final String? difficultyDisplay;
  final VoidCallback onBack;

  const SpecializedGameScreen({
    super.key,
    required this.topicSettings,
    required this.ageGroup,
    required this.difficulty,
    this.difficultyDisplay,
    required this.onBack,
  });

  @override
  State<SpecializedGameScreen> createState() => _SpecializedGameScreenState();
}

class _SpecializedGameScreenState extends State<SpecializedGameScreen>
    with TickerProviderStateMixin {
  late final AudioService _audio;
  late List<Map<String, dynamic>> _questions;
  int _currentQuestionIndex = 0;
  int _score = 0;
  int _correctAnswers = 0;
  int _wrongAnswers = 0;
  int _currentStreak = 0;
  int _bestStreak = 0;
  int _totalAnswerTimeSeconds = 0;
  int _fastAnswersCount = 0;
  int _superFastAnswersCount = 0;
  bool _hasReportedCompletion = false;
  bool _isAnswered = false;
  dynamic _selectedAnswer;
  bool _isCorrect = false;
  Timer? _timer;
  int _timeLeft = 30;
  late AnimationController _animationController;
  late Animation<double> _animation;
  late AnimationController _heartController;
  late Animation<double> _heartAnimation;

  late ConfettiController _confettiController;
  late AnimationController _wrongShakeController;
  String? _wrongReactionEmoji;

  bool _isGameOver = false; // Oyun bitti mi?
  bool _gamePaused = false; // Oyun duraklatıldı mı?

  @override
  void initState() {
    super.initState();
    _audio = context.read<AudioService>();
    _questions = [];
    _generateQuestions();
    _confettiController = ConfettiController(
      duration: const Duration(milliseconds: 750),
    );
    _wrongShakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _heartController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _heartAnimation = Tween<double>(begin: 1.0, end: 1.5).animate(
      CurvedAnimation(parent: _heartController, curve: Curves.elasticOut),
    );

    scheduleSectionAmbient(
      context,
      soundscapeForTopicType(widget.topicSettings.topicType),
    );

    _startTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeGrantDailyEntryBonus());
  }

  bool get _isTimeTopic => widget.topicSettings.topicType == GameMechanics.TopicType.time;
  bool get _isCountingTopic => widget.topicSettings.topicType == GameMechanics.TopicType.counting;
  bool get _isAdditionTopic => widget.topicSettings.topicType == GameMechanics.TopicType.addition;
  bool get _isSubtractionTopic => widget.topicSettings.topicType == GameMechanics.TopicType.subtraction;
  bool get _isDivisionTopic => widget.topicSettings.topicType == GameMechanics.TopicType.division;
  bool get _isGeometryTopic => widget.topicSettings.topicType == GameMechanics.TopicType.geometry;
  bool get _isMultiplicationTopic => widget.topicSettings.topicType == GameMechanics.TopicType.multiplication;

  Future<void> _maybeGrantDailyEntryBonus() async {
    if (!mounted) return;
    final mechanics = Provider.of<GameMechanicsService>(context, listen: false);
    final granted = await mechanics.tryGrantDailyTopicGameEntryBonus();
    if (!mounted || !granted) return;

    try {
      final daily = Provider.of<DailyRewardService>(context, listen: false);
      await daily.refresh();
    } catch (_) {}

    if (!mounted) return;
    final loc = AppLocalizations(Provider.of<LocaleProvider>(context, listen: false).locale);
    _confettiController.stop();
    _confettiController.play();
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      transitionDuration: const Duration(milliseconds: 520),
      pageBuilder: (ctx, animation, secondaryAnimation) {
        return Center(
          child: _KidClockDailyRewardDialog(
            loc: loc,
            onOk: () => Navigator.of(ctx).pop(),
          ),
        );
      },
      transitionBuilder: (ctx, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(parent: animation, curve: Curves.elasticOut);
        return FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.65, end: 1.0).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  void _showClockGameHelp(BuildContext context) {
    final loc = AppLocalizations(Provider.of<LocaleProvider>(context, listen: false).locale);
    String titleKey;
    String aboutKey;
    if (_isTimeTopic) {
      titleKey = 'clock_game_help_title';
      aboutKey = 'clock_game_help_about';
    } else if (_isCountingTopic) {
      titleKey = 'counting_game_help_title';
      aboutKey = 'counting_game_help_about';
    } else if (_isSubtractionTopic) {
      titleKey = 'subtraction_game_help_title';
      aboutKey = 'subtraction_game_help_about';
    } else if (_isDivisionTopic) {
      titleKey = 'division_game_help_title';
      aboutKey = 'division_game_help_about';
    } else if (_isGeometryTopic) {
      titleKey = 'geometry_game_help_title';
      aboutKey = 'geometry_game_help_about';
    } else if (_isMultiplicationTopic) {
      titleKey = 'multiplication_game_help_title';
      aboutKey = 'multiplication_game_help_about';
    } else {
      titleKey = 'addition_game_help_title';
      aboutKey = 'addition_game_help_about';
    }
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 22),
        child: _KidTopicHelpDialog(
          loc: loc,
          titleKey: titleKey,
          aboutKey: aboutKey,
          onClose: () => Navigator.of(ctx).pop(),
        ),
      ),
    );
  }

  /// TopicType'a göre lokalize konu adını döndürür.
  String _getLocalizedTopicTitle(AppLocalizations loc) {
    switch (widget.topicSettings.topicType) {
      case GameMechanics.TopicType.counting:
        return loc.get('topic_counting');
      case GameMechanics.TopicType.addition:
        return loc.get('topic_addition');
      case GameMechanics.TopicType.subtraction:
        return loc.get('topic_subtraction');
      case GameMechanics.TopicType.multiplication:
        return loc.get('topic_multiplication');
      case GameMechanics.TopicType.division:
        return loc.get('topic_division');
      case GameMechanics.TopicType.geometry:
        return loc.get('topic_geometry');
      case GameMechanics.TopicType.fractions:
        return loc.get('topic_fractions');
      case GameMechanics.TopicType.decimals:
        return loc.get('topic_decimals');
      case GameMechanics.TopicType.time:
        return loc.get('topic_time');
      case GameMechanics.TopicType.measurements:
        return loc.get('topic_measurement');
      case GameMechanics.TopicType.patterns:
        return loc.get('topic_patterns');
      case GameMechanics.TopicType.algebra:
        return loc.get('topic_algebra');
      case GameMechanics.TopicType.statistics:
        return loc.get('topic_statistics');
      default:
        return widget.topicSettings.title;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animationController.dispose();
    _heartController.dispose();
    _confettiController.dispose();
    _wrongShakeController.dispose();
    _audio.cancelAmbientSync();
    super.dispose();
  }

  void _generateQuestions() {
    final random = math.Random();
    _questions.clear();
    int questionCount = _getQuestionCount();

    for (int i = 0; i < questionCount; i++) {
      final question = GameMechanics.TopicGameManager.generateTopicQuestion(
        widget.topicSettings.topicType,
        widget.ageGroup,
        random,
      );
      _questions.add(Map<String, dynamic>.from(question));
    }
  }

  int _getQuestionCount() {
    switch (widget.difficulty) {
      case 'easy':
      case 'Kolay': return 5;
      case 'medium':
      case 'Orta': return 10;
      case 'hard':
      case 'Zor': return 15;
      default: return 10;
    }
  }

  void _startTimer() {
    if (_isGameOver || _gamePaused) return;

    _timer?.cancel();
    _timeLeft = _getTimeLimit();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeft > 0 && !_isGameOver && !_gamePaused) {
        setState(() => _timeLeft--);
      } else if (_timeLeft == 0 && !_isGameOver && !_gamePaused) {
        _handleTimeout();
      }
    });
  }

  int _getTimeLimit() {
    switch (widget.difficulty) {
      case 'easy':
      case 'Kolay': return 45;
      case 'medium':
      case 'Orta': return 30;
      case 'hard':
      case 'Zor': return 20;
      default: return 30;
    }
  }

  void _handleTimeout() {
    _timer?.cancel();
    _loseLife();
  }

  void _checkAnswer(dynamic answer) {
    if (_isAnswered || _isGameOver || _gamePaused) return;

    _timer?.cancel();
    final currentQuestion = _questions[_currentQuestionIndex];
    setState(() {
      _isAnswered = true;
      _selectedAnswer = answer;
      _isCorrect = answer == currentQuestion['correctAnswer'];
      _wrongReactionEmoji = _isCorrect ? null : '🥺';
    });

    final timeUsed = _getTimeLimit() - _timeLeft;
    _totalAnswerTimeSeconds += timeUsed;
    if (timeUsed <= 5) _superFastAnswersCount++;
    else if (timeUsed <= 10) _fastAnswersCount++;

    if (_isCorrect) {
      _wrongShakeController.reset();
      _score += _calculateScore();
      _correctAnswers++;
      _currentStreak++;
      if (_currentStreak > _bestStreak) _bestStreak = _currentStreak;
      _animationController.forward(from: 0);
      _audio.playAnswerFeedback(true);
      _confettiController.stop();
      _confettiController.play();

      // Biraz bekle ve sonraki soruya geç
      Future.delayed(const Duration(milliseconds: 600), () {
        if (!mounted || _isGameOver) return;
        _nextQuestion();
      });
    } else {
      _wrongAnswers++;
      _currentStreak = 0;
      _audio.playAnswerFeedback(false);
      _wrongShakeController.forward(from: 0);
      _loseLife();
    }
  }

  void _loseLife() {
    _heartController.forward().then((_) => _heartController.reset());

    final mechanicsService = Provider.of<GameMechanicsService>(context, listen: false);
    mechanicsService.onWrongAnswer();

    if (mechanicsService.currentLives <= 0) {
      _gameOver();
    } else {
      setState(() {});
      _gamePaused = true;

      Future.delayed(const Duration(seconds: 1), () {
        if (!mounted || _isGameOver) return;
        setState(() {
          _isAnswered = false;
          _selectedAnswer = null;
          _wrongReactionEmoji = null;
          _gamePaused = false;
        });
        _wrongShakeController.reset();
        _startTimer();
      });
    }
  }

  int _calculateScore() {
    if (_isTimeTopic) return 0;
    return 10;
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _isAnswered = false;
        _selectedAnswer = null;
        _wrongReactionEmoji = null;
      });
      _confettiController.stop();
      _wrongShakeController.reset();
      _startTimer();
    } else {
      _showResults();
    }
  }

  void _gameOver() {
    setState(() {
      _isGameOver = true;
      _gamePaused = true;
    });
    _timer?.cancel();
    _confettiController.stop();
    _reportGameCompletion();
    _showGameOverDialog();
  }

  /// Oyun sonuçlarını rozet ve günlük görevlere bildir
  void _reportGameCompletion() {
    if (!mounted || _hasReportedCompletion) return;
    _hasReportedCompletion = true;
    try {
      final questionsAnswered = _currentQuestionIndex + 1;
      final avgTime = questionsAnswered > 0
          ? _totalAnswerTimeSeconds / questionsAnswered
          : 0.0;

      GameSessionReport.submit(
        context,
        questionsAnswered: questionsAnswered,
        correctAnswers: _correctAnswers,
        wrongAnswers: _wrongAnswers,
        score: _score,
        averageAnswerTimeSeconds: avgTime,
        fastAnswersCount: _fastAnswersCount,
        superFastAnswersCount: _superFastAnswersCount,
        bestCorrectStreakInSession: _bestStreak,
      );
    } catch (e) {
      debugPrint('Report game completion error: $e');
    }
  }

  void _showGameOverDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                widget.topicSettings.color.withOpacity(0.8),
                widget.topicSettings.color,
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Builder(
            builder: (context) {
              final localeProvider = Provider.of<LocaleProvider>(context, listen: true);
              final loc = AppLocalizations(localeProvider.locale);
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '💔 ${loc.get('lives_finished')} 💔',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '${widget.topicSettings.emoji} ${_getLocalizedTopicTitle(loc)}',
                    style: const TextStyle(
                      fontSize: 20,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        _buildStatRow(loc.get('correct_answers'), '$_correctAnswers / ${_currentQuestionIndex + 1}'),
                        if (!_isTimeTopic) ...[
                          const Divider(color: Colors.white24),
                          _buildStatRow(loc.get('score'), '$_score'),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // TEKRAR DENE
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _restartGame();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.2),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        loc.get('try_again'),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),

                  // ANA MENÜ
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        widget.onBack();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.15),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        loc.get('main_menu'),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    ).then((_) {
      if (!_isGameOver) {
        setState(() {
          _gamePaused = false;
        });
      }
    });
  }

  Widget _buildGeometryQuestion(Map<String, dynamic> question, AppLocalizations loc) {
    final type = question['type'] as String? ?? '';
    final correctAnswer = question['correctAnswer'];
    final questionText = question['question'] as String? ?? '';
    final options = question['options'] as List<dynamic>? ?? [];

    switch (type) {
      case 'identify_shapes':
        final shapeToShow = question['shapeToShow'] as String? ??
            (correctAnswer is String ? correctAnswer : '');
        return Column(
          children: [
            Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Text(
                  _getShapeEmoji(shapeToShow),
                  style: const TextStyle(fontSize: 80),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              questionText,
              style: const TextStyle(
                fontSize: 24,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: options.map((option) {
                return _buildShapeOption(option.toString());
              }).toList(),
            ),
          ],
        );

      case 'count_sides':
        final shapeName = question['shapeToShow'] as String? ??
            (correctAnswer is int && correctAnswer == 3 ? 'üçgen' :
            correctAnswer is int && correctAnswer == 4 ? 'kare' : 'beşgen');
        final optionsList = options.map((o) => o as int).toList();

        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white24,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  _getShapeEmoji(shapeName),
                  style: const TextStyle(fontSize: 50),
                ),
              ),
            ),
            const SizedBox(height: 15),
            Text(
              questionText,
              style: const TextStyle(
                fontSize: 20,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 25),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  if (optionsList.length > 1)
                    Row(
                      children: [
                        Expanded(child: _buildCompactNumberOption(optionsList[0])),
                        const SizedBox(width: 8),
                        Expanded(child: _buildCompactNumberOption(optionsList[1])),
                      ],
                    ),
                  if (optionsList.length > 2) const SizedBox(height: 8),
                  if (optionsList.length > 2)
                    Row(
                      children: [
                        Expanded(child: _buildCompactNumberOption(optionsList[2])),
                        if (optionsList.length > 3) const SizedBox(width: 8),
                        if (optionsList.length > 3)
                          Expanded(child: _buildCompactNumberOption(optionsList[3])),
                      ],
                    ),
                ],
              ),
            ),
          ],
        );

      case 'find_area':
        final optionsList = options.map((o) => o as int).toList();
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Text(
                  '⬛',
                  style: const TextStyle(fontSize: 50),
                ),
              ),
            ),
            const SizedBox(height: 15),
            Text(
              questionText,
              style: const TextStyle(
                fontSize: 20,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 25),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  if (optionsList.length > 1)
                    Row(
                      children: [
                        Expanded(child: _buildCompactNumberOption(optionsList[0])),
                        const SizedBox(width: 8),
                        Expanded(child: _buildCompactNumberOption(optionsList[1])),
                      ],
                    ),
                  if (optionsList.length > 2) const SizedBox(height: 8),
                  if (optionsList.length > 2)
                    Row(
                      children: [
                        Expanded(child: _buildCompactNumberOption(optionsList[2])),
                        if (optionsList.length > 3) const SizedBox(width: 8),
                        if (optionsList.length > 3)
                          Expanded(child: _buildCompactNumberOption(optionsList[3])),
                      ],
                    ),
                ],
              ),
            ),
          ],
        );

      default:
        return Center(
          child: Text(
            questionText,
            style: const TextStyle(
              fontSize: 28,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
    }
  }

  Widget _buildFractionQuestion(Map<String, dynamic> question, AppLocalizations loc) {
    final type = question['type'] as String? ?? '';
    final correctAnswer = question['correctAnswer'];
    final questionText = question['question'] as String? ?? '';
    final options = question['options'] as List<dynamic>? ?? [];

    return Column(
      children: [
        if (type == 'identify_fraction')
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: correctAnswer is String
                  ? _buildFractionVisual(correctAnswer)
                  : const Text('?', style: TextStyle(fontSize: 40, color: Colors.white)),
            ),
          ),
        const SizedBox(height: 20),
        Text(
          questionText,
          style: const TextStyle(
            fontSize: 24,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 30),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: options.map((option) {
            return _buildFractionOption(option.toString());
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildTimeQuestion(Map<String, dynamic> question, AppLocalizations loc) {
    final questionText = question['question'] as String? ?? '';
    final options = question['options'] as List<dynamic>? ?? [];
    final correctAnswer = question['correctAnswer'];

    // Eğer soru daha önce karıştırılmamışsa, karıştır ve soruya ekle
    if (!question.containsKey('shuffledOptions')) {
      final shuffled = List<dynamic>.from(options)..shuffle(math.Random());
      question['shuffledOptions'] = shuffled;
    }

    // Karıştırılmış seçenekleri kullan
    final displayOptions = question['shuffledOptions'] as List<dynamic>;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 180,
          height: 180,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: _buildAnalogClock(correctAnswer.toString()),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            questionText,
            style: const TextStyle(
              fontSize: 22,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
            maxLines: 3,
            softWrap: true,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          alignment: WrapAlignment.center,
          children: displayOptions.map((option) {
            return _buildTimeOption(option.toString());
          }).toList(),
        ),
      ],
    );
  }


  Widget _buildAnalogClock(String time) {
    try {
      final parts = time.split(':');
      if (parts.length != 2) return const Icon(Icons.access_time, size: 80);

      final hour = int.tryParse(parts[0]) ?? 0;
      final minute = int.tryParse(parts[1]) ?? 0;

      return CustomPaint(
        painter: _ClockPainter(hour: hour, minute: minute),
        child: Container(),
      );
    } catch (e) {
      return const Icon(Icons.access_time, size: 80);
    }
  }

  Widget _buildShapeOption(String shape) {
    final currentQuestion = _questions[_currentQuestionIndex];
    final correctAnswer = currentQuestion['correctAnswer'];
    final isCorrectAnswer = shape == correctAnswer;
    final isSelected = _selectedAnswer == shape;

    return GestureDetector(
      onTap: () => _checkAnswer(shape),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _isAnswered
              ? (isCorrectAnswer
              ? Colors.green
              : (isSelected ? Colors.red : Colors.white24))
              : Colors.white24,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          children: [
            Text(_getShapeEmoji(shape), style: const TextStyle(fontSize: 40)),
            const SizedBox(height: 8),
            Text(
              _getShapeName(shape),
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNumberOption(int number) {
    final currentQuestion = _questions[_currentQuestionIndex];
    final correctAnswer = currentQuestion['correctAnswer'];
    final isCorrectAnswer = number == correctAnswer;
    final isSelected = _selectedAnswer == number;

    return GestureDetector(
      onTap: () => _checkAnswer(number),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _isAnswered
              ? (isCorrectAnswer
              ? Colors.green
              : (isSelected ? Colors.red : Colors.white24))
              : Colors.white24,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Center(
          child: Text(
            '$number',
            style: const TextStyle(
              fontSize: 24,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFractionOption(String fraction) {
    final currentQuestion = _questions[_currentQuestionIndex];
    final correctAnswer = currentQuestion['correctAnswer'];
    final isCorrectAnswer = fraction == correctAnswer;
    final isSelected = _selectedAnswer == fraction;

    return GestureDetector(
      onTap: () => _checkAnswer(fraction),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _isAnswered
              ? (isCorrectAnswer
              ? Colors.green
              : (isSelected ? Colors.red : Colors.white24))
              : Colors.white24,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Center(
          child: Text(
            fraction,
            style: const TextStyle(
              fontSize: 24,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimeOption(String time) {
    final currentQuestion = _questions[_currentQuestionIndex];
    final correctAnswer = currentQuestion['correctAnswer'];
    final isCorrectAnswer = time == correctAnswer;
    final isSelected = _selectedAnswer == time;

    return GestureDetector(
      onTap: () => _checkAnswer(time),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: _isAnswered
              ? (isCorrectAnswer
              ? Colors.green
              : (isSelected ? Colors.red : Colors.white24))
              : Colors.white24,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Center(
          child: Text(
            time,
            style: const TextStyle(
              fontSize: 18,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFractionVisual(String fraction) {
    try {
      final parts = fraction.split('/');
      if (parts.length != 2) {
        return const Icon(Icons.pie_chart, size: 80, color: Colors.white);
      }

      final numerator = int.tryParse(parts[0]) ?? 1;
      final denominator = int.tryParse(parts[1]) ?? 2;

      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 4,
            runSpacing: 4,
            children: List.generate(denominator, (index) {
              return Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: index < numerator ? Colors.orange : Colors.white24,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white, width: 2),
                ),
              );
            }),
          ),
        ],
      );
    } catch (e) {
      return const Icon(Icons.pie_chart, size: 80, color: Colors.white);
    }
  }

  String _getShapeEmoji(String shape) {
    switch (shape.toLowerCase()) {
      case 'daire': return '🔴';
      case 'kare': return '⬛';
      case 'üçgen': return '🔺';
      case 'dikdörtgen': return '▭';
      case 'beşgen': return '⬟';
      case 'circle': return '🔴';
      case 'square': return '⬛';
      case 'triangle': return '🔺';
      case 'rectangle': return '▭';
      case 'pentagon': return '⬟';
      default: return '🔶';
    }
  }

  String _getShapeName(String shape) {
    switch (shape.toLowerCase()) {
      case 'daire': return 'Daire';
      case 'kare': return 'Kare';
      case 'üçgen': return 'Üçgen';
      case 'dikdörtgen': return 'Dikdörtgen';
      case 'beşgen': return 'Beşgen';
      case 'circle': return 'Daire';
      case 'square': return 'Kare';
      case 'triangle': return 'Üçgen';
      case 'rectangle': return 'Dikdörtgen';
      case 'pentagon': return 'Beşgen';
      default: return shape;
    }
  }

  /// Konu oyunu soru metni — kısa ekranlarda taşmayı önlemek için [Expanded] + çok satır.
  Widget _buildTopicQuestionPill(String leadingEmoji, String questionText) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(leadingEmoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              questionText,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                height: 1.25,
              ),
              textAlign: TextAlign.center,
              maxLines: 6,
              softWrap: true,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (_isAnswered) ...[
            const SizedBox(width: 8),
            Text(
              _isCorrect ? '✅' : '❌',
              style: const TextStyle(fontSize: 22),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuestionContent(Map<String, dynamic> question, AppLocalizations loc) {
    final topicType = widget.topicSettings.topicType;

    switch (topicType) {
      case GameMechanics.TopicType.counting:
        return _buildCountingQuestion(question, loc);
      case GameMechanics.TopicType.geometry:
        return _buildGeometryQuestion(question, loc);
      case GameMechanics.TopicType.fractions:
        return _buildFractionQuestion(question, loc);
      case GameMechanics.TopicType.time:
        return _buildTimeQuestion(question, loc);
      case GameMechanics.TopicType.addition:
      case GameMechanics.TopicType.subtraction:
      case GameMechanics.TopicType.multiplication:
      case GameMechanics.TopicType.division:
        return _buildBasicMathQuestion(question, loc);
      case GameMechanics.TopicType.decimals:
        return _buildDecimalsQuestion(question, loc);
      case GameMechanics.TopicType.algebra:
        return _buildAlgebraQuestion(question, loc);
      default:
        return _buildBasicMathQuestion(question, loc);
    }
  }

  Widget _buildCountingQuestion(Map<String, dynamic> question, AppLocalizations loc) {
    final type = question['type'] as String;
    String questionText;
    final questionKey = question['questionKey'] as String?;
    final questionParams = question['questionParams'] as Map<String, String>?;
    if (questionKey != null) {
      questionText = loc.get(questionKey);
      if (questionParams != null && questionParams.isNotEmpty) {
        for (final e in questionParams.entries) {
          questionText = questionText.replaceAll('{${e.key}}', e.value);
        }
      }
    } else {
      questionText = question['question'] as String? ?? '';
    }
    final options = question['options'] as List<dynamic>? ?? [];
    final optionsList = options.whereType<int>().toList();

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildTopicQuestionPill('🔢', questionText),

        const SizedBox(height: 30),

        if (type == 'count_objects') ...[
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white, width: 3),
            ),
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 12,
              runSpacing: 12,
              children: List.generate(
                question['count'] as int,
                    (index) => Text(
                  question['emoji'] as String,
                  style: const TextStyle(fontSize: 32),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ] else if (type == 'find_missing' || type == 'whats_next') ...[
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white, width: 3),
            ),
            child: Text(
              question['sequence'] as String,
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C3E50),
                letterSpacing: 4,
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],

        if (optionsList.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                Row(
                  children: [
                    if (optionsList.length > 0)
                      Expanded(child: _buildCompactNumberOption(optionsList[0])),
                    if (optionsList.length > 1) ...[
                      const SizedBox(width: 8),
                      Expanded(child: _buildCompactNumberOption(optionsList[1])),
                    ],
                  ],
                ),
                if (optionsList.length > 2) const SizedBox(height: 8),
                if (optionsList.length > 2)
                  Row(
                    children: [
                      Expanded(child: _buildCompactNumberOption(optionsList[2])),
                      if (optionsList.length > 3) ...[
                        const SizedBox(width: 8),
                        Expanded(child: _buildCompactNumberOption(optionsList[3])),
                      ],
                    ],
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildDecimalsQuestion(Map<String, dynamic> question, AppLocalizations loc) {
    final type = question['type'] as String? ?? '';
    final questionText = question['question'] as String? ?? '';
    final options = question['options'] as List<dynamic>? ?? [];

    List<dynamic> optionsList = [];
    if (type == 'decimal_compare') {
      optionsList = options.whereType<String>().toList();
    } else if (type == 'decimal_round') {
      optionsList = options.whereType<int>().toList();
    } else {
      optionsList = options.whereType<String>().toList();
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildTopicQuestionPill('🔢', questionText),

        const SizedBox(height: 30),

        if (optionsList.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                Row(
                  children: [
                    if (optionsList.length > 0)
                      Expanded(child: _buildDecimalOption(optionsList[0])),
                    if (optionsList.length > 1) ...[
                      const SizedBox(width: 8),
                      Expanded(child: _buildDecimalOption(optionsList[1])),
                    ],
                  ],
                ),
                if (optionsList.length > 2) const SizedBox(height: 8),
                if (optionsList.length > 2)
                  Row(
                    children: [
                      Expanded(child: _buildDecimalOption(optionsList[2])),
                      if (optionsList.length > 3) ...[
                        const SizedBox(width: 8),
                        Expanded(child: _buildDecimalOption(optionsList[3])),
                      ],
                    ],
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildDecimalOption(dynamic value) {
    final currentQuestion = _questions[_currentQuestionIndex];
    final correctAnswer = currentQuestion['correctAnswer'];
    final valueStr = value.toString();
    final correctStr = correctAnswer.toString();
    final isCorrectAnswer = valueStr == correctStr;
    final isSelected = _selectedAnswer?.toString() == valueStr;

    return GestureDetector(
      onTap: _isAnswered ? null : () => _checkAnswer(value),
      child: Container(
        height: 55,
        decoration: BoxDecoration(
          gradient: _isAnswered
              ? (isCorrectAnswer
              ? const LinearGradient(colors: [Color(0xFF4CAF50), Color(0xFF45a049)])
              : (isSelected
              ? const LinearGradient(colors: [Color(0xFFE53935), Color(0xFFD32F2F)])
              : LinearGradient(colors: [Colors.white.withOpacity(0.2), Colors.white.withOpacity(0.1)])))
              : LinearGradient(colors: [Colors.white.withOpacity(0.3), Colors.white.withOpacity(0.2)]),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
            width: 2,
          ),
        ),
        child: Center(
          child: Text(
            valueStr,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAlgebraQuestion(Map<String, dynamic> question, AppLocalizations loc) {
    final questionText = question['question'] as String? ?? '';
    final options = question['options'] as List<dynamic>? ?? [];
    final optionsList = options.whereType<int>().toList();

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: Column(
            children: [
              Text(
                questionText,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              if (_isAnswered) ...[
                const SizedBox(height: 8),
                Text(
                  _isCorrect ? '✅ ${loc.get('correct_feedback')}' : '❌ ${loc.get('wrong_feedback')}',
                  style: const TextStyle(fontSize: 18, color: Colors.white),
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 30),

        if (optionsList.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                Row(
                  children: [
                    if (optionsList.length > 0)
                      Expanded(child: _buildCompactNumberOption(optionsList[0])),
                    if (optionsList.length > 1) ...[
                      const SizedBox(width: 8),
                      Expanded(child: _buildCompactNumberOption(optionsList[1])),
                    ],
                  ],
                ),
                if (optionsList.length > 2) const SizedBox(height: 8),
                if (optionsList.length > 2)
                  Row(
                    children: [
                      Expanded(child: _buildCompactNumberOption(optionsList[2])),
                      if (optionsList.length > 3) ...[
                        const SizedBox(width: 8),
                        Expanded(child: _buildCompactNumberOption(optionsList[3])),
                      ],
                    ],
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildBasicMathQuestion(Map<String, dynamic> question, AppLocalizations loc) {
    final questionText = question['question'] as String? ?? '? = ?';
    final options = question['options'] as List<dynamic>? ?? [];
    final optionsList = options.whereType<int>().toList();

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildTopicQuestionPill('📝', questionText),

        const SizedBox(height: 30),

        if (optionsList.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                Row(
                  children: [
                    if (optionsList.length > 0)
                      Expanded(child: _buildCompactNumberOption(optionsList[0])),
                    if (optionsList.length > 1) ...[
                      const SizedBox(width: 8),
                      Expanded(child: _buildCompactNumberOption(optionsList[1])),
                    ],
                  ],
                ),
                if (optionsList.length > 2) const SizedBox(height: 8),
                if (optionsList.length > 2)
                  Row(
                    children: [
                      Expanded(child: _buildCompactNumberOption(optionsList[2])),
                      if (optionsList.length > 3) ...[
                        const SizedBox(width: 8),
                        Expanded(child: _buildCompactNumberOption(optionsList[3])),
                      ],
                    ],
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildCompactNumberOption(int number) {
    final currentQuestion = _questions[_currentQuestionIndex];
    final correctAnswer = currentQuestion['correctAnswer'];
    final isCorrectAnswer = number == correctAnswer;
    final isSelected = _selectedAnswer == number;

    Color bgColor;
    Color borderColor;

    if (_isAnswered) {
      if (isCorrectAnswer) {
        bgColor = Colors.green;
        borderColor = Colors.green.shade700;
      } else if (isSelected) {
        bgColor = Colors.red;
        borderColor = Colors.red.shade700;
      } else {
        bgColor = Colors.white.withOpacity(0.15);
        borderColor = Colors.white.withOpacity(0.4);
      }
    } else {
      bgColor = Colors.white.withOpacity(0.2);
      borderColor = Colors.white.withOpacity(0.6);
    }

    return GestureDetector(
      onTap: _isAnswered ? null : () => _checkAnswer(number),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 55,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: borderColor, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Center(
          child: Text(
            '$number',
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              shadows: [
                Shadow(
                  blurRadius: 2,
                  color: Colors.black26,
                  offset: Offset(1, 1),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    final loc = AppLocalizations(Provider.of<LocaleProvider>(context, listen: true).locale);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            onPressed: _showExitDialog,
            icon: const Icon(Icons.close, color: Colors.white),
          ),
          const Spacer(),
          Column(
            children: [
              Text(
                _getLocalizedTopicTitle(loc),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                widget.difficultyDisplay ?? widget.difficulty,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
            ],
          ),
          const Spacer(),
          const SizedBox(width: 8),
          // Canlar - GameMechanicsService ile profil senkron
          Consumer<GameMechanicsService>(
            builder: (context, mechanicsService, _) {
              final lives = mechanicsService.currentLives;
              final maxLives = mechanicsService.maxLives;
              return ScaleTransition(
                scale: _heartAnimation,
                child: Row(
                  children: List.generate(maxLives, (index) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Icon(
                        index < lives ? Icons.favorite : Icons.favorite_border,
                        color: index < lives ? Colors.red : Colors.red.withOpacity(0.3),
                        size: 24,
                      ),
                    );
                  }),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    final localeProvider = Provider.of<LocaleProvider>(context, listen: true);
    final localizations = AppLocalizations(localeProvider.locale);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.3),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: Colors.white.withOpacity(0.5),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${localizations.get('question')} ${_currentQuestionIndex + 1} / ${_questions.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  width: 35,
                  height: 35,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _timeLeft <= 5 ? Colors.red : Colors.white.withOpacity(0.3),
                    border: Border.all(
                      color: _timeLeft <= 5 ? Colors.red.shade300 : Colors.white.withOpacity(0.6),
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '$_timeLeft',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: _questions.isNotEmpty
                    ? (_currentQuestionIndex + 1) / _questions.length
                    : 0,
                backgroundColor: Colors.white.withOpacity(0.3),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
                minHeight: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showExitDialog() {
    _gamePaused = true;
    _timer?.cancel();

    GameExitConfirmDialog.show(
      context,
      themeColor: widget.topicSettings.color,
      onStay: () {
        setState(() => _gamePaused = false);
        _startTimer();
      },
      onExit: () {
        _timer?.cancel();
        widget.onBack();
      },
    );
  }

  void _showResults() {
    _timer?.cancel();
    _confettiController.stop();
    _reportGameCompletion();

    final percentage = _questions.isNotEmpty
        ? (_correctAnswers / _questions.length * 100).round()
        : 0;
    final stars = percentage >= 80 ? 3 : percentage >= 60 ? 2 : percentage >= 40 ? 1 : 0;
    final isTime = _isTimeTopic;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final loc = AppLocalizations(Provider.of<LocaleProvider>(context, listen: false).locale);
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  widget.topicSettings.color,
                  widget.topicSettings.color.withOpacity(0.7),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${widget.topicSettings.emoji} ${_getLocalizedTopicTitle(loc)}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              const SizedBox(height: 16),
              Text(
                percentage >= 60 ? '🎉 Tebrikler!' : '💪 Daha Çok Çalışmalısın',
                style: const TextStyle(
                  fontSize: 20,
                  color: Colors.white,
                ),
              ),
              if (!isTime) ...[
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(3, (index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(
                        index < stars ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                        size: 48,
                      ),
                    );
                  }),
                ),
              ],
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    _buildStatRow('Doğru Cevaplar', '$_correctAnswers / ${_questions.length}'),
                    if (!isTime) ...[
                      const Divider(color: Colors.white24),
                      _buildStatRow('Skor', '$_score'),
                    ],
                    const Divider(color: Colors.white24),
                    _buildStatRow('Başarı Oranı', '%$percentage'),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        widget.onBack();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Ana Menü',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _restartGame();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.3),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Tekrar Oyna',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
      },
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white70),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _restartGame() {
    final mechanicsService = Provider.of<GameMechanicsService>(context, listen: false);
    if (!mechanicsService.hasLives) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations(Provider.of<LocaleProvider>(context, listen: false).locale).get('no_lives_play')),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }
    setState(() {
      _currentQuestionIndex = 0;
      _score = 0;
      _correctAnswers = 0;
      _isGameOver = false;
      _gamePaused = false;
      _isAnswered = false;
      _selectedAnswer = null;
      _wrongReactionEmoji = null;
      _generateQuestions();
    });
    _confettiController.stop();
    _wrongShakeController.reset();
    _startTimer();
  }

  @override
  Widget build(BuildContext context) {
    final localeProvider = Provider.of<LocaleProvider>(context, listen: true);
    final loc = AppLocalizations(localeProvider.locale);
    final currentQuestion = _questions.isNotEmpty
        ? _questions[_currentQuestionIndex]
        : <String, dynamic>{};

    final mainLayer = Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF1ABC9C), // Turkuaz
            Color(0xFF16A085), // Koyu turkuaz
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            _buildProgressBar(),
            const SizedBox(height: 12),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: constraints.maxHeight),
                      child: Center(
                        child: _questions.isNotEmpty
                            ? AnimatedSwitcher(
                                duration: const Duration(milliseconds: 500),
                                child: _buildQuestionContent(currentQuestion, loc),
                              )
                            : const CircularProgressIndicator(color: Colors.white),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    return Scaffold(
      body: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _wrongShakeController,
              builder: (context, child) {
                final t = _wrongShakeController.value;
                final dx = math.sin(t * math.pi * 10) * 14 * (1 - t);
                return Transform.translate(
                  offset: Offset(dx, 0),
                  child: child,
                );
              },
              child: mainLayer,
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _wrongShakeController,
                builder: (context, _) {
                  final t = _wrongShakeController.value;
                  final opacity = 0.28 * math.sin(t * math.pi);
                  if (opacity < 0.02) return const SizedBox.shrink();
                  return ColoredBox(color: Colors.red.withOpacity(opacity));
                },
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: LayoutBuilder(
                builder: (context, c) {
                  return Align(
                    alignment: Alignment.topCenter,
                    child: SizedBox(
                      height: c.maxHeight,
                      width: c.maxWidth,
                      child: ConfettiWidget(
                        confettiController: _confettiController,
                        blastDirectionality: BlastDirectionality.explosive,
                        shouldLoop: false,
                        emissionFrequency: 0.32,
                        numberOfParticles: 18,
                        gravity: 0.36,
                        colors: const [
                          Color(0xFFFFD54F),
                          Color(0xFFFF80AB),
                          Color(0xFF80DEEA),
                          Color(0xFFA5D6A7),
                          Color(0xFFB39DDB),
                          Color(0xFFFFAB91),
                          Color(0xFFFFF59D),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          if (_wrongReactionEmoji != null)
            Positioned.fill(
              child: IgnorePointer(
                child: Center(
                  child: TweenAnimationBuilder<double>(
                    key: ValueKey('${_currentQuestionIndex}_$_selectedAnswer'),
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 420),
                    curve: Curves.elasticOut,
                    builder: (context, t, _) {
                      return Opacity(
                        opacity: (0.4 + 0.6 * t).clamp(0.0, 1.0),
                        child: Transform.scale(
                          scale: 0.35 + 0.65 * t,
                          child: Text(
                            _wrongReactionEmoji!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 96),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          if (_isTimeTopic ||
              _isCountingTopic ||
              _isAdditionTopic ||
              _isSubtractionTopic ||
              _isDivisionTopic ||
              _isGeometryTopic ||
              _isMultiplicationTopic)
            Positioned(
              right: 10,
              bottom: MediaQuery.paddingOf(context).bottom + 10,
              child: Material(
                elevation: 10,
                shadowColor: Colors.black45,
                shape: const CircleBorder(),
                color: const Color(0xFFFFD54F),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => _showClockGameHelp(context),
                  customBorder: const CircleBorder(),
                  child: const SizedBox(
                    width: 50,
                    height: 50,
                    child: Center(
                      child: Text(
                        '?',
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF4527A0),
                          height: 1,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Günlük saat bonusu — renkli, çocuk dostu kutlama kartı
class _KidClockDailyRewardDialog extends StatefulWidget {
  final AppLocalizations loc;
  final VoidCallback onOk;

  const _KidClockDailyRewardDialog({
    required this.loc,
    required this.onOk,
  });

  @override
  State<_KidClockDailyRewardDialog> createState() => _KidClockDailyRewardDialogState();
}

class _KidClockDailyRewardDialogState extends State<_KidClockDailyRewardDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _bounce;

  @override
  void initState() {
    super.initState();
    _bounce = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _bounce.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 340),
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF7C4DFF),
                Color(0xFFFF4081),
                Color(0xFFFFC107),
              ],
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF9800).withValues(alpha: 0.55),
                blurRadius: 28,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(22, 26, 22, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🎉', style: TextStyle(fontSize: 56)),
              const SizedBox(height: 8),
              AnimatedBuilder(
                animation: _bounce,
                builder: (context, child) {
                  final y = -6 * math.sin(_bounce.value * math.pi);
                  return Transform.translate(
                    offset: Offset(0, y),
                    child: child,
                  );
                },
                child: const Text('🪙', style: TextStyle(fontSize: 48)),
              ),
              const SizedBox(height: 14),
              Text(
                widget.loc.get('clock_daily_bonus_main'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  height: 1.25,
                  shadows: [
                    Shadow(color: Colors.black38, blurRadius: 6, offset: Offset(0, 2)),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: widget.onOk,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF6A1B9A),
                    elevation: 4,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: Text(
                    widget.loc.get('ok'),
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _KidTopicHelpDialog extends StatelessWidget {
  final AppLocalizations loc;
  final String titleKey;
  final String aboutKey;
  final VoidCallback onClose;

  const _KidTopicHelpDialog({
    required this.loc,
    required this.titleKey,
    required this.aboutKey,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF00ACC1),
            Color(0xFF5E35B1),
          ],
        ),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: Colors.white, width: 2.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.help_outline, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  loc.get(titleKey),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '🌟 ${loc.get('daily_entry_bonus_line')}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Color(0xFFFFF59D),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            loc.get(aboutKey),
            style: TextStyle(
              fontSize: 15,
              height: 1.45,
              color: Colors.white.withValues(alpha: 0.92),
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: onClose,
              child: Text(
                loc.get('ok'),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Analog saat çizen CustomPainter
class _ClockPainter extends CustomPainter {
  final int hour;
  final int minute;

  _ClockPainter({required this.hour, required this.minute});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 10;

    final framePaint = Paint()
      ..color = const Color(0xFF1ABC9C)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8;
    canvas.drawCircle(center, radius, framePaint);

    final bgPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius - 4, bgPaint);

    for (int i = 0; i < 12; i++) {
      final angle = (i * 30 - 90) * math.pi / 180;
      final isHourMark = i % 3 == 0;
      final markLength = isHourMark ? 15.0 : 8.0;
      final markWidth = isHourMark ? 3.0 : 2.0;

      final startX = center.dx + (radius - markLength - 4) * math.cos(angle);
      final startY = center.dy + (radius - markLength - 4) * math.sin(angle);
      final endX = center.dx + (radius - 4) * math.cos(angle);
      final endY = center.dy + (radius - 4) * math.sin(angle);

      final markPaint = Paint()
        ..color = Colors.grey.shade800
        ..strokeWidth = markWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(Offset(startX, startY), Offset(endX, endY), markPaint);
    }

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    for (int i = 1; i <= 12; i++) {
      final angle = (i * 30 - 90) * math.pi / 180;
      final numberRadius = radius - 30;
      final x = center.dx + numberRadius * math.cos(angle);
      final y = center.dy + numberRadius * math.sin(angle);

      textPainter.text = TextSpan(
        text: '$i',
        style: TextStyle(
          color: Colors.grey.shade800,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, y - textPainter.height / 2),
      );
    }

    final minuteAngle = (minute * 6 - 90) * math.pi / 180;
    final minuteLength = radius * 0.6;
    final minutePaint = Paint()
      ..color = Colors.grey.shade700
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      center,
      Offset(
        center.dx + minuteLength * math.cos(minuteAngle),
        center.dy + minuteLength * math.sin(minuteAngle),
      ),
      minutePaint,
    );

    final normalizedHour = hour % 12;
    final hourAngle = ((normalizedHour * 30 + minute * 0.5) - 90) * math.pi / 180;
    final hourLength = radius * 0.4;
    final hourPaint = Paint()
      ..color = Colors.grey.shade800
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      center,
      Offset(
        center.dx + hourLength * math.cos(hourAngle),
        center.dy + hourLength * math.sin(hourAngle),
      ),
      hourPaint,
    );

    final centerDotPaint = Paint()
      ..color = const Color(0xFF1ABC9C)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 8, centerDotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}