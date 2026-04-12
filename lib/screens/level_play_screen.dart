import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import '../audio/section_soundscape.dart';
import '../providers/locale_provider.dart';
import '../services/audio_service.dart';
import '../services/game_mechanics_service.dart';
import '../services/game_session_report.dart';
import '../services/story_service.dart';
import '../models/story_mode.dart';
import '../localization/app_localizations.dart';
import 'dart:math';
import 'package:confetti/confetti.dart';




class LevelPlayScreen extends StatefulWidget {
  final StoryLevel level;
  final StoryChapter chapter;
  final StoryWorld world;


  const LevelPlayScreen({
    super.key,
    required this.level,
    required this.chapter,
    required this.world,
  });

  @override
  State<LevelPlayScreen> createState() => _LevelPlayScreenState();
}

class _LevelPlayScreenState extends State<LevelPlayScreen>
    with TickerProviderStateMixin {
  late final AudioService _audio;
  final Random _random = Random();
  int _currentObjectCount = 1;
  int _currentQuestionIndex = 0;
  int _correctAnswers = 0;
  int _wrongAnswers = 0;
  int _score = 0;
  bool _isAnswered = false;
  bool _sessionReported = false;
  int _runStreak = 0;
  int _bestStreak = 0;
  String? _selectedAnswer;
  Timer? _timer;
  int _timeRemaining = 0;
  bool _showSadEmoji = false;


  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;
  late AnimationController _bounceController;
  late Animation<double> _bounceAnimation;
  late String _currentObjectEmoji;
  late ConfettiController _confettiController;
  late AnimationController _helperJumpController;
  late Animation<double> _helperJumpAnimation;

  final List<String> _objectEmojis = [
    '⭐',
    '🐿️',
    '🐶',
    '🐱',
    '🐰',
    '🐸',
  ];


  void _generateRandomCount() {
    setState(() {
      _currentObjectCount = _random.nextInt(10) + 1; // 1–10
      _currentObjectEmoji =
      _objectEmojis[_random.nextInt(_objectEmojis.length)];
    });
  }



  @override
  void initState() {
    super.initState();
    _audio = context.read<AudioService>();

    _generateRandomCount();

    // 📳 SHAKE CONTROLLER (YANLIŞ CEVAP)
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: -10), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -10, end: 10), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 10, end: -10), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -10, end: 0), weight: 1),
    ]).animate(
      CurvedAnimation(
        parent: _shakeController,
        curve: Curves.easeInOut,
      ),
    );

    // 🔘 BOUNCE CONTROLLER (DOĞRU CEVAP BUTONU)
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _bounceAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(
        parent: _bounceController,
        curve: Curves.elasticOut,
      ),
    );

    // ⏱️ TIMER
    if (widget.level.timeLimit > 0) {
      _timeRemaining = widget.level.timeLimit;
      _startTimer();
    }

    // 🎉 CONFETTI
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 1),
    );

    // 🐿️ HELPER ZIPLAMA
    _helperJumpController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _helperJumpAnimation = Tween<double>(
      begin: 0,
      end: -16, // yukarı zıplama
    ).animate(
      CurvedAnimation(
        parent: _helperJumpController,
        curve: Curves.easeOut,
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final mechanics = Provider.of<GameMechanicsService>(context, listen: false);
      if (!mechanics.hasLives) {
        final loc = AppLocalizations(Provider.of<LocaleProvider>(context, listen: false).locale);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(loc.get('no_lives_play')),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
        return;
      }
      scheduleSectionAmbient(context, soundscapeForStoryWorldId(widget.world.id));
    });
  }


  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_timeRemaining > 0) {
          _timeRemaining--;
        } else {
          _timer?.cancel();
          _showTimeUpDialog();
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _shakeController.dispose();
    _bounceController.dispose();
    _confettiController.dispose();
    _helperJumpController.dispose();
    _audio.cancelAmbientSync();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localeProvider = Provider.of<LocaleProvider>(context, listen: true);
    final localizations = AppLocalizations(localeProvider.locale);

    final gradientColors = [
      Color(int.parse(widget.world.colors[0].replaceFirst('#', '0xFF'))),
      Color(int.parse(widget.world.colors[1].replaceFirst('#', '0xFF'))),
    ];

    if (widget.level.questions.isEmpty) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: gradientColors),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('🏗️', style: TextStyle(fontSize: 80)),
                const SizedBox(height: 20),
                Text(
                  localizations.get('questions_coming_soon'),
                  style: const TextStyle(
                    fontSize: 24,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(localizations.get('go_back')),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final currentQuestion = widget.level.questions[_currentQuestionIndex];

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              gradientColors[0],
              const Color(0xFF1a1a2e),
            ],
          ),
        ),
        child: Stack(
          children: [

            // 🔹 ASIL UI
            SafeArea(
              child: Column(
                children: [
                  _buildHeader(localizations),
                  _buildProgressBar(),
                  const SizedBox(height: 8),

                  Flexible(
                    fit: FlexFit.loose,
                    child: AnimatedBuilder(
                      animation: _shakeAnimation,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(_shakeAnimation.value, 0),
                          child: child,
                        );
                      },
                      child: _buildQuestion(currentQuestion, localizations),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildAnswers(currentQuestion, localizations),
                  ),

                  const SizedBox(height: 8),
                ],
              ),
            ),

            // 🎉 CONFETTI – EN ÜST KATMAN
            Align(
              alignment: Alignment.topCenter,
              child: SizedBox(
                height: MediaQuery.of(context).size.height,
                width: MediaQuery.of(context).size.width,
                child: ConfettiWidget(
                  confettiController: _confettiController,
                  blastDirectionality: BlastDirectionality.explosive,
                  shouldLoop: false,
                  emissionFrequency: 0.6,
                  numberOfParticles: 20,
                  gravity: 0.3,
                  colors: const [
                    Colors.green,
                    Colors.yellow,
                    Colors.blue,
                    Colors.orange,
                    Colors.pink,
                  ],
                ),
              ),
            ),

          ],
        ),
      ),
    );
  }

  Widget _buildHeader(AppLocalizations localizations) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          IconButton(
            onPressed: () => _showExitDialog(localizations),
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 20),
            ),
          ),

          Expanded(
            child: Column(
              children: [
                Text(
                  localizations.get(widget.level.nameKey),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  '${localizations.get('question')} ${_currentQuestionIndex + 1}/${widget.level.questions.length}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),

          // Timer or Score
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(
              children: [
                if (widget.level.timeLimit > 0) ...[
                  Icon(
                    Icons.timer,
                    color: _timeRemaining < 10 ? Colors.red : Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$_timeRemaining',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _timeRemaining < 10 ? Colors.red : Colors.white,
                    ),
                  ),
                ] else ...[
                  const Text('⭐', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 4),
                  Text(
                    '$_score',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    final progress =
        (_currentQuestionIndex + 1) / widget.level.questions.length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 20),
                  const SizedBox(width: 4),
                  Text(
                    '$_correctAnswers',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
              Row(
                children: List.generate(
                  widget.level.questions.length,
                  (index) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: index < _currentQuestionIndex
                          ? Colors.green
                          : index == _currentQuestionIndex
                              ? Colors.white
                              : Colors.white24,
                      shape: BoxShape.circle,
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
              value: progress,
              backgroundColor: Colors.white.withOpacity(0.2),
              valueColor: const AlwaysStoppedAnimation(Colors.green),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestion(MathQuestion question, AppLocalizations localizations) {
    // ⭐🐶🐱 Dinamik nesneler
    final objectsDisplay = List.generate(
      _currentObjectCount,
          (_) => _currentObjectEmoji,
    ).join(' ');



// ❓ Dinamik soru
    final questionDisplay = localizations
        .get('how_many_objects')
        .replaceAll('{object}', _currentObjectEmoji);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _helperJumpAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, _helperJumpAnimation.value),
                child: child,
              );
            },
            child: Text(
              _getHelperEmoji(),
              style: const TextStyle(fontSize: 36),
            ),
          ),


          if (_showSadEmoji)
            const Padding(
              padding: EdgeInsets.only(top: 6),
              child: Text(
                '😢',
                style: TextStyle(fontSize: 30),
              ),
            ),

          const SizedBox(height: 10),


          // ⭐⭐ Nesneler
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              objectsDisplay,
              style: const TextStyle(fontSize: 32),
              textAlign: TextAlign.center,
            ),
          ),

          const SizedBox(height: 16),

          // ❓ Soru
          Text(
            questionDisplay,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),

          if (_showSadEmoji)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                '😢',
                style: TextStyle(fontSize: 32),
              ),
            ),

        ],
      ),
    );
  }


  String _getHelperEmoji() {
    final storyService = Provider.of<StoryService>(context, listen: false);
    final helperInfo = storyService.getHelperInfo(widget.chapter.helper);
    return helperInfo['emoji'] as String;


  }



  String _getQuestionText(MathQuestion question, AppLocalizations localizations) {
    // If it's a localization key, translate it
    if (question.questionKey.startsWith('question_')) {
      return localizations.get(question.questionKey);
    }
    // Otherwise return as is (for math expressions like "2 + 3 = ?")
    return question.questionKey;
  }

  Widget _buildAnswers(MathQuestion question, AppLocalizations localizations) {
    final int correct = _currentObjectCount;

    final Set<int> optionSet = {correct};
    while (optionSet.length < 4) {
      optionSet.add(_random.nextInt(10) + 1);
    }

    final options = optionSet.toList()..shuffle();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildAnswerButton(options[0].toString(), question),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildAnswerButton(options[1].toString(), question),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildAnswerButton(options[2].toString(), question),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildAnswerButton(options[3].toString(), question),
              ),
            ],
          ),
        ],
      ),
    );
  }




  Widget _buildAnswerButton(String option, MathQuestion question) {
    if (option.isEmpty) return const SizedBox.shrink();
    
    final isSelected = _selectedAnswer == option;
    final isCorrect = option == _currentObjectCount.toString();

    Color bgColor = Colors.white.withOpacity(0.15);
    Color borderColor = Colors.white.withOpacity(0.3);

    if (_isAnswered) {
      if (isCorrect) {
        bgColor = Colors.green.withOpacity(0.3);
        borderColor = Colors.green;
      } else if (isSelected && !isCorrect) {
        bgColor = Colors.red.withOpacity(0.3);
        borderColor = Colors.red;
      }
    } else if (isSelected) {
      bgColor = Colors.white.withOpacity(0.3);
      borderColor = Colors.white;
    }

    return AnimatedBuilder(
      animation: _bounceAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _isAnswered && isCorrect ? _bounceAnimation.value : 1.0,
          child: child,
        );
      },
      child: GestureDetector(
        onTap: _isAnswered ? null : () => _selectAnswer(option, question),
        child: AnimatedContainer(
          constraints: const BoxConstraints(
            minHeight: 56,
          ),
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor, width: 2),
          ),
          child: Center(
            child: Text(
              option,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _isAnswered && !isCorrect && isSelected
                    ? Colors.red
                    : Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _selectAnswer(String answer, MathQuestion question) async {
    setState(() {
      _selectedAnswer = answer;
      _isAnswered = true;
    });

    final isCorrect = answer == _currentObjectCount.toString();

    if (isCorrect) {
      // 📳 HAPTIC (DOĞRU)
      HapticFeedback.lightImpact();
      _audio.playAnswerFeedback(true);

      // 🎉 CONFETTI
      _confettiController.play();

      // 🐿️ HELPER ZIPLASIN
      _helperJumpController.forward().then((_) {
        _helperJumpController.reverse();
      });

      // ⭐ SKOR
      _correctAnswers++;
      _runStreak++;
      if (_runStreak > _bestStreak) _bestStreak = _runStreak;
      _score += question.points;

      // 🔘 DOĞRU BUTON ZIPLASIN
      _bounceController.forward().then((_) {
        _bounceController.reverse();
      });

    } else {
      // 📳 HAPTIC (YANLIŞ)
      HapticFeedback.heavyImpact();
      _audio.playAnswerFeedback(false);

      _wrongAnswers++;
      _runStreak = 0;
      final mechanicsService = Provider.of<GameMechanicsService>(context, listen: false);
      mechanicsService.onWrongAnswer();

      // 😢 ÜZGÜN EMOJI GÖSTER
      setState(() {
        _showSadEmoji = true;
      });

      // 📳 EKRAN TİTREMESİ
      _shakeController.forward().then((_) {
        _shakeController.reverse();
      });

      // 😢 EMOJIYI KAPAT
      Future.delayed(const Duration(milliseconds: 800), () {
        if (!mounted) return;
        setState(() {
          _showSadEmoji = false;
        });
      });

      if (!mechanicsService.hasLives) {
        Future.delayed(const Duration(milliseconds: 1200), () {
          if (!mounted) return;
          _timer?.cancel();
          _reportStoryLevelSession();
          Navigator.pop(context);
        });
        return;
      }
    }

    // ➡️ SONRAKİ SORU
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;

      if (_currentQuestionIndex < widget.level.questions.length - 1) {
        setState(() {
          _currentQuestionIndex++;
          _generateRandomCount();
          _isAnswered = false;
          _selectedAnswer = null;
        });
      } else {
        _showResults();
      }
    });
  }

  void _reportStoryLevelSession() {
    if (_sessionReported || !mounted) return;
    _sessionReported = true;
    final total = _correctAnswers + _wrongAnswers;
    final q = total < 1 ? 1 : total;
    try {
      GameSessionReport.submit(
        context,
        questionsAnswered: q,
        correctAnswers: _correctAnswers,
        wrongAnswers: _wrongAnswers,
        score: _score,
        averageAnswerTimeSeconds: 5.0,
        fastAnswersCount: 0,
        superFastAnswersCount: 0,
        bestCorrectStreakInSession: _bestStreak,
      );
    } catch (e) {
      debugPrint('LevelPlay report error: $e');
    }
  }



  void _showTimeUpDialog() {
    final localeProvider = Provider.of<LocaleProvider>(context, listen: true);
    final localizations = AppLocalizations(localeProvider.locale);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1a1a2e),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Text('⏰', style: TextStyle(fontSize: 28)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                localizations.get('time_up'),
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        content: Text(
          localizations.get('time_up_message'),
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showResults();
            },
            child: Text(localizations.get('see_results')),
          ),
        ],
      ),
    );
  }

  void _showExitDialog(AppLocalizations localizations) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1a1a2e),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Text('🚪', style: TextStyle(fontSize: 28)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                localizations.get('exit_level'),
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        content: Text(
          localizations.get('exit_level_confirm'),
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(localizations.get('continue_playing')),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: Text(
              localizations.get('exit'),
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _showResults() async {
    _timer?.cancel();
    _reportStoryLevelSession();

    final storyService = Provider.of<StoryService>(context, listen: false);
    final result = await storyService.completeLevel(
      worldId: widget.world.id,
      chapterId: widget.chapter.id,
      levelId: widget.level.id,
      score: _score,
      correctAnswers: _correctAnswers,
      totalQuestions: widget.level.questions.length,
    );

    if (!mounted) return;

    final localeProvider = Provider.of<LocaleProvider>(context, listen: true);
    final localizations = AppLocalizations(localeProvider.locale);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(int.parse(widget.world.colors[0].replaceFirst('#', '0xFF'))),
                const Color(0xFF1a1a2e),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Title
              Text(
                result.stars >= 2
                    ? localizations.get('level_complete')
                    : localizations.get('keep_trying'),
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 20),

              // Stars
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (index) {
                  return TweenAnimationBuilder<double>(
                    duration: Duration(milliseconds: 300 + index * 200),
                    tween: Tween(begin: 0.0, end: 1.0),
                    builder: (context, value, child) {
                      return Transform.scale(
                        scale: value,
                        child: Icon(
                          index < result.stars ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                          size: 50,
                        ),
                      );
                    },
                  );
                }),
              ),

              const SizedBox(height: 20),

              // Score
              Text(
                '${localizations.get('score')}: $_score',
                style: const TextStyle(
                  fontSize: 20,
                  color: Colors.white70,
                ),
              ),

              const SizedBox(height: 10),

              // Correct answers
              Text(
                '${localizations.get('correct_answers')}: $_correctAnswers/${widget.level.questions.length}',
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
              ),

              const SizedBox(height: 20),

              // Rewards
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildRewardItem('💰', '+${result.coinsEarned}'),
                    _buildRewardItem('⭐', '+${result.expEarned} XP'),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pop(context);
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: Colors.white),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        localizations.get('back_to_map'),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        // Reset and replay
                        setState(() {
                          _currentQuestionIndex = 0;
                          _correctAnswers = 0;
                          _wrongAnswers = 0;
                          _score = 0;
                          _isAnswered = false;
                          _selectedAnswer = null;
                          _sessionReported = false;
                          _runStreak = 0;
                          _bestStreak = 0;
                          if (widget.level.timeLimit > 0) {
                            _timeRemaining = widget.level.timeLimit;
                            _startTimer();
                          }
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: const Color(0xFF4CAF50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        localizations.get('play_again'),
                        style: const TextStyle(color: Colors.white),
                      ),
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

  Widget _buildRewardItem(String emoji, String value) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 24)),
        const SizedBox(width: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.amber,
          ),
        ),
      ],
    );
  }
}

