/// Konu bazlı performans istatistikleri
class TopicPerformanceStats {
  final String topicId;
  final String topicName;
  final String emoji;
  final int correctCount;
  final int wrongCount;
  final double avgTimeSeconds;
  final int totalQuestions;
  final int successPercent;

  const TopicPerformanceStats({
    required this.topicId,
    required this.topicName,
    required this.emoji,
    required this.correctCount,
    required this.wrongCount,
    required this.avgTimeSeconds,
    required this.totalQuestions,
    required this.successPercent,
  });

  bool get isWeak => successPercent < 60;
  bool get needsAttention => successPercent >= 60 && successPercent < 80;
  bool get isStrong => successPercent >= 80;
}

/// Zaman filtresi
enum TopicTimeFilter {
  last7Days,
  last30Days,
  allTime,
}

/// Konu tanımları - ileride genişletilebilir
class TopicDefinitions {
  static const List<Map<String, String>> all = [
    {'id': 'addition', 'name': 'Toplama', 'emoji': '➕'},
    {'id': 'subtraction', 'name': 'Çıkarma', 'emoji': '➖'},
    {'id': 'multiplication', 'name': 'Çarpma', 'emoji': '✖️'},
    {'id': 'division', 'name': 'Bölme', 'emoji': '➗'},
  ];

  static Map<String, String>? getById(String id) {
    try {
      return all.firstWhere((t) => t['id'] == id);
    } catch (_) {
      return null;
    }
  }
}
