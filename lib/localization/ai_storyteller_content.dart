import 'dart:math' as math;

import 'package:mathfun/localization/app_supported_locales.dart';
import 'package:mathfun/models/ai_story_models.dart';

/// AI Hikaye Anlatıcı — 18 arayüz dili (tr, en, de, ar, fa, zh, id, ku, es, fr, ru, ja, ko, hi, ur, pt, it, pl).
String _normLang(String? code) {
  final c = (code ?? 'en').toLowerCase();
  return kSupportedLanguageCodes.contains(c) ? c : 'en';
}

// --- UI (ekran) ---

String aiStoryUi(String? lang, String key) {
  final L = _normLang(lang);
  final row = _ui[L] ?? _ui['en']!;
  return row[key] ?? _ui['en']![key] ?? key;
}

String aiStoryDailyLine(String? lang, math.Random random, String childName, int streak, int level) {
  final L = _normLang(lang);
  final list = _daily[L] ?? _daily['en']!;
  var s = list[random.nextInt(list.length)];
  return s
      .replaceAll('{childName}', childName)
      .replaceAll('{streak}', '$streak')
      .replaceAll('{level}', '$level');
}

String aiStoryHint(String? lang, int num1, int num2, String operator) {
  final L = _normLang(lang);
  final h = _hints[L] ?? _hints['en']!;
  switch (operator) {
    case '+':
      return h['plus']!.replaceAll('{n1}', '$num1').replaceAll('{n2}', '$num2');
    case '-':
      return h['minus']!.replaceAll('{n1}', '$num1').replaceAll('{n2}', '$num2');
    case '×':
      return h['times']!.replaceAll('{n1}', '$num1').replaceAll('{n2}', '$num2');
    default:
      return h['default']!;
  }
}

Map<String, List<StoryTemplate>> aiStoryTemplates(String? lang) {
  final L = _normLang(lang);
  return _templates[L] ?? _templates['en']!;
}

List<Map<String, String>> aiStoryBedtimeList(String? lang) {
  final L = _normLang(lang);
  return _bedtime[L] ?? _bedtime['en']!;
}

Map<String, List<String>> aiStoryQuestionContexts(String? lang) {
  final L = _normLang(lang);
  return _contexts[L] ?? _contexts['en']!;
}

String aiStoryChapterStart(String? lang) => aiStoryUi(lang, 'chapter_start');

String aiStoryFairyName(String? lang) => aiStoryUi(lang, 'fairy_name');

/// Uyku masalı — peri karakterinin kısa rol etiketi
String aiStoryBedtimeFairyRole(String? lang) {
  final L = _normLang(lang);
  const roles = {
    'tr': 'yardımcı',
    'en': 'helper',
    'de': 'Helfer',
    'ar': 'مساعد',
    'fa': 'یار',
    'zh': '小伙伴',
    'id': 'pembantu',
    'ku': 'alîkar',
    'es': 'ayudante',
    'fr': 'assistant',
    'ru': 'помощник',
    'ja': 'おてつだい',
    'ko': '도우미',
    'hi': 'सहायक',
    'ur': 'مددگار',
    'pt': 'ajudante',
    'it': 'aiutante',
    'pl': 'pomocnik',
  };
  return roles[L] ?? roles['en']!;
}

List<StoryCharacter> aiStoryDefaultCharacters(String? lang) {
  final L = _normLang(lang);
  final n = _chars[L] ?? _chars['en']!;
  return [
    StoryCharacter(name: n['squirrel']!, emoji: '🐿️', role: n['role_helper']!),
    StoryCharacter(name: n['owl']!, emoji: '🦉', role: n['role_mentor']!),
    StoryCharacter(name: n['cat']!, emoji: '🐱', role: n['role_friend']!),
  ];
}

// ========== Veri tabloları ==========

