import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';

class GameManager extends ChangeNotifier {
  // === AYARLAR ===
  bool _soundEnabled = true;
  bool _musicEnabled = true;
  bool _vibrationEnabled = true;
  bool _notificationsEnabled = true;
  String _difficulty = 'medium'; // easy, medium, hard
  String _selectedLanguage = 'tr';
  String _playerName = 'Matematik Şampiyonu';

  // === OYUN İSTATİSTİKLERİ ===
  int _totalScore = 0;
  int _gamesPlayed = 0;
  int _correctAnswers = 0;
  int _wrongAnswers = 0;
  int _currentStreak = 0;
  int _bestStreak = 0;
  Map<String, int> _categoryScores = {}; // Kategoriye göre skorlar
  Map<String, dynamic> _achievements = {}; // Kazanılan başarımlar

  // === OYUN DURUMU ===
  bool _isGameActive = false;
  int _currentLevel = 1;
  String _currentCategory = 'toplama';
  int _timeRemaining = 60; // saniye
  int _currentQuestionIndex = 0;
  List<Map<String, dynamic>> _questions = [];

  // === ZAMANLAMA ve CAN ===
  int _lives = 3;
  DateTime? _lastPlayDate;
  int _dailyStreak = 0;
  bool _dailyRewardClaimed = false;

  // === FIREBASE ===
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;

  // === LOCAL STORAGE KEYS ===
  static const String _prefSound = 'sound_enabled';
  static const String _prefMusic = 'music_enabled';
  static const String _prefDifficulty = 'difficulty';
  static const String _prefLanguage = 'language';
  static const String _prefPlayerName = 'player_name';
  static const String _prefTotalScore = 'total_score';
  static const String _prefGamesPlayed = 'games_played';
  static const String _prefBestStreak = 'best_streak';

  // === GETTER'lar ===
  bool get soundEnabled => _soundEnabled;
  bool get musicEnabled => _musicEnabled;
  bool get vibrationEnabled => _vibrationEnabled;
  bool get notificationsEnabled => _notificationsEnabled;
  String get difficulty => _difficulty;
  String get selectedLanguage => _selectedLanguage;
  String get playerName => _playerName;
  int get totalScore => _totalScore;
  int get gamesPlayed => _gamesPlayed;
  int get correctAnswers => _correctAnswers;
  int get wrongAnswers => _wrongAnswers;
  int get currentStreak => _currentStreak;
  int get bestStreak => _bestStreak;
  bool get isGameActive => _isGameActive;
  int get currentLevel => _currentLevel;
  String get currentCategory => _currentCategory;
  int get timeRemaining => _timeRemaining;
  int get lives => _lives;
  int get dailyStreak => _dailyStreak;
  bool get dailyRewardClaimed => _dailyRewardClaimed;
  Map<String, int> get categoryScores => Map.from(_categoryScores);
  Map<String, dynamic> get achievements => Map.from(_achievements);

  // === SETTER'lar ===
  set soundEnabled(bool value) {
    _soundEnabled = value;
    _saveToPrefs(_prefSound, value);
    notifyListeners();
  }

  set musicEnabled(bool value) {
    _musicEnabled = value;
    _saveToPrefs(_prefMusic, value);
    notifyListeners();
  }

  set vibrationEnabled(bool value) {
    _vibrationEnabled = value;
    notifyListeners();
  }

  set notificationsEnabled(bool value) {
    _notificationsEnabled = value;
    notifyListeners();
  }

  set difficulty(String value) {
    _difficulty = value;
    _saveToPrefs(_prefDifficulty, value);
    notifyListeners();
  }

  set selectedLanguage(String value) {
    _selectedLanguage = value;
    _saveToPrefs(_prefLanguage, value);
    notifyListeners();
  }

  set playerName(String value) {
    _playerName = value;
    _saveToPrefs(_prefPlayerName, value);
    notifyListeners();
  }

  // === CONSTRUCTOR ===
  GameManager() {
    _loadFromPrefs();
    _checkDailyLogin();
  }

