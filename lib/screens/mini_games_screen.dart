import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/mini_game_service.dart';
import '../services/ad_service.dart';
import '../models/mini_game.dart';
import '../localization/app_localizations.dart';
import 'games/balloon_pop_game.dart';
import 'games/fruit_collect_game.dart';
import 'games/puzzle_piece_game.dart';
import 'games/magic_clock_game.dart';
import 'games/magic_machine_game.dart';
import 'games/train_journey_game.dart';

class MiniGamesScreen extends StatefulWidget {
  final VoidCallback onBack;

  const MiniGamesScreen({super.key, required this.onBack});

  @override
  State<MiniGamesScreen> createState() => _MiniGamesScreenState();
}

class _MiniGamesScreenState extends State<MiniGamesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  GameCategory _selectedCategory = GameCategory.counting;

  static const Set<String> _playableGameIds = {'balloon_pop', 'fruit_collect', 'puzzle_piece'};
  bool _isComingSoon(MiniGame game) => !_playableGameIds.contains(game.id);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          _selectedCategory = GameCategory.values[_tabController.index];
        });
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initMiniGames();
    });
  }

  Future<void> _initMiniGames() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final miniGameService = Provider.of<MiniGameService>(context, listen: false);

    if (authService.currentUser != null) {
      await miniGameService.loadProgress(authService.currentUser!.uid);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final currentLocale = authService.currentUser?.selectedLanguage ?? 'tr';
    final localizations = AppLocalizations(Locale(currentLocale));
    final miniGameService = Provider.of<MiniGameService>(context);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF667eea), Color(0xFF764ba2)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              _buildHeader(localizations, miniGameService),

              // Category tabs
              _buildCategoryTabs(localizations, miniGameService),

              // Games grid
              Expanded(
                child: _buildGamesGrid(localizations, miniGameService),
              ),

              // Banner reklam (Premium olmayan kullanıcılar için)
              const BannerAdWidget(
                padding: EdgeInsets.symmetric(vertical: 8),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(AppLocalizations localizations, MiniGameService service) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Row(
        children: [
          IconButton(
            onPressed: widget.onBack,
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 16),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  localizations.get('mini_games'),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  '${service.allGames.length} ${localizations.get('games_available')}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          // Stars counter
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Text('⭐', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 4),
                Text(
                  '${service.progress?.totalStars ?? 0}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTabs(AppLocalizations localizations, MiniGameService service) {
    return Container(
      height: 36,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        labelPadding: const EdgeInsets.symmetric(horizontal: 6),
        indicatorColor: Colors.white,
        indicatorWeight: 2,
        indicatorSize: TabBarIndicatorSize.label,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white60,
        tabs: GameCategory.values.map((category) {
          final info = service.getCategoryInfo(category);
          return Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  info['emoji'] as String,
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(width: 2),
                Text(
                  localizations.get(info['nameKey'] as String),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildGamesGrid(AppLocalizations localizations, MiniGameService service) {
    final games = service.getGamesByCategory(_selectedCategory);
    final progress = service.progress;

    if (games.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🎮', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text(
              localizations.get('no_games_in_category'),
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
        childAspectRatio: 1.12,
      ),
      itemCount: games.length,
      itemBuilder: (context, index) {
        return _buildGameCard(games[index], localizations, service, progress);
      },
    );
  }

  Widget _buildGameCard(
      MiniGame game,
      AppLocalizations localizations,
      MiniGameService service,
      MiniGameProgress? progress,
      ) {
    final isComingSoon = _isComingSoon(game);
    final isUnlocked = progress?.unlockedGames.contains(game.id) ?? game.requiredStars == 0;
    final stats = progress?.gameStats[game.id];

    return GestureDetector(
      onTap: isComingSoon
          ? () => _showComingSoonDialog(localizations)
          : (isUnlocked ? () => _openGame(game, localizations) : () => _showLockedDialog(game, localizations)),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: !isUnlocked && !isComingSoon
                ? [Colors.grey.shade600, Colors.grey.shade700]
                : [
              Color(int.parse(game.colors[0].replaceFirst('#', '0xFF'))),
              Color(int.parse(game.colors[1].replaceFirst('#', '0xFF'))),
            ],
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            if (isUnlocked)
              BoxShadow(
                color: Color(int.parse(game.colors[0].replaceFirst('#', '0xFF')))
                    .withOpacity(0.3),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
          ],
        ),
        child: Stack(
          children: [
            // Yakında eklenecek overlay
            if (isComingSoon)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Text(
                        localizations.get('coming_soon_short'),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: [Shadow(color: Colors.black54, blurRadius: 2)],
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                      ),
                    ),
                  ),
                ),
              ),
            // Background pattern - daha küçük
            Positioned(
              right: -10,
              bottom: -10,
              child: Opacity(
                opacity: 0.1,
                child: Text(
                  game.iconEmoji,
                  style: const TextStyle(fontSize: 50),
                ),
              ),
            ),

            // Content (kilitli/gelecek oyunlarda underlying metinleri göstermeyelim)
            if (!isComingSoon)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Icon - biraz küçült
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          isUnlocked ? game.iconEmoji : '🔒',
                          style: const TextStyle(fontSize: 18),
                        ),
                      ),
                    ),

                    const SizedBox(height: 4),

                    // Title - normal boyut
                    Text(
                      localizations.get(game.nameKey),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isUnlocked ? Colors.white : Colors.white70,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 1),

                    // Age range - normal boyut
                    Text(
                      '${game.minAge}-${game.maxAge}',
                      style: TextStyle(
                        fontSize: 10,
                        color: isUnlocked ? Colors.white70 : Colors.white54,
                      ),
                    ),

                    const SizedBox(height: 2),

                    // Stats or unlock requirement - normal boyut
                    if (isUnlocked && stats != null)
                      Row(
                        children: [
                          const Text('⭐', style: TextStyle(fontSize: 10)),
                          const SizedBox(width: 2),
                          Text(
                            '${stats.totalStars}',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Text('🎮', style: TextStyle(fontSize: 10)),
                          const SizedBox(width: 2),
                          Text(
                            '${stats.timesPlayed}',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      )
                    else if (!isUnlocked)
                      Row(
                        children: [
                          const Icon(Icons.lock, size: 10, color: Colors.white54),
                          const SizedBox(width: 2),
                          Text(
                            '${game.requiredStars}',
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.white54,
                            ),
                          ),
                          const Text('⭐', style: TextStyle(fontSize: 10, color: Colors.white54)),
                        ],
                      )
                    else
                      Text(
                        localizations.get('tap_to_play'),
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.white70,
                        ),
                      ),
                  ],
                ),
              ),

            // Best score badge - küçük rozet (sadece aktif oyunlarda göster)
            if (!isComingSoon && isUnlocked && stats != null && stats.bestScore > 0)
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.amber,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${stats.bestScore}',
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _openGame(MiniGame game, AppLocalizations localizations) {
    Widget? gameScreen;

    switch (game.id) {
      case 'balloon_pop':
        gameScreen = BalloonPopGame(game: game, onBack: () => Navigator.pop(context));
        break;
      case 'fruit_collect':
        gameScreen = FruitCollectGame(game: game, onBack: () => Navigator.pop(context));
        break;
      case 'puzzle_piece':
        gameScreen = PuzzlePieceGame(game: game, onBack: () => Navigator.pop(context));
        break;
      case 'magic_clock':
        gameScreen = MagicClockGame(game: game, onBack: () => Navigator.pop(context));
        break;
      case 'magic_machine':
        gameScreen = MagicMachineGame(game: game, onBack: () => Navigator.pop(context));
        break;
      case 'train_journey':
        gameScreen = TrainJourneyGame(game: game, onBack: () => Navigator.pop(context));
        break;
      default:
        _showComingSoonDialog(localizations);
        return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => gameScreen!),
    );
  }

  void _showLockedDialog(MiniGame game, AppLocalizations localizations) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1a1a2e),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titlePadding: const EdgeInsets.all(16),
        contentPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        title: Row(
          children: [
            const Text('🔒', style: TextStyle(fontSize: 22)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                localizations.get('game_locked'),
                style: const TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
          ],
        ),
        content: Text(
          '${localizations.get('collect_stars_to_unlock')} ${game.requiredStars} ⭐',
          style: const TextStyle(fontSize: 14, color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              localizations.get('ok'),
              style: const TextStyle(fontSize: 14, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showComingSoonDialog(AppLocalizations localizations) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1a1a2e),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titlePadding: const EdgeInsets.all(16),
        contentPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        title: Row(
          children: [
            const Text('🏗️', style: TextStyle(fontSize: 22)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                localizations.get('coming_soon'),
                style: const TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
          ],
        ),
        content: Text(
          localizations.get('game_coming_soon'),
          style: const TextStyle(fontSize: 14, color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              localizations.get('ok'),
              style: const TextStyle(fontSize: 14, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}