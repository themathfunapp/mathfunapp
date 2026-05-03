import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:provider/provider.dart';
import '../localization/app_localizations.dart';
import '../providers/locale_provider.dart';
import '../models/age_group_selection.dart';

/// Rakam Nehri - Balıklarla Sayma Oyunu
class NumberRiverScreen extends StatefulWidget {
  final AgeGroupSelection ageGroup;
  final VoidCallback onBack;

  const NumberRiverScreen({super.key, required this.ageGroup, required this.onBack});

  @override
  State<NumberRiverScreen> createState() => _NumberRiverScreenState();
}

class _NumberRiverScreenState extends State<NumberRiverScreen>
    with TickerProviderStateMixin {
  late AnimationController _waveController;
  late AnimationController _swimController;
  late AnimationController _bubbleController;
  late AnimationController _celebrationController;
  late Animation<double> _waveAnimation;

  int _currentLevel = 1;
  int _score = 0;
  int _stars = 0;
  int _targetNumber = 0;
  List<int> _options = [];
  bool _isAnswered = false;
  bool _isCorrect = false;

  // Deniz canlıları
  final List<String> _fishes = ['🐟', '🐠', '🐡', '🦈', '🐬', '🦑', '🐙', '🦀', '🐋', '🐊'];
  final List<String> _seaCreatures = ['🌊', '💧', '🫧', '🐚', '⭐', '🌿'];

  // Her balık için rastgele pozisyonları saklayacağız
  late List<Map<String, dynamic>> _fishPositions;

  @override
  void initState() {
    super.initState();

    _waveController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();

    _waveAnimation = Tween<double>(begin: 0, end: 2 * math.pi).animate(_waveController);

    _swimController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat();

    _bubbleController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _celebrationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _generateQuestion();
  }

  @override
  void dispose() {
    _waveController.dispose();
    _swimController.dispose();
    _bubbleController.dispose();
    _celebrationController.dispose();
    super.dispose();
  }

  void _generateQuestion() {
    final random = math.Random();

    // Yaş kapısı + seviye: küçüklerde daha az sayı, büyüklerde daha fazla
    final int cap = switch (widget.ageGroup) {
      AgeGroupSelection.preschool => math.min(6, 2 + (_currentLevel + 1) ~/ 2),
      AgeGroupSelection.elementary => math.min(10, 3 + _currentLevel),
      AgeGroupSelection.advanced => math.min(18, 5 + _currentLevel * 2),
    };
    // En az 4 farklı şık üretebilmek için 1..max aralığında en az 4 sayı olmalı
    final maxNumber = math.max(4, cap);
    _targetNumber = random.nextInt(maxNumber) + 1;

    // Seçenekler oluştur
    _options = [_targetNumber];
    while (_options.length < 4) {
      final option = random.nextInt(maxNumber) + 1;
      if (!_options.contains(option)) {
        _options.add(option);
      }
    }
    _options.shuffle();

    // Balık pozisyonlarını oluştur - suyun içinde dağınık yerleşim
    _generateFishPositions();

    setState(() {
      _isAnswered = false;
      _isCorrect = false;
    });
  }

  void _generateFishPositions() {
    _fishPositions = [];
    final random = math.Random();

    for (int i = 0; i < _targetNumber; i++) {
      // Her balık için rastgele konum (yatay: 0.1-0.9 arası, dikey: 0.2-0.8 arası)
      // Bu sayede balıklar suyun her yerine dağılacak
      _fishPositions.add({
        'horizontal': 0.1 + random.nextDouble() * 0.8, // 0.1 - 0.9 arası
        'vertical': 0.2 + random.nextDouble() * 0.6,   // 0.2 - 0.8 arası
        'fish': _fishes[random.nextInt(_fishes.length)],
        'offset': random.nextDouble() * 2 * math.pi,   // Animasyon için başlangıç ofseti
      });
    }
  }

  void _checkAnswer(int answer) {
    if (_isAnswered) return;

    setState(() {
      _isAnswered = true;
      _isCorrect = answer == _targetNumber;

      if (_isCorrect) {
        _score += 10;
        _stars++;
        _celebrationController.forward(from: 0);

        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            setState(() {
              _currentLevel++;
              _generateQuestion();
            });
          }
        });
      } else {
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            setState(() {
              _generateQuestion();
            });
          }
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
              Color(0xFF006994), // Koyu mavi
              Color(0xFF0277BD), // Orta mavi
              Color(0xFF4FC3F7), // Açık mavi
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Arka plan animasyonları
              ..._buildFloatingBubbles(),
              ..._buildBackgroundWaves(),

              Column(
                children: [
                  // Üst bar
                  _buildTopBar(loc),

                  const SizedBox(height: 20),

                  // Ana oyun alanı
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          // Seviye ve skor
                          _buildLevelInfo(loc),

                          const SizedBox(height: 30),

                          // Soru bölümü - Nehir ve balıklar
                          _buildQuestionArea(loc),

                          const SizedBox(height: 40),

                          // Cevap seçenekleri
                          _buildAnswerOptions(loc),

                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // Kutlama animasyonu
              if (_isCorrect && _isAnswered)
                _buildCelebration(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(AppLocalizations loc) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Geri butonu
          GestureDetector(
            onTap: widget.onBack,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_back, color: Colors.white),
            ),
          ),

          const SizedBox(width: 16),

          // Başlık
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '🌊 ${loc.get('digit_river')}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  loc.get('count_fish_subtitle'),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),

          // Skor
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Text('⭐', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 4),
                Text(
                  '$_stars',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(loc.get('level_label'), _currentLevel.toString(), '🎯'),
          Container(
            width: 1,
            height: 36,
            color: Colors.white.withOpacity(0.25),
          ),
          _buildStatItem(loc.get('score'), _score.toString(), '🏆'),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, String emoji) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 18)),
        const SizedBox(width: 8),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                height: 1.05,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                height: 1.1,
                color: Colors.white.withOpacity(0.85),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuestionArea(AppLocalizations loc) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            loc.get('river_how_many_creatures'),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF01579B),
            ),
          ),

          const SizedBox(height: 20),

          // Nehir ve Balıklar - Suyun içinde
          Container(
            height: 300,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF81D4FA),
                  Color(0xFF4FC3F7),
                  Color(0xFF0288D1),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF0277BD), width: 3),
            ),
            child: Stack(
              children: [
                // Su yüzeyi dalgaları (üst kısım)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 30,
                  child: AnimatedBuilder(
                    animation: _waveAnimation,
                    builder: (context, child) {
                      return CustomPaint(
                        painter: _SurfaceWavePainter(
                          wavePhase: _waveAnimation.value,
                        ),
                        size: const Size(double.infinity, 30),
                      );
                    },
                  ),
                ),

                // Su altı dalgaları (içeride)
                AnimatedBuilder(
                  animation: _waveAnimation,
                  builder: (context, child) {
                    return CustomPaint(
                      painter: _UnderwaterWavePainter(
                        wavePhase: _waveAnimation.value,
                      ),
                      size: const Size(double.infinity, 300),
                    );
                  },
                ),

                // Su altı bitkileri ve dekorasyon
                ..._buildUnderwaterDecoration(),

                // Yüzen balıklar - suyun içinde dağınık
                AnimatedBuilder(
                  animation: _swimController,
                  builder: (context, child) {
                    return Stack(
                      children: _fishPositions.map((fishData) {
                        final index = _fishPositions.indexOf(fishData);
                        final horizontal = fishData['horizontal'] as double;
                        final vertical = fishData['vertical'] as double;
                        final fish = fishData['fish'] as String;
                        final offset = fishData['offset'] as double;

                        // Yüzme animasyonu - hafif sağa sola ve yukarı aşağı hareket
                        final swimX = math.sin((_swimController.value * 2 * math.pi) + offset) * 8;
                        final swimY = math.cos((_swimController.value * 2 * math.pi) + offset) * 4;

                        // Boyut animasyonu - hafif büyüyüp küçülme
                        final scale = 1.0 + (math.sin((_swimController.value * 2 * math.pi) + index) * 0.1);

                        return Positioned(
                          left: (MediaQuery.of(context).size.width * 0.7 * horizontal) + swimX,
                          top: (180 * vertical) + swimY + 30, // 30px üstten boşluk (su yüzeyi)
                          child: Transform.scale(
                            scale: scale,
                            child: Text(
                              fish,
                              style: const TextStyle(fontSize: 36),
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),

                // Su kabarcıkları
                ..._buildUnderwaterBubbles(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildUnderwaterDecoration() {
    return [
      // Kum (alt kısım)
      Positioned(
        bottom: 0,
        left: 0,
        right: 0,
        child: Container(
          height: 30,
          decoration: BoxDecoration(
            color: Colors.brown.withOpacity(0.4),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
          ),
        ),
      ),

      // Deniz yosunları
      Positioned(
        bottom: 0,
        left: 20,
        child: _buildSeaweed(30, 60),
      ),
      Positioned(
        bottom: 0,
        left: 80,
        child: _buildSeaweed(40, 80),
      ),
      Positioned(
        bottom: 0,
        right: 40,
        child: _buildSeaweed(35, 70),
      ),
      Positioned(
        bottom: 0,
        right: 100,
        child: _buildSeaweed(25, 50),
      ),

      // Taşlar
      Positioned(
        bottom: 5,
        left: 150,
        child: Container(
          width: 40,
          height: 25,
          decoration: BoxDecoration(
            color: Colors.grey.shade600,
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      Positioned(
        bottom: 5,
        right: 180,
        child: Container(
          width: 30,
          height: 20,
          decoration: BoxDecoration(
            color: Colors.grey.shade500,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    ];
  }

  Widget _buildSeaweed(double width, double height) {
    return CustomPaint(
      painter: _SeaweedPainter(),
      size: Size(width, height),
    );
  }

  List<Widget> _buildUnderwaterBubbles() {
    return List.generate(8, (index) {
      final random = math.Random(index);
      return Positioned(
        left: random.nextDouble() * 250,
        bottom: random.nextDouble() * 200 + 30,
        child: AnimatedBuilder(
          animation: _bubbleController,
          builder: (context, child) {
            final progress = (_bubbleController.value + (index * 0.15)) % 1.0;
            return Transform.translate(
              offset: Offset(
                math.sin(progress * 2 * math.pi) * 5,
                -progress * 80,
              ),
              child: Opacity(
                opacity: 0.7 - (progress * 0.5),
                child: Text(
                  '🫧',
                  style: TextStyle(fontSize: 12 + random.nextDouble() * 12),
                ),
              ),
            );
          },
        ),
      );
    });
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
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          // 2x2 Grid
          Column(
            children: [
              Row(
                children: [
                  if (_options.length > 0)
                    Expanded(child: _buildAnswerButton(_options[0])),
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
    final random = math.Random(number);
    final creature = _seaCreatures[random.nextInt(_seaCreatures.length)];
    final isCorrectAnswer = number == _targetNumber;
    final isSelected = _isAnswered && number == _targetNumber;

    Color buttonColor;
    if (_isAnswered) {
      if (isCorrectAnswer) {
        buttonColor = const Color(0xFF00E676); // Yeşil
      } else {
        buttonColor = Colors.white.withOpacity(0.3);
      }
    } else {
      buttonColor = Colors.white.withOpacity(0.9);
    }

    return GestureDetector(
      onTap: _isAnswered ? null : () => _checkAnswer(number),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: 70,
        decoration: BoxDecoration(
          color: buttonColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFFFFEB3B) : Colors.white.withOpacity(0.5),
            width: isSelected ? 3 : 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              creature,
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(width: 8),
            Text(
              number.toString(),
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: _isAnswered && isCorrectAnswer ? Colors.white : const Color(0xFF01579B),
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
              children: List.generate(15, (index) {
                final random = math.Random(index);
                final startX = random.nextDouble();
                final delay = random.nextDouble() * 0.3;
                final progress = (_celebrationController.value - delay).clamp(0.0, 1.0);

                return Positioned(
                  left: MediaQuery.of(context).size.width * startX,
                  top: -50 + (MediaQuery.of(context).size.height * progress * 1.2),
                  child: Opacity(
                    opacity: 1.0 - progress,
                    child: Transform.rotate(
                      angle: progress * 4 * math.pi,
                      child: Text(
                        ['🐟', '🐠', '⭐', '✨', '🎉'][random.nextInt(5)],
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

  List<Widget> _buildFloatingBubbles() {
    return List.generate(10, (index) {
      final random = math.Random(index);
      return Positioned(
        left: random.nextDouble() * 400,
        bottom: -50,
        child: AnimatedBuilder(
          animation: _bubbleController,
          builder: (context, child) {
            final progress = (_bubbleController.value + (index * 0.1)) % 1.0;
            return Transform.translate(
              offset: Offset(
                math.sin(progress * 2 * math.pi) * 20,
                -progress * 600,
              ),
              child: Opacity(
                opacity: 0.7 - (progress * 0.5),
                child: Text(
                  '🫧',
                  style: TextStyle(fontSize: 20 + random.nextDouble() * 20),
                ),
              ),
            );
          },
        ),
      );
    });
  }

  List<Widget> _buildBackgroundWaves() {
    return [
      Positioned(
        bottom: 0,
        left: 0,
        right: 0,
        child: AnimatedBuilder(
          animation: _waveAnimation,
          builder: (context, child) {
            return CustomPaint(
              painter: _BackgroundWavePainter(
                wavePhase: _waveAnimation.value,
              ),
              size: Size(MediaQuery.of(context).size.width, 100),
            );
          },
        ),
      ),
    ];
  }
}

// Su yüzeyi dalgaları
class _SurfaceWavePainter extends CustomPainter {
  final double wavePhase;

  _SurfaceWavePainter({required this.wavePhase});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final path = Path();
    path.moveTo(0, size.height * 0.5);

    for (double i = 0; i < size.width; i += 5) {
      final y = size.height * 0.5 +
          math.sin((i / 30) + wavePhase * 2) * 5;
      path.lineTo(i, y);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_SurfaceWavePainter oldDelegate) => true;
}

// Su altı dalgaları
class _UnderwaterWavePainter extends CustomPainter {
  final double wavePhase;

  _UnderwaterWavePainter({required this.wavePhase});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (int j = 1; j <= 3; j++) {
      final path = Path();
      path.moveTo(0, size.height * (0.3 + j * 0.1));

      for (double i = 0; i < size.width; i += 10) {
        final y = size.height * (0.3 + j * 0.1) +
            math.sin((i / 50) + wavePhase * (j + 1)) * 8;
        path.lineTo(i, y);
      }

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_UnderwaterWavePainter oldDelegate) => true;
}

// Deniz yosunu çizimi
class _SeaweedPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.green.withOpacity(0.7)
      ..style = PaintingStyle.fill
      ..strokeWidth = 2;

    final path = Path();
    path.moveTo(size.width * 0.5, size.height);

    // Yosun dalları
    for (int i = 0; i < 3; i++) {
      final offset = i * 0.3;
      path.cubicTo(
        size.width * 0.2, size.height * 0.7,
        size.width * 0.8, size.height * 0.4,
        size.width * 0.5, 0,
      );
    }

    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Arka plan dalgaları
class _BackgroundWavePainter extends CustomPainter {
  final double wavePhase;

  _BackgroundWavePainter({required this.wavePhase});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, size.height * 0.3);

    for (double i = 0; i < size.width; i += 5) {
      final y = size.height * 0.3 +
          math.sin((i / 80) + wavePhase) * 15;
      path.lineTo(i, y);
    }

    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_BackgroundWavePainter oldDelegate) => true;
}