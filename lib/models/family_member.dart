/// Aile üyesi modeli
class FamilyMember {
  final String userId;
  final String displayName;
  final bool isParent;

  const FamilyMember({
    required this.userId,
    required this.displayName,
    this.isParent = false,
  });

  factory FamilyMember.fromMap(Map<String, dynamic> map) {
    return FamilyMember(
      userId: map['userId'] ?? '',
      displayName: map['displayName'] ?? 'Oyuncu',
      isParent: map['isParent'] ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'displayName': displayName,
        'isParent': isParent,
      };
}

/// Liderlik tablosu girişi (detay ekranı için gerekli alanlar dahil)
class LeaderboardEntry {
  final int rank;
  final String userId;
  final String displayName;
  final int score;
  final int accuracy;
  final DateTime? lastPlayedAt;
  final bool isParent;
  final int earnedBadges;
  final List<int> weeklyValues;

  const LeaderboardEntry({
    required this.rank,
    required this.userId,
    required this.displayName,
    required this.score,
    required this.accuracy,
    this.lastPlayedAt,
    this.isParent = false,
    this.earnedBadges = 0,
    this.weeklyValues = const [],
  });
}

/// Liderlik tablosu filtre türü
enum LeaderboardFilter {
  weekly,
  monthly,
  allTime,
}
