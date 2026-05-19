/// Çarpanlar Kulesi — `ziki_step_1` … `ziki_step_36` nesne adları.
/// `tr`, `en`, `de` ana haritada; diğer 15 dil burada.
String? zikiStepString(String languageCode, String key) {
  if (!key.startsWith('ziki_step_')) return null;
  final lc = languageCode.toLowerCase();
  if (lc == 'tr' || lc == 'en' || lc == 'de') return null;
  return _byLang[lc]?[key];
}

final Map<String, Map<String, String>> _byLang = {
  'ar': _ar,
  'fa': _fa,
  'zh': _zh,
  'id': _id,
  'ku': _ku,
  'es': _es,
  'fr': _fr,
  'ru': _ru,
  'ja': _ja,
  'ko': _ko,
  'hi': _hi,
  'ur': _ur,
  'pt': _pt,
  'it': _it,
  'pl': _pl,
};

Map<String, String> _steps(
  String s1, s2, s3, s4, s5, s6, s7, s8, s9, s10,
  s11, s12, s13, s14, s15, s16, s17, s18, s19, s20,
  s21, s22, s23, s24, s25, s26, s27, s28, s29, s30,
  s31, s32, s33, s34, s35, s36,
) {
  final labels = [
    s1, s2, s3, s4, s5, s6, s7, s8, s9, s10,
    s11, s12, s13, s14, s15, s16, s17, s18, s19, s20,
    s21, s22, s23, s24, s25, s26, s27, s28, s29, s30,
    s31, s32, s33, s34, s35, s36,
  ];
  return {for (var i = 0; i < 36; i++) 'ziki_step_${i + 1}': labels[i]};
}

final _ku = _steps(
  'Muzê yek', 'Giloverên cot', 'Penîrê sêgoşe', 'Yonca çar pel', 'Storika avê',
  'Kulîka mêşan', 'Böçeka keskesor', 'Heştpot', 'Ewr', 'Kêşpîk', 'Tîma futbolê',
  'Qutiya hêkan', 'Pisîk', 'Darê giloverê', 'Heyv', 'Moşeng', 'Komên stêrkan',
  'Selika mûzê', 'Balona hejmaran', 'Tilî', 'Zar', 'Bisiklêt', 'Pirtûk', 'Saet',
  'Şîrînî', 'Alfabe', 'Şekreya küp', 'Salname', 'Dorêna heyvê', 'Roza rojê',
  'Qehweya serma', 'Satranç', 'Plak', 'Kek', 'Pêlik', 'Qutiya hêkan',
);

final _ar = _steps(
  'موزة واحدة', 'كرزتان', 'جبن مثلث', 'برسيم أربع أوراق', 'نجم البحر',
  'خلية نحل', 'دعسوقة', 'أخطبوط', 'سحابة', 'يسروع', 'فريق كرة قدم', 'علبة بيض',
  'قطة', 'شجرة كرز', 'قمر', 'عنكبوت', 'عنقود نجوم', 'سلة موز', 'بالون أرقام',
  'أصابع', 'نرد', 'دراجة', 'كتاب', 'ساعة', 'حلوى', 'أبجدية', 'مكعب سكر',
  'تقويم', 'دورة القمر', 'شارة اليوم', 'آيس كريم', 'شطرنج', 'أسطوانة', 'كعكة',
  'سلم', 'علبة بيض',
);

final _fa = _steps(
  'موز تنها', 'گیلاس دوقلو', 'پنیر مثلث', 'شبدر چهاربرگ', 'ستاره دریایی',
  'کندو زنبور', 'کفشدوزک', 'اختاپوس', 'ابر', 'کرم ابریشم', 'تیم فوتبال',
  'شانه تخم‌مرغ', 'گربه', 'درخت گیلاس', 'ماه', 'عنکبوت', 'خوشه ستاره',
  'سبد موز', 'بادکنک عدد', 'انگشتان', 'تاس', 'دوچرخه', 'کتاب', 'ساعت', 'آب‌نبات',
  'الفبا', 'قند حبه‌ای', 'تقویم', 'چرخه ماه', 'نشان روز', 'بستنی', 'شطرنج',
  'صفحه', 'کیک', 'نردبان', 'شانه تخم‌مرغ',
);

final _zh = _steps(
  '一根香蕉', '双樱桃', '三角奶酪', '四叶草', '海星', '蜂巢', '瓢虫', '章鱼',
  '云朵', '毛毛虫', '足球队', '鸡蛋盒', '猫', '樱桃树', '月亮', '蜘蛛', '星团',
  '香蕉篮', '数字气球', '手指', '骰子', '自行车', '书', '时钟', '糖果', '字母表',
  '方糖', '日历', '月相', '日徽章', '冰淇淋', '国际象棋', '唱片', '蛋糕', '梯子',
  '鸡蛋盒',
);

