import 'package:flutter/material.dart';
import 'dart:math' as math;

class MemoryCardsScreen extends StatefulWidget {
  final String ageGroup;

  const MemoryCardsScreen({
    Key? key,
    required this.ageGroup,
  }) : super(key: key);

  @override
  State<MemoryCardsScreen> createState() => _MemoryCardsScreenState();
}

class _MemoryCardsScreenState extends State<MemoryCardsScreen> {
  int _level = 1;
  int _score = 0;
  int _moves = 0;
  int _totalScore = 0;
  
  List<String> _cards = [];
  List<int> _cardPairIds = [];
  List<bool> _revealed = [];
  List<bool> _matched = [];
  int? _firstCardIndex;
  bool _isProcessing = false;
  bool _canTap = true;

  // Her seviye için farklı matematik eşleştirmeleri (her sonuç benzersiz)
  final Map<int, List<List<String>>> _levelPairs = {
    // Seviye 1: Basit toplama (4 çift)
    1: [
      ['1+1', '2'],
      ['2+1', '3'],
      ['2+2', '4'],
      ['3+2', '5'],
    ],
    // Seviye 2: Toplama (5 çift)
    2: [
      ['4+2', '6'],
      ['4+3', '7'],
      ['5+3', '8'],
      ['6+3', '9'],
      ['5+5', '10'],
    ],
    // Seviye 3: Çıkarma (5 çift)
    3: [
      ['5-3', '2'],
      ['6-3', '3'],
      ['8-4', '4'],
      ['10-5', '5'],
      ['12-6', '6'],
    ],
    // Seviye 4: Karışık toplama/çıkarma (6 çift)
    4: [
      ['5+2', '7'],
      ['10-2', '8'],
      ['6+3', '9'],
      ['15-5', '10'],
      ['8+3', '11'],
      ['20-8', '12'],
    ],
    // Seviye 5: Basit çarpma (6 çift)
    5: [
      ['2×2', '4'],
      ['2×3', '6'],
      ['2×4', '8'],
      ['3×3', '9'],
      ['2×5', '10'],
      ['3×4', '12'],
    ],
    // Seviye 6: Çarpma ileri (6 çift)
    6: [
      ['4×4', '16'],
      ['3×6', '18'],
      ['4×5', '20'],
      ['3×8', '24'],
      ['5×5', '25'],
      ['4×7', '28'],
    ],
    // Seviye 7: Basit bölme (6 çift)
    7: [
      ['6÷2', '3'],
      ['8÷2', '4'],
      ['10÷2', '5'],
      ['12÷2', '6'],
      ['21÷3', '7'],
      ['24÷3', '8'],
    ],
    // Seviye 8: Karışık işlemler (7 çift)
    8: [
      ['5×4', '20'],
      ['7×3', '21'],
      ['11×2', '22'],
      ['8×3', '24'],
      ['5×5', '25'],
      ['9×3', '27'],
      ['7×4', '28'],
    ],
    // Seviye 9: Emoji sayma (7 çift)
    9: [
      ['🍎🍎🍎', '3'],
      ['⭐⭐⭐⭐', '4'],
      ['🎈🎈🎈🎈🎈', '5'],
      ['🌟🌟🌟🌟🌟🌟', '6'],
      ['🎯🎯🎯🎯🎯🎯🎯', '7'],
      ['🎪🎪🎪🎪🎪🎪🎪🎪', '8'],
      ['🎲🎲🎲🎲🎲🎲🎲🎲🎲', '9'],
    ],
    // Seviye 10: Zor karışık (8 çift)
    10: [
      ['6×6', '36'],
      ['7×6', '42'],
      ['8×6', '48'],
      ['7×7', '49'],
      ['8×7', '56'],
      ['9×7', '63'],
      ['8×8', '64'],
      ['9×8', '72'],
    ],
  };

  @override
  void initState() {
    super.initState();
    _initializeGame();
  }

  int _getPairCount() {
    return _levelPairs[_level]?.length ?? 4;
  }

