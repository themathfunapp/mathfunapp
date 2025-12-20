import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';

/// Offline Mod Servisi
/// İnternet olmadan oyun oynama ve veri senkronizasyonu
class OfflineService extends ChangeNotifier {
  bool _isOnline = true;
  bool _isLoading = false;
  bool _hasPendingSync = false;
  DateTime? _lastSyncTime;
  
  SharedPreferences? _prefs;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  bool get isOnline => _isOnline;
  bool get isLoading => _isLoading;
  bool get hasPendingSync => _hasPendingSync;
  DateTime? get lastSyncTime => _lastSyncTime;

  // Önbellek anahtarları
  static const String _cacheKeyProgress = 'offline_progress';
  static const String _cacheKeyQuestions = 'offline_questions';
  static const String _cacheKeySettings = 'offline_settings';
  static const String _cacheKeyPendingActions = 'offline_pending_actions';
  static const String _cacheKeyLastSync = 'offline_last_sync';

  /// Servisi başlat
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      _prefs = await SharedPreferences.getInstance();
      
      // Bağlantı durumunu dinle
      _connectivitySubscription = Connectivity()
          .onConnectivityChanged
          .listen(_handleConnectivityChange);

      // İlk bağlantı durumunu kontrol et
      final connectivityResult = await Connectivity().checkConnectivity();
      _isOnline = !connectivityResult.contains(ConnectivityResult.none);

      // Son senkronizasyon zamanını yükle
      final lastSyncStr = _prefs?.getString(_cacheKeyLastSync);
      if (lastSyncStr != null) {
        _lastSyncTime = DateTime.parse(lastSyncStr);
      }

