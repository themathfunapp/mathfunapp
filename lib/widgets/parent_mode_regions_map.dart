import 'package:flutter/material.dart';

import '../models/game_mechanics.dart' show TopicType;

/// Ebeveyn modu “Matematik Bölgeleri” haritası (ayrı dosya → Web hot reload uyumu).
class ParentModeRegionsMap extends StatelessWidget {
  final VoidCallback onExploreAll;
  final void Function(TopicType topic) onPickRegion;

  // ignore: prefer_const_constructors_in_immutables — callback alanları const değil
  ParentModeRegionsMap({
    super.key,
    required this.onExploreAll,
    required this.onPickRegion,
  });

  static const List<_PmRegionData> _nodes = [
    _PmRegionData(
      emoji: '🧒',
      label: "Keloğlan'ın Köyü",
      topic: TopicType.counting,
    ),
    _PmRegionData(
      emoji: '🔢',
      label: 'Rakam Nehri',
      topic: TopicType.addition,
    ),
    _PmRegionData(
      emoji: '🔺',
      label: 'Geometri Dağı',
      topic: TopicType.geometry,
    ),
    _PmRegionData(
      emoji: '⏰',
      label: 'Zaman Adası',
      topic: TopicType.time,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Color(0xFF2ECC71),
            Color(0xFF3498DB),
            Color(0xFF9B59B6),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(painter: _PmGridPainter()),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 56),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Matematik Bölgeleri',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Bölge seç',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Yuvarlağa dokun → o konuda yarış',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (var i = 0; i < _nodes.length; i++) ...[
                          if (i > 0) const _PmPathJoin(),
                          _PmRegionOrb(
                            data: _nodes[i],
                            onTap: () => onPickRegion(_nodes[i].topic),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              right: 16,
              bottom: 12,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF6B48FF),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                onPressed: onExploreAll,
                icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                label: const Text('Tüm konular'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PmRegionData {
  final String emoji;
  final String label;
  final TopicType topic;

  const _PmRegionData({
    required this.emoji,
    required this.label,
    required this.topic,
  });
}

class _PmRegionOrb extends StatelessWidget {
  final _PmRegionData data;
  final VoidCallback onTap;

  // ignore: prefer_const_constructors_in_immutables
  _PmRegionOrb({
    required this.data,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.95),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 8,
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Text(data.emoji, style: const TextStyle(fontSize: 28)),
              ),
              const SizedBox(height: 6),
              SizedBox(
                width: 76,
                child: Text(
                  data.label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    height: 1.1,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PmPathJoin extends StatelessWidget {
  const _PmPathJoin();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 28, left: 4, right: 4),
      child: CustomPaint(
        size: const Size(24, 8),
        painter: _PmCurvePainter(),
      ),
    );
  }
}

class _PmCurvePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = Colors.white.withValues(alpha: 0.5)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final path = Path();
    path.moveTo(0, size.height / 2);
    path.quadraticBezierTo(size.width / 2, 0, size.width, size.height / 2);
    canvas.drawPath(path, p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PmGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..strokeWidth = 1;
    const step = 20.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), p);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
