import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:confetti/confetti.dart';
import 'dart:math' as math;
import '../services/game_mechanics_service.dart';
import '../localization/app_localizations.dart';
import '../providers/locale_provider.dart';
import '../widgets/child_exit_dialog.dart';

class ColorLabScreen extends StatefulWidget {
  final String ageGroup;
  /// 1=Kolay (1-5), 2=Orta (1-9), 3=Zor (5-15)
  final int levelMode;
  final int totalLevels;

  const ColorLabScreen({
    Key? key,
    required this.ageGroup,
    this.levelMode = 1,
    this.totalLevels = 15,
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
    final random = math.Random();
    final mode = widget.levelMode;
    int maxVal1, maxVal2, minVal;
    if (mode == 1) {
      minVal = 1;
      maxVal1 = 5;
      maxVal2 = 5;
    } else if (mode == 2) {
      minVal = 1;
      maxVal1 = 9;
      maxVal2 = 9;
    } else {
      minVal = 5;
      maxVal1 = 15;
      maxVal2 = 15;
    }
    
    setState(() {
      _hasAnswered = false;
      _resultColor = null;
      
      _amount1 = minVal + random.nextInt(maxVal1 - minVal + 1);
      _amount2 = minVal + random.nextInt(maxVal2 - minVal + 1);
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
      final loc = AppLocalizations(Provider.of<LocaleProvider>(context, listen: false).locale);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loc.get('color_lab_answer_question_first')),
          duration: const Duration(seconds: 2),
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
        if (mounted && _currentLevel < widget.totalLevels) {
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
    final loc = AppLocalizations(Provider.of<LocaleProvider>(context, listen: false).locale);
    Provider.of<GameMechanicsService>(context, listen: false).addCoins(10);
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      builder: (context) => _ColorLabCompleteDialog(
        coinsEarned: 10,
        loc: loc,
        onFinish: () {
          Navigator.pop(context);
          Navigator.pop(context);
        },
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
    final loc = AppLocalizations(Provider.of<LocaleProvider>(context, listen: false).locale);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              ChildExitDialog.show(
                context,
                themeColor: Colors.purple,
                onStay: () {},
                onSectionSelect: () => Navigator.pop(context),
                onExit: () => Navigator.pop(context),
              );
            },
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 6)],
              ),
              child: const Icon(Icons.arrow_back, color: Colors.purple),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 6)],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    '$_score',
                    style: GoogleFonts.quicksand(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.purple.shade800),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 6)],
            ),
            child: Text(
              '${loc.get('level')} $_currentLevel/${widget.totalLevels}',
              style: GoogleFonts.quicksand(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.purple.shade800),
            ),
          ),
          const SizedBox(width: 12),
          Consumer<GameMechanicsService>(
            builder: (context, mechanicsService, _) {
              final lives = mechanicsService.currentLives;
              final maxLives = mechanicsService.maxLives;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.amber.withOpacity(0.3), blurRadius: 6)],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(
                    maxLives,
                    (i) => Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Icon(
                        Icons.bolt,
                        color: i < lives ? Colors.amber.shade600 : Colors.grey.shade300,
                        size: 22,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCharacter() {
    final loc = AppLocalizations(Provider.of<LocaleProvider>(context, listen: false).locale);
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
          child: Text(
            '"${loc.get('color_lab_mix_colors')}"',
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
    final loc = AppLocalizations(Provider.of<LocaleProvider>(context, listen: false).locale);
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
          Text(
            loc.get('color_lab_question'),
            style: const TextStyle(
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
    final loc = AppLocalizations(Provider.of<LocaleProvider>(context, listen: false).locale);
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _buildTestTube(_color1, _amount1, loc.get('color_lab_left')),
            const SizedBox(width: 15),
            const Text(
              '+',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 15),
            _buildTestTube(_color2, _amount2, loc.get('color_lab_right')),
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
    final loc = AppLocalizations(Provider.of<LocaleProvider>(context, listen: false).locale);
    return Column(
      children: [
        Text(
          loc.get('color_lab_result'),
          style: const TextStyle(
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
    final loc = AppLocalizations(Provider.of<LocaleProvider>(context, listen: false).locale);
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
                ? loc.get('color_lab_mixing')
                : _hasAnswered
                    ? loc.get('color_lab_mix')
                    : loc.get('color_lab_answer_first'),
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
    final loc = AppLocalizations(Provider.of<LocaleProvider>(context, listen: false).locale);
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
          Text(
            loc.get('color_lab_what_result'),
            style: const TextStyle(
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
      setState(() {
        _hasAnswered = true;
      });
      
      final loc = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loc.get('color_lab_correct_mix')),
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.green,
        ),
      );
      
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) _mixColors();
      });
    } else {
      final mechanicsService = Provider.of<GameMechanicsService>(context, listen: false);
      mechanicsService.onWrongAnswer();
      
      final loc = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loc.get('color_lab_wrong_answer').replaceAll('%1', '$_correctAnswer')),
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.red,
        ),
      );
      
      if (!mechanicsService.hasLives) {
        _showNoLivesDialog();
      }
    }
  }
  
  void _showNoLivesDialog() {
    final loc = AppLocalizations(Provider.of<LocaleProvider>(context, listen: false).locale);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(loc.get('lives_finished')),
        content: Text(loc.get('no_lives_message')),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: Text(loc.get('simon_back_to_menu')),
          ),
        ],
      ),
    );
  }
}

