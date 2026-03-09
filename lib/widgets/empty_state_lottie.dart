import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

/// Boş durumlar için Lottie veya animasyonlu ikon
class EmptyStateLottie extends StatefulWidget {
  final String? message;
  final double size;
  final String? lottieUrl;
  final String? assetPath;
  final IconData? fallbackIcon;

  const EmptyStateLottie({
    super.key,
    this.message,
    this.size = 160,
    this.lottieUrl,
    this.assetPath,
    this.fallbackIcon,
  });

  @override
  State<EmptyStateLottie> createState() => _EmptyStateLottieState();
}

class _EmptyStateLottieState extends State<EmptyStateLottie>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.05).animate(
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: widget.size,
          height: widget.size,
          child: _buildAnimation(),
        ),
        if (widget.message != null && widget.message!.isNotEmpty) ...[
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              widget.message!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withValues(alpha: 0.85),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildAnimation() {
    if (widget.assetPath != null) {
      return Lottie.asset(
        widget.assetPath!,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => _buildFallbackIcon(),
      );
    }
    if (widget.lottieUrl != null && widget.lottieUrl!.isNotEmpty) {
      return Lottie.network(
        widget.lottieUrl!,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => _buildFallbackIcon(),
      );
    }
    return _buildFallbackIcon();
  }

  Widget _buildFallbackIcon() {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Icon(
        widget.fallbackIcon ?? Icons.inbox_outlined,
        size: widget.size * 0.5,
        color: Colors.white.withValues(alpha: 0.5),
      ),
    );
  }
}
