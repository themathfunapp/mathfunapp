import 'package:flutter/material.dart';

/// Arkadaşlar ekranı — renkli, nabız animasyonlu arama / arkadaş ekle kısayolu.
class AnimatedFriendsSearchButton extends StatefulWidget {
  final VoidCallback onPressed;
  final String tooltip;

  const AnimatedFriendsSearchButton({
    super.key,
    required this.onPressed,
    required this.tooltip,
  });

  @override
  State<AnimatedFriendsSearchButton> createState() =>
      _AnimatedFriendsSearchButtonState();
}

class _AnimatedFriendsSearchButtonState extends State<AnimatedFriendsSearchButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _glow;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _scale = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _glow = Tween<double>(begin: 0.35, end: 0.85).animate(
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
    return Tooltip(
      message: widget.tooltip,
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.scale(
              scale: _scale.value,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFFFFD93D),
                      Color(0xFFFF6B6B),
                      Color(0xFF9B5DE5),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF6B6B).withOpacity(_glow.value),
                      blurRadius: 14,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: child,
              ),
            );
          },
          child: const Icon(Icons.search_rounded, color: Colors.white, size: 28),
        ),
      ),
    );
  }
}