const Map<String, Map<String, String>> _ui = {
  'tr': {
    'title': 'Hikaye Anlatıcı',
    'loading': 'Hikaye hazırlanıyor...',
    'magic': '✨ Sihir yapılıyor ✨',
    'greeting': 'Merhaba {childName}!',
    'pick_topic': '📚 Hikaye konusu seç',
    'topic_addition': 'Toplama',
    'topic_subtraction': 'Çıkarma',
    'topic_multiplication': 'Çarpma',
    'adventure_title': 'Macera hikayesi',
    'adventure_sub': 'Matematik dolu bir macera başlat!',
    'bedtime_title': 'Uyku masalı',
    'bedtime_sub': 'Tatlı rüyalar için matematik masalı',
    'characters_title': '🎭 Hikaye karakterleri',
    'dialog_success_title': '🎉 Harika!',
    'dialog_success_body': 'Doğru cevap!',
    'dialog_continue': 'Devam et',
    'dialog_hint_title': '💡 İpucu',
    'try_again': 'Tekrar dene',
    'math_challenge_btn': 'Matematik meydan okuması!',
    'math_time': '🧮 Matematik zamanı!',
    'nav_back': 'Geri',
    'nav_forward': 'İleri',
    'nav_finish': 'Bitir',
    'chapter_start': 'Başlangıç',
    'fairy_name': 'Sayı perisi',
  },
  'en': {
    'title': 'Storyteller',
    'loading': 'Preparing your story...',
    'magic': '✨ Making magic ✨',
    'greeting': 'Hello {childName}!',
    'pick_topic': '📚 Choose a story topic',
    'topic_addition': 'Addition',
    'topic_subtraction': 'Subtraction',
    'topic_multiplication': 'Multiplication',
    'adventure_title': 'Adventure story',
    'adventure_sub': 'Start a math-filled adventure!',
    'bedtime_title': 'Bedtime tale',
    'bedtime_sub': 'A gentle math story for sweet dreams',
    'characters_title': '🎭 Story characters',
    'dialog_success_title': '🎉 Great job!',
    'dialog_success_body': 'That’s correct!',
    'dialog_continue': 'Continue',
    'dialog_hint_title': '💡 Hint',
    'try_again': 'Try again',
    'math_challenge_btn': 'Math challenge!',
    'math_time': '🧮 Math time!',
    'nav_back': 'Back',
    'nav_forward': 'Next',
    'nav_finish': 'Done',
    'chapter_start': 'Beginning',
    'fairy_name': 'Number fairy',
  },
  'de': {
    'title': 'Geschichtenerzähler',
    'loading': 'Geschichte wird vorbereitet...',
    'magic': '✨ Es wird gezaubert ✨',
    'greeting': 'Hallo {childName}!',
    'pick_topic': '📚 Wähle ein Thema',
    'topic_addition': 'Addition',
    'topic_subtraction': 'Subtraktion',
    'topic_multiplication': 'Multiplikation',
    'adventure_title': 'Abenteuergeschichte',
    'adventure_sub': 'Starte ein Abenteuer voller Mathe!',
    'bedtime_title': 'Gute-Nacht-Geschichte',
    'bedtime_sub': 'Eine sanfte Mathe-Geschichte zum Einschlafen',
    'characters_title': '🎭 Figuren',
    'dialog_success_title': '🎉 Super!',
    'dialog_success_body': 'Richtig!',
    'dialog_continue': 'Weiter',
    'dialog_hint_title': '💡 Tipp',
    'try_again': 'Nochmal',
    'math_challenge_btn': 'Mathe-Herausforderung!',
    'math_time': '🧮 Mathe-Zeit!',
    'nav_back': 'Zurück',
    'nav_forward': 'Weiter',
    'nav_finish': 'Fertig',
    'chapter_start': 'Anfang',
    'fairy_name': 'Zahlenfee',
  },
  'ar': {
    'title': 'راوي القصص',
    'loading': 'جاري تجهيز القصة...',
    'magic': '✨ يحدث السحر ✨',
    'greeting': 'أهلًا {childName}!',
    'pick_topic': '📚 اختر موضوع القصة',
    'topic_addition': 'الجمع',
    'topic_subtraction': 'الطرح',
    'topic_multiplication': 'الضرب',
    'adventure_title': 'قصة مغامرة',
    'adventure_sub': 'ابدأ مغامرة مليئة بالرياضيات!',
    'bedtime_title': 'قصة ما قبل النوم',
    'bedtime_sub': 'قصة رياضية هادئة لأحلام جميلة',
    'characters_title': '🎭 شخصيات القصة',
    'dialog_success_title': '🎉 رائع!',
    'dialog_success_body': 'إجابة صحيحة!',
    'dialog_continue': 'تابع',
    'dialog_hint_title': '💡 تلميح',
    'try_again': 'حاول مجددًا',
    'math_challenge_btn': 'تحدي الرياضيات!',
    'math_time': '🧮 وقت الرياضيات!',
    'nav_back': 'رجوع',
    'nav_forward': 'التالي',
    'nav_finish': 'إنهاء',
    'chapter_start': 'البداية',
    'fairy_name': 'جنية الأرقام',
  },
  'fa': {
    'title': 'قصه‌گو',
    'loading': 'داستان آماده می‌شود...',
    'magic': '✨ جادو در حال انجام است ✨',
    'greeting': 'سلام {childName}!',
    'pick_topic': '📚 موضوع داستان را انتخاب کن',
    'topic_addition': 'جمع',
    'topic_subtraction': 'تفریق',
    'topic_multiplication': 'ضرب',
    'adventure_title': 'داستان ماجراجویی',
    'adventure_sub': 'یک ماجرای پر از ریاضی شروع کن!',
    'bedtime_title': 'قصه خواب',
    'bedtime_sub': 'قصه ریاضی آرام برای رویاهای شیرین',
    'characters_title': '🎭 شخصیت‌های داستان',
    'dialog_success_title': '🎉 آفرین!',
    'dialog_success_body': 'درست بود!',
    'dialog_continue': 'ادامه',
    'dialog_hint_title': '💡 راهنما',
    'try_again': 'دوباره امتحان کن',
    'math_challenge_btn': 'چالش ریاضی!',
    'math_time': '🧮 وقت ریاضی!',
    'nav_back': 'قبلی',
    'nav_forward': 'بعدی',
    'nav_finish': 'پایان',
    'chapter_start': 'آغاز',
    'fairy_name': 'پری اعداد',
  },
  'zh': {
    'title': '故事讲述',
    'loading': '正在准备故事…',
    'magic': '✨ 魔法进行中 ✨',
    'greeting': '你好，{childName}！',
    'pick_topic': '📚 选择故事主题',
    'topic_addition': '加法',
    'topic_subtraction': '减法',
    'topic_multiplication': '乘法',
    'adventure_title': '冒险故事',
    'adventure_sub': '开始一段充满数学的冒险！',
    'bedtime_title': '睡前故事',
    'bedtime_sub': '温柔的数学故事，祝你做个好梦',
    'characters_title': '🎭 故事角色',
    'dialog_success_title': '🎉 太棒了！',
    'dialog_success_body': '答对了！',
    'dialog_continue': '继续',
    'dialog_hint_title': '💡 提示',
    'try_again': '再试一次',
    'math_challenge_btn': '数学挑战！',
    'math_time': '🧮 数学时间！',
    'nav_back': '返回',
    'nav_forward': '下一步',
    'nav_finish': '完成',
    'chapter_start': '开始',
    'fairy_name': '数字小精灵',
  },
  'id': {
    'title': 'Pencerita',
    'loading': 'Cerita sedang disiapkan...',
    'magic': '✨ Sedang menyulap ✨',
    'greeting': 'Halo {childName}!',
    'pick_topic': '📚 Pilih topik cerita',
    'topic_addition': 'Penjumlahan',
    'topic_subtraction': 'Pengurangan',
    'topic_multiplication': 'Perkalian',
    'adventure_title': 'Cerita petualangan',
    'adventure_sub': 'Mulai petualangan penuh matematika!',
    'bedtime_title': 'Cerita sebelum tidur',
    'bedtime_sub': 'Cerita matematika yang lembut untuk mimpi indah',
    'characters_title': '🎭 Tokoh cerita',
    'dialog_success_title': '🎉 Hebat!',
    'dialog_success_body': 'Benar!',
    'dialog_continue': 'Lanjut',
    'dialog_hint_title': '💡 Petunjuk',
    'try_again': 'Coba lagi',
    'math_challenge_btn': 'Tantangan matematika!',
    'math_time': '🧮 Waktu matematika!',
    'nav_back': 'Kembali',
    'nav_forward': 'Berikutnya',
    'nav_finish': 'Selesai',
    'chapter_start': 'Awal',
    'fairy_name': 'Peri angka',
  },
  'ku': {
    'title': 'Çîrokbêj',
    'loading': 'Çîrok amade dibe...',
    'magic': '✨ Sihir tê kirin ✨',
    'greeting': 'Silav {childName}!',
    'pick_topic': '📚 Mijara çîrokê hilbijêre',
    'topic_addition': 'Komkirin',
    'topic_subtraction': 'Kêmkirin',
    'topic_multiplication': 'Lêkçarî',
    'adventure_title': 'Çîroka serpêhatiyê',
    'adventure_sub': 'Serpêhatiyekê bi matematîkê dest pê bike!',
    'bedtime_title': 'Çîroka xewê',
    'bedtime_sub': 'Çîrokeke matematîkê yê nerm ji bo xewnên şîrîn',
    'characters_title': '🎭 Personajên çîrokê',
    'dialog_success_title': '🎉 Bijî!',
    'dialog_success_body': 'Rast e!',
    'dialog_continue': 'Bidomîne',
    'dialog_hint_title': '💡 Rêber',
    'try_again': 'Dîsa biceribîne',
    'math_challenge_btn': 'Şertgirîya matematîkê!',
    'math_time': '🧮 Dema matematîkê!',
    'nav_back': 'Paş',
    'nav_forward': 'Pêş',
    'nav_finish': 'Qediya',
    'chapter_start': 'Destpêk',
    'fairy_name': 'Pêri hejmaran',
  },
  'es': {
    'title': 'Cuentacuentos',
    'loading': 'Preparando tu historia...',
    'magic': '✨ Haciendo magia ✨',
    'greeting': '¡Hola {childName}!',
    'pick_topic': '📚 Elige un tema',
    'topic_addition': 'Suma',
    'topic_subtraction': 'Resta',
    'topic_multiplication': 'Multiplicación',
    'adventure_title': 'Historia de aventuras',
    'adventure_sub': '¡Comienza una aventura llena de mates!',
    'bedtime_title': 'Cuento para dormir',
    'bedtime_sub': 'Un cuento matemático suave para dulces sueños',
    'characters_title': '🎭 Personajes',
    'dialog_success_title': '🎉 ¡Genial!',
    'dialog_success_body': '¡Correcto!',
    'dialog_continue': 'Continuar',
    'dialog_hint_title': '💡 Pista',
    'try_again': 'Intentar otra vez',
    'math_challenge_btn': '¡Reto de mates!',
    'math_time': '🧮 ¡Hora de mates!',
    'nav_back': 'Atrás',
    'nav_forward': 'Siguiente',
    'nav_finish': 'Terminar',
    'chapter_start': 'Comienzo',
    'fairy_name': 'Hada de los números',
  },
  'fr': {
    'title': 'Conteur d’histoires',
    'loading': 'Préparation de l’histoire...',
    'magic': '✨ Un peu de magie ✨',
    'greeting': 'Bonjour {childName} !',
    'pick_topic': '📚 Choisis un sujet',
    'topic_addition': 'Addition',
    'topic_subtraction': 'Soustraction',
    'topic_multiplication': 'Multiplication',
    'adventure_title': 'Histoire d’aventure',
    'adventure_sub': 'Pars pour une aventure pleine de maths !',
    'bedtime_title': 'Histoire du soir',
    'bedtime_sub': 'Une douce histoire de maths pour de beaux rêves',
    'characters_title': '🎭 Personnages',
    'dialog_success_title': '🎉 Bravo !',
    'dialog_success_body': 'Bonne réponse !',
    'dialog_continue': 'Continuer',
    'dialog_hint_title': '💡 Indice',
    'try_again': 'Réessayer',
    'math_challenge_btn': 'Défi maths !',
    'math_time': '🧮 C’est l’heure des maths !',
    'nav_back': 'Retour',
    'nav_forward': 'Suivant',
    'nav_finish': 'Terminer',
    'chapter_start': 'Début',
    'fairy_name': 'Fée des nombres',
  },
  'ru': {
    'title': 'Сказитель',
    'loading': 'Готовим историю...',
    'magic': '✨ Творим волшебство ✨',
    'greeting': 'Привет, {childName}!',
    'pick_topic': '📚 Выбери тему сказки',
    'topic_addition': 'Сложение',
    'topic_subtraction': 'Вычитание',
    'topic_multiplication': 'Умножение',
    'adventure_title': 'Приключение',
    'adventure_sub': 'Начни математическое приключение!',
    'bedtime_title': 'Сказка на ночь',
    'bedtime_sub': 'Спокойная математическая сказка перед сном',
    'characters_title': '🎭 Герои',
    'dialog_success_title': '🎉 Отлично!',
    'dialog_success_body': 'Верно!',
    'dialog_continue': 'Дальше',
    'dialog_hint_title': '💡 Подсказка',
    'try_again': 'Ещё раз',
    'math_challenge_btn': 'Математический вызов!',
    'math_time': '🧮 Время математики!',
    'nav_back': 'Назад',
    'nav_forward': 'Вперёд',
    'nav_finish': 'Готово',
    'chapter_start': 'Начало',
    'fairy_name': 'Фея чисел',
  },
  'ja': {
    'title': 'ストーリーテラー',
    'loading': 'お話を準備しています…',
    'magic': '✨ 魔法をかけています ✨',
    'greeting': 'こんにちは、{childName}！',
    'pick_topic': '📚 テーマを選ぼう',
    'topic_addition': 'たしざん',
    'topic_subtraction': 'ひきざん',
    'topic_multiplication': 'かけざん',
    'adventure_title': 'ぼうけんのお話',
    'adventure_sub': 'すうがくのぼうけんをはじめよう！',
    'bedtime_title': 'ねるまえのお話',
    'bedtime_sub': 'やさしいすうがくのお話でいいゆめを',
    'characters_title': '🎭 キャラクター',
    'dialog_success_title': '🎉 すごい！',
    'dialog_success_body': 'せいかい！',
    'dialog_continue': 'つぎへ',
    'dialog_hint_title': '💡 ヒント',
    'try_again': 'もういちど',
    'math_challenge_btn': 'すうがくチャレンジ！',
    'math_time': '🧮 すうがくのじかん！',
    'nav_back': 'もどる',
    'nav_forward': 'すすむ',
    'nav_finish': 'おわり',
    'chapter_start': 'はじまり',
    'fairy_name': 'かずのようせい',
  },
  'ko': {
    'title': '이야기 꾼',
    'loading': '이야기를 준비하고 있어요...',
    'magic': '✨ 마법을 만드는 중 ✨',
    'greeting': '안녕, {childName}!',
    'pick_topic': '📚 이야기 주제 고르기',
    'topic_addition': '덧셈',
    'topic_subtraction': '뺄셈',
    'topic_multiplication': '곱셈',
    'adventure_title': '모험 이야기',
    'adventure_sub': '수학 가득 모험을 시작해요!',
    'bedtime_title': '잠자리 이야기',
    'bedtime_sub': '달콤한 꿈을 위한 부드러운 수학 이야기',
    'characters_title': '🎭 등장인물',
    'dialog_success_title': '🎉 잘했어요!',
    'dialog_success_body': '정답이에요!',
    'dialog_continue': '계속',
    'dialog_hint_title': '💡 힌트',
    'try_again': '다시 시도',
    'math_challenge_btn': '수학 도전!',
    'math_time': '🧮 수학 시간!',
    'nav_back': '뒤로',
    'nav_forward': '다음',
    'nav_finish': '끝',
    'chapter_start': '시작',
    'fairy_name': '숫자 요정',
  },
  'hi': {
    'title': 'कहानी सुनाने वाला',
    'loading': 'कहानी तैयार हो रही है...',
    'magic': '✨ जादू हो रहा है ✨',
    'greeting': 'नमस्ते {childName}!',
    'pick_topic': '📚 कहानी का विषय चुनें',
    'topic_addition': 'जोड़',
    'topic_subtraction': 'घटाव',
    'topic_multiplication': 'गुणा',
    'adventure_title': 'साहसिक कहानी',
    'adventure_sub': 'गणित से भरा एक रोमांच शुरू करें!',
    'bedtime_title': 'सोने से पहले की कहानी',
    'bedtime_sub': 'मीठे सपनों के लिए एक हल्की गणित कहानी',
    'characters_title': '🎭 पात्र',
    'dialog_success_title': '🎉 शाबाश!',
    'dialog_success_body': 'सही जवाब!',
    'dialog_continue': 'आगे',
    'dialog_hint_title': '💡 संकेत',
    'try_again': 'फिर कोशिश करें',
    'math_challenge_btn': 'गणित चुनौती!',
    'math_time': '🧮 गणित का समय!',
    'nav_back': 'पीछे',
    'nav_forward': 'आगे',
    'nav_finish': 'समाप्त',
    'chapter_start': 'शुरुआत',
    'fairy_name': 'अंक परी',
  },
  'ur': {
    'title': 'کہانی سنانے والا',
    'loading': 'کہانی تیار ہو رہی ہے...',
    'magic': '✨ جادو ہو رہا ہے ✨',
    'greeting': 'سلام {childName}!',
    'pick_topic': '📚 کہانی کا موضوع منتخب کریں',
    'topic_addition': 'جمع',
    'topic_subtraction': 'تفریق',
    'topic_multiplication': 'ضرب',
    'adventure_title': 'مہم جوئی کی کہانی',
    'adventure_sub': 'ریاضی سے بھرپور مہم جوئی شروع کریں!',
    'bedtime_title': 'سونے سے پہلے کی کہانی',
    'bedtime_sub': 'میٹھے خوابوں کے لیے نرم ریاضی کی کہانی',
    'characters_title': '🎭 کردار',
    'dialog_success_title': '🎉 زبردست!',
    'dialog_success_body': 'درست!',
    'dialog_continue': 'جاری رکھیں',
    'dialog_hint_title': '💡 اشارہ',
    'try_again': 'دوبارہ کوشش',
    'math_challenge_btn': 'ریاضی چیلنج!',
    'math_time': '🧮 ریاضی کا وقت!',
    'nav_back': 'واپس',
    'nav_forward': 'آگے',
    'nav_finish': 'ختم',
    'chapter_start': 'آغاز',
    'fairy_name': 'نمبروں کی پری',
  },
  'pt': {
    'title': 'Contador de histórias',
    'loading': 'Preparando a história...',
    'magic': '✨ Fazendo mágica ✨',
    'greeting': 'Olá, {childName}!',
    'pick_topic': '📚 Escolha o tema',
    'topic_addition': 'Adição',
    'topic_subtraction': 'Subtração',
    'topic_multiplication': 'Multiplicação',
    'adventure_title': 'História de aventura',
    'adventure_sub': 'Comece uma aventura cheia de matemática!',
    'bedtime_title': 'História para dormir',
    'bedtime_sub': 'Uma história matemática gentil para bons sonhos',
    'characters_title': '🎭 Personagens',
    'dialog_success_title': '🎉 Muito bem!',
    'dialog_success_body': 'Correto!',
    'dialog_continue': 'Continuar',
    'dialog_hint_title': '💡 Dica',
    'try_again': 'Tentar de novo',
    'math_challenge_btn': 'Desafio de matemática!',
    'math_time': '🧮 Hora da matemática!',
    'nav_back': 'Voltar',
    'nav_forward': 'Próximo',
    'nav_finish': 'Concluir',
    'chapter_start': 'Começo',
    'fairy_name': 'Fada dos números',
  },
  'it': {
    'title': 'Narratore',
    'loading': 'Preparo la storia...',
    'magic': '✨ Un po’ di magia ✨',
    'greeting': 'Ciao {childName}!',
    'pick_topic': '📚 Scegli l’argomento',
    'topic_addition': 'Addizione',
    'topic_subtraction': 'Sottrazione',
    'topic_multiplication': 'Moltiplicazione',
    'adventure_title': 'Storia d’avventura',
    'adventure_sub': 'Inizia un’avventura piena di matematica!',
    'bedtime_title': 'Storia della buonanotte',
    'bedtime_sub': 'Una dolce storia di matematica per sogni d’oro',
    'characters_title': '🎭 Personaggi',
    'dialog_success_title': '🎉 Grande!',
    'dialog_success_body': 'Giusto!',
    'dialog_continue': 'Continua',
    'dialog_hint_title': '💡 Suggerimento',
    'try_again': 'Riprova',
    'math_challenge_btn': 'Sfida di matematica!',
    'math_time': '🧮 Ora di matematica!',
    'nav_back': 'Indietro',
    'nav_forward': 'Avanti',
    'nav_finish': 'Fine',
    'chapter_start': 'Inizio',
    'fairy_name': 'Fata dei numeri',
  },
  'pl': {
    'title': 'Gawędziarz',
    'loading': 'Przygotowuję opowieść...',
    'magic': '✨ Robię magię ✨',
    'greeting': 'Cześć, {childName}!',
    'pick_topic': '📚 Wybierz temat',
    'topic_addition': 'Dodawanie',
    'topic_subtraction': 'Odejmowanie',
    'topic_multiplication': 'Mnożenie',
    'adventure_title': 'Opowieść przygodowa',
    'adventure_sub': 'Rozpocznij przygodę pełną matematyki!',
    'bedtime_title': 'Bajka na dobranoc',
    'bedtime_sub': 'Łagodna matematyczna bajka na słodkie sny',
    'characters_title': '🎭 Postacie',
    'dialog_success_title': '🎉 Świetnie!',
    'dialog_success_body': 'Dobrze!',
    'dialog_continue': 'Dalej',
    'dialog_hint_title': '💡 Podpowiedź',
    'try_again': 'Spróbuj ponownie',
    'math_challenge_btn': 'Wyzwanie matematyczne!',
    'math_time': '🧮 Czas na matematykę!',
    'nav_back': 'Wstecz',
    'nav_forward': 'Dalej',
    'nav_finish': 'Koniec',
    'chapter_start': 'Początek',
    'fairy_name': 'Wróżka liczb',
  },
};

