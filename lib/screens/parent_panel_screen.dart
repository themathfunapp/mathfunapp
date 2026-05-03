import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:printing/printing.dart';
import '../services/auth_service.dart';
import '../services/pdf_report_service.dart';
import '../services/badge_service.dart';
import '../services/game_mechanics_service.dart';
import '../services/daily_reward_service.dart';
import '../services/family_service.dart';
import '../services/family_remote_duel_service.dart';
import '../services/parent_pin_service.dart';
import '../services/parent_panel_notification_scheduler.dart';
import '../models/badge.dart';
import '../models/family_member.dart';
import '../localization/app_localizations.dart';
import '../localization/parent_panel_l10n.dart';
import '../providers/locale_provider.dart';
import '../widgets/animated_counter.dart';
import '../widgets/shimmer_loading.dart';
import '../widgets/empty_state_lottie.dart';
import 'parent_panel_child_detail_screen.dart';
import 'family_duel_race_screen.dart';
import 'family_remote_duel_setup_screen.dart';
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
  static const int _tabCount = 4;
  static const List<String> _profileEmojiChoices = [
    '😀',
    '😎',
    '🤓',
    '🦊',
    '🐼',
    '🐯',
    '🦄',
    '🚀',
    '⚽',
    '🎮',
    '🌟',
    '🧠',
  ];

  Timer? _sessionCheckTimer;
  int _activeTab = 0;
  
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
  List<_ReportHistoryEntry> _reportHistory = [];
  bool _showReportHistory = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_bootstrapNotificationPrefs());
    _loadReportHistory();
    _startSessionCheck();
  }

  @override
  void dispose() {
    _sessionCheckTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _startSessionCheck() {
    _sessionCheckTimer?.cancel();
    _sessionCheckTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!mounted) return;
      final pinService = Provider.of<ParentPinService>(context, listen: false);
      if (pinService.isSessionExpired) {
        pinService.endSession();
        if (mounted) {
          final lc = Provider.of<LocaleProvider>(context, listen: false).locale.languageCode;
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(ParentPanelL10n.of(lc, 'pp_session_timeout')),
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
        final lc = mounted
            ? Provider.of<LocaleProvider>(context, listen: false).locale.languageCode
            : 'en';
        setState(() {
          _reportHistory = list
              .map((e) {
                if (e is Map<String, dynamic>) {
                  return _ReportHistoryEntry.fromMap(e, languageCode: lc);
                }
                if (e is Map) {
                  return _ReportHistoryEntry.fromMap(Map<String, dynamic>.from(e), languageCode: lc);
                }
                final legacy = DateTime.tryParse(e.toString());
                if (legacy == null) return null;
                return _ReportHistoryEntry(
                  createdAt: legacy,
                  data: PdfReportData(
                    childName: ParentPanelL10n.of(lc, 'pp_player_default'),
                    totalScore: 0,
                    totalQuestions: 0,
                    correctAnswers: 0,
                    accuracy: 0,
                    earnedBadgesCount: 0,
                    weeklyValues: [0, 0, 0, 0, 0, 0, 0],
                    badgeNames: [],
                    recommendations: const [],
                  ),
                );
              })
              .whereType<_ReportHistoryEntry>()
              .toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
          _reportHistory = _reportHistory.take(4).toList();
        });
        await _saveReportHistory();
      } catch (_) {}
    }
  }

  Future<void> _saveReportHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final list = _reportHistory.take(4).map((e) => e.toMap()).toList();
    await prefs.setString(_prefReportHistory, jsonEncode(list));
  }

  Future<void> _bootstrapNotificationPrefs() async {
    await _loadNotificationPrefs();
    if (!mounted) return;
    await ParentPanelNotificationScheduler.instance.syncFromDisk();
  }

  Future<void> _loadNotificationPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled =
          prefs.getBool(ParentPanelNotificationScheduler.prefMaster) ?? true;
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
    await prefs.setBool(ParentPanelNotificationScheduler.prefMaster, _notificationsEnabled);
    await prefs.setBool(_prefDailyReminder, _dailyReminderEnabled);
    await prefs.setInt(_prefDailyReminderHour, _dailyReminderHour);
    await prefs.setInt(_prefDailyReminderMin, _dailyReminderMinute);
    await prefs.setBool(_prefSuccessMessages, _successMessagesEnabled);
    await prefs.setBool(_prefWeeklySummary, _weeklySummaryEnabled);
    await prefs.setBool(_prefInactivityWarning, _inactivityWarningEnabled);
    await ParentPanelNotificationScheduler.instance.syncFromDisk();
  }

  String _pp(BuildContext context, String key) => ParentPanelL10n.of(
        Provider.of<LocaleProvider>(context).locale.languageCode,
        key,
      );

  /// Son aktivite metnini formatla (gerçek veri)
  String _formatLastActivity(DateTime? lastPlayedAt, BuildContext context) {
    final lc = Provider.of<LocaleProvider>(context).locale.languageCode;
    if (lastPlayedAt == null) return ParentPanelL10n.of(lc, 'pp_never_played');
    final diff = DateTime.now().difference(lastPlayedAt);
    if (diff.inMinutes < 1) return ParentPanelL10n.of(lc, 'pp_just_now');
    if (diff.inMinutes < 60) {
      return ParentPanelL10n.of(lc, 'pp_minutes_ago').replaceAll('{n}', '${diff.inMinutes}');
    }
    if (diff.inHours < 24) {
      return ParentPanelL10n.of(lc, 'pp_hours_ago').replaceAll('{n}', '${diff.inHours}');
    }
    if (diff.inDays == 1) return ParentPanelL10n.of(lc, 'pp_yesterday');
    return ParentPanelL10n.of(lc, 'pp_days_ago').replaceAll('{n}', '${diff.inDays}');
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
                Color(0xFFE8F5FF),
                Color(0xFFFFF3E0),
                Color(0xFFFFF8F8),
              ],
            ),
          ),
          child: SafeArea(
            child: Stack(
              children: [
                Positioned(
                  top: 24,
                  left: 18,
                  child: Text('⭐', style: TextStyle(fontSize: 22, color: Colors.orange.shade300)),
                ),
                Positioned(
                  top: 62,
                  right: 18,
                  child: Text('🎈', style: TextStyle(fontSize: 24, color: Colors.pink.shade300)),
                ),
                NestedScrollView(
                  headerSliverBuilder: (context, innerBoxIsScrolled) {
                    return [
                      SliverToBoxAdapter(
                        child: _buildCollapsibleHeader(),
                      ),
                    ];
                  },
                  body: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 280),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    transitionBuilder: (child, animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0.06, 0.0),
                            end: Offset.zero,
                          ).animate(animation),
                          child: child,
                        ),
                      );
                    },
                    child: KeyedSubtree(
                      key: ValueKey<int>(_activeTab),
                      child: _buildTabContent(_activeTab),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCollapsibleHeader() {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 8, 14, 8),
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFE7DDFD)),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          _buildTopBar(unifiedCard: true),
          Consumer4<AuthService, BadgeService, GameMechanicsService, DailyRewardService>(
            builder: (context, auth, badge, mechanics, reward, _) {
              return _buildPanelEntryCard(
                childName: auth.currentUser?.displayName ??
                    auth.currentUser?.username ??
                    _pp(context, 'pp_player_default'),
                loginStreak: reward.loginStreak,
                userEmoji: auth.currentUser?.profileEmoji,
                onEmojiTap: () => _showProfileEmojiPicker(auth),
                unifiedCard: true,
              );
            },
          ),
          _buildTabBar(unifiedCard: true),
        ],
      ),
    );
  }

  Widget _buildTopBar({bool unifiedCard = false}) {
    final now = DateTime.now();
    final dateStr = '${now.day} ${_getMonthName(context, now.month)}';
    return Padding(
      padding: unifiedCard
          ? const EdgeInsets.fromLTRB(8, 6, 8, 6)
          : const EdgeInsets.all(16),
      child: Row(
        children: [
          GestureDetector(
            onTap: widget.onBack,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 3)),
                ],
              ),
              child: const Icon(
                Icons.arrow_back_ios_new,
                color: Color(0xFF6A4FBF),
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
                  _pp(context, 'pp_corner_title'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.quicksand(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF6A4FBF),
                  ),
                ),
                Text(
                  _pp(context, 'pp_corner_subtitle'),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.deepPurple.shade300,
                  ),
                ),
              ],
            ),
          ),
          Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.calendar_today, color: Colors.deepPurple.shade300, size: 18),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    dateStr,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.deepPurple.shade300,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPanelEntryCard({
    required String childName,
    required int loginStreak,
    String? userEmoji,
    VoidCallback? onEmojiTap,
    bool unifiedCard = false,
  }) {
    return Container(
      margin: unifiedCard
          ? const EdgeInsets.symmetric(horizontal: 8, vertical: 8)
          : const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: unifiedCard
            ? const LinearGradient(
                colors: [Color(0xFFFFF7E6), Color(0xFFFFFDF7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : const LinearGradient(
                colors: [Color(0xFFFFE0B2), Color(0xFFFFF3E0)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 12, offset: Offset(0, 6)),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: onEmojiTap,
            child: Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(userEmoji?.trim().isNotEmpty == true ? userEmoji! : '😀', style: const TextStyle(fontSize: 22)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  childName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF6A4FBF),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text('🔥', style: TextStyle(fontSize: 12, color: Colors.deepOrange.shade400)),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        _pp(context, 'pp_day_streak').replaceAll('{n}', '$loginStreak'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.deepPurple.shade400,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: -0.06, end: 0.06),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeInOut,
            builder: (context, angle, child) {
              return Transform.rotate(angle: angle, child: child);
            },
            child: const Text('🤖', style: TextStyle(fontSize: 34)),
          ),
        ],
      ),
    );
  }

  Future<void> _showProfileEmojiPicker(AuthService auth) async {
    if (auth.currentUser == null || auth.currentUser!.isGuest) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_pp(context, 'pp_emoji_need_login')),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _pp(sheetContext, 'pp_pick_emoji_title'),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.deepPurple.shade700,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _profileEmojiChoices.map((emoji) {
                    return InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => Navigator.of(sheetContext).pop(emoji),
                      child: Container(
                        width: 48,
                        height: 48,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF6F2FF),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFD7C9FF)),
                        ),
                        child: Text(emoji, style: const TextStyle(fontSize: 24)),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (selected == null || !mounted) return;
    await auth.updateProfile(profileEmoji: selected);
  }

  Future<void> _showMemberEmojiPicker({
    required AuthService auth,
    required FamilyService familyService,
    required LeaderboardEntry entry,
  }) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _pp(sheetContext, 'pp_pick_emoji_for').replaceAll('{name}', entry.displayName),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.deepPurple.shade700,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _profileEmojiChoices.map((emoji) {
                    return InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => Navigator.of(sheetContext).pop(emoji),
                      child: Container(
                        width: 48,
                        height: 48,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF6F2FF),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFD7C9FF)),
                        ),
                        child: Text(emoji, style: const TextStyle(fontSize: 24)),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (selected == null || !mounted) return;
    if (entry.userId == auth.userId) {
      await auth.updateProfile(profileEmoji: selected);
      return;
    }
    await familyService.updateMemberEmoji(userId: entry.userId, profileEmoji: selected);
  }

  Widget _buildTabBar({bool unifiedCard = false}) {
    return Container(
      margin: unifiedCard
          ? const EdgeInsets.fromLTRB(8, 4, 8, 4)
          : const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: unifiedCard ? const Color(0xFFF8F3FF) : Colors.white.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE7DDFD)),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: List.generate(_tabCount, (index) {
          final labels = [
            _pp(context, 'pp_tab_progress'),
            _pp(context, 'pp_tab_stats'),
            _pp(context, 'pp_tab_family'),
            _pp(context, 'pp_tab_settings'),
          ];
          const icons = [Icons.dashboard, Icons.bar_chart, Icons.groups, Icons.settings];
          final active = _activeTab == index;
          return _PressScaleButton(
            onTap: () => setState(() => _activeTab = index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: active ? const Color(0xFFFFEB3B) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: active ? const Color(0xFFE2C600) : const Color(0xFFE8DFFB),
                ),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 3)),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icons[index], size: active ? 20 : 18, color: const Color(0xFF6A4FBF)),
                  const SizedBox(width: 8),
                  Text(
                    labels[index],
                    style: TextStyle(
                      fontSize: active ? 14 : 13,
                      fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                      color: const Color(0xFF6A4FBF),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildTabContent(int index) {
    switch (index) {
      case 0:
        return _buildStatsTab();
      case 1:
        return _buildReportsTab();
      case 2:
        return _buildFamilyGameTab();
      case 3:
      default:
        return _buildSettingsTab();
    }
  }

  /// Oyun Oyna — ebeveyn modu oyun merkezi (birlikte yarış, bölge haritası).
  Widget _buildPlayGamesTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF243B55), Color(0xFF141E30)],
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [
              BoxShadow(color: Colors.black26, blurRadius: 12, offset: Offset(0, 6)),
            ],
          ),
          child: ParentModeGamesHub.forParentPanelTab(
            onJumpToGelisimTab: () {
              if (_activeTab != 0) setState(() => _activeTab = 0);
            },
          ),
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
            _buildSectionTitle(_pp(context, 'pp_section_game_center')),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF243B55), Color(0xFF141E30)],
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 12, offset: Offset(0, 6)),
                ],
              ),
              child: ParentModeGamesHub.forParentPanelTab(
                onJumpToGelisimTab: () {
                  if (_activeTab != 0) setState(() => _activeTab = 0);
                },
              ),
            ),
            const SizedBox(height: 24),
            _buildSectionTitle(_pp(context, 'pp_section_family_lb')),
            const SizedBox(height: 12),
            _buildFamilyLeaderboard(familyService),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEDE7F6)),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4)),
        ],
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
                      _pp(context, 'pp_filter_weekly'),
                    ),
                    _buildLeaderboardFilterChip(
                      familyService,
                      LeaderboardFilter.monthly,
                      _pp(context, 'pp_filter_monthly'),
                    ),
                    _buildLeaderboardFilterChip(
                      familyService,
                      LeaderboardFilter.allTime,
                      _pp(context, 'pp_filter_all_time'),
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
                        _pp(context, 'pp_add_child'),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
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
                message: _pp(context, 'pp_empty_family'),
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
        title: Text(
          _pp(context, 'pp_add_child_title'),
          style: const TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _pp(context, 'pp_add_child_desc'),
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
            child: Text(_pp(context, 'pp_cancel'), style: TextStyle(color: Colors.white.withValues(alpha: 0.8))),
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
                    content: Text(
                      ok ? _pp(context, 'pp_child_added') : _pp(context, 'pp_child_add_fail'),
                    ),
                    backgroundColor: ok ? Colors.green : Colors.orange,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: Text(_pp(context, 'pp_add')),
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
              : const Color(0xFFF4F1FF),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? Colors.amber
                : const Color(0xFFE0D7FF),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? const Color(0xFF4E342E) : const Color(0xFF5E35B1),
          ),
        ),
      ),
    );
  }

  Widget _buildLeaderboardTable(List<LeaderboardEntry> entries) {
    final screenW = MediaQuery.of(context).size.width;
    final compact = screenW < 900;
    final tableWidth = compact ? 520.0 : 620.0;
    final nameWidth = compact ? 180.0 : 220.0;
    final scoreWidth = compact ? 52.0 : 56.0;
    final accuracyWidth = compact ? 44.0 : 48.0;
    final activityWidth = compact ? 140.0 : 180.0;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: tableWidth,
        child: Column(
          children: [
            // Başlık satırı
            Row(
              children: [
                SizedBox(width: 36, child: Text(_pp(context, 'pp_lb_rank'), style: _leaderboardHeaderStyle)),
                const SizedBox(width: 8),
                SizedBox(width: nameWidth, child: Text(_pp(context, 'pp_lb_name'), style: _leaderboardHeaderStyle)),
                SizedBox(width: scoreWidth, child: Text(_pp(context, 'pp_lb_score'), style: _leaderboardHeaderStyle)),
                SizedBox(width: accuracyWidth, child: Text(_pp(context, 'pp_lb_accuracy'), style: _leaderboardHeaderStyle)),
                SizedBox(width: activityWidth, child: Text(_pp(context, 'pp_lb_last_activity'), style: _leaderboardHeaderStyle)),
              ],
            ),
            const SizedBox(height: 12),
            Divider(color: Colors.deepPurple.shade100, height: 1),
            const SizedBox(height: 8),
            ...entries.map((e) => _buildLeaderboardRow(e, compact: compact)),
          ],
        ),
      ),
    );
  }

  TextStyle get _leaderboardHeaderStyle => TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: Colors.deepPurple.shade300,
      );

  Widget _buildLeaderboardRow(LeaderboardEntry entry, {bool compact = false}) {
    final auth = Provider.of<AuthService>(context, listen: false);
    final familyService = Provider.of<FamilyService>(context, listen: false);
    final resolvedEmoji = entry.userId == auth.userId
        ? auth.currentUser?.profileEmoji
        : entry.profileEmoji;
    final nameWidth = compact ? 180.0 : 220.0;
    final scoreWidth = compact ? 52.0 : 56.0;
    final accuracyWidth = compact ? 44.0 : 48.0;
    final activityWidth = compact ? 140.0 : 180.0;
    final baseFont = compact ? 12.0 : 13.0;
    Color rankColor = const Color(0xFF5E35B1);
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
          SizedBox(
            width: nameWidth,
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => _showMemberEmojiPicker(
                    auth: auth,
                    familyService: familyService,
                    entry: entry,
                  ),
                  child: Text(
                    '${(resolvedEmoji != null && resolvedEmoji.trim().isNotEmpty) ? resolvedEmoji : (entry.isParent ? '👑' : '🧒')} ',
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
                Expanded(
                  child: Text(
                    entry.displayName,
                    style: TextStyle(
                      fontSize: baseFont,
                      color: Color(0xFF5E35B1),
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: scoreWidth,
            child: Text(
              '${entry.score}',
              style: TextStyle(
                fontSize: baseFont,
                fontWeight: FontWeight.w600,
                color: Color(0xFF4E342E),
              ),
            ),
          ),
          SizedBox(
            width: accuracyWidth,
            child: Text(
              '%${entry.accuracy}',
              style: TextStyle(
                fontSize: baseFont,
                fontWeight: FontWeight.w600,
                color: _getSuccessColor(entry.accuracy),
              ),
            ),
          ),
          SizedBox(
            width: activityWidth,
            child: Text(
              _formatLastActivity(entry.lastPlayedAt, context),
              style: TextStyle(
                fontSize: compact ? 10 : 11,
                color: Colors.deepPurple.shade300,
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

  Future<void> _openRemoteFamilyDuel(BuildContext context) async {
    final auth = Provider.of<AuthService>(context, listen: false);
    final uid = auth.currentUser?.uid;
    if (uid == null || uid.isEmpty) return;

    final duel = Provider.of<FamilyRemoteDuelService>(context, listen: false);
    final linked = await duel.linkedChildUserIdsForHost(uid);
    if (!context.mounted) return;
    if (linked.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_pp(context, 'pp_remote_duel_login')),
        ),
      );
      return;
    }

    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (ctx) => FamilyRemoteDuelSetupScreen(
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
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFEDE7F6)),
            boxShadow: const [
              BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
            ],
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
                child: Icon(icon, color: const Color(0xFF5E35B1), size: 24),
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
                        color: Color(0xFF5E35B1),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.deepPurple.shade300,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: Colors.deepPurple.shade200, size: 16),
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
          _buildSectionTitle(_pp(context, 'pp_section_progress')),
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
          _buildSectionTitle(_pp(context, 'pp_section_detailed_stats')),
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
    return Consumer5<AuthService, FamilyService, DailyRewardService, BadgeService, GameMechanicsService>(
      builder: (context, auth, familyService, reward, badge, mechanics, _) {
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
              _buildSectionTitle(_pp(context, 'pp_section_progress')),
              const SizedBox(height: 24),
              Center(
                child: EmptyStateLottie(
                  message: _pp(context, 'pp_empty_family_stats'),
                  size: 140,
                  fallbackIcon: Icons.group_off_rounded,
                ),
              ),
              const SizedBox(height: 20),
              _buildSectionTitle(_pp(context, 'pp_section_detailed_stats')),
              const SizedBox(height: 12),
              _buildDetailedStats(context, badge, mechanics),
            ],
          );
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildSectionTitle(_pp(context, 'pp_section_progress')),
            const SizedBox(height: 12),
            ...entries.map((entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildRealChildCard(
                    context,
                    childName: entry.displayName,
                    totalScore: entry.score,
                    accuracy: entry.accuracy,
                    lastActivity: _formatLastActivity(entry.lastPlayedAt, context),
                    dailyTarget: dailyTarget,
                    dailySolved: dailySolved,
                    earnedBadges: entry.earnedBadges,
                    weeklyValues: entry.weeklyValues,
                    isParent: entry.isParent,
                    userId: entry.userId,
                    userEmoji: entry.userId == auth.userId
                        ? auth.currentUser?.profileEmoji
                        : entry.profileEmoji,
                    onEmojiTap: () => _showMemberEmojiPicker(
                      auth: auth,
                      familyService: familyService,
                      entry: entry,
                    ),
                  ),
                )),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    '🏆',
                    _pp(context, 'pp_stat_family_members'),
                    entries.length,
                    Colors.purple,
                    suffix: '',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    '🔥',
                    _pp(context, 'pp_stat_login_streak'),
                    reward.loginStreak,
                    Colors.orange,
                    suffix: _pp(context, 'pp_suffix_days'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildSectionTitle(_pp(context, 'pp_section_detailed_stats')),
            const SizedBox(height: 12),
            _buildDetailedStats(context, badge, mechanics),
          ],
        );
      },
    );
  }

  /// Yatay kaydırılabilir detaylı istatistik kartları
  Widget _buildDetailedStats(
    BuildContext context,
    BadgeService badge,
    GameMechanicsService mechanics,
  ) {
    final stats = badge.userStats;
    final totalQuestions = stats?.totalQuestionsAnswered ?? 0;
    final totalCorrect = stats?.totalCorrectAnswers ?? 0;
    final bestAvgTime = stats?.bestAverageTime ?? 999.0;
    final bestDailyStreak = stats?.bestDailyStreak ?? 0;
    final perfectGames = stats?.perfectGames ?? 0;

    // Tahmini toplam süre: soru başına ~12 sn
    final totalMinutes = totalQuestions > 0 ? (totalQuestions * 12 / 60).round() : 0;
    final avgTimeStr = bestAvgTime < 999
        ? '${bestAvgTime.toStringAsFixed(1)}${_pp(context, 'pp_suffix_seconds')}'
        : '-';
    final sufDays = _pp(context, 'pp_suffix_days');

    final cards = [
      _DetailedStatCard(
        emoji: '⏱️',
        title: _pp(context, 'pp_det_stat_total_time'),
        value: totalMinutes > 0 ? '$totalMinutes${_pp(context, 'pp_suffix_minutes')}' : '-',
        tooltip: _pp(context, 'pp_det_tooltip_total_time'),
        color: Colors.blue,
      ),
      _DetailedStatCard(
        emoji: '⚡',
        title: _pp(context, 'pp_det_stat_avg_time'),
        value: avgTimeStr,
        tooltip: _pp(context, 'pp_det_tooltip_avg'),
        color: Colors.teal,
      ),
      _DetailedStatCard(
        emoji: '📅',
        title: _pp(context, 'pp_det_stat_best_day'),
        value: bestDailyStreak > 0 ? '$bestDailyStreak$sufDays' : '-',
        tooltip: _pp(context, 'pp_det_tooltip_streak'),
        color: Colors.amber,
      ),
      _DetailedStatCard(
        emoji: '✅',
        title: _pp(context, 'pp_det_stat_correct'),
        value: '$totalCorrect',
        tooltip: _pp(context, 'pp_det_tooltip_correct'),
        color: Colors.green,
      ),
      _DetailedStatCard(
        emoji: '💎',
        title: _pp(context, 'pp_det_stat_perfect'),
        value: '$perfectGames',
        tooltip: _pp(context, 'pp_det_tooltip_perfect'),
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

  Widget _buildRealChildCard(
    BuildContext context, {
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
    String? userEmoji,
    VoidCallback? onEmojiTap,
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
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFFFFFF),
              Color(0xFFFFF7E6),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFFFE0B2)),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: onEmojiTap,
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.3),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          (userEmoji != null && userEmoji.trim().isNotEmpty)
                              ? userEmoji
                              : (isParent ? '👑' : '🧒'),
                          style: const TextStyle(fontSize: 24),
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
                          childName,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple.shade500,
                          ),
                        ),
                        Text(
                          '${_pp(context, 'pp_last_activity_prefix')}$lastActivity',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.deepPurple.shade300,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios, color: Colors.deepPurple.shade200, size: 16),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildMiniStat(_pp(context, 'pp_mini_points'), totalScore, Colors.amber),
                  ),
                  Expanded(
                    child: _buildMiniStat(
                      _pp(context, 'pp_mini_success'),
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
                  Icon(Icons.flag, size: 14, color: Colors.deepPurple.shade300),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      _pp(context, 'pp_daily_goal_template')
                          .replaceAll('{target}', '$dailyTarget')
                          .replaceAll('{solved}', '$dailySolved'),
                      style: TextStyle(fontSize: 12, color: Colors.deepPurple.shade400),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                _pp(context, 'pp_weekly_progress_label'),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.deepPurple.shade400,
                ),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(7, (i) {
                    final days = List.generate(
                      7,
                      (d) => _pp(context, 'pp_weekday_$d'),
                    );
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
                            style: TextStyle(fontSize: 9, color: Colors.deepPurple.shade300),
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.deepPurple.shade300,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          isNumeric
              ? AnimatedCounter(
                  value: value,
                  prefix: prefix,
                  suffix: suffix,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                )
              : Text(
                  '$prefix$value$suffix',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
        ],
      ),
    );
  }

  String _getMonthName(BuildContext context, int month) =>
      _pp(context, 'pp_month_$month');

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
              color: Colors.deepPurple.shade300,
            ),
          ),
          isNumeric
              ? AnimatedCounter(
                  value: value,
                  suffix: suffix,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF5E35B1),
                  ),
                )
              : Text(
                  '$value$suffix',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF5E35B1),
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
        final childName = auth.currentUser?.displayName ??
            auth.currentUser?.username ??
            _pp(context, 'pp_player_default');

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildSectionTitle(_pp(context, 'pp_report_pdf_title')),
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

            _buildSectionTitle(_pp(context, 'pp_report_weekly_chart')),
            const SizedBox(height: 12),
            _buildWeeklyChart(context, weeklyValues),

            const SizedBox(height: 24),

            _buildSectionTitle(_pp(context, 'pp_report_topic')),
            const SizedBox(height: 12),
            _buildTopicPerformance(context, accuracy),

            const SizedBox(height: 24),

            _buildSectionTitle(_pp(context, 'pp_recommendations_title')),
            const SizedBox(height: 12),
            _buildRecommendations(context, stats, accuracy),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4)),
        ],
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
              label: Text(_pp(context, 'pp_report_generate')),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE53935),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          if (_reportHistory.isNotEmpty) ...[
            const SizedBox(height: 16),
            Divider(color: Colors.deepPurple.shade100),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: () => setState(() => _showReportHistory = !_showReportHistory),
                icon: Icon(
                  _showReportHistory ? Icons.expand_less : Icons.history,
                  size: 18,
                  color: Colors.deepPurple.shade400,
                ),
                label: Text(
                  _showReportHistory
                      ? _pp(context, 'pp_report_history_hide')
                      : _pp(context, 'pp_report_history_show'),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.deepPurple.shade500,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.deepPurple.shade100),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: _showReportHistory
                  ? Padding(
                      key: const ValueKey('report_history_open'),
                      padding: const EdgeInsets.only(top: 8),
                      child: Column(
                        children: _reportHistory.take(4).map((entry) => Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(8),
                                  onTap: () => _openReportHistoryEntry(entry),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                                    child: Row(
                                      children: [
                                        Icon(Icons.history, size: 16, color: Colors.deepPurple.shade300),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            '${entry.createdAt.day}.${entry.createdAt.month}.${entry.createdAt.year} ${entry.createdAt.hour.toString().padLeft(2, '0')}:${entry.createdAt.minute.toString().padLeft(2, '0')}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.deepPurple.shade300,
                                            ),
                                          ),
                                        ),
                                        GestureDetector(
                                          onTap: () => _confirmDeleteReportHistoryEntry(entry),
                                          child: const Padding(
                                            padding: EdgeInsets.all(4),
                                            child: Icon(Icons.delete_outline, size: 16, color: Color(0xFFE53935)),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            )).toList(),
                      ),
                    )
                  : const SizedBox(key: ValueKey('report_history_closed')),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _openReportHistoryEntry(_ReportHistoryEntry entry) async {
    try {
      final bytes = await PdfReportService.generateReport(entry.data);
      final fileName =
          'mathfun_rapor_${entry.data.childName.replaceAll(' ', '_')}_${entry.createdAt.millisecondsSinceEpoch}.pdf';
      await Printing.sharePdf(bytes: bytes, filename: fileName);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${_pp(context, 'pp_report_open_fail')}$e')),
      );
    }
  }

  Future<void> _confirmDeleteReportHistoryEntry(_ReportHistoryEntry target) async {
    final shouldDelete = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: _pp(context, 'pp_barrier_delete_confirm'),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        return SafeArea(
          child: Center(
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: 360,
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF6FB),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: const Color(0xFFFFCFE2)),
                  boxShadow: const [
                    BoxShadow(color: Colors.black26, blurRadius: 18, offset: Offset(0, 10)),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFE3EE),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text('🗑️', style: TextStyle(fontSize: 18)),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _pp(context, 'pp_report_delete_title'),
                            style: TextStyle(
                              fontSize: 21,
                              fontWeight: FontWeight.w800,
                              color: Colors.deepPurple.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _pp(context, 'pp_report_delete_body'),
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.deepPurple.shade500,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(dialogContext).pop(false),
                          child: Text(_pp(context, 'pp_no')),
                        ),
                        const SizedBox(width: 8),
                        FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFFE53935),
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () => Navigator.of(dialogContext).pop(true),
                          child: Text(_pp(context, 'pp_yes_delete')),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutBack);
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(scale: Tween<double>(begin: 0.9, end: 1.0).animate(curved), child: child),
        );
      },
    );
    if (shouldDelete != true || !mounted) return;

    setState(() {
      _reportHistory.remove(target);
    });
    await _saveReportHistory();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_pp(context, 'pp_report_deleted')),
        duration: const Duration(seconds: 2),
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
    final now = DateTime.now();
    final isSunday = now.weekday == DateTime.sunday;
    if (!isSunday) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_pp(context, 'pp_report_sunday_only')),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final locale = Localizations.localeOf(context);
    final localizations = AppLocalizations(locale);

    final badgeNames = badge.earnedBadges.map((e) {
      final def = badge.getBadgeDefinition(e.badgeId);
      return def != null ? localizations.get(def.nameKey) : e.badgeId;
    }).toList();

    final recommendations = _getRecommendationsList(context, stats, accuracy);

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
        SnackBar(
          content: Text(_pp(context, 'pp_pdf_generating')),
          duration: const Duration(seconds: 1),
        ),
      );

      final bytes = await PdfReportService.generateReport(data);

      final fileName = 'mathfun_rapor_${childName.replaceAll(' ', '_')}.pdf';

      await Printing.sharePdf(
        bytes: bytes,
        filename: fileName,
      );

      setState(() {
        _reportHistory.insert(
          0,
          _ReportHistoryEntry(
            createdAt: DateTime.now(),
            data: data,
          ),
        );
        _reportHistory = _reportHistory.take(4).toList();
      });
      await _saveReportHistory();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_pp(context, 'pp_pdf_ready')),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_pp(context, 'pp_pdf_error')}$e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<String> _getRecommendationsList(
    BuildContext context,
    UserStats? stats,
    int accuracy,
  ) {
    final items = <String>[];
    if (accuracy >= 80) {
      items.add(_pp(context, 'pp_rec_great'));
    } else if (accuracy >= 60) {
      items.add(_pp(context, 'pp_rec_practice'));
    } else {
      items.add(_pp(context, 'pp_rec_basics'));
    }
    final totalQuestions = stats?.totalQuestionsAnswered ?? 0;
    if (totalQuestions < 50) {
      items.add(_pp(context, 'pp_rec_more_questions'));
    }
    if (items.isEmpty) {
      items.add(_pp(context, 'pp_rec_keep_playing'));
    }
    return items;
  }

  Widget _buildWeeklyChart(BuildContext context, List<int> values) {
    final days = List.generate(7, (d) => _pp(context, 'pp_weekday_$d'));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4)),
        ],
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

  Widget _buildTopicPerformance(BuildContext context, int overallAccuracy) {
    final topics = [
      {'name': _pp(context, 'pp_topic_general'), 'emoji': '📊', 'score': overallAccuracy},
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4)),
        ],
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
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.deepPurple.shade500,
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
                            backgroundColor: Colors.deepPurple.shade50,
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

  Widget _buildRecommendations(BuildContext context, UserStats? stats, int accuracy) {
    final items = <String>[];
    if (accuracy >= 80) {
      items.add(_pp(context, 'pp_rec_star_great'));
    } else if (accuracy >= 60) {
      items.add(_pp(context, 'pp_rec_book_practice'));
    } else {
      items.add(_pp(context, 'pp_rec_target_basics'));
    }
    final totalQuestions = stats?.totalQuestionsAnswered ?? 0;
    if (totalQuestions < 50) {
      items.add(_pp(context, 'pp_rec_note_questions'));
    }
    if (items.isEmpty) {
      items.add(_pp(context, 'pp_rec_game_keep'));
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lightbulb, color: Colors.amber, size: 24),
              const SizedBox(width: 8),
              Text(
                _pp(context, 'pp_recommendations_title'),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple.shade500,
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
          Text('•', style: TextStyle(color: Colors.deepPurple.shade300)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: Colors.deepPurple.shade300,
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
        _buildSectionTitle(_pp(context, 'pp_settings_time')),
        const SizedBox(height: 12),
        _buildTimeControlSettings(),

        const SizedBox(height: 24),

        _buildSectionTitle(_pp(context, 'pp_settings_notifications')),
        const SizedBox(height: 12),
        _buildNotificationSettings(),

        const SizedBox(height: 24),

        _buildSectionTitle(_pp(context, 'pp_settings_language')),
        const SizedBox(height: 12),
        _buildLanguageSettings(),

        const SizedBox(height: 24),

        _buildSectionTitle(_pp(context, 'pp_settings_app')),
        const SizedBox(height: 12),
        _buildAppSettings(),

        const SizedBox(height: 24),

        _buildSectionTitle(_pp(context, 'pp_settings_security')),
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
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4)),
            ],
          ),
          child: ListTile(
            leading: Text(
              currentLang['flag'] as String,
              style: const TextStyle(fontSize: 28),
            ),
            title: Text(
              _pp(context, 'pp_lang_app_title'),
              style: TextStyle(color: Colors.deepPurple.shade500, fontWeight: FontWeight.w700),
            ),
            subtitle: Text(
              currentLang['name'] as String,
              style: TextStyle(color: Colors.deepPurple.shade300),
            ),
            trailing: Icon(Icons.chevron_right, color: Colors.deepPurple.shade300),
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
                  _pp(ctx, 'pp_lang_choose_title'),
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
                                content: Text(
                                  _pp(context, 'pp_lang_changed').replaceAll('{name}', '${lang['name']}'),
                                ),
                                backgroundColor: Colors.green,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${_pp(context, 'pp_error_prefix')}$e'),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          SwitchListTile(
            title: Text(
              _pp(context, 'pp_daily_limit_title'),
              style: TextStyle(color: Colors.deepPurple.shade500),
            ),
            subtitle: Text(
              _dailyLimitEnabled
                  ? '$_dailyLimitMinutes${_pp(context, 'pp_suffix_minutes')}'
                  : _pp(context, 'pp_off'),
              style: TextStyle(color: Colors.deepPurple.shade300),
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
            Divider(color: Colors.deepPurple.shade100),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _pp(context, 'pp_duration_label'),
                  style: TextStyle(color: Colors.deepPurple.shade300),
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
                      icon: Icon(Icons.remove_circle, color: Colors.deepPurple.shade300),
                    ),
                    Text(
                      '$_dailyLimitMinutes',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple.shade500,
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
                      icon: Icon(Icons.add_circle, color: Colors.deepPurple.shade300),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SwitchListTile(
            title: Text(
              _pp(context, 'pp_reminder_daily'),
              style: TextStyle(color: Colors.deepPurple.shade500),
            ),
            subtitle: Text(
              _dailyReminderEnabled
                  ? '${_pp(context, 'pp_every_day')}${_dailyReminderHour.toString().padLeft(2, '0')}:${_dailyReminderMinute.toString().padLeft(2, '0')}'
                  : _pp(context, 'pp_off'),
              style: TextStyle(color: Colors.deepPurple.shade300),
            ),
            value: _dailyReminderEnabled,
            onChanged: (value) async {
              setState(() => _dailyReminderEnabled = value);
              await _saveNotificationPrefs();
            },
            activeColor: Colors.green,
          ),
          if (_dailyReminderEnabled) ...[
            Divider(color: Colors.deepPurple.shade100),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                _pp(context, 'pp_reminder_time'),
                style: TextStyle(color: Colors.deepPurple.shade300, fontSize: 13),
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
                icon: Icon(Icons.access_time, color: Colors.deepPurple.shade300, size: 20),
                label: Text(
                  '${_dailyReminderHour.toString().padLeft(2, '0')}:${_dailyReminderMinute.toString().padLeft(2, '0')}',
                  style: TextStyle(
                    color: Colors.deepPurple.shade500,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
          Divider(color: Colors.deepPurple.shade100),
          SwitchListTile(
            title: Text(
              _pp(context, 'pp_success_msgs'),
              style: TextStyle(color: Colors.deepPurple.shade500),
            ),
            subtitle: Text(
              _pp(context, 'pp_success_msgs_sub'),
              style: TextStyle(color: Colors.deepPurple.shade300),
            ),
            value: _successMessagesEnabled,
            onChanged: (value) async {
              setState(() => _successMessagesEnabled = value);
              await _saveNotificationPrefs();
            },
            activeColor: Colors.green,
          ),
          Divider(color: Colors.deepPurple.shade100),
          SwitchListTile(
            title: Text(
              _pp(context, 'pp_weekly_summary'),
              style: TextStyle(color: Colors.deepPurple.shade500),
            ),
            subtitle: Text(
              _pp(context, 'pp_weekly_summary_sub'),
              style: TextStyle(color: Colors.deepPurple.shade300),
            ),
            value: _weeklySummaryEnabled,
            onChanged: (value) async {
              setState(() => _weeklySummaryEnabled = value);
              await _saveNotificationPrefs();
            },
            activeColor: Colors.green,
          ),
          Divider(color: Colors.deepPurple.shade100),
          SwitchListTile(
            title: Text(
              _pp(context, 'pp_inactivity'),
              style: TextStyle(color: Colors.deepPurple.shade500),
            ),
            subtitle: Text(
              _pp(context, 'pp_inactivity_sub'),
              style: TextStyle(color: Colors.deepPurple.shade300),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          SwitchListTile(
            title: Text(
              _pp(context, 'pp_sounds'),
              style: TextStyle(color: Colors.deepPurple.shade500),
            ),
            subtitle: Text(
              _pp(context, 'pp_sounds_sub'),
              style: TextStyle(color: Colors.deepPurple.shade300),
            ),
            value: _soundEnabled,
            onChanged: (value) {
              setState(() {
                _soundEnabled = value;
              });
            },
            activeColor: Colors.green,
          ),
          Divider(color: Colors.deepPurple.shade100),
          SwitchListTile(
            title: Text(
              _pp(context, 'pp_notifications_toggle'),
              style: TextStyle(color: Colors.deepPurple.shade500),
            ),
            subtitle: Text(
              _pp(context, 'pp_notifications_sub'),
              style: TextStyle(color: Colors.deepPurple.shade300),
            ),
            value: _notificationsEnabled,
            onChanged: (value) async {
              setState(() {
                _notificationsEnabled = value;
              });
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool(ParentPanelNotificationScheduler.prefMaster, value);
              await ParentPanelNotificationScheduler.instance.syncFromDisk();
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          SwitchListTile(
            title: Text(
              _pp(context, 'pp_safe_mode'),
              style: TextStyle(color: Colors.deepPurple.shade500),
            ),
            subtitle: Text(
              _pp(context, 'pp_safe_mode_sub'),
              style: TextStyle(color: Colors.deepPurple.shade300),
            ),
            value: _safeMode,
            onChanged: (value) {
              setState(() {
                _safeMode = value;
              });
            },
            activeColor: Colors.green,
          ),
          Divider(color: Colors.deepPurple.shade100),
          ListTile(
            leading: Icon(Icons.lock, color: Colors.deepPurple.shade300),
            title: Text(
              _pp(context, 'pp_change_pin'),
              style: TextStyle(color: Colors.deepPurple.shade500),
            ),
            subtitle: Text(
              _pp(context, 'pp_change_pin_sub'),
              style: TextStyle(color: Colors.deepPurple.shade300),
            ),
            trailing: Icon(Icons.chevron_right, color: Colors.deepPurple.shade300),
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
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: const Color(0xFF2C3E50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(_pp(context, 'pp_pin_title'), style: const TextStyle(color: Colors.white)),
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
                labelText: _pp(context, 'pp_pin_current'),
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
                labelText: _pp(context, 'pp_pin_new'),
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
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text(_pp(context, 'pp_cancel_caps'), style: const TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () async {
              final current = currentController.text.trim();
              final newPin = newController.text.trim();
              if (current.length != 4 || newPin.length != 4) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(_pp(context, 'pp_pin_must_4')),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }
              final pinService = Provider.of<ParentPinService>(context, listen: false);
              final ok = await pinService.changePin(current, newPin);
              if (!dialogCtx.mounted) return;
              Navigator.pop(dialogCtx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(ok ? _pp(context, 'pp_pin_changed') : _pp(context, 'pp_pin_wrong')),
                  backgroundColor: ok ? Colors.green : Colors.red,
                ),
              );
            },
            child: Text(_pp(context, 'pp_save_caps'), style: const TextStyle(color: Colors.blue)),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    final firstSpace = title.indexOf(' ');
    final firstToken = firstSpace > 0 ? title.substring(0, firstSpace) : title;
    final hasEmojiPrefix = firstSpace > 0 && _looksLikeEmojiPrefix(firstToken);
    final emoji = hasEmojiPrefix ? title.substring(0, firstSpace) : '✨';
    final text = hasEmojiPrefix ? title.substring(firstSpace + 1) : title;
    return Row(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: const Color(0xFFFFF3B0),
            borderRadius: BorderRadius.circular(10),
            boxShadow: const [
              BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
            ],
          ),
          alignment: Alignment.center,
          child: Text(emoji, style: const TextStyle(fontSize: 16)),
        ),
        const SizedBox(width: 10),
        Text(
          text,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.deepPurple.shade500,
          ),
        ),
      ],
    );
  }

  bool _looksLikeEmojiPrefix(String token) {
    final value = token.trim();
    if (value.isEmpty) return false;
    return value.runes.any(
      (rune) =>
          rune >= 0x1F000 || // çoğu modern emoji bloğu
          (rune >= 0x2600 && rune <= 0x27BF), // misc symbols / dingbats
    );
  }
}

/// Sekme/butonlarda hafif basma-kalkma efekti.
class _PressScaleButton extends StatefulWidget {
  final VoidCallback onTap;
  final Widget child;

  const _PressScaleButton({required this.onTap, required this.child});

  @override
  State<_PressScaleButton> createState() => _PressScaleButtonState();
}

class _PressScaleButtonState extends State<_PressScaleButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 110),
        scale: _pressed ? 0.96 : 1.0,
        child: widget.child,
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
        final showStar = value >= 80;
        return Column(
          children: [
            AnimatedCounter(
              value: value,
              prefix: '%',
              duration: const Duration(milliseconds: 600),
              style: TextStyle(fontSize: 10, color: Colors.deepPurple.shade300),
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
            if (showStar)
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0.7, end: 1.0),
                duration: const Duration(milliseconds: 700),
                curve: Curves.easeInOutBack,
                builder: (context, scale, child) {
                  return Transform.scale(scale: scale, child: child);
                },
                child: const Text('🌟', style: TextStyle(fontSize: 11)),
              )
            else
              const SizedBox(height: 11),
            const SizedBox(height: 4),
            Text(
              dayLabel,
              style: TextStyle(fontSize: 10, color: Colors.deepPurple.shade300),
            ),
          ],
        );
      },
    );
  }
}

