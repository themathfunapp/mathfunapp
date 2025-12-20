import 'package:flutter/foundation.dart';
import 'dart:math' as math;

/// AI Hikaye Anlatıcı Servisi
/// Kişiselleştirilmiş matematik hikayeleri oluşturur
class AIStorytellerService extends ChangeNotifier {
  final math.Random _random = math.Random();

  /// Kişiselleştirilmiş matematik hikayesi oluştur
  MathStory generateStory({
    required String childName,
    required int age,
    required String topic,
    required String difficulty,
    List<String>? interests,
  }) {
    final template = _getStoryTemplate(topic, age);
    final characters = _generateCharacters(interests);
    final problem = _generateMathProblem(topic, difficulty);

    return MathStory(
      title: _personalizeText(template.title, childName),
      chapters: template.chapters.map((chapter) {
        return StoryChapter(
          title: chapter.title,
          content: _personalizeText(chapter.content, childName),
          image: chapter.image,
          mathChallenge: problem,
          choices: chapter.choices,
        );
      }).toList(),
      characters: characters,
      mathTopic: topic,
      totalDuration: template.chapters.length * 3, // dakika
    );
  }

  /// Uyku öncesi matematik masalı
  MathStory generateBedtimeStory({
    required String childName,
    required int age,
  }) {
    final stories = _bedtimeStories;
    final template = stories[_random.nextInt(stories.length)];

    return MathStory(
      title: _personalizeText(template['title']!, childName),
      chapters: [
        StoryChapter(
          title: 'Başlangıç',
          content: _personalizeText(template['content']!, childName),
          image: template['image']!,
          choices: [],
        ),
      ],
      characters: [
        StoryCharacter(name: 'Sayı Perisi', emoji: '🧚', role: 'yardımcı'),
      ],
      mathTopic: 'counting',
      totalDuration: 5,
      isBedtimeStory: true,
    );
  }

  /// Günlük mesaj oluştur
  String generateDailyMessage(String childName, int streak, int level) {
    final messages = [
      '$childName, bugün matematik macerasına hazır mısın? 🚀',
      'Harika! $streak gündür arka arkaya giriş yaptın! 🔥',
      'Seviye $level\'e ulaştın! Süper gidiyorsun! ⭐',
      '$childName, sayılar seni bekliyor! 🔢',
      'Bugün yeni bir şeyler öğrenmeye ne dersin? 📚',
      'Matematik kahramanı $childName sahneye! 🦸',
    ];

    return messages[_random.nextInt(messages.length)];
  }

  /// Soru için hikaye bağlamı oluştur
  String generateQuestionContext({
    required int num1,
    required int num2,
    required String operator,
    required String topic,
  }) {
    final contexts = _questionContexts[topic] ?? _questionContexts['default']!;
    final template = contexts[_random.nextInt(contexts.length)];

    return template
        .replaceAll('{num1}', num1.toString())
        .replaceAll('{num2}', num2.toString());
  }

  StoryTemplate _getStoryTemplate(String topic, int age) {
    final templates = _storyTemplates[topic] ?? _storyTemplates['default']!;
    
    // Yaşa uygun şablon seç
    if (age <= 5) {
      return templates.where((t) => t.ageGroup == 'preschool').first;
    } else if (age <= 8) {
      return templates.where((t) => t.ageGroup == 'elementary').first;
    } else {
      return templates.where((t) => t.ageGroup == 'advanced').first;
    }
  }

  List<StoryCharacter> _generateCharacters(List<String>? interests) {
    final baseCharacters = [
      StoryCharacter(name: 'Sayı Sincabı', emoji: '🐿️', role: 'yardımcı'),
      StoryCharacter(name: 'Geometri Baykuşu', emoji: '🦉', role: 'akıl hocası'),
      StoryCharacter(name: 'Toplama Kedisi', emoji: '🐱', role: 'arkadaş'),
    ];

    if (interests != null && interests.contains('space')) {
      baseCharacters.add(
        StoryCharacter(name: 'Uzay Robotu', emoji: '🤖', role: 'rehber'),
      );
    }

    if (interests != null && interests.contains('animals')) {
      baseCharacters.add(
        StoryCharacter(name: 'Matematik Aslanı', emoji: '🦁', role: 'koruyucu'),
      );
    }

    return baseCharacters;
  }