const Map<String, Map<String, String>> _chars = {
  'tr': {'squirrel': 'Sayı sincabı', 'owl': 'Baykuş', 'cat': 'Kedi', 'role_helper': 'yardımcı', 'role_mentor': 'akıl hocası', 'role_friend': 'arkadaş'},
  'en': {'squirrel': 'Number squirrel', 'owl': 'Owl', 'cat': 'Cat', 'role_helper': 'helper', 'role_mentor': 'mentor', 'role_friend': 'friend'},
  'de': {'squirrel': 'Zahlen-Eichhörnchen', 'owl': 'Eule', 'cat': 'Katze', 'role_helper': 'Helfer', 'role_mentor': 'Mentor', 'role_friend': 'Freund'},
  'ar': {'squirrel': 'سنجاب الأرقام', 'owl': 'بومة', 'cat': 'قطة', 'role_helper': 'مساعد', 'role_mentor': 'مرشد', 'role_friend': 'صديق'},
  'fa': {'squirrel': 'سنجاب اعداد', 'owl': 'جغد', 'cat': 'گربه', 'role_helper': 'یار', 'role_mentor': 'راهنما', 'role_friend': 'دوست'},
  'zh': {'squirrel': '数字松鼠', 'owl': '猫头鹰', 'cat': '小猫', 'role_helper': '帮手', 'role_mentor': '导师', 'role_friend': '朋友'},
  'id': {'squirrel': 'Tupai angka', 'owl': 'Burung hantu', 'cat': 'Kucing', 'role_helper': 'pembantu', 'role_mentor': 'mentor', 'role_friend': 'teman'},
  'ku': {'squirrel': 'Sincaxê hejmaran', 'owl': 'Bayûs', 'cat': 'Pisîk', 'role_helper': 'alîkar', 'role_mentor': 'rêber', 'role_friend': 'heval'},
  'es': {'squirrel': 'Ardilla de números', 'owl': 'Búho', 'cat': 'Gato', 'role_helper': 'ayudante', 'role_mentor': 'mentor', 'role_friend': 'amigo'},
  'fr': {'squirrel': 'Écureuil des nombres', 'owl': 'Hibou', 'cat': 'Chat', 'role_helper': 'assistant', 'role_mentor': 'mentor', 'role_friend': 'ami'},
  'ru': {'squirrel': 'Белка чисел', 'owl': 'Сова', 'cat': 'Кот', 'role_helper': 'помощник', 'role_mentor': 'наставник', 'role_friend': 'друг'},
  'ja': {'squirrel': 'かずりす', 'owl': 'ふくろう', 'cat': 'ねこ', 'role_helper': 'ヘルパー', 'role_mentor': 'メンター', 'role_friend': 'ともだち'},
  'ko': {'squirrel': '숫자 다람쥐', 'owl': '부엉이', 'cat': '고양이', 'role_helper': '도우미', 'role_mentor': '멘토', 'role_friend': '친구'},
  'hi': {'squirrel': 'अंक गिलहरी', 'owl': 'उल्लू', 'cat': 'बिल्ली', 'role_helper': 'सहायक', 'role_mentor': 'गुरु', 'role_friend': 'दोस्त'},
  'ur': {'squirrel': 'نمبروں والا گلہری', 'owl': 'الو', 'cat': 'بلی', 'role_helper': 'مددگار', 'role_mentor': 'رہنما', 'role_friend': 'دوست'},
  'pt': {'squirrel': 'Esquilo dos números', 'owl': 'Coruja', 'cat': 'Gato', 'role_helper': 'ajudante', 'role_mentor': 'mentor', 'role_friend': 'amigo'},
  'it': {'squirrel': 'Scoiattolo dei numeri', 'owl': 'Gufo', 'cat': 'Gatto', 'role_helper': 'aiutante', 'role_mentor': 'mentore', 'role_friend': 'amico'},
  'pl': {'squirrel': 'Wiewiórka liczb', 'owl': 'Sowa', 'cat': 'Kot', 'role_helper': 'pomocnik', 'role_mentor': 'mentor', 'role_friend': 'przyjaciel'},
};

Map<String, List<StoryTemplate>> _makeStoryPack(_Tpl t) {
  return {
    'addition': [
      StoryTemplate(
        title: t.addPreTitle,
        ageGroup: 'preschool',
        chapters: [
          ChapterTemplate(
            title: t.addPreCh1Title,
            content: t.addPreCh1Content,
            image: '🍎',
            choices: [t.addPreCh1C1, t.addPreCh1C2],
          ),
          ChapterTemplate(
            title: t.addPreCh2Title,
            content: t.addPreCh2Content,
            image: '🧺',
            choices: [t.addPreCh2C1],
          ),
        ],
      ),
      StoryTemplate(
        title: t.addElemTitle,
        ageGroup: 'elementary',
        chapters: [
          ChapterTemplate(
            title: t.addElemCh1Title,
            content: t.addElemCh1Content,
            image: '🚀',
            choices: [t.addElemCh1C1],
          ),
        ],
      ),
      StoryTemplate(
        title: t.addAdvTitle,
        ageGroup: 'advanced',
        chapters: [
          ChapterTemplate(
            title: t.addAdvCh1Title,
            content: t.addAdvCh1Content,
            image: '🏆',
            choices: [t.addAdvCh1C1],
          ),
        ],
      ),
    ],
    'default': [
      StoryTemplate(
        title: t.defTitle,
        ageGroup: 'preschool',
        chapters: [
          ChapterTemplate(
            title: t.defCh1Title,
            content: t.defCh1Content,
            image: '☀️',
            choices: [t.defCh1C1],
          ),
        ],
      ),
    ],
  };
}

class _Tpl {
  final String addPreTitle;
  final String addPreCh1Title;
  final String addPreCh1Content;
  final String addPreCh1C1;
  final String addPreCh1C2;
  final String addPreCh2Title;
  final String addPreCh2Content;
  final String addPreCh2C1;
  final String addElemTitle;
  final String addElemCh1Title;
  final String addElemCh1Content;
  final String addElemCh1C1;
  final String addAdvTitle;
  final String addAdvCh1Title;
  final String addAdvCh1Content;
  final String addAdvCh1C1;
  final String defTitle;
  final String defCh1Title;
  final String defCh1Content;
  final String defCh1C1;

  const _Tpl({
    required this.addPreTitle,
    required this.addPreCh1Title,
    required this.addPreCh1Content,
    required this.addPreCh1C1,
    required this.addPreCh1C2,
    required this.addPreCh2Title,
    required this.addPreCh2Content,
    required this.addPreCh2C1,
    required this.addElemTitle,
    required this.addElemCh1Title,
    required this.addElemCh1Content,
    required this.addElemCh1C1,
    required this.addAdvTitle,
    required this.addAdvCh1Title,
    required this.addAdvCh1Content,
    required this.addAdvCh1C1,
    required this.defTitle,
    required this.defCh1Title,
    required this.defCh1Content,
    required this.defCh1C1,
  });
}

