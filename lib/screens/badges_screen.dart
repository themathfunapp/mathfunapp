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
  ];

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

              // İÇERİK
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildAllBadgesTab(badgeService, localizations),
                    _buildEarnedBadgesTab(badgeService, localizations),
                  ],
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
              width: 55,
              height: 55,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFFFD93D), Color(0xFFFF6B6B)],
                ),
                borderRadius: BorderRadius.circular(27.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '←',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text('👑', style: TextStyle(fontSize: 16)),
                  ],
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
                  fontSize: 28,
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
          // PLACEHOLDER
          const SizedBox(width: 55),
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
        Text(emoji, style: const TextStyle(fontSize: 24)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.white.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildTabBar(AppLocalizations localizations) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        indicatorPadding: const EdgeInsets.all(4),
        labelColor: const Color(0xFF667eea),
        unselectedLabelColor: Colors.white,
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
        tabs: [
          Tab(text: localizations.get('all_badges')),
          Tab(text: localizations.get('earned_badges')),
        ],
      ),
    );
  }

  // ==================== TÜM ROZETLER ====================

  Widget _buildAllBadgesTab(BadgeService badgeService, AppLocalizations localizations) {
    return Column(
      children: [
        // KATEGORİ FİLTRESİ
        _buildCategoryFilter(localizations),
        
        // ROZETLER
        Expanded(
          child: _buildBadgeGrid(
            badgeService,
            localizations,
            _selectedCategory == null
                ? BadgeService.allBadges
                : badgeService.getBadgesByCategory(_selectedCategory!),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryFilter(AppLocalizations localizations) {
    return Container(
      height: 50,
      margin: const EdgeInsets.only(top: 12),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          // TÜMÜ
          _buildCategoryChip(null, localizations.get('all'), localizations),
          ..._categories.map((cat) => _buildCategoryChip(
            cat,
            localizations.get('category_${cat.name}'),
            localizations,
          )),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(BadgeCategory? category, String label, AppLocalizations localizations) {
    final isSelected = _selectedCategory == category;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategory = category;
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBadgeGrid(BadgeService badgeService, AppLocalizations localizations, List<BadgeDefinition> badges) {
    if (badges.isEmpty) {
      return _buildEmptyState(
        emoji: '🏆',
        title: localizations.get('no_badges_in_category'),
        description: '',
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.85,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: badges.length,
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
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            if (isEarned)
              BoxShadow(
                color: Color(colors['glow'] as int),
                blurRadius: 12,
                spreadRadius: 2,
              ),
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // ANA İÇERİK
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // EMOJİ
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: isEarned
                        ? LinearGradient(
                            colors: [
                              Color(colors['primary'] as int),
                              Color(colors['secondary'] as int),
                            ],
                          )
                        : null,
                    color: isEarned ? null : Colors.grey.shade300,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      badge.emoji,
                      style: TextStyle(
                        fontSize: 24,
                        color: isEarned ? null : Colors.grey,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // İSİM
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    localizations.get(badge.nameKey),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isEarned ? const Color(0xFF2d3436) : Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 4),
                // YILDIZLAR
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    badge.starCount,
                    (i) => Icon(
                      Icons.star,
                      size: 10,
                      color: isEarned
                          ? Color(colors['primary'] as int)
                          : Colors.grey.shade400,
                    ),
                  ),
                ),
              ],
            ),
            // İLERLEME GÖSTERGE
            if (!isEarned)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(16),
                  ),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(colors['primary'] as int).withOpacity(0.5),
                    ),
                    minHeight: 4,
                  ),
                ),
              ),
            // KİLİT İKONU
            if (!isEarned)
              Positioned(
                top: 4,
                right: 4,
                child: Icon(
                  Icons.lock,
                  size: 14,
                  color: Colors.grey.shade400,
                ),
              ),
            // CHECK İKONU
            if (isEarned)
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    size: 12,
                    color: Colors.white,
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

    if (earnedBadges.isEmpty) {
      return _buildEmptyState(
        emoji: '🎯',
        title: localizations.get('no_earned_badges_title'),
        description: localizations.get('no_earned_badges_desc'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: earnedBadges.length,
      itemBuilder: (context, index) {
        final earnedBadge = earnedBadges[index];
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Color(colors['glow'] as int),
            blurRadius: 8,
            spreadRadius: 1,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // EMOJİ
          Container(
            width: 60,
            height: 60,
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
          const SizedBox(width: 16),
          // BİLGİLER
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  localizations.get(badge.nameKey),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2d3436),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  localizations.get(badge.descriptionKey),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 14, color: Colors.grey[400]),
                    const SizedBox(width: 4),
                    Text(
                      timeAgo,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[500],
                      ),
                    ),
                    const Spacer(),
                    // YILDIZLAR
                    ...List.generate(
                      badge.starCount,
                      (i) => Icon(
                        Icons.star,
                        size: 14,
                        color: Color(colors['primary'] as int),
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

  // ==================== ROZET DETAY ====================

  void _showBadgeDetail(BadgeDefinition badge, BadgeService badgeService, AppLocalizations localizations) {
    final isEarned = badgeService.isBadgeEarned(badge.id);
    final progress = badgeService.getBadgeProgress(badge);
    final colors = badge.colors;
    final currentValue = badgeService.userStats?.getStatValue(badge.statKey) ?? 0;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // HANDLE
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            // EMOJİ
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
                color: isEarned ? null : Colors.grey.shade300,
                shape: BoxShape.circle,
                boxShadow: isEarned
                    ? [
                        BoxShadow(
                          color: Color(colors['glow'] as int),
                          blurRadius: 20,
                          spreadRadius: 5,
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
            // İSİM
            Text(
              localizations.get(badge.nameKey),
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2d3436),
              ),
            ),
            const SizedBox(height: 8),
            // YILDIZLAR
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                5,
                (i) => Icon(
                  Icons.star,
                  size: 20,
                  color: i < badge.starCount
                      ? Color(colors['primary'] as int)
                      : Colors.grey.shade300,
                ),
              ),
            ),
            const SizedBox(height: 16),
            // AÇIKLAMA
            Text(
              localizations.get(badge.descriptionKey),
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            // İLERLEME
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
                  minHeight: 10,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${(progress * 100).toInt()}% ${localizations.get("completed")}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      localizations.get('badge_earned'),
                      style: TextStyle(
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.bold,
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
    );
  }

  // ==================== YARDIMCI ====================

  Widget _buildEmptyState({
    required String emoji,
    required String title,
    required String description,
  }) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(32),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2d3436),
              ),
              textAlign: TextAlign.center,
            ),
            if (description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                description,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
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

