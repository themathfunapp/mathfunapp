import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../models/badge.dart';
import '../models/daily_reward.dart';
import '../widgets/badge_unlock_dialog.dart';
import 'badge_service.dart';
import 'daily_reward_service.dart';

/// Konu oyunları ve hızlı matematik gibi oturumlar bittiğinde rozet + günlük görev güncellemesi.
class GameSessionReport {
  GameSessionReport._();

  static Future<List<BadgeDefinition>> submit(
    BuildContext context, {
    required int questionsAnswered,
    required int correctAnswers,
    required int wrongAnswers,
    required int score,
    required double averageAnswerTimeSeconds,
    required int fastAnswersCount,
    required int superFastAnswersCount,
    required int bestCorrectStreakInSession,
    bool showUnlockDialog = true,
  }) async {
    final badgeService = Provider.of<BadgeService>(context, listen: false);
    final rewardService = Provider.of<DailyRewardService>(context, listen: false);

    final newBadges = await badgeService.onGameCompleted(
      questionsAnswered: questionsAnswered,
      correctAnswers: correctAnswers,
      wrongAnswers: wrongAnswers,
      score: score,
      averageTime: averageAnswerTimeSeconds,
      fastAnswersCount: fastAnswersCount,
      superFastAnswersCount: superFastAnswersCount,
      streak: bestCorrectStreakInSession,
    );

    await rewardService.updateTaskProgress(TaskType.playGames, 1);
    await rewardService.updateTaskProgress(TaskType.solveQuestions, correctAnswers);
    await rewardService.updateTaskProgress(TaskType.correctStreak, bestCorrectStreakInSession);
    if (wrongAnswers == 0 && correctAnswers > 0 && questionsAnswered > 0) {
      await rewardService.updateTaskProgress(TaskType.perfectGame, 1);
    }
    await rewardService.updateTaskProgress(
      TaskType.fastAnswers,
      fastAnswersCount + superFastAnswersCount,
    );

    if (showUnlockDialog && newBadges.isNotEmpty && context.mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          BadgeUnlockDialog.show(context, newBadges);
        }
      });
    }

    return newBadges;
  }
}
