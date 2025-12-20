import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Karakter Duygu Sistemi
/// Oyun durumuna göre değişen karakter animasyonları
class EmotionalCharacter extends StatefulWidget {
  final CharacterEmotion emotion;
  final String character;
  final double size;
  final bool showSpeechBubble;
  final String? speechText;

  const EmotionalCharacter({
    super.key,
    this.emotion = CharacterEmotion.neutral,
    this.character = '👦',
    this.size = 100,
    this.showSpeechBubble = false,
    this.speechText,
  });

  @override
  State<EmotionalCharacter> createState() => _EmotionalCharacterState();
}

class _EmotionalCharacterState extends State<EmotionalCharacter>
    with TickerProviderStateMixin {
  late AnimationController _bounceController;
  late AnimationController _shakeController;
  late AnimationController _danceController;
  late Animation<double> _bounceAnimation;
  late Animation<double> _shakeAnimation;
  late Animation<double> _danceAnimation;

  @override
  void initState() {
    super.initState();

    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _bounceAnimation = Tween<double>(begin: 0, end: -20).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.easeOut),
    );

    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 10).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );

    _danceController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat(reverse: true);
    _danceAnimation = Tween<double>(begin: -5, end: 5).animate(
      CurvedAnimation(parent: _danceController, curve: Curves.easeInOut),
    );

    _playEmotionAnimation();
  }

  @override
  void didUpdateWidget(EmotionalCharacter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.emotion != widget.emotion) {
      _playEmotionAnimation();
    }
  }

  void _playEmotionAnimation() {
    switch (widget.emotion) {
      case CharacterEmotion.happy:
      case CharacterEmotion.excited:
        _bounceController.forward().then((_) => _bounceController.reverse());
        break;
      case CharacterEmotion.thinking:
        // Sabit poz
        break;
      case CharacterEmotion.confused:
      case CharacterEmotion.sad:
        _shakeController.forward().then((_) => _shakeController.reverse());
        break;
      case CharacterEmotion.dancing:
        // Dans animasyonu zaten çalışıyor
        break;
      default:
        break;
    }
  }

  @override
  void dispose() {
    _bounceController.dispose();
    _shakeController.dispose();
    _danceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _bounceAnimation,
        _shakeAnimation,
        _danceAnimation,
      ]),
      builder: (context, child) {
        double translateY = 0;
        double translateX = 0;
        double rotation = 0;

        switch (widget.emotion) {
          case CharacterEmotion.happy:
          case CharacterEmotion.excited:
            translateY = _bounceAnimation.value;
            break;
          case CharacterEmotion.confused:
          case CharacterEmotion.sad:
            translateX = _shakeAnimation.value * 
                math.sin(_shakeController.value * math.pi * 4);
            break;
          case CharacterEmotion.dancing:
            translateX = _danceAnimation.value;
            rotation = _danceAnimation.value * 0.02;
            break;
          default:
            break;
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Konuşma balonu
            if (widget.showSpeechBubble && widget.speechText != null)
              _buildSpeechBubble(),

            // Karakter
            Transform(
              transform: Matrix4.identity()
                ..translate(translateX, translateY)
                ..rotateZ(rotation),
              alignment: Alignment.center,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Ana karakter
                  Text(
                    widget.character,
                    style: TextStyle(fontSize: widget.size),
                  ),
                  
                  // Duygu efektleri
                  _buildEmotionEffect(),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSpeechBubble() {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        widget.speechText!,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildEmotionEffect() {
    switch (widget.emotion) {
      case CharacterEmotion.happy:
        return Positioned(
          top: 0,
          right: 0,
          child: Text('✨', style: TextStyle(fontSize: widget.size * 0.3)),
        );
      case CharacterEmotion.excited:
        return Positioned(
          top: -10,
          child: Text('🎉', style: TextStyle(fontSize: widget.size * 0.4)),
        );
      case CharacterEmotion.thinking:
        return Positioned(
          top: -20,
          right: -10,
          child: ThinkingBubble(size: widget.size * 0.3),
        );
      case CharacterEmotion.confused:
        return Positioned(
          top: -10,
          child: Text('❓', style: TextStyle(fontSize: widget.size * 0.3)),
        );
      case CharacterEmotion.sad:
        return Positioned(
          top: -10,
          child: Text('😢', style: TextStyle(fontSize: widget.size * 0.25)),
        );
      case CharacterEmotion.motivated:
        return Positioned(
          bottom: 0,
          child: Text('💪', style: TextStyle(fontSize: widget.size * 0.3)),
        );
      case CharacterEmotion.dancing:
        return Positioned(
          top: -20,
          child: Text('🎵', style: TextStyle(fontSize: widget.size * 0.25)),
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

enum CharacterEmotion {
  neutral,
  happy,
  excited,
  thinking,
  confused,
  sad,
  motivated,
  dancing,
}

/// Düşünme Balonu
class ThinkingBubble extends StatefulWidget {
  final double size;

  const ThinkingBubble({super.key, this.size = 30});

  @override
  State<ThinkingBubble> createState() => _ThinkingBubbleState();
}

class _ThinkingBubbleState extends State<ThinkingBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            final delay = index * 0.2;
            final animation = (_controller.value + delay) % 1.0;
            final scale = 0.5 + (math.sin(animation * math.pi) * 0.5);
            
            return Transform.scale(
              scale: scale,
              child: Container(
                width: widget.size * 0.4,
                height: widget.size * 0.4,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: const BoxDecoration(
                  color: Colors.white70,
                  shape: BoxShape.circle,
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

/// Karakter Tepkileri
class CharacterReaction {
  static const Map<String, List<String>> reactions = {
    'correct': [
      'Harika! 🎉',
      'Mükemmel! ⭐',
      'Doğru! 💪',
      'Süper! 🚀',
      'Aferin! 👏',
    ],
    'wrong': [
      'Tekrar dene! 💪',
      'Olur böyle şeyler! 🌟',
      'Bir daha deneyelim! 🎯',
      'Yaklaştın! 🔥',
    ],
    'streak': [
      'Müthiş seri! 🔥',
      'Durdurulamıyorsun! ⚡',
      'Komboo! 💥',
    ],
    'levelUp': [
      'Seviye atladın! 🎊',
      'Yeni seviye açıldı! 🏆',
    ],
    'thinking': [
      'Hmm, düşünelim... 🤔',
      'Bir bakalım... 👀',
    ],
  };

  static String getRandomReaction(String type) {
    final typeReactions = reactions[type];
    if (typeReactions == null || typeReactions.isEmpty) {
      return '';
    }
    return typeReactions[math.Random().nextInt(typeReactions.length)];
  }
}

/// Yardımcı Karakter Widget'ı
class HelperCharacterWidget extends StatefulWidget {
  final HelperCharacterType type;
  final CharacterEmotion emotion;
  final double size;
  final String? message;

  const HelperCharacterWidget({
    super.key,
    required this.type,
    this.emotion = CharacterEmotion.neutral,
    this.size = 80,
    this.message,
  });

  @override
  State<HelperCharacterWidget> createState() => _HelperCharacterWidgetState();
}

class _HelperCharacterWidgetState extends State<HelperCharacterWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _floatController;
  late Animation<double> _floatAnimation;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _floatAnimation = Tween<double>(begin: 0, end: 8).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _floatController.dispose();
    super.dispose();
  }

  String get _emoji {
    switch (widget.type) {
      case HelperCharacterType.cat:
        return '🐱';
      case HelperCharacterType.owl:
        return '🦉';
      case HelperCharacterType.fox:
        return '🦊';
      case HelperCharacterType.dolphin:
        return '🐬';
      case HelperCharacterType.robot:
        return '🤖';
      case HelperCharacterType.fairy:
        return '🧚';
    }
  }

  String get _specialty {
    switch (widget.type) {
      case HelperCharacterType.cat:
        return 'Toplama';
      case HelperCharacterType.owl:
        return 'Geometri';
      case HelperCharacterType.fox:
        return 'Problem Çözme';
      case HelperCharacterType.dolphin:
        return 'Hızlı Hesap';
      case HelperCharacterType.robot:
        return 'Çarpma';
      case HelperCharacterType.fairy:
        return 'Kesirler';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _floatAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _floatAnimation.value),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Mesaj balonu
              if (widget.message != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Text(
                    widget.message!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black87,
                    ),
                  ),
                ),
              
              // Karakter
              EmotionalCharacter(
                character: _emoji,
                emotion: widget.emotion,
                size: widget.size,
              ),
              
              // Uzmanlık etiketi
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _specialty,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.amber,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

enum HelperCharacterType {
  cat,
  owl,
  fox,
  dolphin,
  robot,
  fairy,
}

