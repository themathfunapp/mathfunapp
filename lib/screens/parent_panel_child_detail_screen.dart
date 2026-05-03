import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/badge.dart';
import '../models/topic_performance_stats.dart';
import '../services/auth_service.dart';
import '../services/badge_service.dart';
import '../localization/app_localizations.dart';
import '../widgets/animated_counter.dart';
import '../widgets/empty_state_lottie.dart';

/// Detaylı gelişim raporu - Gerçek verilerle
///
/// Not: Bu sınıfın alanları değiştirildiğinde Hot Reload (r) çalışmaz.
/// Hot Restart (R) veya uygulamayı yeniden başlatın.
class ParentPanelChildDetailScreen extends StatelessWidget {
  final String childName;
  final int totalScore;
  final int accuracy;
  final String lastActivity;
  final int earnedBadges;
  final List<int> weeklyValues;
  final VoidCallback onBack;
  final String? userId;
  final String? heroTag;

  const ParentPanelChildDetailScreen({
    super.key,
    required this.childName,
    required this.totalScore,
    required this.accuracy,
    required this.lastActivity,
    required this.earnedBadges,
    required this.weeklyValues,
    required this.onBack,
    this.userId,
    this.heroTag,
  });

  factory ParentPanelChildDetailScreen.fromRealData({
    required String childName,
    required int totalScore,
    required int accuracy,
    required String lastActivity,
    required int earnedBadges,
    required List<int> weeklyValues,
    required VoidCallback onBack,
    String? userId,
    String? heroTag,
  }) {
    return ParentPanelChildDetailScreen(
      childName: childName,
      totalScore: totalScore,
      accuracy: accuracy,
      lastActivity: lastActivity,
      earnedBadges: earnedBadges,
      weeklyValues: weeklyValues,
      onBack: onBack,
      userId: userId,
      heroTag: heroTag,
    );
  }

