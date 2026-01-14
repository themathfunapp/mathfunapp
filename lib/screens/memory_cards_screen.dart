import 'package:flutter/material.dart';
import 'dart:math' as math;

class MemoryCardsScreen extends StatefulWidget {
  final String ageGroup;

  const MemoryCardsScreen({
    Key? key,
    required this.ageGroup,
  }) : super(key: key);

  @override
  State<MemoryCardsScreen> createState() => _MemoryCardsScreenState();
}

class _MemoryCardsScreenState extends State<MemoryCardsScreen> {
  int _level = 1; // 1: Kolay (6 kart), 2: Orta (12 kart), 3: Zor (16 kart)
  int _score = 0;
  int _moves = 0;
  
  List<String> _cards = [];
  List<bool> _revealed = [];
  List<bool> _matched = [];
  int? _firstCardIndex;
  int? _secondCardIndex;

  @override
  void initState() {
    super.initState();
    _initializeGame();
  }

  void _initializeGame() {
    int pairCount = _level == 1 ? 3 : (_level == 2 ? 6 : 8);
    
    // Matematik eşleştirmeleri
    List<List<String>> pairs = [
      ['3+2', '5'],
      ['2×3', '6'],
      ['🍎🍎🍎', '3'],
      ['⭐⭐⭐⭐', '4'],
      ['10÷2', '5'],
      ['4+4', '8'],
      ['3×3', '9'],
      ['12÷3', '4'],
    ];
    
    _cards = [];
    for (int i = 0; i < pairCount; i++) {
      _cards.add(pairs[i][0]);
      _cards.add(pairs[i][1]);
    }
    _cards.shuffle();
    
    _revealed = List.filled(_cards.length, false);
    _matched = List.filled(_cards.length, false);
    _moves = 0;
    _firstCardIndex = null;
    _secondCardIndex = null;
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
              Colors.purple.shade300,
              Colors.purple.shade100,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildTopBar(),
              _buildScoreBar(),
              Expanded(
                child: Center(
                  child: _buildCardGrid(),
                ),
              ),
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
          const Text(
            '🃏 Hafıza Kartları',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _initializeGame();
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildScoreBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('Seviye', '$_level'),
          _buildStatItem('Puan', '$_score'),
          _buildStatItem('Hamle', '$_moves'),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.purple,
          ),
        ),
      ],
    );
  }

  Widget _buildCardGrid() {
    int columns = _level == 1 ? 3 : 4;
    
    return GridView.builder(
      shrinkWrap: true,
      padding: const EdgeInsets.all(20),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.8,
      ),
      itemCount: _cards.length,
      itemBuilder: (context, index) {
        return _buildCard(index);
      },
    );
  }

  Widget _buildCard(int index) {
    bool isRevealed = _revealed[index] || _matched[index];
    
    return GestureDetector(
      onTap: () => _onCardTap(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          color: isRevealed ? Colors.white : Colors.purple.shade400,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: _matched[index] ? Colors.green : Colors.purple.shade600,
            width: _matched[index] ? 3 : 2,
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
          child: isRevealed
              ? Text(
                  _cards[index],
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                )
              : const Text(
                  '❓',
                  style: TextStyle(fontSize: 40),
                ),
        ),
      ),
    );
  }

  void _onCardTap(int index) {
    if (_revealed[index] || _matched[index]) return;
    if (_firstCardIndex != null && _secondCardIndex != null) return;
    
    setState(() {
      _revealed[index] = true;
      
      if (_firstCardIndex == null) {
        _firstCardIndex = index;
      } else if (_secondCardIndex == null) {
        _secondCardIndex = index;
        _moves++;
        
        // Check match after delay
        Future.delayed(const Duration(seconds: 1), () {
          _checkMatch();
        });
      }
    });
  }

  void _checkMatch() {
    if (_firstCardIndex == null || _secondCardIndex == null) return;
    
    // Check if cards match (implement matching logic)
    bool isMatch = _cards[_firstCardIndex!] == _cards[_secondCardIndex!] ||
                   (_cards[_firstCardIndex!] == '3+2' && _cards[_secondCardIndex!] == '5') ||
                   (_cards[_firstCardIndex!] == '5' && _cards[_secondCardIndex!] == '3+2');
    
    setState(() {
      if (isMatch) {
        _matched[_firstCardIndex!] = true;
        _matched[_secondCardIndex!] = true;
        _score += 10;
      } else {
        _revealed[_firstCardIndex!] = false;
        _revealed[_secondCardIndex!] = false;
      }
      
      _firstCardIndex = null;
      _secondCardIndex = null;
      
      // Check if all matched
      if (_matched.every((m) => m)) {
        _showLevelComplete();
      }
    });
  }

  void _showLevelComplete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🎉 Tebrikler!'),
        content: Text('Seviye $_level tamamlandı!\nHamle sayısı: $_moves'),
        actions: [
          if (_level < 3)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  _level++;
                  _initializeGame();
                });
              },
              child: const Text('Sonraki Seviye'),
            ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Bitir'),
          ),
        ],
      ),
    );
  }
}
