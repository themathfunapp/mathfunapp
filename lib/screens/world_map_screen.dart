import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/story_mode.dart';
import '../models/story_invite_payload.dart';
import '../models/game_mechanics.dart' show TopicType;
import '../models/daily_reward.dart' show TaskType;
import '../localization/app_localizations.dart';
import '../providers/locale_provider.dart';
import '../services/daily_reward_service.dart';
import '../services/game_mechanics_service.dart';
import 'chapter_screen.dart';
import 'counting_forest_screen.dart';
import 'cyber_workshop_screen.dart';
import 'fraction_bakery_screen.dart';
import 'fairy_land_screen.dart';
import 'geometry_castle_screen.dart';
import 'measurement_land_screen.dart';
import 'time_adventure_screen.dart';
import 'money_market_screen.dart';
import 'multipliers_tower_screen.dart';
import 'algebra_realm_screen.dart';
import 'family_remote_duel_setup_screen.dart';

class WorldMapScreen extends StatefulWidget {
  final List<StoryWorld> worlds;
  final StoryProgress? progress;
  /// Ebeveyn paneli hikâye önizlemesinden açıldıysa bölüm ekranında aile daveti gösterilir.
  final bool openedFromParentPanel;
  final String? initialWorldId;
  final String? initialChapterId;

