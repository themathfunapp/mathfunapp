import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'game_session_report.dart';

/// Mini oyunlar bittiğinde rozet + günlük görev (`GameSessionReport`) ile ana oyunu hizalar.
class MiniGameSessionReport {
  MiniGameSessionReport._();

  static Future<void> submit(
    BuildContext context, {
    required int correctAnswers,
    required int wrongAnswers,
    required int score,
    int bestCorrectStreakInSession = 0,
  }) async {
    if (!context.mounted) return;
    final total = correctAnswers + wrongAnswers;
    final q = total < 1 ? 1 : total;
    try {
      await GameSessionReport.submit(
        context,
        questionsAnswered: q,
        correctAnswers: correctAnswers,
        wrongAnswers: wrongAnswers,
        score: score,
        averageAnswerTimeSeconds: 5.0,
        fastAnswersCount: 0,
        superFastAnswersCount: 0,
        bestCorrectStreakInSession: bestCorrectStreakInSession,
      );
    } catch (e) {
      debugPrint('MiniGameSessionReport: $e');
    }
  }
}
