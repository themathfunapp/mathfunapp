import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../localization/app_localizations.dart';
import '../providers/locale_provider.dart';
import '../services/game_mechanics_service.dart';

/// Cebir Diyarı - Ziki'nin Bilinmeyen Hazine Avı
/// Eşitlikler, bilinmeyenler ve denklemler öğrenme oyunu
class AlgebraRealmScreen extends StatefulWidget {
  final VoidCallback onBack;

  const AlgebraRealmScreen({super.key, required this.onBack});

  @override
  State<AlgebraRealmScreen> createState() => _AlgebraRealmScreenState();
}

enum AlgebraRegion {
  bilinmeyenOrmani,   // 1. Görsel denklemler
  islemVadisi,       // 2. x+3=7
  carpanDaglari,     // 3. 3×x=15
  denklemKoprusu,    // 4. 2x+3=9
  hazineKalesi,      // 5. 4x-5=15
}

class _AlgebraRealmScreenState extends State<AlgebraRealmScreen>
    with TickerProviderStateMixin {
  late AnimationController _jumpController;
  late AnimationController _shakeController;
  late AnimationController _glowController;
  late Animation<double> _jumpAnimation;
  late Animation<double> _shakeAnimation;

  int _keysCollected = 0;
  int _currentQuestionInRegion = 0;
  static const int _questionsPerRegion = 5;
  AlgebraRegion _currentRegion = AlgebraRegion.bilinmeyenOrmani;
  bool _hasShownNoLivesDialog = false;
  bool _isAnswered = false;
  int _correctAnswer = 0;
  List<int> _options = [];
  String _questionDisplay = '';
  String _questionEmoji = '🍎';
  bool _isBossQuestion = false;

  static const Color _purple = Color(0xFF673AB7);
  static const Color _gold = Color(0xFFFFD700);

  static const Map<AlgebraRegion, String> _regionEmojis = {
    AlgebraRegion.bilinmeyenOrmani: '🏝️',
    AlgebraRegion.islemVadisi: '🧪',
    AlgebraRegion.carpanDaglari: '🏔️',
    AlgebraRegion.denklemKoprusu: '🌉',
    AlgebraRegion.hazineKalesi: '🏰',
  };

  static const Map<AlgebraRegion, String> _regionNameKeys = {
    AlgebraRegion.bilinmeyenOrmani: 'algebra_region_bilinmeyen',
    AlgebraRegion.islemVadisi: 'algebra_region_islem',
    AlgebraRegion.carpanDaglari: 'algebra_region_carpan',
    AlgebraRegion.denklemKoprusu: 'algebra_region_denklem',
    AlgebraRegion.hazineKalesi: 'algebra_region_hazine',
  };

  @override
  void initState() {
    super.initState();
    _jumpController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _jumpAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _jumpController, curve: Curves.easeOut),
    );
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    _generateQuestion();
  }

  @override
  void dispose() {
    _jumpController.dispose();
    _shakeController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  void _generateQuestion() {
    final random = math.Random();
    _isAnswered = false;
    _isBossQuestion = _currentQuestionInRegion == _questionsPerRegion - 1;

    switch (_currentRegion) {
      case AlgebraRegion.bilinmeyenOrmani:
        _generateVisualEquation(random);
        break;
      case AlgebraRegion.islemVadisi:
        _generateAddSubEquation(random);
        break;
      case AlgebraRegion.carpanDaglari:
        _generateMulDivEquation(random);
        break;
      case AlgebraRegion.denklemKoprusu:
        _generateTwoOpEquation(random);
        break;
      case AlgebraRegion.hazineKalesi:
        _generateMixedEquation(random);
        break;
    }
    setState(() {});
  }

  void _generateVisualEquation(math.Random random) {
    final count = random.nextInt(3) + 2;
    final value = random.nextInt(4) + 2;
    _correctAnswer = value;
    _questionEmoji = ['🍎', '🍌', '🍇', '🍊', '⭐', '🎈'][random.nextInt(6)];
    final parts = List.filled(count, _questionEmoji);
    _questionDisplay = parts.join(' + ') + ' = ${count * value}';
    _options = _generateOptions(_correctAnswer, 4, random);
  }

  void _generateAddSubEquation(math.Random random) {
    final op = random.nextBool();
    final a = random.nextInt(5) + 2;
    final b = random.nextInt(5) + 5;
    if (op) {
      _correctAnswer = b - a;
      _questionDisplay = 'x + $a = $b';
    } else {
      _correctAnswer = a + b;
      _questionDisplay = 'x - $a = $b';
    }
    _options = _generateOptions(_correctAnswer, 4, random);
  }

  void _generateMulDivEquation(math.Random random) {
    final op = random.nextBool();
    final a = random.nextInt(5) + 2;
    final b = random.nextInt(8) + 2;
    if (op) {
      _correctAnswer = a * b;
      _questionDisplay = '$a × x = ${a * b}';
    } else {
      _correctAnswer = b;
      _questionDisplay = '${a * b} ÷ x = $a';
    }
    _options = _generateOptions(_correctAnswer, 4, random);
  }

  void _generateTwoOpEquation(math.Random random) {
    final a = random.nextInt(3) + 2;
    final x = random.nextInt(5) + 2;
    final b = random.nextInt(4) + 1;
    final c = a * x + b;
    _correctAnswer = x;
    _questionDisplay = '${a}x + $b = $c';
    _options = _generateOptions(_correctAnswer, 4, random);
  }

  void _generateMixedEquation(math.Random random) {
    final a = random.nextInt(3) + 2;
    final x = random.nextInt(6) + 3;
    final b = random.nextInt(5) + 1;
    final c = a * x - b;
    _correctAnswer = x;
    _questionDisplay = '${a}x - $b = $c';
    _options = _generateOptions(_correctAnswer, 4, random);
  }

  List<int> _generateOptions(int correct, int count, math.Random random) {
    final opts = <int>{correct};
    while (opts.length < count) {
      final offset = (random.nextInt(5) + 1) * (random.nextBool() ? 1 : -1);
      opts.add((correct + offset).clamp(1, 50));
    }
    return opts.toList()..shuffle(random);
  }

  void _checkAnswer(int selected) {
    if (_isAnswered) return;
    final mechanics = Provider.of<GameMechanicsService>(context, listen: false);
    if (!mechanics.hasLives) return;

    final correct = selected == _correctAnswer;
    setState(() => _isAnswered = true);

    if (correct) {
      _jumpController.forward(from: 0).then((_) {
        if (!mounted) return;
        _currentQuestionInRegion++;
        if (_currentQuestionInRegion >= _questionsPerRegion) {
          _keysCollected++;
          _currentQuestionInRegion = 0;
          if (_currentRegion.index < AlgebraRegion.values.length - 1) {
            setState(() {
              _currentRegion = AlgebraRegion.values[_currentRegion.index + 1];
            });
          }
        }
        _generateQuestion();
      });
    } else {
      mechanics.onWrongAnswer();
      _shakeController.forward(from: 0).then((_) {
        if (!mounted) return;
        if (!mechanics.hasLives) {
          _showGameOver();
        } else {
          _generateQuestion();
        }
      });
    }
  }

  void _showGameOver() {
    final loc = AppLocalizations(Provider.of<LocaleProvider>(context, listen: false).locale);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🏰', style: TextStyle(fontSize: 28)),
            const SizedBox(width: 8),
            Flexible(child: Text(loc.get('lives_finished'), textAlign: TextAlign.center)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(loc.get('no_lives_play')),
            const SizedBox(height: 16),
            Text('🔑 $_keysCollected', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: _gold)),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
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
    final mechanics = Provider.of<GameMechanicsService>(context, listen: true);
    if (!mechanics.hasLives && !_hasShownNoLivesDialog) {
      _hasShownNoLivesDialog = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showGameOver();
      });
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1a237e), Color(0xFF4a148c), Color(0xFF311b92)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildTopBar(loc, mechanics),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildRegionBadge(loc),
                      const SizedBox(height: 24),
                      _buildQuestionCard(loc),
                      const SizedBox(height: 24),
                      _buildZiki(loc),
                      const SizedBox(height: 16),
                      _buildKeysDisplay(loc),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(AppLocalizations loc, GameMechanicsService mechanics) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: widget.onBack,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
                border: Border.all(color: _gold),
              ),
              child: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('⚗️ ${loc.get('world_algebra_realm')}', style: _textStyle(Colors.white, size: 18, bold: true)),
                Text(loc.get('world_algebra_realm_desc'), style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 11)),
              ],
            ),
          ),
          Consumer<GameMechanicsService?>(builder: (context, m, _) {
            final lives = m?.maxLives ?? 3;
            final current = m?.currentLives ?? 3;
            return Row(
              children: List.generate(lives, (i) => Padding(
                padding: const EdgeInsets.only(left: 2),
                child: Opacity(opacity: i < current ? 1.0 : 0.3, child: const Text('⚡', style: TextStyle(fontSize: 18))),
              )),
            );
          }),
        ],
      ),
    );
  }

  /// Bilinmeyen Ormanı: denklemdeki meyve/şekil emojisi + "kaçtır?"; diğer bölgelerde klasik "x kaçtır?".
  Widget _buildWhatIsPrompt(AppLocalizations loc) {
    final style = _textStyle(_purple, size: 16, bold: true);
    if (_currentRegion == AlgebraRegion.bilinmeyenOrmani) {
      final suffix = loc.get('algebra_how_many_suffix');
      return Center(
        child: Text.rich(
          textAlign: TextAlign.center,
          TextSpan(
            children: [
              TextSpan(
                text: _questionEmoji,
                style: GoogleFonts.quicksand(fontSize: 26, fontWeight: FontWeight.bold, color: _purple, height: 1.1),
              ),
              TextSpan(text: suffix, style: style),
            ],
          ),
        ),
      );
    }
    return Text(loc.get('algebra_what_is_x'), style: style, textAlign: TextAlign.center);
  }

  Widget _buildRegionBadge(AppLocalizations loc) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: _purple.withOpacity(0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _gold.withOpacity(0.6)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(_regionEmojis[_currentRegion]!, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Text(loc.get(_regionNameKeys[_currentRegion]!), style: _textStyle(Colors.white, size: 18, bold: true)),
          const SizedBox(width: 8),
          Text('${_currentQuestionInRegion + 1}/$_questionsPerRegion', style: TextStyle(color: Colors.white70, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(AppLocalizations loc) {
    final mechanics = Provider.of<GameMechanicsService>(context, listen: false);
    final canTap = !_isAnswered && mechanics.hasLives;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _gold.withOpacity(0.6)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 20)],
      ),
      child: Column(
        children: [
          if (_isBossQuestion)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: _gold.withOpacity(0.3), borderRadius: BorderRadius.circular(12)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Text('👑', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                Text(loc.get('algebra_boss_question'), style: _textStyle(Colors.brown, size: 14, bold: true)),
              ]),
            ),
          if (_isBossQuestion) const SizedBox(height: 16),
          _buildWhatIsPrompt(loc),
          const SizedBox(height: 16),
          Text(_questionDisplay, style: GoogleFonts.quicksand(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87), textAlign: TextAlign.center),
          const SizedBox(height: 24),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: _options.map((n) => _buildOptionButton(n, canTap)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionButton(int value, bool canTap) {
    final isCorrect = value == _correctAnswer;
    final showResult = _isAnswered;

    Color bgColor = Colors.white;
    if (showResult) bgColor = isCorrect ? Colors.green.shade100 : Colors.red.shade50;

    return AnimatedBuilder(
      animation: _shakeAnimation,
      builder: (context, child) {
        final shake = !isCorrect && _isAnswered && _shakeController.isAnimating
            ? 6 * math.sin(_shakeAnimation.value * math.pi * 4)
            : 0.0;
        return Transform.translate(
          offset: Offset(shake, 0),
          child: GestureDetector(
            onTap: canTap ? () => _checkAnswer(value) : null,
            child: Container(
              width: 80,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: showResult && isCorrect ? Colors.green : _purple.withOpacity(0.4), width: 2),
              ),
              child: Center(
                child: Text('$value', style: _textStyle(Colors.black87, size: 24, bold: true)),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildZiki(AppLocalizations loc) {
    return AnimatedBuilder(
      animation: _jumpAnimation,
      builder: (context, child) {
        final offsetY = _jumpAnimation.value > 0 ? -30 * math.sin(_jumpAnimation.value * math.pi) : 0.0;
        return Transform.translate(
          offset: Offset(0, offsetY),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.brown.withOpacity(0.3),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.brown),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🐵', style: TextStyle(fontSize: 48)),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Ziki', style: _textStyle(Colors.white, size: 18, bold: true)),
                    Text(loc.get('algebra_find_unknown'), style: TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildKeysDisplay(AppLocalizations loc) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _gold.withOpacity(0.6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🔑', style: TextStyle(fontSize: 24)),
          const SizedBox(width: 8),
          Text(loc.get('algebra_keys_format').replaceAll('{0}', '$_keysCollected'), style: _textStyle(Colors.white, size: 18, bold: true)),
        ],
      ),
    );
  }

  static TextStyle _textStyle(Color color, {double size = 16, bool bold = false}) =>
      GoogleFonts.quicksand(color: color, fontSize: size, fontWeight: bold ? FontWeight.bold : FontWeight.w500);
}
