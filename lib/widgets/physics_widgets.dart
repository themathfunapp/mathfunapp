import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Fizik Tabanlı Widget'lar
/// Yerçekimi, çarpışma, yaylanma efektleri

/// Yerçekimi ile Düşen Widget
class GravityWidget extends StatefulWidget {
  final Widget child;
  final bool enabled;
  final double gravity;
  final VoidCallback? onLand;

  const GravityWidget({
    super.key,
    required this.child,
    this.enabled = true,
    this.gravity = 9.8,
    this.onLand,
  });

  @override
  State<GravityWidget> createState() => _GravityWidgetState();
}

class _GravityWidgetState extends State<GravityWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _velocity = 0;
  double _position = 0;
  double _maxPosition = 300;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 16),
      vsync: this,
    );

    _controller.addListener(_updatePhysics);

    if (widget.enabled) {
      _controller.repeat();
    }
  }

  void _updatePhysics() {
    if (!widget.enabled) return;

    setState(() {
      _velocity += widget.gravity * 0.016;
      _position += _velocity;

      if (_position >= _maxPosition) {
        _position = _maxPosition;
        _velocity = -_velocity * 0.6; // Sekme efekti
        
        if (_velocity.abs() < 1) {
          _velocity = 0;
          widget.onLand?.call();
        }
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: Offset(0, _position),
      child: widget.child,
    );
  }
}

/// Yaylanma Efekti Widget'ı
class SpringWidget extends StatefulWidget {
  final Widget child;
  final bool trigger;
  final double springStrength;
  final double damping;

  const SpringWidget({
    super.key,
    required this.child,
    this.trigger = false,
    this.springStrength = 500,
    this.damping = 15,
  });

  @override
  State<SpringWidget> createState() => _SpringWidgetState();
}

class _SpringWidgetState extends State<SpringWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.elasticOut,
      ),
    );
  }

  @override
  void didUpdateWidget(SpringWidget oldWidget) {
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
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.scale(
          scale: 0.8 + (_animation.value * 0.4),
          child: widget.child,
        );
      },
    );
  }
}

/// Sallantı Efekti Widget'ı
class WobbleWidget extends StatefulWidget {
  final Widget child;
  final bool active;
  final double intensity;

  const WobbleWidget({
    super.key,
    required this.child,
    this.active = true,
    this.intensity = 5,
  });

  @override
  State<WobbleWidget> createState() => _WobbleWidgetState();
}

class _WobbleWidgetState extends State<WobbleWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    )..repeat(reverse: true);
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
        final angle = math.sin(_controller.value * math.pi * 2) * 
                      widget.intensity * math.pi / 180;
        return Transform.rotate(
          angle: angle,
          child: widget.child,
        );
      },
    );
  }
}

/// Sürüklenebilir Fizik Widget'ı
class DraggablePhysicsWidget extends StatefulWidget {
  final Widget child;
  final Function(Offset)? onDragEnd;
  final bool snapBack;

  const DraggablePhysicsWidget({
    super.key,
    required this.child,
    this.onDragEnd,
    this.snapBack = true,
  });

  @override
  State<DraggablePhysicsWidget> createState() => _DraggablePhysicsWidgetState();
}

class _DraggablePhysicsWidgetState extends State<DraggablePhysicsWidget>
    with SingleTickerProviderStateMixin {
  Offset _position = Offset.zero;
  Offset _velocity = Offset.zero;
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 16),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _position += details.delta;
      _velocity = details.delta;
    });
  }

  void _onPanEnd(DragEndDetails details) {
    widget.onDragEnd?.call(_position);

    if (widget.snapBack) {
      // Geri yay animasyonu
      final startPosition = _position;
      
      _controller.reset();
      _controller.duration = const Duration(milliseconds: 300);
      
      _controller.addListener(() {
        setState(() {
          _position = Offset.lerp(startPosition, Offset.zero, 
              Curves.elasticOut.transform(_controller.value))!;
        });
      });
      
      _controller.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      child: Transform.translate(
        offset: _position,
        child: widget.child,
      ),
    );
  }
}

/// Çarpışma Algılama Widget'ı
class CollisionWidget extends StatelessWidget {
  final Widget child;
  final GlobalKey targetKey;
  final VoidCallback? onCollision;

  const CollisionWidget({
    super.key,
    required this.child,
    required this.targetKey,
    this.onCollision,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return child;
      },
    );
  }

  bool checkCollision(Rect a, Rect b) {
    return a.overlaps(b);
  }
}

/// Parçacık Fiziği - Çoklu Parçacık Sistemi
class PhysicsParticleSystem extends StatefulWidget {
  final int particleCount;
  final double gravity;
  final double bounce;
  final List<Color> colors;

  const PhysicsParticleSystem({
    super.key,
    this.particleCount = 20,
    this.gravity = 0.5,
    this.bounce = 0.7,
    this.colors = const [Colors.blue, Colors.red, Colors.green],
  });

  @override
  State<PhysicsParticleSystem> createState() => _PhysicsParticleSystemState();
}