/// Çocuklara yönelik animasyonlu tamamlanma diyaloğu
class _ColorLabCompleteDialog extends StatefulWidget {
  final int coinsEarned;
  final AppLocalizations loc;
  final VoidCallback onFinish;

  const _ColorLabCompleteDialog({
    required this.coinsEarned,
    required this.loc,
    required this.onFinish,
  });

  @override
  State<_ColorLabCompleteDialog> createState() => _ColorLabCompleteDialogState();
}

class _ColorLabCompleteDialogState extends State<_ColorLabCompleteDialog>
    with SingleTickerProviderStateMixin {
  late ConfettiController _confettiController;
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _confettiController.play();
      _scaleController.forward();
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Konfeti - arka planda
        Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            height: MediaQuery.of(context).size.height,
            width: MediaQuery.of(context).size.width,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              emissionFrequency: 0.05,
              numberOfParticles: 25,
              gravity: 0.2,
              colors: const [
                Colors.purple,
                Colors.pink,
                Colors.amber,
                Colors.blue,
                Colors.green,
                Colors.orange,
              ],
            ),
          ),
        ),
        // Diyalog içeriği - animasyonlu giriş
        ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 48),
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  Colors.purple.shade50,
                ],
              ),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.purple.withOpacity(0.3),
                  blurRadius: 24,
                  spreadRadius: 2,
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Bilim insanı emoji - büyük ve neşeli
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.8, end: 1.0),
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.elasticOut,
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: value,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade100,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.amber.withOpacity(0.4),
                              blurRadius: 12,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Text('👨‍🔬', style: TextStyle(fontSize: 56)),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
                // Başlık - kupa ve tebrikler
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('🏆', style: TextStyle(fontSize: 32)),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        widget.loc.get('congratulations'),
                        style: GoogleFonts.quicksand(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.purple.shade800,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Mesaj
                Text(
                  widget.loc.get('color_lab_all_complete').replaceAll('%1', '${widget.coinsEarned}'),
                  style: GoogleFonts.quicksand(
                    fontSize: 16,
                    color: Colors.grey.shade700,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                // Kazanılan koin kutusu
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.amber.shade400, Colors.orange.shade400],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.orange.withOpacity(0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🪙', style: TextStyle(fontSize: 24)),
                      const SizedBox(width: 8),
                      Text(
                        '+${widget.coinsEarned}',
                        style: GoogleFonts.quicksand(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              color: Colors.black26,
                              offset: const Offset(2, 2),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                // Bitir butonu - gradient ve yuvarlak
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: widget.onFinish,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.purple.shade500,
                            Colors.pink.shade400,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.purple.withOpacity(0.5),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            widget.loc.get('finish'),
                            style: GoogleFonts.quicksand(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.celebration, color: Colors.white, size: 22),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

