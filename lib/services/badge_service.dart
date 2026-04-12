import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mathfun/models/badge.dart';
import 'package:mathfun/models/app_user.dart';
import 'package:mathfun/models/spin_wheel_reward.dart';
import 'package:mathfun/models/topic_performance_stats.dart';

class BadgeService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  String? _userId;
  bool _isGuest = true;
  
  UserStats? _userStats;
  List<EarnedBadge> _earnedBadges = [];
  List<BadgeDefinition> _newlyUnlockedBadges = []; // Yeni açılan rozetler (bildirim için)
  
  // Getters
  UserStats? get userStats => _userStats;
  List<EarnedBadge> get earnedBadges => _earnedBadges;
  List<BadgeDefinition> get newlyUnlockedBadges => _newlyUnlockedBadges;
  int get totalBadgesCount => allBadges.length;
  int get earnedBadgesCount => _earnedBadges.length;
  bool get isGuest => _isGuest;

  // ==================== TÜM ROZETLER ====================
  
  static const List<BadgeDefinition> allBadges = [
    // 🎮 GAMEPLAY - Oyun Oynama
    BadgeDefinition(
      id: 'first_game',
      nameKey: 'badge_first_game',
      descriptionKey: 'badge_first_game_desc',
      emoji: '🎯',
      category: BadgeCategory.gameplay,
      rarity: BadgeRarity.common,
      targetValue: 1,
      statKey: 'totalGamesPlayed',
    ),
    BadgeDefinition(
      id: 'games_10',
      nameKey: 'badge_games_10',
      descriptionKey: 'badge_games_10_desc',
      emoji: '🎮',
      category: BadgeCategory.gameplay,
      rarity: BadgeRarity.common,
      targetValue: 10,
      statKey: 'totalGamesPlayed',
    ),
    BadgeDefinition(
      id: 'games_50',
      nameKey: 'badge_games_50',
      descriptionKey: 'badge_games_50_desc',
      emoji: '🕹️',
      category: BadgeCategory.gameplay,
      rarity: BadgeRarity.uncommon,
      targetValue: 50,
      statKey: 'totalGamesPlayed',
    ),
    BadgeDefinition(
      id: 'games_100',
      nameKey: 'badge_games_100',
      descriptionKey: 'badge_games_100_desc',
      emoji: '🏆',
      category: BadgeCategory.gameplay,
      rarity: BadgeRarity.rare,
      targetValue: 100,
      statKey: 'totalGamesPlayed',
    ),
    BadgeDefinition(
      id: 'games_500',
      nameKey: 'badge_games_500',
      descriptionKey: 'badge_games_500_desc',
      emoji: '👑',
      category: BadgeCategory.gameplay,
      rarity: BadgeRarity.legendary,
      targetValue: 500,
      statKey: 'totalGamesPlayed',
    ),

    // 📝 SORULAR
    BadgeDefinition(
      id: 'questions_100',
      nameKey: 'badge_questions_100',
      descriptionKey: 'badge_questions_100_desc',
      emoji: '📝',
      category: BadgeCategory.gameplay,
      rarity: BadgeRarity.common,
      targetValue: 100,
      statKey: 'totalQuestionsAnswered',
    ),
    BadgeDefinition(
      id: 'questions_500',
      nameKey: 'badge_questions_500',
      descriptionKey: 'badge_questions_500_desc',
      emoji: '📚',
      category: BadgeCategory.gameplay,
      rarity: BadgeRarity.uncommon,
      targetValue: 500,
      statKey: 'totalQuestionsAnswered',
    ),
    BadgeDefinition(
      id: 'questions_1000',
      nameKey: 'badge_questions_1000',
      descriptionKey: 'badge_questions_1000_desc',
      emoji: '🧠',
      category: BadgeCategory.gameplay,
      rarity: BadgeRarity.rare,
      targetValue: 1000,
      statKey: 'totalQuestionsAnswered',
    ),
    BadgeDefinition(
      id: 'questions_5000',
      nameKey: 'badge_questions_5000',
      descriptionKey: 'badge_questions_5000_desc',
      emoji: '🎓',
      category: BadgeCategory.gameplay,
      rarity: BadgeRarity.epic,
      targetValue: 5000,
      statKey: 'totalQuestionsAnswered',
    ),

    // 🔥 SERİ
    BadgeDefinition(
      id: 'streak_5',
      nameKey: 'badge_streak_5',
      descriptionKey: 'badge_streak_5_desc',
      emoji: '🔥',
      category: BadgeCategory.streak,
      rarity: BadgeRarity.common,
      targetValue: 5,
      statKey: 'bestStreak',
    ),
    BadgeDefinition(
      id: 'streak_10',
      nameKey: 'badge_streak_10',
      descriptionKey: 'badge_streak_10_desc',
      emoji: '💥',
      category: BadgeCategory.streak,
      rarity: BadgeRarity.uncommon,
      targetValue: 10,
      statKey: 'bestStreak',
    ),
    BadgeDefinition(
      id: 'streak_25',
      nameKey: 'badge_streak_25',
      descriptionKey: 'badge_streak_25_desc',
      emoji: '⚡',
      category: BadgeCategory.streak,
      rarity: BadgeRarity.rare,
      targetValue: 25,
      statKey: 'bestStreak',
    ),
    BadgeDefinition(
      id: 'streak_50',
      nameKey: 'badge_streak_50',
      descriptionKey: 'badge_streak_50_desc',
      emoji: '🌟',
      category: BadgeCategory.streak,
      rarity: BadgeRarity.epic,
      targetValue: 50,
      statKey: 'bestStreak',
    ),
    BadgeDefinition(
      id: 'streak_100',
      nameKey: 'badge_streak_100',
      descriptionKey: 'badge_streak_100_desc',
      emoji: '☄️',
      category: BadgeCategory.streak,
      rarity: BadgeRarity.legendary,
      targetValue: 100,
      statKey: 'bestStreak',
    ),

    // ⚡ HIZ
    BadgeDefinition(
      id: 'fast_10',
      nameKey: 'badge_fast_10',
      descriptionKey: 'badge_fast_10_desc',
      emoji: '⏱️',
      category: BadgeCategory.speed,
      rarity: BadgeRarity.common,
      targetValue: 10,
      statKey: 'fastAnswers',
    ),
    BadgeDefinition(
      id: 'fast_50',
      nameKey: 'badge_fast_50',
      descriptionKey: 'badge_fast_50_desc',
      emoji: '🚀',
      category: BadgeCategory.speed,
      rarity: BadgeRarity.uncommon,
      targetValue: 50,
      statKey: 'fastAnswers',
    ),
    BadgeDefinition(
      id: 'fast_200',
      nameKey: 'badge_fast_200',
      descriptionKey: 'badge_fast_200_desc',
      emoji: '💨',
      category: BadgeCategory.speed,
      rarity: BadgeRarity.rare,
      targetValue: 200,
      statKey: 'fastAnswers',
    ),
    BadgeDefinition(
      id: 'superfast_10',
      nameKey: 'badge_superfast_10',
      descriptionKey: 'badge_superfast_10_desc',
      emoji: '⚡',
      category: BadgeCategory.speed,
      rarity: BadgeRarity.epic,
      targetValue: 10,
      statKey: 'superFastAnswers',
    ),

    // ✅ DOĞRULUK
    BadgeDefinition(
      id: 'perfect_1',
      nameKey: 'badge_perfect_1',
      descriptionKey: 'badge_perfect_1_desc',
      emoji: '✨',
      category: BadgeCategory.accuracy,
      rarity: BadgeRarity.common,
      targetValue: 1,
      statKey: 'perfectGames',
    ),
    BadgeDefinition(
      id: 'perfect_5',
      nameKey: 'badge_perfect_5',
      descriptionKey: 'badge_perfect_5_desc',
      emoji: '💎',
      category: BadgeCategory.accuracy,
      rarity: BadgeRarity.uncommon,
      targetValue: 5,
      statKey: 'perfectGames',
    ),
    BadgeDefinition(
      id: 'perfect_20',
      nameKey: 'badge_perfect_20',
      descriptionKey: 'badge_perfect_20_desc',
      emoji: '🏅',
      category: BadgeCategory.accuracy,
      rarity: BadgeRarity.rare,
      targetValue: 20,
      statKey: 'perfectGames',
    ),
    BadgeDefinition(
      id: 'perfect_50',
      nameKey: 'badge_perfect_50',
      descriptionKey: 'badge_perfect_50_desc',
      emoji: '🌈',
      category: BadgeCategory.accuracy,
      rarity: BadgeRarity.epic,
      targetValue: 50,
      statKey: 'perfectGames',
    ),

    // 👥 SOSYAL
    BadgeDefinition(
      id: 'first_friend',
      nameKey: 'badge_first_friend',
      descriptionKey: 'badge_first_friend_desc',
      emoji: '🤝',
      category: BadgeCategory.social,
      rarity: BadgeRarity.common,
      targetValue: 1,
      statKey: 'friendsCount',
    ),
    BadgeDefinition(
      id: 'friends_5',
      nameKey: 'badge_friends_5',
      descriptionKey: 'badge_friends_5_desc',
      emoji: '👥',
      category: BadgeCategory.social,
      rarity: BadgeRarity.uncommon,
      targetValue: 5,
      statKey: 'friendsCount',
    ),
    BadgeDefinition(
      id: 'friends_20',
      nameKey: 'badge_friends_20',
      descriptionKey: 'badge_friends_20_desc',
      emoji: '🎉',
      category: BadgeCategory.social,
      rarity: BadgeRarity.rare,
      targetValue: 20,
      statKey: 'friendsCount',
    ),

    // 📅 SADAKAT
    BadgeDefinition(
      id: 'days_7',
      nameKey: 'badge_days_7',
      descriptionKey: 'badge_days_7_desc',
      emoji: '📅',
      category: BadgeCategory.loyalty,
      rarity: BadgeRarity.uncommon,
      targetValue: 7,
      statKey: 'consecutiveDays',
    ),
    BadgeDefinition(
      id: 'days_30',
      nameKey: 'badge_days_30',
      descriptionKey: 'badge_days_30_desc',
      emoji: '🗓️',
      category: BadgeCategory.loyalty,
      rarity: BadgeRarity.rare,
      targetValue: 30,
      statKey: 'consecutiveDays',
    ),
    BadgeDefinition(
      id: 'days_100',
      nameKey: 'badge_days_100',
      descriptionKey: 'badge_days_100_desc',
      emoji: '🏛️',
      category: BadgeCategory.loyalty,
      rarity: BadgeRarity.legendary,
      targetValue: 100,
      statKey: 'consecutiveDays',
    ),

    // 🎖️ USTALИК
    BadgeDefinition(
      id: 'score_1000',
      nameKey: 'badge_score_1000',
      descriptionKey: 'badge_score_1000_desc',
      emoji: '⭐',
      category: BadgeCategory.mastery,
      rarity: BadgeRarity.common,
      targetValue: 1000,
      statKey: 'totalScore',
    ),
    BadgeDefinition(
      id: 'score_10000',
      nameKey: 'badge_score_10000',
      descriptionKey: 'badge_score_10000_desc',
      emoji: '🌟',
      category: BadgeCategory.mastery,
      rarity: BadgeRarity.rare,
      targetValue: 10000,
      statKey: 'totalScore',
    ),
    BadgeDefinition(
      id: 'score_100000',
      nameKey: 'badge_score_100000',
      descriptionKey: 'badge_score_100000_desc',
      emoji: '💫',
      category: BadgeCategory.mastery,
      rarity: BadgeRarity.legendary,
      targetValue: 100000,
      statKey: 'totalScore',
    ),
  ];

  // ==================== BAŞLATMA ====================

  void initialize(AppUser? user) {
    if (user == null) {
      _userId = null;
      _isGuest = true;
      _userStats = null;
      _earnedBadges = [];
      notifyListeners();
      return;
    }

    _userId = user.uid;
    _isGuest = user.isGuest;

    if (!_isGuest) {
      _loadUserStats();
      _loadEarnedBadges();
    }
  }

  // ==================== VERİ YÜKLEME ====================

  Future<void> _loadUserStats() async {
    if (_userId == null || _isGuest) return;

    try {
      final doc = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('stats')
          .doc('gameStats')
          .get();

      if (doc.exists && doc.data() != null) {
        _userStats = UserStats.fromMap(doc.data()!, _userId!);
      } else {
        _userStats = UserStats(userId: _userId!);
        await _saveUserStats();
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Load user stats error: $e');
      _userStats = UserStats(userId: _userId!);
    }
  }

  Future<void> _loadEarnedBadges() async {
    if (_userId == null || _isGuest) return;

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('badges')
          .orderBy('earnedAt', descending: true)
          .get();

      _earnedBadges = snapshot.docs
          .map((doc) => EarnedBadge.fromMap(doc.data(), doc.id))
          .toList();
      
      notifyListeners();
    } catch (e) {
      debugPrint('Load earned badges error: $e');
    }
  }

  // ==================== İSTATİSTİK GÜNCELLEME ====================

  Future<void> _saveUserStats() async {
    if (_userId == null || _isGuest || _userStats == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('stats')
          .doc('gameStats')
          .set(_userStats!.toMap());
    } catch (e) {
      debugPrint('Save user stats error: $e');
    }
  }

  /// Oyun tamamlandığında çağrılır
  Future<List<BadgeDefinition>> onGameCompleted({
    required int questionsAnswered,
    required int correctAnswers,
    required int wrongAnswers,
    required int score,
    required double averageTime,
    required int fastAnswersCount,
    required int superFastAnswersCount,
    required int streak,
  }) async {
    if (_userId == null || _isGuest) return [];

    // Mevcut stats'ı al veya oluştur
    _userStats ??= UserStats(userId: _userId!);

    final bool isPerfectGame = wrongAnswers == 0 && questionsAnswered > 0;
    final previousLastPlayed = _userStats!.lastPlayedAt;

    // Stats'ı güncelle
    _userStats = _userStats!.copyWith(
      totalGamesPlayed: _userStats!.totalGamesPlayed + 1,
      totalQuestionsAnswered: _userStats!.totalQuestionsAnswered + questionsAnswered,
      totalCorrectAnswers: _userStats!.totalCorrectAnswers + correctAnswers,
      totalWrongAnswers: _userStats!.totalWrongAnswers + wrongAnswers,
      totalScore: _userStats!.totalScore + score,
      currentStreak: streak,
      bestStreak: streak > _userStats!.bestStreak ? streak : _userStats!.bestStreak,
      fastAnswers: _userStats!.fastAnswers + fastAnswersCount,
      superFastAnswers: _userStats!.superFastAnswers + superFastAnswersCount,
      bestAverageTime: averageTime < _userStats!.bestAverageTime ? averageTime : _userStats!.bestAverageTime,
      perfectGames: isPerfectGame ? _userStats!.perfectGames + 1 : _userStats!.perfectGames,
      lastPlayedAt: DateTime.now(),
    );

    // Günlük ardışık oyun günü (önceki `lastPlayedAt` ile takvim farkı)
    await _updateDailyStreak(previousLastPlayed: previousLastPlayed);

    // Stats'ı kaydet
    await _saveUserStats();

    // Rozetleri kontrol et
    final newBadges = await _checkAndUnlockBadges();
    
    notifyListeners();
    return newBadges;
  }

  /// Şans çarkı ödülünü profile ekle (XP, coins vb.)
  Future<void> addSpinWheelReward(SpinWheelReward reward, {int multiplier = 1}) async {
    if (_userId == null || _userId!.isEmpty || _isGuest) return;

    _userStats ??= UserStats(userId: _userId!);

    final m = multiplier.clamp(1, 10);
    switch (reward.type) {
      case 'coins':
        _userStats = _userStats!.copyWith(
          coinsEarned: _userStats!.coinsEarned + reward.value * m,
        );
        break;
      case 'xp':
        _userStats = _userStats!.copyWith(
          totalScore: _userStats!.totalScore + reward.value * m,
        );
        break;
      case 'stars':
      case 'lightning':
        // Yıldızlar UserRewards.profileBonusStars (SpinWheelScreen); şimşek rozet yok
        return;
      default:
        return;
    }

    await _saveUserStats();
    notifyListeners();
  }

  /// Arkadaş eklendiğinde çağrılır
  Future<List<BadgeDefinition>> onFriendAdded() async {
    if (_userId == null || _isGuest) return [];

    _userStats ??= UserStats(userId: _userId!);
    _userStats = _userStats!.copyWith(
      friendsCount: _userStats!.friendsCount + 1,
    );

    await _saveUserStats();
    final newBadges = await _checkAndUnlockBadges();
    notifyListeners();
    return newBadges;
  }

  /// Oyun oturumu sonunda: önceki `lastPlayedAt` ile takvim günü farkına göre `consecutiveDays` güncellenir.
  Future<void> _updateDailyStreak({DateTime? previousLastPlayed}) async {
    if (_userStats == null) return;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (previousLastPlayed == null) {
      _userStats = _userStats!.copyWith(
        consecutiveDays: _userStats!.consecutiveDays < 1 ? 1 : _userStats!.consecutiveDays,
        totalDaysPlayed: _userStats!.totalDaysPlayed < 1 ? 1 : _userStats!.totalDaysPlayed,
      );
      return;
    }

    final prevDay = DateTime(
      previousLastPlayed.year,
      previousLastPlayed.month,
      previousLastPlayed.day,
    );
    final diff = today.difference(prevDay).inDays;

    if (diff == 0) {
      // Aynı takvim günü — seri sayacı değişmez
      return;
    }

    if (diff == 1) {
      final next = _userStats!.consecutiveDays + 1;
      _userStats = _userStats!.copyWith(
        consecutiveDays: next,
        bestDailyStreak: next > _userStats!.bestDailyStreak ? next : _userStats!.bestDailyStreak,
        totalDaysPlayed: _userStats!.totalDaysPlayed + 1,
      );
    } else {
      _userStats = _userStats!.copyWith(
        consecutiveDays: 1,
        totalDaysPlayed: _userStats!.totalDaysPlayed + 1,
      );
    }
  }

  // ==================== ROZET KONTROLÜ ====================

  Future<List<BadgeDefinition>> _checkAndUnlockBadges() async {
    if (_userId == null || _isGuest || _userStats == null) return [];

    final newlyUnlocked = <BadgeDefinition>[];
    final earnedBadgeIds = _earnedBadges.map((e) => e.badgeId).toSet();

    for (final badge in allBadges) {
      // Zaten kazanılmış mı?
      if (earnedBadgeIds.contains(badge.id)) continue;

      // Hedef değere ulaşılmış mı?
      final currentValue = _userStats!.getStatValue(badge.statKey);
      if (currentValue >= badge.targetValue) {
        // Rozeti kazan!
        await _unlockBadge(badge, currentValue);
        newlyUnlocked.add(badge);
      }
    }

    if (newlyUnlocked.isNotEmpty) {
      _newlyUnlockedBadges = newlyUnlocked;
      
      // Achievements unlocked sayısını güncelle
      _userStats = _userStats!.copyWith(
        achievementsUnlocked: _earnedBadges.length,
      );
      await _saveUserStats();
    }

    return newlyUnlocked;
  }

  Future<void> _unlockBadge(BadgeDefinition badge, int valueAtEarn) async {
    if (_userId == null) return;

    final earnedBadge = EarnedBadge(
      userId: _userId!,
      badgeId: badge.id,
      earnedAt: DateTime.now(),
      valueAtEarn: valueAtEarn,
    );

    try {
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('badges')
          .doc(badge.id)
          .set(earnedBadge.toMap());

      _earnedBadges.insert(0, earnedBadge);
    } catch (e) {
      debugPrint('Unlock badge error: $e');
    }
  }

  // ==================== YARDIMCI METOTLAR ====================

  /// Rozet kazanılmış mı kontrol et
  bool isBadgeEarned(String badgeId) {
    return _earnedBadges.any((e) => e.badgeId == badgeId);
  }

  /// Rozet tanımını al
  BadgeDefinition? getBadgeDefinition(String badgeId) {
    try {
      return allBadges.firstWhere((b) => b.id == badgeId);
    } catch (e) {
      return null;
    }
  }

  /// Belirli bir rozet için ilerleme yüzdesini al
  double getBadgeProgress(BadgeDefinition badge) {
    if (_userStats == null) return 0.0;
    
    final currentValue = _userStats!.getStatValue(badge.statKey);
    final progress = currentValue / badge.targetValue;
    return progress.clamp(0.0, 1.0);
  }

  /// Kategoriye göre rozetleri al
  List<BadgeDefinition> getBadgesByCategory(BadgeCategory category) {
    return allBadges.where((b) => b.category == category).toList();
  }

  /// Nadirliğe göre rozetleri al
  List<BadgeDefinition> getBadgesByRarity(BadgeRarity rarity) {
    return allBadges.where((b) => b.rarity == rarity).toList();
  }

  /// Yeni rozet bildirimlerini temizle
  void clearNewBadgeNotifications() {
    _newlyUnlockedBadges = [];
    notifyListeners();
  }

  /// Verileri yenile
  Future<void> refresh() async {
    if (_isGuest) return;
    await _loadUserStats();
    await _loadEarnedBadges();
  }

  /// Konu bazlı performans istatistiklerini al
  /// [targetUserId] - Belirli kullanıcı için (null ise mevcut kullanıcı)
  Future<List<TopicPerformanceStats>> getTopicPerformanceStats({
    String? targetUserId,
    TopicTimeFilter timeFilter = TopicTimeFilter.allTime,
  }) async {
    final uid = targetUserId ?? _userId;
    if (uid == null) return _getSampleTopicStatsFromUserStats(null);

    try {
      final doc = await _firestore
          .collection('users')
          .doc(uid)
          .collection('stats')
          .doc('topicStats')
          .get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        final topics = data['topics'] as Map<String, dynamic>?;
        if (topics != null) {
          final result = <TopicPerformanceStats>[];
          for (final def in TopicDefinitions.all) {
            final topicId = def['id']!;
            final topicData = topics[topicId] as Map<String, dynamic>?;
            if (topicData != null) {
              final total = (topicData['totalQuestions'] ?? 0) as int;
              final correct = (topicData['correctCount'] ?? 0) as int;
              final wrong = (topicData['wrongCount'] ?? total - correct) as int;
              final avgTime = (topicData['avgTimeSeconds'] ?? 0.0) as num;
              final percent = total > 0 ? (correct / total * 100).round() : 0;
              result.add(TopicPerformanceStats(
                topicId: topicId,
                topicName: def['name']!,
                emoji: def['emoji']!,
                correctCount: correct,
                wrongCount: wrong,
                avgTimeSeconds: avgTime.toDouble(),
                totalQuestions: total,
                successPercent: percent,
              ));
            } else {
              result.add(_emptyTopicStats(def));
            }
          }
          return result;
        }
      }
    } catch (e) {
      debugPrint('Load topic stats error: $e');
    }

    final userStats = await _loadUserStatsFor(uid);
    return _getSampleTopicStatsFromUserStats(userStats);
  }

  Future<UserStats?> _loadUserStatsFor(String targetUid) async {
    if (targetUid == _userId) return _userStats;
    try {
      final doc = await _firestore
          .collection('users')
          .doc(targetUid)
          .collection('stats')
          .doc('gameStats')
          .get();
      if (doc.exists && doc.data() != null) {
        return UserStats.fromMap(doc.data()!, targetUid);
      }
    } catch (e) {
      debugPrint('Load user stats for $targetUid error: $e');
    }
    return null;
  }

  List<TopicPerformanceStats> _getSampleTopicStatsFromUserStats(UserStats? stats) {
    final totalQ = stats?.totalQuestionsAnswered ?? 45;
    final totalC = stats?.totalCorrectAnswers ?? 35;
    final totalW = stats?.totalWrongAnswers ?? 10;
    final avgTime = stats?.bestAverageTime ?? 12.0;

    if (totalQ == 0) {
      return TopicDefinitions.all
          .map((def) => _emptyTopicStats(def))
          .toList();
    }

    final variations = [0.92, 1.08, 0.85, 1.15];
    return TopicDefinitions.all.asMap().entries.map((entry) {
      final i = entry.key;
      final def = entry.value;
      final share = variations[i] / 4;
      final total = (totalQ * share).round().clamp(1, totalQ);
      final correct = (totalC * share).round().clamp(0, total);
      final wrong = (total - correct).clamp(0, total);
      final percent = total > 0 ? (correct / total * 100).round() : 0;
      return TopicPerformanceStats(
        topicId: def['id']!,
        topicName: def['name']!,
        emoji: def['emoji']!,
        correctCount: correct,
        wrongCount: wrong,
        avgTimeSeconds: avgTime * (0.9 + (i * 0.05)),
        totalQuestions: total,
        successPercent: percent,
      );
    }).toList();
  }

  TopicPerformanceStats _emptyTopicStats(Map<String, String> def) {
    return TopicPerformanceStats(
      topicId: def['id']!,
      topicName: def['name']!,
      emoji: def['emoji']!,
      correctCount: 0,
      wrongCount: 0,
      avgTimeSeconds: 0,
      totalQuestions: 0,
      successPercent: 0,
    );
  }
}

