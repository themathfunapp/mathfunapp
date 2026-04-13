import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/game_mechanics.dart';
import '../models/daily_reward.dart' show UserRewards;

/// Oyun Mekanikleri Servisi
/// Combo, Can, İpucu, Güç-Up, Günlük Challenge yönetimi
class GameMechanicsService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Sistemler
  late ComboSystem comboSystem;
  late LivesSystem livesSystem;
  late PlayerInventory inventory;
  
  // Günlük Challenge
  DailyChallenge? todayChallenge;
  
  // Şans Çarkı
  DateTime? lastSpinTime;
  /// Şimşek diliminden kalan ekstra çevirme (aynı gün içinde).
  int bonusWheelSpins = 0;
  int _pendingSpinRewardMultiplier = 1;

  bool _isNewCalendarDaySinceLastSpin() {
    if (lastSpinTime == null) return true;
    final now = DateTime.now();
    final last = DateTime(lastSpinTime!.year, lastSpinTime!.month, lastSpinTime!.day);
    final today = DateTime(now.year, now.month, now.day);
    return today.isAfter(last);
  }

  /// Günlük ücretsiz çevirme hakkı var mı (takvim günü).
  bool get hasDailySpinAvailable => _isNewCalendarDaySinceLastSpin();

  bool get canSpin => bonusWheelSpins > 0 || hasDailySpinAvailable;

  /// Günlük hak bitti; yalnızca şimşekten gelen ekstra çevirme kaldı.
  bool get hasOnlyBonusSpin => canSpin && !hasDailySpinAvailable;
  
  // Aktif güç-uplar
  Map<PowerUpType, DateTime> activePowerUps = {};
  
  // Streak
  int dailyStreak = 0;
  DateTime? lastPlayDate;
  
  String? _userId;
  bool _isGuest = false;
  bool _isLoading = false;
  /// Premium: can düşmez, her zaman oynanabilir (reklam / can zamanlayıcısı yok).
  bool _premiumUnlimited = false;
  bool get isLoading => _isLoading;
  bool get isGuest => _isGuest;
  bool get premiumUnlimited => _premiumUnlimited;

  /// [initialize] yalnızca kullanıcı / misafir değişince çağrılmalı (Premium güncellemesi tam yenileme yapmaz).
  bool shouldReloadForUser(String userId, bool isGuest) =>
      _userId != userId || _isGuest != isGuest;

  static const String _guestMechanicsKey = 'guest_mechanics';

  /// Duolingo tarzı can dolumunu periyodik kontrol eder.
  Timer? _lifeRegenTimer;

  void setPremiumUnlimited(bool value) {
    if (_premiumUnlimited == value) return;
    _premiumUnlimited = value;
    if (_premiumUnlimited) {
      _lifeRegenTimer?.cancel();
      _lifeRegenTimer = null;
    } else {
      tickLifeRegeneration();
      if (_userId != null) {
        _startLifeRegenTimer();
      }
    }
    notifyListeners();
  }

  GameMechanicsService() {
    comboSystem = ComboSystem();
    livesSystem = LivesSystem();
    inventory = PlayerInventory();
  }

  /// Kullanıcı için sistemi başlat
  Future<void> initialize(String userId, {bool isGuest = false}) async {
    _lifeRegenTimer?.cancel();
    _lifeRegenTimer = null;

    _userId = userId;
    _isGuest = isGuest;
    _isLoading = true;
    notifyListeners();

    try {
      if (_isGuest) {
        await _clearGuestData();
      }
      await _loadUserData();
      if (!_isGuest) {
        await _loadCurrencyFromRewards();
      }
      await _loadTodayChallenge();
      tickLifeRegeneration();
      _updateDailyStreak();
      _startLifeRegenTimer();
    } catch (e) {
      debugPrint('GameMechanicsService initialization error: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  void _startLifeRegenTimer() {
    _lifeRegenTimer?.cancel();
    _lifeRegenTimer = null;
    if (_premiumUnlimited) return;
    _lifeRegenTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      tickLifeRegeneration();
    });
  }

  /// Uygulama ön plana gelince veya diyalog içi sayaçta çağrılabilir.
  /// Yeni can verildiyse true (kayıt çağıran tarafında da yapılabilir).
  bool tickLifeRegeneration() {
    if (_premiumUnlimited) return false;
    final changed = livesSystem.applyRegeneration(DateTime.now());
    if (changed) {
      // ignore: discarded_futures
      _saveUserData();
      notifyListeners();
    }
    return changed;
  }

  /// Bir sonraki otomatik cana kalan süre (doluysa null). Premium'da null.
  Duration? get timeUntilNextLife =>
      _premiumUnlimited ? null : livesSystem.timeUntilNextLife;

  /// Misafir verilerini temizle (her uygulama açılışında - çıkış sonrası sıfırlama)
  Future<void> _clearGuestData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_guestMechanicsKey);
    } catch (e) {
      debugPrint('Clear guest data error: $e');
    }
  }

  /// DailyRewardService'ten alınan ödüller sonrası envanteri senkronize et
  Future<void> syncInventoryFromRewards(int coins, int diamonds) async {
    inventory.coins = coins;
    inventory.gems = diamonds;
    await _saveUserData();
    notifyListeners();
  }

  /// Günlük ödüller (`users/.../rewards/daily`) ile oyun envanterini tam eşitle:
  /// jeton, elmas, ipucu + günlük sayaçlardaki güçlendiriciler.
  Future<void> syncInventoryFromDailyRewards(UserRewards rewards) async {
    inventory.coins = rewards.coins;
    inventory.gems = rewards.diamonds;

    // daily_reward.PowerUpType -> game_mechanics.PowerUpType
    int mergePowerUp(PowerUpType t, int fromDaily) =>
        max(inventory.getPowerUpCount(t), fromDaily);

    inventory.powerUps[PowerUpType.fiftyFifty] =
        mergePowerUp(PowerUpType.fiftyFifty, rewards.halfOptionsCount);
    inventory.powerUps[PowerUpType.slowMotion] =
        mergePowerUp(PowerUpType.slowMotion, rewards.extraTimeCount);
    inventory.powerUps[PowerUpType.doublePoints] =
        mergePowerUp(PowerUpType.doublePoints, rewards.doublePointsCount);
    inventory.powerUps[PowerUpType.skipQuestion] =
        mergePowerUp(PowerUpType.skipQuestion, rewards.skipQuestionCount);
    inventory.powerUps[PowerUpType.freezeTime] =
        mergePowerUp(PowerUpType.freezeTime, rewards.freezeTimeCount);

    await _saveUserData();
    notifyListeners();
  }

  /// Kayıtlı kullanıcılar için UserRewards'tan para birimlerini yükle
  Future<void> _loadCurrencyFromRewards() async {
    if (_userId == null || _isGuest) return;
    try {
      final doc = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('rewards')
          .doc('daily')
          .get();
      if (doc.exists && doc.data() != null) {
        final d = doc.data()!;
        final coins = (d['coins'] is int) ? d['coins'] as int : 0;
        final diamonds = (d['diamonds'] is int) ? d['diamonds'] as int : 0;
        if (coins > inventory.coins) inventory.coins = coins;
        if (diamonds > inventory.gems) inventory.gems = diamonds;
      }
    } catch (e) {
      debugPrint('Load currency from rewards error: $e');
    }
  }

  /// Kullanıcı verisini yükle
  Future<void> _loadUserData() async {
    if (_userId == null) return;

    try {
      if (_isGuest) {
        final prefs = await SharedPreferences.getInstance();
        final jsonStr = prefs.getString(_guestMechanicsKey);
        if (jsonStr != null && jsonStr.isNotEmpty) {
          try {
            final data = jsonDecode(jsonStr) as Map<String, dynamic>? ?? {};
            livesSystem = LivesSystem.fromJson(data['lives'] ?? {});
            inventory = PlayerInventory.fromJson(data['inventory'] ?? {});
            if (data['lastSpinTime'] != null) {
              lastSpinTime = DateTime.tryParse(data['lastSpinTime'].toString());
            }
            dailyStreak = data['dailyStreak'] ?? 0;
            if (data['lastPlayDate'] != null) {
              lastPlayDate = DateTime.tryParse(data['lastPlayDate'].toString());
            }
            bonusWheelSpins = (data['bonusWheelSpins'] is int) ? data['bonusWheelSpins'] as int : 0;
            _pendingSpinRewardMultiplier =
                (data['pendingSpinRewardMultiplier'] is int) ? (data['pendingSpinRewardMultiplier'] as int).clamp(1, 10) : 1;
          } catch (_) {}
        }
      } else {
        final doc = await _firestore
            .collection('user_mechanics')
            .doc(_userId)
            .get();

        if (doc.exists && doc.data() != null) {
          final data = doc.data()!;
          
          livesSystem = LivesSystem.fromJson(data['lives'] ?? {});
          inventory = PlayerInventory.fromJson(data['inventory'] ?? {});
          
          if (data['lastSpinTime'] != null) {
            lastSpinTime = DateTime.tryParse(data['lastSpinTime'].toString());
          }
          
          dailyStreak = data['dailyStreak'] ?? 0;
          if (data['lastPlayDate'] != null) {
            lastPlayDate = DateTime.tryParse(data['lastPlayDate'].toString());
          }

          bonusWheelSpins = (data['bonusWheelSpins'] is int) ? data['bonusWheelSpins'] as int : 0;
          _pendingSpinRewardMultiplier =
              (data['pendingSpinRewardMultiplier'] is int) ? (data['pendingSpinRewardMultiplier'] as int).clamp(1, 10) : 1;
        }
      }
    } catch (e) {
      debugPrint('Error loading user mechanics data: $e');
    }
  }

  /// Kullanıcı verisini kaydet
  Future<void> _saveUserData() async {
    if (_userId == null) return;

    try {
      if (_isGuest) {
        final prefs = await SharedPreferences.getInstance();
        final data = {
          'lives': livesSystem.toJson(),
          'inventory': inventory.toJson(),
          'lastSpinTime': lastSpinTime?.toIso8601String(),
          'dailyStreak': dailyStreak,
          'lastPlayDate': lastPlayDate?.toIso8601String(),
          'bonusWheelSpins': bonusWheelSpins,
          'pendingSpinRewardMultiplier': _pendingSpinRewardMultiplier,
        };
        await prefs.setString(_guestMechanicsKey, jsonEncode(data));
      } else {
        await _firestore.collection('user_mechanics').doc(_userId).set({
          'lives': livesSystem.toJson(),
          'inventory': inventory.toJson(),
          'lastSpinTime': lastSpinTime?.toIso8601String(),
          'dailyStreak': dailyStreak,
          'lastPlayDate': lastPlayDate?.toIso8601String(),
          'bonusWheelSpins': bonusWheelSpins,
          'pendingSpinRewardMultiplier': _pendingSpinRewardMultiplier,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        await _syncCurrencyToRewards();
      }
    } catch (e) {
      debugPrint('Error saving user mechanics data: $e');
    }
  }

  /// Para birimlerini users/rewards/daily ile senkronize et
  Future<void> _syncCurrencyToRewards() async {
    if (_userId == null || _isGuest) return;
    try {
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('rewards')
          .doc('daily')
          .set({
        'coins': inventory.coins,
        'diamonds': inventory.gems,
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Sync currency to rewards error: $e');
    }
  }

  /// Günlük challenge yükle
  Future<void> _loadTodayChallenge() async {
    final today = DateTime.now();
    final dateKey = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    try {
      final doc = await _firestore
          .collection('daily_challenges')
          .doc(dateKey)
          .get();

      if (doc.exists) {
        todayChallenge = DailyChallenge.fromJson(doc.data()!);
        // Eski verilerde targetScore yanlış olabilir (2000 vb.) - düzelt
        const int pointsPerCorrect = 10;
        final correctTargetScore = todayChallenge!.targetCorrect * pointsPerCorrect;
        if (todayChallenge!.targetScore != correctTargetScore) {
          todayChallenge = DailyChallenge(
            id: todayChallenge!.id,
            date: todayChallenge!.date,
            title: todayChallenge!.title,
            description: todayChallenge!.description,
            targetScore: correctTargetScore,
            targetCorrect: todayChallenge!.targetCorrect,
            timeLimit: todayChallenge!.timeLimit,
            difficulty: todayChallenge!.difficulty,
            topics: todayChallenge!.topics,
            rewardCoins: todayChallenge!.rewardCoins,
            rewardXp: todayChallenge!.rewardXp,
            isCompleted: todayChallenge!.isCompleted,
            bestScore: todayChallenge!.bestScore,
          );
          await _firestore.collection('daily_challenges').doc(dateKey).set(
            todayChallenge!.toJson(),
            SetOptions(merge: true),
          );
          notifyListeners();
        }
      } else {
        // Günlük challenge oluştur
        todayChallenge = _generateDailyChallenge(today);
        await _firestore.collection('daily_challenges').doc(dateKey).set(
          todayChallenge!.toJson(),
        );
      }

      // Kullanıcının bu challenge'ı tamamlayıp tamamlamadığını kontrol et
      if (_userId != null) {
        final userChallengeDoc = await _firestore
            .collection('user_challenges')
            .doc('${_userId}_$dateKey')
            .get();
        
        if (userChallengeDoc.exists) {
          todayChallenge = DailyChallenge.fromJson({
            ...todayChallenge!.toJson(),
            ...userChallengeDoc.data()!,
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading daily challenge: $e');
      todayChallenge = _generateDailyChallenge(today);
    }
  }

  /// Günlük challenge oluştur
  DailyChallenge _generateDailyChallenge(DateTime date) {
    final random = Random(date.millisecondsSinceEpoch);
    final difficulties = ['easy', 'medium', 'hard'];
    final topics = [
      ['addition'],
      ['subtraction'],
      ['addition', 'subtraction'],
      ['multiplication'],
      ['addition', 'subtraction', 'multiplication'],
    ];

    final difficulty = difficulties[random.nextInt(difficulties.length)];
    final selectedTopics = topics[random.nextInt(topics.length)];

    int targetScore, targetCorrect, timeLimit, rewardCoins, rewardXp;
    String title, description;

    // Her doğru cevap 10 puan (daily_challenge_screen ile uyumlu)
    const int pointsPerCorrect = 10;

    switch (difficulty) {
      case 'easy':
        targetCorrect = 10;
        timeLimit = 180;
        rewardCoins = 50;
        rewardXp = 25;
        title = 'Kolay Meydan Okuma';
        description = '10 soruyu 3 dakikada çöz!';
        break;
      case 'medium':
        targetCorrect = 15;
        timeLimit = 240;
        rewardCoins = 100;
        rewardXp = 50;
        title = 'Orta Meydan Okuma';
        description = '15 soruyu 4 dakikada çöz!';
        break;
      case 'hard':
        targetCorrect = 20;
        timeLimit = 300;
        rewardCoins = 200;
        rewardXp = 100;
        title = 'Zor Meydan Okuma';
        description = '20 soruyu 5 dakikada çöz!';
        break;
      default:
        targetCorrect = 10;
        timeLimit = 180;
        rewardCoins = 50;
        rewardXp = 25;
        title = 'Günlük Meydan Okuma';
        description = 'Bugünün görevini tamamla!';
    }
    targetScore = targetCorrect * pointsPerCorrect;

    return DailyChallenge(
      id: '${date.year}${date.month}${date.day}',
      date: date,
      title: title,
      description: description,
      targetScore: targetScore,
      targetCorrect: targetCorrect,
      timeLimit: timeLimit,
      difficulty: difficulty,
      topics: selectedTopics,
      rewardCoins: rewardCoins,
      rewardXp: rewardXp,
    );
  }

  /// Günlük streak güncelle
  void _updateDailyStreak() {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    if (lastPlayDate != null) {
      final lastDate = DateTime(lastPlayDate!.year, lastPlayDate!.month, lastPlayDate!.day);
      final difference = todayDate.difference(lastDate).inDays;

      if (difference == 1) {
        // Arka arkaya gün - streak devam
        dailyStreak++;
      } else if (difference > 1) {
        // Streak kırıldı
        dailyStreak = 1;
      }
      // difference == 0 ise aynı gün, streak değişmez
    } else {
      dailyStreak = 1;
    }

    lastPlayDate = today;
    _saveUserData();
  }

  // ============= COMBO SİSTEMİ =============
  
  /// Doğru cevap verildiğinde
  void onCorrectAnswer() {
    comboSystem.onCorrectAnswer();
    notifyListeners();
  }

  /// Yanlış cevap verildiğinde
  void onWrongAnswer() {
    comboSystem.onWrongAnswer();
    
    // Kalkan aktif mi kontrol et
    if (activePowerUps.containsKey(PowerUpType.shield)) {
      activePowerUps.remove(PowerUpType.shield);
      notifyListeners();
      return; // Can kaybetme
    }

    if (_premiumUnlimited) {
      notifyListeners();
      return;
    }

    livesSystem.loseLife();
    _saveUserData();
    notifyListeners();
  }

  /// Combo ile puan hesapla
  int calculateScoreWithCombo(int baseScore) {
    int score = comboSystem.calculateScore(baseScore);
    
    // 2x puan aktif mi?
    if (activePowerUps.containsKey(PowerUpType.doublePoints)) {
      score *= 2;
    }
    
    return score;
  }

  // ============= GÜÇ-UP SİSTEMİ =============
  
  /// Güç-up kullan
  bool usePowerUp(PowerUpType type) {
    if (_premiumUnlimited && type == PowerUpType.extraLife) {
      return true;
    }
    if (!inventory.usePowerUp(type)) return false;

    switch (type) {
      case PowerUpType.extraLife:
        livesSystem.gainLife();
        break;
      case PowerUpType.showHint:
        // İpucu göster - UI'da işlenecek
        break;
      case PowerUpType.freezeTime:
        activePowerUps[type] = DateTime.now().add(const Duration(seconds: 10));
        break;
      case PowerUpType.doublePoints:
        activePowerUps[type] = DateTime.now().add(const Duration(seconds: 30));
        break;
      case PowerUpType.slowMotion:
        activePowerUps[type] = DateTime.now().add(const Duration(seconds: 15));
        break;
      case PowerUpType.shield:
        activePowerUps[type] = DateTime.now().add(const Duration(minutes: 5));
        break;
      default:
        break;
    }

    _saveUserData();
    notifyListeners();
    return true;
  }

  /// Güç-up aktif mi kontrol et
  bool isPowerUpActive(PowerUpType type) {
    if (!activePowerUps.containsKey(type)) return false;
    return DateTime.now().isBefore(activePowerUps[type]!);
  }

  /// %50-50 için yanlış cevapları elde et
  List<int> getFiftyFiftyWrongAnswers(List<int> options, int correctAnswer) {
    final wrongAnswers = options.where((o) => o != correctAnswer).toList();
    wrongAnswers.shuffle();
    return wrongAnswers.take(2).toList();
  }

  /// Soru için açıklayıcı metin (envanter ipucu yok)
  String getHintForQuestion(int num1, int num2, String operator, int answer) {
    return HintSystem.generateHint(num1, num2, operator, answer);
  }

  // ============= ŞANS ÇARKI =============
  
  /// Çarkı döndür - ödülü uygular ve kalıcı olarak kaydeder
  Future<SpinWheelOutcome> spinWheel() async {
    if (!canSpin) {
      throw Exception('Bugün zaten çarkı döndürdünüz!');
    }

    final appliedMult = _pendingSpinRewardMultiplier.clamp(1, 10);
    _pendingSpinRewardMultiplier = 1;

    if (hasDailySpinAvailable) {
      lastSpinTime = DateTime.now();
    } else if (bonusWheelSpins > 0) {
      bonusWheelSpins--;
    } else {
      throw Exception('Bugün zaten çarkı döndürdünüz!');
    }

    final rewards = SpinWheelReward.defaultRewards;
    final random = Random();
    final roll = random.nextDouble();

    double cumulative = 0;
    SpinWheelReward selectedReward = rewards.first;

    for (final reward in rewards) {
      cumulative += reward.probability;
      if (roll <= cumulative) {
        selectedReward = reward;
        break;
      }
    }

    if (selectedReward.type == 'lightning') {
      bonusWheelSpins++;
      // Önceki şimşekten kalan 2x bu çevirmede tüketilmediyse sonraki ödüle taşınsın
      _pendingSpinRewardMultiplier = max(2, appliedMult);
    } else {
      _applyReward(selectedReward, appliedMult);
    }

    await _saveUserData();
    notifyListeners();

    final int multForUi = selectedReward.type == 'lightning' ? 1 : appliedMult;
    return SpinWheelOutcome(reward: selectedReward, appliedMultiplier: multForUi);
  }

  void _applyReward(SpinWheelReward reward, int multiplier) {
    final m = multiplier.clamp(1, 10);
    switch (reward.type) {
      case 'coins':
        inventory.coins += reward.value * m;
        break;
      case 'xp':
        // XP ekle - ayrı serviste işlenebilir
        break;
      case 'stars':
        // Profil yıldızı DailyRewardService üzerinden (SpinWheelScreen) eklenir
        break;
      case 'life':
        if (!_premiumUnlimited) {
          for (int i = 0; i < reward.value * m; i++) {
            livesSystem.gainLife();
          }
        }
        break;
      case 'powerup':
        final powerUps = PowerUpType.values;
        final rnd = Random();
        for (int i = 0; i < m; i++) {
          inventory.addPowerUp(powerUps[rnd.nextInt(powerUps.length)]);
        }
        break;
      default:
        break;
    }
  }

  // ============= GÜNLÜK CHALLENGE =============
  
  /// Challenge'ı tamamla
  Future<void> completeChallenge(int score, int correctAnswers) async {
    if (todayChallenge == null) return;

    final success = score >= todayChallenge!.targetScore && 
                    correctAnswers >= todayChallenge!.targetCorrect;

    if (success && !todayChallenge!.isCompleted) {
      todayChallenge!.isCompleted = true;
      inventory.coins += todayChallenge!.rewardCoins;
      
      // Kaydet
      if (_userId != null) {
        final today = DateTime.now();
        final dateKey = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
        
        await _firestore.collection('user_challenges').doc('${_userId}_$dateKey').set({
          'isCompleted': true,
          'bestScore': score,
          'completedAt': FieldValue.serverTimestamp(),
        });
      }
      
      _saveUserData();
      notifyListeners();
    }

    if (score > todayChallenge!.bestScore) {
      todayChallenge!.bestScore = score;
    }
  }

  // ============= BOSS SAVAŞI =============
  
  /// Boss'a hasar ver
  int damageBoss(BossBattle boss, bool isCorrect) {
    if (isCorrect) {
      return boss.damagePerCorrect;
    } else {
      if (!_premiumUnlimited) {
        livesSystem.loseLife();
        _saveUserData();
      }
      notifyListeners();
      return -boss.damagePerWrong;
    }
  }

  // ============= MAĞAZA =============
  
  /// Güç-up satın al
  bool purchasePowerUp(PowerUp powerUp) {
    if (inventory.coins < powerUp.cost) return false;
    
    inventory.coins -= powerUp.cost;
    inventory.addPowerUp(powerUp.type);
    _saveUserData();
    notifyListeners();
    return true;
  }

  /// Can doldur
  bool refillLives(int cost) {
    if (_premiumUnlimited) return true;
    if (inventory.coins < cost) return false;

    inventory.coins -= cost;
    livesSystem.refillLives();
    _saveUserData();
    notifyListeners();
    return true;
  }

  // ============= ENVANTER =============
  
  /// Coin ekle
  void addCoins(int amount) {
    inventory.coins += amount;
    _saveUserData();
    notifyListeners();
  }

  /// Gems ekle
  void addGems(int amount) {
    inventory.gems += amount;
    _saveUserData();
    notifyListeners();
  }

  // ============= REKLAM İLE CAN KAZANMA =============
  
  /// Reklam izleyerek 1 can kazan
  void earnLifeFromAd() {
    if (_premiumUnlimited) return;
    livesSystem.gainLife();
    _saveUserData();
    notifyListeners();
    debugPrint('GameMechanicsService: Reklam ile 1 can kazanıldı!');
  }

  /// Can durumunu kontrol et
  bool get hasLives => _premiumUnlimited || livesSystem.hasLives;

  /// Mevcut can sayısı (Premium'da gösterim için hep max)
  int get currentLives =>
      _premiumUnlimited ? livesSystem.maxLives : livesSystem.currentLives;

  /// Maksimum can sayısı
  int get maxLives => livesSystem.maxLives;

  /// Canlar dolu mu? (Premium'da her zaman true sayılır)
  bool get isFullLives => _premiumUnlimited || livesSystem.isFullLives;
}