class _ReportHistoryEntry {
  final DateTime createdAt;
  final PdfReportData data;

  const _ReportHistoryEntry({
    required this.createdAt,
    required this.data,
  });

  Map<String, dynamic> toMap() => {
        'createdAt': createdAt.toIso8601String(),
        'data': {
          'childName': data.childName,
          'totalScore': data.totalScore,
          'totalQuestions': data.totalQuestions,
          'correctAnswers': data.correctAnswers,
          'accuracy': data.accuracy,
          'earnedBadgesCount': data.earnedBadgesCount,
          'weeklyValues': data.weeklyValues,
          'badgeNames': data.badgeNames,
          'recommendations': data.recommendations,
        },
      };

  factory _ReportHistoryEntry.fromMap(Map<String, dynamic> map, {String? languageCode}) {
    final rawData = (map['data'] as Map?) ?? const {};
    final m = <String, dynamic>{for (final e in rawData.entries) e.key.toString(): e.value};
    final cn = m['childName']?.toString().trim();
    return _ReportHistoryEntry(
      createdAt: DateTime.tryParse(map['createdAt']?.toString() ?? '') ?? DateTime.now(),
      data: PdfReportData(
        childName: (cn != null && cn.isNotEmpty)
            ? cn
            : ParentPanelL10n.of(languageCode, 'pp_player_default'),
        totalScore: (m['totalScore'] as num?)?.toInt() ?? 0,
        totalQuestions: (m['totalQuestions'] as num?)?.toInt() ?? 0,
        correctAnswers: (m['correctAnswers'] as num?)?.toInt() ?? 0,
        accuracy: (m['accuracy'] as num?)?.toInt() ?? 0,
        earnedBadgesCount: (m['earnedBadgesCount'] as num?)?.toInt() ?? 0,
        weeklyValues: (m['weeklyValues'] as List<dynamic>? ?? const [])
            .map((e) => (e as num?)?.toInt() ?? 0)
            .toList(),
        badgeNames: (m['badgeNames'] as List<dynamic>? ?? const []).map((e) => e.toString()).toList(),
        recommendations:
            (m['recommendations'] as List<dynamic>? ?? const []).map((e) => e.toString()).toList(),
      ),
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
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                color: Colors.white.withValues(alpha: 0.85),
              ),
            ),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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