final _id = _steps(
  'Pisang tunggal', 'Ceri kembar', 'Keju segitiga', 'Semanggi empat daun',
  'Bintang laut', 'Sarang lebah', 'Kepik', 'Gurita', 'Awan', 'Ulat', 'Tim sepak bola',
  'Kotak telur', 'Kucing', 'Pohon ceri', 'Bulan', 'Laba-laba', 'Gugus bintang',
  'Keranjang pisang', 'Balon angka', 'Jari', 'Dadu', 'Sepeda', 'Buku', 'Jam',
  'Permen', 'Alfabet', 'Gula dadu', 'Kalender', 'Siklus bulan', 'Lencana hari',
  'Es krim', 'Catur', 'Piringan hitam', 'Kue', 'Tangga', 'Kotak telur',
);

final _es = _steps(
  'Plátano solo', 'Cerezas gemelas', 'Queso triangular', 'Trébol de cuatro hojas',
  'Estrella de mar', 'Colmena', 'Mariquita', 'Pulpo', 'Nube', 'Oruga',
  'Equipo de fútbol', 'Cartón de huevos', 'Gato', 'Cerezo', 'Luna', 'Araña',
  'Cúmulo estelar', 'Cesta de plátanos', 'Globo numérico', 'Dedos', 'Dado',
  'Bicicleta', 'Libro', 'Reloj', 'Caramelo', 'Alfabeto', 'Azúcar en cubo',
  'Calendario', 'Ciclo lunar', 'Insignia del día', 'Helado', 'Ajedrez', 'Disco',
  'Pastel', 'Escalera', 'Cartón de huevos',
);

final _fr = _steps(
  'Banane seule', 'Cerises jumelles', 'Fromage triangle', 'Trèfle à quatre feuilles',
  'Étoile de mer', 'Ruche', 'Coccinelle', 'Pieuvre', 'Nuage', 'Chenille',
  'Équipe de foot', 'Boîte d\'œufs', 'Chat', 'Cerisier', 'Lune', 'Araignée',
  'Amas d\'étoiles', 'Panier de bananes', 'Ballon chiffres', 'Doigts', 'Dé',
  'Vélo', 'Livre', 'Horloge', 'Bonbon', 'Alphabet', 'Sucre en cube', 'Calendrier',
  'Cycle lunaire', 'Badge du jour', 'Glace', 'Échecs', 'Disque', 'Gâteau',
  'Échelle', 'Boîte d\'œufs',
);

final _ru = _steps(
  'Один банан', 'Парные вишни', 'Треугольный сыр', 'Четырёхлистный клевер',
  'Морская звезда', 'Улей', 'Божья коровка', 'Осьминог', 'Облако', 'Гусеница',
  'Футбольная команда', 'Лоток яиц', 'Кот', 'Вишнёвое дерево', 'Луна', 'Паук',
  'Скопление звёзд', 'Корзина бананов', 'Шар с цифрами', 'Пальцы', 'Кубик',
  'Велосипед', 'Книга', 'Часы', 'Конфета', 'Алфавит', 'Кубик сахара', 'Календарь',
  'Лунный цикл', 'Значок дня', 'Мороженое', 'Шахматы', 'Пластинка', 'Торт',
  'Лестница', 'Лоток яиц',
);

final _ja = _steps(
  'バナナ1本', '双子のさくらんぼ', '三角チーズ', '四つ葉のクローバー', 'ヒトデ',
  '蜂の巣', 'てんとう虫', 'タコ', '雲', 'いもむし', 'サッカーチーム', '卵パック',
  'ねこ', 'さくらんぼの木', '月', 'くも', '星団', 'バナナかご', '数字バルーン',
  '指', 'サイコロ', '自転車', '本', '時計', 'キャンディ', 'アルファベット',
  '角砂糖', 'カレンダー', '月の周期', '日のバッジ', 'アイスクリーム', 'チェス',
  'レコード', 'ケーキ', 'はしご', '卵パック',
);

final _ko = _steps(
  '바나나 하나', '쌍둥이 체리', '세모 치즈', '네잎클로버', '불가사리', '벌집',
  '무당벌레', '문어', '구름', '애벌레', '축구팀', '계란판', '고양이', '체리나무',
  '달', '거미', '성단', '바나나 바구니', '숫자 풍선', '손가락', '주사위', '자전거',
  '책', '시계', '사탕', '알파벳', '각설탕', '달력', '달의 주기', '하루 배지',
  '아이스크림', '체스', '레코드', '케이크', '사다리', '계란판',
);

