import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../localization/app_localizations.dart';
import '../models/age_group_selection.dart';
import '../models/game_mechanics.dart' as GameMechanics;
import '../models/topic_play_level.dart';
import '../providers/locale_provider.dart';
import '../screens/specialized_game_screen.dart';
import '../services/auth_service.dart';
import '../services/game_mechanics_service.dart';
import '../services/topic_level_progress_service.dart';
import '../widgets/no_lives_gate_dialog.dart';

/// Konu oyunları (Sayma, Toplama, …) için seviye seçimi, kayıt ve oyuna geçiş.
class TopicLevelFlow {
  TopicLevelFlow._();

  /// Konu seçim ekranındaki standart konu meta verisi.
  static Map<String, dynamic> topicMetaFor(
    String topicId,
    AppLocalizations loc, {
    Color? colorOverride,
    String? emojiOverride,
    String? titleOverride,
  }) {
    switch (topicId) {
      case 'counting':
        return {
          'id': 'counting',
          'emoji': emojiOverride ?? '🔢',
          'title': titleOverride ?? loc.get('counting'),
          'color': colorOverride ?? const Color(0xFF2ECC71),
        };
      case 'addition':
        return {
          'id': 'addition',
          'emoji': emojiOverride ?? '➕',
          'title': titleOverride ?? loc.get('addition'),
          'color': colorOverride ?? const Color(0xFF3498DB),
        };
      case 'subtraction':
        return {
          'id': 'subtraction',
          'emoji': emojiOverride ?? '➖',
          'title': titleOverride ?? loc.get('subtraction'),
          'color': colorOverride ?? const Color(0xFFE74C3C),
        };
      case 'multiplication':
        return {
          'id': 'multiplication',
          'emoji': emojiOverride ?? '✖️',
          'title': titleOverride ?? loc.get('multiplication'),
          'color': colorOverride ?? const Color(0xFF9B59B6),
        };
      case 'division':
        return {
          'id': 'division',
          'emoji': emojiOverride ?? '➗',
          'title': titleOverride ?? loc.get('division'),
          'color': colorOverride ?? const Color(0xFF34495E),
        };
      case 'geometry':
      case 'shapes':
        return {
          'id': 'geometry',
          'emoji': emojiOverride ?? '🔺',
          'title': titleOverride ?? loc.get('geometry'),
          'color': colorOverride ?? const Color(0xFFE67E22),
        };
      default:
        return {
          'id': topicId,
          'emoji': emojiOverride ?? '📘',
          'title': titleOverride ?? topicId,
          'color': colorOverride ?? const Color(0xFF3498DB),
        };
    }
  }

  /// Sayma / Toplama / Çıkarma vb. standart seviyeli konuları açar.
  static Future<void> openStandardMathTopic(
    BuildContext context, {
    required String topicId,
    required AgeGroupSelection ageGroup,
    Color? color,
    String? emoji,
    String? title,
  }) async {
    final loc = AppLocalizations(Provider.of<LocaleProvider>(context, listen: false).locale);
    await openTopicWithLevelDialog(
      context,
      ageGroup: ageGroup,
      topic: topicMetaFor(topicId, loc, colorOverride: color, emojiOverride: emoji, titleOverride: title),
    );
  }

  static GameMechanics.TopicType topicTypeFromId(String topicId) {
    switch (topicId) {
      case 'geometry':
        return GameMechanics.TopicType.geometry;
      case 'fractions':
        return GameMechanics.TopicType.fractions;
      case 'decimals':
        return GameMechanics.TopicType.decimals;
      case 'time':
        return GameMechanics.TopicType.time;
      case 'shapes':
        return GameMechanics.TopicType.geometry;
      case 'counting':
        return GameMechanics.TopicType.counting;
      case 'addition':
        return GameMechanics.TopicType.addition;
      case 'subtraction':
        return GameMechanics.TopicType.subtraction;
      case 'multiplication':
        return GameMechanics.TopicType.multiplication;
      case 'division':
        return GameMechanics.TopicType.division;
      case 'algebra':
        return GameMechanics.TopicType.algebra;
      default:
        return GameMechanics.TopicType.addition;
    }
  }

  static Map<String, dynamic> createGameSettings(
    AgeGroupSelection ageGroup,
    Map<String, dynamic> topic,
  ) {
    int questionCount;
    int timeLimit;
    String difficulty;

    switch (ageGroup) {
      case AgeGroupSelection.preschool:
        questionCount = 5;
        timeLimit = 30;
        difficulty = 'Kolay';
        break;
      case AgeGroupSelection.elementary:
        questionCount = 10;
        timeLimit = 45;
        difficulty = 'Orta';
        break;
      case AgeGroupSelection.advanced:
        questionCount = 15;
        timeLimit = 60;
        difficulty = 'Zor';
        break;
      default:
        questionCount = 10;
        timeLimit = 45;
        difficulty = 'Orta';
    }

    return {
      'topicId': topic['id'],
      'topicName': topic['title'],
      'topicEmoji': topic['emoji'],
      'topicColor': topic['color'],
      'questionCount': questionCount,
      'timeLimit': timeLimit,
      'difficulty': difficulty,
      'baseScorePerQuestion': 100,
      'coinReward': questionCount * 10,
      'xpReward': questionCount * 5,
    };
  }