final Map<String, Map<String, List<StoryTemplate>>> _templates = {
  'tr': _makeStoryPack(const _Tpl(
    addPreTitle: '{childName} ve Kayıp Elmalar',
    addPreCh1Title: 'Elma Bahçesi',
    addPreCh1Content: 'Bir gün {childName}, elma bahçesine gitti. Ağaçta güzel elmalar vardı...',
    addPreCh1C1: 'Elmaları topla',
    addPreCh1C2: 'Bekle',
    addPreCh2Title: 'Toplama Zamanı',
    addPreCh2Content: 'Birinci ağaçtan 3 elma, ikinci ağaçtan 4 elma topladı. Kaç elma oldu?',
    addPreCh2C1: 'Hesapla',
    addElemTitle: '{childName} ve Yıldız Toplama',
    addElemCh1Title: 'Gökyüzü Macerası',
    addElemCh1Content: '{childName} uzay gemisine bindi ve yıldız toplamaya çıktı...',
    addElemCh1C1: 'Uçuşa başla',
    addAdvTitle: '{childName}: Matematik Şampiyonu',
    addAdvCh1Title: 'Turnuva',
    addAdvCh1Content: 'Büyük matematik turnuvasında {childName} yarışmaya hazır...',
    addAdvCh1C1: 'Yarışmaya katıl',
    defTitle: '{childName}\'ın Matematik Macerası',
    defCh1Title: 'Yeni Bir Gün',
    defCh1Content: 'Güneşli bir sabah, {childName} yeni bir maceraya atıldı...',
    defCh1C1: 'Başla',
  )),
  'en': _makeStoryPack(const _Tpl(
    addPreTitle: '{childName} and the Lost Apples',
    addPreCh1Title: 'The Apple Orchard',
    addPreCh1Content: 'One day {childName} went to the apple orchard. Shiny apples hung from the trees...',
    addPreCh1C1: 'Pick the apples',
    addPreCh1C2: 'Wait',
    addPreCh2Title: 'Time to Add',
    addPreCh2Content: 'From the first tree came 3 apples, from the second 4 apples. How many apples altogether?',
    addPreCh2C1: 'Count',
    addElemTitle: '{childName} and the Star Collectors',
    addElemCh1Title: 'Sky Adventure',
    addElemCh1Content: '{childName} climbed into a spaceship to gather stars across the sky...',
    addElemCh1C1: 'Launch',
    addAdvTitle: '{childName}: Math Champion',
    addAdvCh1Title: 'The Tournament',
    addAdvCh1Content: 'At the big math tournament, {childName} is ready to compete...',
    addAdvCh1C1: 'Join the match',
    defTitle: '{childName}\'s Math Adventure',
    defCh1Title: 'A New Day',
    defCh1Content: 'On a sunny morning, {childName} set off on a brand-new adventure...',
    defCh1C1: 'Begin',
  )),
  'de': _makeStoryPack(const _Tpl(
    addPreTitle: '{childName} und die verlorenen Äpfel',
    addPreCh1Title: 'Apfelgarten',
    addPreCh1Content: 'Eines Tages ging {childName} in den Apfelgarten. Die Äpfel leuchteten rot und rund...',
    addPreCh1C1: 'Äpfel pflücken',
    addPreCh1C2: 'Warten',
    addPreCh2Title: 'Zeit zum Addieren',
    addPreCh2Content: 'Vom ersten Baum kamen 3 Äpfel, vom zweiten 4. Wie viele sind es zusammen?',
    addPreCh2C1: 'Rechnen',
    addElemTitle: '{childName} und die Sternsammler',
    addElemCh1Title: 'Abenteuer am Himmel',
    addElemCh1Content: '{childName} stieg ins Raumschiff, um Sterne zu sammeln...',
    addElemCh1C1: 'Abflug',
    addAdvTitle: '{childName}: Mathe-Meister',
    addAdvCh1Title: 'Das Turnier',
    addAdvCh1Content: 'Beim großen Matheturnier ist {childName} bereit anzutreten...',
    addAdvCh1C1: 'Mitmachen',
    defTitle: '{childName}s Mathe-Abenteuer',
    defCh1Title: 'Ein neuer Tag',
    defCh1Content: 'An einem sonnigen Morgen brach {childName} zu einem neuen Abenteuer auf...',
    defCh1C1: 'Los',
  )),
  'ar': _makeStoryPack(const _Tpl(
    addPreTitle: '{childName} والتفاح الضائع',
    addPreCh1Title: 'بستان التفاح',
    addPreCh1Content: 'في يوم من الأيام ذهب {childName} إلى بستان التفاح. كانت هناك تفاحات جميلة على الأشجار...',
    addPreCh1C1: 'اجمع التفاح',
    addPreCh1C2: 'انتظر',
    addPreCh2Title: 'وقت الجمع',
    addPreCh2Content: 'من الشجرة الأولى 3 تفاحات ومن الثانية 4. كم عدد التفاحات؟',
    addPreCh2C1: 'احسب',
    addElemTitle: '{childName} وجمع النجوم',
    addElemCh1Title: 'مغامرة في السماء',
    addElemCh1Content: 'صعد {childName} إلى سفينة فضاء ليجمع النجوم في السماء...',
    addElemCh1C1: 'انطلق',
    addAdvTitle: '{childName}: بطل الرياضيات',
    addAdvCh1Title: 'البطولة',
    addAdvCh1Content: 'في بطولة الرياضيات الكبرى، {childName} مستعد للمنافسة...',
    addAdvCh1C1: 'شارك',
    defTitle: 'مغامرة {childName} في الرياضيات',
    defCh1Title: 'يوم جديد',
    defCh1Content: 'في صباح مشمس انطلق {childName} في مغامرة جديدة...',
    defCh1C1: 'ابدأ',
  )),
  'fa': _makeStoryPack(const _Tpl(
    addPreTitle: '{childName} و سیب‌های گمشده',
    addPreCh1Title: 'باغ سیب',
    addPreCh1Content: 'روزی {childName} به باغ سیب رفت. سیب‌های زیبا روی درخت‌ها بود...',
    addPreCh1C1: 'سیب‌ها را بچین',
    addPreCh1C2: 'صبر کن',
    addPreCh2Title: 'وقت جمع کردن',
    addPreCh2Content: 'از درخت اول ۳ سیب و از دوم ۴ سیب. جمعاً چند سیب؟',
    addPreCh2C1: 'بشمار',
    addElemTitle: '{childName} و جمع‌آوری ستاره‌ها',
    addElemCh1Title: 'ماجرای آسمان',
    addElemCh1Content: '{childName} سوار فضاپیپ شد تا ستاره‌ها را جمع کند...',
    addElemCh1C1: 'پرواز',
    addAdvTitle: '{childName}: قهرمان ریاضی',
    addAdvCh1Title: 'مسابقه',
    addAdvCh1Content: 'در مسابقه بزرگ ریاضی، {childName} آماده است...',
    addAdvCh1C1: 'شرکت کن',
    defTitle: 'ماجرای ریاضی {childName}',
    defCh1Title: 'روز تازه',
    defCh1Content: 'در صبح آفتابی، {childName} به ماجرای تازه رفت...',
    defCh1C1: 'شروع',
  )),
  'zh': _makeStoryPack(const _Tpl(
    addPreTitle: '{childName}和丢失的苹果',
    addPreCh1Title: '苹果园',
    addPreCh1Content: '一天，{childName}来到苹果园。树上挂着漂亮的苹果……',
    addPreCh1C1: '摘苹果',
    addPreCh1C2: '等一下',
    addPreCh2Title: '加法时间',
    addPreCh2Content: '第一棵树上有3个苹果，第二棵有4个。一共有多少个？',
    addPreCh2C1: '算一算',
    addElemTitle: '{childName}收集星星',
    addElemCh1Title: '天空冒险',
    addElemCh1Content: '{childName}坐上飞船去收集天上的星星……',
    addElemCh1C1: '出发',
    addAdvTitle: '{childName}：数学冠军',
    addAdvCh1Title: '比赛',
    addAdvCh1Content: '在数学大赛上，{childName}准备登场……',
    addAdvCh1C1: '参加',
    defTitle: '{childName}的数学冒险',
    defCh1Title: '新的一天',
    defCh1Content: '阳光明媚的早晨，{childName}踏上了新的冒险……',
    defCh1C1: '开始',
  )),
  'id': _makeStoryPack(const _Tpl(
    addPreTitle: '{childName} dan apel yang hilang',
    addPreCh1Title: 'Kebun apel',
    addPreCh1Content: 'Suatu hari {childName} pergi ke kebun apel. Ada apel merah di pohon...',
    addPreCh1C1: 'Petik apel',
    addPreCh1C2: 'Tunggu',
    addPreCh2Title: 'Waktu menjumlahkan',
    addPreCh2Content: 'Dari pohon pertama 3 apel, dari yang kedua 4 apel. Berapa jumlahnya?',
    addPreCh2C1: 'Hitung',
    addElemTitle: '{childName} dan pengumpul bintang',
    addElemCh1Title: 'Petualangan langit',
    addElemCh1Content: '{childName} naik pesawat ruang angkasa untuk mengumpulkan bintang...',
    addElemCh1C1: 'Terbang',
    addAdvTitle: '{childName}: juara matematika',
    addAdvCh1Title: 'Turnamen',
    addAdvCh1Content: 'Di turnamen matematika besar, {childName} siap bertanding...',
    addAdvCh1C1: 'Ikut',
    defTitle: 'Petualangan matematika {childName}',
    defCh1Title: 'Hari baru',
    defCh1Content: 'Di pagi yang cerah, {childName} memulai petualangan baru...',
    defCh1C1: 'Mulai',
  )),
  'ku': _makeStoryPack(const _Tpl(
    addPreTitle: '{childName} û sêvên winda',
    addPreCh1Title: 'Baxçeya sêvan',
    addPreCh1Content: 'Rojekê {childName} çû baxçeya sêvan. Li daristan sêvên xweş hebûn...',
    addPreCh1C1: 'Sêvan kom bike',
    addPreCh1C2: 'Bisekine',
    addPreCh2Title: 'Dema komkirinê',
    addPreCh2Content: 'Ji darê yekem 3 sêv, ji ya duyem 4 sêv. Bi tevahî çend sêv in?',
    addPreCh2C1: 'Hesab bike',
    addElemTitle: '{childName} û komkirina stêrkan',
    addElemCh1Title: 'Serpêhatiya ezmanê',
    addElemCh1Content: '{childName} ket keştiya fezayê da ku stêrkan kom bike...',
    addElemCh1C1: 'Dest pê bike',
    addAdvTitle: '{childName}: şampiyona matematîkê',
    addAdvCh1Title: 'Pêşbazî',
    addAdvCh1Content: 'Di pêşbaziya mezin a matematîkê de {childName} amade ye...',
    addAdvCh1C1: 'Beşdar bibe',
    defTitle: 'Serpêhatiya matematîkê ya {childName}',
    defCh1Title: 'Roja nû',
    defCh1Content: 'Di sibehê tavdar de {childName} derket ser rêya serpêhatiyê...',
    defCh1C1: 'Dest pê bike',
  )),
  'es': _makeStoryPack(const _Tpl(
    addPreTitle: '{childName} y las manzanas perdidas',
    addPreCh1Title: 'El huerto',
    addPreCh1Content: 'Un día {childName} fue al huerto de manzanas. Los árboles estaban llenos de fruta...',
    addPreCh1C1: 'Recoge manzanas',
    addPreCh1C2: 'Espera',
    addPreCh2Title: 'Hora de sumar',
    addPreCh2Content: 'Del primer árbol 3 manzanas y del segundo 4. ¿Cuántas hay en total?',
    addPreCh2C1: 'Cuenta',
    addElemTitle: '{childName} y las estrellas',
    addElemCh1Title: 'Aventura en el cielo',
    addElemCh1Content: '{childName} subió a una nave para recolectar estrellas...',
    addElemCh1C1: 'Despegar',
    addAdvTitle: '{childName}: campeón de mates',
    addAdvCh1Title: 'El torneo',
    addAdvCh1Content: 'En el gran torneo de mates, {childName} está listo...',
    addAdvCh1C1: 'Participar',
    defTitle: 'La aventura matemática de {childName}',
    defCh1Title: 'Un día nuevo',
    defCh1Content: 'En una mañana soleada, {childName} empezó una nueva aventura...',
    defCh1C1: 'Empezar',
  )),
  'fr': _makeStoryPack(const _Tpl(
    addPreTitle: '{childName} et les pommes perdues',
    addPreCh1Title: 'Le verger',
    addPreCh1Content: 'Un jour {childName} est allé au verger. De belles pommes brillaient dans les arbres...',
    addPreCh1C1: 'Cueillir',
    addPreCh1C2: 'Attendre',
    addPreCh2Title: 'L’heure d’additionner',
    addPreCh2Content: 'Du premier arbre 3 pommes, du second 4. Combien au total ?',
    addPreCh2C1: 'Compter',
    addElemTitle: '{childName} et les étoiles',
    addElemCh1Title: 'Aventure dans le ciel',
    addElemCh1Content: '{childName} monte dans un vaisseau pour collecter des étoiles...',
    addElemCh1C1: 'Décollage',
    addAdvTitle: '{childName} : champion des maths',
    addAdvCh1Title: 'Le tournoi',
    addAdvCh1Content: 'Au grand tournoi de maths, {childName} est prêt à jouer...',
    addAdvCh1C1: 'Participer',
    defTitle: 'L’aventure maths de {childName}',
    defCh1Title: 'Un nouveau jour',
    defCh1Content: 'Un matin ensoleillé, {childName} part pour une nouvelle aventure...',
    defCh1C1: 'Commencer',
  )),
  'ru': _makeStoryPack(const _Tpl(
    addPreTitle: '{childName} и потерянные яблоки',
    addPreCh1Title: 'Яблоневый сад',
    addPreCh1Content: 'Однажды {childName} пошёл в яблоневый сад. На деревьях красовались яблоки...',
    addPreCh1C1: 'Собрать яблоки',
    addPreCh1C2: 'Подождать',
    addPreCh2Title: 'Пора складывать',
    addPreCh2Content: 'С первого дерева 3 яблока, со второго 4. Сколько всего?',
    addPreCh2C1: 'Считать',
    addElemTitle: '{childName} и звёздные собиратели',
    addElemCh1Title: 'Небесное приключение',
    addElemCh1Content: '{childName} сел в корабль, чтобы собрать звёзды...',
    addElemCh1C1: 'Старт',
    addAdvTitle: '{childName} — чемпион по математике',
    addAdvCh1Title: 'Турнир',
    addAdvCh1Content: 'На большом турнире {childName} готов соревноваться...',
    addAdvCh1C1: 'Участвовать',
    defTitle: 'Математическое приключение {childName}',
    defCh1Title: 'Новый день',
    defCh1Content: 'В солнечное утро {childName} отправился в новое приключение...',
    defCh1C1: 'Начать',
  )),
  'ja': _makeStoryPack(const _Tpl(
    addPreTitle: '{childName}となくしたりんご',
    addPreCh1Title: 'りんごばたけ',
    addPreCh1Content: 'ある日、{childName}はりんごばたけへ。きれいなりんごがなっていました…',
    addPreCh1C1: 'りんごをひろう',
    addPreCh1C2: 'まつ',
    addPreCh2Title: 'たしざんのじかん',
    addPreCh2Content: '１本めから３こ、２本めから４こ。ぜんぶでいくつ？',
    addPreCh2C1: 'かぞえる',
    addElemTitle: '{childName}とほしあつめ',
    addElemCh1Title: 'そらのぼうけん',
    addElemCh1Content: '{childName}はふねにのってほしをあつめにいきます…',
    addElemCh1C1: 'しゅっぱつ',
    addAdvTitle: '{childName}、すうがくチャンピオン',
    addAdvCh1Title: 'たいかい',
    addAdvCh1Content: 'おおきなすうがくたいかいで、{childName}はじゅんびできました…',
    addAdvCh1C1: 'さんか',
    defTitle: '{childName}のすうがくぼうけん',
    defCh1Title: 'あたらしいひ',
    defCh1Content: 'はれたあさ、{childName}はあたらしいぼうけんにでかけました…',
    defCh1C1: 'はじめる',
  )),
  'ko': _makeStoryPack(const _Tpl(
    addPreTitle: '{childName}와 잃어버린 사과',
    addPreCh1Title: '사과밭',
    addPreCh1Content: '어느 날 {childName}이(가) 사과밭에 갔어요. 나무에 예쁜 사과가 열려 있었어요...',
    addPreCh1C1: '사과 따기',
    addPreCh1C2: '기다리기',
    addPreCh2Title: '더하기 시간',
    addPreCh2Content: '첫 나무에서 사과 3개, 둘째 나무에서 4개. 모두 몇 개일까요?',
    addPreCh2C1: '세어 보기',
    addElemTitle: '{childName}와 별 모으기',
    addElemCh1Title: '하늘 모험',
    addElemCh1Content: '{childName}이(가) 우주선에 타 별을 모으러 갔어요...',
    addElemCh1C1: '출발',
    addAdvTitle: '{childName}, 수학 챔피언',
    addAdvCh1Title: '대회',
    addAdvCh1Content: '큰 수학 대회에서 {childName}이(가) 준비됐어요...',
    addAdvCh1C1: '참가',
    defTitle: '{childName}의 수학 모험',
    defCh1Title: '새로운 하루',
    defCh1Content: '화창한 아침, {childName}이(가) 새 모험을 떠났어요...',
    defCh1C1: '시작',
  )),
  'hi': _makeStoryPack(const _Tpl(
    addPreTitle: '{childName} और खोए हुए सेब',
    addPreCh1Title: 'सेब का बाग',
    addPreCh1Content: 'एक दिन {childName} सेब के बाग में गया। पेड़ों पर सुंदर सेब थे...',
    addPreCh1C1: 'सेब चुनो',
    addPreCh1C2: 'रुको',
    addPreCh2Title: 'जोड़ने का समय',
    addPreCh2Content: 'पहले पेड़ से 3 सेब, दूसरे से 4। कुल कितने?',
    addPreCh2C1: 'गिनो',
    addElemTitle: '{childName} और तारे बटोरना',
    addElemCh1Title: 'आसमान की साहसिक कहानी',
    addElemCh1Content: '{childName} तारे इकट्ठा करने जहाज़ में चढ़ा...',
    addElemCh1C1: 'उड़ान',
    addAdvTitle: '{childName}: गणित चैंपियन',
    addAdvCh1Title: 'टूर्नामेंट',
    addAdvCh1Content: 'बड़े गणित टूर्नामेंट में {childName} तैयार है...',
    addAdvCh1C1: 'भाग लो',
    defTitle: '{childName} की गणित साहसिक कहानी',
    defCh1Title: 'नया दिन',
    defCh1Content: 'धूप वाली सुबह {childName} नई साहसिक यात्रा पर निकला...',
    defCh1C1: 'शुरू',
  )),
  'ur': _makeStoryPack(const _Tpl(
    addPreTitle: '{childName} اور گمشدہ سیب',
    addPreCh1Title: 'سیب کا باغ',
    addPreCh1Content: 'ایک دن {childName} سیب کے باغ میں گیا۔ درختوں پر خوبصورت سیب تھے...',
    addPreCh1C1: 'سیب چنیں',
    addPreCh1C2: 'انتظار',
    addPreCh2Title: 'جمع کا وقت',
    addPreCh2Content: 'پہلے درخت سے 3، دوسرے سے 4 سیب۔ کل کتنے؟',
    addPreCh2C1: 'گنیں',
    addElemTitle: '{childName} اور ستارے',
    addElemCh1Title: 'آسمان کی مہم',
    addElemCh1Content: '{childName} ستارے جمع کرنے جہاز میں چڑھا...',
    addElemCh1C1: 'اڑان',
    addAdvTitle: '{childName}: ریاضی چیمپئن',
    addAdvCh1Title: 'ٹورنامنٹ',
    addAdvCh1Content: 'بڑے ریاضی مقابلے میں {childName} تیار ہے...',
    addAdvCh1C1: 'حصہ لیں',
    defTitle: '{childName} کی ریاضی مہم',
    defCh1Title: 'نیا دن',
    defCh1Content: 'دھوپ والی صبح {childName} نئی مہم پر نکلا...',
    defCh1C1: 'شروع',
  )),
  'pt': _makeStoryPack(const _Tpl(
    addPreTitle: '{childName} e as maçãs perdidas',
    addPreCh1Title: 'O pomar',
    addPreCh1Content: 'Um dia {childName} foi ao pomar de maçãs. Havia maçãs lindas nas árvores...',
    addPreCh1C1: 'Colher maçãs',
    addPreCh1C2: 'Esperar',
    addPreCh2Title: 'Hora de somar',
    addPreCh2Content: 'Da primeira árvore 3 maçãs, da segunda 4. Quantas no total?',
    addPreCh2C1: 'Contar',
    addElemTitle: '{childName} e as estrelas',
    addElemCh1Title: 'Aventura no céu',
    addElemCh1Content: '{childName} entrou na nave para juntar estrelas...',
    addElemCh1C1: 'Decolar',
    addAdvTitle: '{childName}: campeão de matemática',
    addAdvCh1Title: 'O torneio',
    addAdvCh1Content: 'No grande torneio, {childName} está pronto...',
    addAdvCh1C1: 'Participar',
    defTitle: 'A aventura matemática de {childName}',
    defCh1Title: 'Um dia novo',
    defCh1Content: 'Numa manhã ensolarada, {childName} partiu numa nova aventura...',
    defCh1C1: 'Começar',
  )),
  'it': _makeStoryPack(const _Tpl(
    addPreTitle: '{childName} e le mele perdute',
    addPreCh1Title: 'Il frutteto',
    addPreCh1Content: 'Un giorno {childName} andò nel frutteto di mele. Sugli alberi c’erano belle mele...',
    addPreCh1C1: 'Raccogli le mele',
    addPreCh1C2: 'Aspetta',
    addPreCh2Title: 'Ora di addizionare',
    addPreCh2Content: 'Dal primo albero 3 mele, dal secondo 4. Quante in tutto?',
    addPreCh2C1: 'Conta',
    addElemTitle: '{childName} e le stelle',
    addElemCh1Title: 'Avventura nel cielo',
    addElemCh1Content: '{childName} sale su un’astronave per raccogliere stelle...',
    addElemCh1C1: 'Decollo',
    addAdvTitle: '{childName}: campione di matematica',
    addAdvCh1Title: 'Il torneo',
    addAdvCh1Content: 'Al grande torneo di matematica, {childName} è pronto...',
    addAdvCh1C1: 'Partecipa',
    defTitle: 'L’avventura di matematica di {childName}',
    defCh1Title: 'Un nuovo giorno',
    defCh1Content: 'In una mattina di sole, {childName} parte per una nuova avventura...',
    defCh1C1: 'Inizia',
  )),
  'pl': _makeStoryPack(const _Tpl(
    addPreTitle: '{childName} i zaginione jabłka',
    addPreCh1Title: 'Sad jabłoni',
    addPreCh1Content: 'Pewnego dnia {childName} poszedł do sadu. Na drzewach wisiały piękne jabłka...',
    addPreCh1C1: 'Zbierz jabłka',
    addPreCh1C2: 'Poczekaj',
    addPreCh2Title: 'Czas na dodawanie',
    addPreCh2Content: 'Z pierwszego drzewa 3 jabłka, z drugiego 4. Ile razem?',
    addPreCh2C1: 'Policz',
    addElemTitle: '{childName} i zbieranie gwiazd',
    addElemCh1Title: 'Przygoda na niebie',
    addElemCh1Content: '{childName} wsiada do statku, by zbierać gwiazdy...',
    addElemCh1C1: 'Start',
    addAdvTitle: '{childName}: mistrz matematyki',
    addAdvCh1Title: 'Turniej',
    addAdvCh1Content: 'Na wielkim turnieju {childName} jest gotowy...',
    addAdvCh1C1: 'Weź udział',
    defTitle: 'Matematyczna przygoda {childName}',
    defCh1Title: 'Nowy dzień',
    defCh1Content: 'W słoneczny poranek {childName} wyrusza w nową przygodę...',
    defCh1C1: 'Start',
  )),
};

