import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../localization/app_localizations.dart';
import '../providers/locale_provider.dart';
import '../services/game_mechanics_service.dart';

/// Para Pazarı - Antik pazarda alışveriş yap!
/// Matematik Gezginleri (6-8 yaş) için animasyonlu para öğrenme ekranı
class MoneyMarketScreen extends StatefulWidget {
  final VoidCallback onBack;

  const MoneyMarketScreen({super.key, required this.onBack});

  @override
  State<MoneyMarketScreen> createState() => _MoneyMarketScreenState();
}

class _MoneyMarketScreenState extends State<MoneyMarketScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _floatController;
  late AnimationController _celebrationController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _floatAnimation;

  int _currentLevel = 1;
  int _stars = 0;
  int _coins = 0;
  bool _isAnswered = false;
  bool _isCorrect = false;
  bool _hasShownNoLivesDialog = false;

  Map<String, dynamic> _currentItem = _marketItems[0];
  int _pricePerKg = 50;
  double _amount = 1.5;
  List<int> _coinOptions = [];
  int _correctAnswer = 0;

  static const Color _gold = Color(0xFFFFD700);
  static const Color _orange = Color(0xFFFF9800);

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _floatController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _floatAnimation = Tween<double>(begin: -6, end: 6).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    _celebrationController = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    );

    _generateQuestion();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _floatController.dispose();
    _celebrationController.dispose();
    super.dispose();
  }

  void _generateQuestion() {
    final random = math.Random();
    _currentItem = _marketItems[random.nextInt(_marketItems.length)];
    final pricesPerKg = [10, 20, 25, 30, 40, 50];
    final amounts = [0.5, 1.0, 1.5, 2.0, 2.5, 3.0];
    _pricePerKg = pricesPerKg[random.nextInt(pricesPerKg.length)];
    _amount = amounts[random.nextInt(amounts.length)];
    _correctAnswer = (_pricePerKg * _amount).round();

    _coinOptions = [_correctAnswer];
    while (_coinOptions.length < 3) {
      final offset = (random.nextInt(3) + 1) * (random.nextBool() ? 5 : -5);
      final val = (_correctAnswer + offset).clamp(5, 200);
      if (!_coinOptions.contains(val)) _coinOptions.add(val);
    }
    _coinOptions.shuffle(random);

    setState(() {
      _isAnswered = false;
      _isCorrect = false;
    });
  }

  void _checkAnswer(int selected) {
    if (_isAnswered) return;
    final mechanicsService = Provider.of<GameMechanicsService>(context, listen: false);
    if (!mechanicsService.hasLives) return;

    final correct = selected == _correctAnswer;

    setState(() {
      _isAnswered = true;
      _isCorrect = correct;
      if (correct) {
        _stars++;
        _coins += _correctAnswer;
        _celebrationController.forward(from: 0);
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            _currentLevel++;
            _generateQuestion();
          }
        });
      } else {
        mechanicsService.onWrongAnswer();
        if (!mechanicsService.hasLives) {
          _showGameOver();
          return;
        }
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) _generateQuestion();
        });
      }
    });
  }

  void _showNoLivesDialog() {
    final loc = AppLocalizations(Provider.of<LocaleProvider>(context, listen: false).locale);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('💰', style: TextStyle(fontSize: 32)),
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
    final loc = AppLocalizations(Provider.of<LocaleProvider>(context, listen: false).locale);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('💰', style: TextStyle(fontSize: 28)),
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

  static const List<Map<String, dynamic>> _marketItems = [
    {'emoji': '🍎', 'name': 'Elma', 'possessive': 'Elmanın'},
    {'emoji': '🥕', 'name': 'Havuç', 'possessive': 'Havucun'},
    {'emoji': '🍇', 'name': 'Üzüm', 'possessive': 'Üzümün'},
    {'emoji': '🍅', 'name': 'Domates', 'possessive': 'Domatesin'},
    {'emoji': '🥒', 'name': 'Salatalık', 'possessive': 'Salatalığın'},
    {'emoji': '🥔', 'name': 'Patates', 'possessive': 'Patatesin'},
    {'emoji': '🧅', 'name': 'Soğan', 'possessive': 'Soğanın'},
    {'emoji': '🍌', 'name': 'Muz', 'possessive': 'Muzun'},
    {'emoji': '🍊', 'name': 'Portakal', 'possessive': 'Portakalın'},
    {'emoji': '🥬', 'name': 'Lahana', 'possessive': 'Lahananın'},
    {'emoji': '🥦', 'name': 'Brokoli', 'possessive': 'Brokolinin'},
    {'emoji': '🍐', 'name': 'Armut', 'possessive': 'Armudun'},
  ];

  String _amountText(double amount) {
    if (amount == 0.5) return 'yarım';
    return amount.toString().replaceAll('.', ',');
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
              Color(0xFF8B4513),
              Color(0xFFD2691E),
              Color(0xFFFF8C00),
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
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          _buildQuestionCard(loc, _currentItem),
                          const SizedBox(height: 24),
                          _buildItemDisplay(_currentItem),
                          const SizedBox(height: 24),
                          _buildCoinOptions(loc),
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

  Widget _buildAmbientEffects() {
    return Stack(
      children: [
        AnimatedBuilder(
          animation: _floatAnimation,
          builder: (context, child) {
            return Positioned(
              top: 80 + _floatAnimation.value,
              right: 20,
              child: Text('🏪', style: TextStyle(fontSize: 50)),
            );
          },
        ),
        ...List.generate(6, (i) {
          final r = math.Random(i);
          return Positioned(
            top: r.nextDouble() * 400,
            left: r.nextDouble() * 300,
            child: Opacity(
              opacity: 0.4,
              child: Text('💰', style: TextStyle(fontSize: 18 + r.nextDouble() * 10)),
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
                border: Border.all(color: _gold.withOpacity(0.6)),
              ),
              child: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('🏪 Para Pazarı', style: _textStyle(Colors.white, size: 20, bold: true)),
                Text(loc.get('world_money_market_desc'), style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 12)),
              ],
            ),
          ),
          Consumer<GameMechanicsService>(
            builder: (context, mechanicsService, _) {
              final lives = mechanicsService.currentLives;
              final maxLives = mechanicsService.maxLives;
              return Row(
                children: List.generate(maxLives, (i) => Padding(
                  padding: const EdgeInsets.only(left: 2),
                  child: Opacity(
                    opacity: i < lives ? 1.0 : 0.3,
                    child: const Text('💰', style: TextStyle(fontSize: 20)),
                  ),
                )),
              );
            },
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _gold.withOpacity(0.4),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text('⭐ $_stars', style: _textStyle(_gold, size: 16, bold: true)),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(AppLocalizations loc, Map<String, dynamic> item) {
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
                    color: _gold.withOpacity(0.4),
                    shape: BoxShape.circle,
                    border: Border.all(color: _orange, width: 2),
                  ),
                  child: const Center(child: Text('🛒', style: TextStyle(fontSize: 32))),
                ),
              );
            },
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Pazar Tüccarı', style: _textStyle(_orange, size: 16, bold: true)),
                const SizedBox(height: 6),
                Text(
                  '${item['emoji'] ?? '🥕'} ${item['possessive'] ?? item['name'] ?? ''} kilosu $_pricePerKg TL. Pazardan ${_amountText(_amount)} kilo ${'${item['name'] ?? ''}'.toLowerCase()} alırsak kaç TL olur?',
                  style: _textStyle(Colors.black87, size: 16),
                  maxLines: 3,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemDisplay(Map<String, dynamic> item) {
    return AnimatedBuilder(
      animation: _floatAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _floatAnimation.value * 0.3),
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
                Text('🛍️ Alışveriş sepeti', style: _textStyle(_orange, size: 16, bold: true)),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: _gold.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _gold.withOpacity(0.5)),
                  ),
                  child: Text(item['emoji'], style: const TextStyle(fontSize: 64)),
                ),
                const SizedBox(height: 8),
                Text('${item['name']}', style: _textStyle(Colors.black87, size: 18, bold: true)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCoinOptions(AppLocalizations loc) {
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
          Text('Toplam fiyatı seç:', style: _textStyle(_orange, size: 16, bold: true)),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: _coinOptions.map((amount) => _buildCoinButton(amount)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCoinButton(int amount) {
    final isCorrect = amount == _correctAnswer;
    final isSelected = _isAnswered && isCorrect;

    Color bgColor = Colors.white.withOpacity(0.9);
    if (_isAnswered) {
      bgColor = isCorrect ? Colors.green.withOpacity(0.8) : Colors.red.withOpacity(0.2);
    }

    final mechanicsService = Provider.of<GameMechanicsService>(context, listen: false);
    final canTap = !_isAnswered && mechanicsService.hasLives;

    return GestureDetector(
      onTap: canTap ? () => _checkAnswer(amount) : null,
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('💰', style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 4),
            Text(
              '$amount TL',
              style: _textStyle(Colors.black87, size: 16, bold: true),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCelebration() {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;
    final cx = w / 2;
    final cy = h / 2;

    return AnimatedBuilder(
      animation: _celebrationController,
      builder: (context, child) {
        return Positioned.fill(
          child: IgnorePointer(
            child: Stack(
              children: List.generate(40, (i) {
                final r = math.Random(i);
                final angle = r.nextDouble() * 2 * math.pi;
                final dist = _celebrationController.value * 400;
                final x = cx + math.cos(angle) * dist - 20;
                final y = cy + math.sin(angle) * dist - 20;
                final progress = _celebrationController.value;
                final opacity = (1.0 - progress * 0.5).clamp(0.0, 1.0);
                return Positioned(
                  left: x,
                  top: y,
                  child: Opacity(
                    opacity: opacity,
                    child: Transform.rotate(
                      angle: progress * 8 * math.pi,
                      child: Text(
                        '💰',
                        style: TextStyle(fontSize: 28 + r.nextDouble() * 20),
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
