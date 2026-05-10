import 'dart:math';

import 'pdf_weekly_report_tips_data.dart';

/// Haftalık PDF raporu için 50 farklı öneri × 18 dil (25 güçlü / 25 gelişim).
/// Metinler PDF’te Roboto ile güvenli; emoji yok.
class PdfWeeklyReportTips {
  PdfWeeklyReportTips._();

  /// Rapor ve haftalık çubuk verisine göre 4 öneri seçer (haftalık seed ile çeşitlenir).
  static List<String> pickTips({
    required String languageCode,
    required String childName,
    required int accuracy,
    required int totalQuestions,
    required List<int> weeklyValues,
    int count = 4,
  }) {
    final strong = _isStrongWeek(accuracy, totalQuestions, weeklyValues);
    final pool = strong
        ? pdfWeeklyTipsStrong(languageCode)
        : pdfWeeklyTipsWeak(languageCode);
    final weekBucket = DateTime.now().millisecondsSinceEpoch ~/ (86400000 * 7);
    final seed = Object.hash(childName.hashCode, weekBucket, strong);
    final rnd = Random(seed);
    final copy = List<String>.from(pool)..shuffle(rnd);
    return copy.take(count.clamp(1, pool.length)).toList();
  }

  static bool _isStrongWeek(int accuracy, int totalQ, List<int> weekly) {
    final daysActive = weekly.where((v) => v > 0).length;
    if (accuracy >= 72 && totalQ >= 28) return true;
    if (accuracy >= 65 && daysActive >= 4 && totalQ >= 22) return true;
    if (accuracy < 48) return false;
    if (daysActive <= 1 && totalQ < 30) return false;
    if (accuracy >= 60 && totalQ >= 35) return true;
    return accuracy >= 58;
  }
}
