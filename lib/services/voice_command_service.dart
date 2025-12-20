import 'package:flutter/foundation.dart';

/// Sesli Komut Servisi
/// Sesle matematik sorusu çözme ve uygulama kontrolü
class VoiceCommandService extends ChangeNotifier {
  bool _isListening = false;
  bool _isEnabled = true;
  String _lastCommand = '';
  String _feedback = '';

  bool get isListening => _isListening;
  bool get isEnabled => _isEnabled;
  String get lastCommand => _lastCommand;
  String get feedback => _feedback;

  /// Dinlemeyi başlat
  void startListening() {
    _isListening = true;
    _feedback = 'Dinliyorum...';
    notifyListeners();
  }

  /// Dinlemeyi durdur
  void stopListening() {
    _isListening = false;
    _feedback = '';
    notifyListeners();
  }

  /// Sesli komutu işle
  VoiceCommandResult processCommand(String text) {
    _lastCommand = text;
    final normalized = text.toLowerCase().trim();

    // Sayı cevabı kontrolü
    final numberMatch = RegExp(r'\d+').firstMatch(normalized);
    if (numberMatch != null) {
      return VoiceCommandResult(
        type: VoiceCommandType.answer,
        value: int.parse(numberMatch.group(0)!),
        message: 'Cevabın: ${numberMatch.group(0)}',
      );
    }

    // Uygulama komutları
    if (_containsAny(normalized, ['oyun başlat', 'yeni oyun', 'başla', 'oyna'])) {
      return VoiceCommandResult(
        type: VoiceCommandType.startGame,
        message: 'Oyun başlatılıyor!',
      );
    }

    if (_containsAny(normalized, ['ipucu', 'yardım', 'yardım et'])) {
      return VoiceCommandResult(
        type: VoiceCommandType.hint,
        message: 'İpucu geliyor!',
      );
    }

    if (_containsAny(normalized, ['tekrar', 'tekrarla', 'bir daha'])) {
      return VoiceCommandResult(
        type: VoiceCommandType.repeat,
        message: 'Soruyu tekrarlıyorum...',
      );
    }

    if (_containsAny(normalized, ['atla', 'sonraki', 'geç'])) {
      return VoiceCommandResult(
        type: VoiceCommandType.skip,
        message: 'Sonraki soruya geçiliyor...',
      );
    }

    if (_containsAny(normalized, ['mola', 'dur', 'duraklat', 'bekle'])) {
      return VoiceCommandResult(
        type: VoiceCommandType.pause,
        message: 'Oyun duraklatıldı.',
      );
    }

    if (_containsAny(normalized, ['devam', 'devam et', 'sürdür'])) {
      return VoiceCommandResult(
        type: VoiceCommandType.resume,
        message: 'Devam ediyoruz!',
      );
    }

    if (_containsAny(normalized, ['çıkış', 'kapat', 'bitir'])) {
      return VoiceCommandResult(
        type: VoiceCommandType.exit,
        message: 'Oyundan çıkılıyor...',
      );
    }

    if (_containsAny(normalized, ['hikaye', 'masal', 'hikaye anlat'])) {
      return VoiceCommandResult(
        type: VoiceCommandType.story,
        message: 'Hikaye modu açılıyor...',
      );
    }

    if (_containsAny(normalized, ['şarkı', 'müzik', 'matematik şarkısı'])) {
      return VoiceCommandResult(
        type: VoiceCommandType.music,
        message: '🎵 Matematik şarkısı çalınıyor!',
      );
    }

    if (_containsAny(normalized, ['puan', 'skor', 'puanım', 'ne kadar'])) {
      return VoiceCommandResult(
        type: VoiceCommandType.score,
        message: 'Puanın gösteriliyor...',
      );
    }

    if (_containsAny(normalized, ['ayarlar', 'ayar', 'seçenekler'])) {
      return VoiceCommandResult(
        type: VoiceCommandType.settings,
        message: 'Ayarlar açılıyor...',
      );
    }

    // Matematik işlemleri
    if (_containsAny(normalized, ['toplama', 'topla', 'artı'])) {
      return VoiceCommandResult(
        type: VoiceCommandType.topic,
        value: 'addition',
        message: 'Toplama konusu seçildi!',
      );
    }

    if (_containsAny(normalized, ['çıkarma', 'çıkar', 'eksi'])) {
      return VoiceCommandResult(
        type: VoiceCommandType.topic,
        value: 'subtraction',
        message: 'Çıkarma konusu seçildi!',
      );
    }

    if (_containsAny(normalized, ['çarpma', 'çarp', 'kere'])) {
      return VoiceCommandResult(
        type: VoiceCommandType.topic,
        value: 'multiplication',
        message: 'Çarpma konusu seçildi!',
      );
    }

    if (_containsAny(normalized, ['bölme', 'böl'])) {
      return VoiceCommandResult(
        type: VoiceCommandType.topic,
        value: 'division',
        message: 'Bölme konusu seçildi!',
      );
    }

    // Tanınmayan komut
    return VoiceCommandResult(
      type: VoiceCommandType.unknown,
      message: 'Anlamadım. Tekrar söyler misin?',
    );
  }

