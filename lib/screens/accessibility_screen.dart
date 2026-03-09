import 'package:flutter/material.dart';

/// Erişilebilirlik Ayarları Ekranı
/// Karanlık mod, sesli okuma, büyük yazı
class AccessibilityScreen extends StatefulWidget {
  final VoidCallback onBack;

  const AccessibilityScreen({super.key, required this.onBack});

  @override
  State<AccessibilityScreen> createState() => _AccessibilityScreenState();
}

class _AccessibilityScreenState extends State<AccessibilityScreen> {
  // Görsel ayarlar
  bool _darkMode = false;
  bool _highContrast = false;
  bool _colorBlindMode = false;
  double _textSize = 1.0; // 0.8 - 1.5 arası
  
  // Ses ayarları
  bool _voiceEnabled = true;
  bool _readQuestions = true;
  bool _readOptions = false;
  bool _soundEffects = true;
  bool _backgroundMusic = true;
  double _voiceSpeed = 1.0; // 0.5 - 2.0 arası
  
  // Hareket azaltma
  bool _reduceMotion = false;
  bool _reduceParticles = false;
  
  // Dokunma ayarları
  double _touchSize = 1.0; // 0.8 - 1.5 arası
  int _touchDelay = 0; // ms cinsinden

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: _darkMode
              ? const LinearGradient(
                  colors: [Color(0xFF1a1a2e), Color(0xFF16213e)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                )
              : const LinearGradient(
                  colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Üst bar
              _buildTopBar(),

              // Ayarlar listesi
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildSectionTitle('👁️ Görsel Ayarlar'),
                    _buildVisualSettings(),

                    const SizedBox(height: 24),

                    _buildSectionTitle('🔊 Ses Ayarları'),
                    _buildSoundSettings(),

                    const SizedBox(height: 24),

                    _buildSectionTitle('✨ Hareket Ayarları'),
                    _buildMotionSettings(),

                    const SizedBox(height: 24),

                    _buildSectionTitle('👆 Dokunma Ayarları'),
                    _buildTouchSettings(),

                    const SizedBox(height: 24),

                    _buildResetButton(),
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
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '♿ Erişilebilirlik',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                'Deneyimini özelleştir',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18 * _textSize,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildVisualSettings() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // Karanlık Mod
          _buildSwitchTile(
            icon: Icons.dark_mode,
            title: 'Karanlık Mod',
            subtitle: 'Göz yorgunluğunu azaltır',
            value: _darkMode,
            onChanged: (value) {
              setState(() {
                _darkMode = value;
              });
            },
          ),

          const Divider(color: Colors.white24),

          // Yüksek Kontrast
          _buildSwitchTile(
            icon: Icons.contrast,
            title: 'Yüksek Kontrast',
            subtitle: 'Renk kontrastını artırır',
            value: _highContrast,
            onChanged: (value) {
              setState(() {
                _highContrast = value;
              });
            },
          ),

          const Divider(color: Colors.white24),

          // Renk Körlüğü Modu
          _buildSwitchTile(
            icon: Icons.visibility,
            title: 'Renk Körlüğü Modu',
            subtitle: 'Renk paletini uyarlar',
            value: _colorBlindMode,
            onChanged: (value) {
              setState(() {
                _colorBlindMode = value;
              });
            },
          ),

          const Divider(color: Colors.white24),

          // Yazı Boyutu
          _buildSliderTile(
            icon: Icons.text_fields,
            title: 'Yazı Boyutu',
            value: _textSize,
            min: 0.8,
            max: 1.5,
            divisions: 7,
            label: '${(_textSize * 100).toInt()}%',
            onChanged: (value) {
              setState(() {
                _textSize = value;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSoundSettings() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // Sesli Okuma
          _buildSwitchTile(
            icon: Icons.record_voice_over,
            title: 'Sesli Okuma',
            subtitle: 'Metinleri sesli okur',
            value: _voiceEnabled,
            onChanged: (value) {
              setState(() {
                _voiceEnabled = value;
              });
            },
          ),

          if (_voiceEnabled) ...[
            const Divider(color: Colors.white24),

            // Soruları Oku
            _buildSwitchTile(
              icon: Icons.quiz,
              title: 'Soruları Oku',
              subtitle: 'Matematik sorularını sesli okur',
              value: _readQuestions,
              onChanged: (value) {
                setState(() {
                  _readQuestions = value;
                });
              },
            ),

            const Divider(color: Colors.white24),

            // Seçenekleri Oku
            _buildSwitchTile(
              icon: Icons.list,
              title: 'Seçenekleri Oku',
              subtitle: 'Cevap seçeneklerini sesli okur',
              value: _readOptions,
              onChanged: (value) {
                setState(() {
                  _readOptions = value;
                });
              },
            ),

            const Divider(color: Colors.white24),

            // Ses Hızı
            _buildSliderTile(
              icon: Icons.speed,
              title: 'Ses Hızı',
              value: _voiceSpeed,
              min: 0.5,
              max: 2.0,
              divisions: 6,
              label: '${_voiceSpeed.toStringAsFixed(1)}x',
              onChanged: (value) {
                setState(() {
                  _voiceSpeed = value;
                });
              },
            ),
          ],

          const Divider(color: Colors.white24),

          // Ses Efektleri
          _buildSwitchTile(
            icon: Icons.music_note,
            title: 'Ses Efektleri',
            subtitle: 'Oyun içi sesler',
            value: _soundEffects,
            onChanged: (value) {
              setState(() {
                _soundEffects = value;
              });
            },
          ),

          const Divider(color: Colors.white24),

          // Arka Plan Müziği
          _buildSwitchTile(
            icon: Icons.library_music,
            title: 'Arka Plan Müziği',
            subtitle: 'Müzik çalar',
            value: _backgroundMusic,
            onChanged: (value) {
              setState(() {
                _backgroundMusic = value;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMotionSettings() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // Hareketi Azalt
          _buildSwitchTile(
            icon: Icons.animation,
            title: 'Hareketi Azalt',
            subtitle: 'Animasyonları basitleştirir',
            value: _reduceMotion,
            onChanged: (value) {
              setState(() {
                _reduceMotion = value;
              });
            },
          ),

          const Divider(color: Colors.white24),

          // Partikülleri Azalt
          _buildSwitchTile(
            icon: Icons.auto_awesome,
            title: 'Partikülleri Azalt',
            subtitle: 'Arka plan efektlerini azaltır',
            value: _reduceParticles,
            onChanged: (value) {
              setState(() {
                _reduceParticles = value;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTouchSettings() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // Dokunma Alanı Boyutu
          _buildSliderTile(
            icon: Icons.touch_app,
            title: 'Dokunma Alanı',
            value: _touchSize,
            min: 0.8,
            max: 1.5,
            divisions: 7,
            label: '${(_touchSize * 100).toInt()}%',
            onChanged: (value) {
              setState(() {
                _touchSize = value;
              });
            },
          ),

          const Divider(color: Colors.white24),

          // Dokunma Gecikmesi
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.timer, color: Colors.white.withOpacity(0.7), size: 20),
                  const SizedBox(width: 12),
                  Text(
                    'Dokunma Gecikmesi',
                    style: TextStyle(
                      fontSize: 14 * _textSize,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Kazara dokunmayı önler',
                style: TextStyle(
                  fontSize: 12 * _textSize,
                  color: Colors.white60,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildDelayOption(0, 'Yok'),
                  const SizedBox(width: 8),
                  _buildDelayOption(200, '0.2s'),
                  const SizedBox(width: 8),
                  _buildDelayOption(500, '0.5s'),
                  const SizedBox(width: 8),
                  _buildDelayOption(1000, '1s'),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDelayOption(int delay, String label) {
    final isSelected = _touchDelay == delay;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _touchDelay = delay;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? Colors.amber.withOpacity(0.3)
                : Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? Colors.amber : Colors.white24,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? Colors.amber : Colors.white70,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.white.withOpacity(0.7), size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14 * _textSize,
                    color: Colors.white,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12 * _textSize,
                    color: Colors.white60,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.amber,
          ),
        ],
      ),
    );
  }

  Widget _buildSliderTile({
    required IconData icon,
    required String title,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required String label,
    required ValueChanged<double> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.white.withOpacity(0.7), size: 24),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14 * _textSize,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.amber,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            activeColor: Colors.amber,
            inactiveColor: Colors.white24,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildResetButton() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _darkMode = false;
          _highContrast = false;
          _colorBlindMode = false;
          _textSize = 1.0;
          _voiceEnabled = true;
          _readQuestions = true;
          _readOptions = false;
          _soundEffects = true;
          _backgroundMusic = true;
          _voiceSpeed = 1.0;
          _reduceMotion = false;
          _reduceParticles = false;
          _touchSize = 1.0;
          _touchDelay = 0;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ayarlar sıfırlandı'),
            backgroundColor: Colors.green,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.withOpacity(0.3)),
        ),
        child: const Center(
          child: Text(
            '🔄 Varsayılana Sıfırla',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