  static List<Map<String, dynamic>> buildPlayLevelMaps(Map<String, dynamic> settings) {
    final baseQ = settings['questionCount'] as int;
    final baseT = settings['timeLimit'] as int;
    return [
      {
        'level': 1,
        'nameKey': 'level_easy',
        'difficultyId': 'easy',
        'emoji': '🌟',
        'questionCount': baseQ,
        'timeLimit': baseT,
        'rewardMultiplier': 1.0,
      },
      {
        'level': 2,
        'nameKey': 'level_medium',
        'difficultyId': 'medium',
        'emoji': '🚀',
        'questionCount': baseQ + 5,
        'timeLimit': baseT - 10,
        'rewardMultiplier': 1.5,
      },
      {
        'level': 3,
        'nameKey': 'level_hard',
        'difficultyId': 'hard',
        'emoji': '🦁',
        'questionCount': baseQ + 10,
        'timeLimit': baseT - 20,
        'rewardMultiplier': 2.0,
      },
    ];
  }

  /// Diyalog arka planı — konuya göre sıcak tonlar.
  static List<Color> _dialogBackgroundGradient(String topicId, Color topicColor) {
    switch (topicId) {
      case 'subtraction':
        return [const Color(0xFFFFF5F5), const Color(0xFFFFE8E8)];
      case 'multiplication':
        return [const Color(0xFFF8F0FF), const Color(0xFFEDE0FF)];
      case 'geometry':
        return [const Color(0xFFFFF8F0), const Color(0xFFFFECD2)];
      case 'counting':
        return [const Color(0xFFF0FFF4), const Color(0xFFD4F5E0)];
      case 'addition':
        return [const Color(0xFFF0F8FF), const Color(0xFFD6EBFF)];
      case 'division':
        return [const Color(0xFFF4F6F7), const Color(0xFFE5E8E8)];
      default:
        return [
          Color.lerp(topicColor, Colors.white, 0.92)!,
          Color.lerp(topicColor, Colors.white, 0.82)!,
        ];
    }
  }

  /// Seviye kartı gradyanı — çıkarma / çarpma / geometri için konu renkleri.
  static List<Color> _levelCardGradient(
    int levelNum,
    Color topicColor,
    String topicId, {
    required bool locked,
  }) {
    if (locked) {
      switch (topicId) {
        case 'subtraction':
          return [const Color(0xFFFADBD8), const Color(0xFFF5B7B1)];
        case 'multiplication':
          return [const Color(0xFFE8DAEF), const Color(0xFFD2B4DE)];
        case 'geometry':
          return [const Color(0xFFFFE0B2), const Color(0xFFFFCC80)];
        default:
          return [const Color(0xFFE8D5F2), const Color(0xFFD4B8E8)];
      }
    }

    switch (topicId) {
      case 'subtraction':
        switch (levelNum) {
          case 1:
            return [const Color(0xFFFFB8B8), const Color(0xFFFF6B6B)];
          case 2:
            return [const Color(0xFFFF8E8E), const Color(0xFFE74C3C)];
          case 3:
            return [const Color(0xFFE74C3C), const Color(0xFFC0392B)];
          default:
            return [const Color(0xFFFF6B6B), topicColor];
        }
      case 'multiplication':
        switch (levelNum) {
          case 1:
            return [const Color(0xFFE1BEE7), const Color(0xFFCE93D8)];
          case 2:
            return [const Color(0xFFCE93D8), const Color(0xFF9B59B6)];
          case 3:
            return [const Color(0xFF9B59B6), const Color(0xFF6C3483)];
          default:
            return [const Color(0xFFBB86FC), topicColor];
        }
      case 'geometry':
        switch (levelNum) {
          case 1:
            return [const Color(0xFFFFE0B2), const Color(0xFFFFB74D)];
          case 2:
            return [const Color(0xFFFFCC80), const Color(0xFFE67E22)];
          case 3:
            return [const Color(0xFFE67E22), const Color(0xFFD35400)];
          default:
            return [const Color(0xFFFFB74D), topicColor];
        }
      default:
        final accent = Color.lerp(topicColor, Colors.white, 0.25)!;
        switch (levelNum) {
          case 1:
            return [
              Color.lerp(const Color(0xFF7BED9F), accent, 0.35)!,
              Color.lerp(const Color(0xFF2ED573), topicColor, 0.45)!,
            ];
          case 2:
            return [
              Color.lerp(const Color(0xFFFFE66D), accent, 0.3)!,
              Color.lerp(const Color(0xFFFF9F43), topicColor, 0.4)!,
            ];
          case 3:
            return [
              Color.lerp(const Color(0xFFFF8A9B), accent, 0.25)!,
              Color.lerp(const Color(0xFFE056FD), topicColor, 0.35)!,
            ];
          default:
            return [accent, topicColor];
        }
    }
  }

