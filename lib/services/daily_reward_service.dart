import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/daily_reward.dart';
import '../models/app_user.dart';
import 'world_leaderboard_sync.dart';

class DailyRewardService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Random _random = Random();
  
  String? _userId;
  bool _isGuest = true;
  String? _leaderboardDisplayName;
  String? _leaderboardProfileEmoji;
  
  UserRewards? _userRewards;
  Map<String, UserTaskProgress> _taskProgress = {};
  
  // Getters
  UserRewards? get userRewards => _userRewards;
  Map<String, UserTaskProgress> get taskProgress => _taskProgress;
  bool get isGuest => _isGuest;
  int get coins => _userRewards?.coins ?? 0;
  int get diamonds => _userRewards?.diamonds ?? 0;
  int get profileBonusStars => _userRewards?.profileBonusStars ?? 0;
  int get loginStreak => _userRewards?.loginStreak ?? 0;
  int get freeSpinsToday => _userRewards?.freeSpinsToday ?? 0;
  bool get canSpin => (_userRewards?.freeSpinsToday ?? 0) > 0;
  bool get dailyBoxOpened => _userRewards?.dailyBoxOpened ?? false;

  // ==================== STREAK ÖDÜL TANIMLARI ====================
  
  static const List<StreakReward> streakRewards = [
    StreakReward(day: 1, rewards: [
      RewardItem(type: RewardType.coins, amount: 8, emoji: '🪙'),
      RewardItem(type: RewardType.stars, amount: 1, emoji: '⭐'),
    ]),
    StreakReward(day: 2, rewards: [
      RewardItem(type: RewardType.coins, amount: 10, emoji: '🪙'),
      RewardItem(type: RewardType.coins, amount: 8, emoji: '⚡'),
    ]),
    StreakReward(day: 3, rewards: [
      RewardItem(type: RewardType.coins, amount: 12, emoji: '🪙'),
      RewardItem(type: RewardType.stars, amount: 1, emoji: '⭐'),
    ]),
    StreakReward(day: 4, rewards: [
      RewardItem(type: RewardType.coins, amount: 15, emoji: '🪙'),
      RewardItem(type: RewardType.diamonds, amount: 1, emoji: '💎'),
    ]),
    StreakReward(day: 5, rewards: [
      RewardItem(type: RewardType.coins, amount: 15, emoji: '🪙'),
      RewardItem(type: RewardType.powerUp, amount: 1, powerUpType: PowerUpType.doublePoints, emoji: '✨'),
    ], isSpecial: true),
    StreakReward(day: 6, rewards: [
      RewardItem(type: RewardType.coins, amount: 15, emoji: '🪙'),
      RewardItem(type: RewardType.diamonds, amount: 2, emoji: '💎'),
    ]),
    StreakReward(day: 7, rewards: [
      RewardItem(type: RewardType.coins, amount: 15, emoji: '🪙'),
      RewardItem(type: RewardType.diamonds, amount: 2, emoji: '💎'),
      RewardItem(type: RewardType.stars, amount: 2, emoji: '⭐'),
      RewardItem(type: RewardType.badge, amount: 1, itemId: 'weekly_streak', emoji: '🏆'),
    ], isSpecial: true),
  ];

  // ==================== GÜNLÜK GÖREV TANIMLARI ====================
  
  static const List<DailyTask> dailyTasks = [
    // Kolay görevler
    DailyTask(
      id: 'solve_5',
      titleKey: 'task_solve_5',
      descriptionKey: 'task_solve_5_desc',
      emoji: '🎯',
      type: TaskType.solveQuestions,
      targetValue: 5,
      rewards: [RewardItem(type: RewardType.coins, amount: 8, emoji: '🪙')],
      difficulty: TaskDifficulty.easy,
    ),
    DailyTask(
      id: 'play_3_games',
      titleKey: 'task_play_3',
      descriptionKey: 'task_play_3_desc',
      emoji: '🎮',
      type: TaskType.playGames,
      targetValue: 3,
      rewards: [RewardItem(type: RewardType.coins, amount: 10, emoji: '🪙')],
      difficulty: TaskDifficulty.easy,
    ),
    DailyTask(
      id: 'daily_login',
      titleKey: 'task_login',
      descriptionKey: 'task_login_desc',
      emoji: '📅',
      type: TaskType.dailyLogin,
      targetValue: 1,
      rewards: [RewardItem(type: RewardType.coins, amount: 8, emoji: '🪙')],
      difficulty: TaskDifficulty.easy,
    ),
    // Orta görevler
    DailyTask(
      id: 'streak_5',
      titleKey: 'task_streak_5',
      descriptionKey: 'task_streak_5_desc',
      emoji: '🔥',
      type: TaskType.correctStreak,
      targetValue: 5,
      rewards: [
        RewardItem(type: RewardType.coins, amount: 12, emoji: '🪙'),
        RewardItem(type: RewardType.diamonds, amount: 1, emoji: '💎'),
      ],
      difficulty: TaskDifficulty.medium,
    ),
    DailyTask(
      id: 'solve_10_90',
      titleKey: 'task_solve_10_90',
      descriptionKey: 'task_solve_10_90_desc',
      emoji: '⭐',
      type: TaskType.solveQuestions,
      targetValue: 10,
      rewards: [
        RewardItem(type: RewardType.coins, amount: 15, emoji: '🪙'),
        RewardItem(type: RewardType.diamonds, amount: 2, emoji: '💎'),
      ],
      difficulty: TaskDifficulty.medium,
    ),
    // Zor görevler
    DailyTask(
      id: 'perfect_game',
      titleKey: 'task_perfect',
      descriptionKey: 'task_perfect_desc',
      emoji: '💎',
      type: TaskType.perfectGame,
      targetValue: 1,
      rewards: [
        RewardItem(type: RewardType.coins, amount: 15, emoji: '🪙'),
        RewardItem(type: RewardType.powerUp, amount: 1, powerUpType: PowerUpType.doublePoints, emoji: '✨'),
      ],
      difficulty: TaskDifficulty.hard,
    ),
    DailyTask(
      id: 'fast_10',
      titleKey: 'task_fast_10',
      descriptionKey: 'task_fast_10_desc',
      emoji: '⚡',
      type: TaskType.fastAnswers,
      targetValue: 10,
      rewards: [
        RewardItem(type: RewardType.coins, amount: 15, emoji: '🪙'),
        RewardItem(type: RewardType.diamonds, amount: 2, emoji: '💎'),
      ],
      difficulty: TaskDifficulty.hard,
    ),
  ];

  // ==================== ŞANS ÇARKI DİLİMLERİ ====================
  
  static const List<WheelSlice> wheelSlices = [
    WheelSlice(
      reward: RewardItem(type: RewardType.coins, amount: 8, emoji: '🪙'),
      probability: 0.22,
      colorIndex: 0,
    ),
    WheelSlice(
      reward: RewardItem(type: RewardType.coins, amount: 10, emoji: '🪙'),
      probability: 0.22,
      colorIndex: 1,
    ),
    WheelSlice(
      reward: RewardItem(type: RewardType.coins, amount: 12, emoji: '🪙'),
      probability: 0.20,
      colorIndex: 2,
    ),
    WheelSlice(
      reward: RewardItem(type: RewardType.coins, amount: 15, emoji: '⚡'),
      probability: 0.16,
      colorIndex: 3,
    ),
    WheelSlice(
      reward: RewardItem(type: RewardType.diamonds, amount: 1, emoji: '💎'),
      probability: 0.12,
      colorIndex: 4,
    ),
    WheelSlice(
      reward: RewardItem(type: RewardType.diamonds, amount: 2, emoji: '💎'),
      probability: 0.04,
      colorIndex: 5,
    ),
    WheelSlice(
      reward: RewardItem(type: RewardType.powerUp, amount: 1, powerUpType: PowerUpType.doublePoints, emoji: '✨'),
      probability: 0.02,
      colorIndex: 6,
    ),
    WheelSlice(
      reward: RewardItem(type: RewardType.stars, amount: 2, emoji: '⭐'),
      probability: 0.02,
      colorIndex: 7,
    ),
  ];

  // ==================== BAŞLATMA ====================

  void initialize(AppUser? user) {
    if (user == null) {
      _userId = null;
      _isGuest = true;
      _userRewards = null;
      _taskProgress = {};
      _leaderboardDisplayName = null;
      _leaderboardProfileEmoji = null;
      notifyListeners();
      return;
    }

    _userId = user.uid;
    _isGuest = user.isGuest;
    _leaderboardDisplayName = user.isGuest ? null : user.username;
    _leaderboardProfileEmoji = user.isGuest ? null : user.profileEmoji;

    if (!_isGuest) {
      _loadUserRewards();
      _loadTaskProgress();
    }
  }

  // ==================== VERİ YÜKLEME ====================

  Future<void> _loadUserRewards() async {
    if (_userId == null || _isGuest) return;

    try {
      final doc = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('rewards')
          .doc('daily')
          .get();

      final hadExistingDoc = doc.exists && doc.data() != null;
      if (hadExistingDoc) {
        _userRewards = UserRewards.fromMap(doc.data()!, _userId!);
        await _checkAndResetDaily();
      } else {
        _userRewards = UserRewards(userId: _userId!);
        await _saveUserRewards();
      }
      notifyListeners();

      // Mevcut kayıt yüklendiğinde sıralamayı güncelle (_saveUserRewards zaten yayımlıyorsa tekrar etme)
      if (_userRewards != null && hadExistingDoc) {
        unawaited(
          publishWorldLeaderboardScores(
            firestore: _firestore,
            userId: _userId!,
            coins: _userRewards!.coins,
            diamonds: _userRewards!.diamonds,
            displayName: _leaderboardDisplayName,
            profileEmoji: _leaderboardProfileEmoji,
          ).catchError((Object e) {
            debugPrint('World leaderboard publish: $e');
          }),
        );
      }
    } catch (e) {
      debugPrint('Load user rewards error: $e');
      _userRewards = UserRewards(userId: _userId!);
    }
  }

  Future<void> _loadTaskProgress() async {
    if (_userId == null || _isGuest) return;

    try {
      final today = _getTodayString();
      final doc = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('rewards')
          .doc('tasks_$today')
          .get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        _taskProgress = {};
        data.forEach((key, value) {
          if (value is Map<String, dynamic>) {
            _taskProgress[key] = UserTaskProgress.fromMap(value, key);
          }
        });
      } else {
        _initializeTodayTasks();
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Load task progress error: $e');
      _initializeTodayTasks();
    }
  }

  void _initializeTodayTasks() {
    _taskProgress = {};
    for (final task in dailyTasks) {
      _taskProgress[task.id] = UserTaskProgress(taskId: task.id);
    }
    // Günlük giriş görevini otomatik tamamla
    _taskProgress['daily_login'] = UserTaskProgress(
      taskId: 'daily_login',
      currentValue: 1,
      isCompleted: true,
    );
  }

  // ==================== GÜNLÜK SIFIRLAMA ====================

  Future<void> _checkAndResetDaily() async {
    if (_userRewards == null) return;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastReset = _userRewards!.tasksResetDate;

    if (lastReset == null || lastReset.isBefore(today)) {
      // Yeni gün - günlük değerleri sıfırla
      _userRewards = _userRewards!.copyWith(
        freeSpinsToday: 1,
        dailyBoxOpened: false,
        tasksResetDate: today,
      );

      // Streak kontrolü
      await _checkLoginStreak();

      await _saveUserRewards();
      _initializeTodayTasks();
      await _saveTaskProgress();
    }
  }

  Future<void> _checkLoginStreak() async {
    if (_userRewards == null) return;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastLogin = _userRewards!.lastLoginDate;

    if (lastLogin == null) {
      // İlk giriş
      _userRewards = _userRewards!.copyWith(
        loginStreak: 1,
        bestLoginStreak: 1,
        lastLoginDate: today,
      );
    } else {
      final lastLoginDate = DateTime(lastLogin.year, lastLogin.month, lastLogin.day);
      final difference = today.difference(lastLoginDate).inDays;

      if (difference == 1) {
        // Ardışık gün
        final newStreak = _userRewards!.loginStreak + 1;
        _userRewards = _userRewards!.copyWith(
          loginStreak: newStreak,
          bestLoginStreak: newStreak > _userRewards!.bestLoginStreak
              ? newStreak
              : _userRewards!.bestLoginStreak,
          lastLoginDate: today,
        );
      } else if (difference > 1) {
        // Streak bozuldu
        _userRewards = _userRewards!.copyWith(
          loginStreak: 1,
          lastLoginDate: today,
        );
      }
      // difference == 0 ise aynı gün, güncelleme yok
    }
  }

  // ==================== STREAK ÖDÜLÜ AL ====================

  StreakReward getCurrentStreakReward() {
    final streak = _userRewards?.loginStreak ?? 1;
    final dayIndex = ((streak - 1) % 7); // 0-6 arası
    return streakRewards[dayIndex];
  }

  bool canClaimStreakReward() {
    if (_userRewards == null) return false;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastClaim = _userRewards!.lastRewardClaimDate;

    if (lastClaim == null) return true;

    final lastClaimDate = DateTime(lastClaim.year, lastClaim.month, lastClaim.day);
    return today.isAfter(lastClaimDate);
  }

  Future<List<RewardItem>> claimStreakReward() async {
    if (!canClaimStreakReward() || _userId == null) return [];

    final reward = getCurrentStreakReward();
    
    // Ödülleri uygula
    await _applyRewards(reward.rewards);

    // Son talep tarihini güncelle
    _userRewards = _userRewards!.copyWith(
      lastRewardClaimDate: DateTime.now(),
    );

    await _saveUserRewards();
    notifyListeners();

    return reward.rewards;
  }

  // ==================== ŞANS ÇARKI ====================

  int getRandomWheelIndex() {
    final random = _random.nextDouble();
    double cumulative = 0.0;

    for (int i = 0; i < wheelSlices.length; i++) {
      cumulative += wheelSlices[i].probability;
      if (random <= cumulative) {
        return i;
      }
    }
    return 0;
  }

  /// [sliceIndex] verilirse çark animasyonu ile aynı dilim ödül olarak uygulanır.
  Future<RewardItem?> spinWheel({int? sliceIndex}) async {
    if (!canSpin || _userId == null || _isGuest) return null;

    final int index;
    if (sliceIndex != null) {
      if (sliceIndex < 0 || sliceIndex >= wheelSlices.length) return null;
      index = sliceIndex;
    } else {
      index = getRandomWheelIndex();
    }
    final reward = wheelSlices[index].reward;

    // Ödülü uygula
    await _applyRewards([reward]);

    // Spin sayısını güncelle
    _userRewards = _userRewards!.copyWith(
      freeSpinsToday: _userRewards!.freeSpinsToday - 1,
      totalSpins: _userRewards!.totalSpins + 1,
      lastSpinDate: DateTime.now(),
    );

    await _saveUserRewards();
    notifyListeners();

    return reward;
  }

  // ==================== SÜRPRİZ KUTU ====================

  Future<List<RewardItem>> openDailyBox() async {
    if (dailyBoxOpened || _userId == null || _isGuest) return [];

    // Rastgele 2-4 ödül
    final rewardCount = 2 + _random.nextInt(3);
    final rewards = <RewardItem>[];

    for (int i = 0; i < rewardCount; i++) {
      rewards.add(_getRandomBoxReward());
    }

    // Ödülleri uygula
    await _applyRewards(rewards);

    // Kutu durumunu güncelle
    _userRewards = _userRewards!.copyWith(
      dailyBoxOpened: true,
      totalBoxesOpened: _userRewards!.totalBoxesOpened + 1,
    );

    await _saveUserRewards();
    notifyListeners();

    return rewards;
  }

  RewardItem _getRandomBoxReward() {
    final rand = _random.nextDouble();

    if (rand < 0.40) {
      // %40 - Altın (5–15)
      final amounts = [5, 6, 8, 10, 12, 15];
      return RewardItem(
        type: RewardType.coins,
        amount: amounts[_random.nextInt(amounts.length)],
        emoji: '🪙',
      );
    } else if (rand < 0.60) {
      // %20 - Altın (5–15)
      return RewardItem(
        type: RewardType.coins,
        amount: 5 + _random.nextInt(11),
        emoji: '⚡',
      );
    } else if (rand < 0.72) {
      // %12 - Güçlendirici (makas / halfOptions hariç — oyunda kullanılmıyor)
      final powerUps = PowerUpType.values
          .where((p) => p != PowerUpType.halfOptions)
          .toList();
      return RewardItem(
        type: RewardType.powerUp,
        amount: 1,
        powerUpType: powerUps[_random.nextInt(powerUps.length)],
        emoji: '✨',
      );
    } else if (rand < 0.82) {
      // %10 - Profil yıldızı
      return RewardItem(
        type: RewardType.stars,
        amount: 1 + _random.nextInt(2),
        emoji: '⭐',
      );
    } else if (rand < 0.86) {
      // %4 - Elmas (en fazla 2)
      return RewardItem(
        type: RewardType.diamonds,
        amount: 1 + _random.nextInt(2),
        emoji: '💎',
      );
    } else {
      // %14 - Altın (5–15)
      return RewardItem(
        type: RewardType.coins,
        amount: 5 + _random.nextInt(11),
        emoji: '💰',
      );
    }
  }

  // ==================== GÖREV İLERLEMESİ ====================

  Future<void> updateTaskProgress(TaskType type, int value) async {
    if (_userId == null || _isGuest) return;

    bool anyUpdated = false;

    for (final task in dailyTasks) {
      if (task.type == type) {
        final progress = _taskProgress[task.id];
        if (progress != null && !progress.isCompleted) {
          final newValue = progress.currentValue + value;
          final isCompleted = newValue >= task.targetValue;

          _taskProgress[task.id] = progress.copyWith(
            currentValue: newValue,
            isCompleted: isCompleted,
            completedAt: isCompleted ? DateTime.now() : null,
          );
          anyUpdated = true;
        }
      }
    }

    if (anyUpdated) {
      await _saveTaskProgress();
      notifyListeners();
    }
  }

  Future<List<RewardItem>> claimTaskReward(String taskId) async {
    if (_userId == null || _isGuest) return [];

    final progress = _taskProgress[taskId];
    if (progress == null || !progress.isCompleted || progress.isRewardClaimed) {
      return [];
    }

    final task = dailyTasks.firstWhere((t) => t.id == taskId);
    
    // Ödülleri uygula
    await _applyRewards(task.rewards);

    // Görevi güncelle
    _taskProgress[taskId] = progress.copyWith(isRewardClaimed: true);

    await _saveTaskProgress();
    notifyListeners();

    return task.rewards;
  }

  int getCompletedTasksCount() {
    return _taskProgress.values.where((p) => p.isCompleted).length;
  }

  int getClaimedTasksCount() {
    return _taskProgress.values.where((p) => p.isRewardClaimed).length;
  }

  // ==================== ÖDÜL UYGULAMA ====================

  Future<void> _applyRewards(List<RewardItem> rewards) async {
    if (_userRewards == null) return;

    int coinsToAdd = 0;
    int diamondsToAdd = 0;
    int halfOptionsToAdd = 0;
    int extraTimeToAdd = 0;
    int doublePointsToAdd = 0;
    int skipQuestionToAdd = 0;
    int freezeTimeToAdd = 0;
    int starsToAdd = 0;

    for (final reward in rewards) {
      switch (reward.type) {
        case RewardType.coins:
          coinsToAdd += reward.amount;
          break;
        case RewardType.stars:
          starsToAdd += reward.amount;
          break;
        case RewardType.diamonds:
          diamondsToAdd += reward.amount;
          break;
        case RewardType.hint:
          coinsToAdd += reward.amount * 20;
          break;
        case RewardType.powerUp:
          switch (reward.powerUpType) {
            case PowerUpType.halfOptions:
              halfOptionsToAdd += reward.amount;
              break;
            case PowerUpType.extraTime:
              extraTimeToAdd += reward.amount;
              break;
            case PowerUpType.doublePoints:
              doublePointsToAdd += reward.amount;
              break;
            case PowerUpType.skipQuestion:
              skipQuestionToAdd += reward.amount;
              break;
            case PowerUpType.freezeTime:
              freezeTimeToAdd += reward.amount;
              break;
            default:
              break;
          }
          break;
        default:
          break;
      }
    }

    _userRewards = _userRewards!.copyWith(
      coins: _userRewards!.coins + coinsToAdd,
      diamonds: _userRewards!.diamonds + diamondsToAdd,
      profileBonusStars: _userRewards!.profileBonusStars + starsToAdd,
      halfOptionsCount: _userRewards!.halfOptionsCount + halfOptionsToAdd,
      extraTimeCount: _userRewards!.extraTimeCount + extraTimeToAdd,
      doublePointsCount: _userRewards!.doublePointsCount + doublePointsToAdd,
      skipQuestionCount: _userRewards!.skipQuestionCount + skipQuestionToAdd,
      freezeTimeCount: _userRewards!.freezeTimeCount + freezeTimeToAdd,
    );
  }

  /// Ana ekran şans çarkından gelen yıldızlar (Firestore `rewards/daily` ile senkron)
  Future<void> addProfileBonusStars(int amount) async {
    if (_userId == null || _isGuest || _userRewards == null || amount <= 0) return;
    _userRewards = _userRewards!.copyWith(
      profileBonusStars: _userRewards!.profileBonusStars + amount,
    );
    await _saveUserRewards();
    notifyListeners();
  }

  // ==================== KAYDETME ====================

  Future<void> _saveUserRewards() async {
    if (_userId == null || _userRewards == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('rewards')
          .doc('daily')
          .set(_userRewards!.toMap());

      if (!_isGuest && _userId != null && _userId!.isNotEmpty) {
        await publishWorldLeaderboardScores(
          firestore: _firestore,
          userId: _userId!,
          coins: _userRewards!.coins,
          diamonds: _userRewards!.diamonds,
          displayName: _leaderboardDisplayName,
          profileEmoji: _leaderboardProfileEmoji,
        );
      }
    } catch (e) {
      debugPrint('Save user rewards error: $e');
    }
  }

  Future<void> _saveTaskProgress() async {
    if (_userId == null) return;

    try {
      final today = _getTodayString();
      final data = <String, dynamic>{};
      
      _taskProgress.forEach((key, value) {
        data[key] = value.toMap();
      });

      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('rewards')
          .doc('tasks_$today')
          .set(data);
    } catch (e) {
      debugPrint('Save task progress error: $e');
    }
  }

  // ==================== YARDIMCI ====================

  String _getTodayString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  Future<void> refresh() async {
    if (_isGuest) return;
    await _loadUserRewards();
    await _loadTaskProgress();
  }
}

