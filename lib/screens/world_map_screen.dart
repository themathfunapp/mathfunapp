import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../models/story_mode.dart';
import '../localization/app_localizations.dart';
import 'chapter_screen.dart';

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
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final currentLocale = authService.currentUser?.selectedLanguage ?? 'tr';
    final localizations = AppLocalizations(Locale(currentLocale));

    if (widget.worlds.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🏗️', style: TextStyle(fontSize: 60)),
            const SizedBox(height: 20),
            Text(
              localizations.get('worlds_coming_soon'),
              style: const TextStyle(
                fontSize: 20,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // World Title
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            children: [
              const Text('🗺️', style: TextStyle(fontSize: 28)),
              const SizedBox(width: 12),
              Text(
                localizations.get('world_map'),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),

        // World Cards
        Expanded(
          child: PageView.builder(
            controller: PageController(viewportFraction: 0.85),
            itemCount: widget.worlds.length,
            itemBuilder: (context, index) {
              return _buildWorldCard(
                widget.worlds[index],
                localizations,
                index,
              );
            },
          ),
        ),

        // Page indicator
        Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              widget.worlds.length,
              (index) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWorldCard(
    StoryWorld world,
    AppLocalizations localizations,
    int index,
  ) {
    final worldProgress = widget.progress?.worldProgress[world.id];
    final isLocked = world.requiredStars > (widget.progress?.totalStars ?? 0);
    final totalStars = worldProgress?.totalStars ?? 0;
    final maxStars = world.chapters.fold<int>(
      0,
      (sum, chapter) => sum + chapter.levels.length * 3,
    );

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: !isLocked && index == 0 ? _pulseAnimation.value : 1.0,
          child: child,
        );
      },
      child: GestureDetector(
        onTap: isLocked
            ? () => _showLockedDialog(localizations, world)
            : () => _openWorld(world, localizations),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 20),
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
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: isLocked
                    ? Colors.black26
                    : Color(int.parse(world.colors[0].replaceFirst('#', '0xFF')))
                        .withOpacity(0.4),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Background pattern
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: CustomPaint(
                    painter: _WorldPatternPainter(
                      color: Colors.white.withOpacity(0.05),
                    ),
                  ),
                ),
              ),

              // Content
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Center(
                            child: Text(
                              isLocked ? '🔒' : world.iconEmoji,
                              style: const TextStyle(fontSize: 40),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                localizations.get(world.nameKey),
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: isLocked ? Colors.grey : Colors.white,
                                ),
                              ),
                              if (!isLocked)
                                Row(
                                  children: [
                                    const Text('⭐', style: TextStyle(fontSize: 16)),
                                    const SizedBox(width: 4),
                                    Text(
                                      '$totalStars / $maxStars',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.white70,
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Description
                    Text(
                      localizations.get(world.descriptionKey),
                      style: TextStyle(
                        fontSize: 16,
                        color: isLocked ? Colors.grey : Colors.white.withOpacity(0.9),
                        height: 1.4,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const Spacer(),

                    // Topics
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: world.topics.take(3).map((topic) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Text(
                            _getTopicName(topic, localizations),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isLocked ? Colors.grey : Colors.white,
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 20),

                    // Action button
                    if (isLocked)
                      Row(
                        children: [
                          const Icon(Icons.lock, color: Colors.grey, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            '${localizations.get('requires')} ${world.requiredStars} ⭐',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      )
                    else
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              localizations.get('start_adventure'),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.arrow_forward,
                              color: Colors.white,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getTopicName(MathTopic topic, AppLocalizations localizations) {
    switch (topic) {
      case MathTopic.counting:
        return localizations.get('topic_counting');
      case MathTopic.addition:
        return localizations.get('topic_addition');
      case MathTopic.subtraction:
        return localizations.get('topic_subtraction');
      case MathTopic.multiplication:
        return localizations.get('topic_multiplication');
      case MathTopic.division:
        return localizations.get('topic_division');
      case MathTopic.fractions:
        return localizations.get('topic_fractions');
      case MathTopic.shapes:
        return localizations.get('topic_shapes');
      case MathTopic.time:
        return localizations.get('topic_time');
      case MathTopic.money:
        return localizations.get('topic_money');
      case MathTopic.measurement:
        return localizations.get('topic_measurement');
      case MathTopic.angles:
        return localizations.get('topic_angles');
      case MathTopic.decimals:
        return localizations.get('topic_decimals');
      case MathTopic.patterns:
        return localizations.get('topic_patterns');
      case MathTopic.algebra:
        return localizations.get('topic_algebra');
    }
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
              '${localizations.get('collect_stars_to_unlock')} ${world.requiredStars} ⭐',
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

  void _openWorld(StoryWorld world, AppLocalizations localizations) {
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

class _WorldPatternPainter extends CustomPainter {
  final Color color;

  _WorldPatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Draw decorative circles
    for (int i = 0; i < 5; i++) {
      canvas.drawCircle(
        Offset(
          size.width * (0.1 + i * 0.2),
          size.height * (0.2 + (i % 2) * 0.6),
        ),
        20 + i * 10,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

