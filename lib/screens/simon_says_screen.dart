import 'package:flutter/material.dart';
import 'dart:math' as math;

class SimonSaysScreen extends StatefulWidget {
  final String ageGroup;

  const SimonSaysScreen({
    Key? key,
    required this.ageGroup,
  }) : super(key: key);

  @override
  State<SimonSaysScreen> createState() => _SimonSaysScreenState();
}

class _SimonSaysScreenState extends State<SimonSaysScreen>
    with SingleTickerProviderStateMixin {
  int _level = 1;
  int _score = 0;
  List<int> _sequence = [];
  List<int> _playerInput = [];
  bool _isPlaying = false;
  bool _isPlayerTurn = false;
  int _currentFlash = -1;

  final List<Color> _colors = [
    Colors.red,
    Colors.blue,
    Colors.yellow,
    Colors.green,
  ];

  @override
  void initState() {
    super.initState();
    _startGame();
  }

  void _startGame() {
    setState(() {
      _sequence = [];
      _playerInput = [];
      _level = 1;
      _score = 0;
    });
    _addToSequence();
  }

  void _addToSequence() {
    final random = math.Random();
    setState(() {
      _sequence.add(random.nextInt(4));
      _playerInput = [];
      _isPlayerTurn = false;
    });
    _playSequence();
  }

  Future<void> _playSequence() async {
    setState(() {
      _isPlaying = true;
    });
    
    await Future.delayed(const Duration(milliseconds: 500));
    
    for (int i = 0; i < _sequence.length; i++) {
      await _flashButton(_sequence[i]);
      await Future.delayed(const Duration(milliseconds: 300));
    }
    
    setState(() {
      _isPlaying = false;
      _isPlayerTurn = true;
    });
  }

  Future<void> _flashButton(int index) async {
    setState(() {
      _currentFlash = index;
    });
    
    await Future.delayed(const Duration(milliseconds: 600));
    
    setState(() {
      _currentFlash = -1;
    });
  }

  void _onButtonTap(int index) {
    if (!_isPlayerTurn || _isPlaying) return;
    
    setState(() {
      _playerInput.add(index);
      _currentFlash = index;
    });
    
    Future.delayed(const Duration(milliseconds: 200), () {
      setState(() {
        _currentFlash = -1;
      });
    });
    
    // Check if input matches
    if (_playerInput.length == _sequence.length) {
      _checkSequence();
    } else {
      // Check current input
      if (_playerInput.last != _sequence[_playerInput.length - 1]) {
        _gameOver();
      }
    }
  }

  void _checkSequence() {
    bool correct = true;
    for (int i = 0; i < _sequence.length; i++) {
      if (_playerInput[i] != _sequence[i]) {
        correct = false;
        break;
      }
    }
    
    if (correct) {
      setState(() {
        _score += 10;
        _level++;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Doğru! Bir sonraki seviye'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 1),
        ),
      );
      
      Future.delayed(const Duration(milliseconds: 1200), () {
        _addToSequence();
      });
    } else {
      _gameOver();
    }
  }

  void _gameOver() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Oyun Bitti!'),
        content: Text('Seviye: $_level\nPuan: $_score'),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _startGame();
            },
            child: const Text('Tekrar Oyna'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Çık'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue.shade300,
              Colors.blue.shade100,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildTopBar(),
              const SizedBox(height: 20),
              _buildTitle(),
              const Spacer(),
              _buildGameBoard(),
              const Spacer(),
              if (_isPlayerTurn)
                const Text(
                  'Şimdi senin sıran!',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              if (_isPlaying)
                const Text(
                  'Diziyi izle...',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
              const SizedBox(height: 30),
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
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Icons.star, color: Colors.amber),
                const SizedBox(width: 8),
                Text(
                  '$_score',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Seviye $_level',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitle() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            '🎯',
            style: TextStyle(fontSize: 50),
          ),
          const SizedBox(height: 12),
          const Text(
            'Simon Says',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Diziyi hatırla: ${_sequence.length} adım',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameBoard() {
    return Center(
      child: SizedBox(
        width: 300,
        height: 300,
        child: GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: 4,
          itemBuilder: (context, index) {
            bool isFlashing = _currentFlash == index;
            return GestureDetector(
              onTap: () => _onButtonTap(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: isFlashing
                      ? _colors[index]
                      : _colors[index].withOpacity(0.4),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white,
                    width: 4,
                  ),
                  boxShadow: isFlashing
                      ? [
                          BoxShadow(
                            color: _colors[index].withOpacity(0.6),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ]
                      : null,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
