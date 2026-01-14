import 'package:flutter/material.dart';
import 'memory_cards_screen.dart';
import 'find_different_screen.dart';
import 'pattern_completion_screen.dart';
import 'simon_says_screen.dart';
import 'true_false_math_screen.dart';
import 'tangram_screen.dart';

class IntelligenceGamesScreen extends StatelessWidget {
  final String ageGroup;

  const IntelligenceGamesScreen({
    Key? key,
    required this.ageGroup,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.cyan.shade300,
              Colors.blue.shade500,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildTopBar(context),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 30),
                      _buildGameGrid(context),
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

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          const Spacer(),
          const Text(
            '🧠 Zeka Oyunları',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const Spacer(),
          const SizedBox(width: 48), // Balance for back button
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
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
            style: TextStyle(fontSize: 60),
          ),
          const SizedBox(height: 12),
          Text(
            'Beynini Geliştir!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.cyan.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Eğlenceli oyunlarla zekânı test et',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameGrid(BuildContext context) {
    final games = [
      {
        'name': 'Hafıza Kartları',
        'subtitle': 'Eşleştir ve hatırla',
        'icon': '🃏',
        'color': Colors.purple,
        'screen': MemoryCardsScreen(ageGroup: ageGroup),
      },
      {
        'name': 'Farklı Olanı Bul',
        'subtitle': 'Dikkatini test et',
        'icon': '🔍',
        'color': Colors.orange,
        'screen': FindDifferentScreen(ageGroup: ageGroup),
      },
      {
        'name': 'Desen Tamamlama',
        'subtitle': 'Mantık yürüt',
        'icon': '🧩',
        'color': Colors.green,
        'screen': PatternCompletionScreen(ageGroup: ageGroup),
      },
      {
        'name': 'Simon Says',
        'subtitle': 'Diziyi hatırla',
        'icon': '🎯',
        'color': Colors.blue,
        'screen': SimonSaysScreen(ageGroup: ageGroup),
      },
      {
        'name': 'Hızlı Matematik',
        'subtitle': 'Doğru mu Yanlış mı?',
        'icon': '⚡',
        'color': Colors.red,
        'screen': TrueFalseMathScreen(ageGroup: ageGroup),
      },
      {
        'name': 'Tangram',
        'subtitle': 'Şekilleri birleştir',
        'icon': '🔺',
        'color': Colors.teal,
        'screen': TangramScreen(ageGroup: ageGroup),
      },
    ];

    return Column(
      children: games.map((game) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _buildGameCard(
            context,
            name: game['name'] as String,
            subtitle: game['subtitle'] as String,
            icon: game['icon'] as String,
            color: game['color'] as Color,
            screen: game['screen'] as Widget,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildGameCard(
    BuildContext context, {
    required String name,
    required String subtitle,
    required String icon,
    required Color color,
    required Widget screen,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => screen),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color,
              color.withOpacity(0.7),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Center(
                child: Text(
                  icon,
                  style: const TextStyle(fontSize: 40),
                ),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: Colors.white,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}
