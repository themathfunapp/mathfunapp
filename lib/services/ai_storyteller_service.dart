import 'package:flutter/foundation.dart';
import 'dart:math' as math;

import 'package:mathfun/localization/ai_storyteller_content.dart';
import 'package:mathfun/localization/app_supported_locales.dart';
import 'package:mathfun/models/ai_story_models.dart';

/// Kişiselleştirilmiş matematik hikayeleri — seçilen arayüz diline göre metin üretir.
class AIStorytellerService extends ChangeNotifier {
  final math.Random _random = math.Random();

  MathStory generateStory({
    required String childName,
    required int age,
    required String topic,
    required String difficulty,
    required String languageCode,
    List<String>? interests,
  }) {
    final templates = aiStoryTemplates(languageCode);
    final template = _pickTemplate(templates, topic, age);
    final characters = _generateCharacters(languageCode, interests);
    final problem = _generateMathProblem(topic, difficulty, languageCode);

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
      totalDuration: template.chapters.length * 3,
    );
  }

  MathStory generateBedtimeStory({
    required String childName,
    required int age,
    required String languageCode,
  }) {
    final stories = aiStoryBedtimeList(languageCode);
    final template = stories[_random.nextInt(stories.length)];

    return MathStory(
      title: _personalizeText(template['title']!, childName),
      chapters: [
        StoryChapter(
          title: aiStoryChapterStart(languageCode),
          content: _personalizeText(template['content']!, childName),
          image: template['image']!,
          choices: [],
        ),
      ],
      characters: [
        StoryCharacter(
          name: aiStoryFairyName(languageCode),
          emoji: '🧚',
          role: aiStoryBedtimeFairyRole(languageCode),
        ),
      ],
      mathTopic: 'counting',
      totalDuration: 5,
      isBedtimeStory: true,
    );
  }

  String generateDailyMessage(String childName, int streak, int level, String languageCode) {
    return aiStoryDailyLine(languageCode, _random, childName, streak, level);
  }

  String generateQuestionContext({
    required int num1,
    required int num2,
    required String topic,
    required String languageCode,
  }) {
    final contexts = aiStoryQuestionContexts(languageCode);
    final list = contexts[topic] ?? contexts['default']!;
    final template = list[_random.nextInt(list.length)];

    return template.replaceAll('{num1}', num1.toString()).replaceAll('{num2}', num2.toString());
  }

  StoryTemplate _pickTemplate(Map<String, List<StoryTemplate>> templates, String topic, int age) {
    final list = templates[topic] ?? templates['default']!;
    if (age <= 5) {
      return list.firstWhere((t) => t.ageGroup == 'preschool');
    } else if (age <= 8) {
      return list.firstWhere((t) => t.ageGroup == 'elementary');
    } else {
      return list.firstWhere((t) => t.ageGroup == 'advanced');
    }
  }

  List<StoryCharacter> _generateCharacters(String languageCode, List<String>? interests) {
    final base = List<StoryCharacter>.from(aiStoryDefaultCharacters(languageCode));

    if (interests != null && interests.contains('space')) {
      base.add(StoryCharacter(name: _spaceRobotName(languageCode), emoji: '🤖', role: _guideRole(languageCode)));
    }

    if (interests != null && interests.contains('animals')) {
      base.add(StoryCharacter(name: _mathLionName(languageCode), emoji: '🦁', role: _guardRole(languageCode)));
    }

    return base;
  }

  String _spaceRobotName(String languageCode) {
    const m = {
      'tr': 'Uzay robotu',
      'en': 'Space robot',
      'de': 'Weltraumroboter',
      'ar': 'روبوت فضاء',
      'fa': 'ربات فضایی',
      'zh': '太空机器人',
      'id': 'Robot luar angkasa',
      'ku': 'Robotê fezayê',
      'es': 'Robot espacial',
      'fr': 'Robot spatial',
      'ru': 'Космический робот',
      'ja': 'うちゅうロボット',
      'ko': '우주 로봇',
      'hi': 'अंतरिक्ष रोबोट',
      'ur': 'خلائی روبوٹ',
      'pt': 'Robô espacial',
      'it': 'Robot spaziale',
      'pl': 'Robot kosmiczny',
    };
    return m[_norm(languageCode)] ?? m['en']!;
  }

  String _mathLionName(String languageCode) {
    const m = {
      'tr': 'Matematik aslanı',
      'en': 'Math lion',
      'de': 'Mathe-Löwe',
      'ar': 'أسد الرياضيات',
      'fa': 'شیر ریاضی',
      'zh': '数学狮子',
      'id': 'Singa matematika',
      'ku': 'Şêrê matematîkê',
      'es': 'León de las mates',
      'fr': 'Lion des maths',
      'ru': 'Математический лев',
      'ja': 'すうがくのライオン',
      'ko': '수학 사자',
      'hi': 'गणित शेर',
      'ur': 'ریاضی کا شیر',
      'pt': 'Leão da matemática',
      'it': 'Leone della matematica',
      'pl': 'Lew matematyki',
    };
    return m[_norm(languageCode)] ?? m['en']!;
  }

  String _guideRole(String languageCode) {
    const m = {
      'tr': 'rehber',
      'en': 'guide',
      'de': 'Führer',
      'ar': 'دليل',
      'fa': 'راهنما',
      'zh': '向导',
      'id': 'pandu',
      'ku': 'rêber',
      'es': 'guía',
      'fr': 'guide',
      'ru': 'проводник',
      'ja': 'ガイド',
      'ko': '안내자',
      'hi': 'मार्गदर्शक',
      'ur': 'رہنما',
      'pt': 'guia',
      'it': 'guida',
      'pl': 'przewodnik',
    };
    return m[_norm(languageCode)] ?? m['en']!;
  }

  String _guardRole(String languageCode) {
    const m = {
      'tr': 'koruyucu',
      'en': 'guardian',
      'de': 'Beschützer',
      'ar': 'حارس',
      'fa': 'نگهبان',
      'zh': '守护者',
      'id': 'penjaga',
      'ku': 'parêzer',
      'es': 'guardián',
      'fr': 'gardien',
      'ru': 'страж',
      'ja': 'まもりがみ',
      'ko': '수호자',
      'hi': 'रक्षक',
      'ur': 'محافظ',
      'pt': 'guardião',
      'it': 'guardiano',
      'pl': 'strażnik',
    };
    return m[_norm(languageCode)] ?? m['en']!;
  }

  String _norm(String code) {
    final c = code.toLowerCase();
    return kSupportedLanguageCodes.contains(c) ? c : 'en';
  }

  MathProblem _generateMathProblem(String topic, String difficulty, String languageCode) {
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
      hint: aiStoryHint(languageCode, num1, num2, operator),
    );
  }

  String _personalizeText(String text, String childName) {
    return text.replaceAll('{childName}', childName);
  }
}
