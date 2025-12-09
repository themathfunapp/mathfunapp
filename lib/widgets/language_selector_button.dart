import 'package:flutter/material.dart';

class LanguageSelectorButton extends StatefulWidget {
  final String currentLanguage;
  final Function(String) onLanguageChanged;

  const LanguageSelectorButton({
    super.key,
    required this.currentLanguage,
    required this.onLanguageChanged,
  });

  @override
  State<LanguageSelectorButton> createState() => _LanguageSelectorButtonState();
}

class _LanguageSelectorButtonState extends State<LanguageSelectorButton> {
  bool _showMenu = false;

  String _getFlagEmoji(String languageCode) {
    switch (languageCode) {
      case 'tr':
        return '🇹🇷';
      case 'en':
        return '🇺🇸';
      case 'de':
        return '🇩🇪';
      default:
        return '🌐';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Bayrak butonu
        GestureDetector(
          onTap: () {
            setState(() {
              _showMenu = !_showMenu;
            });
          },
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                _getFlagEmoji(widget.currentLanguage),
                style: const TextStyle(fontSize: 20),
              ),
            ),
          ),
        ),

        // Dil seçim menüsü
        if (_showMenu)
          Positioned(
            top: 50,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildMenuItem('🇹🇷 Türkçe', 'tr'),
                  _buildMenuItem('🇺🇸 English', 'en'),
                  _buildMenuItem('🇩🇪 Deutsch', 'de'),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMenuItem(String text, String languageCode) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          widget.onLanguageChanged(languageCode);
          setState(() {
            _showMenu = false;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          width: 150,
          child: Text(
            text,
            style: const TextStyle(fontSize: 14),
          ),
        ),
      ),
    );
  }
}