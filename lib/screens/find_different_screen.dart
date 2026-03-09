import 'package:flutter/material.dart';
import 'dart:math' as math;

class FindDifferentScreen extends StatefulWidget {
  final String ageGroup;

  const FindDifferentScreen({
    Key? key,
    required this.ageGroup,
  }) : super(key: key);

  @override
  State<FindDifferentScreen> createState() => _FindDifferentScreenState();
}

class _FindDifferentScreenState extends State<FindDifferentScreen> {
  int _level = 1;
  int _score = 0;
  int _correctIndex = 0;
  List<String> _items = [];

  @override
  void initState() {
    super.initState();
    _generateQuestion();
  }

  void _generateQuestion() {
    final random = math.Random();
    
    // Farklı soru tipleri
    List<Map<String, dynamic>> questionTypes = [
      {
        'type': 'numbers',
        'items': ['5', '5', '5', '7', '5', '5'],
        'different': '7',
      },
      {
        'type': 'shapes',
        'items': ['⭐', '⭐', '⭐', '❤️', '⭐', '⭐'],
        'different': '❤️',
      },
      {
        'type': 'operations',
        'items': ['2+2', '1+3', '5-1', '3×2', '8÷2', '0+4'],
        'different': '3×2',
      },
    ];
    
    var question = questionTypes[random.nextInt(questionTypes.length)];
    _items = List<String>.from(question['items']);
    _items.shuffle();
    
    _correctIndex = _items.indexOf(question['different']);
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
              Colors.orange.shade300,
              Colors.orange.shade100,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildTopBar(),
              const SizedBox(height: 20),
              _buildTitle(),
              Expanded(
                child: _buildItemsGrid(),
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
      margin: const EdgeInsets.symmetric(horizontal: 32),
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
            '🔍',
            style: TextStyle(fontSize: 50),
          ),
          const SizedBox(height: 12),
          const Text(
            'Farklı Olanı Bul!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Diğerlerinden farklı olanı bul',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsGrid() {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        mainAxisExtent: 55,
      ),
      itemCount: _items.length,
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () => _checkAnswer(index),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.orange.shade300,
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Center(
              child: Text(
                _items[index],
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        );
      },
    );
  }

  void _checkAnswer(int index) {
    if (index == _correctIndex) {
      // Doğru cevap!
      setState(() {
        _score += 10;
        _level++;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Doğru! Aferin!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 1),
        ),
      );
      
      Future.delayed(const Duration(milliseconds: 1200), () {
        setState(() {
          _generateQuestion();
        });
      });
    } else {
      // Yanlış cevap
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
