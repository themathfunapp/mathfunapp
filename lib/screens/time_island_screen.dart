import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../localization/app_localizations.dart';
import '../providers/locale_provider.dart';
import '../services/game_mechanics_service.dart';

class TimeIslandScreen extends StatefulWidget {
  final String ageGroup;

  const TimeIslandScreen({
    Key? key,
    required this.ageGroup,
  }) : super(key: key);

  @override
  State<TimeIslandScreen> createState() => _TimeIslandScreenState();
}

class _TimeIslandScreenState extends State<TimeIslandScreen>
    with TickerProviderStateMixin {
  int _currentQuestion = 0;
  int _score = 0;
  bool _isAnswering = false;
  String _feedback = '';
  
  late AnimationController _sunMoonController;
  late AnimationController _clockController;
  late AnimationController _characterController;
  late AnimationController _feedbackController;
  
  // Saat ayarları
  int _hourHandValue = 12;
  int _minuteHandValue = 0;
  
  // Sorular
  List<Map<String, dynamic>> _questions = [];
  int _totalQuestions = 10;
  
  // Günün zamanı
  int _timeOfDay = 1;
  
  // Karakter animasyonu
  bool _characterIsHappy = false;
  
  // Sürükleme durumu
  bool _isDragging = false;
  String _draggingHand = 'none'; // 'hour' veya 'minute'
  bool _hasShownNoLivesDialog = false;

  @override
  void initState() {
    super.initState();
    
    _sunMoonController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _clockController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _characterController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);
    
    _feedbackController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _generateQuestions();
  }

  @override
  void dispose() {
    _sunMoonController.dispose();
    _clockController.dispose();
    _characterController.dispose();
    _feedbackController.dispose();
    super.dispose();
  }

  void _generateQuestions() {
    _questions.clear();
    final random = math.Random();
    
    for (int i = 0; i < _totalQuestions; i++) {
      // Rastgele saat (1-12) ve dakika (0-59)
      int hour = random.nextInt(12) + 1;
      int minute = random.nextInt(60);
      
      _questions.add({
        'hour': hour,
        'minute': minute,
      });
    }
  }

  void _updateTimeOfDay(int hour) {
    setState(() {
      if (hour >= 0 && hour < 6) {
        _timeOfDay = 0; // Gece
      } else if (hour >= 6 && hour < 12) {
        _timeOfDay = 1; // Sabah
      } else if (hour >= 12 && hour < 18) {
        _timeOfDay = 2; // Öğle
      } else {
        _timeOfDay = 3; // Akşam
      }
    });
    _sunMoonController.forward(from: 0);
  }

  Color _getSkyColor() {
    switch (_timeOfDay) {
      case 0: // Gece
        return const Color(0xFF1a1a2e);
      case 1: // Sabah
        return const Color(0xFF87CEEB);
      case 2: // Öğle
        return const Color(0xFF00BFFF);
      case 3: // Akşam
        return const Color(0xFFFF6B6B);
      default:
        return const Color(0xFF87CEEB);
    }
  }

  void _handlePanStart(Offset localPosition, Size size) {
    // Saatin merkezi (110, 110)
    final center = Offset(size.width / 2, size.height / 2);
    final dx = localPosition.dx - center.dx;
    final dy = localPosition.dy - center.dy;
    
    // Merkezden uzaklığı hesapla
    final distance = math.sqrt(dx * dx + dy * dy);
    final radius = size.width / 2;
    
    print('PanStart - localPos: $localPosition, center: $center, distance: $distance, radius: $radius');
    
    // Hangi ibreye dokunuldu?
    setState(() {
      _isDragging = true;
      if (distance < radius * 0.45) {
        _draggingHand = 'hour'; // Merkeze yakınsa saat akrebi
        print('Hour hand selected');
      } else if (distance < radius * 0.95) {
        _draggingHand = 'minute'; // Dışarıdaysa dakika ibresi
        print('Minute hand selected');
      } else {
        _draggingHand = 'none'; // Çok dışardaysa hiçbiri
        print('No hand selected');
      }
    });
  }

  void _handlePanUpdate(Offset localPosition, Size size) {
    if (!_isDragging || _draggingHand == 'none') return;
    
    // Saatin merkezi
    final center = Offset(size.width / 2, size.height / 2);
    final dx = localPosition.dx - center.dx;
    final dy = localPosition.dy - center.dy;
    
    // Açıyı hesapla (-90 derece offset ile 12'den başlar)
    double angle = math.atan2(dy, dx) + math.pi / 2;
    if (angle < 0) angle += 2 * math.pi;
    
    print('PanUpdate - angle: ${angle * 180 / math.pi} degrees, hand: $_draggingHand');
    
    setState(() {
      if (_draggingHand == 'hour') {
        // Saat akrebi (12 bölüm)
        double hours = (angle / (2 * math.pi)) * 12;
        _hourHandValue = hours.round() % 12;
        if (_hourHandValue == 0) _hourHandValue = 12;
        _updateTimeOfDay(_hourHandValue);
        print('Hour set to: $_hourHandValue');
      } else if (_draggingHand == 'minute') {
        // Dakika ibresi (60 bölüm)
        double minutes = (angle / (2 * math.pi)) * 60;
        _minuteHandValue = minutes.round() % 60;
        print('Minute set to: $_minuteHandValue');
      }
    });
  }

  void _handlePanEnd() {
    setState(() {
      _isDragging = false;
      _draggingHand = 'none';
    });
  }

  void _checkAnswer() {
    if (_isAnswering) return;

    final mechanicsService = Provider.of<GameMechanicsService>(context, listen: false);
    if (!mechanicsService.hasLives) return;

    final question = _questions[_currentQuestion];
    int targetHour = question['hour'];
    int targetMinute = question['minute'];

    // Saat ve dakikayı kontrol et (±2 dakika tolerans)
    int adjustedHour = _hourHandValue % 12;
    if (adjustedHour == 0) adjustedHour = 12;
    if (targetHour > 12) targetHour = targetHour - 12;

    bool hourCorrect = adjustedHour == targetHour;
    bool minuteCorrect = (_minuteHandValue - targetMinute).abs() <= 2; // 2 dakika tolerans

    bool isCorrect = hourCorrect && minuteCorrect;

    setState(() {
      _isAnswering = true;
      _characterIsHappy = isCorrect;

      if (isCorrect) {
        _score += 10;
        _feedback = '🎉 Harika! Doğru saat!';
        _clockController.forward(from: 0);
      } else {
        mechanicsService.onWrongAnswer();
        _feedback = '⏰ Tekrar deneyin!';
        if (!mechanicsService.hasLives) {
          _showGameOver();
          return;
        }
      }
    });
    
    _feedbackController.forward(from: 0).then((_) {
      if (isCorrect) {
        Future.delayed(const Duration(seconds: 1), () {
          if (_currentQuestion < _totalQuestions - 1) {
            setState(() {
              _currentQuestion++;
              _feedback = '';
              _isAnswering = false;
              _characterIsHappy = false;
              _hourHandValue = 12;
              _minuteHandValue = 0;
              _isDragging = false;
              _draggingHand = 'none';
            });
          } else {
            _showVictory();
          }
        });
      } else {
        Future.delayed(const Duration(seconds: 1), () {
          setState(() {
            _feedback = '';
            _isAnswering = false;
            _characterIsHappy = false;
          });
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
            Icon(Icons.hourglass_empty, color: Colors.amber, size: 32),
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
              Navigator.of(context).pop();
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
            Icon(Icons.hourglass_empty, color: Colors.amber, size: 28),
            const SizedBox(width: 8),
            Text(loc.get('lives_finished'), textAlign: TextAlign.center),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(loc.get('no_lives_play'), textAlign: TextAlign.center),
            const SizedBox(height: 10),
            Text(loc.get('time_score_label').replaceAll('{0}', '$_score'), 
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: Text(loc.get('time_exit')),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _currentQuestion = 0;
                _score = 0;
                _isDragging = false;
                _draggingHand = 'none';
                _generateQuestions();
              });
            },
            child: Text(loc.get('time_try_again')),
          ),
        ],
      ),
    );
  }

  void _showVictory() {
    final loc = AppLocalizations(Provider.of<LocaleProvider>(context, listen: false).locale);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(loc.get('time_congratulations'), textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(loc.get('time_island_completed'), textAlign: TextAlign.center),
            const SizedBox(height: 10),
            Text(loc.get('time_total_score').replaceAll('{0}', '$_score'), 
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text(loc.get('time_master_badge')),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: Text(loc.get('time_complete')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_questions.isEmpty) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final mechanicsService = Provider.of<GameMechanicsService>(context, listen: true);
    if (!mechanicsService.hasLives && !_hasShownNoLivesDialog) {
      _hasShownNoLivesDialog = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showNoLivesDialog();
      });
    }

    final question = _questions[_currentQuestion];
    
    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(seconds: 2),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              _getSkyColor(),
              _getSkyColor().withOpacity(0.7),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildTopBar(),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildSunMoon(),
                      _buildCharacter(),
                      _buildQuestionCard(question),
                      _buildInstructions(),
                      _buildClock(question),
                      if (_feedback.isNotEmpty) _buildFeedback(),
                      _buildCheckButton(),
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

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
            onPressed: () => Navigator.pop(context),
          ),
          const Spacer(),
          // Canlar - kum saati şeklinde, profile bağlı (5 can)
          Consumer<GameMechanicsService>(
            builder: (context, mechanicsService, _) {
              final lives = mechanicsService.currentLives;
              final maxLives = mechanicsService.maxLives;
              return Row(
                children: List.generate(maxLives, (index) {
                  return Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Icon(
                      index < lives ? Icons.hourglass_top : Icons.hourglass_empty,
                      color: index < lives ? Colors.amber : Colors.white.withOpacity(0.4),
                      size: 26,
                    ),
                  );
                }),
              );
            },
          ),
          const SizedBox(width: 16),
          // Puan
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 24),
                const SizedBox(width: 4),
                Text(
                  '$_score',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSunMoon() {
    return AnimatedBuilder(
      animation: _sunMoonController,
      builder: (context, child) {
        return SizedBox(
          height: 40,
          child: Center(
            child: AnimatedOpacity(
              duration: const Duration(seconds: 1),
              opacity: _timeOfDay == 0 ? 0.3 : 1.0,
              child: Text(
                _timeOfDay == 0 ? '🌙' : '☀️',
                style: const TextStyle(fontSize: 30),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCharacter() {
    return AnimatedBuilder(
      animation: _characterController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, math.sin(_characterController.value * 2 * math.pi) * 3),
          child: AnimatedScale(
            scale: _characterIsHappy ? 1.2 : 1.0,
            duration: const Duration(milliseconds: 300),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                _characterIsHappy ? '🤩' : '⏰',
                style: const TextStyle(fontSize: 35),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuestionCard(Map<String, dynamic> question) {
    final localeProvider = Provider.of<LocaleProvider>(context, listen: true);
    final localizations = AppLocalizations(localeProvider.locale);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            '${localizations.get('question')} ${_currentQuestion + 1}/$_totalQuestions',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: (_currentQuestion + 1) / _totalQuestions,
            backgroundColor: Colors.grey[200],
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
            minHeight: 6,
            borderRadius: BorderRadius.circular(3),
          ),
          const SizedBox(height: 10),
          Text(
            localizations.get('time_set_clock_format')
                .replaceAll('{0}', (question['hour'] as int).toString().padLeft(2, '0'))
                .replaceAll('{1}', (question['minute'] as int).toString().padLeft(2, '0')),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildInstructions() {
    final loc = AppLocalizations(Provider.of<LocaleProvider>(context, listen: true).locale);
    String instruction = '';
    Color bgColor = Colors.amber.withOpacity(0.2);
    Color borderColor = Colors.amber.withOpacity(0.5);
    IconData icon = Icons.touch_app;
    Color iconColor = Colors.amber;
    
    if (_isDragging && _draggingHand == 'hour') {
      instruction = loc.get('time_dragging_hour');
      bgColor = Colors.red.withOpacity(0.2);
      borderColor = Colors.red.withOpacity(0.5);
      icon = Icons.pan_tool;
      iconColor = Colors.red;
    } else if (_isDragging && _draggingHand == 'minute') {
      instruction = loc.get('time_dragging_minute');
      bgColor = Colors.blue.withOpacity(0.2);
      borderColor = Colors.blue.withOpacity(0.5);
      icon = Icons.pan_tool;
      iconColor = Colors.blue;
    } else {
      instruction = loc.get('time_drag_hint');
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: 8),
          Text(
            instruction,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClock(Map<String, dynamic> question) {
    return Column(
      children: [
        // Saat göstergesi
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.9),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.access_time, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                '${_hourHandValue.toString().padLeft(2, '0')}:${_minuteHandValue.toString().padLeft(2, '0')}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        
        // Saat - LayoutBuilder ile kesin pozisyon
        Center(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return GestureDetector(
                onPanStart: (details) {
                  // Widget'ın RenderBox'ını al
                  final RenderBox? box = context.findRenderObject() as RenderBox?;
                  if (box == null) return;
                  
                  // Global pozisyonu local pozisyona çevir
                  final localPosition = box.globalToLocal(details.globalPosition);
                  
                  // Saat merkezine göre hesapla (110, 110 - saatin merkezi)
                  _handlePanStart(localPosition, const Size(220, 220));
                },
                onPanUpdate: (details) {
                  final RenderBox? box = context.findRenderObject() as RenderBox?;
                  if (box == null) return;
                  
                  final localPosition = box.globalToLocal(details.globalPosition);
                  _handlePanUpdate(localPosition, const Size(220, 220));
                },
                onPanEnd: (details) {
                  _handlePanEnd();
                },
                child: Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: CustomPaint(
                    size: const Size(220, 220),
                    painter: _ClockPainter(
                      hour: _hourHandValue,
                      minute: _minuteHandValue,
                      isAnimating: _clockController.isAnimating,
                      isDraggingHour: _isDragging && _draggingHand == 'hour',
                      isDraggingMinute: _isDragging && _draggingHand == 'minute',
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }


  Widget _buildFeedback() {
    return AnimatedBuilder(
      animation: _feedbackController,
      builder: (context, child) {
        return Transform.scale(
          scale: 1.0 + (_feedbackController.value * 0.2),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: _characterIsHappy 
                ? Colors.green.withOpacity(0.9)
                : Colors.orange.withOpacity(0.9),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              _feedback,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCheckButton() {
    final loc = AppLocalizations(Provider.of<LocaleProvider>(context, listen: true).locale);
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isAnswering ? null : _checkAnswer,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 5,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, size: 24),
            const SizedBox(width: 8),
            Text(
              loc.get('time_check_button'),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ClockPainter extends CustomPainter {
  final int hour;
  final int minute;
  final bool isAnimating;
  final bool isDraggingHour;
  final bool isDraggingMinute;

  _ClockPainter({
    required this.hour,
    required this.minute,
    required this.isAnimating,
    required this.isDraggingHour,
    required this.isDraggingMinute,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Saat çerçevesi
    final framePaint = Paint()
      ..color = Colors.brown.shade400
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6;
    canvas.drawCircle(center, radius, framePaint);

    // Saat arka planı
    final bgPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius - 3, bgPaint);

    // Saat rakamları
    final textPainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );

    for (int i = 1; i <= 12; i++) {
      final angle = (i * 30 - 90) * math.pi / 180;
      final x = center.dx + (radius - 30) * math.cos(angle);
      final y = center.dy + (radius - 30) * math.sin(angle);

      textPainter.text = TextSpan(
        text: i.toString(),
        style: TextStyle(
          color: Colors.black87,
          fontSize: i % 3 == 0 ? 18 : 14,
          fontWeight: i % 3 == 0 ? FontWeight.bold : FontWeight.w600,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, y - textPainter.height / 2),
      );
    }

    // Dakika çizgileri
    for (int i = 0; i < 60; i++) {
      if (i % 5 != 0) {
        final angle = (i * 6 - 90) * math.pi / 180;
        final startX = center.dx + (radius - 15) * math.cos(angle);
        final startY = center.dy + (radius - 15) * math.sin(angle);
        final endX = center.dx + (radius - 10) * math.cos(angle);
        final endY = center.dy + (radius - 10) * math.sin(angle);

        final tickPaint = Paint()
          ..color = Colors.grey.shade400
          ..strokeWidth = 1;
        canvas.drawLine(Offset(startX, startY), Offset(endX, endY), tickPaint);
      }
    }

    // Dakika ibresi (mavi - uzun)
    final minuteAngle = (minute * 6 - 90) * math.pi / 180;
    final minuteHandPaint = Paint()
      ..color = isDraggingMinute ? Colors.blue.shade900 : Colors.blue.shade700
      ..strokeWidth = isDraggingMinute ? 7 : 5
      ..strokeCap = StrokeCap.round;
    
    // Sürükleme sırasında gölge ekle
    if (isDraggingMinute) {
      final shadowPaint = Paint()
        ..color = Colors.blue.withOpacity(0.3)
        ..strokeWidth = 10
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
        center,
        Offset(
          center.dx + (radius - 35) * math.cos(minuteAngle),
          center.dy + (radius - 35) * math.sin(minuteAngle),
        ),
        shadowPaint,
      );
    }
    
    canvas.drawLine(
      center,
      Offset(
        center.dx + (radius - 35) * math.cos(minuteAngle),
        center.dy + (radius - 35) * math.sin(minuteAngle),
      ),
      minuteHandPaint,
    );

    // Saat akrebi (kırmızı - kısa)
    final hourAngle = ((hour % 12) * 30 + minute * 0.5 - 90) * math.pi / 180;
    final hourHandPaint = Paint()
      ..color = isDraggingHour ? Colors.red.shade900 : Colors.red.shade700
      ..strokeWidth = isDraggingHour ? 9 : 7
      ..strokeCap = StrokeCap.round;
    
    // Sürükleme sırasında gölge ekle
    if (isDraggingHour) {
      final shadowPaint = Paint()
        ..color = Colors.red.withOpacity(0.3)
        ..strokeWidth = 12
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
        center,
        Offset(
          center.dx + (radius - 60) * math.cos(hourAngle),
          center.dy + (radius - 60) * math.sin(hourAngle),
        ),
        shadowPaint,
      );
    }
    
    canvas.drawLine(
      center,
      Offset(
        center.dx + (radius - 60) * math.cos(hourAngle),
        center.dy + (radius - 60) * math.sin(hourAngle),
      ),
      hourHandPaint,
    );

    // Merkez noktası
    final centerPaint = Paint()
      ..color = Colors.black87
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 8, centerPaint);

    // Animasyon efekti (doğru cevap)
    if (isAnimating) {
      final animPaint = Paint()
        ..color = Colors.green.withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5;
      canvas.drawCircle(center, radius - 3, animPaint);
    }
  }

  @override
  bool shouldRepaint(_ClockPainter oldDelegate) {
    return oldDelegate.hour != hour ||
        oldDelegate.minute != minute ||
        oldDelegate.isAnimating != isAnimating ||
        oldDelegate.isDraggingHour != isDraggingHour ||
        oldDelegate.isDraggingMinute != isDraggingMinute;
  }
}
