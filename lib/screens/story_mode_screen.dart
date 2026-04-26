import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/story_service.dart';
import '../services/ad_service.dart';
import '../models/story_mode.dart';
import '../localization/app_localizations.dart';
import '../providers/locale_provider.dart';
import 'world_map_screen.dart';

class StoryModeScreen extends StatefulWidget {
  /// true: Ebeveyn paneli → Oyun Oyna sekmesinden açılan tam ekran önizleme (çocuk hikâye akışı).
  /// false: Ana sayfadaki normal Hikaye Modu girişi — davranış aynı kalır.
  final bool openedFromParentPanel;
  final String? initialWorldId;
  final String? initialChapterId;

  const StoryModeScreen({
    super.key,
    this.openedFromParentPanel = false,
    this.initialWorldId,
    this.initialChapterId,
  });

  @override
  State<StoryModeScreen> createState() => _StoryModeScreenState();
}

class _StoryModeScreenState extends State<StoryModeScreen>
    with TickerProviderStateMixin {
  late AnimationController _floatController;
  late Animation<double> _floatAnimation;
  bool _showAgeSelection = true;
  bool get _openedFromStoryInvite =>
      (widget.initialWorldId?.isNotEmpty ?? false) ||
      (widget.initialChapterId?.isNotEmpty ?? false);

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _floatAnimation = Tween<double>(begin: 0, end: 10).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    // Post-frame callback ile Provider'a erişim
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initStoryMode();
    });
  }

  Future<void> _initStoryMode() async {
    if (!mounted) return;

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final storyService = Provider.of<StoryService>(context, listen: false);

      if (authService.currentUser != null) {
        await storyService.loadProgress(authService.currentUser!.uid);

        if (mounted && storyService.progress != null &&
            storyService.progress!.avatar.odername != 'Kahraman') {
          setState(() {
            _showAgeSelection = false;
          });
          await storyService.loadWorlds(storyService.progress!.selectedAgeGroup);
        }
      }
    } catch (e) {
      debugPrint('Story mode init error: $e');
    }
  }

  @override
  void dispose() {
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
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1a1a2e),
              Color(0xFF16213e),
              Color(0xFF0f3460),
            ],
          ),
        ),
        child: SafeArea(
          child: Consumer<StoryService>(
            builder: (context, storyService, child) {
              if (storyService.isLoading) {
                return const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                );
              }

              if (_showAgeSelection) {
                return _buildAgeSelection(localizations, storyService);
              }

              return _buildMainContent(localizations, storyService);
            },
          ),
        ),
      ),
    );
  }

  /// ~390dp referans genişliğine göre kart/padding oranını sabitler; farklı telefonlarda benzer "ince" görünüm.
  double _ageSelectionLayoutScale(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return (w / 390.0).clamp(0.86, 1.0);
  }

  Widget _buildAgeSelection(AppLocalizations localizations, StoryService storyService) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (didPop) return;
        Navigator.pop(context);
      },
      child: MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: MediaQuery.textScalerOf(context).clamp(
            minScaleFactor: 0.92,
            maxScaleFactor: 1.12,
          ),
        ),
        child: Builder(
          builder: (context) {
            final scale = _ageSelectionLayoutScale(context);
            final hPad = 18.0 * scale;
            final heroH = (88 * scale).clamp(72.0, 96.0);
            final heroEmoji = (62 * scale).clamp(52.0, 72.0);
            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(12 * scale, 12 * scale, 12 * scale, 8 * scale),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                          constraints: BoxConstraints(minWidth: 40 * scale, minHeight: 40 * scale),
                          padding: EdgeInsets.all(8 * scale),
                        ),
                        Expanded(
                          child: Text(
                            localizations.storyMode,
                            style: TextStyle(
                              fontSize: (22 * scale).clamp(18.0, 24.0),
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        SizedBox(width: 40 * scale),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: heroH,
                    child: ClipRect(
                      child: AnimatedBuilder(
                        animation: _floatAnimation,
                        builder: (context, child) {
                          return Transform.translate(
                            offset: Offset(0, _floatAnimation.value),
                            child: Center(
                              child: Text(
                                '🦸',
                                style: TextStyle(fontSize: heroEmoji),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(child: SizedBox(height: 8 * scale)),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: hPad),
                    child: Text(
                      localizations.get('choose_adventure'),
                      style: TextStyle(
                        fontSize: (24 * scale).clamp(20.0, 28.0),
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                SliverToBoxAdapter(child: SizedBox(height: 6 * scale)),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: hPad + 4),
                    child: Text(
                      localizations.get('age_appropriate_adventure'),
                      style: TextStyle(
                        fontSize: (14 * scale).clamp(12.0, 16.0),
                        color: Colors.white.withOpacity(0.8),
                        height: 1.25,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                SliverToBoxAdapter(child: SizedBox(height: 16 * scale)),
                SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: 16 * scale),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _buildAgeCard(
                        context: context,
                        scale: scale,
                        title: localizations.get('number_adventures'),
                        subtitle: localizations.get('colorful_animals_discovery'),
                        ageRange: '3-5',
                        yearsOld: localizations.get('years_old'),
                        emoji: '🧒',
                        colors: [const Color(0xFF4CAF50), const Color(0xFF8BC34A)],
                        storyService: storyService,
                        ageGroup: AgeGroup.preschool,
                      ),
                      SizedBox(height: 11 * scale),
                      _buildAgeCard(
                        context: context,
                        scale: scale,
                        title: localizations.get('math_explorers'),
                        subtitle: localizations.get('time_space_journey'),
                        ageRange: '6-8',
                        yearsOld: localizations.get('years_old'),
                        emoji: '🚀',
                        colors: [const Color(0xFF2196F3), const Color(0xFF03A9F4)],
                        storyService: storyService,
                        ageGroup: AgeGroup.earlyElementary,
                      ),
                      SizedBox(height: 11 * scale),
                      _buildAgeCard(
                        context: context,
                        scale: scale,
                        title: localizations.get('math_kingdom'),
                        subtitle: localizations.get('kingdom_rescue_mission'),
                        ageRange: '9-11',
                        yearsOld: localizations.get('years_old'),
                        emoji: '🏰',
                        colors: [const Color(0xFF9C27B0), const Color(0xFFE91E63)],
                        storyService: storyService,
                        ageGroup: AgeGroup.lateElementary,
                      ),
                      SizedBox(height: 24 * scale),
                    ]),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildAgeCard({
    required BuildContext context,
    required double scale,
    required String title,
    required String subtitle,
    required String ageRange,
    required String yearsOld,
    required String emoji,
    required List<Color> colors,
    required StoryService storyService,
    required AgeGroup ageGroup,
  }) {
    final iconBox = (52 * scale).clamp(46.0, 58.0);
    final emojiSize = (30 * scale).clamp(26.0, 36.0);
    final padH = (14 * scale).clamp(12.0, 16.0);
    final padV = (12 * scale).clamp(10.0, 14.0);

    return GestureDetector(
      onTap: () async {
        await storyService.selectAgeGroup(ageGroup);

        // TODO: Avatar özelliği yayın sonrası güncellemede aktif edilecek
        // Avatar oluşturma ekranını atlayıp direkt devam et
        // if (mounted) {
        //   final result = await Navigator.push<bool>(
        //     context,
        //     MaterialPageRoute(
        //       builder: (context) => AvatarCreatorScreen(ageGroup: ageGroup),
        //     ),
        //   );
        //
        //   if (result == true) {
        //     setState(() {
        //       _showAgeSelection = false;
        //     });
        //   }
        // }
        
        // Varsayılan avatar ile direkt devam et
        if (mounted) {
          setState(() {
            _showAgeSelection = false;
          });
        }
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: padH, vertical: padV),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: colors),
          borderRadius: BorderRadius.circular((18 * scale).clamp(16.0, 20.0)),
          boxShadow: [
            BoxShadow(
              color: colors[0].withOpacity(0.35),
              blurRadius: 12 * scale,
              offset: Offset(0, 5 * scale),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: iconBox,
              height: iconBox,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular((12 * scale).clamp(10.0, 14.0)),
              ),
              child: Center(
                child: Text(
                  emoji,
                  style: TextStyle(fontSize: emojiSize),
                ),
              ),
            ),
            SizedBox(width: 12 * scale),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: (16.5 * scale).clamp(15.0, 18.0),
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1.15,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4 * scale),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: (7 * scale).clamp(6.0, 9.0),
                      vertical: (3 * scale).clamp(2.0, 4.0),
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$ageRange $yearsOld',
                      style: TextStyle(
                        fontSize: (10.5 * scale).clamp(10.0, 12.0),
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  SizedBox(height: 4 * scale),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: (12.5 * scale).clamp(11.0, 14.0),
                      color: Colors.white.withOpacity(0.9),
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            SizedBox(width: 4 * scale),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.white,
              size: (17 * scale).clamp(15.0, 20.0),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent(
    AppLocalizations localizations,
    StoryService storyService,
  ) {
    final progress = storyService.progress;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (didPop) return;
        setState(() {
          _showAgeSelection = true;
        });
      },
      child: Column(
        children: [
          // Top Bar
          _buildTopBar(localizations),
          if (_openedFromStoryInvite)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.lightGreenAccent.withOpacity(0.16),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.lightGreenAccent.withOpacity(0.55)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.mark_chat_read_rounded, size: 16, color: Colors.lightGreenAccent),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Aile davetinden açıldı.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // World Map
          Expanded(
            child: WorldMapScreen(
              worlds: storyService.worlds,
              progress: progress,
              openedFromParentPanel: widget.openedFromParentPanel,
              initialWorldId: widget.initialWorldId,
              initialChapterId: widget.initialChapterId,
            ),
          ),

          // Banner reklam (Premium olmayan kullanıcılar için)
          const BannerAdWidget(
            padding: EdgeInsets.symmetric(vertical: 8),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(AppLocalizations localizations) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              setState(() {
                _showAgeSelection = true;
              });
            },
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
            ),
          ),
          Expanded(
            child: Center(
              child: GestureDetector(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${localizations.get('avatar_coming_soon')} 🎨'),
                      backgroundColor: Colors.purple,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                    ),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1a1a2e),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Text('🦸', style: TextStyle(fontSize: 28)),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}