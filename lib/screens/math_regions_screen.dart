import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../localization/app_localizations.dart';
import '../services/game_mechanics_service.dart';
import 'game_start_screen.dart';
import '../models/game_mechanics.dart' as GameMechanics;
import 'specialized_game_screen.dart';
import '../widgets/topic_level_flow.dart';
import 'cyber_workshop_screen.dart';
import 'number_river_screen.dart';
import 'time_island_screen.dart';
import 'keloglan_village_screen.dart';
import '../widgets/no_lives_gate_dialog.dart';

String? _regionDailyRewardHintKey(String regionId) {
  switch (regionId) {
    case 'keloglan_koyu':
      return 'keloglan_daily_reward_hint';
    case 'digit_river':
      return 'digit_river_daily_reward_hint';
    default:
      return null;
  }
}

String _topicDifficultyForAge(AgeGroupSelection age) {
  switch (age) {
    case AgeGroupSelection.preschool:
      return 'Kolay';
    case AgeGroupSelection.elementary:
      return 'Orta';
    case AgeGroupSelection.advanced:
      return 'Zor';
  }
}

/// Matematik Bölgeleri Ekranı (Dünya Haritası)
class MathRegionsScreen extends StatefulWidget {
  final AgeGroupSelection ageGroup;
  final VoidCallback onBack;

  const MathRegionsScreen({
    super.key,
    required this.ageGroup,
    required this.onBack,
  });

  @override
  State<MathRegionsScreen> createState() => _MathRegionsScreenState();
}

