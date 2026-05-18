/// Konu seçim diyaloğundan oyuna aktarılan seviye tanımı.
class TopicPlayLevel {
  final int levelNumber;
  final String difficultyId;
  final String nameKey;
  final int questionCount;
  final int timeLimitSeconds;
  final double rewardMultiplier;

  const TopicPlayLevel({
    required this.levelNumber,
    required this.difficultyId,
    required this.nameKey,
    required this.questionCount,
    required this.timeLimitSeconds,
    required this.rewardMultiplier,
  });

  Map<String, dynamic> toJson() => {
        'level': levelNumber,
        'difficultyId': difficultyId,
        'nameKey': nameKey,
        'questionCount': questionCount,
        'timeLimit': timeLimitSeconds,
        'rewardMultiplier': rewardMultiplier,
      };

  factory TopicPlayLevel.fromLevelMap(Map<String, dynamic> level) {
    return TopicPlayLevel(
      levelNumber: level['level'] as int,
      difficultyId: level['difficultyId'] as String,
      nameKey: level['nameKey'] as String,
      questionCount: level['questionCount'] as int,
      timeLimitSeconds: level['timeLimit'] as int,
      rewardMultiplier: (level['rewardMultiplier'] as num).toDouble(),
    );
  }
}