  const WorldMapScreen({
    super.key,
    required this.worlds,
    this.progress,
    this.openedFromParentPanel = false,
    this.initialWorldId,
    this.initialChapterId,
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
  bool _handledInitialDeepLink = false;

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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleInitialDeepLink();
      _maybeGrantWorldMapDailyBonus();
    });
  }

  @override
  void didUpdateWidget(covariant WorldMapScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_handledInitialDeepLink &&
        widget.worlds.isNotEmpty &&
        oldWidget.worlds.length != widget.worlds.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleInitialDeepLink();
      });
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  void _handleInitialDeepLink() {
    if (!mounted || _handledInitialDeepLink) return;
    final worldId = widget.initialWorldId;
    if (worldId == null || worldId.isEmpty || widget.worlds.isEmpty) return;
    StoryWorld? world;
    for (final w in widget.worlds) {
      if (w.id == worldId) {
        world = w;
        break;
      }
    }
    if (world == null) return;
    _handledInitialDeepLink = true;
    _openWorld(world, forcedChapterId: widget.initialChapterId);
  }

  Future<void> _maybeGrantWorldMapDailyBonus() async {
    if (!mounted) return;
    final mechanics = Provider.of<GameMechanicsService>(context, listen: false);
    final storyStars = widget.progress?.totalStars ?? 0;
    final granted = await mechanics.tryGrantDailyWorldMapBonus(currentStoryStars: storyStars);
    if (!mounted || !granted) return;

    // Daily task progress
    try {
      final daily = Provider.of<DailyRewardService>(context, listen: false);
      // ignore: discarded_futures
      daily.updateTaskProgress(TaskType.visitWorldMap, 1);
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
          child: _KidWorldMapDailyRewardDialog(
            loc: loc,
            tickets: mechanics.worldMapTickets,
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
    final localeProvider = Provider.of<LocaleProvider>(context, listen: true);
    final localizations = AppLocalizations(localeProvider.locale);

    // İç Scaffold kullanma: StoryModeScreen zaten Scaffold; iç içe Scaffold bazı cihazlarda ikinci geri / yanlış pop davranışına yol açabiliyor.
    return Container(
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
        top: false,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                    ..._buildWorldCards(localizations),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Kesir Pastanesi tasarım paleti
  static const Color _pastelPink = Color(0xFFFAD0C4);
  static const Color _lightTurquoise = Color(0xFFB2FEFA);
  static const Color _blueberryPurple = Color(0xFF8E44AD);

  List<Widget> _buildWorldCards(AppLocalizations localizations) {
    return widget.worlds.map((world) {
      final worldProgress = widget.progress?.worldProgress[world.id];
      final isLocked = world.requiredStars > (widget.progress?.totalStars ?? 0);
      final isFractionBakery = world.theme == WorldTheme.fractionBakery;

      // Kesir Pastanesi: Kilitliyken pastel tema (koyu gri yerine)
      final List<Color> cardColors = isFractionBakery && isLocked
          ? [_pastelPink.withOpacity(0.85), _blueberryPurple.withOpacity(0.6)]
          : isLocked
              ? [Colors.grey.shade700, Colors.grey.shade800]
              : [
                  Color(int.parse(world.colors[0].replaceFirst('#', '0xFF'))),
                  Color(int.parse(world.colors[1].replaceFirst('#', '0xFF'))),
                ];

      return AnimatedBuilder(
        animation: Listenable.merge([_floatAnimation, _pulseAnimation]),
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, _floatAnimation.value * 0.5),
            child: Transform.scale(
              scale: !isLocked ? (1.0 + (_pulseAnimation.value - 1) * 0.2) : 1.0,
              child: child,
            ),
          );
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: cardColors,
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
                          color: isFractionBakery && isLocked
                              ? _lightTurquoise.withOpacity(0.4)
                              : Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isFractionBakery && isLocked
                                ? _blueberryPurple.withOpacity(0.4)
                                : Colors.white.withOpacity(0.3),
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
                                  style: (isFractionBakery
                                          ? GoogleFonts.quicksand(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                              color: isLocked
                                                  ? _blueberryPurple
                                                  : Colors.white,
                                            )
                                          : TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                              color: isLocked
                                                  ? Colors.grey
                                                  : Colors.white,
                                            )),
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
                            style: (isFractionBakery
                                    ? GoogleFonts.quicksand(
                                        fontSize: 14,
                                        color: isLocked
                                            ? _blueberryPurple.withOpacity(0.9)
                                            : Colors.white.withOpacity(0.9),
                                        height: 1.3,
                                      )
                                    : TextStyle(
                                        fontSize: 14,
                                        color: isLocked
                                            ? Colors.grey
                                            : Colors.white.withOpacity(0.9),
                                        height: 1.3,
                                      )),
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
                                Icon(
                                  Icons.lock,
                                  color: isFractionBakery
                                      ? _blueberryPurple
                                      : Colors.grey,
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${world.requiredStars} ⭐ ${localizations.get('stars_required')}',
                                  style: isFractionBakery
                                      ? GoogleFonts.quicksand(
                                          fontSize: 14,
                                          color: _blueberryPurple,
                                          fontWeight: FontWeight.w600,
                                        )
                                      : const TextStyle(
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

  void _showLockedDialog(AppLocalizations localizations, StoryWorld world) {
    final mechanics = Provider.of<GameMechanicsService>(context, listen: false);
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
          if (mechanics.worldMapTickets > 0)
            TextButton(
              onPressed: () async {
                final ok = await mechanics.spendWorldMapTicket();
                if (!mounted) return;
                Navigator.pop(context);
                if (ok) {
                  _openWorld(world);
                }
              },
              child: Text(
                '${localizations.get('use_ticket')} (${mechanics.worldMapTickets})',
                style: const TextStyle(color: Colors.amber),
              ),
            ),
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

  TopicType? _topicForWorld(StoryWorld world) {
    if (world.theme == WorldTheme.numberForest ||
        world.nameKey == 'world_number_forest' ||
        world.nameKey == 'world_fairy_land' ||
        world.id == 'periler_diyari') {
      return TopicType.counting;
    }
    if (world.theme == WorldTheme.geometryCastle) return TopicType.geometry;
    if (world.theme == WorldTheme.measurementLand) return TopicType.measurements;
    if (world.theme == WorldTheme.timeAdventure ||
        world.nameKey == 'world_time_adventure') {
      return TopicType.time;
    }
    if (world.theme == WorldTheme.moneyMarket ||
        world.nameKey == 'world_money_market') {
      return TopicType.addition;
    }
    if (world.theme == WorldTheme.multipliersTower ||
        world.nameKey == 'world_multipliers_tower') {
      return TopicType.multiplication;
    }
    if (world.nameKey == 'world_fraction_bakery' ||
        world.theme == WorldTheme.fractionBakery) {
      return TopicType.fractions;
    }
    if (world.id == 'algebra_realm' || world.nameKey == 'world_algebra_realm') {
      return TopicType.algebra;
    }
    return null;
  }

  Future<void> _openWorld(StoryWorld world, {String? forcedChapterId}) async {
    if (widget.openedFromParentPanel) {
      final localeProvider = Provider.of<LocaleProvider>(context, listen: false);
      final localizations = AppLocalizations(localeProvider.locale);
      final worldTitle = localizations.get(world.nameKey);
      final choice = await showModalBottomSheet<String>(
        context: context,
        backgroundColor: const Color(0xFF1F2A5A),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (sheetContext) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${world.iconEmoji} $worldTitle',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    localizations.get('parent_world_how_start'),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 14),
                  FilledButton.icon(
                    onPressed: () => Navigator.of(sheetContext).pop('local'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(44),
                      backgroundColor: const Color(0xFF34A853),
                    ),
                    icon: const Icon(Icons.play_arrow),
                    label: Text(localizations.get('parent_world_start_on_device')),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: () => Navigator.of(sheetContext).pop('remote'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(44),
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Color(0xFF7AA7FF)),
                    ),
                    icon: const Icon(Icons.group_add),
                    label: Text(localizations.get('parent_world_send_family_remote')),
                  ),
                ],
              ),
            ),
          );
        },
      );

      if (!mounted || choice == null) return;
      if (choice == 'remote') {
        final topic = _topicForWorld(world) ?? TopicType.counting;
        await Navigator.of(context).push<void>(
          MaterialPageRoute<void>(
            builder: (ctx) => FamilyRemoteDuelSetupScreen(
              onBack: () => Navigator.of(ctx).pop(),
              initialTopic: topic,
            ),
          ),
        );
        return;
      }
    }

    final StoryInvitePayload? parentInvite =
        widget.openedFromParentPanel ? StoryInvitePayload.fromWorld(world) : null;

    // Siber Atölye / Sayı Ormanı teması - özel ekrana yönlendir
    // NOT: Sadece Matematik Gezginleri (6-8 yaş) için Siber Atölye
    if ((world.nameKey == 'world_siber_atolye' ||
         world.nameKey == 'world_number_forest' ||
         world.theme == WorldTheme.numberForest) &&
        world.targetAge == AgeGroup.earlyElementary) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CyberWorkshopScreen(
            onBack: () => Navigator.pop(context),
            parentPanelStoryInvite: parentInvite,
          ),
        ),
      );
      return;
    }

    // Periler Diyarı - özel ekrana yönlendir (Sayı Maceraları / 3-5 yaş)
    if (world.id == 'periler_diyari' ||
        world.nameKey == 'world_fairy_land') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FairyLandScreen(
            onBack: () => Navigator.pop(context),
            parentPanelStoryInvite: parentInvite,
          ),
        ),
      );
      return;
    }

    // Kesir Pastanesi - özel ekrana yönlendir
    if (world.nameKey == 'world_fraction_bakery' ||
        world.theme == WorldTheme.fractionBakery) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FractionBakeryScreen(
            onBack: () => Navigator.pop(context),
            parentPanelStoryInvite: parentInvite,
          ),
        ),
      );
      return;
    }

    // Geometri Şatosu - özel ekrana yönlendir
    if (world.theme == WorldTheme.geometryCastle) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => GeometryCastleScreen(
            onBack: () => Navigator.pop(context),
            parentPanelStoryInvite: parentInvite,
          ),
        ),
      );
      return;
    }

    // Ölçüm Diyarı - özel ekrana yönlendir
    if (world.theme == WorldTheme.measurementLand) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MeasurementLandScreen(
            onBack: () => Navigator.pop(context),
            parentPanelStoryInvite: parentInvite,
          ),
        ),
      );
      return;
    }

    // Zaman Macerası - özel ekrana yönlendir
    if (world.theme == WorldTheme.timeAdventure ||
        world.nameKey == 'world_time_adventure') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TimeAdventureScreen(
            onBack: () => Navigator.pop(context),
            parentPanelStoryInvite: parentInvite,
          ),
        ),
      );
      return;
    }

    // Para Pazarı - özel ekrana yönlendir
    if (world.theme == WorldTheme.moneyMarket ||
        world.nameKey == 'world_money_market') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MoneyMarketScreen(
            onBack: () => Navigator.pop(context),
            parentPanelStoryInvite: parentInvite,
          ),
        ),
      );
      return;
    }

    // Çarpanlar Kulesi - özel ekrana yönlendir
    if (world.theme == WorldTheme.multipliersTower ||
        world.nameKey == 'world_multipliers_tower') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MultipliersTowerScreen(
            onBack: () => Navigator.pop(context),
            parentPanelStoryInvite: parentInvite,
          ),
        ),
      );
      return;
    }

    // Cebir Diyarı - özel ekrana yönlendir
    if (world.id == 'algebra_realm' || world.nameKey == 'world_algebra_realm') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AlgebraRealmScreen(
            onBack: () => Navigator.pop(context),
            parentPanelStoryInvite: parentInvite,
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
          openedFromParentPanel: widget.openedFromParentPanel,
          initialChapterId: forcedChapterId,
        ),
      ),
    );
  }
}

