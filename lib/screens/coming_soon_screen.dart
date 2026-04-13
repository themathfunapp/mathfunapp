// lib/screens/coming_soon_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../localization/app_localizations.dart';
import '../providers/locale_provider.dart';

class ComingSoonScreen extends StatelessWidget {
  final VoidCallback onBack;

  const ComingSoonScreen({
    super.key,
    required this.onBack,
  });

  static const List<_ComingSoonItem> _items = [
    _ComingSoonItem(
      emoji: '🚀',
      titleKey: 'math_champion',
      subtitleKey: 'math_champion_subtitle',
      color: Color(0xFFFF6B6B),
    ),
    _ComingSoonItem(
      emoji: '🔍',
      titleKey: 'math_hunt',
      subtitleKey: 'math_hunt_subtitle',
      color: Color(0xFF00B894),
    ),
    _ComingSoonItem(
      emoji: '📚',
      titleKey: 'math_stories',
      subtitleKey: 'math_stories_subtitle',
      color: Color(0xFF0984E3),
    ),
    _ComingSoonItem(
      emoji: '🎯',
      titleKey: 'target_shooting',
      subtitleKey: 'target_shooting_subtitle',
      color: Color(0xFFD63031),
    ),
    _ComingSoonItem(
      emoji: '🌈',
      titleKey: 'color_codes',
      subtitleKey: 'color_codes_subtitle',
      color: Color(0xFF636E72),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations(Provider.of<LocaleProvider>(context, listen: false).locale);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
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
                      onTap: onBack,
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
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            loc.get('coming_soon_section'),
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            loc.get('coming_soon_features_count').replaceAll('%1', '${_items.length}'),
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

              // İçerik
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  children: [
                    // Bilgi kartı
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: Text('⏳', style: TextStyle(fontSize: 16)),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              loc.get('coming_soon_info'),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                height: 1.35,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Yakında gelecek özellikler
                    Text(
                      loc.get('coming_soon_features'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),

                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        crossAxisSpacing: 4,
                        mainAxisSpacing: 4,
                        // Sabit yükseklik: 1.35 en-boy oranı metin + rozet için çok kısaydı (bottom overflow).
                        mainAxisExtent: 108,
                      ),
                      itemCount: _items.length,
                      itemBuilder: (context, index) {
                        return _buildComingSoonCard(context, _items[index], loc);
                      },
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildComingSoonCard(BuildContext context, _ComingSoonItem item, AppLocalizations loc) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [item.color, item.color.withOpacity(0.8)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: item.color.withOpacity(0.35),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(item.emoji, style: const TextStyle(fontSize: 18)),
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.amber,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        loc.get('coming_soon_short'),
                        style: const TextStyle(
                          fontSize: 7,
                          color: Color(0xFF5D4037),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Expanded(
              child: Align(
                alignment: Alignment.topLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      loc.get(item.titleKey),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      loc.get(item.subtitleKey),
                      style: TextStyle(
                        fontSize: 8,
                        color: Colors.white.withOpacity(0.95),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ComingSoonItem {
  final String emoji;
  final String titleKey;
  final String subtitleKey;
  final Color color;

  const _ComingSoonItem({
    required this.emoji,
    required this.titleKey,
    required this.subtitleKey,
    required this.color,
  });
}
