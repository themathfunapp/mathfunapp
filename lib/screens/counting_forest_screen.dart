import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:provider/provider.dart';
import '../localization/app_localizations.dart';
import '../providers/locale_provider.dart';

/// Sayı Ormanı - Eğlenceli Sayma Oyunu
class CountingForestScreen extends StatefulWidget {
  final VoidCallback onBack;

  const CountingForestScreen({super.key, required this.onBack});

  @override
  State<CountingForestScreen> createState() => _CountingForestScreenState();
}

class _CountingForestScreenState extends State<CountingForestScreen>
    with TickerProviderStateMixin {
  late AnimationController _swingController;
  late AnimationController _celebrationController;
  late Animation<double> _swingAnimation;
  
  int _currentLevel = 1;
  int _score = 0;
  int _stars = 0;
  int _targetNumber = 0;
  List<int> _options = [];
  bool _isAnswered = false;
  bool _isCorrect = false;
  
  // Orman hayvanları
  final List<String> _animals = ['🐿️', '🦊', '🦉', '🐻', '🦌', '🐰'];
  final List<String> _fruits = ['🍎', '🍊', '🍇', '🍓', '🍑', '🍒'];
  
  @override
  void initState() {
    super.initState();
    
    _swingController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    
    _swingAnimation = Tween<double>(begin: -0.05, end: 0.05).animate(
      CurvedAnimation(parent: _swingController, curve: Curves.easeInOut),
    );
    
    _celebrationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _generateQuestion();
  }

  @override
  void dispose() {
    _swingController.dispose();
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
        
        // Ses efekti burada çalacak
        // AudioService.play('correct');
        
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            setState(() {
              _currentLevel++;
              _generateQuestion();
            });
          }
        });
      } else {
        // Ses efekti burada çalacak
        // AudioService.play('wrong');
        
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
              Color(0xFF2E7D32), // Koyu yeşil
              Color(0xFF66BB6A), // Orta yeşil
              Color(0xFF81C784), // Açık yeşil
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Arka plan ağaçları
              ..._buildBackgroundTrees(),
              
              // Arka plan animasyonları
              ..._buildFloatingLeaves(),
              
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
                          
                          // Soru bölümü - Ağaçlar ve meyveler
                          _buildQuestionArea(loc),
                          
                          const SizedBox(height: 40),
                          
                          // Cevap seçenekleri
                          _buildAnswerOptions(loc),
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
                  '🌳 ${loc.get('number_forest')}',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  loc.get('count_fruits_subtitle'),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(loc.get('level_label'), _currentLevel.toString(), '🎯'),
          _buildStatItem(loc.get('score'), _score.toString(), '🏆'),
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

  Widget _buildQuestionArea(AppLocalizations loc) {
    final random = math.Random();
    final fruit = _fruits[random.nextInt(_fruits.length)];
    
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
            loc.get('forest_how_many_fruits'),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1B5E20),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Meyveler ve Ağaçlar - Stack ile üst üste
          SizedBox(
            height: 200,
            child: Stack(
              children: [
                // Ağaçlar - Orman görünümü
                // Sol ağaç
                const Positioned(
                  left: 20,
                  bottom: 0,
                  child: Text('🌲', style: TextStyle(fontSize: 70)),
                ),
                // Sol orta ağaç
                const Positioned(
                  left: 80,
                  bottom: 10,
                  child: Text('🌳', style: TextStyle(fontSize: 60)),
                ),
                // Merkez ağaç (büyük)
                const Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Center(
                    child: Text('🌳', style: TextStyle(fontSize: 100)),
                  ),
                ),
                // Sağ orta ağaç
                Positioned(
                  right: 80,
                  bottom: 10,
                  child: Transform.scale(
                    scaleX: -1,
                    child: const Text('🌳', style: TextStyle(fontSize: 60)),
                  ),
                ),
                // Sağ ağaç
                Positioned(
                  right: 20,
                  bottom: 0,
                  child: Transform.scale(
                    scaleX: -1,
                    child: const Text('🌲', style: TextStyle(fontSize: 70)),
                  ),
                ),
                
                // Meyveler üstte - Sallanan animasyon
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: AnimatedBuilder(
                    animation: _swingAnimation,
                    builder: (context, child) {
                      return Transform.rotate(
                        angle: _swingAnimation.value * 0.3,
                        child: Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 8,
                          runSpacing: 8,
                          children: List.generate(
                            _targetNumber,
                            (index) => Transform.scale(
                              scale: 1.0 + (math.sin((index + _swingController.value) * math.pi) * 0.1),
                              child: Text(
                                fruit,
                                style: const TextStyle(fontSize: 32),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
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
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          // 2x2 Grid daha kompakt
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
    final random = math.Random();
    final animal = _animals[random.nextInt(_animals.length)];
    final isCorrectAnswer = number == _targetNumber;
    final isSelected = _isAnswered && number == _targetNumber;
    
    Color buttonColor;
    if (_isAnswered) {
      if (isCorrectAnswer) {
        buttonColor = Colors.green;
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
            color: isSelected ? Colors.yellow : Colors.white.withOpacity(0.5),
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
              animal,
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(width: 8),
            Text(
              number.toString(),
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: _isAnswered && isCorrectAnswer ? Colors.white : const Color(0xFF1B5E20),
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
                        ['⭐', '✨', '🎉', '🎊'][random.nextInt(4)],
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

  List<Widget> _buildBackgroundTrees() {
    return List.generate(8, (index) {
      final random = math.Random(index + 100);
      final trees = ['🌲', '🌳', '🎄'];
      final tree = trees[random.nextInt(trees.length)];
      final size = 30.0 + random.nextDouble() * 40;
      final screenWidth = MediaQuery.of(context).size.width;
      
      return Positioned(
        left: random.nextDouble() * screenWidth,
        top: 100 + random.nextDouble() * 200,
        child: AnimatedBuilder(
          animation: _swingController,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(
                math.sin(_swingController.value * 2 * math.pi + index * 0.5) * 3,
                0,
              ),
              child: Opacity(
                opacity: 0.3 + random.nextDouble() * 0.3,
                child: Text(
                  tree,
                  style: TextStyle(fontSize: size),
                ),
              ),
            );
          },
        ),
      );
    });
  }

  List<Widget> _buildFloatingLeaves() {
    return List.generate(5, (index) {
      final random = math.Random(index);
      return Positioned(
        left: random.nextDouble() * 300,
        top: random.nextDouble() * 600,
        child: AnimatedBuilder(
          animation: _swingController,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(
                math.sin(_swingController.value * 2 * math.pi + index) * 20,
                math.cos(_swingController.value * 2 * math.pi + index) * 15,
              ),
              child: Opacity(
                opacity: 0.6,
                child: Transform.rotate(
                  angle: _swingController.value * 2 * math.pi,
                  child: Text(
                    ['🍃', '🍂'][random.nextInt(2)],
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              ),
            );
          },
        ),
      );
    });
  }
}
