import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;
import '../services/game_mechanics_service.dart';
import '../services/daily_reward_service.dart';
import '../localization/app_localizations.dart';
import '../providers/locale_provider.dart';
import '../widgets/child_exit_dialog.dart';
import '../models/daily_reward.dart' show TaskType;

class NumberColoringScreen extends StatefulWidget {
  final String ageGroup;
  /// 1=Tek Basamaklı (0-9), 2=İki Basamaklı (10-99), 3=Üç Basamaklı (100-999)
  final int levelMode;
  final int totalLevels;

  const NumberColoringScreen({
    Key? key,
    required this.ageGroup,
    this.levelMode = 1,
    this.totalLevels = 30,
  }) : super(key: key);

  @override
  State<NumberColoringScreen> createState() => _NumberColoringScreenState();
}

class _NumberColoringScreenState extends State<NumberColoringScreen> {
  int _currentLevel = 1; // 1-30
  int _currentNumber = 0; // Boyanan sayı
  int _numberIndexInLevel = 0; // Seviye içindeki sıra (0-9)
  Color? _selectedColor; // Şu an seçili olan renk
  int? _selectedDigitIndex; // Hangi basamak seçili (0, 1, 2...)
  
  // Her basamak için boyanmış renkler (digit index -> color)
  Map<int, Color> _digitColors = {};
  
  // Renk paleti
  final List<Color> _colorPalette = [
    Colors.red,
    Colors.orange,
    Colors.yellow,
    Colors.green,
    Colors.blue,
    Colors.purple,
    Colors.brown,
    Colors.black,
    Colors.pink,
  ];

  @override
  void initState() {
    super.initState();
    _loadLevel();
  }

  void _loadLevel() {
    setState(() {
      _numberIndexInLevel = 0;
      _selectedColor = null;
      _selectedDigitIndex = null;
      _digitColors.clear();
      
      final mode = widget.levelMode;
      final totalLevels = widget.totalLevels;
      
      if (mode == 1) {
        // Tek Basamaklı: 0-9
        _currentNumber = 0;
      } else if (mode == 2) {
        // İki Basamaklı: 10-99, her seviye 10 sayı
        int groupIndex = (_currentLevel - 1).clamp(0, 8);
        _currentNumber = 10 + (groupIndex * 10);
      } else {
        // Üç Basamaklı: 100-999, her seviye 10 sayı
        int groupIndex = (_currentLevel - 1).clamp(0, 89);
        _currentNumber = 100 + (groupIndex * 10);
      }
    });
  }
  
