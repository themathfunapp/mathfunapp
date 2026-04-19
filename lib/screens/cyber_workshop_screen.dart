import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:provider/provider.dart';
import '../audio/section_soundscape.dart';
import '../localization/app_localizations.dart';
import '../providers/locale_provider.dart';
import '../services/audio_service.dart';
import '../services/game_mechanics_service.dart';
import '../services/game_session_report.dart';

/// Siber Atölye - Robot Laboratuvarı Temalı Sayma Oyunu
/// Matematik Gezginleri - Tekno-Sincap ile matematik çipleri
class CyberWorkshopScreen extends StatefulWidget {
  final VoidCallback onBack;

  const CyberWorkshopScreen({super.key, required this.onBack});

  @override
  State<CyberWorkshopScreen> createState() => _CyberWorkshopScreenState();
}

class _CyberWorkshopScreenState extends State<CyberWorkshopScreen>
    with TickerProviderStateMixin {
  late final AudioService _audio;
  late AnimationController _pulseController;
  late AnimationController _celebrationController;
  late Animation<double> _pulseAnimation;

  int _currentLevel = 1;
  int _score = 0;
  int _stars = 0;
  int _targetNumber = 0;
  List<int> _options = [];
  String _currentTechObject = '⚙️'; // Soru değişene kadar sabit kalmalı (flash önleme)
  bool _isAnswered = false;
  bool _isCorrect = false;
  bool _gameOver = false;
  bool _hasShownNoLivesDialog = false;
  bool _sessionReported = false;
  int _sessQuestions = 0;
  int _sessCorrect = 0;
  int _sessWrong = 0;
  int _runStreak = 0;
  int _bestStreak = 0;

  // Siber Atölye nesneleri: Flaticon chip teması - dişli, pil, mikroçip, devre, CPU, anten vb.
  // Her emoji için localization key (siber_atolye_tech_XXX)
  static const Map<String, String> _techObjectKeys = {
    '⚙️': 'siber_atolye_tech_disli',
    '🔋': 'siber_atolye_tech_pil',
    '🔌': 'siber_atolye_tech_fis',
    '💾': 'siber_atolye_tech_disket',
    '📟': 'siber_atolye_tech_cagri',
    '🖥️': 'siber_atolye_tech_bilgisayar',
    '🧩': 'siber_atolye_tech_devre',
    '🎛️': 'siber_atolye_tech_panel',
    '📡': 'siber_atolye_tech_anten',
    '🛰️': 'siber_atolye_tech_uydu',
    '⚡': 'siber_atolye_tech_enerji',
    '🔧': 'siber_atolye_tech_anahtar',
    '🔩': 'siber_atolye_tech_vida',
    '💻': 'siber_atolye_tech_laptop',
    '📱': 'siber_atolye_tech_telefon',
    '📀': 'siber_atolye_tech_dvd',
    '💿': 'siber_atolye_tech_cd',
    '🎮': 'siber_atolye_tech_oyun_cipl',
    '🎯': 'siber_atolye_tech_sensor',
    '📺': 'siber_atolye_tech_monitor',
  };

  final List<String> _techObjects = _techObjectKeys.keys.toList();

  // Renk paleti: #2C3E50 (Koyu Gri), #3498DB (Neon Mavi), #ECF0F1 (Gümüş)
  static const Color _darkGray = Color(0xFF2C3E50);
  static const Color _neonBlue = Color(0xFF3498DB);
  static const Color _silver = Color(0xFFECF0F1);

  @override
  void initState() {
    super.initState();
    _audio = context.read<AudioService>();
    scheduleSectionAmbient(context, SoundscapeTheme.space);

    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.98, end: 1.02).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _celebrationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _generateQuestion();
  }

  @override
  void dispose() {
    _audio.cancelAmbientSync();
    _pulseController.dispose();
    _celebrationController.dispose();
    super.dispose();
  }

  /// Tekno-Sincap'ın ağzından görev metni: "Bakalım kahraman! Atölyede kaç tane [nesne] buldun?"
  String _getQuestionText(AppLocalizations loc) {
    final objectName = loc.get(_techObjectKeys[_currentTechObject] ?? 'siber_atolye_tech_mikrocipl');
    final format = loc.get('siber_atolye_how_many_format');
    return format.replaceAll('{0}', objectName);
  }

  void _generateQuestion() {
    final random = math.Random();
    final maxNumber = math.min(10, 3 + _currentLevel);
    _targetNumber = random.nextInt(maxNumber) + 1;
    _currentTechObject = _techObjects[random.nextInt(_techObjects.length)];

    _options = [_targetNumber];
    while (_options.length < 4) {
      final option = random.nextInt(maxNumber) + 1;
      if (!_options.contains(option)) {
        _options.add(option);
      }
    }
    _options.shuffle();

    _isAnswered = false;
    _isCorrect = false;
    if (mounted) setState(() {});
  }

  void _checkAnswer(int answer) {
    if (_isAnswered || _gameOver) return;
    final mechanicsService = Provider.of<GameMechanicsService>(context, listen: false);
    if (!mechanicsService.hasLives) return;

    setState(() {
      _isAnswered = true;
      _isCorrect = answer == _targetNumber;

      if (_isCorrect) {
        _sessQuestions++;
        _sessCorrect++;
        _runStreak++;
        if (_runStreak > _bestStreak) _bestStreak = _runStreak;
        if (_sessCorrect % 10 == 0) mechanicsService.addCoins(5);
        _score += 10;
        _stars++;
        _audio.playAnswerFeedback(true);
        _celebrationController.forward(from: 0);

        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            _currentLevel++;
            _generateQuestion();
          }
        });
      } else {
        _sessQuestions++;
        _sessWrong++;
        _runStreak = 0;
        _audio.playAnswerFeedback(false);
        mechanicsService.onWrongAnswer();
        if (!mechanicsService.hasLives) {
          _gameOver = true;
          _showGameOver();
          return;
        }
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted && !_gameOver) _generateQuestion();
        });
      }
    });
  }

  void _reportCyberSession() {
    if (_sessionReported || !mounted) return;
    _sessionReported = true;
    final q = (_sessCorrect + _sessWrong).clamp(1, 9999);
    try {
      GameSessionReport.submit(
        context,
        questionsAnswered: q,
        correctAnswers: _sessCorrect,
        wrongAnswers: _sessWrong,
        score: _score,
        averageAnswerTimeSeconds: 5.0,
        fastAnswersCount: 0,
        superFastAnswersCount: 0,
        bestCorrectStreakInSession: _bestStreak,
      );
    } catch (e) {
      debugPrint('CyberWorkshop report error: $e');
    }
  }

  void _showNoLivesDialog() {
    _reportCyberSession();
    final loc = AppLocalizations(Provider.of<LocaleProvider>(context, listen: false).locale);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🤖', style: TextStyle(fontSize: 32)),
            const SizedBox(width: 8),
            Text(loc.get('lives_finished')),
          ],
        ),
        content: Text(loc.get('no_lives_play')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(loc.get('ok')),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              widget.onBack();
            },
            child: Text(loc.get('profile')),
          ),
        ],
      ),
    );
  }

  void _showGameOver() {
    _reportCyberSession();
    final loc = AppLocalizations(Provider.of<LocaleProvider>(context, listen: false).locale);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🤖', style: TextStyle(fontSize: 28)),
            const SizedBox(width: 8),
            Flexible(child: Text(loc.get('lives_finished'), textAlign: TextAlign.center)),
          ],
        ),
        content: Text(loc.get('no_lives_play')),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              widget.onBack();
            },
            child: Text(loc.get('ok')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations(Provider.of<LocaleProvider>(context, listen: true).locale);
    final mechanicsService = Provider.of<GameMechanicsService>(context, listen: true);
    if (!mechanicsService.hasLives && !_hasShownNoLivesDialog) {
      _hasShownNoLivesDialog = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showNoLivesDialog();
      });
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              _darkGray,
              Color(0xFF34495E),
              _neonBlue,
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Devre çizgileri arka plan
              ..._buildCircuitBackground(),
              // Yüzen teknoloji nesneleri
              ..._buildFloatingTech(),

              Column(
                children: [
                  _buildTopBar(loc),
                  const SizedBox(height: 20),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          _buildCharacterMessage(loc),
                          const SizedBox(height: 20),
                          _buildLevelInfo(loc),
                          const SizedBox(height: 30),
                          _buildQuestionArea(loc),
                          const SizedBox(height: 40),
                          _buildAnswerOptions(loc),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              if (_isCorrect && _isAnswered) _buildCelebration(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(AppLocalizations loc) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Üst satır: geri + başlık (geniş) + skor; canlar ayrı satırda (dar ekranda başlığı sıkıştırmaz).
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: widget.onBack,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _silver.withOpacity(0.2),
                    shape: BoxShape.circle,
                    border: Border.all(color: _neonBlue.withOpacity(0.5)),
                  ),
                  child: const Icon(Icons.arrow_back, color: _silver),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🤖 ${loc.get('siber_atolye')}',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: _silver,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      loc.get('siber_atolye_subtitle'),
                      style: TextStyle(
                        fontSize: 12,
                        color: _neonBlue.withOpacity(0.9),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: _neonBlue.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _neonBlue.withOpacity(0.6)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('⚡', style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 4),
                    Text(
                      '$_stars',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _silver,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: Consumer<GameMechanicsService>(
              builder: (context, mechanicsService, _) {
                final lives = mechanicsService.currentLives;
                final maxLives = mechanicsService.maxLives;
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(
                    maxLives,
                    (i) => Padding(
                      padding: const EdgeInsets.only(left: 2),
                      child: Text(
                        i < lives ? '🧩' : '🔌',
                        style: const TextStyle(fontSize: 18),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCharacterMessage(AppLocalizations loc) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _darkGray.withOpacity(0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _neonBlue.withOpacity(0.4), width: 2),
        boxShadow: [
          BoxShadow(
            color: _neonBlue.withOpacity(0.2),
            blurRadius: 15,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        children: [
          const Text('🐿️', style: TextStyle(fontSize: 48)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  loc.get('siber_atolye_character_name'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _neonBlue,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  loc.get('siber_atolye_character_message'),
                  style: TextStyle(
                    fontSize: 13,
                    color: _silver.withOpacity(0.9),
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelInfo(AppLocalizations loc) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _darkGray.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _neonBlue.withOpacity(0.5), width: 2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(loc.get('level_label'), _currentLevel.toString(), '🎯'),
          _buildStatItem(loc.get('score'), _score.toString(), '⚡'),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, String emoji) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 24)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: _neonBlue,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: _silver.withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildQuestionArea(AppLocalizations loc) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _darkGray.withOpacity(0.8),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _neonBlue, width: 2),
        boxShadow: [
          BoxShadow(
            color: _neonBlue.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            _getQuestionText(loc),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: _silver,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 12,
                  runSpacing: 12,
                  children: List.generate(
                    _targetNumber,
                    (index) => Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _neonBlue.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _neonBlue.withOpacity(0.6)),
                      ),
                      child: Text(_currentTechObject, style: const TextStyle(fontSize: 36)),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerOptions(AppLocalizations loc) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Text(
            loc.get('choose_answer'),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: _silver,
            ),
          ),
          const SizedBox(height: 12),
          Column(
            children: [
              Row(
                children: [
                  if (_options.isNotEmpty) Expanded(child: _buildAnswerButton(_options[0])),
                  if (_options.length > 1) ...[
                    const SizedBox(width: 10),
                    Expanded(child: _buildAnswerButton(_options[1])),
                  ],
                ],
              ),
              if (_options.length > 2) const SizedBox(height: 10),
              if (_options.length > 2)
                Row(
                  children: [
                    Expanded(child: _buildAnswerButton(_options[2])),
                    if (_options.length > 3) ...[
                      const SizedBox(width: 10),
                      Expanded(child: _buildAnswerButton(_options[3])),
                    ],
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerButton(int number) {
    final isCorrectAnswer = number == _targetNumber;
    final isSelected = _isAnswered && number == _targetNumber;

    Color buttonColor;
    if (_isAnswered) {
      buttonColor = isCorrectAnswer ? _neonBlue : _darkGray.withOpacity(0.5);
    } else {
      buttonColor = _darkGray.withOpacity(0.6);
    }

    final mechanicsService = Provider.of<GameMechanicsService>(context, listen: false);
    final canTap = !_isAnswered && !_gameOver && mechanicsService.hasLives;
    return GestureDetector(
      onTap: canTap ? () => _checkAnswer(number) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: 70,
        decoration: BoxDecoration(
          color: buttonColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? _neonBlue : _neonBlue.withOpacity(0.5),
            width: isSelected ? 3 : 2,
          ),
          boxShadow: [
            BoxShadow(
              color: _neonBlue.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🔌', style: TextStyle(fontSize: 24)),
            const SizedBox(width: 8),
            Text(
              number.toString(),
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: _isAnswered && isCorrectAnswer ? _silver : _neonBlue,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCelebration() {
    return AnimatedBuilder(
      animation: _celebrationController,
      builder: (context, child) {
        return Positioned.fill(
          child: IgnorePointer(
            child: Stack(
              children: List.generate(20, (index) {
                final random = math.Random(index);
                final startX = random.nextDouble();
                final delay = random.nextDouble() * 0.5;
                final progress = (_celebrationController.value - delay).clamp(0.0, 1.0);

                return Positioned(
                  left: MediaQuery.of(context).size.width * startX,
                  top: -50 + (MediaQuery.of(context).size.height * progress * 1.2),
                  child: Opacity(
                    opacity: 1.0 - progress,
                    child: Transform.rotate(
                      angle: progress * 4 * math.pi,
                      child: Text(
                        ['⚡', '✨', '🎉', '🔋'][random.nextInt(4)],
                        style: const TextStyle(fontSize: 30),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildCircuitBackground() {
    return List.generate(6, (index) {
      final random = math.Random(index);
      return Positioned(
        left: random.nextDouble() * 400,
        top: 80 + random.nextDouble() * 500,
        child: Opacity(
          opacity: 0.1 + random.nextDouble() * 0.15,
          child: Icon(
            Icons.memory,
            size: 30 + random.nextDouble() * 40,
            color: _neonBlue,
          ),
        ),
      );
    });
  }

  List<Widget> _buildFloatingTech() {
    return List.generate(5, (index) {
      final random = math.Random(index);
      final objs = ['⚙️', '🔋', '💾', '🔌'];
      return Positioned(
        left: random.nextDouble() * 300,
        top: random.nextDouble() * 600,
        child: AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(
                math.sin(_pulseController.value * 2 * math.pi + index) * 15,
                math.cos(_pulseController.value * 2 * math.pi + index) * 10,
              ),
              child: Opacity(
                opacity: 0.4,
                child: Text(
                  objs[index % objs.length],
                  style: const TextStyle(fontSize: 28),
                ),
              ),
            );
          },
        ),
      );
    });
  }
}
