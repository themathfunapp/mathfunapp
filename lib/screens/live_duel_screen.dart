import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math' as math;
import '../localization/app_localizations.dart';
import 'game_start_screen.dart';

/// Canlı Düello Ekranı
/// Gerçek zamanlı 1v1 matematik yarışması
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
  // Oyun durumu
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

  // Soru
  late _DuelQuestion _currentQuestion;

  // Zamanlayıcı
  Timer? _searchTimer;
  Timer? _gameTimer;
  int _timeLeft = 10;
  int _searchTime = 0;

  // Rakip bilgileri
  String _opponentName = '';
  String _opponentEmoji = '';
  int _opponentLevel = 0;

  // Animasyonlar
  late AnimationController _searchController;
  late Animation<double> _searchAnimation;
  late AnimationController _vsController;
  late Animation<double> _vsAnimation;

  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();

    _searchController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _searchAnimation = Tween<double>(begin: 0, end: 2 * math.pi).animate(
      CurvedAnimation(parent: _searchController, curve: Curves.linear),
    );

    _vsController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _vsAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _vsController, curve: Curves.elasticOut),
    );

    _startSearch();
  }

  @override
  void dispose() {
    _searchTimer?.cancel();
    _gameTimer?.cancel();
    _searchController.dispose();
    _vsController.dispose();
    super.dispose();
  }

  void _startSearch() {
    setState(() {
      _state = DuelState.searching;
      _searchTime = 0;
    });

    _searchTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _searchTime++;
      });

      // 3-8 saniye arasında rastgele "rakip bul"
      if (_searchTime >= _random.nextInt(6) + 3) {
        _findOpponent();
      }
    });
  }

  void _findOpponent() {
    _searchTimer?.cancel();

    // Rastgele rakip oluştur
    final names = ['Matematik123', 'SayıUstası', 'HızlıHesap', 'AkıllıÇocuk', 'SuperBrain'];
    final emojis = ['👦', '👧', '👦🏻', '👧🏽', '👦🏿'];

    setState(() {
      _opponentName = names[_random.nextInt(names.length)];
      _opponentEmoji = emojis[_random.nextInt(emojis.length)];
      _opponentLevel = _random.nextInt(20) + 5;
      _state = DuelState.matched;
    });

    _vsController.forward();

    // 2 saniye sonra oyuna başla
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
      _playerScore = 0;
      _opponentScore = 0;
    });
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
  }

  void _startRoundTimer() {
    _gameTimer?.cancel();
    setState(() {
      _timeLeft = 10;
    });

    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeft > 0) {
        setState(() {
          _timeLeft--;
        });

        // Rakip cevaplama simülasyonu
        if (!_opponentAnswered && _random.nextDouble() < 0.15) {
          _simulateOpponentAnswer();
        }
      } else {
        _endRound();
      }
    });
  }

  void _simulateOpponentAnswer() {
    // Rakibin doğru cevap verme olasılığı
    final isCorrect = _random.nextDouble() < 0.7;
    setState(() {
      _opponentAnswered = true;
      _opponentCorrect = isCorrect;
    });
  }

  void _checkAnswer(int answer) {
    if (_isAnswered) return;

    setState(() {
      _isAnswered = true;
      _selectedAnswer = answer;
      _isCorrect = answer == _currentQuestion.correctAnswer;
    });

    if (_isCorrect!) {
      // Zaman bonusu
      final timeBonus = _timeLeft > 5 ? 20 : 10;
      setState(() {
        _playerScore += 100 + timeBonus;
      });
    }

    // Eğer rakip henüz cevaplamadıysa, kısa süre bekle
    if (!_opponentAnswered) {
      Future.delayed(Duration(milliseconds: _random.nextInt(1000) + 500), () {
        if (mounted && !_opponentAnswered) {
          _simulateOpponentAnswer();
        }
      });
    }

    // Raunt sonu
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) _endRound();
    });
  }

  void _endRound() {
    _gameTimer?.cancel();

    // Rakip cevaplamadıysa simüle et
    if (!_opponentAnswered) {
      _simulateOpponentAnswer();
    }

    // Rakip puanı
    if (_opponentCorrect == true) {
      setState(() {
        _opponentScore += 100 + _random.nextInt(30);
      });
    }

    // Sonraki raunt veya oyun sonu
    if (_currentRound >= _totalRounds) {
      _endGame();
    } else {
      Future.delayed(const Duration(milliseconds: 500), () {
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
              Color(0xFF0f0c29),
              Color(0xFF302b63),
              Color(0xFF24243e),
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _searchAnimation,
            builder: (context, child) {
              return Transform.rotate(
                angle: _searchAnimation.value,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.amber,
                      width: 4,
                    ),
                  ),
                  child: const Center(
                    child: Text('⚔️', style: TextStyle(fontSize: 50)),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 32),
          const Text(
            'Rakip Aranıyor...',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${_searchTime}s',
            style: const TextStyle(
              fontSize: 18,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 48),
          GestureDetector(
            onTap: () {
              _searchTimer?.cancel();
              widget.onBack();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'İptal',
                style: TextStyle(color: Colors.white70),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchedView() {
    return Center(
      child: ScaleTransition(
        scale: _vsAnimation,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Oyuncu
            Column(
              children: [
                const Text('👤', style: TextStyle(fontSize: 60)),
                const SizedBox(height: 8),
                const Text(
                  'Sen',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // VS
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Colors.red, Colors.orange],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.5),
                    blurRadius: 20,
                  ),
                ],
              ),
              child: const Text(
                'VS',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Rakip
            Column(
              children: [
                Text(_opponentEmoji, style: const TextStyle(fontSize: 60)),
                const SizedBox(height: 8),
                Text(
                  _opponentName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Lv.$_opponentLevel',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.amber,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayingView() {
    return Column(
      children: [
        // Üst bar - Skor tablosu
        _buildScoreBoard(),

        // Raunt ve zamanlayıcı
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Raunt $_currentRound/$_totalRounds',
                style: const TextStyle(color: Colors.white70),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: _timeLeft <= 3
                      ? Colors.red.withOpacity(0.3)
                      : Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.timer,
                      color: _timeLeft <= 3 ? Colors.red : Colors.white,
                      size: 18,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$_timeLeft',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _timeLeft <= 3 ? Colors.red : Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Soru
        Expanded(
          child: Center(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${_currentQuestion.num1} ${_currentQuestion.operator} ${_currentQuestion.num2} = ?',
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  if (_isAnswered && _isCorrect != null) ...[
                    const SizedBox(height: 12),
                    Icon(
                      _isCorrect! ? Icons.check_circle : Icons.cancel,
                      color: _isCorrect! ? Colors.green : Colors.red,
                      size: 40,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),

        // Rakip durumu
        if (_opponentAnswered)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _opponentCorrect!
                  ? Colors.green.withOpacity(0.2)
                  : Colors.red.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(_opponentEmoji, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                Text(
                  _opponentCorrect! ? 'Doğru cevapladı!' : 'Yanlış cevapladı!',
                  style: TextStyle(
                    color: _opponentCorrect! ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

        const SizedBox(height: 16),

        // Seçenekler
        Padding(
          padding: const EdgeInsets.all(16),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 2.5,
            ),
            itemCount: _currentQuestion.options.length,
            itemBuilder: (context, index) {
              final option = _currentQuestion.options[index];
              return _buildOptionButton(option);
            },
          ),
        ),

        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildScoreBoard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // Oyuncu
          Expanded(
            child: Column(
              children: [
                const Text('👤', style: TextStyle(fontSize: 30)),
                const Text(
                  'Sen',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                Text(
                  '$_playerScore',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber,
                  ),
                ),
              ],
            ),
          ),
          // VS
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'VS',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
          ),
          // Rakip
          Expanded(
            child: Column(
              children: [
                Text(_opponentEmoji, style: const TextStyle(fontSize: 30)),
                Text(
                  _opponentName,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '$_opponentScore',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionButton(int option) {
    final isSelected = _selectedAnswer == option;
    final isCorrectAnswer = option == _currentQuestion.correctAnswer;

    Color bgColor;
    if (_isAnswered) {
      if (isCorrectAnswer) {
        bgColor = Colors.green;
      } else if (isSelected && !isCorrectAnswer) {
        bgColor = Colors.red;
      } else {
        bgColor = Colors.white.withOpacity(0.1);
      }
    } else {
      bgColor = Colors.white.withOpacity(0.15);
    }

    return GestureDetector(
      onTap: () => _checkAnswer(option),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        child: Center(
          child: Text(
            '$option',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFinishedView() {
    final playerWon = _playerScore > _opponentScore;
    final isDraw = _playerScore == _opponentScore;

    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: playerWon
                ? [const Color(0xFF11998e), const Color(0xFF38ef7d)]
                : isDraw
                    ? [const Color(0xFF667eea), const Color(0xFF764ba2)]
                    : [const Color(0xFFeb3349), const Color(0xFFf45c43)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              playerWon ? '🎉 KAZANDIN! 🎉' : isDraw ? '🤝 BERABERE' : '😢 KAYBETTİN',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),

            // Skor karşılaştırması
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    const Text('👤', style: TextStyle(fontSize: 40)),
                    const Text('Sen', style: TextStyle(color: Colors.white70)),
                    Text(
                      '$_playerScore',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const Text(
                  '-',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Column(
                  children: [
                    Text(_opponentEmoji, style: const TextStyle(fontSize: 40)),
                    Text(_opponentName,
                        style: const TextStyle(color: Colors.white70)),
                    Text(
                      '$_opponentScore',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 24),

            if (playerWon)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('🪙', style: TextStyle(fontSize: 24)),
                    SizedBox(width: 8),
                    Text(
                      '+50',
                      style: TextStyle(
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
                  child: GestureDetector(
                    onTap: widget.onBack,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Text(
                          'ÇIKIŞ',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _startSearch(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.amber,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Text(
                          'TEKRAR',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
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

