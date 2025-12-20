import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../localization/app_localizations.dart';
import 'game_start_screen.dart';

/// Konu Seçimi Ekranı
class TopicSelectionScreen extends StatefulWidget {
  final AgeGroupSelection ageGroup;
  final VoidCallback onBack;

  const TopicSelectionScreen({
    super.key,
    required this.ageGroup,
    required this.onBack,
  });

  @override
  State<TopicSelectionScreen> createState() => _TopicSelectionScreenState();
}

class _TopicSelectionScreenState extends State<TopicSelectionScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: -3, end: 3).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    // Yaş grubuna göre konular
    final topics = _getTopicsForAge(widget.ageGroup, localizations);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF667eea),
              Color(0xFF764ba2),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Üst bar
              _buildTopBar(localizations),

              // Başlık
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(
                      localizations.get('choose_topic'),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      localizations.get('select_topic_to_practice'),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),

              // Konular grid
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 1.1,
                  ),
                  itemCount: topics.length,
                  itemBuilder: (context, index) {
                    final topic = topics[index];
                    return _buildTopicCard(
                      topic: topic,
                      index: index,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(AppLocalizations localizations) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          GestureDetector(
            onTap: widget.onBack,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_back_ios_new,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          const Spacer(),
          Text(
            localizations.get('topics'),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const Spacer(),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildTopicCard({
    required Map<String, dynamic> topic,
    required int index,
  }) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _animation.value * (index % 2 == 0 ? 1 : -1)),
          child: GestureDetector(
            onTap: () => _selectTopic(topic),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    topic['color'] as Color,
                    (topic['color'] as Color).withOpacity(0.7),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: (topic['color'] as Color).withOpacity(0.4),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Arka plan deseni
                  Positioned(
                    right: -10,
                    bottom: -10,
                    child: Opacity(
                      opacity: 0.2,
                      child: Text(
                        topic['emoji'] as String,
                        style: const TextStyle(fontSize: 80),
                      ),
                    ),
                  ),

                  // İçerik
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              topic['emoji'] as String,
                              style: const TextStyle(fontSize: 28),
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          topic['title'] as String,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          topic['subtitle'] as String,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            ...List.generate(
                              topic['stars'] as int,
                              (i) => const Icon(
                                Icons.star,
                                color: Colors.amber,
                                size: 16,
                              ),
                            ),
                            ...List.generate(
                              3 - (topic['stars'] as int),
                              (i) => Icon(
                                Icons.star_border,
                                color: Colors.white.withOpacity(0.5),
                                size: 16,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Kilit durumu
                  if (topic['locked'] == true)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.lock,
                            color: Colors.white,
                            size: 40,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  List<Map<String, dynamic>> _getTopicsForAge(
    AgeGroupSelection age,
    AppLocalizations localizations,
  ) {
    final baseTopic = [
      {
        'id': 'counting',
        'emoji': '🔢',
        'title': localizations.get('counting'),
        'subtitle': localizations.get('learn_numbers'),
        'color': const Color(0xFF2ECC71),
        'stars': 1,
        'locked': false,
      },
      {
        'id': 'addition',
        'emoji': '➕',
        'title': localizations.get('addition'),
        'subtitle': localizations.get('add_numbers'),
        'color': const Color(0xFF3498DB),
        'stars': 1,
        'locked': false,
      },
      {
        'id': 'subtraction',
        'emoji': '➖',
        'title': localizations.get('subtraction'),
        'subtitle': localizations.get('subtract_numbers'),
        'color': const Color(0xFFE74C3C),
        'stars': 1,
        'locked': false,
      },
      {
        'id': 'shapes',
        'emoji': '🔺',
        'title': localizations.get('shapes'),
        'subtitle': localizations.get('learn_shapes'),
        'color': const Color(0xFFE67E22),
        'stars': 1,
        'locked': false,
      },
    ];

    if (age == AgeGroupSelection.preschool) {
      return baseTopic;
    }

    // 6-8 yaş için ek konular
    final elementaryTopics = [
      ...baseTopic,
      {
        'id': 'multiplication',
        'emoji': '✖️',
        'title': localizations.get('multiplication'),
        'subtitle': localizations.get('multiply_numbers'),
        'color': const Color(0xFF9B59B6),
        'stars': 2,
        'locked': false,
      },
      {
        'id': 'time',
        'emoji': '🕰',
        'title': localizations.get('time'),
        'subtitle': localizations.get('read_clock'),
        'color': const Color(0xFF1ABC9C),
        'stars': 2,
        'locked': false,
      },
    ];

    if (age == AgeGroupSelection.elementary) {
      return elementaryTopics;
    }

    // 9-11 yaş için ek konular
    return [
      ...elementaryTopics,
      {
        'id': 'division',
        'emoji': '➗',
        'title': localizations.get('division'),
        'subtitle': localizations.get('divide_numbers'),
        'color': const Color(0xFF34495E),
        'stars': 2,
        'locked': false,
      },
      {
        'id': 'fractions',
        'emoji': '½',
        'title': localizations.get('fractions'),
        'subtitle': localizations.get('learn_fractions'),
        'color': const Color(0xFFD35400),
        'stars': 3,
        'locked': false,
      },
      {
        'id': 'decimals',
        'emoji': '0️⃣',
        'title': localizations.get('decimals'),
        'subtitle': localizations.get('learn_decimals'),
        'color': const Color(0xFF8E44AD),
        'stars': 3,
        'locked': false,
      },
      {
        'id': 'algebra',
        'emoji': '🔤',
        'title': localizations.get('algebra'),
        'subtitle': localizations.get('basic_algebra'),
        'color': const Color(0xFF2C3E50),
        'stars': 3,
        'locked': false,
      },
    ];
  }

  void _selectTopic(Map<String, dynamic> topic) {
    if (topic['locked'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${topic['title']} henüz kilitli!'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    debugPrint('Selected topic: ${topic['id']}');
    // TODO: Navigate to topic game
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${topic['title']} seçildi! Oyun başlıyor...'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

