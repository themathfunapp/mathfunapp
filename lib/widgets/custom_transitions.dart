import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Özel Sayfa Geçişleri
/// Kitap açılma, portal, ışık patlaması efektleri

/// Kitap Açılma Geçişi
class BookPageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  BookPageRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: const Duration(milliseconds: 600),
          reverseTransitionDuration: const Duration(milliseconds: 400),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return BookPageTransition(
              animation: animation,
              child: child,
            );
          },
        );
}

class BookPageTransition extends StatelessWidget {
  final Animation<double> animation;
  final Widget child;

  const BookPageTransition({
    super.key,
    required this.animation,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final rotateAnimation = Tween<double>(begin: math.pi / 2, end: 0).animate(
      CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
    );

    final fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: animation,
        curve: const Interval(0.3, 1.0, curve: Curves.easeIn),
      ),
    );

    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        return Transform(
          alignment: Alignment.centerLeft,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateY(rotateAnimation.value),
          child: Opacity(
            opacity: fadeAnimation.value,
            child: child,
          ),
        );
      },
    );
  }
}

/// Portal Geçişi
class PortalPageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  PortalPageRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: const Duration(milliseconds: 800),
          reverseTransitionDuration: const Duration(milliseconds: 500),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return PortalTransition(
              animation: animation,
              child: child,
            );
          },
        );
}

class PortalTransition extends StatelessWidget {
  final Animation<double> animation;
  final Widget child;

  const PortalTransition({
    super.key,
    required this.animation,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final scaleAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: animation, curve: Curves.elasticOut),
    );

    final rotateAnimation = Tween<double>(begin: math.pi, end: 0).animate(
      CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
    );

    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        return Transform.scale(
          scale: scaleAnimation.value,
          child: Transform.rotate(
            angle: rotateAnimation.value,
            child: child,
          ),
        );
      },
    );
  }
}

/// Işık Patlaması Geçişi
class LightBurstPageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  LightBurstPageRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: const Duration(milliseconds: 700),
          reverseTransitionDuration: const Duration(milliseconds: 400),
          opaque: false,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return LightBurstTransition(
              animation: animation,
              child: child,
            );
          },
        );
}

class LightBurstTransition extends StatelessWidget {
  final Animation<double> animation;
  final Widget child;

  const LightBurstTransition({
    super.key,
    required this.animation,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final burstAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: animation,
        curve: const Interval(0, 0.5, curve: Curves.easeOut),
      ),
    );

    final contentAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: animation,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
      ),
    );

    return Stack(
      children: [
        // Işık patlaması efekti
        AnimatedBuilder(
          animation: burstAnimation,
          builder: (context, _) {
            return Center(
              child: Container(
                width: MediaQuery.of(context).size.width * 3 * burstAnimation.value,
                height: MediaQuery.of(context).size.height * 3 * burstAnimation.value,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.white.withOpacity(1 - burstAnimation.value),
                      Colors.amber.withOpacity(0.5 - burstAnimation.value * 0.5),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        // İçerik
        Opacity(
          opacity: contentAnimation.value,
          child: child,
        ),
      ],
    );
  }
}

/// Seviye Atlama Geçişi
class LevelUpPageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  LevelUpPageRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: const Duration(milliseconds: 1000),
          reverseTransitionDuration: const Duration(milliseconds: 400),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return LevelUpTransition(
              animation: animation,
              child: child,
            );
          },
        );
}

class LevelUpTransition extends StatelessWidget {
  final Animation<double> animation;
  final Widget child;