  // Sayıyı basamaklarına ayır
  List<int> _getDigits() {
    return _currentNumber.toString().split('').map((e) => int.parse(e)).toList();
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
              Colors.orange.shade200,
              Colors.orange.shade50,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildTopBar(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _buildLevelInfo(),
                      const SizedBox(height: 30),
                      _buildNumberCanvas(),
                      const SizedBox(height: 30),
                      _buildColorPalette(),
                      const SizedBox(height: 20),
                      _buildActionButtons(),
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
                themeColor: Colors.orange,
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
              child: const Icon(Icons.arrow_back, color: Colors.orange),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 6)],
              ),
              child: Text(
                '${loc.get('level')} $_currentLevel/${widget.totalLevels}',
                style: GoogleFonts.quicksand(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.orange.shade800),
                textAlign: TextAlign.center,
              ),
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
                  borderRadius: BorderRadius.circular(16),
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

  Widget _buildLevelInfo() {
    final loc = AppLocalizations(Provider.of<LocaleProvider>(context, listen: false).locale);
    String levelType = '';
    String rangeInfo = '';
    final mode = widget.levelMode;
    
    if (mode == 1) {
      levelType = loc.get('number_mode_single');
      rangeInfo = loc.get('number_mode_single_desc');
    } else if (mode == 2) {
      levelType = loc.get('number_mode_double');
      int start = 10 + (((_currentLevel - 1).clamp(0, 8)) * 10);
      int end = (start + 9).clamp(10, 99);
      rangeInfo = loc.get('number_coloring_range').replaceAll('%1', '$start').replaceAll('%2', '$end');
    } else {
      levelType = loc.get('number_mode_triple');
      int start = 100 + (((_currentLevel - 1).clamp(0, 89)) * 10);
      int end = (start + 9).clamp(100, 999);
      rangeInfo = loc.get('number_coloring_range').replaceAll('%1', '$start').replaceAll('%2', '$end');
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            levelType,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            rangeInfo,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            loc.get('color_the_number').replaceAll('%1', '$_currentNumber'),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNumberCanvas() {
    List<int> digits = _getDigits();
    
    return Center(
      child: Container(
        width: 350,
        height: 280,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
            ),
          ],
        ),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(digits.length, (index) {
              bool isSelected = _selectedDigitIndex == index;
              Color? digitColor = _digitColors[index];
              
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedDigitIndex = index;
                  });
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: isSelected ? Colors.orange : Colors.transparent,
                      width: 4,
                    ),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Text(
                    '${digits[index]}',
                    style: TextStyle(
                      fontSize: 120,
                      fontWeight: FontWeight.bold,
                      color: digitColor ?? Colors.grey[300],
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.2),
                          offset: const Offset(2, 2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildColorPalette() {
    final loc = AppLocalizations(Provider.of<LocaleProvider>(context, listen: false).locale);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '🎨 ${loc.get('select_color')}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (_selectedDigitIndex != null)
                Container(
                  margin: const EdgeInsets.only(left: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    loc.get('digit_n').replaceAll('%1', '${_selectedDigitIndex! + 1}'),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange.shade900,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _colorPalette.map((color) {
              bool isSelected = _selectedColor == color;
              return GestureDetector(
                onTap: () {
                  if (_selectedDigitIndex != null) {
                    setState(() {
                      _selectedColor = color;
                      _digitColors[_selectedDigitIndex!] = color;
                    });
                  } else {
                    // Basamak seçili değilse uyarı göster
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(loc.get('tap_digit_first')),
                        duration: const Duration(seconds: 2),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  }
                },
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? Colors.black : Colors.grey[300]!,
                      width: isSelected ? 4 : 2,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: color.withOpacity(0.5),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ]
                        : null,
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, color: Colors.white)
                      : null,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    final loc = AppLocalizations(Provider.of<LocaleProvider>(context, listen: false).locale);
    // Tüm basamaklar boyandıysa butonu aktif et
    List<int> digits = _getDigits();
    bool allDigitsColored = digits.asMap().keys.every((index) => _digitColors.containsKey(index));
    
    return Center(
      child: SizedBox(
        width: 300,
        child: ElevatedButton(
          onPressed: allDigitsColored
              ? () {
                  _completeNumber();
                }
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            disabledBackgroundColor: Colors.grey[300],
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            allDigitsColored ? loc.get('complete_check') : loc.get('color_all_digits'),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
  
  void _completeNumber() {
    // Her seviyede 10 sayı var
    int numbersInLevel = 10;
    
    // Bir sonraki sayıya geç
    _numberIndexInLevel++;
    
    if (_numberIndexInLevel >= numbersInLevel) {
      // Seviye tamamlandı!
      if (_currentLevel < widget.totalLevels) {
        // Bir sonraki seviyeye geç
        _showLevelCompleteDialog();
      } else {
        // Oyun tamamlandı!
        _showGameCompleteDialog();
      }
    } else {
      // Aynı seviye içinde bir sonraki sayıya geç
      setState(() {
        _currentNumber++;
        _selectedColor = null; // Renk seçimini sıfırla
        _selectedDigitIndex = null; // Basamak seçimini sıfırla
        _digitColors.clear(); // Basamak renklerini temizle
      });
    }
  }
  
  void _showLevelCompleteDialog() {
    final loc = AppLocalizations(Provider.of<LocaleProvider>(context, listen: false).locale);
    final mechanicsService = Provider.of<GameMechanicsService>(context, listen: false);
    final rewardService = Provider.of<DailyRewardService>(context, listen: false);

    // Renkli Matematik: seviye tamam ödülü (küçük)
    // ignore: discarded_futures
    mechanicsService.grantColorMathProgressCoins(baseCoins: 1, bonusCoins: 0);
    // ignore: discarded_futures
    mechanicsService.setColorMathProgress(module: 'number', completedLevel: _currentLevel, totalLevels: widget.totalLevels);
    // ignore: discarded_futures
    rewardService.updateTaskProgress(TaskType.playColorMathStep, 1);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('🎉 ${loc.get('congratulations')}'),
        content: Text(loc.get('level_completed_with_num').replaceAll('%1', '$_currentLevel')),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _currentLevel++;
                _loadLevel();
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
            ),
            child: Text(loc.get('next_level')),
          ),
        ],
      ),
    );
  }
  
  void _showGameCompleteDialog() {
    final loc = AppLocalizations(Provider.of<LocaleProvider>(context, listen: false).locale);
    final mechanicsService = Provider.of<GameMechanicsService>(context, listen: false);
    final rewardService = Provider.of<DailyRewardService>(context, listen: false);

    // Renkli Matematik: mod tamamlama bonusu (büyük)
    // ignore: discarded_futures
    mechanicsService.grantColorMathProgressCoins(baseCoins: 15, bonusCoins: 0);
    // ignore: discarded_futures
    mechanicsService.setColorMathProgress(module: 'number', completedLevel: widget.totalLevels, totalLevels: widget.totalLevels);
    // ignore: discarded_futures
    rewardService.updateTaskProgress(TaskType.completeColorMath, 1);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('🏆 ${loc.get('great')}'),
        content: Text(loc.get('all_levels_completed')),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context); // Ana ekrana dön
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
            ),
            child: Text(loc.get('finish')),
          ),
        ],
      ),
    );
  }
}