  Color _getSuccessColor(int percent) {
    if (percent >= 80) return const Color(0xFF4CAF50); // Yeşil: Başarılı
    if (percent >= 60) return const Color(0xFFFFC107); // Sarı: Dikkat
    return const Color(0xFFE53935); // Kırmızı: Zorlanıyor
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF2C3E50), Color(0xFF3498DB)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (heroTag != null)
                      Hero(
                        tag: heroTag!,
                        child: Material(
                          color: Colors.transparent,
                          child: _buildHeaderCard(),
                        ),
                      )
                    else
                      _buildHeaderCard(),
                    const SizedBox(height: 20),
                    _buildWeeklyProgressChart(),
                    const SizedBox(height: 20),
                    _buildTopicPerformanceAnalysis(context),
                    const SizedBox(height: 20),
                    _buildBadgeGallery(context),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          GestureDetector(
            onTap: onBack,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$childName - Detaylı Rapor',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  lastActivity,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCard() {
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
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: const Center(child: Text('🧒', style: TextStyle(fontSize: 32))),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('⭐', style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 6),
                    AnimatedCounter(
                      value: totalScore,
                      suffix: ' Puan',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.trending_up, size: 18, color: _getSuccessColor(accuracy)),
                    const SizedBox(width: 6),
                    AnimatedCounter(
                      value: accuracy,
                      prefix: 'Genel Başarı: %',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: _getSuccessColor(accuracy),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Zaman içindeki haftalık ilerleme grafiği (fl_chart)
  Widget _buildWeeklyProgressChart() {
    final days = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
    final spots = weeklyValues.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.toDouble());
    }).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.show_chart, color: Colors.blue, size: 24),
              const SizedBox(width: 8),
              const Text(
                'Zaman İçindeki İlerleme',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 25,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Colors.white.withValues(alpha: 0.1),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      interval: 25,
                      getTitlesWidget: (value, meta) => Text(
                        '${value.toInt()}%',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final i = value.toInt();
                        if (i >= 0 && i < days.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              days[i],
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: 11,
                              ),
                            ),
                          );
                        }
                        return const SizedBox();
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: 6,
                minY: 0,
                maxY: 100,
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: const Color(0xFF4CAF50),
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: const Color(0xFF4CAF50).withValues(alpha: 0.2),
                    ),
                  ),
                ],
              ),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutCubic,
            ),
          ),
        ],
      ),
    );
  }

  /// Konu bazlı performans analizi
  Widget _buildTopicPerformanceAnalysis(BuildContext context) {
    return _TopicPerformanceAnalysisWidget(userId: userId);
  }

  /// Rozet galerisi - GridView 3 sütun, BadgeService veya userId ile veri
  Widget _buildBadgeGallery(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final badgeService = Provider.of<BadgeService>(context);
    final useCurrentUser = userId == null || userId == authService.currentUser?.uid;

    if (useCurrentUser) {
      return _buildBadgeGalleryContent(
        context,
        badgeService: badgeService,
        earnedMap: _buildEarnedMap(badgeService.earnedBadges),
        showProgressInDialog: true,
      );
    }

    return FutureBuilder<Map<String, EarnedBadge>>(
      future: _fetchEarnedBadgesForUser(userId!),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
            ),
            child: const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          );
        }
        return _buildBadgeGalleryContent(
          context,
          badgeService: badgeService,
          earnedMap: snapshot.data!,
          showProgressInDialog: false,
        );
      },
    );
  }

  Map<String, EarnedBadge> _buildEarnedMap(List<EarnedBadge> list) {
    final map = <String, EarnedBadge>{};
    for (final e in list) {
      if (!map.containsKey(e.badgeId) || e.earnedAt.isAfter(map[e.badgeId]!.earnedAt)) {
        map[e.badgeId] = e;
      }
    }
    return map;
  }

  Future<Map<String, EarnedBadge>> _fetchEarnedBadgesForUser(String uid) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('badges')
        .orderBy('earnedAt', descending: true)
        .get();
    final map = <String, EarnedBadge>{};
    for (final doc in snapshot.docs) {
      final e = EarnedBadge.fromMap(doc.data(), doc.id);
      if (!map.containsKey(e.badgeId) || e.earnedAt.isAfter(map[e.badgeId]!.earnedAt)) {
        map[e.badgeId] = e;
      }
    }
    return map;
  }

  Widget _buildBadgeGalleryContent(
    BuildContext context, {
    required BadgeService badgeService,
    required Map<String, EarnedBadge> earnedMap,
    required bool showProgressInDialog,
  }) {
    final locale = Localizations.localeOf(context);
    final localizations = AppLocalizations(locale);
    final allBadges = BadgeService.allBadges;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🏆', style: TextStyle(fontSize: 24)),
              const SizedBox(width: 8),
              const Text(
                'Rozet Galerisi',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '$earnedBadges / ${allBadges.length} rozet kazanıldı',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 480,
            child: GridView.builder(
              padding: EdgeInsets.zero,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 0.75,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: allBadges.length,
              itemBuilder: (context, index) {
                final badge = allBadges[index];
                final earned = earnedMap[badge.id];
                return _buildBadgeGalleryItem(
                  context,
                  badge,
                  earned,
                  badgeService,
                  localizations,
                  index,
                  showProgressInDialog: showProgressInDialog,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadgeGalleryItem(
    BuildContext context,
    BadgeDefinition badge,
    EarnedBadge? earned,
    BadgeService badgeService,
    AppLocalizations localizations,
    int index, {
    bool showProgressInDialog = true,
  }) {
    final isEarned = earned != null;
    final colors = badge.colors;

    return TweenAnimationBuilder<double>(
      key: ValueKey('${badge.id}_$index'),
      tween: Tween(begin: 0.85, end: 1.0),
      duration: Duration(milliseconds: 300 + (index % 9) * 30),
      curve: Curves.easeOutBack,
      builder: (context, value, child) => Transform.scale(
        scale: value,
        alignment: Alignment.center,
        child: child,
      ),
      child: GestureDetector(
        onTap: () => _showBadgeDetailDialog(
          context,
          badge,
          earned,
          badgeService,
          localizations,
          showProgressInDialog: showProgressInDialog,
        ),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isEarned
                ? Color(colors['primary'] as int).withValues(alpha: 0.25)
                : Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isEarned
                  ? Color(colors['secondary'] as int).withValues(alpha: 0.6)
                  : Colors.white.withValues(alpha: 0.15),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: isEarned
                      ? LinearGradient(
                          colors: [
                            Color(colors['primary'] as int),
                            Color(colors['secondary'] as int),
                          ],
                        )
                      : null,
                  color: isEarned ? null : Colors.white.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    badge.emoji,
                    style: TextStyle(
                      fontSize: 22,
                      color: isEarned ? null : Colors.white.withValues(alpha: 0.4),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                localizations.get(badge.nameKey),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isEarned
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.5),
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (earned != null) ...[
                const SizedBox(height: 4),
                Text(
                  DateFormat('d.M.yyyy').format(earned.earnedAt),
                  style: TextStyle(
                    fontSize: 9,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
              ] else
                Icon(
                  Icons.lock_outline,
                  size: 12,
                  color: Colors.white.withValues(alpha: 0.4),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showBadgeDetailDialog(
    BuildContext context,
    BadgeDefinition badge,
    EarnedBadge? earned,
    BadgeService badgeService,
    AppLocalizations localizations, {
    bool showProgressInDialog = true,
  }) {
    final isEarned = earned != null;
    final colors = badge.colors;
    final currentValue = badgeService.userStats?.getStatValue(badge.statKey) ?? 0;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF2C3E50),
                const Color(0xFF3498DB),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    gradient: isEarned
                        ? LinearGradient(
                            colors: [
                              Color(colors['primary'] as int),
                              Color(colors['secondary'] as int),
                            ],
                          )
                        : null,
                    color: isEarned ? null : Colors.white.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    boxShadow: isEarned
                        ? [
                            BoxShadow(
                              color: Color(colors['glow'] as int),
                              blurRadius: 12,
                              spreadRadius: 1,
                            ),
                          ]
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      badge.emoji,
                      style: TextStyle(
                        fontSize: 36,
                        color: isEarned ? null : Colors.white.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  localizations.get(badge.nameKey),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    5,
                    (i) => Icon(
                      Icons.star,
                      size: 18,
                      color: i < badge.starCount
                          ? Color(colors['primary'] as int)
                          : Colors.white.withValues(alpha: 0.3),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  localizations.get(badge.descriptionKey),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        localizations.get('badge_how_title'),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        localizations.get(badge.howToEarnKey),
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.35,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ),
                if (earned != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Kazanıldı: ${DateFormat('d MMM yyyy').format(earned.earnedAt)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.95),
                      ),
                    ),
                  ),
                ] else if (showProgressInDialog) ...[
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        localizations.get('progress'),
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                      Text(
                        '$currentValue / ${badge.targetValue}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(colors['primary'] as int),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (currentValue / badge.targetValue).clamp(0.0, 1.0),
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(colors['primary'] as int),
                      ),
                      minHeight: 6,
                    ),
                  ),
                ] else ...[
                  const SizedBox(height: 12),
                  Text(
                    'Henüz kazanılmadı',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    localizations.get('close'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
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
}

/// Konu bazlı performans analizi widget'ı
class _TopicPerformanceAnalysisWidget extends StatefulWidget {
  final String? userId;

  const _TopicPerformanceAnalysisWidget({this.userId});

  @override
  State<_TopicPerformanceAnalysisWidget> createState() =>
      _TopicPerformanceAnalysisWidgetState();
}

class _TopicPerformanceAnalysisWidgetState
    extends State<_TopicPerformanceAnalysisWidget> {
  TopicTimeFilter _timeFilter = TopicTimeFilter.allTime;

  Color _getSuccessColor(int percent) {
    if (percent >= 80) return const Color(0xFF4CAF50);
    if (percent >= 60) return const Color(0xFFFFC107);
    return const Color(0xFFE53935);
  }

  @override
  Widget build(BuildContext context) {
    final badgeService = Provider.of<BadgeService>(context);
    return FutureBuilder<List<TopicPerformanceStats>>(
      future: badgeService.getTopicPerformanceStats(
        targetUserId: widget.userId,
        timeFilter: _timeFilter,
      ),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            ),
            child: const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          );
        }
        final stats = snapshot.data!;
        final weakTopics = stats.where((s) => s.isWeak).toList();

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.analytics, color: Colors.blue, size: 24),
                  const SizedBox(width: 8),
                  const Text(
                    'Konu Bazlı Performans',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildFilterChip('Son 7 gün', TopicTimeFilter.last7Days),
                  _buildFilterChip('Son 30 gün', TopicTimeFilter.last30Days),
                  _buildFilterChip('Tüm zamanlar', TopicTimeFilter.allTime),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 200,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: 100,
                    barTouchData: BarTouchData(enabled: false),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            final i = value.toInt();
                            if (i >= 0 && i < stats.length) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  stats[i].emoji,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.8),
                                    fontSize: 18,
                                  ),
                                ),
                              );
                            }
                            return const SizedBox();
                          },
                          reservedSize: 32,
                          interval: 1,
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 32,
                          interval: 25,
                          getTitlesWidget: (value, meta) => Text(
                            '${value.toInt()}%',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: 25,
                      getDrawingHorizontalLine: (v) => FlLine(
                        color: Colors.white.withValues(alpha: 0.1),
                        strokeWidth: 1,
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    barGroups: stats.asMap().entries.map((e) {
                      final color = _getSuccessColor(e.value.successPercent);
                      return BarChartGroupData(
                        x: e.key,
                        barRods: [
                          BarChartRodData(
                            toY: e.value.successPercent.toDouble(),
                            color: color,
                            width: 28,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                          ),
                        ],
                        showingTooltipIndicators: [0],
                      );
                    }).toList(),
                  ),
                  swapAnimationDuration: const Duration(milliseconds: 300),
                ),
              ),
              const SizedBox(height: 20),
              ...stats.map((s) => _buildTopicCard(s)),
              if (weakTopics.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.lightbulb_outline, color: Colors.amber, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Öneri: ${weakTopics.map((t) => t.topicName).join(", ")} konularında daha fazla pratik yapılması faydalı olacaktır.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withValues(alpha: 0.95),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterChip(String label, TopicTimeFilter filter) {
    final isSelected = _timeFilter == filter;
    return GestureDetector(
      onTap: () => setState(() => _timeFilter = filter),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.blue.withValues(alpha: 0.4)
              : Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? Colors.blue
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

  Widget _buildTopicCard(TopicPerformanceStats s) {
    final color = _getSuccessColor(s.successPercent);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () => _showTopicDetailPopup(s),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.4)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(s.emoji, style: const TextStyle(fontSize: 24)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.topicName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Doğru: ${s.correctCount} / Yanlış: ${s.wrongCount} • Toplam: ${s.totalQuestions} soru',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '%${s.successPercent}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                      Text(
                        s.avgTimeSeconds > 0
                            ? '${s.avgTimeSeconds.toStringAsFixed(1)} sn/soru'
                            : '-',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.visibility_outlined,
                    size: 20,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: s.successPercent / 100,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  valueColor: AlwaysStoppedAnimation(color),
                  minHeight: 6,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTopicDetailPopup(TopicPerformanceStats s) {
    final color = _getSuccessColor(s.successPercent);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2C3E50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Text(s.emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 12),
            Text(
              '${s.topicName} Detayı',
              style: const TextStyle(color: Colors.white, fontSize: 18),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _detailRow('✅ Doğru cevap', '${s.correctCount}'),
            _detailRow('❌ Yanlış cevap', '${s.wrongCount}'),
            _detailRow('📊 Toplam soru', '${s.totalQuestions}'),
            _detailRow('📈 Başarı oranı', '%${s.successPercent}'),
            _detailRow(
              '⏱️ Ort. süre',
              s.avgTimeSeconds > 0 ? '${s.avgTimeSeconds.toStringAsFixed(1)} sn/soru' : '-',
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: s.successPercent / 100,
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                valueColor: AlwaysStoppedAnimation(color),
                minHeight: 10,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Kapat', style: TextStyle(color: Colors.white70)),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70)),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
