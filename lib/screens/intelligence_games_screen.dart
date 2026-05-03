import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../localization/app_localizations.dart';
import '../providers/locale_provider.dart';
import '../services/daily_reward_service.dart';
import '../services/game_mechanics_service.dart';
import 'memory_cards_screen.dart';
import 'find_different_screen.dart';
import 'pattern_completion_screen.dart';
import 'simon_says_screen.dart';
import 'true_false_math_screen.dart';
import '../widgets/responsive_top_bar_title_row.dart';

class IntelligenceGamesScreen extends StatefulWidget {
  final String ageGroup;

  const IntelligenceGamesScreen({
    Key? key,
    required this.ageGroup,
  }) : super(key: key);

  @override
  State<IntelligenceGamesScreen> createState() => _IntelligenceGamesScreenState();
}

class _IntelligenceGamesScreenState extends State<IntelligenceGamesScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bounce;

  @override
  void initState() {
    super.initState();
    _bounce = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeGrantBrainDailyBonus());
  }

  @override
  void dispose() {
    _bounce.dispose();
    super.dispose();
  }

  Future<void> _maybeGrantBrainDailyBonus() async {
    if (!mounted) return;
    final mechanics = Provider.of<GameMechanicsService>(context, listen: false);
    final granted = await mechanics.tryGrantDailyBrainGamesEntryBonus();
    if (!mounted || !granted) return;

    try {
      final daily = Provider.of<DailyRewardService>(context, listen: false);
      await daily.refresh();
    } catch (_) {}

    if (!mounted) return;
    final loc = AppLocalizations(Provider.of<LocaleProvider>(context, listen: false).locale);
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      transitionDuration: const Duration(milliseconds: 520),
      pageBuilder: (ctx, animation, secondaryAnimation) {
        return Center(
          child: _KidBrainDailyRewardDialog(
            loc: loc,
            bounce: _bounce,
            onOk: () => Navigator.of(ctx).pop(),
          ),
        );
      },
      transitionBuilder: (ctx, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(parent: animation, curve: Curves.elasticOut);
        return FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.65, end: 1.0).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

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
      child: ResponsiveTopBarTitleRow(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: '🧠 ${loc.intelligenceGames}',
        titleStyle: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
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
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.cyan.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            loc.brainDevelopSubtitle,
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
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
        'screen': MemoryCardsScreen(ageGroup: widget.ageGroup),
      },
      {
        'name': loc.gameFindDifferent,
        'subtitle': loc.gameFindDifferentSubtitle,
        'icon': '🔍',
        'color': Colors.orange,
        'screen': FindDifferentScreen(ageGroup: widget.ageGroup),
      },
      {
        'name': loc.gamePatternCompletion,
        'subtitle': loc.gamePatternCompletionSubtitle,
        'icon': '🧩',
        'color': Colors.green,
        'screen': PatternCompletionScreen(ageGroup: widget.ageGroup),
      },
      {
        'name': loc.gameSimonSays,
        'subtitle': loc.gameSimonSaysSubtitle,
        'icon': '🎯',
        'color': Colors.blue,
        'screen': SimonSaysScreen(ageGroup: widget.ageGroup),
      },
      {
        'name': loc.gameFastMath,
        'subtitle': loc.gameFastMathSubtitle,
        'icon': '⚡',
        'color': Colors.red,
        'screen': TrueFalseMathScreen(ageGroup: widget.ageGroup),
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

class _KidBrainDailyRewardDialog extends StatelessWidget {
  final AppLocalizations loc;
  final Animation<double> bounce;
  final VoidCallback onOk;

  const _KidBrainDailyRewardDialog({
    required this.loc,
    required this.bounce,
    required this.onOk,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 340),
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF7C4DFF),
                Color(0xFF00BCD4),
                Color(0xFFFFC107),
              ],
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00BCD4).withValues(alpha: 0.45),
                blurRadius: 28,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(22, 26, 22, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🧠', style: TextStyle(fontSize: 56)),
              const SizedBox(height: 8),
              AnimatedBuilder(
                animation: bounce,
                builder: (context, child) {
                  final y = -6 * (1 - (bounce.value * 2 - 1).abs());
                  return Transform.translate(offset: Offset(0, y), child: child);
                },
                child: const Text('🪙', style: TextStyle(fontSize: 46)),
              ),
              const SizedBox(height: 14),
              Text(
                loc.get('brain_daily_bonus_main'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  height: 1.25,
                  shadows: [
                    Shadow(color: Colors.black38, blurRadius: 6, offset: Offset(0, 2)),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onOk,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF1565C0),
                    elevation: 4,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: Text(
                    loc.get('ok'),
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
