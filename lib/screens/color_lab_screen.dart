import 'package:flutter/material.dart';
import 'dart:math' as math;

class ColorLabScreen extends StatefulWidget {
  final String ageGroup;

  const ColorLabScreen({
    Key? key,
    required this.ageGroup,
  }) : super(key: key);

  @override
  State<ColorLabScreen> createState() => _ColorLabScreenState();
}

class _ColorLabScreenState extends State<ColorLabScreen>
    with TickerProviderStateMixin {
  int _currentLevel = 1; // 1-15
  int _score = 0;
  
  // Soru bilgileri
  String _question = '';
  Color _color1 = Colors.red;
  Color _color2 = Colors.blue;
  Color? _resultColor; // Başta null, karıştırınca renk oluşur
  int _amount1 = 3;
  int _amount2 = 2;
  int _correctAnswer = 5;
  
  late AnimationController _mixingController;
  bool _isMixing = false;
  bool _hasAnswered = false;

  @override
  void initState() {
    super.initState();
    _mixingController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _loadLevel();
  }

  @override
  void dispose() {
    _mixingController.dispose();
    super.dispose();
  }

  void _loadLevel() {
    // Seviyeye göre soru oluştur
    final random = math.Random();
    
    setState(() {
      _hasAnswered = false;
      _resultColor = null;
      
      // Rastgele miktarlar oluştur (1-9 arası)
      _amount1 = random.nextInt(5) + 1;
      _amount2 = random.nextInt(5) + 1;
      _correctAnswer = _amount1 + _amount2;
      
      // Rastgele renkler seç (beyaz arka planda görünür renkler)
      List<Map<String, dynamic>> colorPairs = [
        {'c1': Colors.red, 'c2': Colors.blue, 'result': Colors.purple},
        {'c1': Colors.red, 'c2': Colors.orange, 'result': Colors.deepOrange},
        {'c1': Colors.blue, 'c2': Colors.green, 'result': Colors.teal},
        {'c1': Colors.purple, 'c2': Colors.pink, 'result': Colors.pinkAccent},
        {'c1': Colors.indigo, 'c2': Colors.blue, 'result': Colors.blue.shade700},
        {'c1': Colors.red, 'c2': Colors.pink, 'result': Colors.pink.shade400},
      ];
      
      var selectedPair = colorPairs[random.nextInt(colorPairs.length)];
      _color1 = selectedPair['c1'];
      _color2 = selectedPair['c2'];
      
      _question = '$_amount1 + $_amount2 = ?';
    });
  }

  void _mixColors() {
    if (!_hasAnswered) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Önce soruyu cevapla!'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    setState(() {
      _isMixing = true;
    });
    
    _mixingController.forward(from: 0).then((_) {
      setState(() {
        _isMixing = false;
        // Renk karışımını göster
        _resultColor = _getMixedColor();
      });
      
      // 2 saniye sonra bir sonraki seviyeye geç
      Future.delayed(const Duration(seconds: 2), () {
        if (_currentLevel < 15) {
          setState(() {
            _currentLevel++;
            _loadLevel();
          });
        } else {
          _showCompleteDialog();
        }
      });
    });
  }
  
  Color _getMixedColor() {
    // Renk karışımlarını kontrol et
    if (_color1 == Colors.red && _color2 == Colors.blue ||
        _color1 == Colors.blue && _color2 == Colors.red) {
      return Colors.purple;
    } else if (_color1 == Colors.red && _color2 == Colors.orange ||
               _color1 == Colors.orange && _color2 == Colors.red) {
      return Colors.deepOrange;
    } else if (_color1 == Colors.blue && _color2 == Colors.green ||
               _color1 == Colors.green && _color2 == Colors.blue) {
      return Colors.teal;
    } else if (_color1 == Colors.purple && _color2 == Colors.pink ||
               _color1 == Colors.pink && _color2 == Colors.purple) {
      return Colors.pinkAccent;
    } else if (_color1 == Colors.indigo && _color2 == Colors.blue ||
               _color1 == Colors.blue && _color2 == Colors.indigo) {
      return Colors.blue.shade700;
    } else if (_color1 == Colors.red && _color2 == Colors.pink ||
               _color1 == Colors.pink && _color2 == Colors.red) {
      return Colors.pink.shade400;
    }
    
    // Varsayılan: iki rengin ortalaması
    return Color.alphaBlend(_color1.withOpacity(0.5), _color2);
  }
  
  void _showCompleteDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('🏆 Tebrikler!'),
        content: Text('Tüm renk karışımlarını tamamladın!\nToplam Puan: $_score'),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
            child: const Text('Bitir'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.purple.shade200,
              Colors.purple.shade50,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildTopBar(),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildCharacter(),
                      _buildQuestion(),
                      _buildLabSetup(),
                      _buildMixButton(),
                      _buildAnswerOptions(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Icons.star, color: Colors.amber),
                const SizedBox(width: 8),
                Text(
                  '$_score',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Seviye $_currentLevel/15',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCharacter() {
    return Column(
      children: [
        Text(
          '👨‍🔬',
          style: TextStyle(fontSize: 50),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
              ),
            ],
          ),
          child: const Text(
            '"Renkleri karıştıralım!"',
            style: TextStyle(
              fontSize: 14,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuestion() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Soru',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _question,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabSetup() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _buildTestTube(_color1, _amount1, 'Sol'),
            const SizedBox(width: 15),
            const Text(
              '+',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 15),
            _buildTestTube(_color2, _amount2, 'Sağ'),
          ],
        ),
        if (_resultColor != null) ...[
          const SizedBox(height: 10),
          const Icon(Icons.arrow_downward, size: 30, color: Colors.purple),
          const SizedBox(height: 5),
          _buildResultTube(_resultColor!, _correctAnswer),
        ],
      ],
    );
  }
  
  Widget _buildResultTube(Color color, int amount) {
    return Column(
      children: [
        const Text(
          'Sonuç',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.purple,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: 80,
          height: 130,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(40),
            border: Border.all(color: Colors.purple, width: 3),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.5),
                blurRadius: 15,
                spreadRadius: 3,
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                width: 72,
                height: 95,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(36),
                    bottomRight: Radius.circular(36),
                  ),
                ),
                child: Center(
                  child: Text(
                    '$amount',
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          color: Colors.black45,
                          offset: Offset(2, 2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTestTube(Color color, int amount, String label) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: 65,
          height: 120,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(35),
            border: Border.all(color: Colors.grey[400]!, width: 2),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                width: 58,
                height: 80,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                ),
                child: Center(
                  child: Text(
                    '$amount',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMixButton() {
    bool canMix = _hasAnswered && !_isMixing;
    
    return ElevatedButton(
      onPressed: canMix ? _mixColors : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.purple,
        disabledBackgroundColor: Colors.grey[300],
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.science,
            size: 22,
            color: canMix ? Colors.white : Colors.grey[600],
          ),
          const SizedBox(width: 8),
          Text(
            _isMixing
                ? 'Karıştırılıyor...'
                : _hasAnswered
                    ? 'Karıştır'
                    : 'Önce cevapla',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: canMix ? Colors.white : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerOptions() {
    List<int> options = [
      _correctAnswer - 1,
      _correctAnswer,
      _correctAnswer + 1,
    ];
    options.shuffle();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          const Text(
            'Sonuç Kaç?',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: options.map((option) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: ElevatedButton(
                    onPressed: _hasAnswered
                        ? null
                        : () {
                            _checkAnswer(option);
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      disabledBackgroundColor: option == _correctAnswer
                          ? Colors.green
                          : Colors.grey,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      '$option',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
  
  void _checkAnswer(int selectedAnswer) {
    if (selectedAnswer == _correctAnswer) {
      // Doğru cevap!
      setState(() {
        _hasAnswered = true;
        _score += 10;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Doğru! Şimdi renkleri karıştıralım!'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.green,
        ),
      );
      
      // Otomatik olarak karıştır
      Future.delayed(const Duration(milliseconds: 500), () {
        _mixColors();
      });
    } else {
      // Yanlış cevap!
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Hatalı cevap! Doğru cevap: $_correctAnswer. Tekrar dene!'),
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

