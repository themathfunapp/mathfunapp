import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:async';

/// Parçacık Sistemi
/// Başarı efektleri, konfeti, yıldız patlaması
class ParticleSystem extends StatefulWidget {
  final ParticleType type;
  final bool autoPlay;
  final VoidCallback? onComplete;

  const ParticleSystem({
    super.key,
    required this.type,
    this.autoPlay = true,
    this.onComplete,
  });

  @override
  State<ParticleSystem> createState() => _ParticleSystemState();
}

class _ParticleSystemState extends State<ParticleSystem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  List<Particle> _particles = [];
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _controller.addListener(() {
      setState(() {
        _updateParticles();
      });
    });

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onComplete?.call();
      }
    });

    if (widget.autoPlay) {
      _generateParticles();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void play() {
    _particles.clear();
    _generateParticles();
    _controller.forward(from: 0);
  }

  void _generateParticles() {
    final count = _getParticleCount();
    
    for (int i = 0; i < count; i++) {
      _particles.add(Particle(
        x: 200,
        y: 400,
        vx: (_random.nextDouble() - 0.5) * 15,
        vy: -_random.nextDouble() * 15 - 5,
        size: _random.nextDouble() * 10 + 5,
        color: _getRandomColor(),
        rotation: _random.nextDouble() * math.pi * 2,
        rotationSpeed: (_random.nextDouble() - 0.5) * 0.3,
        symbol: _getParticleSymbol(),
        gravity: widget.type == ParticleType.confetti ? 0.3 : 0.1,
      ));
    }
  }

  int _getParticleCount() {
    switch (widget.type) {
      case ParticleType.confetti:
        return 50;
      case ParticleType.stars:
        return 30;
      case ParticleType.mathSymbols:
        return 25;
      case ParticleType.hearts:
        return 20;
      case ParticleType.sparkles:
        return 40;
      case ParticleType.coins:
        return 15;
      case ParticleType.fireworks:
        return 60;
    }
  }

  Color _getRandomColor() {
    switch (widget.type) {
      case ParticleType.confetti:
        final colors = [
          Colors.red,
          Colors.blue,
          Colors.green,
          Colors.yellow,
          Colors.purple,
          Colors.orange,
          Colors.pink,
          Colors.cyan,
        ];
        return colors[_random.nextInt(colors.length)];
      case ParticleType.stars:
        return Colors.amber;
      case ParticleType.mathSymbols:
        return Colors.white;
      case ParticleType.hearts:
        return Colors.red;
      case ParticleType.sparkles:
        return Colors.white;
      case ParticleType.coins:
        return Colors.amber;
      case ParticleType.fireworks:
        final colors = [
          Colors.red,
          Colors.blue,
          Colors.green,
          Colors.amber,
          Colors.purple,
        ];
        return colors[_random.nextInt(colors.length)];
    }
  }

  String _getParticleSymbol() {
    switch (widget.type) {
      case ParticleType.confetti:
        return '';
      case ParticleType.stars:
        return '⭐';
      case ParticleType.mathSymbols:
        final symbols = ['+', '-', '×', '÷', '=', '√', 'π', '∞'];
        return symbols[_random.nextInt(symbols.length)];
      case ParticleType.hearts:
        return '❤️';
      case ParticleType.sparkles:
        return '✨';
      case ParticleType.coins:
        return '🪙';
      case ParticleType.fireworks:
        return '';
    }
  }

  void _updateParticles() {
    for (var particle in _particles) {
      particle.x += particle.vx;
      particle.y += particle.vy;
      particle.vy += particle.gravity;
      particle.rotation += particle.rotationSpeed;
      particle.opacity = 1 - _controller.value;
    }
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: _particles.map((particle) {
          return Positioned(
            left: particle.x - particle.size / 2,
            top: particle.y - particle.size / 2,
            child: Transform.rotate(
              angle: particle.rotation,
              child: Opacity(
                opacity: particle.opacity.clamp(0.0, 1.0),
                child: _buildParticleWidget(particle),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildParticleWidget(Particle particle) {
    if (particle.symbol.isNotEmpty) {
      return Text(
        particle.symbol,
        style: TextStyle(
          fontSize: particle.size,
          color: particle.color,
        ),
      );
    }

    // Konfeti veya havai fişek için şekil
    return Container(
      width: particle.size,
      height: particle.size * (widget.type == ParticleType.confetti ? 0.6 : 1),
      decoration: BoxDecoration(
        color: particle.color,
        borderRadius: widget.type == ParticleType.confetti
            ? BorderRadius.circular(2)
            : BorderRadius.circular(particle.size / 2),
        boxShadow: widget.type == ParticleType.fireworks
            ? [
                BoxShadow(
                  color: particle.color.withOpacity(0.5),
                  blurRadius: particle.size,
                ),
              ]
            : null,
      ),
    );
  }
}

class Particle {
  double x;
  double y;
  double vx;
  double vy;
  double size;
  Color color;
  double rotation;
  double rotationSpeed;
  String symbol;
  double gravity;
  double opacity;

  Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.size,
    required this.color,
    required this.rotation,
    required this.rotationSpeed,
    required this.symbol,
    required this.gravity,
    this.opacity = 1.0,
  });
}

enum ParticleType {
  confetti,
  stars,
  mathSymbols,
  hearts,
  sparkles,
  coins,
  fireworks,
}

/// Başarı Efekti Widget'ı - Kullanımı kolay
class SuccessEffect extends StatefulWidget {
  final Widget child;
  final SuccessType type;
  final bool trigger;
  final VoidCallback? onComplete;

  const SuccessEffect({
    super.key,
    required this.child,
    this.type = SuccessType.correct,
    this.trigger = false,
    this.onComplete,
  });

  @override
  State<SuccessEffect> createState() => _SuccessEffectState();
}

class _SuccessEffectState extends State<SuccessEffect> {
  bool _showEffect = false;
  ParticleType _particleType = ParticleType.sparkles;

  @override
  void didUpdateWidget(SuccessEffect oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.trigger && !oldWidget.trigger) {
      _triggerEffect();
    }
  }

  void _triggerEffect() {
    setState(() {
      _showEffect = true;
      _particleType = _getParticleType();
    });
  }

  ParticleType _getParticleType() {
    switch (widget.type) {
      case SuccessType.correct:
        return ParticleType.sparkles;
      case SuccessType.perfect:
        return ParticleType.confetti;
      case SuccessType.levelUp:
        return ParticleType.stars;
      case SuccessType.achievement:
        return ParticleType.fireworks;
      case SuccessType.reward:
        return ParticleType.coins;
      case SuccessType.streak:
        return ParticleType.mathSymbols;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_showEffect)
          ParticleSystem(
            type: _particleType,
            autoPlay: true,
            onComplete: () {
              setState(() {
                _showEffect = false;
              });
              widget.onComplete?.call();
            },
          ),
      ],
    );
  }
}

enum SuccessType {
  correct,
  perfect,
  levelUp,
  achievement,
  reward,
  streak,
}

/// Dalga Efekti Widget'ı
class WaveEffect extends StatefulWidget {
  final Widget child;
  final Color color;
  final bool trigger;

  const WaveEffect({
    super.key,
    required this.child,
    this.color = Colors.blue,
    this.trigger = false,
  });

  @override
  State<WaveEffect> createState() => _WaveEffectState();
}

class _WaveEffectState extends State<WaveEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void didUpdateWidget(WaveEffect oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.trigger && !oldWidget.trigger) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return Container(
              width: 100 + (_animation.value * 200),
              height: 100 + (_animation.value * 200),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: widget.color.withOpacity(1 - _animation.value),
                  width: 3,
                ),
              ),
            );
          },
        ),
        widget.child,
      ],
    );
  }
}

/// Işık Huzmesi Efekti
class LightBeamEffect extends StatefulWidget {
  final Widget child;
  final bool active;
  final Color color;

  const LightBeamEffect({
    super.key,
    required this.child,
    this.active = false,
    this.color = Colors.amber,
  });

  @override
  State<LightBeamEffect> createState() => _LightBeamEffectState();
}

class _LightBeamEffectState extends State<LightBeamEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
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
    if (!widget.active) return widget.child;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Işık huzmeleri
            ...List.generate(8, (index) {
              final angle = (index * math.pi / 4) + (_controller.value * math.pi);
              return Transform.rotate(
                angle: angle,
                child: Container(
                  width: 200,
                  height: 4,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        widget.color.withOpacity(0),
                        widget.color.withOpacity(0.5),
                        widget.color.withOpacity(0),
                      ],
                    ),
                  ),
                ),
              );
            }),
            widget.child,
          ],
        );
      },
    );
  }
}

