import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/game_mechanics.dart';

/// Oyun Mekanikleri Servisi
/// Combo, Can, İpucu, Güç-Up, Günlük Challenge yönetimi
class GameMechanicsService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Sistemler
  late ComboSystem comboSystem;
  late LivesSystem livesSystem;
  late HintSystem hintSystem;
  late PlayerInventory inventory;
  
  // Günlük Challenge
  DailyChallenge? todayChallenge;
  
  // Şans Çarkı
  DateTime? lastSpinTime;
  bool get canSpin {
    if (lastSpinTime == null) return true;
    final now = DateTime.now();
    final lastSpinDate = DateTime(lastSpinTime!.year, lastSpinTime!.month, lastSpinTime!.day);
    final today = DateTime(now.year, now.month, now.day);
    return today.isAfter(lastSpinDate);
  }
  
  // Aktif güç-uplar
  Map<PowerUpType, DateTime> activePowerUps = {};
  
  // Streak
  int dailyStreak = 0;
  DateTime? lastPlayDate;
  
  String? _userId;
  bool _isGuest = false;
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  bool get isGuest => _isGuest;
  static const String _guestMechanicsKey = 'guest_mechanics';

  GameMechanicsService() {
    comboSystem = ComboSystem();
    livesSystem = LivesSystem();
    hintSystem = HintSystem();
    inventory = PlayerInventory();
  }

  /// Kullanıcı için sistemi başlat
  Future<void> initialize(String userId, {bool isGuest = false}) async {
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
      _checkLifeRegeneration();
      _updateDailyStreak();
    } catch (e) {
      debugPrint('GameMechanicsService initialization error: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

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
  Future<void> syncInventoryFromRewards(int coins, int diamonds, int hints) async {
    inventory.coins = coins;
    inventory.gems = diamonds;
    hintSystem.availableHints = hints;
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
        final hints = (d['hintCount'] is int) ? d['hintCount'] as int : 0;
        if (coins > inventory.coins) inventory.coins = coins;
        if (diamonds > inventory.gems) inventory.gems = diamonds;
        if (hints > hintSystem.availableHints) hintSystem.availableHints = hints;
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
            hintSystem.availableHints = data['hints'] ?? 3;
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
          
          hintSystem.availableHints = data['hints'] ?? 3;
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
          'hints': hintSystem.availableHints,
        };
        await prefs.setString(_guestMechanicsKey, jsonEncode(data));
      } else {
        await _firestore.collection('user_mechanics').doc(_userId).set({
          'lives': livesSystem.toJson(),
          'inventory': inventory.toJson(),
          'lastSpinTime': lastSpinTime?.toIso8601String(),
          'dailyStreak': dailyStreak,
          'lastPlayDate': lastPlayDate?.toIso8601String(),
          'hints': hintSystem.availableHints,
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
        'hintCount': hintSystem.availableHints,
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

  /// Can yenilenmesini kontrol et
  void _checkLifeRegeneration() {
    if (livesSystem.isFullLives) return;
    if (livesSystem.lastLifeLostAt == null) return;

    final elapsed = DateTime.now().difference(livesSystem.lastLifeLostAt!);
    final livesToAdd = elapsed.inMinutes ~/ 30; // Her 30 dakikada 1 can

    if (livesToAdd > 0) {
      for (int i = 0; i < livesToAdd && !livesSystem.isFullLives; i++) {
        livesSystem.gainLife();
      }
      _saveUserData();
    }
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

  // ============= İPUCU SİSTEMİ =============
  
  /// İpucu kullan
  bool useHint() {
    if (!hintSystem.hasHints) return false;
    hintSystem.useHint();
    _saveUserData();
    notifyListeners();
    return true;
  }

  /// Soru için ipucu al
  String getHintForQuestion(int num1, int num2, String operator, int answer) {
    return HintSystem.generateHint(num1, num2, operator, answer);
  }

  // ============= ŞANS ÇARKI =============
  
  /// Çarkı döndür
  SpinWheelReward spinWheel() {
    if (!canSpin) {
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

    // Ödülü uygula
    _applyReward(selectedReward);
    
    lastSpinTime = DateTime.now();
    _saveUserData();
    notifyListeners();

    return selectedReward;
  }

  void _applyReward(SpinWheelReward reward) {
    switch (reward.type) {
      case 'coins':
        inventory.coins += reward.value;
        break;
      case 'xp':
        // XP ekle - ayrı serviste işlenebilir
        break;
      case 'hint':
        hintSystem.addHint(reward.value);
        break;
      case 'life':
        for (int i = 0; i < reward.value; i++) {
          livesSystem.gainLife();
        }
        break;
      case 'powerup':
        // Rastgele güç-up ekle
        final powerUps = PowerUpType.values;
        final randomPowerUp = powerUps[Random().nextInt(powerUps.length)];
        inventory.addPowerUp(randomPowerUp);
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
      // Oyuncuya hasar
      livesSystem.loseLife();
      _saveUserData();
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

  /// İpucu satın al
  bool purchaseHints(int count, int cost) {
    if (inventory.coins < cost) return false;
    
    inventory.coins -= cost;
    hintSystem.addHint(count);
    _saveUserData();
    notifyListeners();
    return true;
  }

  /// Can doldur
  bool refillLives(int cost) {
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
    livesSystem.gainLife();
    _saveUserData();
    notifyListeners();
    debugPrint('GameMechanicsService: Reklam ile 1 can kazanıldı!');
  }

  /// Can durumunu kontrol et
  bool get hasLives => livesSystem.hasLives;
  
  /// Mevcut can sayısı
  int get currentLives => livesSystem.currentLives;
  
  /// Maksimum can sayısı
  int get maxLives => livesSystem.maxLives;
  
  /// Canlar dolu mu?
  bool get isFullLives => livesSystem.isFullLives;
}

