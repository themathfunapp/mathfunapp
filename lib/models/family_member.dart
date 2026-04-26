/// Aile üyesi modeli
class FamilyMember {
  final String userId;
  final String displayName;
  final bool isParent;
  final String? profileEmoji;

  const FamilyMember({
    required this.userId,
    required this.displayName,
    this.isParent = false,
    this.profileEmoji,
  });

  factory FamilyMember.fromMap(Map<String, dynamic> map) {
    return FamilyMember(
      userId: map['userId'] ?? '',
      displayName: map['displayName'] ?? 'Oyuncu',
      isParent: map['isParent'] ?? false,
      profileEmoji: map['profileEmoji'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'displayName': displayName,
        'isParent': isParent,
        'profileEmoji': profileEmoji,
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
  final String? profileEmoji;

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
    this.profileEmoji,
  });
}

/// Liderlik tablosu filtre türü
enum LeaderboardFilter {
  weekly,
  monthly,
  allTime,
}