// --- Günlük mesajlar (rastgele) ---
const Map<String, List<String>> _daily = {
  'tr': [
    '{childName}, bugün matematik macerasına hazır mısın? 🚀',
    'Harika! {streak} gündür arka arkaya giriş yaptın! 🔥',
    'Seviye {level}\'e ulaştın! Süper gidiyorsun! ⭐',
    '{childName}, sayılar seni bekliyor! 🔢',
    'Bugün yeni bir şeyler öğrenmeye ne dersin? 📚',
    'Matematik kahramanı {childName} sahneye! 🦸',
  ],
  'en': [
    '{childName}, ready for a math adventure today? 🚀',
    'Nice! You’ve logged in {streak} days in a row! 🔥',
    'You reached level {level}! You’re doing great! ⭐',
    '{childName}, the numbers are waiting for you! 🔢',
    'How about learning something new today? 📚',
    'Math hero {childName} takes the stage! 🦸',
  ],
  'de': [
    '{childName}, heute bereit für ein Mathe-Abenteuer? 🚀',
    'Super! Du bist {streak} Tage in Folge dabei! 🔥',
    'Level {level} geschafft! Weiter so! ⭐',
    '{childName}, die Zahlen warten auf dich! 🔢',
    'Wie wäre es heute mit etwas Neuem? 📚',
    'Mathe-Held {childName} ist da! 🦸',
  ],
  'ar': [
    '{childName}، هل أنت مستعد لمغامرة رياضية اليوم؟ 🚀',
    'رائع! لقد سجّلت دخولك {streak} أيام متتالية! 🔥',
    'وصلت إلى المستوى {level}! أحسنت! ⭐',
    '{childName}، الأرقام في انتظارك! 🔢',
    'ما رأيك أن تتعلم شيئًا جديدًا اليوم؟ 📚',
    'بطل الرياضيات {childName} يظهر! 🦸',
  ],
  'fa': [
    '{childName}، امروز برای ماجرای ریاضی آماده‌ای؟ 🚀',
    'عالی! {streak} روز پشت‌سرهم آمدی! 🔥',
    'به سطح {level} رسیدی! داری عالی پیش می‌روی! ⭐',
    '{childName}، اعداد منتظرند! 🔢',
    'امروز چیز تازه‌ای یاد بگیریم؟ 📚',
    'قهرمان ریاضی {childName}! 🦸',
  ],
  'zh': [
    '{childName}，今天准备好数学冒险了吗？🚀',
    '太棒了！你已经连续登录 {streak} 天！🔥',
    '你达到了第 {level} 级！继续加油！⭐',
    '{childName}，数字在等你！🔢',
    '今天学点新东西怎么样？📚',
    '数学小英雄 {childName} 登场！🦸',
  ],
  'id': [
    '{childName}, siap petualangan matematika hari ini? 🚀',
    'Keren! Kamu masuk {streak} hari berturut-turut! 🔥',
    'Kamu mencapai level {level}! Luar biasa! ⭐',
    '{childName}, angka menunggumu! 🔢',
    'Bagaimana kalau belajar hal baru hari ini? 📚',
    'Pahlawan matematika {childName}! 🦸',
  ],
  'ku': [
    '{childName}, îro amade ye ji bo serpêhatiya matematîkê? 🚀',
    'Ecêb! Te {streak} rojan li pey hev têketî! 🔥',
    'Te asta {level} gihîşt! Ber bi baş ve diçî! ⭐',
    '{childName}, hejmar li benda te ne! 🔢',
    'Îro tiştek nû fêr bibî? 📚',
    'Qahramana matematîkê {childName}! 🦸',
  ],
  'es': [
    '{childName}, ¿listo para una aventura de mates hoy? 🚀',
    '¡Genial! ¡Llevas {streak} días seguidos! 🔥',
    '¡Llegaste al nivel {level}! ¡Vas muy bien! ⭐',
    '{childName}, ¡los números te esperan! 🔢',
    '¿Qué tal aprender algo nuevo hoy? 📚',
    '¡El héroe de las mates, {childName}! 🦸',
  ],
  'fr': [
    '{childName}, prêt pour une aventure maths aujourd’hui ? 🚀',
    'Super ! Tu te connectes depuis {streak} jours d’affilée ! 🔥',
    'Tu as atteint le niveau {level} ! Continue ! ⭐',
    '{childName}, les nombres t’attendent ! 🔢',
    'Et si on apprenait quelque chose de nouveau ? 📚',
    'Le héros des maths, {childName} ! 🦸',
  ],
  'ru': [
    '{childName}, готов к математическому приключению сегодня? 🚀',
    'Класс! Ты заходишь {streak} дней подряд! 🔥',
    'Ты достиг уровня {level}! Так держать! ⭐',
    '{childName}, числа ждут тебя! 🔢',
    'Как насчёт выучить что-то новое сегодня? 📚',
    'Герой математики {childName}! 🦸',
  ],
  'ja': [
    '{childName}、きょうはすうがくのぼうけん、じゅんびできた？🚀',
    '{streak}にちれんぞくでログインだね！🔥',
    'レベル{level}にとうたつ！がんばってるね！⭐',
    '{childName}、すうじがまってるよ！🔢',
    'きょうはあたらしいことをまなんでみる？📚',
    'すうがくのヒーロー{childName}！🦸',
  ],
  'ko': [
    '{childName}, 오늘 수학 모험 갈 준비됐어요? 🚀',
    '멋져요! {streak}일 연속이에요! 🔥',
    '{level}레벨에 도달했어요! 잘하고 있어요! ⭐',
    '{childName}, 숫자들이 기다려요! 🔢',
    '오늘 새로운 걸 배워볼까요? 📚',
    '수학 영웅 {childName}! 🦸',
  ],
  'hi': [
    '{childName}, आज गणित की साहसिक यात्रा के लिए तैयार? 🚀',
    'शाबाश! {streak} दिन लगातार आए! 🔥',
    'स्तर {level} पर पहुँचे! बहुत अच्छा! ⭐',
    '{childName}, अंक इंतज़ार कर रहे हैं! 🔢',
    'आज कुछ नया सीखें? 📚',
    'गणित नायक {childName}! 🦸',
  ],
  'ur': [
    '{childName}, آج ریاضی کی مہم کے لیے تیار؟ 🚀',
    'زبردست! {streak} دن لگاتار! 🔥',
    'لیول {level} تک پہنچ گئے! شاباش! ⭐',
    '{childName}، اعداد انتظار میں ہیں! 🔢',
    'آج کچھ نیا سیکھیں? 📚',
    'ریاضی کا ہیرو {childName}! 🦸',
  ],
  'pt': [
    '{childName}, pronto para uma aventura de matemática hoje? 🚀',
    'Legal! {streak} dias seguidos! 🔥',
    'Chegou ao nível {level}! Muito bem! ⭐',
    '{childName}, os números esperam por você! 🔢',
    'Que tal aprender algo novo hoje? 📚',
    'Herói da matemática, {childName}! 🦸',
  ],
  'it': [
    '{childName}, pronto per un’avventura di matematica oggi? 🚀',
    'Grande! {streak} giorni di fila! 🔥',
    'Hai raggiunto il livello {level}! Continua così! ⭐',
    '{childName}, i numeri ti aspettano! 🔢',
    'Che ne dici di imparare qualcosa di nuovo? 📚',
    'Eroe della matematica {childName}! 🦸',
  ],
  'pl': [
    '{childName}, gotowy na matematyczną przygodę dziś? 🚀',
    'Super! {streak} dni z rzędu! 🔥',
    'Osiągnąłeś poziom {level}! Tak trzymaj! ⭐',
    '{childName}, liczby na ciebie czekają! 🔢',
    'Co powiesz na coś nowego dziś? 📚',
    'Bohater matematyki {childName}! 🦸',
  ],
};