class _KidWorldMapDailyRewardDialog extends StatelessWidget {
  final AppLocalizations loc;
  final int tickets;
  final VoidCallback onOk;

  const _KidWorldMapDailyRewardDialog({
    required this.loc,
    required this.tickets,
    required this.onOk,
  });

  /// RTL yerellerde Latin/عدد karışımında ünlem ve rakamların yanlış sıralanmasını azaltır.
  static String _embedLtrForDigits(String s) {
    return s.replaceAllMapped(RegExp(r'[0-9]+'), (m) => '\u200E${m[0]}\u200E');
  }

  static bool _useLtrDigitIsolation(String languageCode) {
    const rtlish = {'ar', 'fa', 'ur', 'ku', 'hi'};
    return rtlish.contains(languageCode);
  }

  @override
  Widget build(BuildContext context) {
    final lang = loc.locale.languageCode;
    final isolate = _useLtrDigitIsolation(lang);
    final mainMsg = isolate
        ? _embedLtrForDigits(loc.get('world_daily_bonus_main'))
        : loc.get('world_daily_bonus_main');
    final ticketsRaw =
        loc.get('world_map_bonus_tickets_row').replaceAll('{count}', '$tickets');
    final ticketsText = isolate ? _embedLtrForDigits(ticketsRaw) : ticketsRaw;

    return Material(
      color: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
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
          padding: const EdgeInsets.fromLTRB(22, 26, 22, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🗺️', style: TextStyle(fontSize: 56)),
              const SizedBox(height: 10),
              const Text('🪙', style: TextStyle(fontSize: 44)),
              const SizedBox(height: 10),
              Text(
                mainMsg,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  height: 1.25,
                  shadows: [
                    Shadow(color: Colors.black38, blurRadius: 6, offset: Offset(0, 2)),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🎟️', style: TextStyle(fontSize: 20)),
                    const SizedBox(width: 8),
                    Text(
                      ticketsText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
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