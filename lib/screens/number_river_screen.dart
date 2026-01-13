import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Rakam Nehri - Balıklarla Sayma Oyunu
class NumberRiverScreen extends StatefulWidget {
  final VoidCallback onBack;

  const NumberRiverScreen({super.key, required this.onBack});

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
  final List<String> _fishes = ['🐟', '🐠', '🐡', '🦈', '🐬', '🦑', '🐙', '🦀'];
  final List<String> _seaCreatures = ['🌊', '💧', '🫧'];
  
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
    
    // Seviyeye göre zorluk
    final maxNumber = math.min(10, 3 + _currentLevel);
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
    
    setState(() {
      _isAnswered = false;
      _isCorrect = false;
    });
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
                  _buildTopBar(),
                  
                  const SizedBox(height: 20),
                  
                  // Ana oyun alanı
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          // Seviye ve skor
                          _buildLevelInfo(),
                          
                          const SizedBox(height: 30),
                          
                          // Soru bölümü - Nehir ve balıklar
                          _buildQuestionArea(),
                          
                          const SizedBox(height: 40),
                          
                          // Cevap seçenekleri
                          _buildAnswerOptions(),
                          
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

  Widget _buildTopBar() {
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
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '🌊 Rakam Nehri',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Balıkları say!',
                  style: TextStyle(
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

  Widget _buildLevelInfo() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('Seviye', _currentLevel.toString(), '🎯'),
          _buildStatItem('Skor', _score.toString(), '🏆'),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, String emoji) {
    return Column(
      children: [
        Text(
          emoji,
          style: const TextStyle(fontSize: 24),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildQuestionArea() {
    final random = math.Random();
    final fish = _fishes[random.nextInt(_fishes.length)];
    
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
          const Text(
            'Nehirde kaç balık var?',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF01579B),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Nehir ve Balıklar
          Container(
            height: 180,
            padding: const EdgeInsets.all(16),
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
                // Dalgalar
                AnimatedBuilder(
                  animation: _waveAnimation,
                  builder: (context, child) {
                    return CustomPaint(
                      painter: _WavePainter(
                        wavePhase: _waveAnimation.value,
                      ),
                      size: const Size(double.infinity, 180),
                    );
                  },
                ),
                
                // Yüzen balıklar
                AnimatedBuilder(
                  animation: _swimController,
                  builder: (context, child) {
                    return Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 12,
                      runSpacing: 12,
                      children: List.generate(
                        _targetNumber,
                        (index) {
                          final offset = math.sin((_swimController.value * 2 * math.pi) + (index * 0.5));
                          return Transform.translate(
                            offset: Offset(offset * 15, 0),
                            child: Transform.scale(
                              scale: 1.0 + (math.sin((index + _swimController.value) * math.pi) * 0.1),
                              child: Text(
                                fish,
                                style: const TextStyle(fontSize: 36),
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerOptions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          const Text(
            'Cevabını seç:',
            style: TextStyle(
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

// Dalga çizimi
class _WavePainter extends CustomPainter {
  final double wavePhase;

  _WavePainter({required this.wavePhase});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, size.height * 0.5);

    for (double i = 0; i < size.width; i += 5) {
      final y = size.height * 0.5 + 
                math.sin((i / 50) + wavePhase) * 10;
      path.lineTo(i, y);
    }

    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_WavePainter oldDelegate) => true;
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