const Map<String, Map<String, String>> _hints = {
  'tr': {
    'plus': 'İpucu: {n1} sayısından başla ve {n2} tane daha say',
    'minus': 'İpucu: {n1} sayısından {n2} tane geri say',
    'times': 'İpucu: {n1} sayısını {n2} kere topla',
    'default': 'Dikkatli düşün!',
  },
  'en': {
    'plus': 'Hint: start at {n1} and count {n2} more',
    'minus': 'Hint: from {n1}, count back {n2}',
    'times': 'Hint: add {n1} to itself {n2} times',
    'default': 'Think carefully!',
  },
  'de': {
    'plus': 'Tipp: beginne bei {n1} und zähle {n2} weiter',
    'minus': 'Tipp: von {n1} um {n2} zurückzählen',
    'times': 'Tipp: {n1} insgesamt {n2} mal addieren',
    'default': 'Denk gut nach!',
  },
  'ar': {
    'plus': 'تلميح: ابدأ من {n1} وعد {n2} إضافية',
    'minus': 'تلميح: من {n1} عد للخلف {n2}',
    'times': 'تلميح: أضف {n1} إلى نفسه {n2} مرات',
    'default': 'فكّر بعناية!',
  },
  'fa': {
    'plus': 'راهنما: از {n1} شروع کن و {n2} تا دیگر بشمار',
    'minus': 'راهنما: از {n1}، {n2} تا به عقب برگرد',
    'times': 'راهنما: {n1} را {n2} بار با خودش جمع کن',
    'default': 'با دقت فکر کن!',
  },
  'zh': {
    'plus': '提示：从{n1}开始再数{n2}个',
    'minus': '提示：从{n1}往回数{n2}个',
    'times': '提示：把{n1}加{n2}次',
    'default': '仔细想想！',
  },
  'id': {
    'plus': 'Petunjuk: mulai dari {n1}, lalu hitung {n2} lagi',
    'minus': 'Petunjuk: dari {n1}, mundur {n2}',
    'times': 'Petunjuk: jumlahkan {n1} sebanyak {n2} kali',
    'default': 'Berpikir pelan-pelan!',
  },
  'ku': {
    'plus': 'Rêber: ji {n1} dest pê bike û {n2} din jî bibe',
    'minus': 'Rêber: ji {n1} {n2} paş ve bibire',
    'times': 'Rêber: {n1} bi xwe re {n2} caran kom bike',
    'default': 'Bi baldarî bifikire!',
  },
  'es': {
    'plus': 'Pista: empieza en {n1} y cuenta {n2} más',
    'minus': 'Pista: desde {n1}, cuenta hacia atrás {n2}',
    'times': 'Pista: suma {n1} consigo mismo {n2} veces',
    'default': '¡Piensa con calma!',
  },
  'fr': {
    'plus': 'Indice : commence à {n1} et compte {n2} de plus',
    'minus': 'Indice : à partir de {n1}, recule de {n2}',
    'times': 'Indice : ajoute {n1} à lui-même {n2} fois',
    'default': 'Réfléchis bien !',
  },
  'ru': {
    'plus': 'Подсказка: начни с {n1} и прибавь {n2}',
    'minus': 'Подсказка: от {n1} отсчитай назад {n2}',
    'times': 'Подсказка: сложи {n1} само с собой {n2} раз',
    'default': 'Подумай хорошенько!',
  },
  'ja': {
    'plus': 'ヒント：{n1}から{n2}だけすすんでみよう',
    'minus': 'ヒント：{n1}から{n2}だけもどる',
    'times': 'ヒント：{n1}を{n2}かいたす',
    'default': 'よくかんがえてみて！',
  },
  'ko': {
    'plus': '힌트: {n1}에서 {n2}만큼 더 세어 봐요',
    'minus': '힌트: {n1}에서 {n2}만큼 거꾸로 세요',
    'times': '힌트: {n1}을(를) {n2}번 더해요',
    'default': '천천히 생각해 봐요!',
  },
  'hi': {
    'plus': 'संकेत: {n1} से शुरू करो और {n2} और गिनो',
    'minus': 'संकेत: {n1} से {n2} पीछे गिनो',
    'times': 'संकेत: {n1} को {n2} बार जोड़ो',
    'default': 'ध्यान से सोचो!',
  },
  'ur': {
    'plus': 'اشارہ: {n1} سے شروع کریں اور {n2} اور گنیں',
    'minus': 'اشارہ: {n1} سے {n2} پیچھے گنیں',
    'times': 'اشارہ: {n1} کو {n2} بار جمع کریں',
    'default': 'غور سے سوچیں!',
  },
  'pt': {
    'plus': 'Dica: comece em {n1} e conte mais {n2}',
    'minus': 'Dica: de {n1}, volte {n2}',
    'times': 'Dica: some {n1} com ele mesmo {n2} vezes',
    'default': 'Pense com calma!',
  },
  'it': {
    'plus': 'Suggerimento: parti da {n1} e conta altri {n2}',
    'minus': 'Suggerimento: da {n1}, torna indietro di {n2}',
    'times': 'Suggerimento: somma {n1} a se stesso {n2} volte',
    'default': 'Pensa con calma!',
  },
  'pl': {
    'plus': 'Podpowiedź: zacznij od {n1} i dodaj {n2}',
    'minus': 'Podpowiedź: od {n1} odejmij {n2}',
    'times': 'Podpowiedź: dodaj {n1} do siebie {n2} razy',
    'default': 'Pomyśl dokładnie!',
  },
};