  const LevelUpTransition({
    super.key,
    required this.animation,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: animation,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOutBack),
      ),
    );

    final numberAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: animation,
        curve: const Interval(0, 0.5, curve: Curves.easeOut),
      ),
    );

    return Stack(
      children: [
        // Sayı animasyonu (3, 2, 1...)
        if (animation.value < 0.5)
          Center(
            child: Transform.scale(
              scale: 1 + (1 - numberAnimation.value) * 2,
              child: Opacity(
                opacity: 1 - numberAnimation.value,
                child: Text(
                  '${3 - (animation.value * 6).floor()}',
                  style: const TextStyle(
                    fontSize: 100,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber,
                    shadows: [
                      Shadow(
                        color: Colors.amber,
                        blurRadius: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        // Sayfa içeriği
        SlideTransition(
          position: slideAnimation,
          child: child,
        ),
      ],
    );
  }
}

/// Kayan Geçiş (Slide)
class SlidePageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  final SlideDirection direction;

  SlidePageRoute({
    required this.page,
    this.direction = SlideDirection.right,
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: const Duration(milliseconds: 400),
          reverseTransitionDuration: const Duration(milliseconds: 300),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            Offset begin;
            switch (direction) {
              case SlideDirection.right:
                begin = const Offset(1, 0);
                break;
              case SlideDirection.left:
                begin = const Offset(-1, 0);
                break;
              case SlideDirection.up:
                begin = const Offset(0, 1);
                break;
              case SlideDirection.down:
                begin = const Offset(0, -1);
                break;
            }

            final slideAnimation = Tween<Offset>(
              begin: begin,
              end: Offset.zero,
            ).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            );

            return SlideTransition(
              position: slideAnimation,
              child: child,
            );
          },
        );
}

enum SlideDirection { right, left, up, down }

/// Ölçek + Fade Geçişi
class ScaleFadePageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  ScaleFadePageRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: const Duration(milliseconds: 400),
          reverseTransitionDuration: const Duration(milliseconds: 300),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final scaleAnimation = Tween<double>(begin: 0.9, end: 1).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOut),
            );

            final fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeIn),
            );

            return FadeTransition(
              opacity: fadeAnimation,
              child: ScaleTransition(
                scale: scaleAnimation,
                child: child,
              ),
            );
          },
        );
}

/// Dairesel Açılma Geçişi
class CircularRevealPageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  final Offset? center;

  CircularRevealPageRoute({
    required this.page,
    this.center,
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: const Duration(milliseconds: 500),
          reverseTransitionDuration: const Duration(milliseconds: 400),
          opaque: false,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return CircularRevealTransition(
              animation: animation,
              center: center,
              child: child,
            );
          },
        );
}

class CircularRevealTransition extends StatelessWidget {
  final Animation<double> animation;
  final Offset? center;
  final Widget child;

  const CircularRevealTransition({
    super.key,
    required this.animation,
    this.center,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final maxRadius = math.sqrt(
      screenSize.width * screenSize.width + screenSize.height * screenSize.height,
    );

    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        return ClipPath(
          clipper: CircularRevealClipper(
            fraction: animation.value,
            center: center ?? Offset(screenSize.width / 2, screenSize.height / 2),
            maxRadius: maxRadius,
          ),
          child: child,
        );
      },
    );
  }
}

class CircularRevealClipper extends CustomClipper<Path> {
  final double fraction;
  final Offset center;
  final double maxRadius;

  CircularRevealClipper({
    required this.fraction,
    required this.center,
    required this.maxRadius,
  });

  @override
  Path getClip(Size size) {
    final path = Path();
    path.addOval(
      Rect.fromCircle(
        center: center,
        radius: maxRadius * fraction,
      ),
    );
    return path;
  }

  @override
  bool shouldReclip(CircularRevealClipper oldClipper) {
    return oldClipper.fraction != fraction;
  }
}

/// Animasyonlu Sayfa Geçiş Helper
class PageTransitions {
  static Route<T> book<T>(Widget page) => BookPageRoute<T>(page: page);
  static Route<T> portal<T>(Widget page) => PortalPageRoute<T>(page: page);
  static Route<T> lightBurst<T>(Widget page) => LightBurstPageRoute<T>(page: page);
  static Route<T> levelUp<T>(Widget page) => LevelUpPageRoute<T>(page: page);
  static Route<T> slide<T>(Widget page, {SlideDirection direction = SlideDirection.right}) =>
      SlidePageRoute<T>(page: page, direction: direction);
  static Route<T> scaleFade<T>(Widget page) => ScaleFadePageRoute<T>(page: page);
  static Route<T> circular<T>(Widget page, {Offset? center}) =>
      CircularRevealPageRoute<T>(page: page, center: center);
}

