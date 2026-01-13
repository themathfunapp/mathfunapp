import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Geometri Dağı - Şekil Tanıma Oyunu
class GeometryMountainScreen extends StatefulWidget {
  final VoidCallback onBack;

  const GeometryMountainScreen({super.key, required this.onBack});

  @override
  State<GeometryMountainScreen> createState() => _GeometryMountainScreenState();
}

class _GeometryMountainScreenState extends State<GeometryMountainScreen>
    with TickerProviderStateMixin {
  late AnimationController _snowController;
  late AnimationController _climbController;
  late AnimationController _celebrationController;
  late AnimationController _cloudController;
  
  int _currentQuestion = 1;
  static const int _totalQuestions = 10;
  int _score = 0;
  int _correctAnswers = 0;
  String _targetShape = '';
  String _targetShapeName = '';
  List<Map<String, String>> _options = [];
  bool _isAnswered = false;
  bool _isCorrect = false;
  bool _isGameFinished = false;
  double _climberPosition = 0.0; // 0.0 (alt) - 1.0 (üst)
  
  // Şekiller ve Türkçe isimleri (görsel olarak farklı olanlar)
  final Map<String, String> _shapes = {
    '🔵': 'Daire',
    '🟦': 'Kare',
    '🔺': 'Üçgen',
    '⭐': 'Yıldız',
    '❤️': 'Kalp',
    '🔶': 'Baklava',
    // Dikdörtgen ve Altıgen kaldırıldı (benzer göründüğü için)
  };
  
  @override
  void initState() {
    super.initState();
    
    _snowController = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: this,
    )..repeat();
    
    _climbController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _celebrationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _cloudController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat();
    
    _generateQuestion();
  }

  @override
  void dispose() {
    _snowController.dispose();
    _climbController.dispose();
    _celebrationController.dispose();
    _cloudController.dispose();
    super.dispose();
  }

  void _generateQuestion() {
    final random = math.Random();
    final shapeEntries = _shapes.entries.toList();
    
    // Hedef şekil seç
    final targetEntry = shapeEntries[random.nextInt(shapeEntries.length)];
    _targetShape = targetEntry.key;
    _targetShapeName = targetEntry.value;
    
    // Seçenekler oluştur (doğru cevap + 3 yanlış)
    _options = [{'emoji': _targetShape, 'name': _targetShapeName}];
    
    // Görsel olarak farklı şekilleri seç
    final usedShapes = <String>{_targetShape};
    final similarShapes = _getSimilarShapes(_targetShape);
    
    int attempts = 0;
    while (_options.length < 4 && attempts < 50) {
      final option = shapeEntries[random.nextInt(shapeEntries.length)];
      final optionEmoji = option.key;
      
      // Aynı şekil değil ve benzer şekil grubu değilse ekle
      if (!usedShapes.contains(optionEmoji) && !similarShapes.contains(optionEmoji)) {
        _options.add({'emoji': optionEmoji, 'name': option.value});
        usedShapes.add(optionEmoji);
      }
      attempts++;
    }
    
    // Eğer yeterli farklı şekil bulamadıysa, herhangi bir şekil ekle
    while (_options.length < 4) {
      final option = shapeEntries[random.nextInt(shapeEntries.length)];
      if (!_options.any((o) => o['emoji'] == option.key)) {
        _options.add({'emoji': option.key, 'name': option.value});
      }
    }
    
    _options.shuffle();
    
    setState(() {
      _isAnswered = false;
      _isCorrect = false;
    });
  }
  
  // Benzer görünen şekilleri grupla (artık hepsi farklı)
  Set<String> _getSimilarShapes(String shape) {
    // Tüm şekiller artık görsel olarak farklı, benzer grup yok
    return {};
  }

  void _checkAnswer(String selectedShape) {
    if (_isAnswered) return;
    
    setState(() {
      _isAnswered = true;
      _isCorrect = selectedShape == _targetShape;
      
      if (_isCorrect) {
        _score += 10;
        _correctAnswers++;
        _celebrationController.forward(from: 0);
        
        // Tırmanış animasyonu - her doğru cevap %10 ilerleme
        _climberPosition = _correctAnswers / _totalQuestions;
        _climbController.forward(from: 0);
      }
      
      // Oyun bitti mi kontrol et
      if (_currentQuestion >= _totalQuestions) {
        Future.delayed(Duration(seconds: _isCorrect ? 2 : 1), () {
          if (mounted) {
            _showGameFinished();
          }
        });
      } else {
        // Sonraki soru
        Future.delayed(Duration(seconds: _isCorrect ? 2 : 1), () {
          if (mounted) {
            setState(() {
              _currentQuestion++;
              _generateQuestion();
            });
          }
        });
      }
    });
  }
  
  void _showGameFinished() {
    setState(() {
      _isGameFinished = true;
    });
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF7E57C2),
                const Color(0xFF5E35B1),
              ],
            ),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '🎉',
                style: TextStyle(fontSize: 60),
              ),
              const SizedBox(height: 16),
              const Text(
                'Tebrikler!',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Zirveye ulaştın! 🏔️',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    _buildResultRow('📝 Toplam Soru', '$_totalQuestions'),
                    const SizedBox(height: 8),
                    _buildResultRow('✅ Doğru', '$_correctAnswers'),
                    const SizedBox(height: 8),
                    _buildResultRow('❌ Yanlış', '${_totalQuestions - _correctAnswers}'),
                    const SizedBox(height: 8),
                    _buildResultRow('🏆 Skor', '$_score'),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  widget.onBack();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF7E57C2),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text(
                  'Geri Dön',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildResultRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.white,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
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
              Color(0xFF5D4E6D), // Mor-gri gökyüzü
              Color(0xFF8E7CC3), // Açık mor
              Color(0xFFDED4E8), // Çok açık mor
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Arka plan animasyonları
              ..._buildFallingSnow(),
              ..._buildFloatingClouds(),
              
              Column(
                children: [
                  // Üst bar
                  _buildTopBar(),
                  
                  const SizedBox(height: 10),
                  
                  // Ana oyun alanı
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        children: [
                          // Seviye ve skor
                          _buildLevelInfo(),
                          
                          const SizedBox(height: 8),
                          
                          // Dağ ve tırmanıcı
                          _buildMountainArea(),
                          
                          const SizedBox(height: 8),
                          
                          // Soru bölümü
                          _buildQuestionArea(),
                          
                          const SizedBox(height: 8),
                          
                          // Cevap seçenekleri
                          _buildAnswerOptions(),
                          
                          const SizedBox(height: 12),
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
                  '⛰️ Geometri Dağı',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Şekilleri tanı ve zirveye tırman!',
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
                  '$_correctAnswers',
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('Soru', '$_currentQuestion/$_totalQuestions', '🎯'),
          _buildStatItem('Skor', _score.toString(), '🏆'),
          _buildStatItem('Doğru', '$_correctAnswers', '✅'),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, String emoji) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          emoji,
          style: const TextStyle(fontSize: 18),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.white.withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildMountainArea() {
    return Container(
      height: 170,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFECEFF1), // Kar beyazı
            Color(0xFF90A4AE), // Gri taş
            Color(0xFF5D4037), // Kahverengi
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.5), width: 3),
      ),
      child: Stack(
        children: [
          // Basamaklar (platformlar)
          ..._buildMountainSteps(),
          
          // Tırmanıcı (animasyonlu)
          AnimatedBuilder(
            animation: _climbController,
            builder: (context, child) {
              final currentPos = _climberPosition;
              final verticalPos = 145 - (currentPos * 135);
              final horizontalOffset = math.sin(currentPos * math.pi * 4) * 12;
              
              return Positioned(
                left: MediaQuery.of(context).size.width * 0.35 + horizontalOffset,
                bottom: verticalPos,
                child: Transform.rotate(
                  angle: math.sin(_climbController.value * math.pi * 2) * 0.1,
                  child: const Text(
                    '🧗',
                    style: TextStyle(fontSize: 28),
                  ),
                ),
              );
            },
          ),
          
          // Zirve bayrağı ve konfeti
          Positioned(
            top: 10,
            right: 40,
            child: Column(
              children: [
                const Text('🚩', style: TextStyle(fontSize: 30)),
                if (_climberPosition >= 0.9)
                  const Text('🎉', style: TextStyle(fontSize: 20)),
              ],
            ),
          ),
          
          // Bulutlar
          Positioned(
            top: 30,
            left: 20,
            child: Opacity(
              opacity: 0.6,
              child: const Text('☁️', style: TextStyle(fontSize: 25)),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildMountainSteps() {
    final steps = <Widget>[];
    final random = math.Random(123);
    
    // 5 basamak oluştur
    for (int i = 0; i < 5; i++) {
      final stepProgress = i / 5.0;
      final completed = _climberPosition >= stepProgress + 0.05;
      final isCurrentStep = _climberPosition >= stepProgress && 
                            _climberPosition < stepProgress + 0.2;
      
      // Her basamak için pozisyon
      final bottom = 15.0 + (i * 27.0);
      final left = i % 2 == 0 ? 20.0 : 130.0;
      final width = 80.0;
      final height = 26.0;
      
      steps.add(
        Positioned(
          left: left,
          bottom: bottom,
          child: Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: completed 
                    ? [
                        const Color(0xFF66BB6A).withOpacity(0.8),
                        const Color(0xFF4CAF50).withOpacity(0.8),
                      ]
                    : [
                        const Color(0xFF8D6E63),
                        const Color(0xFF6D4C41),
                      ],
              ),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isCurrentStep 
                    ? const Color(0xFFFFD700)
                    : Colors.white.withOpacity(0.3),
                width: isCurrentStep ? 3 : 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(2, 3),
                ),
              ],
            ),
            child: Center(
              child: completed
                  ? const Text('✓', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold))
                  : Icon(
                      Icons.crop_square,
                      color: Colors.white.withOpacity(0.5),
                      size: 20,
                    ),
            ),
          ),
        ),
      );
    }
    
    return steps;
  }

  Widget _buildQuestionArea() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            '⛰️ Dağdaki boşluğu tamamla!',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF5D4037),
            ),
          ),
          
          const SizedBox(height: 10),
          
          // Dağ basamağı - gerçek kesik/oyuk
          Container(
            width: 160,
            height: 100,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Dağ taşı arka plan
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF8D6E63),
                          Color(0xFF6D4C41),
                          Color(0xFF5D4037),
                        ],
                      ),
                    ),
                    child: CustomPaint(
                      painter: _RockTexturePainter(),
                      size: const Size(160, 100),
                    ),
                  ),
                  
                  // Oyuk/kesik - gerçek boşluk efekti
                  CustomPaint(
                    painter: _ShapeHolePainter(
                      shapeEmoji: _targetShape,
                    ),
                    size: const Size(160, 100),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 8),
          
          Text(
            'Hangi şekil bu boşluğa uyar?',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerOptions() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Aynı şekli seç:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          // 2x2 Grid
          Row(
            children: [
              Expanded(child: _buildAnswerButton(_options[0])),
              const SizedBox(width: 8),
              Expanded(child: _buildAnswerButton(_options[1])),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _buildAnswerButton(_options[2])),
              const SizedBox(width: 8),
              Expanded(child: _buildAnswerButton(_options[3])),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerButton(Map<String, String> option) {
    final isCorrectAnswer = option['emoji'] == _targetShape;
    final isSelected = _isAnswered && option['emoji'] == _targetShape;
    
    Color buttonColor;
    if (_isAnswered) {
      if (isCorrectAnswer) {
        buttonColor = const Color(0xFF66BB6A); // Yeşil
      } else {
        buttonColor = Colors.white.withOpacity(0.3);
      }
    } else {
      buttonColor = Colors.white.withOpacity(0.95);
    }
    
    return GestureDetector(
      onTap: _isAnswered ? null : () => _checkAnswer(option['emoji']!),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: 60,
        decoration: BoxDecoration(
          color: buttonColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFFFFD700) : Colors.white.withOpacity(0.5),
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
        child: Center(
          child: Text(
            option['emoji']!,
            style: const TextStyle(fontSize: 42),
          ),
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
                        ['⭐', '🎉', '✨', '🏆', '👏'][random.nextInt(5)],
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

  List<Widget> _buildFallingSnow() {
    return List.generate(15, (index) {
      final random = math.Random(index);
      return Positioned(
        left: random.nextDouble() * 400,
        top: -50,
        child: AnimatedBuilder(
          animation: _snowController,
          builder: (context, child) {
            final progress = (_snowController.value + (index * 0.1)) % 1.0;
            return Transform.translate(
              offset: Offset(
                math.sin(progress * 2 * math.pi) * 30,
                progress * 800,
              ),
              child: Opacity(
                opacity: 0.7 - (progress * 0.3),
                child: Text(
                  '❄️',
                  style: TextStyle(fontSize: 15 + random.nextDouble() * 10),
                ),
              ),
            );
          },
        ),
      );
    });
  }

  List<Widget> _buildFloatingClouds() {
    return List.generate(3, (index) {
      final random = math.Random(index + 50);
      final yPos = 50.0 + (index * 80);
      
      return Positioned(
        top: yPos,
        child: AnimatedBuilder(
          animation: _cloudController,
          builder: (context, child) {
            final progress = (_cloudController.value + (index * 0.3)) % 1.0;
            return Transform.translate(
              offset: Offset(progress * 450 - 100, 0),
              child: Opacity(
                opacity: 0.6,
                child: Text(
                  '☁️',
                  style: TextStyle(fontSize: 40 + random.nextDouble() * 20),
                ),
              ),
            );
          },
        ),
      );
    });
  }
}

// Dağ yolu çizici
class _MountainPathPainter extends CustomPainter {
  final double progress;

  _MountainPathPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final path = Path();
    
    // Zikzaklı yol çiz
    path.moveTo(size.width * 0.2, size.height);
    
    for (int i = 0; i < 8; i++) {
      final y = size.height - (i * size.height / 8);
      final x = size.width * (0.2 + (i % 2 == 0 ? 0 : 0.4));
      path.lineTo(x, y);
    }

    canvas.drawPath(path, paint);
    
    // İlerleme göstergesi
    final progressPaint = Paint()
      ..color = Colors.yellow.withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    final progressPath = Path();
    progressPath.moveTo(size.width * 0.2, size.height);
    
    final completedSegments = (progress * 8).floor();
    for (int i = 0; i < completedSegments; i++) {
      final y = size.height - (i * size.height / 8);
      final x = size.width * (0.2 + (i % 2 == 0 ? 0 : 0.4));
      progressPath.lineTo(x, y);
    }

    canvas.drawPath(progressPath, progressPaint);
  }

  @override
  bool shouldRepaint(_MountainPathPainter oldDelegate) => 
      oldDelegate.progress != progress;
}

// Kaya dokusu çizici
class _RockTexturePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(42);
    final paint = Paint()
      ..style = PaintingStyle.fill;

    // Rastgele çatlaklar ve noktalar ekle
    for (int i = 0; i < 20; i++) {
      paint.color = Colors.black.withOpacity(0.1 + random.nextDouble() * 0.1);
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final radius = 2 + random.nextDouble() * 4;
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
    
    // Çatlak çizgileri
    for (int i = 0; i < 5; i++) {
      paint
        ..color = Colors.black.withOpacity(0.15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;
      
      final path = Path();
      final startX = random.nextDouble() * size.width;
      final startY = random.nextDouble() * size.height;
      path.moveTo(startX, startY);
      
      for (int j = 0; j < 3; j++) {
        final x = startX + (random.nextDouble() - 0.5) * 30;
        final y = startY + (random.nextDouble() - 0.5) * 30;
        path.lineTo(x, y);
      }
      
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_RockTexturePainter oldDelegate) => false;
}

// Şekil oyuğu çizici - gerçek kesik efekti
class _ShapeHolePainter extends CustomPainter {
  final String shapeEmoji;

  _ShapeHolePainter({required this.shapeEmoji});

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final holeSize = 65.0;
    
    // Oyuk alanı - açık gri/beyaz ile doldur (içi boş görünümü)
    final holePaint = Paint()
      ..color = const Color(0xFFD0D0D0)
      ..style = PaintingStyle.fill;
    
    // Gölge efekti için koyu kenarlık
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    final path = Path();
    
    // Şekle göre oyuk çiz
    switch (shapeEmoji) {
      case '🔵': // Daire
        // Daire oyuk
        canvas.drawCircle(Offset(centerX, centerY), holeSize / 2, holePaint);
        canvas.drawCircle(Offset(centerX, centerY), holeSize / 2, shadowPaint);
        break;
        
      case '🟦': // Kare
        // Kare oyuk
        final rect = RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(centerX, centerY),
            width: holeSize,
            height: holeSize,
          ),
          const Radius.circular(8),
        );
        canvas.drawRRect(rect, holePaint);
        canvas.drawRRect(rect, shadowPaint);
        break;
        
      case '🔺': // Üçgen
      case '🔻':
        // Üçgen oyuk
        path.moveTo(centerX, centerY - holeSize / 2);
        path.lineTo(centerX - holeSize / 2, centerY + holeSize / 2);
        path.lineTo(centerX + holeSize / 2, centerY + holeSize / 2);
        path.close();
        canvas.drawPath(path, holePaint);
        canvas.drawPath(path, shadowPaint);
        break;
        
      case '❤️': // Kalp
      case '💖':
      case '💗':
        // Kalp oyuk
        final heartPath = _createHeartPath(centerX, centerY, holeSize / 2);
        canvas.drawPath(heartPath, holePaint);
        canvas.drawPath(heartPath, shadowPaint);
        break;
        
      case '⭐': // Yıldız
        // Yıldız oyuk
        final starPath = _createStarPath(centerX, centerY, holeSize / 2, 5);
        canvas.drawPath(starPath, holePaint);
        canvas.drawPath(starPath, shadowPaint);
        break;
        
      case '🔶': // Baklava (45° döndürülmüş kare)
        // Baklava oyuk
        path.moveTo(centerX, centerY - holeSize / 2);
        path.lineTo(centerX + holeSize / 2, centerY);
        path.lineTo(centerX, centerY + holeSize / 2);
        path.lineTo(centerX - holeSize / 2, centerY);
        path.close();
        canvas.drawPath(path, holePaint);
        canvas.drawPath(path, shadowPaint);
        break;
        
      default:
        // Varsayılan: daire
        canvas.drawCircle(Offset(centerX, centerY), holeSize / 2, holePaint);
        canvas.drawCircle(Offset(centerX, centerY), holeSize / 2, shadowPaint);
    }
    
    // İçe gölge efekti (oyuk hissi)
    final innerShadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.inner, 4);
    
    switch (shapeEmoji) {
      case '🔵':
      case '💠':
        canvas.drawCircle(Offset(centerX, centerY - 2), holeSize / 2 - 2, innerShadowPaint);
        break;
      case '🟦':
        final innerRect = RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(centerX, centerY - 2),
            width: holeSize - 4,
            height: holeSize - 4,
          ),
          const Radius.circular(6),
        );
        canvas.drawRRect(innerRect, innerShadowPaint);
        break;
      default:
        break;
    }
  }
  
  Path _createHeartPath(double centerX, double centerY, double size) {
    final path = Path();
    path.moveTo(centerX, centerY + size * 0.3);
    
    // Sol üst kurve
    path.cubicTo(
      centerX - size * 0.5, centerY - size * 0.5,
      centerX - size, centerY + size * 0.3,
      centerX, centerY + size * 0.8,
    );
    
    // Sağ üst kurve
    path.cubicTo(
      centerX + size, centerY + size * 0.3,
      centerX + size * 0.5, centerY - size * 0.5,
      centerX, centerY + size * 0.3,
    );
    
    path.close();
    return path;
  }
  
  Path _createStarPath(double centerX, double centerY, double radius, int points) {
    final path = Path();
    final angle = math.pi / points;
    
    for (int i = 0; i < points * 2; i++) {
      final currentAngle = i * angle - math.pi / 2;
      final currentRadius = i.isEven ? radius : radius * 0.5;
      final x = centerX + currentRadius * math.cos(currentAngle);
      final y = centerY + currentRadius * math.sin(currentAngle);
      
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    
    path.close();
    return path;
  }

  @override
  bool shouldRepaint(_ShapeHolePainter oldDelegate) => 
      oldDelegate.shapeEmoji != shapeEmoji;
}

