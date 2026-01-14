import 'package:flutter/material.dart';
import 'dart:math' as math;

class NumberColoringScreen extends StatefulWidget {
  final String ageGroup;

  const NumberColoringScreen({
    Key? key,
    required this.ageGroup,
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
      
      // Seviyeye göre başlangıç sayısını belirle
      if (_currentLevel == 1) {
        // Seviye 1: 0-9 (10 rakam)
        _currentNumber = 0;
      } else if (_currentLevel <= 10) {
        // Seviye 2-10: İki basamaklı 10-99 (her seviye 10 sayı)
        int groupIndex = _currentLevel - 2;
        _currentNumber = 10 + (groupIndex * 10);
      } else {
        // Seviye 11-30: Üç basamaklı 100-299 (her seviye 10 sayı)
        int groupIndex = _currentLevel - 11;
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
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
          const Spacer(),
          Text(
            'Seviye $_currentLevel/30',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelInfo() {
    String levelType = '';
    String rangeInfo = '';
    
    if (_currentLevel == 1) {
      levelType = 'Tek Basamaklı';
      rangeInfo = '0-9 arası rakamları boya';
    } else if (_currentLevel <= 10) {
      levelType = 'İki Basamaklı';
      int start = 10 + ((_currentLevel - 2) * 10);
      int end = start + 9;
      rangeInfo = '$start-$end arası sayıları boya';
    } else {
      levelType = 'Üç Basamaklı';
      int start = 100 + ((_currentLevel - 11) * 10);
      int end = start + 9;
      rangeInfo = '$start-$end arası sayıları boya';
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
            'Sayıyı Boya: $_currentNumber',
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
              const Text(
                '🎨 Renk Seç',
                style: TextStyle(
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
                    'Basamak ${_selectedDigitIndex! + 1}',
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
                      const SnackBar(
                        content: Text('Önce boyamak istediğiniz basamağa dokunun!'),
                        duration: Duration(seconds: 2),
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
            allDigitsColored ? 'Tamamla ✓' : 'Tüm basamakları boyayın',
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
      if (_currentLevel < 30) {
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
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('🎉 Tebrikler!'),
        content: Text('Seviye $_currentLevel tamamlandı!'),
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
            child: const Text('Sonraki Seviye'),
          ),
        ],
      ),
    );
  }
  
  void _showGameCompleteDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('🏆 Harika!'),
        content: const Text('Tüm seviyeleri tamamladın!'),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context); // Ana ekrana dön
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
            ),
            child: const Text('Bitir'),
          ),
        ],
      ),
    );
  }
}

