import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/badge_service.dart';
import '../models/badge.dart';
import '../localization/app_localizations.dart';

class BadgesScreen extends StatefulWidget {
  final VoidCallback onBack;

  const BadgesScreen({
    super.key,
    required this.onBack,
  });

  @override
  State<BadgesScreen> createState() => _BadgesScreenState();
}

class _BadgesScreenState extends State<BadgesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  BadgeCategory? _selectedCategory;

  final List<BadgeCategory> _categories = [
    BadgeCategory.gameplay,
    BadgeCategory.streak,
    BadgeCategory.speed,
    BadgeCategory.accuracy,
    BadgeCategory.social,
    BadgeCategory.loyalty,
    BadgeCategory.mastery,
    BadgeCategory.special,
  ];

  final Map<BadgeCategory, String> _categoryEmojis = {
    BadgeCategory.gameplay: '🎮',
    BadgeCategory.streak: '🔥',
    BadgeCategory.speed: '⚡',
    BadgeCategory.accuracy: '🎯',
    BadgeCategory.social: '👥',
    BadgeCategory.loyalty: '💎',
    BadgeCategory.mastery: '🏆',
    BadgeCategory.special: '✨',
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final badgeService = Provider.of<BadgeService>(context);
    final locale = Localizations.localeOf(context);
    final localizations = AppLocalizations(locale);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF667eea), Color(0xFF764ba2)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ÜST BAR
              _buildTopBar(localizations, badgeService),

              const SizedBox(height: 8),

              // İSTATİSTİK KARTI
              _buildStatsCard(badgeService, localizations),

              const SizedBox(height: 16),

              // TAB BAR
              _buildTabBar(localizations),

              // İÇERİK - Expanded ile esnek yükseklik
              Expanded(
                child: Container(
                  // Alt kısımda güvenli boşluk bırak
                  margin: EdgeInsets.only(
                    bottom: MediaQuery.of(context).padding.bottom + 8,
                  ),
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildAllBadgesTab(badgeService, localizations),
                      _buildEarnedBadgesTab(badgeService, localizations),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(AppLocalizations localizations, BadgeService badgeService) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // GERİ BUTONU
          GestureDetector(
            onTap: widget.onBack,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              child: const Center(
                child: Icon(
                  Icons.arrow_back_ios_new,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ),
          // BAŞLIK
          Column(
            children: [
              Text(
                localizations.get('badges_title'),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                '${badgeService.earnedBadgesCount}/${badgeService.totalBadgesCount}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
            ],
          ),
          // BOŞLUK
          const SizedBox(width: 44),
        ],
      ),
    );
  }

  Widget _buildStatsCard(BadgeService badgeService, AppLocalizations localizations) {
    final stats = badgeService.userStats;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('🎮', '${stats?.totalGamesPlayed ?? 0}', localizations.get('total_games')),
          _buildStatItem('✅', '${stats?.totalCorrectAnswers ?? 0}', localizations.get('correct')),
          _buildStatItem('🔥', '${stats?.bestStreak ?? 0}', localizations.get('best_streak')),
          _buildStatItem('⭐', '${stats?.totalScore ?? 0}', localizations.get('score')),
        ],
      ),
    );
  }

  Widget _buildStatItem(String emoji, String value, String label) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.white.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildTabBar(AppLocalizations localizations) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        indicatorPadding: const EdgeInsets.all(4),
        labelColor: const Color(0xFF667eea),
        unselectedLabelColor: Colors.white,
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
        tabs: [
          Tab(text: localizations.get('all_badges')),
          Tab(text: localizations.get('earned_badges')),
        ],
      ),
    );
  }

  // ==================== TÜM ROZETLER ====================

  Widget _buildAllBadgesTab(BadgeService badgeService, AppLocalizations localizations) {
    final allBadges = BadgeService.allBadges;
    final uniqueBadges = allBadges.toSet().toList();

    final displayBadges = _selectedCategory == null
        ? uniqueBadges
        : badgeService.getBadgesByCategory(_selectedCategory!).toSet().toList();

    return Column(
      children: [
        // KATEGORİ FİLTRESİ
        _buildCategoryFilter(localizations),

        const SizedBox(height: 8),

        // ROZETLER - Expanded ile esnek yükseklik
        Expanded(
          child: _buildBadgeGrid(
            badgeService,
            localizations,
            displayBadges,
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryFilter(AppLocalizations localizations) {
    return Container(
      height: 44,
      margin: const EdgeInsets.only(top: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          // TÜMÜ
          _buildCategoryChip(null, localizations.get('all')),
          ..._categories.map((cat) => _buildCategoryChip(
            cat,
            '${_categoryEmojis[cat] ?? ''} ${_getCategoryName(cat, localizations)}',
          )),
        ],
      ),
    );
  }

  String _getCategoryName(BadgeCategory category, AppLocalizations localizations) {
    switch (category) {
      case BadgeCategory.gameplay:
        return localizations.get('badge_cat_gameplay');
      case BadgeCategory.streak:
        return localizations.get('badge_cat_streak');
      case BadgeCategory.speed:
        return localizations.get('badge_cat_speed');
      case BadgeCategory.accuracy:
        return localizations.get('badge_cat_accuracy');
      case BadgeCategory.social:
        return localizations.get('badge_cat_social');
      case BadgeCategory.loyalty:
        return localizations.get('badge_cat_loyalty');
      case BadgeCategory.mastery:
        return localizations.get('badge_cat_mastery');
      case BadgeCategory.special:
        return localizations.get('badge_cat_special');
    }
  }

  Widget _buildCategoryChip(BadgeCategory? category, String label) {
    final isSelected = _selectedCategory == category;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategory = category;
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.transparent : Colors.white.withOpacity(0.3),
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? const Color(0xFF667eea) : Colors.white,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBadgeGrid(BadgeService badgeService, AppLocalizations localizations, List<BadgeDefinition> badges) {
    if (badges.isEmpty) {
      return Center(
        child: Container(
          margin: const EdgeInsets.all(32),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🏆', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 12),
              Text(
                localizations.get('no_badges_in_category'),
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF2d3436),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return GridView.builder(
      // DÜZELTME: Alt boşluk eklendi
      padding: const EdgeInsets.only(
        left: 12,
        right: 12,
        top: 8,
        bottom: 24, // Alt boşluk artırıldı
      ),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 6.9, // Değiştirilmedi
        mainAxisExtent: 140, // 👈 Sabit yükseklik
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: badges.length,
      // DÜZELTME: Fizik ayarları
      physics: const AlwaysScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        return _buildBadgeCard(badges[index], badgeService, localizations);
      },
    );
  }

  Widget _buildBadgeCard(BadgeDefinition badge, BadgeService badgeService, AppLocalizations localizations) {
    final isEarned = badgeService.isBadgeEarned(badge.id);
    final progress = badgeService.getBadgeProgress(badge);
    final colors = badge.colors;

    return GestureDetector(
      onTap: () => _showBadgeDetail(badge, badgeService, localizations),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: isEarned
                          ? LinearGradient(
                        colors: [
                          Color(colors['primary'] as int),
                          Color(colors['secondary'] as int),
                        ],
                      )
                          : null,
                      color: isEarned ? null : Colors.grey.shade200,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        badge.emoji,
                        style: TextStyle(
                          fontSize: 24,
                          color: isEarned ? null : Colors.grey.shade500,
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
                      color: isEarned ? const Color(0xFF2d3436) : Colors.grey.shade500,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      3,
                          (i) => Icon(
                        Icons.star,
                        size: 10,
                        color: i < badge.starCount
                            ? (isEarned
                            ? Color(colors['primary'] as int)
                            : Colors.grey.shade400)
                            : Colors.grey.shade200,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (!isEarned)
              Positioned(
                top: 4,
                right: 4,
                child: Icon(
                  Icons.lock,
                  size: 12,
                  color: Colors.grey.shade400,
                ),
              ),
            if (isEarned)
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    size: 10,
                    color: Colors.white,
                  ),
                ),
              ),
            if (!isEarned && progress > 0)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(14),
                  ),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(colors['primary'] as int).withOpacity(0.5),
                    ),
                    minHeight: 3,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ==================== KAZANILAN ROZETLER ====================

  Widget _buildEarnedBadgesTab(BadgeService badgeService, AppLocalizations localizations) {
    final earnedBadges = badgeService.earnedBadges;

    final Map<String, EarnedBadge> uniqueEarnedBadges = {};
    for (var badge in earnedBadges) {
      if (!uniqueEarnedBadges.containsKey(badge.badgeId) ||
          badge.earnedAt.isAfter(uniqueEarnedBadges[badge.badgeId]!.earnedAt)) {
        uniqueEarnedBadges[badge.badgeId] = badge;
      }
    }

    final uniqueList = uniqueEarnedBadges.values.toList();

    if (uniqueList.isEmpty) {
      return Center(
        child: Container(
          margin: const EdgeInsets.all(32),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🎯', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 12),
              Text(
                localizations.get('no_earned_badges_title'),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2d3436),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                localizations.get('no_earned_badges_desc'),
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      // DÜZELTME: ListView için padding eklendi
      padding: const EdgeInsets.only(
        left: 16,
        right: 16,
        top: 8,
        bottom: 24, // Alt boşluk eklendi
      ),
      itemCount: uniqueList.length,
      itemBuilder: (context, index) {
        final earnedBadge = uniqueList[index];
        final badgeDef = badgeService.getBadgeDefinition(earnedBadge.badgeId);
        if (badgeDef == null) return const SizedBox();

        return _buildEarnedBadgeCard(earnedBadge, badgeDef, localizations);
      },
    );
  }

  Widget _buildEarnedBadgeCard(EarnedBadge earned, BadgeDefinition badge, AppLocalizations localizations) {
    final colors = badge.colors;
    final timeAgo = _getTimeAgo(earned.earnedAt, localizations);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(colors['primary'] as int),
                  Color(colors['secondary'] as int),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                badge.emoji,
                style: const TextStyle(fontSize: 28),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  localizations.get(badge.nameKey),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2d3436),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  localizations.get(badge.descriptionKey),
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 12, color: Colors.grey.shade400),
                    const SizedBox(width: 4),
                    Text(
                      timeAgo,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: List.generate(
                        badge.starCount,
                            (i) => Icon(
                          Icons.star,
                          size: 12,
                          color: Color(colors['primary'] as int),
                        ),
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

  void _showBadgeDetail(BadgeDefinition badge, BadgeService badgeService, AppLocalizations localizations) {
    final isEarned = badgeService.isBadgeEarned(badge.id);
    final progress = badgeService.getBadgeProgress(badge);
    final colors = badge.colors;
    final currentValue = badgeService.userStats?.getStatValue(badge.statKey) ?? 0;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: isEarned
                      ? LinearGradient(
                    colors: [
                      Color(colors['primary'] as int),
                      Color(colors['secondary'] as int),
                    ],
                  )
                      : null,
                  color: isEarned ? null : Colors.grey.shade200,
                  shape: BoxShape.circle,
                  boxShadow: isEarned
                      ? [
                    BoxShadow(
                      color: Color(colors['glow'] as int).withOpacity(0.5),
                      blurRadius: 16,
                      spreadRadius: 2,
                    ),
                  ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    badge.emoji,
                    style: const TextStyle(fontSize: 40),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                localizations.get(badge.nameKey),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2d3436),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  3,
                      (i) => Icon(
                    Icons.star,
                    size: 24,
                    color: i < badge.starCount
                        ? Color(colors['primary'] as int)
                        : Colors.grey.shade300,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                localizations.get(badge.descriptionKey),
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              if (!isEarned) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      localizations.get('progress'),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '$currentValue / ${badge.targetValue}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(colors['primary'] as int),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(colors['primary'] as int),
                    ),
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${(progress * 100).toInt()}% ${localizations.get("completed")}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, color: Colors.green.shade600, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        localizations.get('badge_earned'),
                        style: TextStyle(
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  String _getTimeAgo(DateTime dateTime, AppLocalizations localizations) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()} ${localizations.get("years_ago")}';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} ${localizations.get("months_ago")}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} ${localizations.get("days_ago")}';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ${localizations.get("hours_ago")}';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} ${localizations.get("minutes_ago")}';
    } else {
      return localizations.get("just_now");
    }
  }
}