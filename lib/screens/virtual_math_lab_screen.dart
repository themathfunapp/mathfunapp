import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Sanal Matematik Laboratuvarı
/// Deneyler, araçlar, simülasyonlar
class VirtualMathLabScreen extends StatefulWidget {
  final VoidCallback onBack;

  const VirtualMathLabScreen({super.key, required this.onBack});

  @override
  State<VirtualMathLabScreen> createState() => _VirtualMathLabScreenState();
}

class _VirtualMathLabScreenState extends State<VirtualMathLabScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0f3460),
              Color(0xFF16213e),
              Color(0xFF1a1a2e),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Üst bar
              _buildTopBar(),

              // Tab bar
              Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white60,
                  tabs: const [
                    Tab(icon: Icon(Icons.science), text: 'Deneyler'),
                    Tab(icon: Icon(Icons.straighten), text: 'Araçlar'),
                    Tab(icon: Icon(Icons.analytics), text: 'Simülasyon'),
                  ],
                ),
              ),

              // İçerik
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildExperimentsTab(),
                    _buildToolsTab(),
                    _buildSimulationsTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
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
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '🔬 Sanal Matematik Laboratuvarı',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Deney yap, keşfet!',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExperimentsTab() {
    final experiments = [
      LabExperiment(
        id: 'geometry',
        name: 'Geometri Deneyi',
        emoji: '📐',
        description: 'Şekillerin açılarını keşfet',
        color: Colors.blue,
      ),
      LabExperiment(
        id: 'fractions',
        name: 'Kesir Karışımları',
        emoji: '🧪',
        description: 'Kesirleri karıştır ve birleştir',
        color: Colors.purple,
      ),
      LabExperiment(
        id: 'symmetry',
        name: 'Simetri Aynası',
        emoji: '🪞',
        description: 'Simetrik şekiller oluştur',
        color: Colors.teal,
      ),
      LabExperiment(
        id: 'patterns',
        name: 'Örüntü Oluşturucu',
        emoji: '🔢',
        description: 'Sayı örüntüleri bul',
        color: Colors.orange,
      ),
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: experiments.length,
      itemBuilder: (context, index) {
        final exp = experiments[index];
        return _buildExperimentCard(exp);
      },
    );
  }

  Widget _buildExperimentCard(LabExperiment experiment) {
    return GestureDetector(
      onTap: () => _openExperiment(experiment),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              experiment.color.withOpacity(0.3),
              experiment.color.withOpacity(0.1),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: experiment.color.withOpacity(0.5),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: experiment.color.withOpacity(0.3),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(
                  experiment.emoji,
                  style: const TextStyle(fontSize: 32),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    experiment.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    experiment.description,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: experiment.color,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolsTab() {
    final tools = [
      LabTool(name: 'Cetvel', emoji: '📏', description: 'Uzunluk ölç'),
      LabTool(name: 'İletki', emoji: '📐', description: 'Açı ölç'),
      LabTool(name: 'Pergel', emoji: '⭕', description: 'Daire çiz'),
      LabTool(name: 'Hesap Makinesi', emoji: '🧮', description: 'Hesapla'),
      LabTool(name: 'Grafik Çizici', emoji: '📊', description: 'Grafik oluştur'),
      LabTool(name: 'Küp Oluşturucu', emoji: '🧊', description: '3D şekil'),
    ];

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 1.1,
      ),
      itemCount: tools.length,
      itemBuilder: (context, index) {
        final tool = tools[index];
        return _buildToolCard(tool);
      },
    );
  }

  Widget _buildToolCard(LabTool tool) {
    return GestureDetector(
      onTap: () => _openTool(tool),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(tool.emoji, style: const TextStyle(fontSize: 48)),
            const SizedBox(height: 8),
            Text(
              tool.name,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              tool.description,
              style: const TextStyle(
                fontSize: 10,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSimulationsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Olasılık simülasyonu
          _buildSimulationCard(
            title: '🎲 Zar Atma Simülasyonu',
            description: 'Zar at ve olasılıkları gör',
            child: _buildDiceSimulation(),
          ),

          const SizedBox(height: 16),

          // Sayı doğrusu simülasyonu
          _buildSimulationCard(
            title: '📊 Sayı Doğrusu',
            description: 'Sayıları görselleştir',
            child: _buildNumberLineSimulation(),
          ),

          const SizedBox(height: 16),

          // Kesir simülasyonu
          _buildSimulationCard(
            title: '🍕 Kesir Dilimi',
            description: 'Kesirleri pizza ile öğren',
            child: _buildFractionSimulation(),
          ),
        ],
      ),
    );
  }

  Widget _buildSimulationCard({
    required String title,
    required String description,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            description,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildDiceSimulation() {
    return StatefulBuilder(
      builder: (context, setState) {
        int diceValue = 1;
        final counts = <int, int>{1: 0, 2: 0, 3: 0, 4: 0, 5: 0, 6: 0};

        return Column(
          children: [
            // Zar gösterimi
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  _getDiceEmoji(diceValue),
                  style: const TextStyle(fontSize: 48),
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  diceValue = math.Random().nextInt(6) + 1;
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.black,
              ),
              child: const Text('🎲 Zar At'),
            ),
          ],
        );
      },
    );
  }

  String _getDiceEmoji(int value) {
    switch (value) {
      case 1: return '⚀';
      case 2: return '⚁';
      case 3: return '⚂';
      case 4: return '⚃';
      case 5: return '⚄';
      case 6: return '⚅';
      default: return '⚀';
    }
  }

  Widget _buildNumberLineSimulation() {
    return StatefulBuilder(
      builder: (context, setState) {
        double value = 5;

        return Column(
          children: [
            // Sayı göstergesi
            Text(
              value.toInt().toString(),
              style: const TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Colors.amber,
              ),
            ),
            const SizedBox(height: 8),
            // Slider
            Slider(
              value: value,
              min: 0,
              max: 10,
              divisions: 10,
              activeColor: Colors.amber,
              inactiveColor: Colors.white24,
              onChanged: (v) {
                setState(() {
                  value = v;
                });
              },
            ),
            // Sayı doğrusu
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(11, (index) {
                return Text(
                  '$index',
                  style: TextStyle(
                    fontSize: 12,
                    color: index == value.toInt() 
                        ? Colors.amber 
                        : Colors.white70,
                    fontWeight: index == value.toInt() 
                        ? FontWeight.bold 
                        : FontWeight.normal,
                  ),
                );
              }),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFractionSimulation() {
    return StatefulBuilder(
      builder: (context, setState) {
        int numerator = 3;
        int denominator = 8;

        return Column(
          children: [
            // Pizza gösterimi
            Container(
              width: 150,
              height: 150,
              child: CustomPaint(
                painter: PizzaPainter(
                  numerator: numerator,
                  denominator: denominator,
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Kesir gösterimi
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Column(
                  children: [
                    Text(
                      '$numerator',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber,
                      ),
                    ),
                    Container(
                      width: 40,
                      height: 3,
                      color: Colors.white,
                    ),
                    Text(
                      '$denominator',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Kontroller
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: () {
                    if (numerator > 0) {
                      setState(() => numerator--);
                    }
                  },
                  icon: const Icon(Icons.remove_circle, color: Colors.white),
                ),
                Text(
                  'Dilim',
                  style: const TextStyle(color: Colors.white70),
                ),
                IconButton(
                  onPressed: () {
                    if (numerator < denominator) {
                      setState(() => numerator++);
                    }
                  },
                  icon: const Icon(Icons.add_circle, color: Colors.white),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  void _openExperiment(LabExperiment experiment) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${experiment.name} açılıyor...'),
        backgroundColor: experiment.color,
      ),
    );
  }

  void _openTool(LabTool tool) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${tool.name} açılıyor...'),
        backgroundColor: Colors.blue,
      ),
    );
  }
}

class LabExperiment {
  final String id;
  final String name;
  final String emoji;
  final String description;
  final Color color;

  LabExperiment({
    required this.id,
    required this.name,
    required this.emoji,
    required this.description,
    required this.color,
  });
}

class LabTool {
  final String name;
  final String emoji;
  final String description;

  LabTool({
    required this.name,
    required this.emoji,
    required this.description,
  });
}

// Pizza Painter
class PizzaPainter extends CustomPainter {
  final int numerator;
  final int denominator;

  PizzaPainter({required this.numerator, required this.denominator});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;

    // Pizza arka planı
    final bgPaint = Paint()
      ..color = Colors.orange.shade200
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, bgPaint);

    // Dilimler
    final sliceAngle = 2 * math.pi / denominator;
    final filledPaint = Paint()
      ..color = Colors.amber
      ..style = PaintingStyle.fill;

    for (int i = 0; i < numerator; i++) {
      final startAngle = -math.pi / 2 + i * sliceAngle;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sliceAngle,
        true,
        filledPaint,
      );
    }

    // Dilim çizgileri
    final linePaint = Paint()
      ..color = Colors.brown
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (int i = 0; i < denominator; i++) {
      final angle = -math.pi / 2 + i * sliceAngle;
      final endPoint = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
      canvas.drawLine(center, endPoint, linePaint);
    }

    // Dış çember
    canvas.drawCircle(center, radius, linePaint);
  }

  @override
  bool shouldRepaint(covariant PizzaPainter oldDelegate) {
    return oldDelegate.numerator != numerator || 
           oldDelegate.denominator != denominator;
  }
}

