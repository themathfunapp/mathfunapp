import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'dart:math' as math;
import '../localization/app_localizations.dart';
import '../providers/locale_provider.dart';
import 'game_start_screen.dart';

/// Canlı Düello Ekranı - Optimize Edilmiş Çocuk Tasarımı
class LiveDuelScreen extends StatefulWidget {
  final AgeGroupSelection ageGroup;
  final VoidCallback onBack;

  const LiveDuelScreen({
    super.key,
    required this.ageGroup,
    required this.onBack,
  });

  @override
  State<LiveDuelScreen> createState() => _LiveDuelScreenState();
}

class _LiveDuelScreenState extends State<LiveDuelScreen>
    with TickerProviderStateMixin {
  DuelState _state = DuelState.searching;
  int _playerScore = 0;
  int _opponentScore = 0;
  int _currentRound = 0;
  int _totalRounds = 5;
  bool _isAnswered = false;
  bool _opponentAnswered = false;
  int? _selectedAnswer;
  bool? _isCorrect;
  bool? _opponentCorrect;

  late _DuelQuestion _currentQuestion;
  Timer? _searchTimer;
  Timer? _gameTimer;
  int _timeLeft = 15;
  int _searchTime = 0;

  String _opponentNameKey = '';
  String _opponentAvatar = '';
  int _opponentLevel = 0;

  // Animasyonlar
  late AnimationController _searchController;
  late Animation<double> _searchAnimation;
  late AnimationController _vsController;
  late Animation<double> _vsAnimation;
  late AnimationController _scorePulseController;
  late AnimationController _questionAppearController;
  late AnimationController _correctAnswerController;
  late AnimationController _wrongAnswerController;
  late AnimationController _timePulseController;

  final math.Random _random = math.Random();
  final List<Color> _playerColors = [
    const Color(0xFF4285F4),
    const Color(0xFF34A853),
    const Color(0xFFFBBC05),
    const Color(0xFFEA4335),
  ];
  final List<Color> _opponentColors = [
    const Color(0xFF9C27B0),
    const Color(0xFF673AB7),
    const Color(0xFF3F51B5),
    const Color(0xFF2196F3),
  ];

  final List<Map<String, dynamic>> _characterAvatars = [
    {'emoji': '🧠', 'color': Colors.amber},
    {'emoji': '⚡', 'color': Colors.yellow},
    {'emoji': '🚀', 'color': Colors.blue},
    {'emoji': '🌟', 'color': Colors.purple},
    {'emoji': '🦸', 'color': Colors.red},
    {'emoji': '👑', 'color': Colors.amber},
    {'emoji': '🦊', 'color': Colors.orange},
    {'emoji': '🐱', 'color': Colors.pink},
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startSearch();
  }

  void _initializeAnimations() {
    _searchController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _searchAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _searchController, curve: Curves.easeInOut),
    );

    _vsController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _vsAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _vsController, curve: Curves.elasticOut),
    );

    _scorePulseController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _questionAppearController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _correctAnswerController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _wrongAnswerController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _timePulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _searchTimer?.cancel();
    _gameTimer?.cancel();
    _searchController.dispose();
    _vsController.dispose();
    _scorePulseController.dispose();
    _questionAppearController.dispose();
    _correctAnswerController.dispose();
    _wrongAnswerController.dispose();
    _timePulseController.dispose();
    super.dispose();
  }

  void _startSearch() {
    setState(() {
      _state = DuelState.searching;
      _searchTime = 0;
      _playerScore = 0;
      _opponentScore = 0;
      _currentRound = 0;
    });

    _searchTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _searchTime++;
      });

      if (_searchTime >= _random.nextInt(6) + 3) {
        _findOpponent();
      }
    });
  }

  void _findOpponent() {
    _searchTimer?.cancel();

    final nameKeys = ['opponent_number_champion', 'opponent_math_master', 'opponent_fast_calc', 'opponent_smart_kid', 'opponent_super_brain', 'opponent_genius_cube'];
    final avatar = _characterAvatars[_random.nextInt(_characterAvatars.length)];

    setState(() {
      _opponentNameKey = nameKeys[_random.nextInt(nameKeys.length)];
      _opponentAvatar = avatar['emoji'];
      _opponentLevel = _random.nextInt(20) + 5;
      _state = DuelState.matched;
    });

    _vsController.forward();

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        _startGame();
      }
    });
  }

  void _startGame() {
    setState(() {
      _state = DuelState.playing;
      _currentRound = 1;
    });
    _questionAppearController.forward();
    _generateQuestion();
    _startRoundTimer();
  }

  void _generateQuestion() {
    int num1, num2, answer;
    String operator;

    int maxNum;
    switch (widget.ageGroup) {
      case AgeGroupSelection.preschool:
        maxNum = 10;
        break;
      case AgeGroupSelection.elementary:
        maxNum = 20;
        break;
      case AgeGroupSelection.advanced:
        maxNum = 50;
        break;
    }

    List<String> operators;
    switch (widget.ageGroup) {
      case AgeGroupSelection.preschool:
        operators = ['+', '-'];
        break;
      case AgeGroupSelection.elementary:
        operators = ['+', '-', '×'];
        break;
      case AgeGroupSelection.advanced:
        operators = ['+', '-', '×', '÷'];
        break;
    }

    operator = operators[_random.nextInt(operators.length)];

    switch (operator) {
      case '+':
        num1 = _random.nextInt(maxNum) + 1;
        num2 = _random.nextInt(maxNum) + 1;
        answer = num1 + num2;
        break;
      case '-':
        num1 = _random.nextInt(maxNum) + 1;
        num2 = _random.nextInt(num1) + 1;
        answer = num1 - num2;
        break;
      case '×':
        num1 = _random.nextInt(12) + 1;
        num2 = _random.nextInt(12) + 1;
        answer = num1 * num2;
        break;
      case '÷':
        num2 = _random.nextInt(10) + 1;
        answer = _random.nextInt(10) + 1;
        num1 = num2 * answer;
        break;
      default:
        num1 = _random.nextInt(maxNum) + 1;
        num2 = _random.nextInt(maxNum) + 1;
        answer = num1 + num2;
    }

    List<int> options = [answer];
    while (options.length < 4) {
      int wrong = answer + _random.nextInt(10) - 5;
      if (wrong > 0 && wrong != answer && !options.contains(wrong)) {
        options.add(wrong);
      }
    }
    options.shuffle();

    setState(() {
      _currentQuestion = _DuelQuestion(
        num1: num1,
        num2: num2,
        operator: operator,
        correctAnswer: answer,
        options: options,
      );
      _isAnswered = false;
      _opponentAnswered = false;
      _selectedAnswer = null;
      _isCorrect = null;
      _opponentCorrect = null;
    });

    _questionAppearController.reset();
    _questionAppearController.forward();
  }

  void _startRoundTimer() {
    _gameTimer?.cancel();
    setState(() {
      _timeLeft = 15;
    });

    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeft > 0) {
        setState(() {
          _timeLeft--;
        });

        if (!_opponentAnswered && _random.nextDouble() < 0.12) {
          _simulateOpponentAnswer();
        }
      } else {
        _endRound();
      }
    });
  }

  void _simulateOpponentAnswer() {
    final isCorrect = _random.nextDouble() < 0.75;
    setState(() {
      _opponentAnswered = true;
      _opponentCorrect = isCorrect;
    });

    if (isCorrect) {
      setState(() {
        _opponentScore += 10;
      });
      _scorePulseController.forward(from: 0);
    }
  }

  void _checkAnswer(int answer) {
    if (_isAnswered) return;

    setState(() {
      _isAnswered = true;
      _selectedAnswer = answer;
      _isCorrect = answer == _currentQuestion.correctAnswer;
    });

    if (_isCorrect!) {
      _correctAnswerController.forward();
      setState(() {
        _playerScore += 10;
      });
      _scorePulseController.forward(from: 0);
    } else {
      _wrongAnswerController.forward();
    }

    if (!_opponentAnswered) {
      Future.delayed(Duration(milliseconds: _random.nextInt(1000) + 500), () {
        if (mounted && !_opponentAnswered) {
          _simulateOpponentAnswer();
        }
      });
    }

    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) _endRound();
    });
  }

  void _endRound() {
    _gameTimer?.cancel();

    if (!_opponentAnswered) {
      _simulateOpponentAnswer();
    }

    if (_currentRound >= _totalRounds) {
      _endGame();
    } else {
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) {
          setState(() {
            _currentRound++;
          });
          _generateQuestion();
          _startRoundTimer();
        }
      });
    }
  }

  void _endGame() {
    setState(() {
      _state = DuelState.finished;
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
              Color(0xFF1a2980),
              Color(0xFF26d0ce),
            ],
          ),
        ),
        child: SafeArea(
          child: _buildContent(),
        ),
      ),
    );
  }

  Widget _buildContent() {
    switch (_state) {
      case DuelState.searching:
        return _buildSearchingView();
      case DuelState.matched:
        return _buildMatchedView();
      case DuelState.playing:
        return _buildPlayingView();
      case DuelState.finished:
        return _buildFinishedView();
    }
  }

  Widget _buildSearchingView() {
    final localeProvider = Provider.of<LocaleProvider>(context, listen: true);
    final loc = AppLocalizations(localeProvider.locale);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _searchAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _searchAnimation.value,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Colors.amber, Colors.orange],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.amber.withOpacity(0.5),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(Icons.search, size: 50, color: Colors.white),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 30),
          ShaderMask(
            shaderCallback: (bounds) {
              return LinearGradient(
                colors: [Colors.amber, Colors.orange, Colors.yellow],
              ).createShader(bounds);
            },
            child: Text(
              loc.get('searching_for_opponent'),
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '${_searchTime}s',
            style: const TextStyle(
              fontSize: 20,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 25),
          Container(
            width: 180,
            height: 6,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: LinearProgressIndicator(
              value: _searchTime / 10,
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.amber),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 35),
          FloatingActionButton.extended(
            onPressed: () {
              _searchTimer?.cancel();
              widget.onBack();
            },
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.close),
            label: Text(loc.get('cancel'), style: const TextStyle(fontSize: 16)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchedView() {
    final localeProvider = Provider.of<LocaleProvider>(context, listen: true);
    final loc = AppLocalizations(localeProvider.locale);

    return Center(
      child: ScaleTransition(
        scale: _vsAnimation,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildPlayerCard(
              emoji: '👑',
              name: loc.get('you'),
              level: loc.get('champion'),
              color: _playerColors[_currentRound % _playerColors.length],
              isPlayer: true,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.red, Colors.orange],
                ),
                borderRadius: BorderRadius.circular(40),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.5),
                    blurRadius: 25,
                    spreadRadius: 3,
                  ),
                ],
              ),
              child: const Text(
                'VS',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      blurRadius: 8,
                      color: Colors.black,
                      offset: Offset(2, 2),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildPlayerCard(
              emoji: _opponentAvatar,
              name: loc.get(_opponentNameKey),
              level: '${loc.get('duel_level')} $_opponentLevel',
              color: _opponentColors[_currentRound % _opponentColors.length],
              isPlayer: false,
            ),
            const SizedBox(height: 25),
            Text(
              loc.get('ready_to_play'),
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.amber,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerCard({
    required String emoji,
    required String name,
    required String level,
    required Color color,
    required bool isPlayer,
  }) {
    return Container(
      width: 180,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.8), color],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.5),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Text(
              emoji,
              style: const TextStyle(fontSize: 36),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            name,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            level,
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayingView() {
    final localeProvider = Provider.of<LocaleProvider>(context, listen: true);
    final loc = AppLocalizations(localeProvider.locale);

    return Column(
      children: [
        // Üst skor kartı - DÜZELTİLDİ
        Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.3)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              // Oyuncu kartları yan yana
              Row(
                children: [
                  // SEN kartı - ORTALANDI
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            _playerColors[_currentRound % _playerColors.length]
                                .withOpacity(0.3),
                            _playerColors[_currentRound % _playerColors.length]
                                .withOpacity(0.1),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: _playerColors[_currentRound % _playerColors.length]
                                      .withOpacity(0.5),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            child: const Text(
                              '👑',
                              style: TextStyle(fontSize: 20),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            loc.get('you'),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            '$_playerScore',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.amber,
                              shadows: [
                                Shadow(
                                  blurRadius: 2,
                                  color: Colors.black45,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // VS kartı
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.amber.withOpacity(0.5),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'VS',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Düello',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // RAKİP kartı
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            _opponentColors[_currentRound % _opponentColors.length]
                                .withOpacity(0.3),
                            _opponentColors[_currentRound % _opponentColors.length]
                                .withOpacity(0.1),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: _opponentColors[_currentRound % _opponentColors.length]
                                      .withOpacity(0.5),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            child: Text(
                              _opponentAvatar,
                              style: const TextStyle(fontSize: 20),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            loc.get(_opponentNameKey),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '$_opponentScore',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.amber,
                              shadows: [
                                Shadow(
                                  blurRadius: 2,
                                  color: Colors.black45,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        // Raunt bilgisi ve zamanlayıcı - GÜNCELLENDİ
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.3)),
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
                'RAUNT $_currentRound/$_totalRounds',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              AnimatedBuilder(
                animation: _timePulseController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _timeLeft <= 5 ? 1.0 + _timePulseController.value * 0.1 : 1.0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: _timeLeft <= 5
                              ? [Colors.red, Colors.orange]
                              : [Colors.blue, Colors.green],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: (_timeLeft <= 5 ? Colors.red : Colors.blue).withOpacity(0.5),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.timer, color: Colors.white, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            '$_timeLeft',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),

        // Soru - Küçük ve Yuvarlak
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: AnimatedBuilder(
            animation: _questionAppearController,
            builder: (context, child) {
              return Transform.scale(
                scale: _questionAppearController.value,
                child: Opacity(
                  opacity: _questionAppearController.value,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(50),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.purple.withOpacity(0.4),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                      border: Border.all(color: Colors.white, width: 3),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('🤔', style: TextStyle(fontSize: 28)),
                        const SizedBox(width: 12),
                        Text(
                          '${_currentQuestion.num1} ${_currentQuestion.operator} ${_currentQuestion.num2} = ?',
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                blurRadius: 4,
                                color: Colors.black26,
                                offset: Offset(2, 2),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        if (_isAnswered)
                          AnimatedBuilder(
                            animation: _isCorrect! ? _correctAnswerController : _wrongAnswerController,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: 1.0 + (_isCorrect! ? _correctAnswerController : _wrongAnswerController).value * 0.3,
                                child: Text(
                                  _isCorrect! ? '✅' : '❌',
                                  style: const TextStyle(fontSize: 28),
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 30),

        // Şıklar - Küçük ve Kompakt
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(child: _buildOptionButton(_currentQuestion.options[0])),
                  const SizedBox(width: 10),
                  Expanded(child: _buildOptionButton(_currentQuestion.options[1])),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: _buildOptionButton(_currentQuestion.options[2])),
                  const SizedBox(width: 10),
                  Expanded(child: _buildOptionButton(_currentQuestion.options[3])),
                ],
              ),
            ],
          ),
        ),

      ],
    );
  }

  Widget _buildOptionButton(int option) {
    final isSelected = _selectedAnswer == option;
    final isCorrectAnswer = option == _currentQuestion.correctAnswer;
    final isWrongSelected = isSelected && !isCorrectAnswer;

    Color bgColor;
    Color borderColor;

    if (_isAnswered) {
      if (isCorrectAnswer) {
        bgColor = Colors.green;
        borderColor = Colors.green.shade700;
      } else if (isWrongSelected) {
        bgColor = Colors.red;
        borderColor = Colors.red.shade700;
      } else {
        bgColor = Colors.white.withOpacity(0.15);
        borderColor = Colors.white.withOpacity(0.4);
      }
    } else {
      bgColor = Colors.white.withOpacity(0.2);
      borderColor = Colors.white.withOpacity(0.6);
    }

    return GestureDetector(
      onTap: _isAnswered ? null : () => _checkAnswer(option),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 55,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: borderColor, width: 3),
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
            '$option',
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              shadows: [
                Shadow(
                  blurRadius: 2,
                  color: Colors.black26,
                  offset: Offset(1, 1),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFinishedView() {
    final localeProvider = Provider.of<LocaleProvider>(context, listen: true);
    final loc = AppLocalizations(localeProvider.locale);
    final playerWon = _playerScore > _opponentScore;
    final isDraw = _playerScore == _opponentScore;
    final medalColor = playerWon ? Colors.amber : isDraw ? Colors.blue : Colors.grey;
    final resultText = playerWon ? loc.get('result_congratulations') : isDraw ? loc.get('result_draw') : loc.get('result_try_again');
    final opponentName = loc.get(_opponentNameKey);

    return Center(
      child: SingleChildScrollView(
        child: Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: playerWon
                  ? [const Color(0xFF11998e), const Color(0xFF38ef7d)]
                  : isDraw
                      ? [const Color(0xFF667eea), const Color(0xFF764ba2)]
                      : [const Color(0xFFeb3349), const Color(0xFFf45c43)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: (playerWon ? Colors.green : isDraw ? Colors.blue : Colors.red).withOpacity(0.5),
                blurRadius: 25,
                spreadRadius: 3,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: medalColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: medalColor.withOpacity(0.5),
                      blurRadius: 15,
                      spreadRadius: 3,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    playerWon ? '🏆' : isDraw ? '🤝' : '😢',
                    style: const TextStyle(fontSize: 45),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              ShaderMask(
                shaderCallback: (bounds) {
                  return LinearGradient(
                    colors: [Colors.amber, Colors.white, Colors.amber],
                  ).createShader(bounds);
                },
                child: Text(
                  resultText,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildFinalScoreCard(
                    title: loc.get('you'),
                    score: _playerScore,
                    emoji: '👑',
                    color: Colors.blue,
                  ),
                  _buildFinalScoreCard(
                    title: opponentName,
                    score: _opponentScore,
                    emoji: _opponentAvatar,
                    color: Colors.purple,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              if (playerWon)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber, width: 2),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('🏆', style: TextStyle(fontSize: 20)),
                      const SizedBox(width: 8),
                      Text(
                        loc.get('winnings'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '+$_playerScore XP',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber,
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: widget.onBack,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.2),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.white.withOpacity(0.5)),
                        ),
                        elevation: 8,
                        shadowColor: Colors.black.withOpacity(0.3),
                      ),
                      icon: const Icon(Icons.exit_to_app),
                      label: Text(loc.get('exit_button'), style: const TextStyle(fontSize: 16)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _startSearch,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 8,
                        shadowColor: Colors.amber.withOpacity(0.5),
                      ),
                      icon: const Icon(Icons.refresh),
                      label: Text(loc.get('play_again_action'), style: const TextStyle(fontSize: 16)),
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

  Widget _buildFinalScoreCard({
    required String title,
    required int score,
    required String emoji,
    required Color color,
  }) {
    return Container(
      width: 110,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.3), color.withOpacity(0.1)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.5), width: 2),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 36)),
          const SizedBox(height: 6),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white70,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$score',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.amber,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum DuelState {
  searching,
  matched,
  playing,
  finished,
}

class _DuelQuestion {
  final int num1;
  final int num2;
  final String operator;
  final int correctAnswer;
  final List<int> options;

  _DuelQuestion({
    required this.num1,
    required this.num2,
    required this.operator,
    required this.correctAnswer,
    required this.options,
  });
}