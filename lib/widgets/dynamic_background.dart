import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:async';

/// Dinamik Arka Plan Sistemi
/// Günün saatine, mevsimlere ve hava durumuna göre değişen arka plan
class DynamicBackground extends StatefulWidget {
  final Widget child;
  final bool enableWeather;
  final bool enableParticles;
  final String? forceTheme; // 'morning', 'noon', 'evening', 'night'
  final String? forceSeason; // 'spring', 'summer', 'autumn', 'winter'

  const DynamicBackground({
    super.key,
    required this.child,
    this.enableWeather = true,
    this.enableParticles = true,
    this.forceTheme,
    this.forceSeason,
  });

  @override
  State<DynamicBackground> createState() => _DynamicBackgroundState();
}

class _DynamicBackgroundState extends State<DynamicBackground>
    with TickerProviderStateMixin {
  late AnimationController _gradientController;
  late AnimationController _particleController;
  late Animation<double> _gradientAnimation;
  
  List<BackgroundParticle> _particles = [];
  Timer? _particleTimer;

  @override
  void initState() {
    super.initState();

    _gradientController = AnimationController(
      duration: const Duration(seconds: 30),
      vsync: this,
    )..repeat();

    _gradientAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _gradientController, curve: Curves.linear),
    );

    _particleController = AnimationController(
      duration: const Duration(milliseconds: 50),
      vsync: this,
    )..repeat();

    _particleController.addListener(_updateParticles);
    _generateInitialParticles();
  }

  @override
  void dispose() {
    _gradientController.dispose();
    _particleController.dispose();
    _particleTimer?.cancel();
    super.dispose();
  }

  void _generateInitialParticles() {
    final random = math.Random();
    final season = _getCurrentSeason();
    
    for (int i = 0; i < 30; i++) {
      _particles.add(BackgroundParticle(
        x: random.nextDouble() * 400,
        y: random.nextDouble() * 800,
        size: random.nextDouble() * 8 + 2,
        speed: random.nextDouble() * 2 + 0.5,
        type: _getParticleType(season),
        opacity: random.nextDouble() * 0.5 + 0.3,
      ));
    }
  }

  ParticleType _getParticleType(String season) {
    switch (season) {
      case 'winter':
        return ParticleType.snowflake;
      case 'spring':
        return ParticleType.butterfly;
      case 'summer':
        return ParticleType.sparkle;
      case 'autumn':
        return ParticleType.leaf;
      default:
        return ParticleType.sparkle;
    }
  }

  void _updateParticles() {
    if (!widget.enableParticles) return;
    
    setState(() {
      for (var particle in _particles) {
        particle.y += particle.speed;
        particle.x += math.sin(particle.y * 0.02) * 0.5;
        
        if (particle.y > 900) {
          particle.y = -20;
          particle.x = math.Random().nextDouble() * 400;
        }
      }
    });
  }

  String _getCurrentTimeOfDay() {
    if (widget.forceTheme != null) return widget.forceTheme!;
    
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 10) return 'morning';
    if (hour >= 10 && hour < 17) return 'noon';
    if (hour >= 17 && hour < 20) return 'evening';
    return 'night';
  }

  String _getCurrentSeason() {
    if (widget.forceSeason != null) return widget.forceSeason!;
    
    final month = DateTime.now().month;
    if (month >= 3 && month <= 5) return 'spring';
    if (month >= 6 && month <= 8) return 'summer';
    if (month >= 9 && month <= 11) return 'autumn';
    return 'winter';
  }

  List<Color> _getGradientColors() {
    final timeOfDay = _getCurrentTimeOfDay();
    
    switch (timeOfDay) {
      case 'morning':
        return [
          const Color(0xFFFFD89B),
          const Color(0xFF19547B),
        ];
      case 'noon':
        return [
          const Color(0xFF2193B0),
          const Color(0xFF6DD5ED),
        ];
      case 'evening':
        return [
          const Color(0xFFFF5F6D),
          const Color(0xFFFFC371),
        ];
      case 'night':
        return [
          const Color(0xFF0F2027),
          const Color(0xFF203A43),
          const Color(0xFF2C5364),
        ];
      default:
        return [
          const Color(0xFF667eea),
          const Color(0xFF764ba2),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _gradientAnimation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: _getGradientColors(),
              transform: GradientRotation(_gradientAnimation.value * 0.5),
            ),
          ),
          child: Stack(
            children: [
              // Parallax katmanları
              _buildParallaxLayers(),
              
              // Parçacıklar
              if (widget.enableParticles) _buildParticles(),
              
              // Hava durumu efekti
              if (widget.enableWeather) _buildWeatherEffect(),
              
              // Alt içerik
              widget.child,
            ],
          ),
        );
      },
    );
  }

  Widget _buildParallaxLayers() {
    return Stack(
      children: [
        // Katman 1 - Uzak bulutlar (yavaş)
        AnimatedBuilder(
          animation: _gradientController,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(
                math.sin(_gradientController.value * math.pi * 2) * 20,
                math.cos(_gradientController.value * math.pi * 2) * 10,
              ),
              child: Opacity(
                opacity: 0.3,
                child: _buildCloudLayer(),
              ),
            );
          },
        ),
        
        // Katman 2 - Orta mesafe (orta hız)
        AnimatedBuilder(
          animation: _gradientController,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(
                math.sin(_gradientController.value * math.pi * 2) * 40,
                0,
              ),
              child: Opacity(
                opacity: 0.2,
                child: _buildMountainLayer(),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildCloudLayer() {
    return Positioned(
      top: 50,
      left: 0,
      right: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildCloud(60),
          _buildCloud(80),
          _buildCloud(50),
        ],
      ),
    );
  }

  Widget _buildCloud(double size) {
    return Container(
      width: size,
      height: size * 0.5,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.3),
        borderRadius: BorderRadius.circular(size * 0.5),
      ),
    );
  }

  Widget _buildMountainLayer() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: CustomPaint(
        size: const Size(double.infinity, 150),
        painter: MountainPainter(),
      ),
    );
  }

  Widget _buildParticles() {
    return Stack(
      children: _particles.map((particle) {
        return Positioned(
          left: particle.x,
          top: particle.y,
          child: Opacity(
            opacity: particle.opacity,
            child: _buildParticleWidget(particle),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildParticleWidget(BackgroundParticle particle) {
    switch (particle.type) {
      case ParticleType.snowflake:
        return Text('❄️', style: TextStyle(fontSize: particle.size * 2));
      case ParticleType.butterfly:
        return Text('🦋', style: TextStyle(fontSize: particle.size * 2));
      case ParticleType.sparkle:
        return Container(
          width: particle.size,
          height: particle.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(0.8),
            boxShadow: [
              BoxShadow(
                color: Colors.white.withOpacity(0.5),
                blurRadius: particle.size,
              ),
            ],
          ),
        );
      case ParticleType.leaf:
        return Text('🍂', style: TextStyle(fontSize: particle.size * 2));
      case ParticleType.rain:
        return Container(
          width: 2,
          height: particle.size * 3,
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.6),
            borderRadius: BorderRadius.circular(1),
          ),
        );
    }
  }

  Widget _buildWeatherEffect() {
    // Basit hava durumu efekti - rastgele seçilir
    return const SizedBox.shrink();
  }
}

class BackgroundParticle {
  double x;
  double y;
  double size;
  double speed;
  ParticleType type;
  double opacity;

  BackgroundParticle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.type,
    required this.opacity,
  });
}

enum ParticleType {
  snowflake,
  butterfly,
  sparkle,
  leaf,
  rain,
}

class MountainPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, size.height);
    path.lineTo(0, size.height * 0.6);
    path.lineTo(size.width * 0.3, size.height * 0.3);
    path.lineTo(size.width * 0.5, size.height * 0.5);
    path.lineTo(size.width * 0.7, size.height * 0.2);
    path.lineTo(size.width, size.height * 0.4);
    path.lineTo(size.width, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

