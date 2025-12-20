import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../localization/app_localizations.dart';

/// Ebeveyn Paneli Ekranı
/// Çocuğun ilerlemesini takip etme, süre sınırları, raporlar
class ParentPanelScreen extends StatefulWidget {
  final VoidCallback onBack;

  const ParentPanelScreen({super.key, required this.onBack});

  @override
  State<ParentPanelScreen> createState() => _ParentPanelScreenState();
}

class _ParentPanelScreenState extends State<ParentPanelScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Ayarlar
  bool _dailyLimitEnabled = true;
  int _dailyLimitMinutes = 30;
  bool _soundEnabled = true;
  bool _notificationsEnabled = true;
  bool _safeMode = true;
  
  // İstatistikler (örnek veriler)
  final Map<String, dynamic> _stats = {
    'totalPlayTime': 245, // dakika
    'totalQuestions': 432,
    'correctAnswers': 389,
    'wrongAnswers': 43,
    'streakDays': 7,
    'level': 12,
    'coins': 1250,
    'badges': 15,
    'weeklyProgress': [65, 80, 45, 90, 70, 85, 55], // Son 7 günün doğru oranları
  };

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
              Color(0xFF2C3E50),
              Color(0xFF3498DB),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Üst bar
              _buildTopBar(),

              // Tab bar
              _buildTabBar(),

              // Tab içerikleri
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildStatsTab(),
                    _buildReportsTab(),
                    _buildSettingsTab(),
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
                '👨‍👩‍👧 Ebeveyn Paneli',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                'Çocuğunuzun ilerlemesini takip edin',
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

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
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
          Tab(icon: Icon(Icons.bar_chart), text: 'İstatistik'),
          Tab(icon: Icon(Icons.analytics), text: 'Raporlar'),
          Tab(icon: Icon(Icons.settings), text: 'Ayarlar'),
        ],
      ),
    );
  }

  // ============= İSTATİSTİK TAB =============
  Widget _buildStatsTab() {
    final accuracy = _stats['totalQuestions'] > 0
        ? (_stats['correctAnswers'] / _stats['totalQuestions'] * 100).round()
        : 0;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Özet kartları
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                '⏱️',
                'Toplam Süre',
                '${_stats['totalPlayTime']} dk',
                Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                '🎯',
                'Başarı Oranı',
                '%$accuracy',
                Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                '🔥',
                'Giriş Serisi',
                '${_stats['streakDays']} gün',
                Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                '📊',
                'Seviye',
                '${_stats['level']}',
                Colors.purple,
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Soru istatistikleri
        _buildSectionTitle('Soru İstatistikleri'),
        const SizedBox(height: 12),
        _buildQuestionStats(),

        const SizedBox(height: 24),

        // Kazanımlar
        _buildSectionTitle('Kazanımlar'),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildAchievementCard(
                '🪙',
                'Altın',
                '${_stats['coins']}',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildAchievementCard(
                '🏆',
                'Rozet',
                '${_stats['badges']}',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String emoji, String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionStats() {
    final total = _stats['totalQuestions'];
    final correct = _stats['correctAnswers'];
    final wrong = _stats['wrongAnswers'];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildCircularStat('Toplam', total, Colors.blue),
              _buildCircularStat('Doğru', correct, Colors.green),
              _buildCircularStat('Yanlış', wrong, Colors.red),
            ],
          ),
          const SizedBox(height: 16),
          // İlerleme çubuğu
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: total > 0 ? correct / total : 0,
              backgroundColor: Colors.red.withOpacity(0.3),
              valueColor: const AlwaysStoppedAnimation(Colors.green),
              minHeight: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCircularStat(String label, int value, Color color) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withOpacity(0.2),
            border: Border.all(color: color, width: 3),
          ),
          child: Center(
            child: Text(
              '$value',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  Widget _buildAchievementCard(String emoji, String title, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 32)),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white70,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============= RAPORLAR TAB =============
  Widget _buildReportsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionTitle('Haftalık İlerleme'),
        const SizedBox(height: 12),
        _buildWeeklyChart(),

        const SizedBox(height: 24),

        _buildSectionTitle('Konu Bazlı Performans'),
        const SizedBox(height: 12),
        _buildTopicPerformance(),

        const SizedBox(height: 24),

        _buildSectionTitle('Öneriler'),
        const SizedBox(height: 12),
        _buildRecommendations(),
      ],
    );
  }

  Widget _buildWeeklyChart() {
    final days = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
    final values = _stats['weeklyProgress'] as List<int>;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(7, (index) {
              final value = values[index];
              final height = (value / 100) * 100;
              
              return Column(
                children: [
                  Text(
                    '%$value',
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: 30,
                    height: height,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          value >= 70 ? Colors.green : Colors.orange,
                          value >= 70 ? Colors.green.shade300 : Colors.amber,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    days[index],
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.white70,
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildTopicPerformance() {
    final topics = [
      {'name': 'Toplama', 'emoji': '➕', 'score': 92},
      {'name': 'Çıkarma', 'emoji': '➖', 'score': 85},
      {'name': 'Çarpma', 'emoji': '✖️', 'score': 78},
      {'name': 'Bölme', 'emoji': '➗', 'score': 65},
      {'name': 'Geometri', 'emoji': '🔺', 'score': 70},
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: topics.map((topic) {
          final score = topic['score'] as int;
          Color color;
          if (score >= 80) {
            color = Colors.green;
          } else if (score >= 60) {
            color = Colors.orange;
          } else {
            color = Colors.red;
          }

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Text(
                  topic['emoji'] as String,
                  style: const TextStyle(fontSize: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            topic['name'] as String,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            '%$score',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: score / 100,
                          backgroundColor: Colors.white.withOpacity(0.2),
                          valueColor: AlwaysStoppedAnimation(color),
                          minHeight: 6,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRecommendations() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lightbulb, color: Colors.amber, size: 24),
              const SizedBox(width: 8),
              const Text(
                'Öneriler',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildRecommendationItem(
            '📚 Bölme konusuna daha fazla pratik yapılabilir',
          ),
          _buildRecommendationItem(
            '🎯 Günlük hedef 20 soru olarak ayarlanabilir',
          ),
          _buildRecommendationItem(
            '⭐ Harika gidiyorsun! Serini korumaya devam et',
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('•', style: TextStyle(color: Colors.white70)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.white70,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============= AYARLAR TAB =============
  Widget _buildSettingsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionTitle('Süre Kontrolü'),
        const SizedBox(height: 12),
        _buildTimeControlSettings(),

        const SizedBox(height: 24),

        _buildSectionTitle('Uygulama Ayarları'),
        const SizedBox(height: 12),
        _buildAppSettings(),

        const SizedBox(height: 24),

        _buildSectionTitle('Güvenlik'),
        const SizedBox(height: 12),
        _buildSecuritySettings(),
      ],
    );
  }

  Widget _buildTimeControlSettings() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          SwitchListTile(
            title: const Text(
              'Günlük Süre Limiti',
              style: TextStyle(color: Colors.white),
            ),
            subtitle: Text(
              _dailyLimitEnabled
                  ? '$_dailyLimitMinutes dakika'
                  : 'Kapalı',
              style: const TextStyle(color: Colors.white70),
            ),
            value: _dailyLimitEnabled,
            onChanged: (value) {
              setState(() {
                _dailyLimitEnabled = value;
              });
            },
            activeColor: Colors.green,
          ),
          if (_dailyLimitEnabled) ...[
            const Divider(color: Colors.white24),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Süre (dakika)',
                  style: TextStyle(color: Colors.white70),
                ),
                Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        if (_dailyLimitMinutes > 10) {
                          setState(() {
                            _dailyLimitMinutes -= 10;
                          });
                        }
                      },
                      icon: const Icon(Icons.remove_circle,
                          color: Colors.white70),
                    ),
                    Text(
                      '$_dailyLimitMinutes',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        if (_dailyLimitMinutes < 120) {
                          setState(() {
                            _dailyLimitMinutes += 10;
                          });
                        }
                      },
                      icon: const Icon(Icons.add_circle, color: Colors.white70),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAppSettings() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          SwitchListTile(
            title: const Text(
              'Sesler',
              style: TextStyle(color: Colors.white),
            ),
            subtitle: const Text(
              'Oyun içi sesler',
              style: TextStyle(color: Colors.white70),
            ),
            value: _soundEnabled,
            onChanged: (value) {
              setState(() {
                _soundEnabled = value;
              });
            },
            activeColor: Colors.green,
          ),
          const Divider(color: Colors.white24),
          SwitchListTile(
            title: const Text(
              'Bildirimler',
              style: TextStyle(color: Colors.white),
            ),
            subtitle: const Text(
              'Günlük hatırlatmalar',
              style: TextStyle(color: Colors.white70),
            ),
            value: _notificationsEnabled,
            onChanged: (value) {
              setState(() {
                _notificationsEnabled = value;
              });
            },
            activeColor: Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _buildSecuritySettings() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          SwitchListTile(
            title: const Text(
              'Güvenli Mod',
              style: TextStyle(color: Colors.white),
            ),
            subtitle: const Text(
              'Reklamsız, sosyal özellikler kapalı',
              style: TextStyle(color: Colors.white70),
            ),
            value: _safeMode,
            onChanged: (value) {
              setState(() {
                _safeMode = value;
              });
            },
            activeColor: Colors.green,
          ),
          const Divider(color: Colors.white24),
          ListTile(
            leading: const Icon(Icons.lock, color: Colors.white70),
            title: const Text(
              'PIN Değiştir',
              style: TextStyle(color: Colors.white),
            ),
            subtitle: const Text(
              'Ebeveyn paneli erişim PIN\'i',
              style: TextStyle(color: Colors.white70),
            ),
            trailing: const Icon(Icons.chevron_right, color: Colors.white70),
            onTap: () => _showPinDialog(),
          ),
        ],
      ),
    );
  }

  void _showPinDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2C3E50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('PIN Değiştir', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 4,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Mevcut PIN',
                labelStyle: const TextStyle(color: Colors.white70),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.blue),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 4,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Yeni PIN',
                labelStyle: const TextStyle(color: Colors.white70),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.blue),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İPTAL', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('PIN değiştirildi'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('KAYDET', style: TextStyle(color: Colors.blue)),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
  }
}