  // === LOCAL STORAGE İŞLEMLERİ ===
  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      _soundEnabled = prefs.getBool(_prefSound) ?? true;
      _musicEnabled = prefs.getBool(_prefMusic) ?? true;
      _difficulty = prefs.getString(_prefDifficulty) ?? 'medium';
      _selectedLanguage = prefs.getString(_prefLanguage) ?? 'tr';
      _playerName = prefs.getString(_prefPlayerName) ?? 'Matematik Şampiyonu';
      _totalScore = prefs.getInt(_prefTotalScore) ?? 0;
      _gamesPlayed = prefs.getInt(_prefGamesPlayed) ?? 0;
      _bestStreak = prefs.getInt(_prefBestStreak) ?? 0;

      // Kategori skorlarını yükle
      final categories = ['toplama', 'cikarma', 'carpma', 'bolme', 'karisik'];
      for (var category in categories) {
        _categoryScores[category] = prefs.getInt('score_$category') ?? 0;
      }

      // Başarımları yükle
      final achievementKeys = prefs.getKeys().where((key) => key.startsWith('ach_'));
      for (var key in achievementKeys) {
        _achievements[key.replaceFirst('ach_', '')] = prefs.getBool(key) ?? false;
      }

      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('GameManager pref yükleme hatası: $e');
      }
    }
  }

  Future<void> _saveToPrefs(String key, dynamic value) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      if (value is bool) {
        await prefs.setBool(key, value);
      } else if (value is int) {
        await prefs.setInt(key, value);
      } else if (value is String) {
        await prefs.setString(key, value);
      } else if (value is double) {
        await prefs.setDouble(key, value);
      }
    } catch (e) {
      if (kDebugMode) {
        print('GameManager pref kaydetme hatası: $e');
      }
    }
  }

  // === OYUN İŞLEMLERİ ===

  // Oyunu başlat
  void startGame({
    required String category,
    int level = 1,
    int timeLimit = 60,
  }) {
    _isGameActive = true;
    _currentCategory = category;
    _currentLevel = level;
    _timeRemaining = timeLimit;
    _currentStreak = 0;
    _lives = 3;
    _currentQuestionIndex = 0;

    // Soruları oluştur (örnek)
    _generateQuestions();

    notifyListeners();
  }

  // Soruları oluştur
  void _generateQuestions() {
    _questions = [];
    int questionCount = 10 + (_currentLevel * 5);

    for (int i = 0; i < questionCount; i++) {
      final question = _createQuestion();
      _questions.add(question);
    }
  }

  // Tek soru oluştur
  Map<String, dynamic> _createQuestion() {
    int num1, num2, answer;
    String operator;
    List<int> options = [];

    switch (_currentCategory) {
      case 'toplama':
        num1 = _getRandomNumber(1, 20 * _currentLevel);
        num2 = _getRandomNumber(1, 20 * _currentLevel);
        answer = num1 + num2;
        operator = '+';
        break;
      case 'cikarma':
        num1 = _getRandomNumber(10, 30 * _currentLevel);
        num2 = _getRandomNumber(1, num1);
        answer = num1 - num2;
        operator = '-';
        break;
      case 'carpma':
        num1 = _getRandomNumber(1, 10 * _currentLevel);
        num2 = _getRandomNumber(1, 10);
        answer = num1 * num2;
        operator = '×';
        break;
      case 'bolme':
        num2 = _getRandomNumber(2, 10);
        answer = _getRandomNumber(2, 10);
        num1 = num2 * answer;
        operator = '÷';
        break;
      default: // karisik
        final operators = ['+', '-', '×', '÷'];
        operator = operators[_getRandomNumber(0, 3)];
        // ... diğer işlemler
        num1 = _getRandomNumber(1, 20);
        num2 = _getRandomNumber(1, 20);
        answer = operator == '+' ? num1 + num2 :
        operator == '-' ? num1 - num2 :
        operator == '×' ? num1 * num2 : num1 ~/ num2;
        break;
    }

    // Şıkları oluştur
    options.add(answer);
    while (options.length < 4) {
      int wrongAnswer;
      do {
        wrongAnswer = answer + _getRandomNumber(-5, 5);
        if (wrongAnswer < 0) wrongAnswer = 0;
      } while (options.contains(wrongAnswer) || wrongAnswer == answer);
      options.add(wrongAnswer);
    }

    options.shuffle();

    return {
      'question': '$num1 $operator $num2 = ?',
      'correctAnswer': answer,
      'options': options,
      'timeLimit': 15, // saniye
    };
  }

  int _getRandomNumber(int min, int max) {
    return min + (DateTime.now().microsecondsSinceEpoch % (max - min + 1));
  }

  // Cevap kontrolü
  bool checkAnswer(int selectedAnswer) {
    if (!_isGameActive || _questions.isEmpty) return false;

    final currentQuestion = _questions[_currentQuestionIndex];
    final isCorrect = selectedAnswer == currentQuestion['correctAnswer'];

    if (isCorrect) {
      _correctAnswers++;
      _currentStreak++;
      _totalScore += 10 * _currentLevel * (_currentStreak ~/ 3 + 1);

      if (_currentStreak > _bestStreak) {
        _bestStreak = _currentStreak;
        _saveToPrefs(_prefBestStreak, _bestStreak);
      }

      // Kategori skorunu güncelle
      _categoryScores[_currentCategory] =
          (_categoryScores[_currentCategory] ?? 0) + 10;
      _saveToPrefs('score_$_currentCategory', _categoryScores[_currentCategory]!);

      // Başarım kontrolü
      _checkAchievements();

    } else {
      _wrongAnswers++;
      _currentStreak = 0;
      _lives--;

      if (_lives <= 0) {
        endGame();
      }
    }

    _currentQuestionIndex++;

    // Tüm sorular bitti mi?
    if (_currentQuestionIndex >= _questions.length) {
      levelUp();
    }

    notifyListeners();
    return isCorrect;
  }

  // Seviye atla
  void levelUp() {
    _currentLevel++;
    _currentQuestionIndex = 0;
    _generateQuestions();

    // Can yenile
    _lives = 3;

    notifyListeners();
  }

  // Oyunu bitir
  void endGame() {
    _isGameActive = false;
    _gamesPlayed++;

    // Skoru kaydet
    _saveToPrefs(_prefTotalScore, _totalScore);
    _saveToPrefs(_prefGamesPlayed, _gamesPlayed);

    // Firestore'a kaydet (kullanıcı giriş yaptıysa)
    _saveToFirestore();

    notifyListeners();
  }

  // === FİREBASE İŞLEMLERİ ===
  Future<void> _saveToFirestore() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final userRef = _firestore.collection('users').doc(user.uid);
      final statsRef = userRef.collection('game_stats').doc('summary');

      final statsData = {
        'totalScore': _totalScore,
        'gamesPlayed': _gamesPlayed,
        'correctAnswers': _correctAnswers,
        'wrongAnswers': _wrongAnswers,
        'bestStreak': _bestStreak,
        'categoryScores': _categoryScores,
        'lastPlayed': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await statsRef.set(statsData, SetOptions(merge: true));

      // Oyun geçmişi kaydı
      final historyRef = userRef.collection('game_history').doc();
      final historyData = {
        'score': _totalScore,
        'level': _currentLevel,
        'category': _currentCategory,
        'correct': _correctAnswers,
        'wrong': _wrongAnswers,
        'duration': 60 - _timeRemaining,
        'playedAt': FieldValue.serverTimestamp(),
      };

      await historyRef.set(historyData);

    } catch (e) {
      if (kDebugMode) {
        print('Firestore kayıt hatası: $e');
      }
    }
  }

  // === BAŞARIM SİSTEMİ ===
  void _checkAchievements() {
    // Örnek başarımlar
    final newAchievements = <String, bool>{};

    if (_totalScore >= 100 && !_achievements.containsKey('score_100')) {
      newAchievements['score_100'] = true;
    }

    if (_bestStreak >= 10 && !_achievements.containsKey('streak_10')) {
      newAchievements['streak_10'] = true;
    }

    if (_gamesPlayed >= 10 && !_achievements.containsKey('games_10')) {
      newAchievements['games_10'] = true;
    }

    // Tüm kategorilerde skor
    final allCategories = ['toplama', 'cikarma', 'carpma', 'bolme'];
    if (allCategories.every((cat) => (_categoryScores[cat] ?? 0) >= 50) &&
        !_achievements.containsKey('master_all')) {
      newAchievements['master_all'] = true;
    }

    // Yeni başarımları kaydet
    if (newAchievements.isNotEmpty) {
      _achievements.addAll(newAchievements);

      // Local storage'a kaydet
      newAchievements.forEach((key, value) async {
        await _saveToPrefs('ach_$key', value);
      });

      notifyListeners();
    }
  }

  // === GÜNLÜK SİSTEM ===
  void _checkDailyLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final lastDateStr = prefs.getString('last_login_date');
    final today = DateTime.now();

    if (lastDateStr != null) {
      final lastDate = DateTime.parse(lastDateStr);
      final difference = today.difference(lastDate).inDays;

      if (difference == 1) {
        // Ardışık giriş
        _dailyStreak = prefs.getInt('daily_streak') ?? 0;
        _dailyStreak++;
        await prefs.setInt('daily_streak', _dailyStreak);
      } else if (difference > 1) {
        // Zincir kırıldı
        _dailyStreak = 1;
        await prefs.setInt('daily_streak', _dailyStreak);
      }
    } else {
      // İlk giriş
      _dailyStreak = 1;
      await prefs.setInt('daily_streak', _dailyStreak);
    }

    // Bugünkü tarihi kaydet
    await prefs.setString('last_login_date', today.toIso8601String());

    // Günlük ödül kontrolü
    _dailyRewardClaimed = prefs.getBool('daily_reward_${today.day}') ?? false;

    notifyListeners();
  }

  Future<void> claimDailyReward() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();

    if (!_dailyRewardClaimed) {
      // Ödül ver (örneğin 100 puan)
      _totalScore += 100 * (_dailyStreak ~/ 7 + 1); // Haftalık bonus
      _dailyRewardClaimed = true;

      await prefs.setBool('daily_reward_${today.day}', true);
      await _saveToPrefs(_prefTotalScore, _totalScore);

      notifyListeners();
    }
  }

  // === DİĞER YARDIMCI METOTLAR ===

  // Skoru sıfırla
  void resetStats() {
    _totalScore = 0;
    _gamesPlayed = 0;
    _correctAnswers = 0;
    _wrongAnswers = 0;
    _currentStreak = 0;
    _bestStreak = 0;
    _categoryScores.clear();
    _achievements.clear();

    // Pref'leri temizle
    _clearPrefs();

    notifyListeners();
  }

  Future<void> _clearPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefTotalScore);
    await prefs.remove(_prefGamesPlayed);
    await prefs.remove(_prefBestStreak);

    // Tüm kategori skorlarını temizle
    final keys = prefs.getKeys().where((key) => key.startsWith('score_'));
    for (var key in keys) {
      await prefs.remove(key);
    }

    // Tüm başarımları temizle
    final achKeys = prefs.getKeys().where((key) => key.startsWith('ach_'));
    for (var key in achKeys) {
      await prefs.remove(key);
    }
  }

  // Zamanlayıcı
  Timer? _gameTimer;

  void startTimer() {
    _gameTimer?.cancel();
    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeRemaining > 0 && _isGameActive) {
        _timeRemaining--;
        notifyListeners();
      } else {
        timer.cancel();
        if (_isGameActive) {
          endGame();
        }
      }
    });
  }

  void stopTimer() {
    _gameTimer?.cancel();
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    super.dispose();
  }

  // === UTILITY ===

  // İlerleme yüzdesi
  double getProgressPercentage(String category) {
    final score = _categoryScores[category] ?? 0;
    return (score / 100).clamp(0.0, 1.0); // Max 100 puan üzerinden
  }

  // Seviye bilgisi
  int getLevelFromScore(int score) {
    return (score / 100).floor() + 1;
  }

  // Kalan can görseli
  List<Widget> getHeartWidgets() {
    return List.generate(_lives, (index) => const Icon(Icons.favorite, color: Colors.red));
  }

  // Zorluk ayarına göre zaman
  int getTimeForDifficulty() {
    switch (_difficulty) {
      case 'easy': return 90;
      case 'medium': return 60;
      case 'hard': return 45;
      default: return 60;
    }
  }
}