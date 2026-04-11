import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:printing/printing.dart';
import '../services/auth_service.dart';
import '../services/pdf_report_service.dart';
import '../services/badge_service.dart';
import '../services/game_mechanics_service.dart';
import '../services/daily_reward_service.dart';
import '../services/family_service.dart';
import '../services/parent_pin_service.dart';
import '../models/badge.dart';
import '../models/family_member.dart';
import '../localization/app_localizations.dart';
import '../providers/locale_provider.dart';
import '../widgets/animated_counter.dart';
import '../widgets/shimmer_loading.dart';
import '../widgets/empty_state_lottie.dart';
import 'parent_panel_child_detail_screen.dart';
import 'family_duel_race_screen.dart';
import 'parent_mode_games_hub.dart';

/// Ebeveyn Paneli Ekranı
/// Gerçek verilerle çocuğun ilerlemesini takip etme
class ParentPanelScreen extends StatefulWidget {
  final VoidCallback onBack;

  const ParentPanelScreen({super.key, required this.onBack});

  @override
  State<ParentPanelScreen> createState() => _ParentPanelScreenState();
}

class _ParentPanelScreenState extends State<ParentPanelScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  static const int _tabCount = 5;

  late TabController _tabController;
  Timer? _sessionCheckTimer;
  
  // Ayarlar
  bool _dailyLimitEnabled = true;
  int _dailyLimitMinutes = 30;
  bool _soundEnabled = true;
  bool _notificationsEnabled = true;
  bool _safeMode = true;

  // Bildirim / Hatırlatıcı ayarları
  static const String _prefDailyReminder = 'parent_notif_daily_reminder';
  static const String _prefDailyReminderHour = 'parent_notif_daily_hour';
  static const String _prefDailyReminderMin = 'parent_notif_daily_min';
  static const String _prefSuccessMessages = 'parent_notif_success_messages';
  static const String _prefWeeklySummary = 'parent_notif_weekly_summary';
  static const String _prefInactivityWarning = 'parent_notif_inactivity_warning';
  static const String _prefReportHistory = 'parent_pdf_report_history';

  bool _dailyReminderEnabled = true;
  int _dailyReminderHour = 18;
  int _dailyReminderMinute = 0;

  static const List<Map<String, dynamic>> _supportedLanguages = [
    {'code': 'tr', 'name': 'Türkçe', 'flag': '🇹🇷'},
    {'code': 'en', 'name': 'English', 'flag': '🇺🇸'},
    {'code': 'de', 'name': 'Deutsch', 'flag': '🇩🇪'},
    {'code': 'ar', 'name': 'العربية (Arapça)', 'flag': '🇸🇦'},
    {'code': 'fa', 'name': 'فارسی (Farsça)', 'flag': '🇮🇷'},
    {'code': 'zh', 'name': '中文 (Çince)', 'flag': '🇨🇳'},
    {'code': 'id', 'name': 'Bahasa (Endonezce)', 'flag': '🇮🇩'},
    {'code': 'ku', 'name': 'Kurdî (Kürtçe)', 'flag': '☀️'},
    {'code': 'es', 'name': 'Español (İspanyolca)', 'flag': '🇪🇸'},
    {'code': 'fr', 'name': 'Français (Fransızca)', 'flag': '🇫🇷'},
    {'code': 'ru', 'name': 'Русский (Rusça)', 'flag': '🇷🇺'},
    {'code': 'ja', 'name': '日本語 (Japonca)', 'flag': '🇯🇵'},
    {'code': 'ko', 'name': '한국어 (Korece)', 'flag': '🇰🇷'},
    {'code': 'hi', 'name': 'हिन्दी (Hintçe)', 'flag': '🇮🇳'},
    {'code': 'ur', 'name': 'اردو (Urduca)', 'flag': '🇵🇰'},
    {'code': 'pt', 'name': 'Português (Portekizce)', 'flag': '🇧🇷'},
    {'code': 'it', 'name': 'Italiano (İtalyanca)', 'flag': '🇮🇹'},
    {'code': 'pl', 'name': 'Polski (Lehçe)', 'flag': '🇵🇱'},
  ];
  bool _successMessagesEnabled = true;
  bool _weeklySummaryEnabled = true;
  bool _inactivityWarningEnabled = true;
  List<DateTime> _reportHistory = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _tabController = TabController(length: _tabCount, vsync: this);
    _loadNotificationPrefs();
    _loadReportHistory();
    _startSessionCheck();
  }

  @override
  void dispose() {
    _sessionCheckTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _tabController.dispose();
    super.dispose();
  }

  /// Hot reload sonrası TabController eski uzunlukta kalmasın (4 vs 5 sekme uyumsuzluğu).
  @override
  void reassemble() {
    super.reassemble();
    if (_tabController.length != _tabCount) {
      final oldIndex = _tabController.index.clamp(0, _tabCount - 1);
      _tabController.dispose();
      _tabController = TabController(
        length: _tabCount,
        vsync: this,
        initialIndex: oldIndex,
      );
    }
  }

  void _startSessionCheck() {
    _sessionCheckTimer?.cancel();
    _sessionCheckTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!mounted) return;
      final pinService = Provider.of<ParentPinService>(context, listen: false);
      if (pinService.isSessionExpired) {
        pinService.endSession();
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Güvenlik nedeniyle oturum sonlandırıldı (5 dk işlem yok)'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      Provider.of<ParentPinService>(context, listen: false).recordActivity();
    }
  }

  Future<void> _loadReportHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_prefReportHistory);
    if (json != null) {
      try {
        final list = jsonDecode(json) as List<dynamic>;
        setState(() {
          _reportHistory = list
              .map((e) => DateTime.tryParse(e.toString()))
              .whereType<DateTime>()
              .toList();
        });
      } catch (_) {}
    }
  }

  Future<void> _saveReportHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final list = _reportHistory.take(4).map((d) => d.toIso8601String()).toList();
    await prefs.setString(_prefReportHistory, jsonEncode(list));
  }

  Future<void> _loadNotificationPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _dailyReminderEnabled = prefs.getBool(_prefDailyReminder) ?? true;
      _dailyReminderHour = prefs.getInt(_prefDailyReminderHour) ?? 18;
      _dailyReminderMinute = prefs.getInt(_prefDailyReminderMin) ?? 0;
      _successMessagesEnabled = prefs.getBool(_prefSuccessMessages) ?? true;
      _weeklySummaryEnabled = prefs.getBool(_prefWeeklySummary) ?? true;
      _inactivityWarningEnabled = prefs.getBool(_prefInactivityWarning) ?? true;
    });
  }

  Future<void> _saveNotificationPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefDailyReminder, _dailyReminderEnabled);
    await prefs.setInt(_prefDailyReminderHour, _dailyReminderHour);
    await prefs.setInt(_prefDailyReminderMin, _dailyReminderMinute);
    await prefs.setBool(_prefSuccessMessages, _successMessagesEnabled);
    await prefs.setBool(_prefWeeklySummary, _weeklySummaryEnabled);
    await prefs.setBool(_prefInactivityWarning, _inactivityWarningEnabled);
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

    return Listener(
      onPointerDown: (_) {
        Provider.of<ParentPinService>(context, listen: false).recordActivity();
      },
      child: Scaffold(
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

              // Panel giriş - Gerçek kullanıcı verisi
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
                    _buildPlayGamesTab(),
                    _buildFamilyGameTab(),
                    _buildSettingsTab(),
                  ],
                ),
              ),
            ],
          ),
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
                  'Matematik Dünyası: Ebeveyn Paneli',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const Text(
                  'Aile oyunlaştırma paneli',
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
          Tab(icon: Icon(Icons.sports_esports), text: 'Oyun Oyna'),
          Tab(icon: Icon(Icons.groups), text: 'Aile Oyunu'),
          Tab(icon: Icon(Icons.settings), text: 'Ayarlar'),
        ],
      ),
    );
  }

  /// Oyun Oyna — ebeveyn modu oyun merkezi (birlikte yarış, bölge haritası).
  Widget _buildPlayGamesTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ParentModeGamesHub.forParentPanelTab(
          onJumpToGelisimTab: () {
            if (_tabController.index != 0) {
              _tabController.animateTo(0);
            }
          },
        ),
      ],
    );
  }

  // Aile Oyunu sekmesi - Misafir giriş yapanlar buraya erişemez (tüm panel engelli)
  Widget _buildFamilyGameTab() {
    return Consumer<FamilyService>(
      builder: (context, familyService, _) {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildSectionTitle('🏆 Aile Liderlik Tablosu'),
            const SizedBox(height: 12),
            _buildFamilyLeaderboard(familyService),
            const SizedBox(height: 24),
            _buildSectionTitle('🎮 Aile Oyun Modu'),
            const SizedBox(height: 12),
            _buildFamilyGameCard(
              '🏁 Birebir Yarış',
              'Çocuk vs Ebeveyn - Kim daha hızlı?',
              Icons.emoji_events,
              onTap: () => _openFamilyDuelRace(context),
            ),
            const SizedBox(height: 12),
            _buildFamilyGameCard(
              '👨‍👩‍👧 Takım Modu',
              'Aile vs Bilgisayar - Birlikte kazanın!',
              Icons.groups,
              onTap: () => _showFamilyModeSoon(context, 'Takım modu yakında.'),
            ),
            const SizedBox(height: 12),
            _buildFamilyGameCard(
              '🔄 Sırayla Oyna',
              'Herkes sırayla soru çözer',
              Icons.swap_horiz,
              onTap: () => _showFamilyModeSoon(context, 'Sırayla oyna yakında.'),
            ),
          ],
        );
      },
    );
  }

  /// Aile liderlik tablosu - Sıra, İsim, Puan, Başarı %, Son Aktivite
  Widget _buildFamilyLeaderboard(FamilyService familyService) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filtre butonları + Çocuk ekle
          Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildLeaderboardFilterChip(
                      familyService,
                      LeaderboardFilter.weekly,
                      'Haftalık',
                    ),
                    _buildLeaderboardFilterChip(
                      familyService,
                      LeaderboardFilter.monthly,
                      'Aylık',
                    ),
                    _buildLeaderboardFilterChip(
                      familyService,
                      LeaderboardFilter.allTime,
                      'Tüm Zamanlar',
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => _showAddChildDialog(context, familyService),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.green.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.person_add, size: 18, color: Colors.white.withValues(alpha: 0.95)),
                      const SizedBox(width: 6),
                      Text(
                        'Çocuk Ekle',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.95),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (familyService.isLoading)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  ShimmerLoading(
                    child: Column(
                      children: List.generate(
                        4,
                        (_) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: ShimmerCard(height: 56, borderRadius: 12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            )
          else if (familyService.leaderboard.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: EmptyStateLottie(
                message: 'Henüz aile üyesi yok. Oynamaya devam edin!',
                size: 120,
                fallbackIcon: Icons.people_outline_rounded,
              ),
            )
          else
            _buildLeaderboardTable(familyService.leaderboard),
        ],
      ),
    );
  }

  void _showAddChildDialog(BuildContext context, FamilyService familyService) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2C3E50),
        title: const Text(
          'Çocuk Ekle',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Çocuğun oyuncu kodunu girin (örn: MTN1234567890)',
              style: TextStyle(
                fontSize: 13,
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'MTN1234567890',
                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('İptal', style: TextStyle(color: Colors.white.withValues(alpha: 0.8))),
          ),
          ElevatedButton(
            onPressed: () async {
              final code = controller.text.trim();
              if (code.isEmpty) return;
              final ok = await familyService.addChildByUserCode(code, '');
              if (context.mounted) Navigator.pop(context);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(ok ? 'Çocuk eklendi!' : 'Oyuncu bulunamadı veya zaten ekli.'),
                    backgroundColor: ok ? Colors.green : Colors.orange,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text('Ekle'),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardFilterChip(
    FamilyService familyService,
    LeaderboardFilter filter,
    String label,
  ) {
    final isSelected = familyService.currentFilter == filter;
    return GestureDetector(
      onTap: () => familyService.setFilter(filter),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.amber.withValues(alpha: 0.4)
              : Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? Colors.amber
                : Colors.white.withValues(alpha: 0.2),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildLeaderboardTable(List<LeaderboardEntry> entries) {
    return Column(
      children: [
        // Başlık satırı
        Row(
          children: [
            SizedBox(width: 36, child: Text('Sıra', style: _leaderboardHeaderStyle)),
            const SizedBox(width: 8),
            Expanded(flex: 2, child: Text('İsim', style: _leaderboardHeaderStyle)),
            SizedBox(width: 56, child: Text('Puan', style: _leaderboardHeaderStyle)),
            SizedBox(width: 48, child: Text('Başarı', style: _leaderboardHeaderStyle)),
            Expanded(child: Text('Son Aktivite', style: _leaderboardHeaderStyle)),
          ],
        ),
        const SizedBox(height: 12),
        const Divider(color: Colors.white24, height: 1),
        const SizedBox(height: 8),
        ...entries.map((e) => _buildLeaderboardRow(e)),
      ],
    );
  }

  TextStyle get _leaderboardHeaderStyle => TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: Colors.white.withValues(alpha: 0.9),
      );

  Widget _buildLeaderboardRow(LeaderboardEntry entry) {
    Color rankColor = Colors.white;
    if (entry.rank == 1) rankColor = const Color(0xFFFFD700); // Altın
    if (entry.rank == 2) rankColor = const Color(0xFFC0C0C0); // Gümüş
    if (entry.rank == 3) rankColor = const Color(0xFFCD7F32); // Bronz

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            child: Text(
              '${entry.rank}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: rankColor,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Text(
                  entry.isParent ? '👑 ' : '🧒 ',
                  style: const TextStyle(fontSize: 14),
                ),
                Expanded(
                  child: Text(
                    entry.displayName,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 56,
            child: Text(
              '${entry.score}',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
          SizedBox(
            width: 48,
            child: Text(
              '%${entry.accuracy}',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _getSuccessColor(entry.accuracy),
              ),
            ),
          ),
          Expanded(
            child: Text(
              _formatLastActivity(entry.lastPlayedAt),
              style: TextStyle(
                fontSize: 11,
                color: Colors.white.withValues(alpha: 0.8),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  void _openFamilyDuelRace(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (ctx) => FamilyDuelRaceScreen(
          onBack: () => Navigator.of(ctx).pop(),
        ),
      ),
    );
  }

  void _showFamilyModeSoon(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildFamilyGameCard(
    String title,
    String subtitle,
    IconData icon, {
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
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
        ),
      ),
    );
  }

  Widget _buildShimmerStatsTab() {
    return ShimmerLoading(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionTitle('🧒 Gelişim Özeti'),
          const SizedBox(height: 12),
          ShimmerCard(height: 180, borderRadius: 20),
          const SizedBox(height: 12),
          ShimmerCard(height: 180, borderRadius: 20),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: ShimmerCard(height: 100, borderRadius: 16)),
              const SizedBox(width: 12),
              Expanded(child: ShimmerCard(height: 100, borderRadius: 16)),
            ],
          ),
          const SizedBox(height: 20),
          _buildSectionTitle('📊 Detaylı İstatistikler'),
          const SizedBox(height: 12),
          SizedBox(
            height: 140,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: 4,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, __) => ShimmerCard(height: 140, borderRadius: 16),
            ),
          ),
        ],
      ),
    );
  }

  // ============= GELİŞİM TAB (Çoklu Çocuk - FamilyService) =============
  Widget _buildStatsTab() {
    return Consumer4<FamilyService, DailyRewardService, BadgeService, GameMechanicsService>(
      builder: (context, familyService, reward, badge, mechanics, _) {
        final solve5Progress = reward.taskProgress['solve_5'];
        final dailyTarget = 5;
        final dailySolved = solve5Progress?.currentValue ?? 0;

        if (familyService.isLoading) {
          return _buildShimmerStatsTab();
        }

        final entries = familyService.leaderboard;
        if (entries.isEmpty) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildSectionTitle('🧒 Gelişim Özeti'),
              const SizedBox(height: 24),
              Center(
                child: EmptyStateLottie(
                  message: 'Henüz aile verisi yok. Oynamaya başlayın!',
                  size: 140,
                  fallbackIcon: Icons.group_off_rounded,
                ),
              ),
              const SizedBox(height: 20),
              _buildSectionTitle('📊 Detaylı İstatistikler'),
              const SizedBox(height: 12),
              _buildDetailedStats(badge, mechanics),
            ],
          );
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildSectionTitle('🧒 Gelişim Özeti'),
            const SizedBox(height: 12),
            ...entries.map((entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildRealChildCard(
                    childName: entry.displayName,
                    totalScore: entry.score,
                    accuracy: entry.accuracy,
                    lastActivity: _formatLastActivity(entry.lastPlayedAt),
                    dailyTarget: dailyTarget,
                    dailySolved: dailySolved,
                    earnedBadges: entry.earnedBadges,
                    weeklyValues: entry.weeklyValues,
                    isParent: entry.isParent,
                    userId: entry.userId,
                  ),
                )),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    '🏆',
                    'Aile Üyesi',
                    entries.length,
                    Colors.purple,
                    suffix: '',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    '🔥',
                    'Giriş Serisi',
                    reward.loginStreak,
                    Colors.orange,
                    suffix: ' gün',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildSectionTitle('📊 Detaylı İstatistikler'),
            const SizedBox(height: 12),
            _buildDetailedStats(badge, mechanics),
          ],
        );
      },
    );
  }

  /// Yatay kaydırılabilir detaylı istatistik kartları
  Widget _buildDetailedStats(BadgeService badge, GameMechanicsService mechanics) {
    final stats = badge.userStats;
    final totalQuestions = stats?.totalQuestionsAnswered ?? 0;
    final totalCorrect = stats?.totalCorrectAnswers ?? 0;
    final bestAvgTime = stats?.bestAverageTime ?? 999.0;
    final bestDailyStreak = stats?.bestDailyStreak ?? 0;
    final perfectGames = stats?.perfectGames ?? 0;

    // Tahmini toplam süre: soru başına ~12 sn
    final totalMinutes = totalQuestions > 0 ? (totalQuestions * 12 / 60).round() : 0;
    final avgTimeStr = bestAvgTime < 999 ? '${bestAvgTime.toStringAsFixed(1)} sn' : '-';

    final cards = [
      _DetailedStatCard(
        emoji: '⏱️',
        title: 'Toplam Süre',
        value: totalMinutes > 0 ? '$totalMinutes dk' : '-',
        tooltip: 'Tahmini toplam oyun süresi (soru başına ~12 sn varsayımı)',
        color: Colors.blue,
      ),
      _DetailedStatCard(
        emoji: '⚡',
        title: 'Ort. Çözüm Süresi',
        value: avgTimeStr,
        tooltip: 'En iyi ortalama soru çözüm süresi (saniye/soru)',
        color: Colors.teal,
      ),
      _DetailedStatCard(
        emoji: '📅',
        title: 'En Başarılı Gün',
        value: bestDailyStreak > 0 ? '$bestDailyStreak gün' : '-',
        tooltip: 'Ardışık en uzun günlük giriş serisi',
        color: Colors.amber,
      ),
      _DetailedStatCard(
        emoji: '✅',
        title: 'En Çok Doğru',
        value: '$totalCorrect',
        tooltip: 'Toplam doğru cevap sayısı',
        color: Colors.green,
      ),
      _DetailedStatCard(
        emoji: '💎',
        title: 'Hatasız Oyun',
        value: '$perfectGames',
        tooltip: 'Hiç yanlış yapmadan tamamlanan oyun sayısı',
        color: Colors.purple,
      ),
    ];

    return SizedBox(
      height: 140,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        itemCount: cards.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) => cards[index],
      ),
    );
  }

  Color _getSuccessColor(int percent) {
    if (percent >= 80) return const Color(0xFF4CAF50); // Yeşil: Başarılı
    if (percent >= 60) return const Color(0xFFFFC107); // Sarı: Dikkat
    return const Color(0xFFE53935); // Kırmızı: Zorlanıyor
  }

  Widget _buildRealChildCard({
    required String childName,
    required int totalScore,
    required int accuracy,
    required String lastActivity,
    required int dailyTarget,
    required int dailySolved,
    required int earnedBadges,
    required List<int> weeklyValues,
    bool isParent = false,
    String? userId,
  }) {
    final successColor = _getSuccessColor(accuracy);
    final heroTag = 'child_card_${userId ?? childName}';
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                ParentPanelChildDetailScreen.fromRealData(
              childName: childName,
              totalScore: totalScore,
              accuracy: accuracy,
              lastActivity: lastActivity,
              earnedBadges: earnedBadges,
              weeklyValues: weeklyValues,
              onBack: () => Navigator.pop(context),
              userId: userId,
              heroTag: heroTag,
            ),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.05),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  )),
                  child: child,
                ),
              );
            },
            transitionDuration: const Duration(milliseconds: 300),
          ),
        );
      },
      child: Hero(
        tag: heroTag,
        child: Container(
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
          mainAxisSize: MainAxisSize.min,
          children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.3),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        isParent ? '👑' : '🧒',
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          childName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Son aktivite: $lastActivity',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 16),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildMiniStat('⭐ Puan', totalScore, Colors.amber),
                  ),
                  Expanded(
                    child: _buildMiniStat(
                      '📊 Başarı',
                      accuracy,
                      successColor,
                      prefix: '%',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.flag, size: 14, color: Colors.white.withValues(alpha: 0.9)),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      'Günlük hedef: $dailyTarget soru ($dailySolved çözüldü)',
                      style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.9)),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Haftalık İlerleme:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(7, (i) {
                    final days = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
                    final v = weeklyValues[i];
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 20,
                            height: (v / 100) * 36,
                            decoration: BoxDecoration(
                              color: v >= 80
                                  ? Colors.green
                                  : (v >= 60 ? Colors.orange : Colors.grey.withValues(alpha: 0.5)),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            days[i],
                            style: TextStyle(fontSize: 9, color: Colors.white.withValues(alpha: 0.8)),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniStat(String label, dynamic value, Color color, {String prefix = '', String suffix = ''}) {
    final isNumeric = value is int;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
          isNumeric
              ? AnimatedCounter(
                  value: value,
                  prefix: prefix,
                  suffix: suffix,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                )
              : Text(
                  '$prefix$value$suffix',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
        ],
      ),
    );
  }

  String _getMonthName(int month) {
    const names = ['Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz', 'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara'];
    return names[month - 1];
  }

  Widget _buildStatCard(String emoji, String title, dynamic value, Color color, {String suffix = ''}) {
    final isNumeric = value is int;
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
          isNumeric
              ? AnimatedCounter(
                  value: value,
                  suffix: suffix,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                )
              : Text(
                  '$value$suffix',
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
    return Consumer3<AuthService, BadgeService, DailyRewardService>(
      builder: (context, auth, badge, reward, _) {
        final weeklyValues = _getWeeklyProgress(reward.loginStreak);
        final stats = badge.userStats;
        final totalQuestions = stats?.totalQuestionsAnswered ?? 0;
        final correctAnswers = stats?.totalCorrectAnswers ?? 0;
        final accuracy = totalQuestions > 0
            ? (correctAnswers / totalQuestions * 100).round()
            : 0;
        final childName = auth.currentUser?.displayName ?? auth.currentUser?.username ?? 'Oyuncu';

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildSectionTitle('PDF Rapor'),
            const SizedBox(height: 12),
            _buildPdfReportSection(
              context,
              childName: childName,
              weeklyValues: weeklyValues,
              stats: stats,
              accuracy: accuracy,
              badge: badge,
            ),

            const SizedBox(height: 24),

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

  Widget _buildPdfReportSection(
    BuildContext context, {
    required String childName,
    required List<int> weeklyValues,
    required UserStats? stats,
    required int accuracy,
    required BadgeService badge,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _generateAndSharePdf(
                context,
                childName: childName,
                weeklyValues: weeklyValues,
                stats: stats,
                accuracy: accuracy,
                badge: badge,
              ),
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text('PDF Rapor Oluştur'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE53935),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          if (_reportHistory.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(color: Colors.white24),
            const SizedBox(height: 8),
            Text(
              'Rapor Geçmişi (Son 4 hafta)',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
            const SizedBox(height: 8),
            ..._reportHistory.take(4).map((d) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Icon(Icons.history, size: 16, color: Colors.white.withOpacity(0.7)),
                      const SizedBox(width: 8),
                      Text(
                        '${d.day}.${d.month}.${d.year} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ],
      ),
    );
  }

  Future<void> _generateAndSharePdf(
    BuildContext context, {
    required String childName,
    required List<int> weeklyValues,
    required UserStats? stats,
    required int accuracy,
    required BadgeService badge,
  }) async {
    final locale = Localizations.localeOf(context);
    final localizations = AppLocalizations(locale);

    final badgeNames = badge.earnedBadges.map((e) {
      final def = badge.getBadgeDefinition(e.badgeId);
      return def != null ? localizations.get(def.nameKey) : e.badgeId;
    }).toList();

    final recommendations = _getRecommendationsList(stats, accuracy);

    final data = PdfReportData(
      childName: childName,
      totalScore: stats?.totalScore ?? 0,
      totalQuestions: stats?.totalQuestionsAnswered ?? 0,
      correctAnswers: stats?.totalCorrectAnswers ?? 0,
      accuracy: accuracy,
      earnedBadgesCount: badge.earnedBadgesCount,
      weeklyValues: weeklyValues,
      badgeNames: badgeNames,
      recommendations: recommendations,
    );

    try {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('PDF oluşturuluyor...'),
          duration: Duration(seconds: 1),
        ),
      );

      final bytes = await PdfReportService.generateReport(data);

      final fileName = 'mathfun_rapor_${childName.replaceAll(' ', '_')}.pdf';

      await Printing.sharePdf(
        bytes: bytes,
        filename: fileName,
      );

      setState(() {
        _reportHistory.insert(0, DateTime.now());
        _reportHistory = _reportHistory.take(4).toList();
      });
      await _saveReportHistory();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PDF rapor paylaşıma hazır!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF oluşturma hatası: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<String> _getRecommendationsList(UserStats? stats, int accuracy) {
    final items = <String>[];
    if (accuracy >= 80) {
      items.add('Harika gidiyorsun! Başarını korumaya devam et');
    } else if (accuracy >= 60) {
      items.add('Daha fazla pratik yaparak başarını artırabilirsin');
    } else {
      items.add('Temel konuları tekrar etmek faydalı olacaktır');
    }
    final totalQuestions = stats?.totalQuestionsAnswered ?? 0;
    if (totalQuestions < 50) {
      items.add('Daha fazla soru çözerek pratik yap');
    }
    if (items.isEmpty) {
      items.add('Oyun oynamaya devam et!');
    }
    return items;
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
              final targetHeight = (value / 100) * 100;
              return _AnimatedBar(
                value: value,
                targetHeight: targetHeight,
                dayLabel: days[index],
                delay: Duration(milliseconds: 100 * index),
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
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: score / 100),
                        duration: const Duration(milliseconds: 800),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, _) => ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: value,
                            backgroundColor: Colors.white.withOpacity(0.2),
                            valueColor: AlwaysStoppedAnimation(color),
                            minHeight: 6,
                          ),
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

        _buildSectionTitle('Bildirim ve Hatırlatıcılar'),
        const SizedBox(height: 12),
        _buildNotificationSettings(),

        const SizedBox(height: 24),

        _buildSectionTitle('Dil'),
        const SizedBox(height: 12),
        _buildLanguageSettings(),

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

  Widget _buildLanguageSettings() {
    return Consumer2<LocaleProvider, AuthService>(
      builder: (context, localeProvider, authService, _) {
        final currentCode = localeProvider.locale.languageCode;
        final currentLang = _supportedLanguages.firstWhere(
          (l) => l['code'] == currentCode,
          orElse: () => _supportedLanguages[0],
        );
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: ListTile(
            leading: Text(
              currentLang['flag'] as String,
              style: const TextStyle(fontSize: 28),
            ),
            title: const Text(
              'Uygulama Dili',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              currentLang['name'] as String,
              style: const TextStyle(color: Colors.white70),
            ),
            trailing: const Icon(Icons.chevron_right, color: Colors.white70),
            onTap: () => _showLanguageDialog(localeProvider, authService),
          ),
        );
      },
    );
  }

  void _showLanguageDialog(LocaleProvider localeProvider, AuthService authService) {
    final currentCode = localeProvider.locale.languageCode;
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF2C3E50),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Dil Seçin',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _supportedLanguages.length,
                  itemBuilder: (_, index) {
                    final lang = _supportedLanguages[index];
                    final isCurrent = currentCode == lang['code'];
                    return ListTile(
                      leading: Text(
                        lang['flag'] as String,
                        style: const TextStyle(fontSize: 24),
                      ),
                      title: Text(
                        lang['name'] as String,
                        style: TextStyle(
                          color: isCurrent ? Colors.amber : Colors.white,
                          fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      trailing: isCurrent
                          ? const Icon(Icons.check_circle, color: Colors.amber)
                          : null,
                      onTap: () async {
                        Navigator.pop(ctx);
                        final code = lang['code'] as String;
                        try {
                          await authService.updateUserLanguage(code);
                          if (mounted) {
                            localeProvider.changeLanguage(Locale(code));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Dil değiştirildi: ${lang['name']}'),
                                backgroundColor: Colors.green,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Hata: $e'),
                                backgroundColor: Colors.red,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        }
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
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

  Widget _buildNotificationSettings() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SwitchListTile(
            title: const Text(
              'Günlük Hatırlatıcı',
              style: TextStyle(color: Colors.white),
            ),
            subtitle: Text(
              _dailyReminderEnabled
                  ? 'Her gün ${_dailyReminderHour.toString().padLeft(2, '0')}:${_dailyReminderMinute.toString().padLeft(2, '0')}'
                  : 'Kapalı',
              style: const TextStyle(color: Colors.white70),
            ),
            value: _dailyReminderEnabled,
            onChanged: (value) async {
              setState(() => _dailyReminderEnabled = value);
              await _saveNotificationPrefs();
            },
            activeColor: Colors.green,
          ),
          if (_dailyReminderEnabled) ...[
            const Divider(color: Colors.white24),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Hatırlatma saati',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              trailing: TextButton.icon(
                onPressed: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay(
                      hour: _dailyReminderHour,
                      minute: _dailyReminderMinute,
                    ),
                    builder: (context, child) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: const ColorScheme.light(
                            primary: Color(0xFF3498DB),
                            onPrimary: Colors.white,
                          ),
                        ),
                        child: child!,
                      );
                    },
                  );
                  if (time != null) {
                    setState(() {
                      _dailyReminderHour = time.hour;
                      _dailyReminderMinute = time.minute;
                    });
                    await _saveNotificationPrefs();
                  }
                },
                icon: const Icon(Icons.access_time, color: Colors.white70, size: 20),
                label: Text(
                  '${_dailyReminderHour.toString().padLeft(2, '0')}:${_dailyReminderMinute.toString().padLeft(2, '0')}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
          const Divider(color: Colors.white24),
          SwitchListTile(
            title: const Text(
              'Başarı Mesajları',
              style: TextStyle(color: Colors.white),
            ),
            subtitle: const Text(
              'Yeni rozet, seri vb. bildirimleri',
              style: TextStyle(color: Colors.white70),
            ),
            value: _successMessagesEnabled,
            onChanged: (value) async {
              setState(() => _successMessagesEnabled = value);
              await _saveNotificationPrefs();
            },
            activeColor: Colors.green,
          ),
          const Divider(color: Colors.white24),
          SwitchListTile(
            title: const Text(
              'Haftalık Özet Raporu',
              style: TextStyle(color: Colors.white),
            ),
            subtitle: const Text(
              'Pazartesi sabahı haftalık özet',
              style: TextStyle(color: Colors.white70),
            ),
            value: _weeklySummaryEnabled,
            onChanged: (value) async {
              setState(() => _weeklySummaryEnabled = value);
              await _saveNotificationPrefs();
            },
            activeColor: Colors.green,
          ),
          const Divider(color: Colors.white24),
          SwitchListTile(
            title: const Text(
              'Çalışma Arası Uyarısı',
              style: TextStyle(color: Colors.white),
            ),
            subtitle: const Text(
              '3 günden fazla ara varsa hatırlat',
              style: TextStyle(color: Colors.white70),
            ),
            value: _inactivityWarningEnabled,
            onChanged: (value) async {
              setState(() => _inactivityWarningEnabled = value);
              await _saveNotificationPrefs();
            },
            activeColor: Colors.green,
          ),
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
    final currentController = TextEditingController();
    final newController = TextEditingController();
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
              controller: currentController,
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 4,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
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
              controller: newController,
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 4,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
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
            onPressed: () async {
              final current = currentController.text.trim();
              final newPin = newController.text.trim();
              if (current.length != 4 || newPin.length != 4) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('PIN 4 haneli olmalıdır'),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }
              final pinService = Provider.of<ParentPinService>(context, listen: false);
              final ok = await pinService.changePin(current, newPin);
              if (!context.mounted) return;
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(ok ? 'PIN değiştirildi' : 'Mevcut PIN yanlış'),
                  backgroundColor: ok ? Colors.green : Colors.red,
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

/// Animasyonlu bar grafik sütunu
class _AnimatedBar extends StatelessWidget {
  final int value;
  final double targetHeight;
  final String dayLabel;
  final Duration delay;

  const _AnimatedBar({
    required this.value,
    required this.targetHeight,
    required this.dayLabel,
    this.delay = Duration.zero,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      builder: (context, t, _) {
        final height = targetHeight * t;
        return Column(
          children: [
            AnimatedCounter(
              value: value,
              prefix: '%',
              duration: const Duration(milliseconds: 600),
              style: const TextStyle(fontSize: 10, color: Colors.white70),
            ),
            const SizedBox(height: 4),
            Container(
              width: 30,
              height: height.clamp(2.0, 100.0),
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
              dayLabel,
              style: const TextStyle(fontSize: 10, color: Colors.white70),
            ),
          ],
        );
      },
    );
  }
}

/// Tooltip'li detaylı istatistik kartı
class _DetailedStatCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String value;
  final String tooltip;
  final Color color;

  const _DetailedStatCard({
    required this.emoji,
    required this.title,
    required this.value,
    required this.tooltip,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      preferBelow: false,
      verticalOffset: 20,
      child: Container(
        width: 140,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withValues(alpha: 0.35),
              color.withValues(alpha: 0.15),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(emoji, style: const TextStyle(fontSize: 24)),
                const Spacer(),
                Icon(Icons.info_outline, size: 16, color: Colors.white.withValues(alpha: 0.6)),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 11,
                color: Colors.white.withValues(alpha: 0.85),
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

