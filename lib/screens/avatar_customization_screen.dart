import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../models/avatar_customization.dart';
import '../localization/app_localizations.dart';

/// Avatar Özelleştirme Ekranı
class AvatarCustomizationScreen extends StatefulWidget {
  final VoidCallback onBack;
  final UserAvatar? initialAvatar;
  final int userCoins;
  final Function(UserAvatar)? onSave;

  const AvatarCustomizationScreen({
    super.key,
    required this.onBack,
    this.initialAvatar,
    this.userCoins = 0,
    this.onSave,
  });

  @override
  State<AvatarCustomizationScreen> createState() => _AvatarCustomizationScreenState();
}

class _AvatarCustomizationScreenState extends State<AvatarCustomizationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late UserAvatar _avatar;
  int _coins = 0;

  final List<String> _tabs = ['Yüz', 'Saç', 'Gözler', 'Kıyafet', 'Aksesuar', 'Arka Plan'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _avatar = widget.initialAvatar ?? UserAvatar(oderId: 'user');
    _coins = widget.userCoins;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _selectPart(AvatarPart part) {
    final isUnlocked = _avatar.unlockedParts.contains(part.id) || 
                       part.isUnlocked ||
                       part.cost == 0;

    if (!isUnlocked) {
      _showPurchaseDialog(part);
      return;
    }

    setState(() {
      switch (part.type) {
        case AvatarPartType.skin:
          _avatar.selectedSkin = part.id;
          break;
        case AvatarPartType.hair:
          _avatar.selectedHair = part.id;
          break;
        case AvatarPartType.eyes:
          _avatar.selectedEyes = part.id;
          break;
        case AvatarPartType.outfit:
          _avatar.selectedOutfit = part.id;
          break;
        case AvatarPartType.accessory:
          _avatar.selectedAccessory = part.id;
          break;
        case AvatarPartType.background:
          _avatar.selectedBackground = part.id;
          break;
      }
    });
  }

  void _showPurchaseDialog(AvatarPart part) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2C3E50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Text(part.emoji, style: const TextStyle(fontSize: 32)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                part.name,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Bu parçayı satın almak ister misin?',
              style: TextStyle(color: Colors.white.withOpacity(0.8)),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('🪙', style: TextStyle(fontSize: 24)),
                const SizedBox(width: 8),
                Text(
                  '${part.cost}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber,
                  ),
                ),
              ],
            ),
            if (_coins < part.cost) ...[
              const SizedBox(height: 8),
              Text(
                'Yeterli altın yok!',
                style: TextStyle(color: Colors.red.shade300),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İPTAL', style: TextStyle(color: Colors.white70)),
          ),
          if (_coins >= part.cost)
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _coins -= part.cost;
                  _avatar.unlockedParts.add(part.id);
                });
                Navigator.pop(context);
                _selectPart(part);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.black,
              ),
              child: const Text('SATIN AL'),
            ),
        ],
      ),
    );
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
              Color(0xFF667eea),
              Color(0xFF764ba2),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Üst bar
              _buildTopBar(),

              // Avatar önizleme
              _buildAvatarPreview(),

              // Tab bar
              _buildTabBar(),

              // Parça listesi
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildPartsList(AvatarPartType.skin),
                    _buildPartsList(AvatarPartType.hair),
                    _buildPartsList(AvatarPartType.eyes),
                    _buildPartsList(AvatarPartType.outfit),
                    _buildPartsList(AvatarPartType.accessory),
                    _buildPartsList(AvatarPartType.background),
                  ],
                ),
              ),

              // Kaydet butonu
              _buildSaveButton(),
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
          const SizedBox(width: 16),
          const Text(
            '👤 Avatar Özelleştir',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.3),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Text('🪙', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 4),
                Text(
                  '$_coins',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarPreview() {
    final allParts = AvatarPart.allParts;
    final skin = allParts.firstWhere((p) => p.id == _avatar.selectedSkin);
    final outfit = allParts.firstWhere((p) => p.id == _avatar.selectedOutfit);
    final accessory = allParts.firstWhere((p) => p.id == _avatar.selectedAccessory);

    return Container(
      height: 180,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Arka plan efekti
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: CustomPaint(
                painter: _BackgroundPatternPainter(),
              ),
            ),
          ),
          // Avatar
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  Text(skin.emoji, style: const TextStyle(fontSize: 60)),
                  if (accessory.id != 'acc_none')
                    Positioned(
                      top: -5,
                      child: Text(accessory.emoji, style: const TextStyle(fontSize: 30)),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                outfit.emoji,
                style: const TextStyle(fontSize: 40),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        indicator: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white60,
        tabs: _tabs.map((tab) => Tab(text: tab)).toList(),
      ),
    );
  }

  Widget _buildPartsList(AvatarPartType type) {
    final parts = AvatarPart.allParts.where((p) => p.type == type).toList();

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.9,
      ),
      itemCount: parts.length,
      itemBuilder: (context, index) {
        final part = parts[index];
        final isSelected = _getSelectedId(type) == part.id;
        final isUnlocked = _avatar.unlockedParts.contains(part.id) || 
                           part.isUnlocked ||
                           part.cost == 0;

        return GestureDetector(
          onTap: () => _selectPart(part),
          child: Container(
            decoration: BoxDecoration(
              color: isSelected
                  ? Colors.amber.withOpacity(0.4)
                  : Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? Colors.amber : Colors.white.withOpacity(0.2),
                width: isSelected ? 3 : 1,
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      part.emoji,
                      style: TextStyle(
                        fontSize: 36,
                        color: isUnlocked ? null : Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      part.name,
                      style: TextStyle(
                        fontSize: 10,
                        color: isUnlocked ? Colors.white : Colors.white60,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (!isUnlocked && part.cost > 0)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('🪙', style: TextStyle(fontSize: 10)),
                          Text(
                            '${part.cost}',
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.amber,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                if (!isUnlocked)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.lock,
                        color: Colors.white,
                        size: 12,
                      ),
                    ),
                  ),
                if (part.isPremium)
                  Positioned(
                    top: 4,
                    left: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.purple,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'VIP',
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
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

  String _getSelectedId(AvatarPartType type) {
    switch (type) {
      case AvatarPartType.skin:
        return _avatar.selectedSkin;
      case AvatarPartType.hair:
        return _avatar.selectedHair;
      case AvatarPartType.eyes:
        return _avatar.selectedEyes;
      case AvatarPartType.outfit:
        return _avatar.selectedOutfit;
      case AvatarPartType.accessory:
        return _avatar.selectedAccessory;
      case AvatarPartType.background:
        return _avatar.selectedBackground;
    }
  }

  Widget _buildSaveButton() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GestureDetector(
        onTap: () {
          widget.onSave?.call(_avatar);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Avatar kaydedildi! ✨'),
              backgroundColor: Colors.green,
            ),
          );
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF11998e), Color(0xFF38ef7d)],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.green.withOpacity(0.4),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: const Center(
            child: Text(
              '💾 KAYDET',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BackgroundPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 20; i++) {
      final x = (i * 30.0) % size.width;
      final y = (i * 25.0) % size.height;
      canvas.drawCircle(Offset(x, y), 10, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