  static List<Color> _headerGradient(String topicId, Color topicColor) {
    switch (topicId) {
      case 'subtraction':
        return [const Color(0xFFFF7675), const Color(0xFFE74C3C)];
      case 'multiplication':
        return [const Color(0xFFBB86FC), const Color(0xFF9B59B6)];
      case 'geometry':
        return [const Color(0xFFFFB74D), const Color(0xFFE67E22)];
      default:
        return [
          Color.lerp(topicColor, Colors.white, 0.15)!,
          topicColor,
        ];
    }
  }

  static Widget _buildPlayfulLevelCard({
    required BuildContext context,
    required AppLocalizations loc,
    required Map<String, dynamic> topic,
    required Map<String, dynamic> level,
    required bool isLocked,
    required bool isContinue,
    required VoidCallback? onTap,
  }) {
    final topicColor = topic['color'] as Color;
    final topicId = topic['id'] as String? ?? '';
    final levelNum = level['level'] as int;
    final gradient = _levelCardGradient(levelNum, topicColor, topicId, locked: isLocked);
    final emoji = isLocked ? '🔒' : level['emoji'] as String;
    final title =
        '${loc.get(level['nameKey'] as String)} - ${loc.get('level_label')} ${level['level']}';
    final subtitle = isLocked
        ? loc.get('topic_level_locked_hint')
        : '${level['questionCount']} ${loc.get('questions_unit')} • ${level['timeLimit']} ${loc.get('seconds_unit')}';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: gradient.last.withValues(alpha: isLocked ? 0.15 : 0.4),
            blurRadius: isLocked ? 4 : 10,
            offset: const Offset(0, 5),
          ),
        ],
        border: isContinue
            ? Border.all(color: Colors.white, width: 3)
            : Border.all(color: Colors.white.withValues(alpha: 0.35), width: 1.5),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text(emoji, style: const TextStyle(fontSize: 28)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: isLocked ? const Color(0xFF6B4E8A) : Colors.white,
                          shadows: isLocked
                              ? null
                              : [
                                  Shadow(
                                    color: Colors.black.withValues(alpha: 0.12),
                                    blurRadius: 2,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isLocked
                              ? const Color(0xFF8B6BA8)
                              : Colors.white.withValues(alpha: 0.95),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    isLocked ? Icons.lock_rounded : Icons.play_arrow_rounded,
                    color: isLocked ? const Color(0xFFB39DDB) : topicColor,
                    size: 26,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Future<({int unlocked, int continueLevel})> loadProgress(
    BuildContext context, {
    required String topicId,
    required AgeGroupSelection ageGroup,
  }) async {
    final progress = TopicLevelProgressService();
    final user = context.read<AuthService>().currentUser;
    if (user == null) return (unlocked: 1, continueLevel: 1);
    final userId = user.isGuest ? 'guest_${user.uid}' : user.uid;
    final ageKey = ageGroup.name;
    final unlocked = await progress.getUnlockedLevel(
      userId: userId,
      ageGroupKey: ageKey,
      topicId: topicId,
    );
    final continueLevel = await progress.getContinueLevel(
      userId: userId,
      ageGroupKey: ageKey,
      topicId: topicId,
    );
    return (unlocked: unlocked, continueLevel: continueLevel);
  }

  /// Can kontrolü + seviye seçim diyaloğu.
  static Future<void> openTopicWithLevelDialog(
    BuildContext context, {
    required Map<String, dynamic> topic,
    required AgeGroupSelection ageGroup,
  }) async {
    final mechanics = context.read<GameMechanicsService>();
    if (!mechanics.hasLives) {
      await showNoLivesGateDialog(context);
      return;
    }

    final settings = createGameSettings(ageGroup, topic);
    final topicId = topic['id'] as String;

    if (topicId == 'time') {
      final q = settings['questionCount'] as int;
      final t = settings['timeLimit'] as int;
      await _startGame(
        context,
        topic: topic,
        settings: settings,
        ageGroup: ageGroup,
        level: {
          'level': 1,
          'nameKey': 'topic_time',
          'difficultyId': 'medium',
          'questionCount': q,
          'timeLimit': t,
        },
        playLevels: null,
        initialLevel: 1,
      );
      return;
    }

    final loc = AppLocalizations(Provider.of<LocaleProvider>(context, listen: false).locale);
    final levels = buildPlayLevelMaps(settings);
    var progress = await loadProgress(context, topicId: topicId, ageGroup: ageGroup);
    if (!context.mounted) return;

    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          backgroundColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: _dialogBackgroundGradient(topicId, topic['color'] as Color),
              ),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: _headerGradient(topicId, topic['color'] as Color),
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: (topic['color'] as Color).withValues(alpha: 0.35),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(topic['emoji'] as String, style: const TextStyle(fontSize: 32)),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Text(
                            topic['title'] as String,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (progress.continueLevel > 1 || progress.unlocked > 1) ...[
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          final level = levels.firstWhere((l) => l['level'] == progress.continueLevel);
                          Navigator.pop(context);
                          _startGame(
                            context,
                            topic: topic,
                            settings: settings,
                            ageGroup: ageGroup,
                            level: level,
                            playLevels: levels,
                            initialLevel: progress.continueLevel,
                          );
                        },
                        icon: const Icon(Icons.play_arrow_rounded),
                        label: Text(loc.get('topic_continue_play'),
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: topic['color'] as Color,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      loc
                          .get('topic_continue_level_hint')
                          .replaceAll('{level}', '${progress.continueLevel}')
                          .replaceAll(
                            '{name}',
                            loc.get(levels
                                .firstWhere((l) => l['level'] == progress.continueLevel)['nameKey'] as String),
                          ),
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                    ),
                    const SizedBox(height: 14),
                  ],
                  ...levels.map((level) {
                    final levelNum = level['level'] as int;
                    final isLocked = levelNum > progress.unlocked;
                    final isContinue = levelNum == progress.continueLevel;
                    return _buildPlayfulLevelCard(
                      context: context,
                      loc: loc,
                      topic: topic,
                      level: level,
                      isLocked: isLocked,
                      isContinue: isContinue,
                      onTap: isLocked
                          ? () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(loc.get('topic_level_locked_hint')),
                                  behavior: SnackBarBehavior.floating,
                                  backgroundColor: topic['color'] as Color,
                                ),
                              );
                            }
                          : () {
                              Navigator.pop(context);
                              _startGame(
                                context,
                                topic: topic,
                                settings: settings,
                                ageGroup: ageGroup,
                                level: level,
                                playLevels: levels,
                                initialLevel: levelNum,
                              );
                            },
                    );
                  }),
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF8E6BA8),
                    ),
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: Text(loc.get('topic_reset_levels')),
                          content: Text(loc.get('topic_reset_levels_confirm')),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(loc.get('cancel'))),
                            TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(loc.get('reset'))),
                          ],
                        ),
                      );
                      if (confirm != true) return;
                      final user = context.read<AuthService>().currentUser;
                      if (user != null) {
                        final userId = user.isGuest ? 'guest_${user.uid}' : user.uid;
                        await TopicLevelProgressService().resetProgress(
                          userId: userId,
                          ageGroupKey: ageGroup.name,
                          topicId: topicId,
                        );
                      }
                      setDialogState(() => progress = (unlocked: 1, continueLevel: 1));
                    },
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: Text(loc.get('topic_reset_levels')),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(loc.get('cancel')),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static Future<void> _startGame(
    BuildContext context, {
    required Map<String, dynamic> topic,
    required Map<String, dynamic> settings,
    required AgeGroupSelection ageGroup,
    required Map<String, dynamic> level,
    required List<Map<String, dynamic>>? playLevels,
    required int initialLevel,
  }) async {
    final topicId = topic['id'] as String;
    final topicType = topicTypeFromId(topicId);
    final topicSettings = GameMechanics.TopicGameManager.getTopicSettings()[topicType]!;
    final levelNum = initialLevel;

    final user = context.read<AuthService>().currentUser;
    if (user != null) {
      final userId = user.isGuest ? 'guest_${user.uid}' : user.uid;
      await TopicLevelProgressService().setContinueLevel(
        userId: userId,
        ageGroupKey: ageGroup.name,
        topicId: topicId,
        level: levelNum,
      );
    }

    final ladder = (playLevels ?? buildPlayLevelMaps(settings)).map(TopicPlayLevel.fromLevelMap).toList();
    if (!context.mounted) return;

    final loc = AppLocalizations(Provider.of<LocaleProvider>(context, listen: false).locale);
    final nameKey = level['nameKey'] as String?;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SpecializedGameScreen(
          topicSettings: topicSettings,
          ageGroup: ageGroup,
          difficulty: level['difficultyId'] as String,
          difficultyDisplay: nameKey != null ? loc.get(nameKey) : null,
          topicId: topicId,
          playLevels: ladder.isEmpty ? null : ladder,
          initialLevelNumber: levelNum,
          onBack: () => Navigator.pop(context),
        ),
      ),
    );
  }
}