  MathProblem _generateMathProblem(String topic, String difficulty) {
    int num1, num2, answer;
    String operator;
    int maxNum;

    switch (difficulty) {
      case 'easy':
        maxNum = 10;
        break;
      case 'medium':
        maxNum = 20;
        break;
      case 'hard':
        maxNum = 50;
        break;
      default:
        maxNum = 10;
    }

    switch (topic) {
      case 'addition':
        operator = '+';
        num1 = _random.nextInt(maxNum) + 1;
        num2 = _random.nextInt(maxNum) + 1;
        answer = num1 + num2;
        break;
      case 'subtraction':
        operator = '-';
        num1 = _random.nextInt(maxNum) + 1;
        num2 = _random.nextInt(num1) + 1;
        answer = num1 - num2;
        break;
      case 'multiplication':
        operator = '×';
        num1 = _random.nextInt(10) + 1;
        num2 = _random.nextInt(10) + 1;
        answer = num1 * num2;
        break;
      default:
        operator = '+';
        num1 = _random.nextInt(maxNum) + 1;
        num2 = _random.nextInt(maxNum) + 1;
        answer = num1 + num2;
    }

    return MathProblem(
      num1: num1,
      num2: num2,
      operator: operator,
      answer: answer,
      hint: _generateHint(num1, num2, operator),
    );
  }

  String _generateHint(int num1, int num2, String operator) {
    switch (operator) {
      case '+':
        return 'İpucu: $num1 sayısından başla ve $num2 tane daha say';
      case '-':
        return 'İpucu: $num1 sayısından $num2 tane geri say';
      case '×':
        return 'İpucu: $num1 sayısını $num2 kere topla';
      default:
        return 'Dikkatli düşün!';
    }
  }

  String _personalizeText(String text, String childName) {
    return text.replaceAll('{childName}', childName);
  }

  // Hikaye şablonları
  final Map<String, List<StoryTemplate>> _storyTemplates = {
    'addition': [
      StoryTemplate(
        title: '{childName} ve Kayıp Elmalar',
        ageGroup: 'preschool',
        chapters: [
          ChapterTemplate(
            title: 'Elma Bahçesi',
            content: 'Bir gün {childName}, elma bahçesine gitti. Ağaçta güzel elmalar vardı...',
            image: '🍎',
            choices: ['Elmaları topla', 'Bekle'],
          ),
          ChapterTemplate(
            title: 'Toplama Zamanı',
            content: 'Birinci ağaçtan 3 elma, ikinci ağaçtan 4 elma topladı. Kaç elma oldu?',
            image: '🧺',
            choices: ['Hesapla'],
          ),
        ],
      ),
      StoryTemplate(
        title: '{childName} ve Yıldız Toplama',
        ageGroup: 'elementary',
        chapters: [
          ChapterTemplate(
            title: 'Gökyüzü Macerası',
            content: '{childName} uzay gemisine bindi ve yıldız toplamaya çıktı...',
            image: '🚀',
            choices: ['Uçuşa başla'],
          ),
        ],
      ),
      StoryTemplate(
        title: '{childName}: Matematik Şampiyonu',
        ageGroup: 'advanced',
        chapters: [
          ChapterTemplate(
            title: 'Turnuva',
            content: 'Büyük matematik turnuvasında {childName} yarışmaya hazır...',
            image: '🏆',
            choices: ['Yarışmaya katıl'],
          ),
        ],
      ),
    ],
    'default': [
      StoryTemplate(
        title: '{childName}\'ın Matematik Macerası',
        ageGroup: 'preschool',
        chapters: [
          ChapterTemplate(
            title: 'Yeni Bir Gün',
            content: 'Güneşli bir sabah, {childName} yeni bir maceraya atıldı...',
            image: '☀️',
            choices: ['Başla'],
          ),
        ],
      ),
    ],
  };