  void _initializeGame() {
    final pairs = _levelPairs[_level] ?? _levelPairs[1]!;
    int pairCount = pairs.length;
    
    _cards = [];
    _cardPairIds = [];
    
    for (int i = 0; i < pairCount; i++) {
      _cards.add(pairs[i][0]);
      _cardPairIds.add(i);
      _cards.add(pairs[i][1]);
      _cardPairIds.add(i);
    }
    
    // Kartları karıştır
    final indices = List.generate(_cards.length, (i) => i);
    indices.shuffle();
    
    final shuffledCards = <String>[];
    final shuffledPairIds = <int>[];
    for (int i in indices) {
      shuffledCards.add(_cards[i]);
      shuffledPairIds.add(_cardPairIds[i]);
    }
    _cards = shuffledCards;
    _cardPairIds = shuffledPairIds;
    
    _revealed = List.filled(_cards.length, false);
    _matched = List.filled(_cards.length, false);
    _moves = 0;
    _firstCardIndex = null;
    _isProcessing = false;
    _canTap = true;
  }

  void _resetGame() {
    setState(() {
      _level = 1;
      _score = 0;
      _totalScore = 0;
      _initializeGame();
    });
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
              Colors.purple.shade400,
              Colors.purple.shade100,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildTopBar(),
              _buildScoreBar(),
              _buildLevelIndicator(),
              Expanded(
                child: Center(
                  child: _buildCardGrid(),
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
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          const Spacer(),
          const Text(
            '🃏 Hafıza Kartları',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.help_outline, color: Colors.white),
            onPressed: _showHelpDialog,
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _resetGame,
          ),
        ],
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Text('🎮 '),
            const Text('Nasıl Oynanır?'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHelpItem('1️⃣', 'Kartlara tıklayarak çevir'),
              _buildHelpItem('2️⃣', 'İki kart seç ve eşleştir'),
              _buildHelpItem('3️⃣', 'Matematik işlemi ile sonucunu bul'),
              _buildHelpItem('4️⃣', 'Örnek: "3+2" kartı ile "5" kartı eşleşir'),
              _buildHelpItem('5️⃣', 'Tüm çiftleri bul ve seviyeyi geç'),
              const Divider(),
              const Text(
                '💡 İpuçları:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('• Daha az hamle = Daha yüksek puan'),
              const Text('• Her seviyede işlemler zorlaşır'),
              const Text('• 10 seviyeyi tamamla ve şampiyon ol!'),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text('Anladım!', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpItem(String emoji, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  int _getMatchedPairCount() {
    int count = 0;
    for (int i = 0; i < _matched.length; i += 2) {
      if (i + 1 < _matched.length && _matched[i] && _matched[i + 1]) {
        count++;
      }
    }
    // Daha doğru hesaplama
    return _matched.where((m) => m).length ~/ 2;
  }

  Widget _buildScoreBar() {
    int totalPairs = _getPairCount();
    int matchedPairs = _getMatchedPairCount();
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('Seviye', '$_level/10', Colors.purple),
          _buildStatItem('Eşleşme', '$matchedPairs/$totalPairs', Colors.teal),
          _buildStatItem('Hamle', '$_moves', Colors.blue),
          _buildStatItem('Puan', '$_totalScore', Colors.orange),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildLevelIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: List.generate(10, (index) {
          bool isCompleted = index + 1 < _level;
          bool isCurrent = index + 1 == _level;
          return Expanded(
            child: Container(
              height: 6,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: isCompleted
                    ? Colors.green
                    : isCurrent
                        ? Colors.orange
                        : Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildCardGrid() {
    int cardCount = _cards.length;
    int columns = cardCount <= 8 ? 4 : (cardCount <= 12 ? 4 : 4);
    int rows = (cardCount / columns).ceil();
    
    return LayoutBuilder(
      builder: (context, constraints) {
        double maxWidth = constraints.maxWidth - 32;
        double maxHeight = constraints.maxHeight - 16;
        
        double cardWidth = (maxWidth - (columns - 1) * 8) / columns;
        double cardHeight = (maxHeight - (rows - 1) * 8) / rows;
        double cardSize = math.min(cardWidth, cardHeight);
        cardSize = math.min(cardSize, 90);
        
        return Center(
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: List.generate(_cards.length, (index) {
              return SizedBox(
                width: cardSize,
                height: cardSize,
                child: _buildCard(index),
              );
            }),
          ),
        );
      },
    );
  }

  Widget _buildCard(int index) {
    bool isRevealed = _revealed[index];
    bool isMatched = _matched[index];
    
    return GestureDetector(
      onTap: () => _onCardTap(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        decoration: BoxDecoration(
          color: isMatched
              ? Colors.green.shade100
              : isRevealed
                  ? Colors.white
                  : Colors.purple.shade500,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isMatched
                ? Colors.green.shade600
                : isRevealed
                    ? Colors.purple.shade300
                    : Colors.purple.shade700,
            width: isMatched ? 3 : 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: (isRevealed || isMatched)
              ? FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Text(
                      _cards[index],
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isMatched ? Colors.green.shade800 : Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : Icon(
                  Icons.question_mark,
                  size: 28,
                  color: Colors.white.withOpacity(0.9),
                ),
        ),
      ),
    );
  }

  void _onCardTap(int index) {
    // Tıklama engellerini kontrol et
    if (!_canTap) return;
    if (_isProcessing) return;
    if (_revealed[index]) return;
    if (_matched[index]) return;
    
    if (_firstCardIndex == null) {
      // İlk kart seçildi
      setState(() {
        _revealed[index] = true;
        _firstCardIndex = index;
      });
    } else {
      // İkinci kart seçildi - hemen kilitle
      final firstIndex = _firstCardIndex!;
      final secondIndex = index;
      
      setState(() {
        _revealed[index] = true;
        _moves++;
        _isProcessing = true;
        _canTap = false;
      });
      
      // Eşleşme kontrolü
      Future.delayed(const Duration(milliseconds: 700), () {
        if (!mounted) return;
        
        bool isMatch = _cardPairIds[firstIndex] == _cardPairIds[secondIndex];
        
        setState(() {
          if (isMatch) {
            _matched[firstIndex] = true;
            _matched[secondIndex] = true;
            _score += 15;
          } else {
            _revealed[firstIndex] = false;
            _revealed[secondIndex] = false;
          }
          
          _firstCardIndex = null;
          _isProcessing = false;
          _canTap = true;
        });
        
        // Seviye tamamlandı mı? - setState sonrası kontrol
        Future.microtask(() {
          if (!mounted) return;
          if (_matched.isNotEmpty && _matched.every((m) => m)) {
            _onLevelComplete();
          }
        });
      });
    }
  }

  void _onLevelComplete() {
    // Bonus puan hesapla (daha az hamle = daha çok bonus)
    int pairCount = _getPairCount();
    int perfectMoves = pairCount;
    int bonusPoints = math.max(0, (perfectMoves * 2 - _moves) * 5);
    int levelScore = _score + bonusPoints;
    _totalScore += levelScore;
    
    // Son seviye değilse otomatik ilerle
    if (_level < 10) {
      _showLevelUpAnimation();
    } else {
      // Son seviye - final dialog göster
      _showFinalDialog(bonusPoints);
    }
  }

  void _showLevelUpAnimation() {
    // Kısa bir kutlama göster ve otomatik ilerle
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🎉 ', style: TextStyle(fontSize: 20)),
            Text(
              'Seviye $_level Tamamlandı! Sonraki seviyeye geçiliyor...',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(milliseconds: 1200),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
    
    // 1.2 saniye sonra otomatik sonraki seviyeye geç
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      setState(() {
        _level++;
        _score = 0;
        _initializeGame();
      });
    });
  }

  void _showFinalDialog(int bonusPoints) {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            '🏆 TEBRİKLER!',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 24, color: Colors.purple),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '🎊 Tüm 10 seviyeyi tamamladın!\nHafıza Şampiyonusun! 🎊',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.purple.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    _buildResultRow('Toplam Hamle', '$_moves'),
                    _buildResultRow('Bonus Puan', '+$bonusPoints'),
                    const Divider(),
                    _buildResultRow('TOPLAM PUAN', '$_totalScore', isBold: true),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                Navigator.pop(context);
                _resetGame();
              },
              icon: const Icon(Icons.replay, color: Colors.white),
              label: const Text('Tekrar Oyna', style: TextStyle(color: Colors.white)),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              icon: const Icon(Icons.home, color: Colors.white),
              label: const Text('Ana Menü', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildResultRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isBold ? Colors.purple : Colors.black87,
              fontSize: isBold ? 18 : 14,
            ),
          ),
        ],
      ),
    );
  }
}