class _PhysicsParticleSystemState extends State<PhysicsParticleSystem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<PhysicsParticle> _particles;
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    
    _particles = List.generate(widget.particleCount, (index) {
      return PhysicsParticle(
        x: _random.nextDouble() * 300,
        y: _random.nextDouble() * 100,
        vx: (_random.nextDouble() - 0.5) * 5,
        vy: _random.nextDouble() * 3,
        radius: _random.nextDouble() * 10 + 5,
        color: widget.colors[_random.nextInt(widget.colors.length)],
      );
    });

    _controller = AnimationController(
      duration: const Duration(milliseconds: 16),
      vsync: this,
    )..repeat();

    _controller.addListener(_updateParticles);
  }

  void _updateParticles() {
    setState(() {
      for (var particle in _particles) {
        // Yerçekimi uygula
        particle.vy += widget.gravity;
        
        // Pozisyon güncelle
        particle.x += particle.vx;
        particle.y += particle.vy;

        // Duvar çarpışması
        if (particle.x <= 0 || particle.x >= 300) {
          particle.vx = -particle.vx * widget.bounce;
          particle.x = particle.x.clamp(0, 300);
        }

        // Zemin çarpışması
        if (particle.y >= 400) {
          particle.vy = -particle.vy * widget.bounce;
          particle.y = 400;
          particle.vx *= 0.95; // Sürtünme
        }
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: PhysicsParticlePainter(particles: _particles),
      size: const Size(300, 400),
    );
  }
}

class PhysicsParticle {
  double x;
  double y;
  double vx;
  double vy;
  double radius;
  Color color;

  PhysicsParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.radius,
    required this.color,
  });
}

class PhysicsParticlePainter extends CustomPainter {
  final List<PhysicsParticle> particles;

  PhysicsParticlePainter({required this.particles});

  @override
  void paint(Canvas canvas, Size size) {
    for (var particle in particles) {
      final paint = Paint()
        ..color = particle.color
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(
        Offset(particle.x, particle.y),
        particle.radius,
        paint,
      );

      // Gölge
      final shadowPaint = Paint()
        ..color = particle.color.withOpacity(0.3)
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(
        Offset(particle.x, size.height - 10),
        particle.radius * 0.5,
        shadowPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant PhysicsParticlePainter oldDelegate) => true;
}

/// Çoklu Dokunma Jest Algılayıcı
class MultiTouchGestureDetector extends StatefulWidget {
  final Widget child;
  final Function(double)? onPinchZoom;
  final Function(double)? onRotate;
  final VoidCallback? onDoubleTap;
  final VoidCallback? onLongPress;
  final Function(Offset)? onPan;

  const MultiTouchGestureDetector({
    super.key,
    required this.child,
    this.onPinchZoom,
    this.onRotate,
    this.onDoubleTap,
    this.onLongPress,
    this.onPan,
  });

  @override
  State<MultiTouchGestureDetector> createState() => _MultiTouchGestureDetectorState();
}

class _MultiTouchGestureDetectorState extends State<MultiTouchGestureDetector> {
  double _scale = 1.0;
  double _rotation = 0.0;
  double _previousScale = 1.0;
  double _previousRotation = 0.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onDoubleTap: widget.onDoubleTap,
      onLongPress: widget.onLongPress,
      onPanUpdate: (details) {
        widget.onPan?.call(details.delta);
      },
      onScaleStart: (details) {
        _previousScale = _scale;
        _previousRotation = _rotation;
      },
      onScaleUpdate: (details) {
        setState(() {
          _scale = _previousScale * details.scale;
          _rotation = _previousRotation + details.rotation;
        });
        widget.onPinchZoom?.call(_scale);
        widget.onRotate?.call(_rotation);
      },
      child: Transform.scale(
        scale: _scale,
        child: Transform.rotate(
          angle: _rotation,
          child: widget.child,
        ),
      ),
    );
  }
}

/// Kaydırmalı Momentum Widget
class MomentumScrollWidget extends StatefulWidget {
  final Widget child;
  final Axis axis;
  final double friction;

  const MomentumScrollWidget({
    super.key,
    required this.child,
    this.axis = Axis.horizontal,
    this.friction = 0.95,
  });

  @override
  State<MomentumScrollWidget> createState() => _MomentumScrollWidgetState();
}

class _MomentumScrollWidgetState extends State<MomentumScrollWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _position = 0;
  double _velocity = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 16),
      vsync: this,
    );

    _controller.addListener(() {
      setState(() {
        _position += _velocity;
        _velocity *= widget.friction;

        if (_velocity.abs() < 0.1) {
          _velocity = 0;
          _controller.stop();
        }
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      if (widget.axis == Axis.horizontal) {
        _position += details.delta.dx;
        _velocity = details.delta.dx;
      } else {
        _position += details.delta.dy;
        _velocity = details.delta.dy;
      }
    });
  }

  void _onPanEnd(DragEndDetails details) {
    _controller.repeat();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      child: Transform.translate(
        offset: widget.axis == Axis.horizontal
            ? Offset(_position, 0)
            : Offset(0, _position),
        child: widget.child,
      ),
    );
  }
}

