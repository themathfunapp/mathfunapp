import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:provider/provider.dart';
import '../services/game_mechanics_service.dart';
import '../services/badge_service.dart';
import '../models/game_mechanics.dart';
import '../localization/app_localizations.dart';

/// Şans Çarkı Ekranı
class SpinWheelScreen extends StatefulWidget {
  final VoidCallback onBack;

  const SpinWheelScreen({super.key, required this.onBack});

  @override
  State<SpinWheelScreen> createState() => _SpinWheelScreenState();
}

class _SpinWheelScreenState extends State<SpinWheelScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  
  bool _isSpinning = false;
  SpinWheelReward? _reward;
  double _currentAngle = 0;

  final List<SpinWheelReward> rewards = SpinWheelReward.defaultRewards;
  final List<Color> wheelColors = [
    const Color(0xFFFF6B6B),
    const Color(0xFF4ECDC4),
    const Color(0xFFFFE66D),
    const Color(0xFF95E1D3),
    const Color(0xFFF38181),
    const Color(0xFFAA96DA),
    const Color(0xFFFCBF49),
    const Color(0xFF2EC4B6),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );

    _controller.addListener(() {
      setState(() {
        _currentAngle = _animation.value * 10 * math.pi + 
            (math.Random().nextDouble() * 2 * math.pi);
      });
    });

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _isSpinning = false;
        });
        _showRewardDialog();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _spin() async {
    final mechanicsService = Provider.of<GameMechanicsService>(context, listen: false);
    
    if (!mechanicsService.canSpin) {
      _showAlreadySpunDialog();
      return;
    }

    setState(() {
      _isSpinning = true;
    });

    try {
      _reward = await mechanicsService.spinWheel();
      if (!mounted) return;
      final badgeService = Provider.of<BadgeService>(context, listen: false);
      await badgeService.addSpinWheelReward(_reward!);
      if (!mounted) return;
      _controller.forward(from: 0);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSpinning = false;
      });
      _showAlreadySpunDialog();
    }
  }

  void _showRewardDialog() {
    if (_reward == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        final loc = AppLocalizations.of(dialogContext);
        final rewardName = loc.get('spin_reward_${_reward!.id}');
        final displayName = rewardName != 'spin_reward_${_reward!.id}' ? rewardName : _reward!.name;
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '🎉 ${loc.get('spin_wheel_congrats')} 🎉',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      _reward!.emoji,
                      style: const TextStyle(fontSize: 48),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  displayName,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    loc.get('spin_wheel_ok'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAlreadySpunDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        final loc = AppLocalizations.of(dialogContext);
        return AlertDialog(
          backgroundColor: const Color(0xFF764ba2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            '⏰ ${loc.get('spin_wheel_come_tomorrow_title')}',
            style: const TextStyle(color: Colors.white),
          ),
          content: Text(
            loc.get('spin_wheel_already_spun'),
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                loc.get('spin_wheel_ok'),
                style: const TextStyle(color: Colors.amber),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final mechanicsService = Provider.of<GameMechanicsService>(context);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1a1a2e),
              Color(0xFF16213e),
              Color(0xFF0f3460),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Üst bar
              _buildTopBar(localizations),

              const SizedBox(height: 20),

              // Başlık
              Text(
                '🎰 ${localizations.get('spin_wheel_title')} 🎰',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber,
                  shadows: [
                    Shadow(
                      color: Colors.amber,
                      blurRadius: 10,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              Text(
                mechanicsService.canSpin
                    ? localizations.get('spin_wheel_subtitle_free')
                    : localizations.get('spin_wheel_subtitle_tomorrow'),
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),

              const SizedBox(height: 30),

              // Çark
              Expanded(
                child: Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Çark
                      Transform.rotate(
                        angle: _currentAngle,
                        child: CustomPaint(
                          size: const Size(300, 300),
                          painter: WheelPainter(
                            rewards: rewards,
                            colors: wheelColors,
                          ),
                        ),
                      ),

                      // Merkez butonu
                      GestureDetector(
                        onTap: _isSpinning ? null : _spin,
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: mechanicsService.canSpin
                                  ? [Colors.amber, Colors.orange]
                                  : [Colors.grey, Colors.grey.shade700],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: mechanicsService.canSpin
                                    ? Colors.amber.withOpacity(0.5)
                                    : Colors.grey.withOpacity(0.3),
                                blurRadius: 15,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Center(
                            child: _isSpinning
                                ? const CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 3,
                                  )
                                : Text(
                                    localizations.get('spin_wheel_button'),
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                      ),

                      // Ok işareti
                      Positioned(
                        top: 0,
                        child: Container(
                          width: 0,
                          height: 0,
                          decoration: const BoxDecoration(
                            border: Border(
                              left: BorderSide(
                                width: 15,
                                color: Colors.transparent,
                              ),
                              right: BorderSide(
                                width: 15,
                                color: Colors.transparent,
                              ),
                              bottom: BorderSide(
                                width: 30,
                                color: Colors.amber,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Ödül listesi
              _buildRewardsList(localizations),

              const SizedBox(height: 20),
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
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_back_ios_new,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRewardsList(AppLocalizations localizations) {
    return Container(
      height: 80,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: rewards.length,
        itemBuilder: (context, index) {
          final reward = rewards[index];
          final rewardLabel = localizations.get('spin_reward_${reward.id}');
          final displayName = rewardLabel != 'spin_reward_${reward.id}' ? rewardLabel : reward.name;
          return Container(
            width: 70,
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: wheelColors[index % wheelColors.length].withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: wheelColors[index % wheelColors.length].withOpacity(0.5),
                width: 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  reward.emoji,
                  style: const TextStyle(fontSize: 24),
                ),
                const SizedBox(height: 4),
                Text(
                  displayName,
                  style: const TextStyle(
                    fontSize: 8,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Çark Painter
class WheelPainter extends CustomPainter {
  final List<SpinWheelReward> rewards;
  final List<Color> colors;

  WheelPainter({required this.rewards, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final sliceAngle = 2 * math.pi / rewards.length;

    for (int i = 0; i < rewards.length; i++) {
      final paint = Paint()
        ..color = colors[i % colors.length]
        ..style = PaintingStyle.fill;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        sliceAngle * i - math.pi / 2,
        sliceAngle,
        true,
        paint,
      );

      // Emoji çiz
      final angle = sliceAngle * i + sliceAngle / 2 - math.pi / 2;
      final textRadius = radius * 0.65;
      final textX = center.dx + textRadius * math.cos(angle);
      final textY = center.dy + textRadius * math.sin(angle);

      final textPainter = TextPainter(
        text: TextSpan(
          text: rewards[i].emoji,
          style: const TextStyle(fontSize: 24),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(textX - textPainter.width / 2, textY - textPainter.height / 2),
      );
    }

    // Dış çember
    final borderPaint = Paint()
      ..color = Colors.amber
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8;
    canvas.drawCircle(center, radius - 4, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

