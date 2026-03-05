import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/story_mode.dart';

class StoryService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  StoryProgress? _progress;
  List<StoryQuest> _activeQuests = [];
  List<StoryWorld> _worlds = [];
  bool _isLoading = false;

  StoryProgress? get progress => _progress;
  List<StoryQuest> get activeQuests => _activeQuests;
  List<StoryWorld> get worlds => _worlds;
  bool get isLoading => _isLoading;

  /// Tüm dünyaları yükle
  Future<void> loadWorlds(AgeGroup ageGroup) async {
    _worlds = _generateWorlds(ageGroup);
    notifyListeners();
  }

  /// Kullanıcı ilerlemesini yükle
  Future<void> loadProgress(String oderId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final doc = await _firestore.collection('story_progress').doc(oderId).get();
      
      if (doc.exists) {
        _progress = StoryProgress.fromMap(doc.data()!);
      } else {
        // Yeni kullanıcı için varsayılan ilerleme oluştur
        _progress = StoryProgress(
          oderId: oderId,
          selectedAgeGroup: AgeGroup.preschool,
          avatar: PlayerAvatar(oderId: oderId, odername: 'Kahraman'),
        );
        await saveProgress();
      }

      // Aktif görevleri yükle
      await _loadActiveQuests(oderId);
    } catch (e) {
      debugPrint('Error loading story progress: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  /// İlerlemeyi kaydet
  Future<void> saveProgress() async {
    if (_progress == null) return;

    try {
      await _firestore
          .collection('story_progress')
          .doc(_progress!.oderId)
          .set(_progress!.toMap());
    } catch (e) {
      debugPrint('Error saving story progress: $e');
    }
  }

  /// Yaş grubunu seç
  Future<void> selectAgeGroup(AgeGroup ageGroup) async {
    if (_progress == null) return;

    _progress = StoryProgress(
      oderId: _progress!.oderId,
      selectedAgeGroup: ageGroup,
      avatar: _progress!.avatar,
      worldProgress: _progress!.worldProgress,
      completedQuests: _progress!.completedQuests,
      earnedBadges: _progress!.earnedBadges,
      unlockedAvatarItems: _progress!.unlockedAvatarItems,
      totalStars: _progress!.totalStars,
      totalCoins: _progress!.totalCoins,
      totalGems: _progress!.totalGems,
      currentStreak: _progress!.currentStreak,
      lastPlayedAt: _progress!.lastPlayedAt,
    );

    await loadWorlds(ageGroup);
    await saveProgress();
    notifyListeners();
  }

  /// Avatar güncelle
  Future<void> updateAvatar(PlayerAvatar newAvatar) async {
    if (_progress == null) return;

    _progress = StoryProgress(
      oderId: _progress!.oderId,
      selectedAgeGroup: _progress!.selectedAgeGroup,
      avatar: newAvatar,
      worldProgress: _progress!.worldProgress,
      completedQuests: _progress!.completedQuests,
      earnedBadges: _progress!.earnedBadges,
      unlockedAvatarItems: _progress!.unlockedAvatarItems,
      totalStars: _progress!.totalStars,
      totalCoins: _progress!.totalCoins,
      totalGems: _progress!.totalGems,
      currentStreak: _progress!.currentStreak,
      lastPlayedAt: _progress!.lastPlayedAt,
    );

    await saveProgress();
    notifyListeners();
  }

  /// Seviye tamamla
  Future<LevelCompleteResult> completeLevel({
    required String worldId,
    required String chapterId,
    required String levelId,
    required int score,
    required int correctAnswers,
    required int totalQuestions,
  }) async {
    if (_progress == null) {
      return LevelCompleteResult(stars: 0, coinsEarned: 0, expEarned: 0);
    }

    // Yıldız hesapla
    final percentage = (correctAnswers / totalQuestions) * 100;
    int stars = 0;
    if (percentage >= 100) {
      stars = 3;
    } else if (percentage >= 75) {
      stars = 2;
    } else if (percentage >= 50) {
      stars = 1;
    }

    // Ödüller hesapla
    final coinsEarned = stars * 10 + correctAnswers * 2;
    final expEarned = stars * 25 + correctAnswers * 5;

    // Mevcut ilerlemeyi al veya oluştur
    Map<String, WorldProgress> worldProgress = Map.from(_progress!.worldProgress);
    
    if (!worldProgress.containsKey(worldId)) {
      worldProgress[worldId] = WorldProgress(worldId: worldId, isUnlocked: true);
    }

    Map<String, ChapterProgress> chapterProgress = 
        Map.from(worldProgress[worldId]!.chapterProgress);
    
    if (!chapterProgress.containsKey(chapterId)) {
      chapterProgress[chapterId] = ChapterProgress(chapterId: chapterId, isUnlocked: true);
    }

    Map<String, LevelProgress> levelProgress = 
        Map.from(chapterProgress[chapterId]!.levelProgress);

    final existingProgress = levelProgress[levelId];
    final newBestScore = existingProgress == null || score > existingProgress.bestScore
        ? score
        : existingProgress.bestScore;
    final newStars = existingProgress == null || stars > existingProgress.stars
        ? stars
        : existingProgress.stars;

    levelProgress[levelId] = LevelProgress(
      levelId: levelId,
      isCompleted: true,
      stars: newStars,
      bestScore: newBestScore,
      attempts: (existingProgress?.attempts ?? 0) + 1,
      completedAt: DateTime.now(),
    );

    // Bölüm yıldızlarını hesapla
    int chapterStars = 0;
    for (var lp in levelProgress.values) {
      chapterStars += lp.stars;
    }

    chapterProgress[chapterId] = ChapterProgress(
      chapterId: chapterId,
      levelProgress: levelProgress,
      isUnlocked: true,
      totalStars: chapterStars,
    );

    // Dünya yıldızlarını hesapla
    int worldStars = 0;
    for (var cp in chapterProgress.values) {
      worldStars += cp.totalStars;
    }

    worldProgress[worldId] = WorldProgress(
      worldId: worldId,
      chapterProgress: chapterProgress,
      isUnlocked: true,
      totalStars: worldStars,
    );

    // Toplam yıldızları hesapla
    int totalStars = 0;
    for (var wp in worldProgress.values) {
      totalStars += wp.totalStars;
    }

    // İlerlemeyi güncelle
    _progress = StoryProgress(
      oderId: _progress!.oderId,
      selectedAgeGroup: _progress!.selectedAgeGroup,
      avatar: _progress!.avatar.copyWith(
        experience: _progress!.avatar.experience + expEarned,
        level: _calculateLevel(_progress!.avatar.experience + expEarned),
      ),
      worldProgress: worldProgress,
      completedQuests: _progress!.completedQuests,
      earnedBadges: _progress!.earnedBadges,
      unlockedAvatarItems: _progress!.unlockedAvatarItems,
      totalStars: totalStars,
      totalCoins: _progress!.totalCoins + coinsEarned,
      totalGems: _progress!.totalGems,
      currentStreak: _progress!.currentStreak,
      lastPlayedAt: DateTime.now(),
    );

    await saveProgress();
    await _updateQuestProgress('complete_level', 1);
    notifyListeners();

    return LevelCompleteResult(
      stars: stars,
      coinsEarned: coinsEarned,
      expEarned: expEarned,
      isNewBest: score == newBestScore && existingProgress != null,
    );
  }

  /// Seviye hesapla
  int _calculateLevel(int experience) {
    // Her seviye için gereken XP: level * 100
    int level = 1;
    int requiredExp = 100;
    int totalRequired = 0;

    while (experience >= totalRequired + requiredExp) {
      totalRequired += requiredExp;
      level++;
      requiredExp = level * 100;
    }

    return level;
  }

  /// Aktif görevleri yükle
  Future<void> _loadActiveQuests(String oderId) async {
    try {
      final now = DateTime.now();
      
      // Günlük görevler
      _activeQuests = _generateDailyQuests();
      
      // Firestore'dan kullanıcının görev ilerlemesini al
      final questDoc = await _firestore
          .collection('user_quests')
          .doc(oderId)
          .collection('active')
          .get();

      for (var doc in questDoc.docs) {
        final questData = doc.data();
        final questId = doc.id;
        
        // Aktif görevleri güncelle
        final index = _activeQuests.indexWhere((q) => q.id == questId);
        if (index != -1) {
          _activeQuests[index] = StoryQuest.fromMap({
            ...questData,
            'id': questId,
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading quests: $e');
    }
  }

  /// Görev ilerlemesini güncelle
  Future<void> _updateQuestProgress(String questType, int value) async {
    if (_progress == null) return;

    for (int i = 0; i < _activeQuests.length; i++) {
      final quest = _activeQuests[i];
      
      if (quest.nameKey.contains(questType) && !quest.isCompleted) {
        final newValue = quest.currentValue + value;
        final isCompleted = newValue >= quest.targetValue;

        _activeQuests[i] = StoryQuest(
          id: quest.id,
          nameKey: quest.nameKey,
          descriptionKey: quest.descriptionKey,
          type: quest.type,
          targetValue: quest.targetValue,
          currentValue: newValue,
          rewards: quest.rewards,
          expiresAt: quest.expiresAt,
          isCompleted: isCompleted,
        );

        // Görev tamamlandıysa ödülleri ver
        if (isCompleted) {
          await _giveQuestRewards(quest.rewards);
        }

        // Firestore'a kaydet
        await _firestore
            .collection('user_quests')
            .doc(_progress!.oderId)
            .collection('active')
            .doc(quest.id)
            .set(_activeQuests[i].toMap());
      }
    }

    notifyListeners();
  }

  /// Görev ödüllerini ver
  Future<void> _giveQuestRewards(List<QuestReward> rewards) async {
    if (_progress == null) return;

    int coins = _progress!.totalCoins;
    int gems = _progress!.totalGems;

    for (var reward in rewards) {
      switch (reward.type) {
        case RewardType.coins:
          coins += reward.amount;
          break;
        case RewardType.gems:
          gems += reward.amount;
          break;
        case RewardType.experience:
          // Avatar XP'si güncelle
          break;
        default:
          break;
      }
    }

    _progress = StoryProgress(
      oderId: _progress!.oderId,
      selectedAgeGroup: _progress!.selectedAgeGroup,
      avatar: _progress!.avatar,
      worldProgress: _progress!.worldProgress,
      completedQuests: [..._progress!.completedQuests],
      earnedBadges: _progress!.earnedBadges,
      unlockedAvatarItems: _progress!.unlockedAvatarItems,
      totalStars: _progress!.totalStars,
      totalCoins: coins,
      totalGems: gems,
      currentStreak: _progress!.currentStreak,
      lastPlayedAt: _progress!.lastPlayedAt,
    );

    await saveProgress();
  }

  /// Günlük görevler oluştur
  List<StoryQuest> _generateDailyQuests() {
    final now = DateTime.now();
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

    return [
      StoryQuest(
        id: 'daily_complete_3_levels',
        nameKey: 'quest_complete_levels',
        descriptionKey: 'quest_complete_levels_desc',
        type: QuestType.daily,
        targetValue: 3,
        rewards: [
          QuestReward(type: RewardType.coins, amount: 50),
          QuestReward(type: RewardType.experience, amount: 100),
        ],
        expiresAt: endOfDay,
      ),
      StoryQuest(
        id: 'daily_earn_5_stars',
        nameKey: 'quest_earn_stars',
        descriptionKey: 'quest_earn_stars_desc',
        type: QuestType.daily,
        targetValue: 5,
        rewards: [
          QuestReward(type: RewardType.coins, amount: 30),
        ],
        expiresAt: endOfDay,
      ),
      StoryQuest(
        id: 'daily_answer_20_correct',
        nameKey: 'quest_correct_answers',
        descriptionKey: 'quest_correct_answers_desc',
        type: QuestType.daily,
        targetValue: 20,
        rewards: [
          QuestReward(type: RewardType.gems, amount: 5),
        ],
        expiresAt: endOfDay,
      ),
    ];
  }

  /// Dünyaları oluştur
  List<StoryWorld> _generateWorlds(AgeGroup ageGroup) {
    switch (ageGroup) {
      case AgeGroup.preschool:
        return _generatePreschoolWorlds();
      case AgeGroup.earlyElementary:
        return _generateEarlyElementaryWorlds();
      case AgeGroup.lateElementary:
        return _generateLateElementaryWorlds();
    }
  }

  /// 3-5 Yaş Dünyaları
  List<StoryWorld> _generatePreschoolWorlds() {
    return [
      StoryWorld(
        id: 'periler_diyari',
        theme: WorldTheme.numberForest,
        nameKey: 'world_fairy_land',
        descriptionKey: 'world_fairy_land_desc',
        iconEmoji: '🧚',
        colors: ['#E1BEE7', '#9C27B0'],
        topics: [MathTopic.counting, MathTopic.patterns],
        targetAge: AgeGroup.preschool,
        chapters: _generateNumberForestChapters(AgeGroup.preschool),
      ),
      StoryWorld(
        id: 'geometry_castle_preschool',
        theme: WorldTheme.geometryCastle,
        nameKey: 'world_geometry_castle',
        descriptionKey: 'world_geometry_castle_desc',
        iconEmoji: '🏰',
        colors: ['#9C27B0', '#E91E63'],
        topics: [MathTopic.shapes],
        targetAge: AgeGroup.preschool,
        chapters: _generateGeometryCastleChapters(AgeGroup.preschool),
        requiredStars: 15,
      ),
      StoryWorld(
        id: 'measurement_land_preschool',
        theme: WorldTheme.measurementLand,
        nameKey: 'world_measurement_land',
        descriptionKey: 'world_measurement_land_desc',
        iconEmoji: '📏',
        colors: ['#FF9800', '#FFC107'],
        topics: [MathTopic.measurement],
        targetAge: AgeGroup.preschool,
        chapters: [],
        requiredStars: 30,
      ),
    ];
  }

  /// 6-8 Yaş Dünyaları
  List<StoryWorld> _generateEarlyElementaryWorlds() {
    return [
      StoryWorld(
        id: 'number_forest_early',
        theme: WorldTheme.numberForest,
        nameKey: 'world_siber_atolye',
        descriptionKey: 'world_siber_atolye_desc_early',
        iconEmoji: '🤖',
        colors: ['#2C3E50', '#3498DB'],
        topics: [MathTopic.addition, MathTopic.subtraction, MathTopic.multiplication],
        targetAge: AgeGroup.earlyElementary,
        chapters: _generateNumberForestChapters(AgeGroup.earlyElementary),
      ),
      StoryWorld(
        id: 'fraction_bakery',
        theme: WorldTheme.fractionBakery,
        nameKey: 'world_fraction_bakery',
        descriptionKey: 'world_fraction_bakery_desc',
        iconEmoji: '🧁',
        colors: ['#FAD0C4', '#8E44AD'],
        topics: [MathTopic.fractions],
        targetAge: AgeGroup.earlyElementary,
        chapters: [],
        requiredStars: 20,
      ),
      StoryWorld(
        id: 'time_adventure',
        theme: WorldTheme.timeAdventure,
        nameKey: 'world_time_adventure',
        descriptionKey: 'world_time_adventure_desc',
        iconEmoji: '⏰',
        colors: ['#2196F3', '#03A9F4'],
        topics: [MathTopic.time],
        targetAge: AgeGroup.earlyElementary,
        chapters: [],
        requiredStars: 40,
      ),
      StoryWorld(
        id: 'money_market',
        theme: WorldTheme.moneyMarket,
        nameKey: 'world_money_market',
        descriptionKey: 'world_money_market_desc',
        iconEmoji: '💰',
        colors: ['#FFC107', '#FF9800'],
        topics: [MathTopic.money],
        targetAge: AgeGroup.earlyElementary,
        chapters: [],
        requiredStars: 60,
      ),
    ];
  }

  /// 9-11 Yaş Dünyaları
  List<StoryWorld> _generateLateElementaryWorlds() {
    return [
      StoryWorld(
        id: 'geometry_castle_late',
        theme: WorldTheme.geometryCastle,
        nameKey: 'world_geometry_castle',
        descriptionKey: 'world_geometry_castle_desc_late',
        iconEmoji: '🏰',
        colors: ['#9C27B0', '#E91E63'],
        topics: [MathTopic.shapes, MathTopic.angles],
        targetAge: AgeGroup.lateElementary,
        chapters: _generateGeometryCastleChapters(AgeGroup.lateElementary),
      ),
      StoryWorld(
        id: 'fraction_bakery_late',
        theme: WorldTheme.fractionBakery,
        nameKey: 'world_fraction_bakery',
        descriptionKey: 'world_fraction_bakery_desc_late',
        iconEmoji: '🧁',
        colors: ['#FAD0C4', '#8E44AD'],
        topics: [MathTopic.fractions, MathTopic.decimals],
        targetAge: AgeGroup.lateElementary,
        chapters: [],
        requiredStars: 25,
      ),
      StoryWorld(
        id: 'algebra_realm',
        theme: WorldTheme.numberForest,
        nameKey: 'world_algebra_realm',
        descriptionKey: 'world_algebra_realm_desc',
        iconEmoji: '🔮',
        colors: ['#673AB7', '#3F51B5'],
        topics: [MathTopic.algebra, MathTopic.patterns],
        targetAge: AgeGroup.lateElementary,
        chapters: [],
        requiredStars: 50,
      ),
    ];
  }

  /// Sayı Ormanı Bölümleri
  List<StoryChapter> _generateNumberForestChapters(AgeGroup age) {
    if (age == AgeGroup.preschool) {
      return [
        StoryChapter(
          id: 'nf_chapter_1',
          worldId: 'number_forest_preschool',
          orderIndex: 0,
          nameKey: 'chapter_lost_animals',
          descriptionKey: 'chapter_lost_animals_desc',
          storyIntroKey: 'story_intro_lost_animals',
          helper: HelperCharacter.calculationSquirrel,
          levels: _generateCountingLevels('nf_chapter_1', 1, 5),
        ),
        StoryChapter(
          id: 'nf_chapter_2',
          worldId: 'number_forest_preschool',
          orderIndex: 1,
          nameKey: 'chapter_number_eggs',
          descriptionKey: 'chapter_number_eggs_desc',
          storyIntroKey: 'story_intro_number_eggs',
          helper: HelperCharacter.calculationSquirrel,
          levels: _generateCountingLevels('nf_chapter_2', 6, 10),
          requiredStars: 9,
        ),
      ];
    }
    
    return [
      StoryChapter(
        id: 'nf_early_chapter_1',
        worldId: 'number_forest_early',
        orderIndex: 0,
        nameKey: 'chapter_cave_adventure',
        descriptionKey: 'chapter_cave_adventure_desc',
        storyIntroKey: 'story_intro_cave_adventure',
        helper: HelperCharacter.calculationSquirrel,
        levels: _generateAdditionLevels('nf_early_chapter_1'),
      ),
    ];
  }

  /// Geometri Şatosu Bölümleri
  List<StoryChapter> _generateGeometryCastleChapters(AgeGroup age) {
    return [
      StoryChapter(
        id: 'gc_chapter_1',
        worldId: age == AgeGroup.preschool ? 'geometry_castle_preschool' : 'geometry_castle_late',
        orderIndex: 0,
        nameKey: 'chapter_secret_doors',
        descriptionKey: 'chapter_secret_doors_desc',
        storyIntroKey: 'story_intro_secret_doors',
        helper: HelperCharacter.shapeOwl,
        levels: _generateShapeLevels('gc_chapter_1', age),
      ),
    ];
  }

  /// Sayma seviyeleri oluştur
  List<StoryLevel> _generateCountingLevels(String chapterId, int start, int end) {
    List<StoryLevel> levels = [];
    
    for (int i = start; i <= end; i++) {
      levels.add(StoryLevel(
        id: '${chapterId}_level_$i',
        chapterId: chapterId,
        orderIndex: i - start,
        nameKey: 'level_count_to_$i',
        type: i == end ? LevelType.challenge : LevelType.practice,
        topic: MathTopic.counting,
        difficulty: 1,
        questions: _generateCountingQuestions(i),
      ));
    }

    return levels;
  }

  /// Toplama seviyeleri
  List<StoryLevel> _generateAdditionLevels(String chapterId) {
    return [
      StoryLevel(
        id: '${chapterId}_level_1',
        chapterId: chapterId,
        orderIndex: 0,
        nameKey: 'level_simple_addition',
        type: LevelType.discovery,
        topic: MathTopic.addition,
        difficulty: 1,
        questions: _generateSimpleAdditionQuestions(),
      ),
      StoryLevel(
        id: '${chapterId}_level_2',
        chapterId: chapterId,
        orderIndex: 1,
        nameKey: 'level_addition_practice',
        type: LevelType.practice,
        topic: MathTopic.addition,
        difficulty: 2,
        questions: _generateSimpleAdditionQuestions(),
      ),
    ];
  }

  /// Şekil seviyeleri
  List<StoryLevel> _generateShapeLevels(String chapterId, AgeGroup age) {
    return [
      StoryLevel(
        id: '${chapterId}_level_1',
        chapterId: chapterId,
        orderIndex: 0,
        nameKey: 'level_basic_shapes',
        type: LevelType.discovery,
        topic: MathTopic.shapes,
        difficulty: 1,
        questions: _generateShapeQuestions(),
      ),
    ];
  }

  /// Sayma soruları oluştur
  List<MathQuestion> _generateCountingQuestions(int maxNumber) {
    List<MathQuestion> questions = [];
    
    // Emoji listesi - sayılacak nesneler
    final objects = ['🍎', '🌟', '🐱', '🦋', '🌸', '🍊', '🐶', '🌈', '🎈', '🐠'];
    
    for (int i = 1; i <= 5; i++) {
      final count = (i * maxNumber ~/ 5).clamp(1, maxNumber);
      final objectEmoji = objects[i % objects.length];
      
      // Nesne emojilerini tekrarla
      final objectsString = List.generate(count, (_) => objectEmoji).join(' ');
      
      // Yanlış cevaplar oluştur
      List<String> options = [count.toString()];
      
      // 3 yanlış cevap ekle
      for (int j = 1; j <= 3; j++) {
        int wrongAnswer;
        if (j == 1) {
          wrongAnswer = (count + 1).clamp(1, 10);
        } else if (j == 2) {
          wrongAnswer = (count - 1).clamp(1, 10);
        } else {
          wrongAnswer = (count + 2).clamp(1, 10);
        }
        
        // Tekrar etmiyorsa ekle
        if (!options.contains(wrongAnswer.toString())) {
          options.add(wrongAnswer.toString());
        } else {
          // Farklı bir sayı bul
          for (int k = 1; k <= 10; k++) {
            if (!options.contains(k.toString())) {
              options.add(k.toString());
              break;
            }
          }
        }
      }
      
      // Seçenekleri karıştır
      options.shuffle();
      
      questions.add(MathQuestion(
        id: 'counting_q_$i',
        questionKey: '$objectsString\n\nKaç tane $objectEmoji var?',
        topic: MathTopic.counting,
        type: QuestionType.multipleChoice,
        options: options,
        correctAnswer: count.toString(),
        points: 10,
        difficulty: 1,
      ));
    }

    return questions;
  }

  /// Basit toplama soruları
  List<MathQuestion> _generateSimpleAdditionQuestions() {
    return [
      MathQuestion(
        id: 'add_1',
        questionKey: '2 + 3 = ?',
        topic: MathTopic.addition,
        type: QuestionType.multipleChoice,
        options: ['4', '5', '6', '7'],
        correctAnswer: '5',
        points: 10,
      ),
      MathQuestion(
        id: 'add_2',
        questionKey: '4 + 2 = ?',
        topic: MathTopic.addition,
        type: QuestionType.multipleChoice,
        options: ['5', '6', '7', '8'],
        correctAnswer: '6',
        points: 10,
      ),
      MathQuestion(
        id: 'add_3',
        questionKey: '1 + 5 = ?',
        topic: MathTopic.addition,
        type: QuestionType.multipleChoice,
        options: ['4', '5', '6', '7'],
        correctAnswer: '6',
        points: 10,
      ),
    ];
  }

  /// Şekil soruları
  List<MathQuestion> _generateShapeQuestions() {
    return [
      MathQuestion(
        id: 'shape_1',
        questionKey: 'question_find_circle',
        topic: MathTopic.shapes,
        type: QuestionType.multipleChoice,
        options: ['⭕', '⬜', '🔺', '⬛'],
        correctAnswer: '⭕',
        points: 10,
      ),
      MathQuestion(
        id: 'shape_2',
        questionKey: 'question_find_square',
        topic: MathTopic.shapes,
        type: QuestionType.multipleChoice,
        options: ['⭕', '⬜', '🔺', '⭐'],
        correctAnswer: '⬜',
        points: 10,
      ),
    ];
  }

  /// Yardımcı karakter bilgisi
  Map<String, dynamic> getHelperInfo(HelperCharacter helper) {
    switch (helper) {
      case HelperCharacter.calculationSquirrel:
        return {
          'nameKey': 'helper_squirrel_name',
          'emoji': '🐿️',
          'color': Colors.orange,
          'specialty': 'fast_calculation',
        };
      case HelperCharacter.shapeOwl:
        return {
          'nameKey': 'helper_owl_name',
          'emoji': '🦉',
          'color': Colors.purple,
          'specialty': 'geometry',
        };
      case HelperCharacter.logicFox:
        return {
          'nameKey': 'helper_fox_name',
          'emoji': '🦊',
          'color': Colors.deepOrange,
          'specialty': 'problem_solving',
        };
      case HelperCharacter.timeTurtle:
        return {
          'nameKey': 'helper_turtle_name',
          'emoji': '🐢',
          'color': Colors.teal,
          'specialty': 'time',
        };
      case HelperCharacter.fractionFrog:
        return {
          'nameKey': 'helper_frog_name',
          'emoji': '🐸',
          'color': Colors.green,
          'specialty': 'fractions',
        };
    }
  }
}

/// Seviye tamamlama sonucu
class LevelCompleteResult {
  final int stars;
  final int coinsEarned;
  final int expEarned;
  final bool isNewBest;

  LevelCompleteResult({
    required this.stars,
    required this.coinsEarned,
    required this.expEarned,
    this.isNewBest = false,
  });
}

