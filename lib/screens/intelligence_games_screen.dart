import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../localization/app_localizations.dart';
import '../providers/locale_provider.dart';
import 'memory_cards_screen.dart';
import 'find_different_screen.dart';
import 'pattern_completion_screen.dart';
import 'simon_says_screen.dart';
import 'true_false_math_screen.dart';

class IntelligenceGamesScreen extends StatelessWidget {
  final String ageGroup;

  const IntelligenceGamesScreen({
    Key? key,
    required this.ageGroup,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations(Provider.of<LocaleProvider>(context, listen: false).locale);
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
              _buildTopBar(context, loc),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _buildHeader(loc),
                      const SizedBox(height: 30),
                      _buildGameGrid(context, loc),
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

  Widget _buildTopBar(BuildContext context, AppLocalizations loc) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          const Spacer(),
          Text(
            '🧠 ${loc.intelligenceGames}',
            style: const TextStyle(
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

  Widget _buildHeader(AppLocalizations loc) {
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
            loc.brainDevelopTitle,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.cyan.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            loc.brainDevelopSubtitle,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameGrid(BuildContext context, AppLocalizations loc) {
    final games = [
      {
        'name': loc.gameMemoryCards,
        'subtitle': loc.gameMemoryCardsSubtitle,
        'icon': '🃏',
        'color': Colors.purple,
        'screen': MemoryCardsScreen(ageGroup: ageGroup),
      },
      {
        'name': loc.gameFindDifferent,
        'subtitle': loc.gameFindDifferentSubtitle,
        'icon': '🔍',
        'color': Colors.orange,
        'screen': FindDifferentScreen(ageGroup: ageGroup),
      },
      {
        'name': loc.gamePatternCompletion,
        'subtitle': loc.gamePatternCompletionSubtitle,
        'icon': '🧩',
        'color': Colors.green,
        'screen': PatternCompletionScreen(ageGroup: ageGroup),
      },
      {
        'name': loc.gameSimonSays,
        'subtitle': loc.gameSimonSaysSubtitle,
        'icon': '🎯',
        'color': Colors.blue,
        'screen': SimonSaysScreen(ageGroup: ageGroup),
      },
      {
        'name': loc.gameFastMath,
        'subtitle': loc.gameFastMathSubtitle,
        'icon': '⚡',
        'color': Colors.red,
        'screen': TrueFalseMathScreen(ageGroup: ageGroup),
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
