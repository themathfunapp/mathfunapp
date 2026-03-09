// lib/screens/discover_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../localization/app_localizations.dart';
import '../providers/locale_provider.dart';
import '../services/auth_service.dart';
import 'game_start_screen.dart'; // AgeGroupSelection için

class DiscoverScreen extends StatefulWidget {
  final AgeGroupSelection ageGroup;
  final VoidCallback onBack;

  const DiscoverScreen({
    super.key,
    required this.ageGroup,
    required this.onBack,
  });

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  final List<DiscoverItem> _discoverItems = [
    DiscoverItem(
      emoji: '🧩',
      title: 'Zeka Oyunları',
      subtitle: 'Matematik bulmacaları ve zeka soruları',
      description: 'Beyin jimnastiği yap, matematiksel düşünme becerilerini geliştir!',
      color: Color(0xFF00CEC9),
      isNew: true,
      isPremium: false, // TODO: Test için geçici kapatıldı
    ),
    DiscoverItem(
      emoji: '🎨',
      title: 'Renkli Matematik',
      subtitle: 'Eğlenceli matematik etkinlikleri',
      description: 'Renklerle matematik öğren, görsel hafızana hitap eden oyunlar!',
      color: Color(0xFF74B9FF),
      isNew: true,
      isPremium: false, // TODO: Test için geçici kapatıldı
    ),
    DiscoverItem(
      emoji: '🎵',
      title: 'Matematik Şarkıları',
      subtitle: 'Ritimle matematik öğren',
      description: 'Çarpım tablosu şarkıları ve matematik tekerlemeleri!',
      color: Color(0xFFE17055),
      isNew: true,
    ),
    DiscoverItem(
      emoji: '🧠',
      title: 'Hafıza Oyunu',
      subtitle: 'Matematiksel hafıza geliştir',
      description: 'Sayıları, şekilleri eşleştir, hafızanı güçlendir!',
      color: Color(0xFF6C5CE7),
      isNew: false,
    ),
    DiscoverItem(
      emoji: '🔍',
      title: 'Matematik Avı',
      subtitle: 'Gizli nesneleri bul',
      description: 'Rakamları ve şekilleri avla, dikkatini geliştir!',
      color: Color(0xFF00B894),
      isNew: true,
    ),
    DiscoverItem(
      emoji: '📚',
      title: 'Matematik Hikayeleri',
      subtitle: 'Eğitici hikayeler',
      description: 'Matematiği hikayelerle öğren, eğlenceli maceralara katıl!',
      color: Color(0xFF0984E3),
      isNew: false,
    ),
    // TODO: Yayın sonrası güncellemede eklenecek özellikler (6-7 ay sonra)
    // - Zaman Atölyesi (🎭)
    // - Hesap Makinesi (🧮)
    // - İstatistik (📊)
    // - Başarılar (🏆)
    DiscoverItem(
      emoji: '🎯',
      title: 'Hedef Vurma',
      subtitle: 'Doğru cevabı bul ve vur',
      description: 'Matematik problemlerini çöz, hedefleri vur, puan topla!',
      color: Color(0xFFD63031),
      isNew: true,
    ),
    DiscoverItem(
      emoji: '🌈',
      title: 'Renk Kodları',
      subtitle: 'Renklerle matematik çöz',
      description: 'Renk kodlarını çöz, gizli resimleri ortaya çıkar!',
      color: Color(0xFF636E72),
      isNew: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF667eea),
              Color(0xFF764ba2),
              Color(0xFF6B8DD6),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Üst Bar
              Padding(
                padding: const EdgeInsets.all(16.0),
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
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 1.5,
                          ),
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_new,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Yeni Geliştir',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Keşfedilecek ${_discoverItems.length} yeni özellik',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Filtreler
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    _buildFilterChip('Tümü', true),
                    SizedBox(width: 8),
                    _buildFilterChip('Yeni', false),
                    SizedBox(width: 8),
                    _buildFilterChip('Popüler', false),
                    Spacer(),
                    Text(
                      '${_discoverItems.length} özellik',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              // İçerik
              Expanded(
                child: ListView(
                  padding: EdgeInsets.all(16),
                  children: [
                    // Öne çıkan özellik
                    Container(
                      margin: EdgeInsets.only(bottom: 20),
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFFFF6B6B), Color(0xFFEE5A52)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xFFFF6B6B).withOpacity(0.4),
                            blurRadius: 15,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text('🚀', style: TextStyle(fontSize: 32)),
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'ÖNE ÇIKAN',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        'YENİ',
                                        style: TextStyle(
                                          color: Color(0xFFFF6B6B),
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Matematik Şampiyonu',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Haftalık turnuvalara katıl, ödüller kazan!',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Diğer özellikler
                    Text(
                      'Tüm Özellikler',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 12),

                    GridView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.85,
                      ),
                      itemCount: _discoverItems.length,
                      itemBuilder: (context, index) {
                        return _buildDiscoverItemCard(_discoverItems[index]);
                      },
                    ),

                    SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String text, bool isSelected) {
    return GestureDetector(
      onTap: () {
        // Filtreleme işlevi eklenebilir
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? Color(0xFF764ba2) : Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildDiscoverItemCard(DiscoverItem item) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final loc = AppLocalizations(Provider.of<LocaleProvider>(context, listen: false).locale);
    final isLocked = item.isPremium && !authService.isPremium;

    return GestureDetector(
      onTap: () {
        _showFeatureDetails(item);
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [item.color, item.color.withOpacity(0.7)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: item.color.withOpacity(0.4),
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        item.emoji,
                        style: TextStyle(fontSize: 28),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isLocked)
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              margin: EdgeInsets.only(right: 4),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                                ),
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.2),
                                    blurRadius: 4,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('👑', style: TextStyle(fontSize: 8)),
                                  SizedBox(width: 2),
                                  Text(
                                    loc.get('premium_badge'),
                                    style: TextStyle(
                                      fontSize: 8,
                                      color: Color(0xFF8B4513),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          if (item.isNew)
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'YENİ',
                                style: TextStyle(
                                  fontSize: 8,
                                  color: item.color,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Text(
                    item.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  Text(
                    item.subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withOpacity(0.9),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Spacer(),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        isLocked ? '👑 PREMİUM' : 'KEŞFET',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFeatureDetails(DiscoverItem item) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final isLocked = item.isPremium && !authService.isPremium;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [item.color, item.color.withOpacity(0.8)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    item.emoji,
                    style: TextStyle(fontSize: 40),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close, color: Colors.white, size: 28),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (isLocked)
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          margin: EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('👑', style: TextStyle(fontSize: 12)),
                              SizedBox(width: 4),
                              Text(
                                'PREMİUM',
                                style: TextStyle(
                                  color: Color(0xFF8B4513),
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (item.isNew)
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'YENİ ÖZELLİK',
                            style: TextStyle(
                              color: item.color,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Text(
                    item.title,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    item.subtitle,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                  SizedBox(height: 24),
                  Text(
                    item.description,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      height: 1.5,
                    ),
                  ),
                  if (isLocked) ...[
                    SizedBox(height: 16),
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.amber.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Row(
                        children: [
                          Text('✨', style: TextStyle(fontSize: 20)),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Bu özellik sadece Premium üyelere özeldir.',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  SizedBox(height: 32),
                  Container(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        if (isLocked) {
                          _showPremiumUpgradeDialog();
                        } else {
                          _launchFeature(item.title);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isLocked ? Colors.amber : Colors.white,
                        foregroundColor: isLocked ? Color(0xFF8B4513) : item.color,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 8,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (isLocked) ...[
                            Text('👑', style: TextStyle(fontSize: 18)),
                            SizedBox(width: 8),
                          ],
                          Text(
                            isLocked ? "Premium'a Yükselt" : 'Hemen Dene',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPremiumUpgradeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2D1B69),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Text('👑', style: TextStyle(fontSize: 28)),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                "Premium'a Yükselt",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Premium üye olarak tüm özelliklere sınırsız erişim kazanın!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
            SizedBox(height: 16),
            _buildPremiumFeature('🧩', 'Zeka Oyunları'),
            _buildPremiumFeature('🎨', 'Renkli Matematik'),
            _buildPremiumFeature('🚀', 'Özel İçerikler'),
            _buildPremiumFeature('🏆', 'Reklamsız Deneyim'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Daha Sonra',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              final loc = AppLocalizations(Provider.of<LocaleProvider>(context, listen: false).locale);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(loc.get('premium_coming_soon')),
                  backgroundColor: Colors.amber.shade700,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              foregroundColor: Color(0xFF8B4513),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('👑', style: TextStyle(fontSize: 14)),
                SizedBox(width: 8),
                Text("Yükselt", style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumFeature(String emoji, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(emoji, style: TextStyle(fontSize: 16)),
          SizedBox(width: 12),
          Text(
            text,
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  void _launchFeature(String featureName) {
    // Özellik başlatma işlevi
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$featureName özelliği yakında eklenecek!'),
        backgroundColor: Colors.purple,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: Duration(seconds: 2),
      ),
    );
  }
}

class DiscoverItem {
  final String emoji;
  final String title;
  final String subtitle;
  final String description;
  final Color color;
  final bool isNew;
  final bool isPremium;

  DiscoverItem({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.color,
    required this.isNew,
    this.isPremium = false,
  });
}