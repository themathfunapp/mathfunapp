import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'number_coloring_screen.dart';
import 'shape_coloring_screen.dart';
import 'color_lab_screen.dart';
import '../services/game_mechanics_service.dart';
import '../services/daily_reward_service.dart';
import '../localization/app_localizations.dart';
import '../providers/locale_provider.dart';

class ColorfulMathScreen extends StatefulWidget {
  final String ageGroup;

  const ColorfulMathScreen({
    Key? key,
    required this.ageGroup,
  }) : super(key: key);

  @override
  State<ColorfulMathScreen> createState() => _ColorfulMathScreenState();
}

class _ColorfulMathScreenState extends State<ColorfulMathScreen>
    with TickerProviderStateMixin {
  late AnimationController _floatController;
  late AnimationController _bounce;
  
  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _bounce = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    )..repeat(reverse: true);
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeGrantColorMathDailyBonus());
  }

  @override
  void dispose() {
    _floatController.dispose();
    _bounce.dispose();
    super.dispose();
  }

  Future<void> _maybeGrantColorMathDailyBonus() async {
    if (!mounted) return;
    final mechanics = Provider.of<GameMechanicsService>(context, listen: false);
    final granted = await mechanics.tryGrantDailyColorMathEntryBonus();
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
          child: _KidColorMathDailyRewardDialog(
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
              Colors.purple.shade300,
              Colors.blue.shade300,
              Colors.pink.shade300,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildTopBar(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _buildTitle(loc),
                      const SizedBox(height: 30),
                      Consumer<GameMechanicsService>(
                        builder: (context, mechanicsService, _) {
                          return _buildModuleCard(
                            title: loc.get('number_coloring'),
                            subtitle: loc.get('number_coloring_subtitle'),
                            icon: '🔢',
                            color: Colors.orange,
                            progress: mechanicsService.colorMathNumberProgress,
                            totalLevels: 30,
                            onTap: () => _showNumberColoringModeDialog(),
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                      Consumer<GameMechanicsService>(
                        builder: (context, mechanicsService, _) {
                          return _buildModuleCard(
                            title: loc.get('shape_coloring'),
                            subtitle: loc.get('shape_coloring_subtitle'),
                            icon: '🔺',
                            color: Colors.green,
                            progress: mechanicsService.colorMathShapeProgress,
                            totalLevels: 20,
                            onTap: () => _showShapeColoringModeDialog(),
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                      Consumer<GameMechanicsService>(
                        builder: (context, mechanicsService, _) {
                          return _buildModuleCard(
                            title: loc.get('color_lab'),
                            subtitle: loc.get('color_lab_subtitle'),
                            icon: '🧪',
                            color: Colors.purple,
                            progress: mechanicsService.colorMathLabProgress,
                            totalLevels: 15,
                            onTap: () => _showColorLabModeDialog(),
                          );
                        },
                      ),
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
    final loc = AppLocalizations(Provider.of<LocaleProvider>(context, listen: false).locale);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.arrow_back, color: Colors.white),
            ),
            onPressed: () => Navigator.pop(context),
          ),
          const Spacer(),
          Consumer<GameMechanicsService>(
            builder: (context, mechanicsService, _) {
              final lives = mechanicsService.currentLives;
              final maxLives = mechanicsService.maxLives;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ...List.generate(
                      maxLives,
                      (i) => Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: Icon(
                          Icons.bolt,
                          color: i < lives ? Colors.amber : Colors.white.withOpacity(0.4),
                          size: 22,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTitle(AppLocalizations loc) {
    return Column(
      children: [
        Text(
          '🎨',
          style: TextStyle(fontSize: 80),
        ),
        const SizedBox(height: 16),
        Text(
          loc.get('colorful_math'),
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: [
              Shadow(
                color: Colors.black.withOpacity(0.3),
                offset: const Offset(2, 2),
                blurRadius: 4,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          loc.get('colorful_math_slogan'),
          style: TextStyle(
            fontSize: 18,
            color: Colors.white.withOpacity(0.9),
          ),
        ),
      ],
    );
  }

  void _showColorLabModeDialog() {
    final mechanicsService = Provider.of<GameMechanicsService>(context, listen: false);
    if (!mechanicsService.hasLives) {
      final loc = AppLocalizations(Provider.of<LocaleProvider>(context, listen: false).locale);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loc.get('no_lives_play')),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    final loc = AppLocalizations(Provider.of<LocaleProvider>(context, listen: false).locale);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20)],
        ),
        child: ListView(
          shrinkWrap: true,
          children: [
            Text(
              loc.get('select_level_mode'),
              style: GoogleFonts.quicksand(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.purple.shade800),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            _buildColorLabModeOption(loc, loc.get('color_lab_mode_easy'), loc.get('color_lab_mode_easy_desc'), 1, 5),
            const SizedBox(height: 8),
            _buildColorLabModeOption(loc, loc.get('color_lab_mode_medium'), loc.get('color_lab_mode_medium_desc'), 2, 5),
            const SizedBox(height: 8),
            _buildColorLabModeOption(loc, loc.get('color_lab_mode_hard'), loc.get('color_lab_mode_hard_desc'), 3, 5),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 12),
          ],
        ),
      ),
    );
  }

  Widget _buildColorLabModeOption(AppLocalizations loc, String title, String subtitle, int mode, int totalLevels) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ColorLabScreen(
                ageGroup: widget.ageGroup,
                levelMode: mode,
                totalLevels: totalLevels,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.purple.shade50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.purple.shade200),
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.purple.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    mode == 1 ? '🧪' : mode == 2 ? '🔬' : '⚗️',
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: GoogleFonts.quicksand(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.purple.shade800)),
                    Text(subtitle, style: GoogleFonts.quicksand(fontSize: 12, color: Colors.grey[600])),
                    const SizedBox(height: 4),
                    Text(loc.get('levels_count').replaceAll('%1', '$totalLevels'), style: GoogleFonts.quicksand(fontSize: 11, color: Colors.purple.shade700, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 18, color: Colors.purple.shade700),
            ],
          ),
        ),
      ),
    );
  }

  void _showShapeColoringModeDialog() {
    final mechanicsService = Provider.of<GameMechanicsService>(context, listen: false);
    if (!mechanicsService.hasLives) {
      final loc = AppLocalizations(Provider.of<LocaleProvider>(context, listen: false).locale);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loc.get('no_lives_play')),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    final loc = AppLocalizations(Provider.of<LocaleProvider>(context, listen: false).locale);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75,
        ),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20)],
        ),
        child: ListView(
          shrinkWrap: true,
          children: [
            Text(
              loc.get('select_level_mode'),
              style: GoogleFonts.quicksand(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green.shade800),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            _buildShapeModeOption(loc, loc.get('shape_mode_basic'), loc.get('shape_mode_basic_desc'), 1, 5),
            const SizedBox(height: 12),
            _buildShapeModeOption(loc, loc.get('shape_mode_mixed'), loc.get('shape_mode_mixed_desc'), 2, 5),
            const SizedBox(height: 12),
            _buildShapeModeOption(loc, loc.get('shape_mode_advanced'), loc.get('shape_mode_advanced_desc'), 3, 5),
            const SizedBox(height: 12),
            _buildShapeModeOption(loc, loc.get('shape_mode_complex'), loc.get('shape_mode_complex_desc'), 4, 5),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
          ],
        ),
      ),
    );
  }

  Widget _buildShapeModeOption(AppLocalizations loc, String title, String subtitle, int mode, int totalLevels) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ShapeColoringScreen(
                ageGroup: widget.ageGroup,
                levelMode: mode,
                totalLevels: totalLevels,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.green.shade200),
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    mode == 1 ? '🔵' : mode == 2 ? '🔺' : mode == 3 ? '⬡' : '◆',
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: GoogleFonts.quicksand(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green.shade800)),
                    Text(subtitle, style: GoogleFonts.quicksand(fontSize: 12, color: Colors.grey[600])),
                    const SizedBox(height: 4),
                    Text(loc.get('levels_count').replaceAll('%1', '$totalLevels'), style: GoogleFonts.quicksand(fontSize: 11, color: Colors.green.shade700, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 18, color: Colors.green.shade700),
            ],
          ),
        ),
      ),
    );
  }

  void _showNumberColoringModeDialog() {
    final mechanicsService = Provider.of<GameMechanicsService>(context, listen: false);
    if (!mechanicsService.hasLives) {
      final loc = AppLocalizations(Provider.of<LocaleProvider>(context, listen: false).locale);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loc.get('no_lives_play')),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    final loc = AppLocalizations(Provider.of<LocaleProvider>(context, listen: false).locale);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.65,
        ),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20)],
        ),
        child: ListView(
          shrinkWrap: true,
          children: [
            Text(
              loc.get('select_level_mode'),
              style: GoogleFonts.quicksand(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.orange.shade800),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            _buildModeOption(loc, loc.get('number_mode_single'), loc.get('number_mode_single_desc'), 1, 1),
            const SizedBox(height: 12),
            _buildModeOption(loc, loc.get('number_mode_double'), loc.get('number_mode_double_desc'), 9, 2),
            const SizedBox(height: 12),
            _buildModeOption(loc, loc.get('number_mode_triple'), loc.get('number_mode_triple_desc'), 20, 3),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
          ],
        ),
      ),
    );
  }

  Widget _buildModeOption(AppLocalizations loc, String title, String subtitle, int totalLevels, int mode) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => NumberColoringScreen(
                ageGroup: widget.ageGroup,
                levelMode: mode,
                totalLevels: totalLevels,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.orange.shade200),
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    mode == 1 ? '0-9' : mode == 2 ? '10-99' : '100+',
                    style: GoogleFonts.quicksand(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.orange.shade800),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: GoogleFonts.quicksand(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange.shade800)),
                    Text(subtitle, style: GoogleFonts.quicksand(fontSize: 12, color: Colors.grey[600])),
                    const SizedBox(height: 4),
                    Text(loc.get('levels_count').replaceAll('%1', '$totalLevels'), style: GoogleFonts.quicksand(fontSize: 11, color: Colors.orange.shade700, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 18, color: Colors.orange.shade700),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModuleCard({
    required String title,
    required String subtitle,
    required String icon,
    required Color color,
    required int progress,
    required int totalLevels,
    required VoidCallback onTap,
  }) {
    return AnimatedBuilder(
      animation: _floatController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _floatController.value * 10),
          child: child,
        );
      },
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Center(
                      child: Text(
                        icon,
                        style: const TextStyle(fontSize: 32),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: color,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: LinearProgressIndicator(
                      value: progress / totalLevels,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '$progress/$totalLevels',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600],
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
}

class _KidColorMathDailyRewardDialog extends StatelessWidget {
  final AppLocalizations loc;
  final Animation<double> bounce;
  final VoidCallback onOk;

  const _KidColorMathDailyRewardDialog({
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
                Color(0xFFFF4081),
                Color(0xFFFFC107),
              ],
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF4081).withValues(alpha: 0.45),
                blurRadius: 28,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(22, 26, 22, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🎨', style: TextStyle(fontSize: 56)),
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
                loc.get('color_math_daily_bonus_main'),
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
                    foregroundColor: const Color(0xFF6A1B9A),
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