final _hi = _steps(
  'एक केला', 'जुड़वाँ चेरी', 'त्रिकोणीय पनीर', 'चार पत्ती वाली तिपतिया',
  'समुद्री तारा', 'मधुमक्खी का छत्ता', 'लेडीबग', 'ऑक्टोपस', 'बादल', 'इल्ली',
  'फुटबॉल टीम', 'अंडे का डिब्बा', 'बिल्ली', 'चेरी का पेड़', 'चाँद', 'मकड़ी',
  'तारों का झुंड', 'केले की टोकरी', 'अंक वाला गुब्बारा', 'उंगलियाँ', 'पासा',
  'साइकिल', 'किताब', 'घड़ी', 'कैंडी', 'वर्णमाला', 'चीनी का टुकड़ा', 'कैलेंडर',
  'चंद्र चक्र', 'दिन का बैज', 'आइसक्रीम', 'शतरंज', 'रिकॉर्ड', 'केक', 'सीढ़ी',
  'अंडे का डिब्बा',
);

final _ur = _steps(
  'ایک کیلا', 'جڑواں چیریاں', 'مثلثی پنیر', 'چار پتوں والی سہ شاخہ',
  'سمندری ستارہ', 'شہد کی مکھیا', 'لیڈی بیگ', 'آکٹوپس', 'بادل', 'کیڑا',
  'فٹبال ٹیم', 'انڈوں کا ڈبہ', 'بلی', 'چیری کا درخت', 'چاند', 'مکڑی',
  'ستاروں کا جھرمٹ', 'کیلوں کی ٹوکری', 'نمبروں کا غبارہ', 'انگلیاں', 'پاسا',
  'سائیکل', 'کتاب', 'گھڑی', 'کینڈی', 'حروف تہجی', 'چینی کا ٹکڑا', 'کیلنڈر',
  'چاند کا چکر', 'دن کا بیج', 'آئس کریم', 'شطرنج', 'ریکارڈ', 'کیک', 'سیڑھی',
  'انڈوں کا ڈبہ',
);

final _pt = _steps(
  'Banana solta', 'Cerejas gêmeas', 'Queijo triangular', 'Trevo de quatro folhas',
  'Estrela-do-mar', 'Colmeia', 'Joaninha', 'Polvo', 'Nuvem', 'Lagarta',
  'Time de futebol', 'Caixa de ovos', 'Gato', 'Cerejeira', 'Lua', 'Aranha',
  'Aglomerado estelar', 'Cesta de bananas', 'Balão de números', 'Dedos', 'Dado',
  'Bicicleta', 'Livro', 'Relógio', 'Doce', 'Alfabeto', 'Cubo de açúcar',
  'Calendário', 'Ciclo lunar', 'Distintivo do dia', 'Sorvete', 'Xadrez', 'Disco',
  'Bolo', 'Escada', 'Caixa de ovos',
);

final _it = _steps(
  'Banana singola', 'Ciliegie gemelle', 'Formaggio triangolare', 'Quadrifoglio',
  'Stella marina', 'Alveare', 'Coccinella', 'Polpo', 'Nuvola', 'Bruco',
  'Squadra di calcio', 'Cartone uova', 'Gatto', 'Ciliegio', 'Luna', 'Ragno',
  'Ammasso stellare', 'Cesto di banane', 'Palloncino numeri', 'Dita', 'Dado',
  'Bicicletta', 'Libro', 'Orologio', 'Caramella', 'Alfabeto', 'Zolletta di zucchero',
  'Calendario', 'Ciclo lunare', 'Distintivo del giorno', 'Gelato', 'Scacchi',
  'Disco', 'Torta', 'Scala', 'Cartone uova',
);

final _pl = _steps(
  'Pojedynczy banan', 'Bliźniacze wiśnie', 'Trójkątny ser', 'Czterolistna koniczyna',
  'Rozgwiazda', 'Ul', 'Biedronka', 'Ośmiornica', 'Chmura', 'Gąsienica',
  'Drużyna piłkarska', 'Karton jajek', 'Kot', 'Drzewo wiśni', 'Księżyc', 'Pająk',
  'Gromada gwiazd', 'Kosz bananów', 'Balon z liczbami', 'Palce', 'Kostka',
  'Rower', 'Książka', 'Zegar', 'Cukierek', 'Alfabet', 'Kostka cukru', 'Kalendarz',
  'Cykl Księżyca', 'Odznaka dnia', 'Lody', 'Szachy', 'Płyta', 'Ciasto', 'Drabina',
  'Karton jajek',
);