const Map<String, Map<String, List<String>>> _contexts = {
  'tr': {
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
    'default': ['Matematik sorusu: {num1} ve {num2} sayılarını kullan.'],
  },
  'en': {
    'addition': [
      'You have {num1} apples in your basket. Your friend gives you {num2} more.',
      '{num1} birds sit in a tree. {num2} more birds arrive.',
      '{num1} kids play in the park. {num2} more kids join.',
    ],
    'subtraction': [
      'You had {num1} candies in a box. You ate {num2}.',
      '{num1} butterflies flew in the garden. {num2} flew away.',
      'You had {num1} balloons. {num2} popped.',
    ],
    'multiplication': [
      'On {num1} plates there are {num2} cookies each.',
      'Each of {num1} cars has {num2} wheels.',
      'Each of {num1} flowers has {num2} petals.',
    ],
    'default': ['Math puzzle: use {num1} and {num2}.'],
  },
  'de': {
    'addition': [
      'Du hast {num1} Äpfel im Korb. Dein Freund gibt dir {num2} mehr.',
      '{num1} Vögel sitzen im Baum. {num2} weitere kommen.',
      '{num1} Kinder spielen im Park. {num2} kommen dazu.',
    ],
    'subtraction': [
      'Du hattest {num1} Bonbons. Du isst {num2}.',
      '{num1} Schmetterlinge flogen. {num2} flogen weg.',
      'Du hattest {num1} Luftballons. {num2} platzten.',
    ],
    'multiplication': [
      'Auf {num1} Tellern liegen je {num2} Kekse.',
      'Jedes der {num1} Autos hat {num2} Räder.',
      'Jede der {num1} Blumen hat {num2} Blätter.',
    ],
    'default': ['Mathe-Rätsel: nutze {num1} und {num2}.'],
  },
  'ar': {
    'addition': [
      'لديك {num1} تفاحة في السلة. صديقك يعطيك {num2} أخرى.',
      '{num1} طيور على الشجرة. أتت {num2} أخرى.',
      '{num1} أطفال يلعبون. انضم {num2} آخرون.',
    ],
    'subtraction': [
      'كان لديك {num1} حلوى. أكلت {num2}.',
      '{num1} فراشة طارت. ذهبت {num2}.',
      'كان لديك {num1} بالون. انفجر {num2}.',
    ],
    'multiplication': [
      'على {num1} أطباق {num2} بسكويت لكل طبق.',
      'لكل من {num1} سيارات {num2} عجلات.',
      'لكل من {num1} زهور {num2} ورقة.',
    ],
    'default': ['لغز رياضي: استخدم {num1} و {num2}.'],
  },
  'fa': {
    'addition': [
      'در سبد {num1} سیب داری. دوستت {num2} سیب دیگر می‌دهد.',
      '{num1} پرنده روی درخت‌اند. {num2} پرنده دیگر می‌آید.',
      '{num1} بچه بازی می‌کنند. {num2} نفر دیگر می‌پیوندند.',
    ],
    'subtraction': [
      '{num1} آب‌نبات داشتی. {num2} تا خوردی.',
      '{num1} پروانه در باغ بود. {num2} تا رفت.',
      '{num1} بادکنک داشتی. {num2} تا ترکید.',
    ],
    'multiplication': [
      'روی {num1} بشقاب هر کدام {num2} بیسکویت است.',
      'هر یک از {num1} ماشین {num2} چرخ دارد.',
      'هر یک از {num1} گل {num2} برگ دارد.',
    ],
    'default': ['معمای ریاضی: از {num1} و {num2} استفاده کن.'],
  },
  'zh': {
    'addition': [
      '篮子里有{num1}个苹果，朋友又给你{num2}个。',
      '树上有{num1}只鸟，又来了{num2}只。',
      '公园里有{num1}个小朋友，又来了{num2}个。',
    ],
    'subtraction': [
      '盒子里有{num1}颗糖，你吃了{num2}颗。',
      '花园里有{num1}只蝴蝶，飞走了{num2}只。',
      '你有{num1}个气球，爆了{num2}个。',
    ],
    'multiplication': [
      '{num1}个盘子上每个有{num2}块饼干。',
      '{num1}辆车每辆有{num2}个轮子。',
      '{num1}朵花每朵有{num2}片花瓣。',
    ],
    'default': ['数学题：用{num1}和{num2}。'],
  },
  'id': {
    'addition': [
      'Ada {num1} apel di keranjang. Teman memberimu {num2} lagi.',
      '{num1} burung di pohon. {num2} burung lagi datang.',
      '{num1} anak bermain. {num2} anak lagi bergabung.',
    ],
    'subtraction': [
      'Kamu punya {num1} permen. Kamu makan {num2}.',
      '{num1} kupu-kupu terbang. {num2} pergi.',
      'Kamu punya {num1} balon. {num2} meletus.',
    ],
    'multiplication': [
      'Di {num1} piring ada {num2} kue tiap piring.',
      'Setiap {num1} mobil punya {num2} roda.',
      'Setiap {num1} bunga punya {num2} daun kelopak.',
    ],
    'default': ['Teka-teki matematika: gunakan {num1} dan {num2}.'],
  },
  'ku': {
    'addition': [
      'Di sîpetê de {num1} sêv hene. Hevalê te {num2} din didê.',
      '{num1} çivîk li darê ne. {num2} din tên.',
      '{num1} zarok dilîzin. {num2} din tevlî dibin.',
    ],
    'subtraction': [
      'Te {num1} şekir hebûn. Te {num2} xwar.',
      '{num1} paporik di baxçê de bûn. {num2} çûn.',
      'Te {num1} balon hebûn. {num2} pat kirin.',
    ],
    'multiplication': [
      'Li ser {num1} sifreyan her yekê {num2} kurabiye hene.',
      'Her yek ji {num1} otomobîlan {num2} teker hene.',
      'Her gulek ji {num1} gulan {num2} pel hene.',
    ],
    'default': ['Peyle ya matematîkê: {num1} û {num2} bi kar bîne.'],
  },
  'es': {
    'addition': [
      'Tienes {num1} manzanas en la cesta. Tu amigo te da {num2} más.',
      '{num1} pájaros en el árbol. Llegan {num2} más.',
      '{num1} niños juegan. Se unen {num2} más.',
    ],
    'subtraction': [
      'Tenías {num1} caramelos. Te comiste {num2}.',
      '{num1} mariposas volaban. Se fueron {num2}.',
      'Tenías {num1} globos. {num2} explotaron.',
    ],
    'multiplication': [
      'En {num1} platos hay {num2} galletas cada uno.',
      'Cada uno de {num1} coches tiene {num2} ruedas.',
      'Cada una de {num1} flores tiene {num2} pétalos.',
    ],
    'default': ['Acertijo: usa {num1} y {num2}.'],
  },
  'fr': {
    'addition': [
      'Tu as {num1} pommes dans le panier. Ton ami en donne {num2} de plus.',
      '{num1} oiseaux dans l’arbre. {num2} autres arrivent.',
      '{num1} enfants jouent. {num2} autres rejoignent.',
    ],
    'subtraction': [
      'Tu avais {num1} bonbons. Tu en manges {num2}.',
      '{num1} papillons volaient. {num2} sont partis.',
      'Tu avais {num1} ballons. {num2} ont éclaté.',
    ],
    'multiplication': [
      'Sur {num1} assiettes il y a {num2} biscuits chacune.',
      'Chacune des {num1} voitures a {num2} roues.',
      'Chacune des {num1} fleurs a {num2} pétales.',
    ],
    'default': ['Énigme : utilise {num1} et {num2}.'],
  },
  'ru': {
    'addition': [
      'В корзине {num1} яблок. Друг даёт ещё {num2}.',
      'На дереве {num1} птиц. Прилетело ещё {num2}.',
      'В парке играют {num1} детей. Присоединилось ещё {num2}.',
    ],
    'subtraction': [
      'Было {num1} конфет. Ты съел {num2}.',
      'Летало {num1} бабочек. {num2} улетели.',
      'Было {num1} шариков. {num2} лопнули.',
    ],
    'multiplication': [
      'На {num1} тарелках по {num2} печенья.',
      'У каждой из {num1} машин {num2} колеса.',
      'У каждого из {num1} цветков {num2} лепестка.',
    ],
    'default': ['Загадка: используй {num1} и {num2}.'],
  },
  'ja': {
    'addition': [
      'かごにりんごが{num1}こ。ともだちが{num2}こくれる。',
      'きに{num1}わのとり。さらに{num2}わくる。',
      'こうえんで{num1}にんあそんでいる。{num2}にんくわわる。',
    ],
    'subtraction': [
      'はこにあめが{num1}こ。{num2}こたべた。',
      '{num1}わのちょうちょ。{num2}わとんだ。',
      'ふうせんが{num1}こ。{num2}こわれた。',
    ],
    'multiplication': [
      '{num1}まいのおさらにそれぞれクッキーが{num2}こ。',
      '{num1}だいのくるまにタイヤが{num2}こ。',
      '{num1}ぼんのはなにはなびらが{num2}まい。',
    ],
    'default': ['なぞなぞ：{num1}と{num2}をつかおう。'],
  },
  'ko': {
    'addition': [
      '바구니에 사과가 {num1}개 있어요. 친구가 {num2}개를 더 줘요.',
      '나무에 새가 {num1}마리 있어요. {num2}마리가 더 와요.',
      '공원에 아이가 {num1}명 놀아요. {num2}명이 더 와요.',
    ],
    'subtraction': [
      '사탕이 {num1}개 있었어요. {num2}개를 먹었어요.',
      '나비가 {num1}마리 날았어요. {num2}마리가 갔어요.',
      '풍선이 {num1}개 있었어요. {num2}개가 터졌어요.',
    ],
    'multiplication': [
      '{num1}개 접시에 각각 쿠키가 {num2}개씩 있어요.',
      '{num1}대 차마다 바퀴가 {num2}개예요.',
      '{num1}송이 꽃마다 꽃잎이 {num2}개예요.',
    ],
    'default': ['수수께끼: {num1}과(와) {num2}를 써 봐요.'],
  },
  'hi': {
    'addition': [
      'टोकरी में {num1} सेब हैं। दोस्त ने {num2} और दिए।',
      'पेड़ पर {num1} पक्षी। {num2} और आए।',
      'पार्क में {num1} बच्चे। {num2} और जुड़े।',
    ],
    'subtraction': [
      '{num1} कैंडी थीं। तुमने {num2} खाईं।',
      '{num1} तितलियाँ उड़ीं। {num2} चली गईं।',
      '{num1} गुब्बारे थे। {num2} फूट गए।',
    ],
    'multiplication': [
      '{num1} प्लेटों पर प्रत्येक पर {num2} बिस्कुट।',
      '{num1} कारों में प्रत्येक में {num2} पहिए।',
      '{num1} फूलों में प्रत्येक में {num2} पंखुड़ियाँ।',
    ],
    'default': ['पहेली: {num1} और {num2} इस्तेमाल करो।'],
  },
  'ur': {
    'addition': [
      'ٹوکری میں {num1} سیب۔ دوست {num2} اور دیتا ہے۔',
      'درخت پر {num1} پرندے۔ {num2} اور آتے ہیں۔',
      'پارک میں {num1} بچے۔ {num2} اور شامل۔',
    ],
    'subtraction': [
      '{num1} کینڈیز تھیں۔ تم نے {num2} کھائیں۔',
      '{num1} تتلیاں۔ {num2} چلی گئیں۔',
      '{num1} غبارے۔ {num2} پھٹ گئے۔',
    ],
    'multiplication': [
      '{num1} پلیٹوں پر ہر ایک پر {num2} بسکٹ۔',
      'ہر {num1} کار میں {num2} پہیے۔',
      'ہر {num1} پھول میں {num2} پنکھڑیاں۔',
    ],
    'default': ['پہیلی: {num1} اور {num2} استعمال کرو۔'],
  },
  'pt': {
    'addition': [
      'Há {num1} maçãs na cesta. O amigo dá mais {num2}.',
      '{num1} pássaros na árvore. Mais {num2} chegam.',
      '{num1} crianças brincam. Mais {num2} entram.',
    ],
    'subtraction': [
      'Havia {num1} doces. Você comeu {num2}.',
      '{num1} borboletas voavam. {num2} foram embora.',
      'Havia {num1} balões. {num2} estouraram.',
    ],
    'multiplication': [
      'Em {num1} pratos há {num2} biscoitos cada.',
      'Cada um dos {num1} carros tem {num2} rodas.',
      'Cada uma das {num1} flores tem {num2} pétalas.',
    ],
    'default': ['Enigma: use {num1} e {num2}.'],
  },
  'it': {
    'addition': [
      'Hai {num1} mele nel cesto. L’amico ti dà altre {num2}.',
      '{num1} uccelli sull’albero. Ne arrivano altri {num2}.',
      '{num1} bambini giocano. Se ne aggiungono {num2}.',
    ],
    'subtraction': [
      'Avevi {num1} caramelle. Ne mangi {num2}.',
      '{num1} farfalle volavano. {num2} se ne vanno.',
      'Avevi {num1} palloncini. {num2} scoppiano.',
    ],
    'multiplication': [
      'Su {num1} piatti ci sono {num2} biscotti ciascuno.',
      'Ognuna delle {num1} auto ha {num2} ruote.',
      'Ognuno dei {num1} fiori ha {num2} petali.',
    ],
    'default': ['Indovinello: usa {num1} e {num2}.'],
  },
  'pl': {
    'addition': [
      'W koszyku jest {num1} jabłek. Przyjaciel daje {num2} więcej.',
      'Na drzewie {num1} ptaków. Przylatuje {num2} więcej.',
      'W parku bawi się {num1} dzieci. Dołącza {num2} więcej.',
    ],
    'subtraction': [
      'Było {num1} cukierków. Zjadłeś {num2}.',
      'Latało {num1} motyli. {num2} odleciało.',
      'Było {num1} balonów. {num2} pękło.',
    ],
    'multiplication': [
      'Na {num1} talerzach jest po {num2} ciastek.',
      'Każde z {num1} aut ma {num2} kół.',
      'Każdy z {num1} kwiatów ma {num2} płatków.',
    ],
    'default': ['Zagadka: użyj {num1} i {num2}.'],
  },
};

