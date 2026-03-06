import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../localization/app_localizations.dart';
import '../providers/locale_provider.dart';

/// Ölçüm Diyarı - Büyük-küçük, uzun-kısa kavramlarını öğren!
class MeasurementLandScreen extends StatefulWidget {
  final VoidCallback onBack;

  const MeasurementLandScreen({super.key, required this.onBack});

  @override
  State<MeasurementLandScreen> createState() => _MeasurementLandScreenState();
}

class _MeasurementLandScreenState extends State<MeasurementLandScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _bounceController;
  late AnimationController _celebrationController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _bounceAnimation;

  int _currentLevel = 1;
  int _score = 0;
  int _stars = 0;
  int _lives = 5;
  bool _isAnswered = false;
  bool _isCorrect = false;
  bool _isBonusLevel = false;

  String _questionType = 'bigSmall';
  String _questionText = '';
  List<String> _options = [];
  String _correctAnswer = '';

  static const Color _orange = Color(0xFFFF9800);
  static const Color _yellow = Color(0xFFFFC107);

  /// Soru tipleri: Sadece doğal boyutları net olan nesneler (cetvel, kalem gibi
  /// belirsiz ölçülebilir nesneler hariç - gerçek dünyada boyutları kesin)
  static final List<Map<String, dynamic>> _questionSets = [
    {'question': 'Hangisi daha BÜYÜK?', 'correctPool': ['🐘', '🦣', '🦛', '🐫', '🦒', '🐋'], 'wrongPool': ['🐜', '🐛', '🦗', '🐝', '🐞', '🦟']},
    {'question': 'Hangisi daha KÜÇÜK?', 'correctPool': ['🐜', '🐛', '🦗', '🐝', '🐞', '🦟'], 'wrongPool': ['🐘', '🦣', '🦛', '🐫', '🦒']},
    {'question': 'Hangisi daha UZUN?', 'correctPool': ['🦒', '🐍', '🦎', '🐘'], 'wrongPool': ['🐢', '🐁', '🐹', '🐸', '🐌']},
    {'question': 'Hangisi daha KISA?', 'correctPool': ['🐢', '🐁', '🐹', '🐸', '🐌'], 'wrongPool': ['🦒', '🐍', '🦎', '🐘']},
    {'question': 'Hangisi daha AĞIR?', 'correctPool': ['🐘', '🦣', '🦛', '🚗', '🏔️', '🐋'], 'wrongPool': ['🪶', '🪁', '🍃', '🦋', '🪺', '🪹']},
    {'question': 'Hangisi daha HAFİF?', 'correctPool': ['🪶', '🪁', '🍃', '🦋', '🪺'], 'wrongPool': ['🐘', '🦣', '🦛', '🚗', '🐋']},
    {'question': 'Hangisi daha UZUN BOYLU?', 'correctPool': ['🦒', '🌳', '🏢', '🐘'], 'wrongPool': ['🐜', '🐁', '🌱', '🐌', '🐹']},
    {'question': 'Hangisi daha KISA BOYLU?', 'correctPool': ['🐜', '🐁', '🌱', '🐌', '🐹'], 'wrongPool': ['🦒', '🌳', '🏢', '🐘']},
    {'question': 'Hangisi daha GENİŞ?', 'correctPool': ['🐘', '🦣', '🦛', '🐋', '🦭', '🐫'], 'wrongPool': ['🦒', '🐍', '🪶', '🐸', '🐌']},
    {'question': 'Hangisi daha DAR?', 'correctPool': ['🦒', '🐍', '🪶', '🐸', '🐌'], 'wrongPool': ['🐘', '🦣', '🦛', '🐋']},
    {'question': 'Hangisi daha BÜYÜK meyve?', 'correctPool': ['🍎', '🍐', '🍊', '🍉', '🍈'], 'wrongPool': ['🍒', '🍇', '🫐', '🍓', '🫒']},
    {'question': 'Hangisi daha KÜÇÜK meyve?', 'correctPool': ['🍒', '🍇', '🫐', '🍓', '🫒'], 'wrongPool': ['🍎', '🍐', '🍊', '🍉']},
    {'question': 'Hangisi daha BÜYÜK bina?', 'correctPool': ['🏰', '🏢', '🏛️', '🏗️'], 'wrongPool': ['🏠', '🏚️', '🏕️', '⛺']},
    {'question': 'Hangisi daha KÜÇÜK ev?', 'correctPool': ['🏠', '🏚️', '🏕️', '⛺'], 'wrongPool': ['🏰', '🏢', '🏛️']},
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat(reverse: true);

    _bounceAnimation = Tween<double>(begin: 0, end: 6).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.easeInOut),
    );

    _celebrationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _generateQuestion();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _bounceController.dispose();
    _celebrationController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _getAvailableQuestionSets() {
    if (_currentLevel <= 2) return _questionSets.take(4).toList();
    if (_currentLevel <= 5) return _questionSets.take(6).toList();
    if (_currentLevel <= 8) return _questionSets.take(8).toList();
    return _questionSets;
  }

  void _generateQuestion() {
    final random = math.Random();
    _isBonusLevel = _currentLevel % 5 == 0 && _currentLevel > 0;

    if (_isBonusLevel) {
      _generateBonusQuestion();
      return;
    }

    final available = _getAvailableQuestionSets();
    final set = available[random.nextInt(available.length)];
    final correctPool = (set['correctPool'] as List).cast<String>();
    final wrongPool = (set['wrongPool'] as List).cast<String>();

    _questionText = set['question'] as String;
    _correctAnswer = correctPool[random.nextInt(correctPool.length)];
    final wrongOptions = wrongPool.toList()..shuffle(random);
    _options = [_correctAnswer, wrongOptions[0], wrongOptions[1]];
    _options.shuffle(random);

    setState(() {
      _isAnswered = false;
      _isCorrect = false;
    });
  }

  void _generateBonusQuestion() {
    final random = math.Random();
    final set = _questionSets[random.nextInt(_questionSets.length)];
    final correctPool = (set['correctPool'] as List).cast<String>();
    final wrongPool = (set['wrongPool'] as List).cast<String>();

    _questionText = '⭐ BONUS: ${set['question']}';
    _correctAnswer = correctPool[random.nextInt(correctPool.length)];
    final wrongOptions = wrongPool.toList()..shuffle(random);
    _options = [_correctAnswer, wrongOptions[0], wrongOptions[1]];
    _options.shuffle(random);

    setState(() {
      _isAnswered = false;
      _isCorrect = false;
    });
  }

  void _checkAnswer(String selected) {
    if (_isAnswered) return;
    final correct = selected == _correctAnswer;

    setState(() {
      _isAnswered = true;
      _isCorrect = correct;
      if (correct) {
        _score += _isBonusLevel ? 25 : 10;
        _stars += _isBonusLevel ? 2 : 1;
        _celebrationController.forward(from: 0);
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            _currentLevel++;
            _generateQuestion();
          }
        });
      } else {
        _lives = (_lives - 1).clamp(0, 5);
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) _generateQuestion();
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations(Provider.of<LocaleProvider>(context, listen: true).locale);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1565C0),
              Color(0xFF42A5F5),
              Color(0xFF81D4FA),
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              _buildAmbientEffects(),
              Column(
                children: [
                  _buildTopBar(loc),
                  _buildProgressPath(),
                  const SizedBox(height: 12),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          _buildQuestionCard(loc),
                          const SizedBox(height: 24),
                          _buildVisualDisplay(),
                          const SizedBox(height: 24),
                          _buildOptionsGrid(),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              if (_isCorrect) _buildCelebration(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressPath() {
    const totalFloors = 10;
    final currentFloor = (_currentLevel - 1) % totalFloors;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          Text('📏', style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 8),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(totalFloors, (i) {
                final isPassed = i < currentFloor;
                final isCurrent = i == currentFloor;
                return Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: isPassed ? _yellow : (isCurrent ? Colors.white : Colors.white.withOpacity(0.4)),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: isCurrent ? 2 : 1),
                  ),
                  child: isPassed ? const Icon(Icons.check, size: 12, color: _orange) : null,
                );
              }),
            ),
          ),
          const SizedBox(width: 8),
          Text('Seviye ${currentFloor + 1}/$totalFloors', style: TextStyle(color: Colors.white.withOpacity(0.95), fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildAmbientEffects() {
    return Stack(
      children: [
        AnimatedBuilder(
          animation: _bounceAnimation,
          builder: (context, child) {
            return Positioned(
              top: 60 + _bounceAnimation.value,
              right: 30,
              child: Text('📏', style: TextStyle(fontSize: 45)),
            );
          },
        ),
        ...List.generate(8, (i) {
          final r = math.Random(i);
          return Positioned(
            top: r.nextDouble() * 400,
            left: r.nextDouble() * 350,
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Opacity(
                  opacity: 0.4 + _pulseAnimation.value * 0.2,
                  child: Text('📐', style: TextStyle(fontSize: 20 + r.nextDouble() * 12)),
                );
              },
            ),
          );
        }),
      ],
    );
  }

  Widget _buildTopBar(AppLocalizations loc) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          GestureDetector(
            onTap: widget.onBack,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                shape: BoxShape.circle,
                border: Border.all(color: _orange.withOpacity(0.6)),
              ),
              child: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('📏 Ölçüm Diyarı', style: _textStyle(Colors.white, size: 20, bold: true)),
                Text(loc.get('world_measurement_land_desc'), style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 12)),
              ],
            ),
          ),
          Row(
            children: List.generate(5, (i) => Padding(
              padding: const EdgeInsets.only(left: 2),
              child: Text(i < _lives ? '❤️' : '🖤', style: const TextStyle(fontSize: 20)),
            )),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _yellow.withOpacity(0.4),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text('⭐ $_stars', style: _textStyle(Colors.amber, size: 16, bold: true)),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(AppLocalizations loc) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _orange.withOpacity(0.6), width: 2),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 15)],
      ),
      child: Row(
        children: [
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: _yellow.withOpacity(0.4),
                    shape: BoxShape.circle,
                    border: Border.all(color: _orange, width: 2),
                  ),
                  child: const Center(child: Text('🐢', style: TextStyle(fontSize: 32))),
                ),
              );
            },
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Zaman Kaplumbağası', style: _textStyle(_orange, size: 16, bold: true)),
                const SizedBox(height: 6),
                Text(
                  _questionText,
                  style: _textStyle(Colors.black87, size: 18),
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVisualDisplay() {
    return AnimatedBuilder(
      animation: _bounceAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _bounceAnimation.value * 0.3),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: _orange.withOpacity(0.4), width: 2),
              boxShadow: [BoxShadow(color: _orange.withOpacity(0.2), blurRadius: 20)],
            ),
            child: Column(
              children: [
                Text('🔍 Dikkatli bak!', style: _textStyle(_orange, size: 16, bold: true)),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: _options.map((emoji) {
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _orange.withOpacity(0.3)),
                      ),
                      child: Text(emoji, style: const TextStyle(fontSize: 52)),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOptionsGrid() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Column(
        children: [
          Text('Cevabını seç:', style: _textStyle(_orange, size: 16, bold: true)),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: _options.map((emoji) => _buildOptionButton(emoji)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionButton(String emoji) {
    final isCorrect = emoji == _correctAnswer;
    final isSelected = _isAnswered && isCorrect;

    Color bgColor = Colors.white.withOpacity(0.9);
    if (_isAnswered) {
      bgColor = isCorrect ? Colors.green.withOpacity(0.8) : Colors.red.withOpacity(0.2);
    }

    return GestureDetector(
      onTap: _isAnswered ? null : () => _checkAnswer(emoji),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 90,
        height: 90,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.green : _orange.withOpacity(0.5),
            width: isSelected ? 3 : 2,
          ),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8)],
        ),
        child: Center(
          child: Text(emoji, style: const TextStyle(fontSize: 48)),
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
              children: List.generate(30, (i) {
                final r = math.Random(i);
                final progress = (_celebrationController.value - r.nextDouble() * 0.2).clamp(0.0, 1.0);
                return Positioned(
                  left: MediaQuery.of(context).size.width * r.nextDouble(),
                  top: -20 + MediaQuery.of(context).size.height * progress,
                  child: Opacity(
                    opacity: (1.0 - progress).clamp(0.0, 1.0),
                    child: Transform.rotate(
                      angle: progress * 6 * math.pi,
                      child: Text(
                        ['📏', '📐', '🦒', '🐘', '✨', '⭐', '🐢', '🐜', '🦣'][r.nextInt(9)],
                        style: TextStyle(fontSize: 24 + r.nextDouble() * 16),
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

  static TextStyle _textStyle(Color color, {double size = 16, bool bold = false}) =>
      GoogleFonts.quicksand(color: color, fontSize: size, fontWeight: bold ? FontWeight.bold : FontWeight.w500);
}
