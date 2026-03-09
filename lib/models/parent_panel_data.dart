// Matematik Dünyası: Ebeveyn Paneli - Veri Modeli
// ASCII tablolardaki değerlerle birebir örtüşen gerçekçi veriler

class ParentPanelChild {
  final String id;
  final String name;
  final int age;
  final int grade; // Sınıf
  final int totalScore;
  final int successPercent;
  final List<int> weeklyProgress; // 7 günlük ilerleme (0-100)
  final List<String> earnedBadges;
  final List<GamePerformance> gamePerformance;
  final List<TopicPerformance> topicPerformance;

  const ParentPanelChild({
    required this.id,
    required this.name,
    required this.age,
    required this.grade,
    required this.totalScore,
    required this.successPercent,
    required this.weeklyProgress,
    required this.earnedBadges,
    required this.gamePerformance,
    required this.topicPerformance,
  });
}

class GamePerformance {
  final String gameName;
  final int successPercent;

  const GamePerformance({
    required this.gameName,
    required this.successPercent,
  });
}

class TopicPerformance {
  final String topicName;
  final int successPercent;
  final bool needsAttention; // %45 gibi düşük değerlerde true

  const TopicPerformance({
    required this.topicName,
    required this.successPercent,
    this.needsAttention = false,
  });
}

/// Örnek veri - ASCII tablolardaki değerlerle birebir
class ParentPanelData {
  static List<ParentPanelChild> get children => [
        // Ayşe: 8 yaş, 3. sınıf, %85 başarı
        const ParentPanelChild(
          id: 'ayse',
          name: 'Ayşe',
          age: 8,
          grade: 3,
          totalScore: 2450,
          successPercent: 85,
          weeklyProgress: [100, 100, 85, 90, 100, 70, 100],
          earnedBadges: ['Cebir Ustası', '7\'lerin Efendisi', 'Kesir Uzmanı'],
          gamePerformance: [
            GamePerformance(gameName: 'Kesir Pastanesi', successPercent: 80),
            GamePerformance(gameName: 'Çarpanlar Kulesi', successPercent: 68),
            GamePerformance(gameName: 'Cebir Diyarı', successPercent: 62),
          ],
          topicPerformance: [
            TopicPerformance(
              topicName: '7\'şer ritmik sayma',
              successPercent: 45,
              needsAttention: true,
            ),
            TopicPerformance(
              topicName: 'Kesirler',
              successPercent: 80,
            ),
            TopicPerformance(
              topicName: 'Çarpma',
              successPercent: 72,
            ),
            TopicPerformance(
              topicName: 'Toplama/Çıkarma',
              successPercent: 92,
            ),
          ],
        ),
        // Mehmet: 6 yaş, 1. sınıf, %76 başarı
        const ParentPanelChild(
          id: 'mehmet',
          name: 'Mehmet',
          age: 6,
          grade: 1,
          totalScore: 1820,
          successPercent: 76,
          weeklyProgress: [80, 100, 60, 90, 100, 50, 75],
          earnedBadges: ['Sayı Avcısı', 'Toplama Kahramanı'],
          gamePerformance: [
            GamePerformance(gameName: 'Sayı Bahçesi', successPercent: 82),
            GamePerformance(gameName: 'Toplama Treni', successPercent: 70),
            GamePerformance(gameName: 'Şekil Avcısı', successPercent: 65),
          ],
          topicPerformance: [
            TopicPerformance(
              topicName: '1-20 arası sayılar',
              successPercent: 88,
            ),
            TopicPerformance(
              topicName: 'Toplama',
              successPercent: 72,
            ),
            TopicPerformance(
              topicName: 'Basit çıkarma',
              successPercent: 68,
            ),
          ],
        ),
        // Zeynep: 10 yaş, 5. sınıf, %83 başarı
        const ParentPanelChild(
          id: 'zeynep',
          name: 'Zeynep',
          age: 10,
          grade: 5,
          totalScore: 3120,
          successPercent: 83,
          weeklyProgress: [100, 95, 100, 85, 100, 90, 100],
          earnedBadges: ['Cebir Ustası', 'Geometri Uzmanı', 'Problem Çözücü'],
          gamePerformance: [
            GamePerformance(gameName: 'Cebir Diyarı', successPercent: 78),
            GamePerformance(gameName: 'Geometri Labirenti', successPercent: 85),
            GamePerformance(gameName: 'Problem Ormanı', successPercent: 72),
          ],
          topicPerformance: [
            TopicPerformance(
              topicName: 'Ondalık sayılar',
              successPercent: 90,
            ),
            TopicPerformance(
              topicName: 'Cebir',
              successPercent: 78,
            ),
            TopicPerformance(
              topicName: 'Geometri',
              successPercent: 85,
            ),
          ],
        ),
      ];

  static ParentPanelChild getChildById(String id) {
    return children.firstWhere((c) => c.id == id);
  }
}
