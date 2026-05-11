/// Modeller — AI Hikaye Anlatıcı (servis ve içerik dosyaları tarafından paylaşılır).

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
