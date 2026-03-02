import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/story_mode.dart';
import '../localization/app_localizations.dart';
import '../providers/locale_provider.dart';
import 'chapter_screen.dart';
import 'counting_forest_screen.dart'; // Sayı Ormanı için

class WorldMapScreen extends StatefulWidget {
  final List<StoryWorld> worlds;
  final StoryProgress? progress;

  const WorldMapScreen({
    super.key,
    required this.worlds,
    this.progress,
  });

  @override
  State<WorldMapScreen> createState() => _WorldMapScreenState();
}

class _WorldMapScreenState extends State<WorldMapScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _floatController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _floatAnimation;

  @override
  void initState() {
    super.initState();

    // Nabız animasyonu
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Yüzdürme animasyonu
    _floatController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _floatAnimation = Tween<double>(begin: -5, end: 5).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localeProvider = Provider.of<LocaleProvider>(context, listen: true);
    final localizations = AppLocalizations(localeProvider.locale);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1a237e),
              Color(0xFF4a148c),
              Color(0xFF880e4f),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Üst navigasyon barı
              _buildTopBar(localizations),

              // Ana içerik
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Başlık
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              localizations.get('world_map'),
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                shadows: [
                                  Shadow(
                                    color: Colors.black26,
                                    blurRadius: 10,
                                    offset: Offset(0, 3),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              localizations.get('every_world_adventure'),
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.8),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Dünya kartları
                      ..._buildWorldCards(localizations),

                      const SizedBox(height: 24),

                      // Alt navigasyon
                      _buildBottomNavigation(localizations),
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

  Widget _buildTopBar(AppLocalizations localizations) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Geri butonu
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_back_ios_new,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),

          const Spacer(),

          // Yıldız sayısı
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.3),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.amber.withOpacity(0.5),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 20),
                const SizedBox(width: 4),
                Text(
                  '${widget.progress?.totalStars ?? 0}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildWorldCards(AppLocalizations localizations) {
    return widget.worlds.map((world) {
      final worldProgress = widget.progress?.worldProgress[world.id];
      final isLocked = world.requiredStars > (widget.progress?.totalStars ?? 0);

      return AnimatedBuilder(
        animation: _floatAnimation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, _floatAnimation.value * 0.5),
            child: child,
          );
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isLocked
                  ? [Colors.grey.shade700, Colors.grey.shade800]
                  : [
                Color(int.parse(world.colors[0].replaceFirst('#', '0xFF'))),
                Color(int.parse(world.colors[1].replaceFirst('#', '0xFF'))),
              ],
            ),
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: isLocked
                  ? () => _showLockedDialog(localizations, world)
                  : () => _openWorld(world),
              borderRadius: BorderRadius.circular(25),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    // Dünya ikonu
                    AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: !isLocked ? _pulseAnimation.value : 1.0,
                          child: child,
                        );
                      },
                      child: Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            isLocked ? '🔒' : world.iconEmoji,
                            style: const TextStyle(fontSize: 36),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 16),

                    // Dünya bilgileri
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  localizations.get(world.nameKey),
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: isLocked ? Colors.grey : Colors.white,
                                  ),
                                ),
                              ),
                              if (!isLocked)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    localizations.get('start'),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isLocked ? Colors.grey : Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),

                          const SizedBox(height: 4),

                          Text(
                            localizations.get(world.descriptionKey),
                            style: TextStyle(
                              fontSize: 14,
                              color: isLocked
                                  ? Colors.grey
                                  : Colors.white.withOpacity(0.9),
                              height: 1.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),

                          const SizedBox(height: 8),

                          // İlerleme barı
                          if (!isLocked)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        const Text('⭐',
                                            style: TextStyle(fontSize: 14)),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${worldProgress?.totalStars ?? 0}',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      isLocked
                                          ? localizations.get('world_locked')
                                          : '${((worldProgress?.totalStars ?? 0) / 100 * 100).toInt()}%',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.white.withOpacity(0.8),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: LinearProgressIndicator(
                                    value: isLocked
                                        ? 0
                                        : (worldProgress?.totalStars ?? 0) / 100,
                                    backgroundColor: Colors.white.withOpacity(0.2),
                                    valueColor: AlwaysStoppedAnimation(
                                      Color(int.parse(world.colors[0].replaceFirst('#', '0xFF'))),
                                    ),
                                    minHeight: 6,
                                  ),
                                ),
                              ],
                            )
                          else
                            Row(
                              children: [
                                const Icon(
                                  Icons.lock,
                                  color: Colors.grey,
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${world.requiredStars} ⭐ ${localizations.get('stars_required')}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }).toList();
  }

  Widget _buildBottomNavigation(AppLocalizations localizations) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem('🏆', localizations.get('achievements'), true),
          _buildNavItem('🎯', localizations.get('quests')),
          _buildNavItem('⚡', localizations.get('energy')),
          _buildNavItem('📊', localizations.get('statistics')),
        ],
      ),
    );
  }

  Widget _buildNavItem(String icon, String label, [bool isActive = false]) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: isActive ? Colors.blue.withOpacity(0.3) : Colors.transparent,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isActive ? Colors.white : Colors.white.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  void _showLockedDialog(AppLocalizations localizations, StoryWorld world) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1a1a2e),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Text('🔒', style: TextStyle(fontSize: 28)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                localizations.get('world_locked'),
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              localizations.get('unlock_world_stars').replaceAll('{0}', '${world.requiredStars}'),
              style: const TextStyle(color: Colors.white70, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${widget.progress?.totalStars ?? 0}',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber,
                  ),
                ),
                const Text(
                  ' / ',
                  style: TextStyle(fontSize: 24, color: Colors.white54),
                ),
                Text(
                  '${world.requiredStars}',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                const Text('⭐', style: TextStyle(fontSize: 28)),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              localizations.get('ok'),
              style: const TextStyle(color: Colors.blue),
            ),
          ),
        ],
      ),
    );
  }

  void _openWorld(StoryWorld world) {
    // Eğer Sayı Ormanı ise özel ekrana yönlendir
    if (world.nameKey == 'number_forest') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CountingForestScreen(
            onBack: () => Navigator.pop(context),
          ),
        ),
      );
      return;
    }

    // Diğer dünyalar için bölüm ekranına git
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChapterScreen(
          world: world,
          progress: widget.progress,
        ),
      ),
    );
  }
}