  /// Sesli cevap oluştur
  String generateVoiceFeedback(bool isCorrect, {int? correctAnswer}) {
    if (isCorrect) {
      final responses = [
        'Doğru! Harika!',
        'Aferin! Çok iyi!',
        'Mükemmel! Doğru cevap!',
        'Bravo! Süpersin!',
        'Evet! Bu doğru!',
      ];
      return responses[DateTime.now().millisecond % responses.length];
    } else {
      final responses = [
        'Olmadı. Tekrar dene!',
        'Hayır, bir daha düşün.',
        'Doğru cevap ${correctAnswer ?? '?'} olmalıydı.',
        'Yaklaştın! Bir daha dene.',
      ];
      return responses[DateTime.now().millisecond % responses.length];
    }
  }

  /// Soru oku
  String readQuestion(int num1, int num2, String operator) {
    String opText;
    switch (operator) {
      case '+':
        opText = 'artı';
        break;
      case '-':
        opText = 'eksi';
        break;
      case '×':
        opText = 'çarpı';
        break;
      case '÷':
        opText = 'bölü';
        break;
      default:
        opText = operator;
    }
    return '$num1 $opText $num2 kaç eder?';
  }

  /// Sesli komutları etkinleştir/devre dışı bırak
  void toggleVoiceCommands(bool enabled) {
    _isEnabled = enabled;
    notifyListeners();
  }

  bool _containsAny(String text, List<String> keywords) {
    return keywords.any((keyword) => text.contains(keyword));
  }

  /// Kullanılabilir komutları listele
  List<VoiceCommandInfo> getAvailableCommands() {
    return [
      VoiceCommandInfo(
        command: 'Sayı söyle',
        description: 'Cevabı söyle (örn: "beş", "on iki")',
        example: '"Yirmi üç"',
      ),
      VoiceCommandInfo(
        command: 'Yeni oyun / Başla',
        description: 'Yeni bir oyun başlat',
        example: '"Yeni oyun başlat"',
      ),
      VoiceCommandInfo(
        command: 'İpucu / Yardım',
        description: 'İpucu al',
        example: '"Yardım et"',
      ),
      VoiceCommandInfo(
        command: 'Tekrarla',
        description: 'Soruyu tekrar oku',
        example: '"Bir daha söyle"',
      ),
      VoiceCommandInfo(
        command: 'Sonraki / Atla',
        description: 'Bir sonraki soruya geç',
        example: '"Sonraki soru"',
      ),
      VoiceCommandInfo(
        command: 'Mola / Duraklat',
        description: 'Oyunu duraklat',
        example: '"Mola ver"',
      ),
      VoiceCommandInfo(
        command: 'Devam',
        description: 'Oyuna devam et',
        example: '"Devam et"',
      ),
      VoiceCommandInfo(
        command: 'Toplama / Çıkarma / Çarpma / Bölme',
        description: 'Konu seç',
        example: '"Toplama oynayalım"',
      ),
      VoiceCommandInfo(
        command: 'Hikaye',
        description: 'Hikaye modunu aç',
        example: '"Bana hikaye anlat"',
      ),
      VoiceCommandInfo(
        command: 'Puanım',
        description: 'Puanı göster',
        example: '"Ne kadar puanım var?"',
      ),
    ];
  }
}

/// Sesli Komut Sonucu
class VoiceCommandResult {
  final VoiceCommandType type;
  final dynamic value;
  final String message;

  VoiceCommandResult({
    required this.type,
    this.value,
    required this.message,
  });
}

/// Sesli Komut Türleri
enum VoiceCommandType {
  answer,
  startGame,
  hint,
  repeat,
  skip,
  pause,
  resume,
  exit,
  story,
  music,
  score,
  settings,
  topic,
  unknown,
}

/// Sesli Komut Bilgisi
class VoiceCommandInfo {
  final String command;
  final String description;
  final String example;

  VoiceCommandInfo({
    required this.command,
    required this.description,
    required this.example,
  });
}