const Map<String, List<Map<String, String>>> _bedtime = {
  'tr': [
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
  ],
  'en': [
    {
      'title': '{childName} and the Number Stars',
      'content': '''In the quiet night, {childName} looked at the sky.
      The stars twinkled. One, two, three... counting began.
      Each star seemed to whisper a number on the breeze.
      “Five plus five makes ten,” said the brightest star.
      {childName} smiled and drifted into a gentle sleep,
      dreaming of dancing with numbers in a magical math world.
      At sunrise, {childName} was ready to learn more...''',
      'image': '⭐',
    },
    {
      'title': '{childName} and the Moon’s Secret',
      'content': '''The full moon shone above.
      {childName} watched from the window as the moon seemed to speak:
      “How many stars do you think there are tonight?”
      {childName} began to count... one, two, three...
      Eyelids grew heavy while counting.
      In dreams, {childName} solved gentle math puzzles with the moon.
      Waking with a smile, {childName} remembered how fun math can be...''',
      'image': '🌙',
    },
  ],
  'de': [
    {
      'title': '{childName} und die Zahlensterne',
      'content': '''In der stillen Nacht blickte {childName} zum Himmel.
      Die Sterne funkelten. Eins, zwei, drei...
      Jeder Stern flüsterte eine Zahl.
      „Fünf plus fünf ist zehn“, sagte der hellste Stern.
      {childName} lächelte und schlief ein,
      träumte von Zahlen und einem magischen Matheland.
      Beim Morgenlicht war {childName} bereit, Neues zu lernen...''',
      'image': '⭐',
    },
    {
      'title': '{childName} und das Mondgeheimnis',
      'content': '''Der Vollmond leuchtete am Fenster.
      „Wie viele Sterne siehst du heute Nacht?“, fragte der Mond leise.
      {childName} zählte... eins, zwei, drei...
      Die Augen wurden schwer.
      Im Traum löste {childName} kleine Rechenrätsel mit dem Mond.
      Beim Aufwachen lächelte {childName} – Mathe macht Spaß...''',
      'image': '🌙',
    },
  ],
  'ar': [
    {
      'title': '{childName} ونجوم الأرقام',
      'content': '''في هدوء الليل نظر {childName} إلى السماء.
      الوميض في النجوم. واحد، اثنان، ثلاثة...
      همست كل نجمة برقم.
      قالت ألمع نجمة: «خمسة زائد خمسة يساوي عشرة».
      ابتسم {childName} ونام بهدوء،
      يحلم بالأرقام في عالم سحري.
      عند الفجر كان مستعدًا ليتعلم المزيد...''',
      'image': '⭐',
    },
    {
      'title': '{childName} وسر القمر',
      'content': '''أضاء البدر السماء.
      سأل القمر: «كم نجمة ترى الليلة؟»
      بدأ {childName} العد... واحد، اثنان، ثلاثة...
      أغمض عينيه تدريجيًا.
      في الحلم حل {childName} ألغازًا بسيطة مع القمر.
      استيقظ مبتسمًا – الرياضيات ممتعة...''',
      'image': '🌙',
    },
  ],
  'fa': [
    {
      'title': '{childName} و ستاره‌های اعداد',
      'content': '''در آرامش شب، {childName} به آسمان نگاه کرد.
      ستاره‌ها می‌درخشیدند. یک، دو، سه...
      هر ستاره عددی را زمزمه می‌کرد.
      درخشان‌ترین ستاره گفت: «پنج به‌علاوه پنج ده می‌شود.»
      {childName} لبخند زد و به خوابی شیرین رفت،
      در رویا با اعداد در دنیای جادویی ریاضی رقصید.
      صبح که شد، آماده بود بیشتر یاد بگیرد...''',
      'image': '⭐',
    },
    {
      'title': '{childName} و راز ماه',
      'content': '''ماه کامل در آسمان می‌درخشید.
      ماه پرسید: «امشب چند ستاره می‌بینی؟»
      {childName} شمرد... یک، دو، سه...
      چشم‌هایش سنگین شد.
      در خواب با ماه معماهای کوچک حل کرد.
      بیدار شد و لبخند زد – ریاضی چه شیرین است...''',
      'image': '🌙',
    },
  ],
  'zh': [
    {
      'title': '{childName}和数字星星',
      'content': '''夜深人静，{childName}望着天空。
      星星一闪一闪。一、二、三……开始数。
      最亮的星星说：“五加五等于十。”
      {childName}微笑着进入梦乡，
      梦见在神奇的数学世界里和数字跳舞。
      天亮时，{childName}准备好学习更多……''',
      'image': '⭐',
    },
    {
      'title': '{childName}和月亮的秘密',
      'content': '''满月挂在天上。
      月亮问：“今晚你看见多少颗星星？”
      {childName}数着……一、二、三……
      眼皮渐渐变重。
      在梦里，{childName}和月亮一起解小小的数学题。
      醒来时笑了——数学真有趣……''',
      'image': '🌙',
    },
  ],
  'id': [
    {
      'title': '{childName} dan Bintang Angka',
      'content': '''Di malam yang tenang, {childName} menatap langit.
      Bintang berkelap-kelip. Satu, dua, tiga...
      Bintang paling terang berkata: “Lima tambah lima sama dengan sepuluh.”
      {childName} tersenyum dan tertidur pulas,
      bermimpi menari dengan angka di dunia matematika ajaib.
      Pagi harinya {childName} siap belajar lagi...''',
      'image': '⭐',
    },
    {
      'title': '{childName} dan Rahasia Bulan',
      'content': '''Bulan purnama bersinar.
      “Berapa bintang yang kamu lihat malam ini?” tanya bulan.
      {childName} menghitung... satu, dua, tiga...
      Kelopak mata menjadi berat.
      Di mimpi, {childName} menyelesaikan teka-teki kecil bersama bulan.
      Bangun dengan senyum – matematika menyenangkan...''',
      'image': '🌙',
    },
  ],
  'ku': [
    {
      'title': '{childName} û stêrkên hejmaran',
      'content': '''Di şeva aram de {childName} li ezmanê maçe kir.
      Stêrkên lêxistin. Yek, du, sê...
      Stêrka herî geş got: "Pênc zî pênc deh dibe."
      {childName} kenî xweş û xewek şîrîn kir,
      di xewnê de bi hejmaran di cîhana sihrî ya matematîkê de dans kir.
      Bi sibehê amade bû bêtir fêr bibe...''',
      'image': '⭐',
    },
    {
      'title': '{childName} û nehşîna heyvê',
      'content': '''Heyva tijî geş bû.
      "Îşev çend stêrk dibînî?" pirsî.
      {childName} hejmart... yek, du, sê...
      Çavên wî/wê giran bûn.
      Di xewnê de bi heyvê re çareseriya matematîkê ya hêsan kir.
      Bi ken rabû – matematîk kêfxweş e...''',
      'image': '🌙',
    },
  ],
  'es': [
    {
      'title': '{childName} y las estrellas numéricas',
      'content': '''En la noche tranquila, {childName} miró el cielo.
      Las estrellas brillaban. Uno, dos, tres...
      La más brillante dijo: «Cinco más cinco son diez.»
      {childName} sonrió y se durmió,
      soñando con números en un mundo mágico.
      Al amanecer, {childName} quería aprender más...''',
      'image': '⭐',
    },
    {
      'title': '{childName} y el secreto de la luna',
      'content': '''La luna llena brillaba.
      Preguntó: «¿Cuántas estrellas ves esta noche?»
      {childName} contó... uno, dos, tres...
      Los párpados se cerraron.
      En sueños resolvió acertijos con la luna.
      Despertó sonriendo: las mates son divertidas...''',
      'image': '🌙',
    },
  ],
  'fr': [
    {
      'title': '{childName} et les étoiles des nombres',
      'content': '''Dans la nuit calme, {childName} regarda le ciel.
      Les étoiles scintillaient. Un, deux, trois...
      La plus brillante dit : « Cinq plus cinq font dix. »
      {childName} sourit et s’endormit,
      rêvant de nombres dans un monde magique.
      Au matin, {childName} voulait encore apprendre...''',
      'image': '⭐',
    },
    {
      'title': '{childName} et le secret de la lune',
      'content': '''La pleine lune brillait.
      « Combien d’étoiles vois-tu ce soir ? » demanda la lune.
      {childName} compta... un, deux, trois...
      Les paupières se fermèrent.
      En rêve, {childName} résolut de petites énigmes avec la lune.
      Au réveil, le sourire aux lèvres : les maths, c’est amusant...''',
      'image': '🌙',
    },
  ],
  'ru': [
    {
      'title': '{childName} и звёзды чисел',
      'content': '''В тихую ночь {childName} смотрел на небо.
      Звёзды мерцали. Раз, два, три...
      Самая яркая сказала: «Пять плюс пять — десять.»
      {childName} улыбнулся и уснул,
      видя во сне танец чисел в волшебном мире.
      На рассвете {childName} был готов учиться дальше...''',
      'image': '⭐',
    },
    {
      'title': '{childName} и тайна луны',
      'content': '''Полная луна светила в окно.
      «Сколько звёзд ты видишь сегодня ночью?» — спросила луна.
      {childName} считал... раз, два, три...
      Веки стали тяжёлыми.
      Во сне решал простые задачки с луной.
      Проснулся с улыбкой — математика весёлая...''',
      'image': '🌙',
    },
  ],
  'ja': [
    {
      'title': '{childName}とかずのほし',
      'content': '''よるのしずかなそらを{childName}はながめた。
      ほしがきらきら。いち、に、さん…
      いちばんかがやくほしがいった。「ごたすごはじゅう。」
      {childName}はえがおでねむりにつき、
      まほうのすうがくのせかいをゆめみた。
      あさ、{childName}はもっとまなびたくなった…''',
      'image': '⭐',
    },
    {
      'title': '{childName}とつきのひみつ',
      'content': '''まんげつがかがやいていた。
      「こんや、ほしはいくつみえる？」つきがきいた。
      {childName}はかぞえた…いち、に、さん…
      まぶたがおもくなった。
      ゆめのなかでつきとちいさななぞをといた。
      めがさめてえがお——すうがくはたのしい…''',
      'image': '🌙',
    },
  ],
  'ko': [
    {
      'title': '{childName}와 숫자 별',
      'content': '''고요한 밤, {childName}이(가) 하늘을 봤어요.
      별이 반짝였어요. 하나, 둘, 셋...
      가장 밝은 별이 말했어요. “다섯 더하기 다섯은 열.”
      {childName}이(가) 미소 지으며 잠들었고,
      마법 같은 수학 세상을 꿈꿨어요.
      아침이 되자 더 배우고 싶었어요...''',
      'image': '⭐',
    },
    {
      'title': '{childName}와 달의 비밀',
      'content': '''보름달이 빛났어요.
      “오늘 밤 별이 몇 개 보이니?” 달이 물었어요.
      {childName}이(가) 세었어요... 하나, 둘, 셋...
      눈이 감겼어요.
      꿈속에서 달과 작은 수수께끼를 풀었어요.
      깨어나며 웃었어요 — 수학은 재미있어요...''',
      'image': '🌙',
    },
  ],
  'hi': [
    {
      'title': '{childName} और अंकों के तारे',
      'content': '''शांत रात में {childName} ने आसमान देखा।
      तारे चमके। एक, दो, तीन...
      सबसे चमकीला तारा बोला: «पाँच और पाँच दस।»
      {childName} मुस्कुराया और सो गया,
      जादुई गणित की दुनिया में सपना देखा।
      सुबह वह और सीखने को तैयार था...''',
      'image': '⭐',
    },
    {
      'title': '{childName} और चाँद का राज़',
      'content': '''पूर्णिमा चमक रही थी।
      चाँद ने पूछा: «आज रात कितने तारे दिखते हैं?»
      {childName} ने गिना... एक, दो, तीन...
      आँखें भारी हो गईं।
      सपने में चाँद के साथ छोटी पहेलियाँ हल कीं।
      जागकर मुस्कुराया — गणित मज़ेदार है...''',
      'image': '🌙',
    },
  ],
  'ur': [
    {
      'title': '{childName} اور اعداد کے ستارے',
      'content': '''پرسکون رات میں {childName} نے آسمان دیکھا۔
      ستارے چمکے۔ ایک، دو، تین...
      سب سے روشن ستارے نے کہا: «پانچ جمع پانچ دس۔»
      {childName} مسکرایا اور سو گیا،
      جادوئی ریاضی کی دنیا کا خواب دیکھا۔
      صبح وہ مزید سیکھنے کو تیار تھا...''',
      'image': '⭐',
    },
    {
      'title': '{childName} اور چاند کا راز',
      'content': '''پورا چاند چمک رہا تھا۔
      چاند نے پوچھا: «آج رات کتنے ستارے دکھتے ہیں؟»
      {childName} نے گنا... ایک، دو، تین...
      پلکیں بھاری ہو گئیں۔
      خواب میں چاند کے ساتھ چھوٹی پہلیاں حل کیں۔
      جاگ کر مسکرایا — ریاضی مزیدار ہے...''',
      'image': '🌙',
    },
  ],
  'pt': [
    {
      'title': '{childName} e as estrelas dos números',
      'content': '''Na noite tranquila, {childName} olhou para o céu.
      As estrelas brilhavam. Um, dois, três...
      A mais brilhante disse: “Cinco mais cinco é dez.”
      {childName} sorriu e adormeceu,
      sonhando com números num mundo mágico.
      Ao amanhecer, queria aprender mais...''',
      'image': '⭐',
    },
    {
      'title': '{childName} e o segredo da lua',
      'content': '''A lua cheia brilhava.
      “Quantas estrelas você vê esta noite?” perguntou a lua.
      {childName} contou... um, dois, três...
      As pálpebras ficaram pesadas.
      No sonho, resolveu charadas com a lua.
      Acordou sorrindo — matemática é divertida...''',
      'image': '🌙',
    },
  ],
  'it': [
    {
      'title': '{childName} e le stelle dei numeri',
      'content': '''Nella notte silenziosa, {childName} guardò il cielo.
      Le stelle brillavano. Uno, due, tre...
      La più luminosa disse: «Cinque più cinque fa dieci.»
      {childName} sorrise e si addormentò,
      sognando numeri in un mondo magico.
      All’alba voleva imparare ancora...''',
      'image': '⭐',
    },
    {
      'title': '{childName} e il segreto della luna',
      'content': '''La luna piena splendeva.
      «Quante stelle vedi stanotte?» chiese la luna.
      {childName} contò... uno, due, tre...
      Le palpebre si fecero pesanti.
      Nel sogno risolse indovinelli con la luna.
      Si svegliò sorridendo — la matematica è divertente...''',
      'image': '🌙',
    },
  ],
  'pl': [
    {
      'title': '{childName} i gwiazdy liczb',
      'content': '''W cichą noc {childName} spojrzał w niebo.
      Gwiazdy migały. Jeden, dwa, trzy...
      Najjaśniejsza szepnęła: „Pięć plus pięć to dziesięć.”
      {childName} uśmiechnął się i zasnął,
      śniąc o liczbach w magicznym świecie.
      O świcie chciał uczyć się dalej...''',
      'image': '⭐',
    },
    {
      'title': '{childName} i tajemnica księżyca',
      'content': '''Pełnia świeciła w oknie.
      „Ile gwiazd widzisz dziś wieczorem?” — zapytał księżyc.
      {childName} liczył... jeden, dwa, trzy...
      Powieki stały się ciężkie.
      We śnie rozwiązywał zagadki z księżycem.
      Obudził się z uśmiechem — matematyka jest fajna...''',
      'image': '🌙',
    },
  ],
};