      // Bekleyen aksiyonları kontrol et
      _checkPendingActions();

    } catch (e) {
      debugPrint('OfflineService initialization error: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Bağlantı değişikliğini işle
  void _handleConnectivityChange(List<ConnectivityResult> result) {
    final wasOffline = !_isOnline;
    _isOnline = !result.contains(ConnectivityResult.none);

    if (_isOnline && wasOffline) {
      // Tekrar çevrimiçi olduk - senkronize et
      syncPendingData();
    }

    notifyListeners();
  }

  /// Bekleyen aksiyonları kontrol et
  void _checkPendingActions() {
    final pendingJson = _prefs?.getString(_cacheKeyPendingActions);
    if (pendingJson != null) {
      final pending = jsonDecode(pendingJson) as List;
      _hasPendingSync = pending.isNotEmpty;
    }
  }

  /// İlerleme verisini önbelleğe kaydet
  Future<void> cacheProgress(Map<String, dynamic> progress) async {
    try {
      await _prefs?.setString(_cacheKeyProgress, jsonEncode(progress));
      debugPrint('Progress cached successfully');
    } catch (e) {
      debugPrint('Error caching progress: $e');
    }
  }

  /// Önbelleğe alınmış ilerlemeyi al
  Map<String, dynamic>? getCachedProgress() {
    try {
      final json = _prefs?.getString(_cacheKeyProgress);
      if (json != null) {
        return jsonDecode(json) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('Error reading cached progress: $e');
    }
    return null;
  }

  /// Soruları önbelleğe kaydet
  Future<void> cacheQuestions(List<Map<String, dynamic>> questions) async {
    try {
      await _prefs?.setString(_cacheKeyQuestions, jsonEncode(questions));
      debugPrint('Questions cached: ${questions.length}');
    } catch (e) {
      debugPrint('Error caching questions: $e');
    }
  }

  /// Önbelleğe alınmış soruları al
  List<Map<String, dynamic>> getCachedQuestions() {
    try {
      final json = _prefs?.getString(_cacheKeyQuestions);
      if (json != null) {
        return (jsonDecode(json) as List)
            .map((e) => e as Map<String, dynamic>)
            .toList();
      }
    } catch (e) {
      debugPrint('Error reading cached questions: $e');
    }
    return [];
  }

  /// Ayarları önbelleğe kaydet
  Future<void> cacheSettings(Map<String, dynamic> settings) async {
    try {
      await _prefs?.setString(_cacheKeySettings, jsonEncode(settings));
    } catch (e) {
      debugPrint('Error caching settings: $e');
    }
  }

  /// Önbelleğe alınmış ayarları al
  Map<String, dynamic>? getCachedSettings() {
    try {
      final json = _prefs?.getString(_cacheKeySettings);
      if (json != null) {
        return jsonDecode(json) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('Error reading cached settings: $e');
    }
    return null;
  }

  /// Offline aksiyonu kaydet (senkronizasyon için)
  Future<void> addPendingAction(OfflineAction action) async {
    try {
      final pendingJson = _prefs?.getString(_cacheKeyPendingActions);
      List<Map<String, dynamic>> pending = [];
      
      if (pendingJson != null) {
        pending = (jsonDecode(pendingJson) as List)
            .map((e) => e as Map<String, dynamic>)
            .toList();
      }

      pending.add(action.toJson());
      await _prefs?.setString(_cacheKeyPendingActions, jsonEncode(pending));
      
      _hasPendingSync = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding pending action: $e');
    }
  }

  /// Bekleyen verileri senkronize et
  Future<bool> syncPendingData() async {
    if (!_isOnline || !_hasPendingSync) return true;

    _isLoading = true;
    notifyListeners();

    try {
      final pendingJson = _prefs?.getString(_cacheKeyPendingActions);
      if (pendingJson == null) {
        _hasPendingSync = false;
        _isLoading = false;
        notifyListeners();
        return true;
      }

      final pending = (jsonDecode(pendingJson) as List)
          .map((e) => OfflineAction.fromJson(e as Map<String, dynamic>))
          .toList();

      // Her aksiyonu işle
      for (final action in pending) {
        try {
          await _processAction(action);
        } catch (e) {
          debugPrint('Error processing action: $e');
          // Hata durumunda aksiyonu sakla
          continue;
        }
      }

      // Tüm aksiyonlar işlendi - temizle
      await _prefs?.remove(_cacheKeyPendingActions);
      _hasPendingSync = false;

      // Son senkronizasyon zamanını güncelle
      _lastSyncTime = DateTime.now();
      await _prefs?.setString(_cacheKeyLastSync, _lastSyncTime!.toIso8601String());

      debugPrint('Sync completed successfully');
    } catch (e) {
      debugPrint('Sync error: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }

    _isLoading = false;
    notifyListeners();
    return true;
  }

  /// Aksiyonu işle (Firebase'e gönder)
  Future<void> _processAction(OfflineAction action) async {
    // Bu metod gerçek uygulamada Firebase'e veri gönderecek
    debugPrint('Processing action: ${action.type}');
    
    // Simüle edilmiş işlem gecikmesi
    await Future.delayed(const Duration(milliseconds: 100));
    
    // TODO: Firebase'e gerçek veri gönderimi burada yapılacak
  }

  /// Tüm önbelleği temizle
  Future<void> clearCache() async {
    await _prefs?.remove(_cacheKeyProgress);
    await _prefs?.remove(_cacheKeyQuestions);
    await _prefs?.remove(_cacheKeySettings);
    await _prefs?.remove(_cacheKeyPendingActions);
    _hasPendingSync = false;
    notifyListeners();
  }

  /// Önbellek boyutunu al (yaklaşık KB cinsinden)
  int getCacheSize() {
    int size = 0;
    
    final progress = _prefs?.getString(_cacheKeyProgress);
    final questions = _prefs?.getString(_cacheKeyQuestions);
    final settings = _prefs?.getString(_cacheKeySettings);
    final pending = _prefs?.getString(_cacheKeyPendingActions);

    if (progress != null) size += progress.length;
    if (questions != null) size += questions.length;
    if (settings != null) size += settings.length;
    if (pending != null) size += pending.length;

    return (size / 1024).round();
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }
}

/// Offline Aksiyon Modeli
class OfflineAction {
  final String id;
  final String type;
  final Map<String, dynamic> data;
  final DateTime timestamp;

  OfflineAction({
    required this.id,
    required this.type,
    required this.data,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'data': data,
    'timestamp': timestamp.toIso8601String(),
  };

  factory OfflineAction.fromJson(Map<String, dynamic> json) => OfflineAction(
    id: json['id'],
    type: json['type'],
    data: json['data'],
    timestamp: DateTime.parse(json['timestamp']),
  );
}

/// Offline Oyun Verisi
class OfflineGameData {
  final List<OfflineQuestion> questions;
  final int difficulty;
  final String topic;

  OfflineGameData({
    required this.questions,
    required this.difficulty,
    required this.topic,
  });

  Map<String, dynamic> toJson() => {
    'questions': questions.map((q) => q.toJson()).toList(),
    'difficulty': difficulty,
    'topic': topic,
  };

  factory OfflineGameData.fromJson(Map<String, dynamic> json) => OfflineGameData(
    questions: (json['questions'] as List)
        .map((q) => OfflineQuestion.fromJson(q))
        .toList(),
    difficulty: json['difficulty'],
    topic: json['topic'],
  );
}

/// Offline Soru
class OfflineQuestion {
  final int num1;
  final int num2;
  final String operator;
  final int correctAnswer;
  final List<int> options;

  OfflineQuestion({
    required this.num1,
    required this.num2,
    required this.operator,
    required this.correctAnswer,
    required this.options,
  });

  Map<String, dynamic> toJson() => {
    'num1': num1,
    'num2': num2,
    'operator': operator,
    'correctAnswer': correctAnswer,
    'options': options,
  };

  factory OfflineQuestion.fromJson(Map<String, dynamic> json) => OfflineQuestion(
    num1: json['num1'],
    num2: json['num2'],
    operator: json['operator'],
    correctAnswer: json['correctAnswer'],
    options: List<int>.from(json['options']),
  );
}

