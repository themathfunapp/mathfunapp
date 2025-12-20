import 'package:flutter/material.dart';
import '../services/ai_storyteller_service.dart';

/// AI Hikaye Anlatıcı Ekranı
/// Kişiselleştirilmiş matematik hikayeleri
class AIStorytellerScreen extends StatefulWidget {
  final String childName;
  final int age;

  const AIStorytellerScreen({
    super.key,
    this.childName = 'Kahraman',
    this.age = 7,
  });

  @override
  State<AIStorytellerScreen> createState() => _AIStorytellerScreenState();
}

class _AIStorytellerScreenState extends State<AIStorytellerScreen>
    with SingleTickerProviderStateMixin {
  final AIStorytellerService _service = AIStorytellerService();

  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  MathStory? _currentStory;
  int _currentChapterIndex = 0;
  bool _isLoading = false;
  String _selectedTopic = 'addition';
  bool _showingMathChallenge = false;
  int? _selectedAnswer;

  final List<Map<String, dynamic>> _topics = [
    {'id': 'addition', 'name': 'Toplama', 'emoji': '➕'},
    {'id': 'subtraction', 'name': 'Çıkarma', 'emoji': '➖'},
    {'id': 'multiplication', 'name': 'Çarpma', 'emoji': '✖️'},
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeIn),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _generateStory() {
    setState(() {
      _isLoading = true;
    });

    Future.delayed(const Duration(milliseconds: 500), () {
      setState(() {
        _currentStory = _service.generateStory(
          childName: widget.childName,
          age: widget.age,
          topic: _selectedTopic,
          difficulty: widget.age <= 5 ? 'easy' : (widget.age <= 8 ? 'medium' : 'hard'),
        );
        _currentChapterIndex = 0;
        _isLoading = false;
        _showingMathChallenge = false;
      });
      _animController.reset();
      _animController.forward();
    });
  }

  void _generateBedtimeStory() {
    setState(() {
      _isLoading = true;
    });

    Future.delayed(const Duration(milliseconds: 500), () {
      setState(() {
        _currentStory = _service.generateBedtimeStory(
          childName: widget.childName,
          age: widget.age,
        );
        _currentChapterIndex = 0;
        _isLoading = false;
      });
      _animController.reset();
      _animController.forward();
    });
  }

  void _nextChapter() {
    if (_currentStory != null && _currentChapterIndex < _currentStory!.chapters.length - 1) {
      setState(() {
        _currentChapterIndex++;
        _showingMathChallenge = false;
      });
      _animController.reset();
      _animController.forward();
    }
  }

  void _showMathChallenge() {
    setState(() {
      _showingMathChallenge = true;
      _selectedAnswer = null;
    });
  }

  void _checkAnswer(int answer) {
    final challenge = _currentStory?.chapters[_currentChapterIndex].mathChallenge;
    if (challenge != null) {
      setState(() {
        _selectedAnswer = answer;
      });

      Future.delayed(const Duration(seconds: 1), () {
        if (answer == challenge.answer) {
          _showSuccessDialog();
        } else {
          _showHintDialog(challenge.hint);
        }
      });
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.green[50],
        title: const Text('🎉 Harika!', textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Doğru cevap!',
              style: TextStyle(fontSize: 20),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _nextChapter();
              },
              child: const Text('Devam Et'),
            ),
          ],
        ),
      ),
    );
  }

  void _showHintDialog(String hint) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.orange[50],
        title: const Text('💡 İpucu', textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              hint,
              style: const TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  _selectedAnswer = null;
                });
              },
              child: const Text('Tekrar Dene'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.deepPurple.shade900,
              Colors.indigo.shade800,
              Colors.blue.shade900,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: _isLoading
                    ? _buildLoadingState()
                    : _currentStory != null
                        ? _buildStoryContent()
                        : _buildStorySelection(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          const SizedBox(width: 8),
          const Text(
            '📖',
            style: TextStyle(fontSize: 28),
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Hikaye Anlatıcı',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          if (_currentStory != null)
            IconButton(
              onPressed: () {
                setState(() {
                  _currentStory = null;
                  _currentChapterIndex = 0;
                });
              },
              icon: const Icon(Icons.home, color: Colors.white),
            ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: Colors.white),
          const SizedBox(height: 24),
          Text(
            'Hikaye hazırlanıyor...',
            style: TextStyle(
              fontSize: 20,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '✨ Sihir yapılıyor ✨',
            style: TextStyle(fontSize: 28),
          ),
        ],
      ),
    );
  }

  Widget _buildStorySelection() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Karşılama mesajı
          FadeTransition(
            opacity: _fadeAnimation,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white24),
              ),
              child: Column(
                children: [
                  const Text(
                    '🧙‍♂️',
                    style: TextStyle(fontSize: 64),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Merhaba ${widget.childName}!',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _service.generateDailyMessage(widget.childName, 5, 3),
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.8),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 32),

          // Konu seçimi
          const Text(
            '📚 Hikaye Konusu Seç',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _topics.map((topic) {
              final isSelected = _selectedTopic == topic['id'];
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedTopic = topic['id'];
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.amber : Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: isSelected ? Colors.amber : Colors.white30,
                      width: 2,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(topic['emoji'], style: const TextStyle(fontSize: 20)),
                      const SizedBox(width: 8),
                      Text(
                        topic['name'],
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.black : Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 32),

          // Hikaye başlat butonu
          _buildStoryButton(
            emoji: '🚀',
            title: 'Macera Hikayesi',
            subtitle: 'Matematik dolu bir macera başlat!',
            color: Colors.blue,
            onTap: _generateStory,
          ),

          const SizedBox(height: 16),

          // Uyku masalı butonu
          _buildStoryButton(
            emoji: '🌙',
            title: 'Uyku Masalı',
            subtitle: 'Tatlı rüyalar için matematik masalı',
            color: Colors.purple,
            onTap: _generateBedtimeStory,
          ),

          const SizedBox(height: 16),

          // Karakterler
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '🎭 Hikaye Karakterleri',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildCharacterChip('🐿️', 'Sayı Sincabı'),
                    _buildCharacterChip('🦉', 'Baykuş'),
                    _buildCharacterChip('🐱', 'Kedi'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoryButton({
    required String emoji,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color, color.withOpacity(0.7)],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 40)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white),
          ],
        ),
      ),
    );
  }

  Widget _buildCharacterChip(String emoji, String name) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 32)),
        const SizedBox(height: 4),
        Text(
          name,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildStoryContent() {
    final chapter = _currentStory!.chapters[_currentChapterIndex];

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Hikaye başlığı
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.amber.withOpacity(0.5)),
              ),
              child: Column(
                children: [
                  Text(
                    chapter.image,
                    style: const TextStyle(fontSize: 64),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _currentStory!.title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    chapter.title,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.amber.shade200,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Hikaye içeriği
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                chapter.content,
                style: const TextStyle(
                  fontSize: 18,
                  height: 1.6,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: 24),

            // Matematik meydan okuması
            if (chapter.mathChallenge != null && !_showingMathChallenge)
              ElevatedButton.icon(
                onPressed: _showMathChallenge,
                icon: const Text('🎯', style: TextStyle(fontSize: 24)),
                label: const Text('Matematik Meydan Okuması!'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  padding: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),

            if (_showingMathChallenge && chapter.mathChallenge != null)
              _buildMathChallenge(chapter.mathChallenge!),

            const SizedBox(height: 24),

            // İlerleme göstergesi
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_currentStory!.chapters.length, (index) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: index == _currentChapterIndex ? 24 : 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: index <= _currentChapterIndex
                        ? Colors.amber
                        : Colors.white30,
                    borderRadius: BorderRadius.circular(6),
                  ),
                );
              }),
            ),

            const SizedBox(height: 16),

            // Navigasyon butonları
            if (!_showingMathChallenge || chapter.mathChallenge == null)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  if (_currentChapterIndex > 0)
                    OutlinedButton.icon(
                      onPressed: () {
                        setState(() {
                          _currentChapterIndex--;
                        });
                        _animController.reset();
                        _animController.forward();
                      },
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      label: const Text('Geri', style: TextStyle(color: Colors.white)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white30),
                      ),
                    ),
                  if (_currentChapterIndex < _currentStory!.chapters.length - 1)
                    ElevatedButton.icon(
                      onPressed: _nextChapter,
                      icon: const Icon(Icons.arrow_forward),
                      label: const Text('İleri'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                      ),
                    ),
                  if (_currentChapterIndex == _currentStory!.chapters.length - 1)
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _currentStory = null;
                        });
                      },
                      icon: const Icon(Icons.check),
                      label: const Text('Bitir'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMathChallenge(MathProblem problem) {
    final options = _generateOptions(problem.answer);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.orange),
      ),
      child: Column(
        children: [
          const Text(
            '🧮 Matematik Zamanı!',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '${problem.num1} ${problem.operator} ${problem.num2} = ?',
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Colors.amber,
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: options.map((option) {
              final isSelected = _selectedAnswer == option;
              final isCorrect = option == problem.answer;

              Color bgColor = Colors.white.withOpacity(0.2);
              if (_selectedAnswer != null) {
                if (isSelected) {
                  bgColor = isCorrect ? Colors.green : Colors.red;
                } else if (isCorrect) {
                  bgColor = Colors.green.withOpacity(0.5);
                }
              }

              return GestureDetector(
                onTap: _selectedAnswer == null ? () => _checkAnswer(option) : null,
                child: Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? Colors.white : Colors.white30,
                      width: 2,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    option.toString(),
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
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

  List<int> _generateOptions(int correctAnswer) {
    final options = <int>{correctAnswer};

    while (options.length < 4) {
      final offset = (options.length * 2) - 3;
      options.add((correctAnswer + offset).abs());
    }

    return options.toList()..shuffle();
  }
}

