import 'package:flutter/material.dart';
import 'dart:math' as math;

class PatternCompletionScreen extends StatefulWidget {
  final String ageGroup;

  const PatternCompletionScreen({
    Key? key,
    required this.ageGroup,
  }) : super(key: key);

  @override
  State<PatternCompletionScreen> createState() =>
      _PatternCompletionScreenState();
}

class _PatternCompletionScreenState extends State<PatternCompletionScreen> {
  int _level = 1;
  int _score = 0;
  List<String> _pattern = [];
  String _correctAnswer = '';
  List<String> _options = [];

  @override
  void initState() {
    super.initState();
    _generatePattern();
  }

  void _generatePattern() {
    final random = math.Random();
    
    List<Map<String, dynamic>> patterns = [
      {
        'pattern': ['2', '4', '6', '8', '?'],
        'answer': '10',
        'options': ['9', '10', '12'],
      },
      {
        'pattern': ['⭐', '❤️', '⭐', '❤️', '?'],
        'answer': '⭐',
        'options': ['⭐', '❤️', '✨'],
      },
      {
        'pattern': ['🔴', '🔵', '🔴', '🔵', '?'],
        'answer': '🔴',
        'options': ['🔴', '🔵', '🟢'],
      },
      {
        'pattern': ['1', '2', '4', '8', '?'],
        'answer': '16',
        'options': ['12', '14', '16'],
      },
      {
        'pattern': ['10', '20', '30', '40', '?'],
        'answer': '50',
        'options': ['45', '50', '60'],
      },
    ];
    
    var selectedPattern = patterns[random.nextInt(patterns.length)];
    _pattern = List<String>.from(selectedPattern['pattern']);
    _correctAnswer = selectedPattern['answer'];
    _options = List<String>.from(selectedPattern['options']);
    _options.shuffle();
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
              Colors.green.shade300,
              Colors.green.shade100,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildTopBar(),
              const SizedBox(height: 20),
              _buildTitle(),
              const SizedBox(height: 30),
              _buildPatternDisplay(),
              const SizedBox(height: 40),
              _buildOptions(),
              const Spacer(),
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
            '🧩',
            style: TextStyle(fontSize: 50),
          ),
          const SizedBox(height: 12),
          const Text(
            'Desen Tamamlama',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Deseni tamamla!',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatternDisplay() {
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: _pattern.map((item) {
          bool isQuestion = item == '?';
          return Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: isQuestion ? Colors.green.shade100 : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: isQuestion ? Colors.green : Colors.grey.shade300,
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                item,
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: isQuestion ? Colors.green : Colors.black,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildOptions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: _options.map((option) {
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: ElevatedButton(
                onPressed: () => _checkAnswer(option),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: Text(
                  option,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  void _checkAnswer(String answer) {
    if (answer == _correctAnswer) {
      setState(() {
        _score += 10;
        _level++;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Doğru! Harika!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 1),
        ),
      );
      
      Future.delayed(const Duration(milliseconds: 1200), () {
        setState(() {
          _generatePattern();
        });
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Yanlış! Tekrar dene!'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 1),
        ),
      );
    }
  }
}
