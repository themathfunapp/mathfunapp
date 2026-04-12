import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/game_mechanics_service.dart';
import '../services/story_service.dart';
import '../models/story_mode.dart';
import '../localization/app_localizations.dart';
import 'level_play_screen.dart';

class ChapterScreen extends StatefulWidget {
  final StoryWorld world;
  final StoryProgress? progress;

  const ChapterScreen({
    super.key,
    required this.world,
    this.progress,
  });

  @override
  State<ChapterScreen> createState() => _ChapterScreenState();
}

class _ChapterScreenState extends State<ChapterScreen> {
  int _selectedChapterIndex = 0;

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final currentLocale = authService.currentUser?.selectedLanguage ?? 'tr';
    final localizations = AppLocalizations(Locale(currentLocale));
    // StoryService'ten güncel progress'i al (listen: true)
    final storyService = Provider.of<StoryService>(context);
    final currentProgress = storyService.progress;

    final gradientColors = [
      Color(int.parse(widget.world.colors[0].replaceFirst('#', '0xFF'))),
      Color(int.parse(widget.world.colors[1].replaceFirst('#', '0xFF'))),
    ];

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              gradientColors[0].withOpacity(0.8),
              const Color(0xFF1a1a2e),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              _buildHeader(localizations, gradientColors, currentProgress),

              // Chapters tabs
              if (widget.world.chapters.length > 1)
                _buildChapterTabs(localizations, currentProgress),

              // Levels
              Expanded(
                child: widget.world.chapters.isEmpty
                    ? _buildComingSoon(localizations)
                    : _buildLevelsList(
                        widget.world.chapters[_selectedChapterIndex],
                        localizations,
                        storyService,
                        currentProgress,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(AppLocalizations localizations, List<Color> colors, StoryProgress? progress) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Center(
                  child: Text(
                    widget.world.iconEmoji,
                    style: const TextStyle(fontSize: 35),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      localizations.get(widget.world.nameKey),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Row(
                      children: [
                        const Text('⭐', style: TextStyle(fontSize: 14)),
                        const SizedBox(width: 4),
                        Text(
                          '${progress?.worldProgress[widget.world.id]?.totalStars ?? 0} ${localizations.get('stars_collected')}',
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
        ],
      ),
    );
  }

  Widget _buildChapterTabs(AppLocalizations localizations, StoryProgress? progress) {
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: widget.world.chapters.length,
        itemBuilder: (context, index) {
          final chapter = widget.world.chapters[index];
          final isSelected = index == _selectedChapterIndex;
          final _ = progress
              ?.worldProgress[widget.world.id]
              ?.chapterProgress[chapter.id];
          final isLocked = chapter.requiredStars >
              (progress?.worldProgress[widget.world.id]?.totalStars ?? 0);

          return GestureDetector(
            onTap: isLocked
                ? null
                : () => setState(() => _selectedChapterIndex = index),
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white
                    : Colors.white.withOpacity(isLocked ? 0.1 : 0.2),
                borderRadius: BorderRadius.circular(25),
              ),
              child: Row(
                children: [
                  if (isLocked) const Text('🔒', style: TextStyle(fontSize: 16)),
                  if (!isLocked)
                    Text(
                      '${index + 1}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.black87 : Colors.white,
                      ),
                    ),
                  const SizedBox(width: 8),
                  Text(
                    localizations.get(chapter.nameKey),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? Colors.black87
                          : (isLocked ? Colors.white38 : Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildComingSoon(AppLocalizations localizations) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🏗️', style: TextStyle(fontSize: 80)),
          const SizedBox(height: 20),
          Text(
            localizations.get('chapters_coming_soon'),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            localizations.get('stay_tuned'),
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelsList(
    StoryChapter chapter,
    AppLocalizations localizations,
    StoryService storyService,
    StoryProgress? progress,
  ) {
    final helperInfo = storyService.getHelperInfo(chapter.helper);

    return Column(
      children: [
        // Helper character intro
        Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: (helperInfo['color'] as Color).withOpacity(0.3),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Center(
                  child: Text(
                    helperInfo['emoji'] as String,
                    style: const TextStyle(fontSize: 35),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      localizations.get(helperInfo['nameKey'] as String),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '"${localizations.get(chapter.storyIntroKey)}"',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.8),
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Levels grid
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 0.85,
            ),
            itemCount: chapter.levels.length,
            itemBuilder: (context, index) {
              return _buildLevelItem(
                chapter.levels[index],
                index,
                localizations,
                chapter,
                progress,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLevelItem(
    StoryLevel level,
    int index,
    AppLocalizations localizations,
    StoryChapter chapter,
    StoryProgress? progress,
  ) {
    final chapterProgress = progress
        ?.worldProgress[widget.world.id]
        ?.chapterProgress[chapter.id];
    final levelProgress = chapterProgress?.levelProgress[level.id];
    final isCompleted = levelProgress?.isCompleted ?? false;
    final stars = levelProgress?.stars ?? 0;

    // Level is locked if previous level is not completed (except first level)
    bool isLocked = false;
    if (index > 0) {
      final prevLevel = chapter.levels[index - 1];
      final prevProgress = chapterProgress?.levelProgress[prevLevel.id];
      isLocked = !(prevProgress?.isCompleted ?? false);
    }

    return GestureDetector(
      onTap: isLocked
          ? null
          : () async {
              final mechanics =
                  Provider.of<GameMechanicsService>(context, listen: false);
              if (!mechanics.hasLives) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(localizations.get('no_lives_play')),
                    backgroundColor: Colors.orange,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                return;
              }
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => LevelPlayScreen(
                    level: level,
                    chapter: chapter,
                    world: widget.world,
                  ),
                ),
              );
              // Level tamamlandıktan sonra ekranı yenile
              if (mounted) setState(() {});
            },
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isLocked
                ? [Colors.grey.shade700, Colors.grey.shade800]
                : isCompleted
                    ? [const Color(0xFF4CAF50), const Color(0xFF8BC34A)]
                    : [
                        Color(int.parse(
                            widget.world.colors[0].replaceFirst('#', '0xFF'))),
                        Color(int.parse(
                            widget.world.colors[1].replaceFirst('#', '0xFF'))),
                      ],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            if (!isLocked)
              BoxShadow(
                color: isCompleted
                    ? Colors.green.withOpacity(0.3)
                    : Color(int.parse(
                            widget.world.colors[0].replaceFirst('#', '0xFF')))
                        .withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Level number or lock
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: isLocked
                    ? const Icon(Icons.lock, color: Colors.white54, size: 20)
                    : Text(
                        '${index + 1}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 8),

            // Stars
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (starIndex) {
                return Icon(
                  starIndex < stars ? Icons.star : Icons.star_border,
                  color: starIndex < stars ? Colors.amber : Colors.white38,
                  size: 16,
                );
              }),
            ),

            // Boss indicator
            if (level.isBossLevel)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    '👑',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

