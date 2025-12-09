import 'dart:async';

import 'package:flutter/material.dart';

class AnimatedMathSymbol extends StatefulWidget {
  const AnimatedMathSymbol({super.key});

  @override
  State<AnimatedMathSymbol> createState() => _AnimatedMathSymbolState();
}

class _AnimatedMathSymbolState extends State<AnimatedMathSymbol>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotationAnimation;
  int _symbolIndex = 0;
  final List<String> _mathSymbols = ['➕', '➖', '✖️', '➗'];

  @override
  void initState() {
    super.initState();

    // Rotasyon animasyonu
    _controller = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat();

    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 2 * 3.14159, // 360 derece radyan cinsinden
    ).animate(_controller);

    // Sembol değişim timer'ı
    Future.delayed(Duration.zero, () {
      Timer.periodic(const Duration(seconds: 2), (timer) {
        if (mounted) {
          setState(() {
            _symbolIndex = (_symbolIndex + 1) % _mathSymbols.length;
          });
        }
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _rotationAnimation,
      builder: (context, child) {
        return Transform.rotate(
          angle: _rotationAnimation.value,
          child: child,
        );
      },
      child: Container(
        width: 80,
        height: 80,
        alignment: Alignment.center,
        child: Transform.scale(
          scale: 1.2,
          child: Text(
            _mathSymbols[_symbolIndex],
            style: const TextStyle(fontSize: 48),
          ),
        ),
      ),
    );
  }
}