  // Uyku öncesi hikayeler
  final List<Map<String, String>> _bedtimeStories = [
    {
      'title': '{childName} ve Sayı Yıldızları',
      'content': '''Gecenin karanlığında, {childName} gökyüzüne baktı. 
      Yıldızlar parıl parıl parlıyordu. Bir, iki, üç... diye saymaya başladı.
      Her yıldız bir sayı fısıldıyordu rüzgarla. 
      "Beş artı beş on eder" dedi en parlak yıldız.
      {childName} gülümsedi ve tatlı bir uykuya daldı.
      Rüyasında sayılarla dans etti, matematiğin büyülü dünyasında gezdi.
      Günaydın dediğinde, yeni sayılar öğrenmeye hazırdı...''',
      'image': '⭐',
    },
    {
      'title': '{childName} ve Ay\'ın Gizemi',
      'content': '''Dolunay gökyüzünde parlıyordu.
      {childName} pencereden izlerken, ay konuşmaya başladı:
      "Sence kaç yıldız var bu gece?" diye sordu.
      {childName} saymaya başladı... bir, iki, üç...
      Sayarken gözleri yavaş yavaş kapandı.
      Rüyasında ay ile matematik soruları çözdü.
      Ertesi gün uyanınca gülümsedi.
      Matematiğin ne kadar eğlenceli olduğunu hatırladı...''',
      'image': '🌙',
    },
  ];

  // Soru bağlamları
  final Map<String, List<String>> _questionContexts = {
    'addition': [
      'Sepetinde {num1} elma var. Arkadaşın sana {num2} elma daha verdi.',
      '{num1} tane kuş ağaçta oturuyor. {num2} tane daha geldi.',
      'Parkta {num1} çocuk oynuyor. {num2} çocuk daha katıldı.',
    ],
    'subtraction': [
      'Kutunda {num1} şeker vardı. {num2} tanesini yedin.',
      'Bahçede {num1} kelebek uçuyordu. {num2} tanesi gitti.',
      '{num1} balonun vardı. {num2} tanesi patladı.',
    ],
    'multiplication': [
      '{num1} tabakta {num2}\'şer kurabiye var.',
      '{num1} arabanın her birinde {num2} tekerlek var.',
      '{num1} çiçeğin her birinde {num2} yaprak var.',
    ],
    'default': [
      'Matematik sorusu: {num1} ve {num2} sayılarını kullan.',
    ],
  };
}

/// Matematik Hikayesi
class MathStory {
  final String title;
  final List<StoryChapter> chapters;
  final List<StoryCharacter> characters;
  final String mathTopic;
  final int totalDuration;
  final bool isBedtimeStory;

  MathStory({
    required this.title,
    required this.chapters,
    required this.characters,
    required this.mathTopic,
    required this.totalDuration,
    this.isBedtimeStory = false,
  });
}

/// Hikaye Bölümü
class StoryChapter {
  final String title;
  final String content;
  final String image;
  final MathProblem? mathChallenge;
  final List<String> choices;

  StoryChapter({
    required this.title,
    required this.content,
    required this.image,
    this.mathChallenge,
    required this.choices,
  });
}

/// Hikaye Karakteri
class StoryCharacter {
  final String name;
  final String emoji;
  final String role;

  StoryCharacter({
    required this.name,
    required this.emoji,
    required this.role,
  });
}

/// Matematik Problemi
class MathProblem {
  final int num1;
  final int num2;
  final String operator;
  final int answer;
  final String hint;

  MathProblem({
    required this.num1,
    required this.num2,
    required this.operator,
    required this.answer,
    required this.hint,
  });
}

/// Hikaye Şablonu
class StoryTemplate {
  final String title;
  final String ageGroup;
  final List<ChapterTemplate> chapters;

  StoryTemplate({
    required this.title,
    required this.ageGroup,
    required this.chapters,
  });
}

/// Bölüm Şablonu
class ChapterTemplate {
  final String title;
  final String content;
  final String image;
  final List<String> choices;

  ChapterTemplate({
    required this.title,
    required this.content,
    required this.image,
    required this.choices,
  });
}