class _MathRegionsScreenState extends State<MathRegionsScreen>
    with TickerProviderStateMixin {
  late AnimationController _floatController;
  late AnimationController _sparkleController;
  late Animation<double> _floatAnimation;
  late Animation<double> _sparkleAnimation;

  int? _selectedRegion;

  @override
  void initState() {
    super.initState();

    _floatController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _floatAnimation = Tween<double>(begin: -5, end: 5).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    _sparkleController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    _sparkleAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _sparkleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _floatController.dispose();
    _sparkleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final regions = _getRegions(localizations);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1a237e),
              Color(0xFF4a148c),
              Color(0xFF880e4f),
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Yıldızlar arka planı
              ..._buildStars(),

              Column(
                children: [
                  // Üst bar
                  _buildTopBar(localizations),

                  // Başlık
                  _buildHeader(localizations),

                  // Harita
                  Expanded(
                    child: _buildMap(regions, localizations),
                  ),

                  // Alt bilgi
                  if (_selectedRegion != null)
                    _buildRegionInfo(regions[_selectedRegion!], localizations),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildStars() {
    return List.generate(30, (index) {
      final random = math.Random(index);
      final left = random.nextDouble() * 400;
      final top = random.nextDouble() * 600;
      final size = random.nextDouble() * 3 + 1;

      return Positioned(
        left: left,
        top: top,
        child: AnimatedBuilder(
          animation: _sparkleAnimation,
          builder: (context, child) {
            return Opacity(
              opacity: _sparkleAnimation.value * (index % 3 == 0 ? 1 : 0.5),
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withOpacity(0.5),
                      blurRadius: size * 2,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
    });
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
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_back_ios_new,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildHeader(AppLocalizations localizations) {
    return AnimatedBuilder(
      animation: _floatAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _floatAnimation.value),
          child: Column(
            children: [
              Text(
                localizations.get('math_world'),
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                localizations.get('choose_adventure'),
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMap(List<Map<String, dynamic>> regions, AppLocalizations localizations) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Stack(
        children: [
          // Bağlantı yolları
          CustomPaint(
            size: Size.infinite,
            painter: _ConnectionPainter(regions.length),
          ),

          // Bölge ikonları
          ...regions.asMap().entries.map((entry) {
            final index = entry.key;
            final region = entry.value;
            final position = _getRegionPosition(index, regions.length);

            return Positioned(
              left: position.dx - 45,
              top: position.dy - 45,
              child: _buildRegionNode(region, index),
            );
          }),
        ],
      ),
    );
  }

  Offset _getRegionPosition(int index, int total) {
    final screenWidth = MediaQuery.of(context).size.width - 32;
    final screenHeight = MediaQuery.of(context).size.height * 0.5;

    // Zigzag düzeni
    final row = index ~/ 2;
    final col = index % 2;

    final x = col == 0
        ? screenWidth * 0.25
        : screenWidth * 0.75;
    final y = (row + 0.5) * (screenHeight / ((total + 1) ~/ 2));

    return Offset(x, y);
  }

  Widget _buildRegionNode(Map<String, dynamic> region, int index) {
    final isSelected = _selectedRegion == index;
    final isLocked = region['locked'] == true;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedRegion = index;
        });
      },
      child: AnimatedBuilder(
        animation: _floatAnimation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, _floatAnimation.value * (index % 2 == 0 ? 1 : -1)),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: isSelected ? 100 : 90,
              height: isSelected ? 100 : 90,
              decoration: BoxDecoration(
                gradient: isLocked
                    ? LinearGradient(
                  colors: [Colors.grey.shade600, Colors.grey.shade800],
                )
                    : LinearGradient(
                  colors: [
                    region['color'] as Color,
                    (region['color'] as Color).withOpacity(0.7),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? Colors.amber : Colors.white.withOpacity(0.5),
                  width: isSelected ? 4 : 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isLocked
                        ? Colors.black.withOpacity(0.3)
                        : (region['color'] as Color).withOpacity(0.5),
                    blurRadius: isSelected ? 20 : 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        region['emoji'] as String,
                        style: TextStyle(
                          fontSize: isSelected ? 36 : 32,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            region['name'] as String,
                            style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                              color: Colors.white.withOpacity(0.9),
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (isLocked)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.lock,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRegionInfo(Map<String, dynamic> region, AppLocalizations localizations) {
    final isLocked = region['locked'] == true;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.15),
            Colors.white.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: isLocked
                      ? Colors.grey.withOpacity(0.3)
                      : (region['color'] as Color).withOpacity(0.3),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    region['emoji'] as String,
                    style: TextStyle(
                      fontSize: 32,
                      color: isLocked ? Colors.grey.shade400 : Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      region['name'] as String,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isLocked ? Colors.grey.shade400 : Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      region['description'] as String,
                      style: TextStyle(
                        fontSize: 12,
                        color: isLocked
                            ? Colors.grey.shade500
                            : Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (!isLocked && _regionDailyRewardHintKey(region['id'] as String) != null) ...[
            const SizedBox(height: 12),
            Text(
              localizations.get(_regionDailyRewardHintKey(region['id'] as String)!),
              style: TextStyle(
                fontSize: 12,
                color: Colors.amber.shade200,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 16),
          if (!isLocked) ...[
            // Başla butonu
            GestureDetector(
              onTap: () => _enterRegion(region),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      region['color'] as Color,
                      (region['color'] as Color).withOpacity(0.7),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: (region['color'] as Color).withOpacity(0.4),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      localizations.get('enter_region'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.arrow_forward,
                      color: Colors.white,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            // Kilit açma bilgisi
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.orange.withOpacity(0.5),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lock_clock, color: Colors.orange, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '🔒 ${localizations.get('region_locked_panel_title')}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _getRegions(AppLocalizations localizations) {
    // SADECE İLK İKİ BÖLGE AÇIK, DİĞERLERİ KİLİTLİ
    return [
      // 1. Bölge - Keloğlan'ın Köyü (AÇIK) - Paylaştırma ve Kesir teması
      {
        'id': 'keloglan_koyu',
        'emoji': '🧑‍🌾',
        'shortName': localizations.get('keloglan_village_short'),
        'name': localizations.get('keloglan_village'),
        'description': localizations.get('keloglan_village_desc'),
        'color': const Color(0xFF8BC34A),
        'progress': 45,
        'locked': false,
      },
      // 2. Bölge - Rakam Nehri (AÇIK)
      {
        'id': 'digit_river',
        'emoji': '🌊',
        'shortName': localizations.get('river'),
        'name': localizations.get('digit_river'),
        'description': localizations.get('digit_river_desc'),
        'color': const Color(0xFF3498DB),
        'progress': 20,
        'locked': false,
      },
      // 3. Bölge - Geometri Dağı (KİLİTLİ)
      {
        'id': 'geometry_mountain',
        'emoji': '⛰️',
        'shortName': localizations.get('mountain'),
        'name': localizations.get('geometry_mountain'),
        'description': localizations.get('geometry_mountain_desc'),
        'color': const Color(0xFF9B59B6),
        'progress': 0,
        'locked': true,
      },
      // 4. Bölge - Zaman Adası (KİLİTLİ)
      {
        'id': 'time_island',
        'emoji': '🏝️',
        'shortName': localizations.get('island'),
        'name': localizations.get('time_island'),
        'description': localizations.get('time_island_desc'),
        'color': const Color(0xFFE67E22),
        'progress': 0,
        'locked': true,
      },
      // 5. Bölge - Sihirli Makine (KİLİTLİ)
      {
        'id': 'magic_machine',
        'emoji': '🧮',
        'shortName': localizations.get('machine'),
        'name': localizations.get('magic_machine_region'),
        'description': localizations.get('magic_machine_region_desc'),
        'color': const Color(0xFF00BCD4),
        'progress': 0,
        'locked': true,
      },
    ];
  }

  void _enterRegion(Map<String, dynamic> region) {
    // Kilitli bölgeye girilmeye çalışılırsa uyarı göster
    if (region['locked'] == true) {
      _showLockedRegionDialog(region);
      return;
    }

    final mechanicsService = Provider.of<GameMechanicsService>(context, listen: false);
    if (!mechanicsService.hasLives) {
      showNoLivesGateDialog(context);
      return;
    }

    debugPrint('Entering region: ${region['id']}');

    // Keloğlan'ın Köyü için özel ekran (Paylaştırma ve Kesir teması)
    if (region['id'] == 'keloglan_koyu') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => KeloglanVillageScreen(
            ageGroup: widget.ageGroup,
            onBack: () => Navigator.pop(context),
          ),
        ),
      );
      return;
    }

    // Sayı Ormanı → Sayma (seviye kaydı + Kolay/Orta/Zor)
    if (region['id'] == 'number_forest') {
      TopicLevelFlow.openStandardMathTopic(
        context,
        topicId: 'counting',
        ageGroup: widget.ageGroup,
      );
      return;
    }

    // Çıkarma Dağı → Çıkarma konusu
    if (region['id'] == 'subtraction_mountain') {
      TopicLevelFlow.openStandardMathTopic(
        context,
        topicId: 'subtraction',
        ageGroup: widget.ageGroup,
      );
      return;
    }

    // Çarpma Kalesi → Çarpma konusu
    if (region['id'] == 'multiplication_castle') {
      TopicLevelFlow.openStandardMathTopic(
        context,
        topicId: 'multiplication',
        ageGroup: widget.ageGroup,
      );
      return;
    }

    // Bölme Çölü → Bölme konusu
    if (region['id'] == 'division_desert') {
      TopicLevelFlow.openStandardMathTopic(
        context,
        topicId: 'division',
        ageGroup: widget.ageGroup,
      );
      return;
    }

    // Rakam Nehri için özel ekran
    if (region['id'] == 'digit_river') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => NumberRiverScreen(
            ageGroup: widget.ageGroup,
            onBack: () => Navigator.pop(context),
          ),
        ),
      );
      return;
    }

    // Geometri Dağı → Geometri konusu (seviye + formül ipuçları)
    if (region['id'] == 'geometry_mountain') {
      TopicLevelFlow.openStandardMathTopic(
        context,
        topicId: 'geometry',
        ageGroup: widget.ageGroup,
      );
      return;
    }

    // Zaman Adası için özel ekran
    if (region['id'] == 'time_island') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TimeIslandScreen(
            ageGroup: widget.ageGroup.toString().split('.').last,
          ),
        ),
      );
      return;
    }

    // Region ID'sine göre TopicType belirle
    GameMechanics.TopicType topicType;
    switch (region['id'] as String) {
      case 'siber_atolye':
      case 'number_forest':
        topicType = GameMechanics.TopicType.counting;
        break;
      case 'digit_river':
        topicType = GameMechanics.TopicType.addition;
        break;
      case 'subtraction_mountain':
        topicType = GameMechanics.TopicType.subtraction;
        break;
      case 'multiplication_castle':
        topicType = GameMechanics.TopicType.multiplication;
        break;
      case 'division_desert':
        topicType = GameMechanics.TopicType.division;
        break;
      case 'geometry_island':
        topicType = GameMechanics.TopicType.geometry;
        break;
      default:
        topicType = GameMechanics.TopicType.addition;
    }

    // Topic ayarlarını al
    final topicSettings = GameMechanics.TopicGameManager.getTopicSettings()[topicType]!;

    // Oyun ekranına git
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SpecializedGameScreen(
          topicSettings: topicSettings,
          ageGroup: widget.ageGroup,
          difficulty: _topicDifficultyForAge(widget.ageGroup),
          onBack: () => Navigator.pop(context),
        ),
      ),
    );
  }

  void _showLockedRegionDialog(Map<String, dynamic> region) {
    final loc = AppLocalizations.of(context);
    final name = region['name'] as String? ?? '';
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.grey.shade800, Colors.grey.shade900],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.orange.shade300, width: 2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_clock, color: Colors.orange, size: 60),
              const SizedBox(height: 16),
              Text(
                '🔒 $name${loc.get('region_locked_name_suffix')}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                loc.get('region_locked_panel_title'),
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.orange.shade200,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                ),
                child: Text(loc.get('ok')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Bağlantı çizgileri painter
class _ConnectionPainter extends CustomPainter {
  final int nodeCount;

  _ConnectionPainter(this.nodeCount);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    // Noktalar arası bağlantılar
    for (int i = 0; i < nodeCount - 1; i++) {
      final start = _getNodeCenter(i, nodeCount, size);
      final end = _getNodeCenter(i + 1, nodeCount, size);

      // Eğri çizgi
      final controlPoint = Offset(
        (start.dx + end.dx) / 2,
        (start.dy + end.dy) / 2 + (i % 2 == 0 ? 30 : -30),
      );

      final path = Path()
        ..moveTo(start.dx, start.dy)
        ..quadraticBezierTo(controlPoint.dx, controlPoint.dy, end.dx, end.dy);

      canvas.drawPath(path, paint);
    }
  }

  Offset _getNodeCenter(int index, int total, Size size) {
    final row = index ~/ 2;
    final col = index % 2;

    final x = col == 0 ? size.width * 0.25 : size.width * 0.75;
    final y = (row + 0.5) * (size.height / ((total + 1) ~/ 2));

    return Offset(x, y);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}