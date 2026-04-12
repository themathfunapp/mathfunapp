import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import '../models/mini_game.dart';
import 'game_mechanics_service.dart';

class MiniGameService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  MiniGameProgress? _progress;
  bool _isLoading = false;
  GameMechanicsService? _mechanicsWallet;

  /// Ana cüzdan (`GameMechanicsService`) ile jeton senkronu — [main] içinde bağlanır.
  void attachMechanicsWallet(GameMechanicsService mechanics) {
    _mechanicsWallet = mechanics;
  }
  
  MiniGameProgress? get progress => _progress;
  bool get isLoading => _isLoading;
  
  /// Tüm mini oyunlar
  List<MiniGame> get allGames => _allMiniGames;
  
  /// Kategoriye göre oyunları getir
  List<MiniGame> getGamesByCategory(GameCategory category) {
    return _allMiniGames.where((g) => g.category == category).toList();
  }
  
  /// Yaşa göre oyunları getir
  List<MiniGame> getGamesByAge(int age) {
    return _allMiniGames.where((g) => g.minAge <= age && g.maxAge >= age).toList();
  }

  /// Kullanıcı ilerlemesini yükle
  Future<void> loadProgress(String oderId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final doc = await _firestore.collection('mini_game_progress').doc(oderId).get();
      
      if (doc.exists) {
        _progress = MiniGameProgress.fromMap(doc.data()!);
      } else {
        _progress = MiniGameProgress(
          oderId: oderId,
          unlockedGames: _allMiniGames.where((g) => g.requiredStars == 0).map((g) => g.id).toList(),
        );
        await saveProgress();
      }
    } catch (e) {
      debugPrint('Error loading mini game progress: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  /// İlerlemeyi kaydet
  Future<void> saveProgress() async {
    if (_progress == null) return;

    try {
      await _firestore
          .collection('mini_game_progress')
          .doc(_progress!.oderId)
          .set(_progress!.toMap());
    } catch (e) {
      debugPrint('Error saving mini game progress: $e');
    }
  }

  /// Oyun sonucunu kaydet
  Future<void> saveGameResult(MiniGameResult result) async {
    if (_progress == null) return;

    // Mevcut istatistikleri al
    final existingStats = _progress!.gameStats[result.gameId];
    
    final newStats = GameStats(
      gameId: result.gameId,
      timesPlayed: (existingStats?.timesPlayed ?? 0) + 1,
      bestScore: max(existingStats?.bestScore ?? 0, result.score),
      totalStars: (existingStats?.totalStars ?? 0) + result.stars,
      bestStreak: max(existingStats?.bestStreak ?? 0, result.correctAnswers),
      lastPlayedAt: DateTime.now(),
    );

    // Güncel istatistikler
    final updatedGameStats = Map<String, GameStats>.from(_progress!.gameStats);
    updatedGameStats[result.gameId] = newStats;

    // Toplam yıldız hesapla
    int totalStars = 0;
    for (var stats in updatedGameStats.values) {
      totalStars += stats.totalStars;
    }

    // Yeni açılacak oyunları kontrol et
    List<String> unlockedGames = List.from(_progress!.unlockedGames);
    for (var game in _allMiniGames) {
      if (!unlockedGames.contains(game.id) && game.requiredStars <= totalStars) {
        unlockedGames.add(game.id);
      }
    }

    _progress = MiniGameProgress(
      oderId: _progress!.oderId,
      gameStats: updatedGameStats,
      totalStars: totalStars,
      totalCoins: _progress!.totalCoins + result.coinsEarned,
      unlockedGames: unlockedGames,
      earnedBadges: _progress!.earnedBadges,
    );

    await saveProgress();
    if (result.coinsEarned > 0) {
      _mechanicsWallet?.addCoins(result.coinsEarned);
    }
    notifyListeners();
  }

  /// Balon oyunu için balonlar oluştur
  List<Balloon> generateBalloons(int count, int maxNumber) {
    final random = Random();
    final colors = ['#FF6B6B', '#4ECDC4', '#45B7D1', '#96CEB4', '#FFEAA7', '#DDA0DD', '#74B9FF'];
    
    return List.generate(count, (index) {
      return Balloon(
        id: index,
        number: random.nextInt(maxNumber) + 1,
        color: colors[random.nextInt(colors.length)],
        x: random.nextDouble() * 0.8 + 0.1,
        y: 1.0 + random.nextDouble() * 0.5,
        speed: 0.5 + random.nextDouble() * 0.5,
      );
    });
  }

  /// Meyve toplama için meyveler oluştur
  List<Fruit> generateFruits(int count) {
    final random = Random();
    final fruitTypes = [
      {'emoji': '🍎', 'name': 'apple'},
      {'emoji': '🍊', 'name': 'orange'},
      {'emoji': '🍋', 'name': 'lemon'},
      {'emoji': '🍇', 'name': 'grape'},
      {'emoji': '🍓', 'name': 'strawberry'},
      {'emoji': '🍌', 'name': 'banana'},
      {'emoji': '🍑', 'name': 'peach'},
      {'emoji': '🍒', 'name': 'cherry'},
    ];
    
    return List.generate(count, (index) {
      final fruit = fruitTypes[random.nextInt(fruitTypes.length)];
      return Fruit(
        id: index,
        emoji: fruit['emoji']!,
        name: fruit['name']!,
        x: random.nextDouble() * 0.8 + 0.1,
        y: random.nextDouble() * 0.3 + 0.1,
      );
    });
  }

  /// Saat soruları oluştur
  List<Map<String, dynamic>> generateClockQuestions(int count, GameDifficulty difficulty) {
    final random = Random();
    final questions = <Map<String, dynamic>>[];
    
    final activities = [
      {'key': 'breakfast', 'hour': 8, 'minute': 0, 'emoji': '🍳'},
      {'key': 'school', 'hour': 9, 'minute': 0, 'emoji': '🏫'},
      {'key': 'lunch', 'hour': 12, 'minute': 0, 'emoji': '🍽️'},
      {'key': 'play', 'hour': 15, 'minute': 0, 'emoji': '⚽'},
      {'key': 'dinner', 'hour': 19, 'minute': 0, 'emoji': '🍕'},
      {'key': 'sleep', 'hour': 21, 'minute': 0, 'emoji': '😴'},
    ];

    for (int i = 0; i < count; i++) {
      final activity = activities[random.nextInt(activities.length)];
      int minute = 0;
      
      if (difficulty == GameDifficulty.medium) {
        minute = [0, 30][random.nextInt(2)];
      } else if (difficulty == GameDifficulty.hard) {
        minute = [0, 15, 30, 45][random.nextInt(4)];
      }
      
      questions.add({
        'activity': activity['key'],
        'emoji': activity['emoji'],
        'hour': activity['hour'],
        'minute': minute,
        'displayTime': '${activity['hour'].toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}',
      });
    }
    
    return questions;
  }

  /// Matematik sorusu oluştur
  Map<String, dynamic> generateMathQuestion(GameDifficulty difficulty, {String? operation}) {
    final random = Random();
    int num1, num2, answer;
    String op;
    
    switch (difficulty) {
      case GameDifficulty.easy:
        num1 = random.nextInt(5) + 1;
        num2 = random.nextInt(5) + 1;
        break;
      case GameDifficulty.medium:
        num1 = random.nextInt(10) + 1;
        num2 = random.nextInt(10) + 1;
        break;
      case GameDifficulty.hard:
        num1 = random.nextInt(20) + 1;
        num2 = random.nextInt(20) + 1;
        break;
    }

    if (operation != null) {
      op = operation;
    } else {
      op = random.nextBool() ? '+' : '-';
    }

    if (op == '+') {
      answer = num1 + num2;
    } else {
      if (num1 < num2) {
        final temp = num1;
        num1 = num2;
        num2 = temp;
      }
      answer = num1 - num2;
    }

    // Yanlış cevaplar oluştur
    final wrongAnswers = <int>[];
    while (wrongAnswers.length < 3) {
      final wrong = answer + random.nextInt(11) - 5;
      if (wrong != answer && wrong >= 0 && !wrongAnswers.contains(wrong)) {
        wrongAnswers.add(wrong);
      }
    }

    final options = [answer, ...wrongAnswers]..shuffle();

    return {
      'num1': num1,
      'num2': num2,
      'operation': op,
      'answer': answer,
      'options': options,
      'questionText': '$num1 $op $num2 = ?',
    };
  }

  /// Tren sorusu oluştur
  Map<String, dynamic> generateTrainQuestion(GameDifficulty difficulty) {
    final random = Random();
    int startPassengers, boarding, alighting;
    
    switch (difficulty) {
      case GameDifficulty.easy:
        startPassengers = random.nextInt(5) + 1;
        boarding = random.nextInt(3) + 1;
        alighting = random.nextInt(min(3, startPassengers)) + 1;
        break;
      case GameDifficulty.medium:
        startPassengers = random.nextInt(8) + 3;
        boarding = random.nextInt(5) + 1;
        alighting = random.nextInt(min(5, startPassengers)) + 1;
        break;
      case GameDifficulty.hard:
        startPassengers = random.nextInt(15) + 5;
        boarding = random.nextInt(8) + 1;
        alighting = random.nextInt(min(8, startPassengers)) + 1;
        break;
    }

    final answer = startPassengers + boarding - alighting;
    
    return {
      'startPassengers': startPassengers,
      'boarding': boarding,
      'alighting': alighting,
      'answer': answer,
    };
  }

  /// Yıldız hesapla
  int calculateStars(int correctAnswers, int totalQuestions, Duration timeTaken, GameDifficulty difficulty) {
    final percentage = (correctAnswers / totalQuestions) * 100;
    
    int stars = 0;
    if (percentage >= 100) {
      stars = 3;
    } else if (percentage >= 75) {
      stars = 2;
    } else if (percentage >= 50) {
      stars = 1;
    }
    
    // Bonus for speed
    if (difficulty != GameDifficulty.easy && stars > 0) {
      final avgTimePerQuestion = timeTaken.inSeconds / totalQuestions;
      if (avgTimePerQuestion < 5) {
        stars = min(3, stars + 1);
      }
    }
    
    return stars;
  }

  /// Kategori bilgilerini getir
  Map<String, dynamic> getCategoryInfo(GameCategory category) {
    switch (category) {
      case GameCategory.counting:
        return {
          'nameKey': 'category_counting',
          'emoji': '🔢',
          'color': const Color(0xFF4ECDC4),
        };
      case GameCategory.shapes:
        return {
          'nameKey': 'category_shapes',
          'emoji': '🔷',
          'color': const Color(0xFF45B7D1),
        };
      case GameCategory.operations:
        return {
          'nameKey': 'category_operations',
          'emoji': '➕',
          'color': const Color(0xFFFF6B6B),
        };
      case GameCategory.time:
        return {
          'nameKey': 'category_time',
          'emoji': '⏰',
          'color': const Color(0xFFFECA57),
        };
      case GameCategory.creative:
        return {
          'nameKey': 'category_creative',
          'emoji': '🎨',
          'color': const Color(0xFFDDA0DD),
        };
      case GameCategory.special:
        return {
          'nameKey': 'category_special',
          'emoji': '⭐',
          'color': const Color(0xFF96CEB4),
        };
    }
  }
}

/// Tüm mini oyunlar listesi
const List<MiniGame> _allMiniGames = [
  // Sayı Oyunları
  MiniGame(
    id: 'balloon_pop',
    nameKey: 'game_balloon_pop',
    descriptionKey: 'game_balloon_pop_desc',
    iconEmoji: '🎈',
    category: GameCategory.counting,
    minAge: 3,
    maxAge: 5,
    colors: ['#FF6B6B', '#FF8E8E'],
    theme: GameTheme.fairytale,
  ),
  MiniGame(
    id: 'fruit_collect',
    nameKey: 'game_fruit_collect',
    descriptionKey: 'game_fruit_collect_desc',
    iconEmoji: '🍎',
    category: GameCategory.counting,
    minAge: 4,
    maxAge: 6,
    colors: ['#96CEB4', '#88D8B0'],
    theme: GameTheme.forest,
  ),
  MiniGame(
    id: 'block_sort',
    nameKey: 'game_block_sort',
    descriptionKey: 'game_block_sort_desc',
    iconEmoji: '🧱',
    category: GameCategory.counting,
    minAge: 3,
    maxAge: 6,
    colors: ['#FFEAA7', '#FDCB6E'],
    theme: GameTheme.city,
  ),

  // Şekil Oyunları
  MiniGame(
    id: 'puzzle_piece',
    nameKey: 'game_puzzle_piece',
    descriptionKey: 'game_puzzle_piece_desc',
    iconEmoji: '🧩',
    category: GameCategory.shapes,
    minAge: 4,
    maxAge: 7,
    colors: ['#45B7D1', '#7ED6E5'],
    theme: GameTheme.fairytale,
  ),
  MiniGame(
    id: 'geo_animals',
    nameKey: 'game_geo_animals',
    descriptionKey: 'game_geo_animals_desc',
    iconEmoji: '🦁',
    category: GameCategory.shapes,
    minAge: 3,
    maxAge: 6,
    colors: ['#DDA0DD', '#E8B4E8'],
    theme: GameTheme.forest,
  ),

  // Toplama-Çıkarma Oyunları
  MiniGame(
    id: 'magic_machine',
    nameKey: 'game_magic_machine',
    descriptionKey: 'game_magic_machine_desc',
    iconEmoji: '🎰',
    category: GameCategory.operations,
    minAge: 5,
    maxAge: 8,
    colors: ['#FF6B6B', '#FF8E8E'],
    requiredStars: 5,
    theme: GameTheme.space,
  ),
  MiniGame(
    id: 'train_journey',
    nameKey: 'game_train_journey',
    descriptionKey: 'game_train_journey_desc',
    iconEmoji: '🚂',
    category: GameCategory.operations,
    minAge: 6,
    maxAge: 9,
    colors: ['#74B9FF', '#A4CAFE'],
    requiredStars: 10,
    theme: GameTheme.city,
  ),

  // Saat Oyunları
  MiniGame(
    id: 'magic_clock',
    nameKey: 'game_magic_clock',
    descriptionKey: 'game_magic_clock_desc',
    iconEmoji: '🕐',
    category: GameCategory.time,
    minAge: 6,
    maxAge: 9,
    colors: ['#FECA57', '#FFE082'],
    requiredStars: 15,
    theme: GameTheme.fairytale,
  ),

  // Yaratıcı Oyunlar
  MiniGame(
    id: 'color_math',
    nameKey: 'game_color_math',
    descriptionKey: 'game_color_math_desc',
    iconEmoji: '🌈',
    category: GameCategory.creative,
    minAge: 5,
    maxAge: 8,
    colors: ['#FF6B6B', '#4ECDC4'],
    requiredStars: 20,
    theme: GameTheme.space,
  ),
  MiniGame(
    id: 'math_orchestra',
    nameKey: 'game_math_orchestra',
    descriptionKey: 'game_math_orchestra_desc',
    iconEmoji: '🎵',
    category: GameCategory.creative,
    minAge: 4,
    maxAge: 7,
    colors: ['#DDA0DD', '#FFB6C1'],
    requiredStars: 25,
    theme: GameTheme.fairytale,
  ),

  // Özel Oyunlar
  MiniGame(
    id: 'math_marathon',
    nameKey: 'game_math_marathon',
    descriptionKey: 'game_math_marathon_desc',
    iconEmoji: '🏃',
    category: GameCategory.special,
    minAge: 6,
    maxAge: 10,
    colors: ['#FF6B6B', '#FF8E8E'],
    requiredStars: 30,
    theme: GameTheme.city,
  ),
  MiniGame(
    id: 'family_math',
    nameKey: 'game_family_math',
    descriptionKey: 'game_family_math_desc',
    iconEmoji: '👨‍👩‍👧‍👦',
    category: GameCategory.special,
    minAge: 3,
    maxAge: 12,
    colors: ['#96CEB4', '#88D8B0'],
    theme: GameTheme.forest,
  ),
];

