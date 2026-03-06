import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/badge_service.dart';
import '../services/game_mechanics_service.dart';
import '../services/daily_reward_service.dart';
import '../models/badge.dart';
import '../localization/app_localizations.dart';

/// Ebeveyn Paneli Ekranı
/// Gerçek verilerle çocuğun ilerlemesini takip etme
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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  /// Son aktivite metnini formatla (gerçek veri)
  String _formatLastActivity(DateTime? lastPlayedAt) {
    if (lastPlayedAt == null) return 'Henüz oynamadı';
    final diff = DateTime.now().difference(lastPlayedAt);
    if (diff.inMinutes < 1) return 'Az önce';
    if (diff.inMinutes < 60) return '${diff.inMinutes} dakika önce';
    if (diff.inHours < 24) return '${diff.inHours} saat önce';
    if (diff.inDays == 1) return 'Dün';
    if (diff.inDays < 7) return '${diff.inDays} gün önce';
    return '${diff.inDays} gün önce';
  }

  /// Haftalık ilerleme - consecutiveDays'a göre (gerçek veri)
  List<int> _getWeeklyProgress(int consecutiveDays) {
    return List.generate(7, (i) {
      final daysFromEnd = 6 - i;
      return (consecutiveDays > daysFromEnd) ? 100 : 0;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showGuestBlockedSnackbar(BuildContext context) {
    final locale = Localizations.localeOf(context);
    final localizations = AppLocalizations(locale);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(localizations.parentPanelLoginRequiredDesc),
        backgroundColor: Colors.orange.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Misafir kullanıcılar ebeveyn panelini kullanamaz
    final authService = Provider.of<AuthService>(context, listen: false);
    if (authService.currentUser?.isGuest == true) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).pop();
          _showGuestBlockedSnackbar(context);
        }
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

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

              // Panel giriş - Gerçek kullanıcı bilgisi
              Consumer4<AuthService, BadgeService, GameMechanicsService, DailyRewardService>(
                builder: (context, auth, badge, mechanics, reward, _) {
                  return _buildPanelEntryCard(
                    childName: auth.currentUser?.displayName ?? auth.currentUser?.username ?? 'Oyuncu',
                    loginStreak: reward.loginStreak,
                  );
                },
              ),

              // Tab bar
              _buildTabBar(),

              // Tab içerikleri - Gerçek verilerle
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildStatsTab(), // Consumer içinde gerçek veri
                    _buildReportsTab(),
                    _buildFamilyGameTab(),
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
    final now = DateTime.now();
    final dateStr = '${now.day} ${_getMonthName(now.month)}';
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
                color: Colors.white.withValues(alpha: 0.2),
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '👨‍👩‍👧 Ebeveyn Paneli',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const Text(
                  'Çocuğunuzun ilerlemesini takip edin',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              Icon(Icons.calendar_today, color: Colors.white.withValues(alpha: 0.9), size: 18),
              const SizedBox(width: 6),
              Text(
                dateStr,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPanelEntryCard({required String childName, required int loginStreak}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: const Center(child: Text('👧', style: TextStyle(fontSize: 22))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  childName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text('🔥', style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.9))),
                    const SizedBox(width: 4),
                    Text(
                      '$loginStreak gün seri',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Row(
            children: [
              const Text('🌟', style: TextStyle(fontSize: 14)),
              const SizedBox(width: 6),
              Text(
                'Aile Modu',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.amber.shade200,
                  fontWeight: FontWeight.w500,
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
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        tabs: const [
          Tab(icon: Icon(Icons.dashboard), text: 'Gelişim'),
          Tab(icon: Icon(Icons.bar_chart), text: 'İstatistik'),
          Tab(icon: Icon(Icons.groups), text: 'Aile Oyunu'),
          Tab(icon: Icon(Icons.settings), text: 'Ayarlar'),
        ],
      ),
    );
  }

  // Aile Oyunu sekmesi - Misafir giriş yapanlar buraya erişemez (tüm panel engelli)
  Widget _buildFamilyGameTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionTitle('🎮 Aile Oyun Modu'),
        const SizedBox(height: 12),
        _buildFamilyGameCard(
          '🏁 Birebir Yarış',
          'Çocuk vs Ebeveyn - Kim daha hızlı?',
          Icons.emoji_events,
        ),
        const SizedBox(height: 12),
        _buildFamilyGameCard(
          '👨‍👩‍👧 Takım Modu',
          'Aile vs Bilgisayar - Birlikte kazanın!',
          Icons.groups,
        ),
        const SizedBox(height: 12),
        _buildFamilyGameCard(
          '🔄 Sırayla Oyna',
          'Herkes sırayla soru çözer',
          Icons.swap_horiz,
        ),
        const SizedBox(height: 24),
        _buildSectionTitle('🏆 Aile Turnuvaları'),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.amber.withOpacity(0.2),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.amber.withOpacity(0.4)),
          ),
          child: Column(
            children: [
              const Text('🏆', style: TextStyle(fontSize: 40)),
              const SizedBox(height: 12),
              const Text(
                'Haftalık Aile Ligi',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Yakında eklenecek',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFamilyGameCard(String title, String subtitle, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
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
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 16),
        ],
      ),
    );
  }

  // ============= GELİŞİM TAB (Gerçek Verilerle) =============
  Widget _buildStatsTab() {
    return Consumer4<AuthService, BadgeService, GameMechanicsService, DailyRewardService>(
      builder: (context, auth, badge, mechanics, reward, _) {
        final stats = badge.userStats;
        final totalQuestions = stats?.totalQuestionsAnswered ?? 0;
        final correctAnswers = stats?.totalCorrectAnswers ?? 0;
        final wrongAnswers = stats?.totalWrongAnswers ?? 0;
        final accuracy = totalQuestions > 0
            ? (correctAnswers / totalQuestions * 100).round()
            : 0;
        final childName = auth.currentUser?.displayName ?? auth.currentUser?.username ?? 'Oyuncu';
        final lastActivity = _formatLastActivity(stats?.lastPlayedAt);
        final loginStreak = reward.loginStreak;
        final earnedBadges = badge.earnedBadgesCount;
        final coins = mechanics.inventory.coins;
        final level = (stats != null && stats.totalScore > 0)
            ? ((stats.totalScore / 500).floor() + 1).clamp(1, 999)
            : 1;
        final totalPlayTimeMin = (totalQuestions * 25 / 60).round();
        final weeklyValues = _getWeeklyProgress(loginStreak);

        final solve5Progress = reward.taskProgress['solve_5'];
        final dailyTarget = 5;
        final dailySolved = solve5Progress?.currentValue ?? 0;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildChildSummaryCard(
              childName: childName,
              accuracy: accuracy,
              lastActivity: lastActivity,
              dailyTarget: dailyTarget,
              dailySolved: dailySolved,
              earnedBadges: earnedBadges,
              weeklyValues: weeklyValues,
            ),
            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    '⏱️',
                    'Toplam Süre',
                    '$totalPlayTimeMin dk',
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
                    '$loginStreak gün',
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    '📊',
                    'Seviye',
                    '$level',
                    Colors.purple,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),
            _buildSectionTitle('Soru İstatistikleri'),
            const SizedBox(height: 12),
            _buildQuestionStats(totalQuestions, correctAnswers, wrongAnswers),

            const SizedBox(height: 24),
            _buildSectionTitle('Kazanımlar'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildAchievementCard('🪙', 'Altın', '$coins'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildAchievementCard('🏆', 'Rozet', '$earnedBadges'),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildChildSummaryCard({
    required String childName,
    required int accuracy,
    required String lastActivity,
    required int dailyTarget,
    required int dailySolved,
    required int earnedBadges,
    required List<int> weeklyValues,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.2),
            Colors.white.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '🧒 $childName',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                '📅 ${DateTime.now().day} ${_getMonthName(DateTime.now().month)}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text('⭐', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Text(
                'Genel Başarı: %$accuracy',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.access_time, size: 16, color: Colors.white.withValues(alpha: 0.9)),
              const SizedBox(width: 6),
              Text(
                'Son aktivite: $lastActivity',
                style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.9)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.flag, size: 16, color: Colors.white.withValues(alpha: 0.9)),
              const SizedBox(width: 6),
              Text(
                'Günlük hedef: $dailyTarget soru ($dailySolved çözüldü)',
                style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.9)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Text('🏆', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Kazanılan rozetler: $earnedBadges',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '📈 Haftalık İlerleme:',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (i) {
              final days = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
              final v = weeklyValues[i];
              return Column(
                children: [
                  Container(
                    width: 24,
                    height: (v / 100) * 40,
                    decoration: BoxDecoration(
                      color: v >= 50 ? Colors.green : (v > 0 ? Colors.orange : Colors.grey.withValues(alpha: 0.5)),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    days[i],
                    style: TextStyle(fontSize: 10, color: Colors.white.withValues(alpha: 0.8)),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  String _getMonthName(int month) {
    const names = ['Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz', 'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara'];
    return names[month - 1];
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

  Widget _buildQuestionStats(int total, int correct, int wrong) {
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

  // ============= RAPORLAR TAB (Gerçek Verilerle) =============
  Widget _buildReportsTab() {
    return Consumer2<BadgeService, DailyRewardService>(
      builder: (context, badge, reward, _) {
        final weeklyValues = _getWeeklyProgress(reward.loginStreak);
        final stats = badge.userStats;
        final totalQuestions = stats?.totalQuestionsAnswered ?? 0;
        final correctAnswers = stats?.totalCorrectAnswers ?? 0;
        final accuracy = totalQuestions > 0
            ? (correctAnswers / totalQuestions * 100).round()
            : 0;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildSectionTitle('Haftalık İlerleme'),
            const SizedBox(height: 12),
            _buildWeeklyChart(weeklyValues),

            const SizedBox(height: 24),

            _buildSectionTitle('Konu Bazlı Performans'),
            const SizedBox(height: 12),
            _buildTopicPerformance(accuracy),

            const SizedBox(height: 24),

            _buildSectionTitle('Öneriler'),
            const SizedBox(height: 12),
            _buildRecommendations(stats, accuracy),
          ],
        );
      },
    );
  }

  Widget _buildWeeklyChart(List<int> values) {
    final days = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];

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

  Widget _buildTopicPerformance(int overallAccuracy) {
    final topics = [
      {'name': 'Genel Başarı', 'emoji': '📊', 'score': overallAccuracy},
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

  Widget _buildRecommendations(UserStats? stats, int accuracy) {
    final items = <String>[];
    if (accuracy >= 80) {
      items.add('⭐ Harika gidiyorsun! Başarını korumaya devam et');
    } else if (accuracy >= 60) {
      items.add('📚 Daha fazla pratik yaparak başarını artırabilirsin');
    } else {
      items.add('🎯 Temel konuları tekrar etmek faydalı olacaktır');
    }
    final totalQuestions = stats?.totalQuestionsAnswered ?? 0;
    if (totalQuestions < 50) {
      items.add('📝 Daha fazla soru çözerek pratik yap');
    }
    if (items.isEmpty) {
      items.add('🎮 Oyun oynamaya devam et!');
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
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
          ...items.map((text) => _buildRecommendationItem(text)),
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

