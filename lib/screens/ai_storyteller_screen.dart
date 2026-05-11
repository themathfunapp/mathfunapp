import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../localization/ai_storyteller_content.dart';
import '../models/ai_story_models.dart';
import '../providers/locale_provider.dart';
import '../services/ai_storyteller_service.dart';
import '../utils/locale_text_helpers.dart';

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

  static const List<Map<String, String>> _topicDefs = [
    {'id': 'addition', 'emoji': '➕'},
    {'id': 'subtraction', 'emoji': '➖'},
    {'id': 'multiplication', 'emoji': '✖️'},
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
          languageCode: Provider.of<LocaleProvider>(context, listen: false).locale.languageCode,
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
          languageCode: Provider.of<LocaleProvider>(context, listen: false).locale.languageCode,
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
    final lang = Provider.of<LocaleProvider>(context, listen: false).locale.languageCode;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.green[50],
        title: Text(aiStoryUi(lang, 'dialog_success_title'), textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              aiStoryUi(lang, 'dialog_success_body'),
              style: const TextStyle(fontSize: 20),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _nextChapter();
              },
              child: Text(aiStoryUi(lang, 'dialog_continue')),
            ),
          ],
        ),
      ),
    );
  }

  void _showHintDialog(String hint) {
    final lang = Provider.of<LocaleProvider>(context, listen: false).locale.languageCode;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.orange[50],
        title: Text(aiStoryUi(lang, 'dialog_hint_title'), textAlign: TextAlign.center),
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
              child: Text(aiStoryUi(lang, 'try_again')),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LocaleProvider>().locale.languageCode;

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
              _buildHeader(lang),
              Expanded(
                child: _isLoading
                    ? _buildLoadingState(lang)
                    : _currentStory != null
                        ? _buildStoryContent(lang)
                        : _buildStorySelection(lang),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(String lang) {
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
          Expanded(
            child: Text(
              aiStoryUi(lang, 'title'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
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

  Widget _buildLoadingState(String lang) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: Colors.white),
          const SizedBox(height: 24),
          Text(
            aiStoryUi(lang, 'loading'),
            style: TextStyle(
              fontSize: 20,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            aiStoryUi(lang, 'magic'),
            style: const TextStyle(fontSize: 28),
          ),
        ],
      ),
    );
  }

  Widget _buildStorySelection(String lang) {
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
                    aiStoryUi(lang, 'greeting').replaceAll('{childName}', widget.childName),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _service.generateDailyMessage(widget.childName, 5, 3, lang),
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
          Text(
            aiStoryUi(lang, 'pick_topic'),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _topicDefs.map((topic) {
              final isSelected = _selectedTopic == topic['id'];
              final topicLabel = aiStoryUi(lang, 'topic_${topic['id']}');
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedTopic = topic['id']!;
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
                      Text(topic['emoji']!, style: const TextStyle(fontSize: 20)),
                      const SizedBox(width: 8),
                      Text(
                        topicLabel,
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
            title: aiStoryUi(lang, 'adventure_title'),
            subtitle: aiStoryUi(lang, 'adventure_sub'),
            color: Colors.blue,
            onTap: _generateStory,
          ),

          const SizedBox(height: 16),

          // Uyku masalı butonu
          _buildStoryButton(
            emoji: '🌙',
            title: aiStoryUi(lang, 'bedtime_title'),
            subtitle: aiStoryUi(lang, 'bedtime_sub'),
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
                Text(
                  aiStoryUi(lang, 'characters_title'),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: () {
                    final c = aiStoryDefaultCharacters(lang);
                    return [
                      _buildCharacterChip(c[0].emoji, c[0].name),
                      _buildCharacterChip(c[1].emoji, c[1].name),
                      _buildCharacterChip(c[2].emoji, c[2].name),
                    ];
                  }(),
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
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    subtitle,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
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

  Widget _buildStoryContent(String lang) {
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
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    chapter.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
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
                label: Text(aiStoryUi(lang, 'math_challenge_btn')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  padding: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),

            if (_showingMathChallenge && chapter.mathChallenge != null)
              _buildMathChallenge(chapter.mathChallenge!, lang),

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
                      label: Text(aiStoryUi(lang, 'nav_back'), style: const TextStyle(color: Colors.white)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white30),
                      ),
                    ),
                  if (_currentChapterIndex < _currentStory!.chapters.length - 1)
                    ElevatedButton.icon(
                      onPressed: _nextChapter,
                      icon: const Icon(Icons.arrow_forward),
                      label: Text(aiStoryUi(lang, 'nav_forward')),
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
                      label: Text(aiStoryUi(lang, 'nav_finish')),
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

  Widget _buildMathChallenge(MathProblem problem, String lang) {
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
          Text(
            aiStoryUi(lang, 'math_time'),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            LocaleTextHelpers.ltrMathIsolate(
              '${problem.num1} ${problem.operator} ${problem.num2} = ?',
            ),
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

