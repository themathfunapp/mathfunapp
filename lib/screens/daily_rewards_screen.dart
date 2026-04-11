import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/daily_reward_service.dart';
import '../services/auth_service.dart';
import '../services/game_mechanics_service.dart';
import '../models/daily_reward.dart';
import '../localization/app_localizations.dart';
import 'welcome_screen.dart';
import 'app_screen_wrappers.dart';

class DailyRewardsScreen extends StatefulWidget {
  final VoidCallback onBack;

  const DailyRewardsScreen({
    super.key,
    required this.onBack,
  });

  @override
  State<DailyRewardsScreen> createState() => _DailyRewardsScreenState();
}

class _DailyRewardsScreenState extends State<DailyRewardsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  
  // Şans çarkı için
  bool _isSpinning = false;
  double _wheelRotation = 0;
  int _selectedSliceIndex = 0;
  
  // Sürpriz kutu için
  bool _isOpeningBox = false;

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

  /// Misafir için hesap oluşturma / giriş seçenekleri (MaterialApp'te `/welcome` rotası yok).
  Future<void> _navigateToCreateAccount() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    try {
      await authService.signOut();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => WelcomeScreen(
            initialPageIsLoginOptions: true,
            onSignInComplete: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const HomeScreenWrapper()),
              );
            },
            onSkip: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const HomeScreenWrapper()),
              );
            },
          ),
        ),
        (route) => false,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Bir hata oluştu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final rewardService = Provider.of<DailyRewardService>(context);
    final authService = Provider.of<AuthService>(context);
    final locale = Localizations.localeOf(context);
    final localizations = AppLocalizations(locale);
    final isGuest = authService.isGuest;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFF6B6B), Color(0xFFFFE66D)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ÜST BAR
              _buildTopBar(localizations, rewardService),
              
              const SizedBox(height: 8),

              // PARA BİRİMLERİ
              _buildCurrencyBar(rewardService, localizations),

              const SizedBox(height: 16),

              // TAB BAR
              if (!isGuest) _buildTabBar(localizations),

              // İÇERİK
              Expanded(
                child: isGuest
                    ? _buildGuestContent(localizations)
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          _buildStreakTab(rewardService, localizations),
                          _buildWheelTab(rewardService, localizations),
                          _buildTasksTab(rewardService, localizations),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Günlük ödül sonrası jeton/elmas/ipucu/güçlendiricileri oyun envanterine yazar.
  Future<void> _syncMechanicsFromDaily(DailyRewardService rewardService) async {
    if (rewardService.isGuest || rewardService.userRewards == null) return;
    final mechanics = Provider.of<GameMechanicsService>(context, listen: false);
    await mechanics.syncInventoryFromDailyRewards(rewardService.userRewards!);
  }

  Widget _buildTopBar(AppLocalizations localizations, DailyRewardService rewardService) {
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
                    Text('←', style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
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
                localizations.get('daily_rewards_title'),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Row(
                children: [
                  const Text('🔥', style: TextStyle(fontSize: 14)),
                  const SizedBox(width: 4),
                  Text(
                    '${rewardService.loginStreak} ${localizations.get("day_streak")}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.9),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
          // PLACEHOLDER
          const SizedBox(width: 55),
        ],
      ),
    );
  }

  Widget _buildCurrencyBar(DailyRewardService rewardService, AppLocalizations localizations) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildCurrencyItem('🪙', '${rewardService.coins}', localizations.get('gold')),
          Container(width: 1, height: 30, color: Colors.white.withOpacity(0.3)),
          _buildCurrencyItem('💎', '${rewardService.diamonds}', localizations.get('diamonds')),
          Container(width: 1, height: 30, color: Colors.white.withOpacity(0.3)),
          _buildCurrencyItem('💡', '${rewardService.userRewards?.hintCount ?? 0}', localizations.get('hints')),
        ],
      ),
    );
  }

  Widget _buildCurrencyItem(String emoji, String value, String label) {
    return Column(
      children: [
        Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 6),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.white.withOpacity(0.8),
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
        labelColor: const Color(0xFFFF6B6B),
        unselectedLabelColor: Colors.white,
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        tabs: [
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('🔥', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 4),
                Text(localizations.get('streak_tab')),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('🎡', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 4),
                Text(localizations.get('wheel_tab')),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('📋', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 4),
                Text(localizations.get('tasks_tab')),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuestContent(AppLocalizations localizations) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(32),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🎁', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            Text(
              localizations.get('rewards_locked_title'),
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2d3436),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              localizations.get('rewards_locked_desc'),
              style: TextStyle(fontSize: 14, color: Colors.grey[600], height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _navigateToCreateAccount,
              icon: const Icon(Icons.person_add),
              label: Text(localizations.get('create_account')),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6B6B),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== STREAK TAB ====================

  Widget _buildStreakTab(DailyRewardService rewardService, AppLocalizations localizations) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // GÜNLÜK ÖDÜL KARTI
          _buildDailyRewardCard(rewardService, localizations),
          
          const SizedBox(height: 20),
          
          // STREAK TAKVİMİ
          _buildStreakCalendar(rewardService, localizations),
          
          const SizedBox(height: 20),
          
          // SÜRPRİZ KUTU
          _buildSurpriseBox(rewardService, localizations),
        ],
      ),
    );
  }

  Widget _buildDailyRewardCard(DailyRewardService rewardService, AppLocalizations localizations) {
    final canClaim = rewardService.canClaimStreakReward();
    final currentReward = rewardService.getCurrentStreakReward();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: canClaim
              ? [const Color(0xFF667eea), const Color(0xFF764ba2)]
              : [Colors.grey.shade400, Colors.grey.shade500],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: (canClaim ? const Color(0xFF667eea) : Colors.grey).withOpacity(0.4),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    localizations.get('daily_bonus'),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    '${localizations.get("day")} ${rewardService.loginStreak}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
              if (currentReward.isSpecial)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.amber,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '⭐ ${localizations.get("special")}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          // ÖDÜLLER
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: currentReward.rewards.map((reward) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(reward.emoji, style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 8),
                    Text(
                      '+${reward.amount}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          // CLAIM BUTONU
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: canClaim
                  ? () async {
                      final rewards = await rewardService.claimStreakReward();
                      if (rewards.isNotEmpty && mounted) {
                        await _syncMechanicsFromDaily(rewardService);
                        _showRewardDialog(rewards, localizations);
                      }
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: canClaim ? const Color(0xFF667eea) : Colors.grey,
                disabledBackgroundColor: Colors.white.withOpacity(0.5),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(
                canClaim
                    ? localizations.get('claim_reward')
                    : localizations.get('reward_claimed'),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStreakCalendar(DailyRewardService rewardService, AppLocalizations localizations) {
    final currentDay = ((rewardService.loginStreak - 1) % 7) + 1;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            localizations.get('weekly_rewards'),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2d3436),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(7, (index) {
              final day = index + 1;
              final isCompleted = day < currentDay;
              final isCurrent = day == currentDay;
              final reward = DailyRewardService.streakRewards[index];

              return _buildDayCircle(
                day: day,
                isCompleted: isCompleted,
                isCurrent: isCurrent,
                isSpecial: reward.isSpecial,
                reward: reward,
                localizations: localizations,
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildDayCircle({
    required int day,
    required bool isCompleted,
    required bool isCurrent,
    required bool isSpecial,
    required StreakReward reward,
    required AppLocalizations localizations,
  }) {
    return GestureDetector(
      onTap: () => _showDayRewardInfo(day, reward, localizations),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: isCompleted || isCurrent
                  ? LinearGradient(
                      colors: isSpecial
                          ? [Colors.amber, Colors.orange]
                          : [const Color(0xFF667eea), const Color(0xFF764ba2)],
                    )
                  : null,
              color: isCompleted || isCurrent ? null : Colors.grey.shade200,
              shape: BoxShape.circle,
              border: isCurrent
                  ? Border.all(color: Colors.amber, width: 3)
                  : null,
            ),
            child: Center(
              child: isCompleted
                  ? const Icon(Icons.check, color: Colors.white, size: 20)
                  : Text(
                      reward.rewards.first.emoji,
                      style: TextStyle(
                        fontSize: isCompleted || isCurrent ? 18 : 16,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${localizations.get("day_short")}$day',
            style: TextStyle(
              fontSize: 10,
              fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
              color: isCurrent ? const Color(0xFF667eea) : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSurpriseBox(DailyRewardService rewardService, AppLocalizations localizations) {
    final isOpened = rewardService.dailyBoxOpened;

    return GestureDetector(
      onTap: isOpened || _isOpeningBox
          ? null
          : () async {
              setState(() => _isOpeningBox = true);
              
              await Future.delayed(const Duration(milliseconds: 500));
              
              final rewards = await rewardService.openDailyBox();
              
              setState(() => _isOpeningBox = false);
              
              if (rewards.isNotEmpty && mounted) {
                await _syncMechanicsFromDaily(rewardService);
                _showRewardDialog(rewards, localizations);
              }
            },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isOpened
                ? [Colors.grey.shade300, Colors.grey.shade400]
                : [const Color(0xFFf093fb), const Color(0xFFf5576c)],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: (isOpened ? Colors.grey : const Color(0xFFf5576c)).withOpacity(0.4),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            // KUTU ANİMASYONU
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: _isOpeningBox ? 1 : 0),
              duration: const Duration(milliseconds: 500),
              builder: (context, value, child) {
                return Transform.scale(
                  scale: 1 + (value * 0.2),
                  child: Transform.rotate(
                    angle: value * 0.3,
                    child: Text(
                      isOpened ? '📭' : '🎁',
                      style: const TextStyle(fontSize: 50),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    localizations.get('surprise_box'),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isOpened
                        ? localizations.get('box_opened_today')
                        : localizations.get('tap_to_open'),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
            if (!isOpened)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  localizations.get('open'),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFf5576c),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ==================== WHEEL TAB ====================

  Widget _buildWheelTab(DailyRewardService rewardService, AppLocalizations localizations) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // ÇARK
          _buildSpinWheel(rewardService, localizations),
        ],
      ),
    );
  }

  Widget _buildSpinWheel(DailyRewardService rewardService, AppLocalizations localizations) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            localizations.get('spin_wheel_title'),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2d3436),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${rewardService.freeSpinsToday} ${localizations.get("free_spins_left")}',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 20),
          // ÇARK — ödüller dilimlerin üzerinde
          SizedBox(
            width: 300,
            height: 300,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: _wheelRotation),
                  duration: Duration(milliseconds: _isSpinning ? 4000 : 0),
                  curve: Curves.easeOutCubic,
                  builder: (context, rotation, child) {
                    return Transform.rotate(
                      angle: rotation,
                      child: CustomPaint(
                        size: const Size(280, 280),
                        painter: DailyWheelPainter(
                          slices: DailyRewardService.wheelSlices,
                          colorForIndex: _getWheelColor,
                        ),
                      ),
                    );
                  },
                ),
                Positioned(
                  top: 4,
                  child: CustomPaint(
                    size: const Size(28, 22),
                    painter: _WheelPointerPainter(),
                  ),
                ),
                GestureDetector(
                  onTap: rewardService.canSpin && !_isSpinning
                      ? () => _spinWheel(rewardService, localizations)
                      : null,
                  child: Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: rewardService.canSpin && !_isSpinning
                            ? [const Color(0xFFFF8C42), const Color(0xFFFF6B35)]
                            : [Colors.grey.shade500, Colors.grey.shade600],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: (rewardService.canSpin && !_isSpinning
                                  ? const Color(0xFFFF8C42)
                                  : Colors.black)
                              .withOpacity(0.35),
                          blurRadius: 12,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Center(
                      child: _isSpinning
                          ? const Text('🎰', style: TextStyle(fontSize: 30))
                          : Text(
                              localizations.get('spin_wheel_button'),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
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

  Future<void> _spinWheel(DailyRewardService rewardService, AppLocalizations localizations) async {
    if (_isSpinning) return;

    setState(() {
      _isSpinning = true;
      _selectedSliceIndex = rewardService.getRandomWheelIndex();
      
      // Rastgele dönüş + seçilen dilime gelecek şekilde
      final sliceAngle = (2 * pi) / DailyRewardService.wheelSlices.length;
      final targetAngle = (2 * pi) - (_selectedSliceIndex * sliceAngle) - (sliceAngle / 2);
      _wheelRotation = (5 * 2 * pi) + targetAngle; // 5 tam tur + hedef açı
    });

    await Future.delayed(const Duration(milliseconds: 4200));

    final reward = await rewardService.spinWheel(sliceIndex: _selectedSliceIndex);

    setState(() => _isSpinning = false);

    if (reward != null && mounted) {
      await _syncMechanicsFromDaily(rewardService);
      _showRewardDialog([reward], localizations);
    }
  }

  Color _getWheelColor(int index) {
    final colors = [
      const Color(0xFFFF6B6B),
      const Color(0xFF4ECDC4),
      const Color(0xFFFFE66D),
      const Color(0xFF95E1D3),
      const Color(0xFFF38181),
      const Color(0xFFAA96DA),
      const Color(0xFFFCBF49),
      const Color(0xFF00BBF0),
    ];
    return colors[index % colors.length];
  }

  // ==================== TASKS TAB ====================

  Widget _buildTasksTab(DailyRewardService rewardService, AppLocalizations localizations) {
    final completed = rewardService.getCompletedTasksCount();
    final total = DailyRewardService.dailyTasks.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // PROGRESS BAR
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      localizations.get('daily_tasks'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '$completed/$total',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: total > 0 ? completed / total : 0,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: const AlwaysStoppedAnimation(Color(0xFF4ECDC4)),
                    minHeight: 8,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // GÖREV LİSTESİ
          ...DailyRewardService.dailyTasks.map((task) {
            final progress = rewardService.taskProgress[task.id];
            return _buildTaskCard(task, progress, rewardService, localizations);
          }),
        ],
      ),
    );
  }

  Widget _buildTaskCard(
    DailyTask task,
    UserTaskProgress? progress,
    DailyRewardService rewardService,
    AppLocalizations localizations,
  ) {
    final currentValue = progress?.currentValue ?? 0;
    final isCompleted = progress?.isCompleted ?? false;
    final isClaimed = progress?.isRewardClaimed ?? false;
    final progressPercent = currentValue / task.targetValue;

    Color difficultyColor;
    switch (task.difficulty) {
      case TaskDifficulty.easy:
        difficultyColor = Colors.green;
        break;
      case TaskDifficulty.medium:
        difficultyColor = Colors.orange;
        break;
      case TaskDifficulty.hard:
        difficultyColor = Colors.red;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isClaimed
            ? Border.all(color: Colors.green.withOpacity(0.5), width: 2)
            : null,
      ),
      child: Column(
        children: [
          Row(
            children: [
              // EMOJİ
              Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  color: difficultyColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(task.emoji, style: const TextStyle(fontSize: 22)),
                ),
              ),
              const SizedBox(width: 12),
              // BİLGİ
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      localizations.get(task.titleKey),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      localizations.get(task.descriptionKey),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              // ÖDÜLLER / BUTON
              if (isClaimed)
                const Icon(Icons.check_circle, color: Colors.green, size: 28)
              else if (isCompleted)
                ElevatedButton(
                  onPressed: () async {
                    final rewards = await rewardService.claimTaskReward(task.id);
                    if (rewards.isNotEmpty && mounted) {
                      await _syncMechanicsFromDaily(rewardService);
                      _showRewardDialog(rewards, localizations);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    localizations.get('claim'),
                    style: const TextStyle(fontSize: 12, color: Colors.white),
                  ),
                )
              else
                Column(
                  children: task.rewards.map((r) {
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(r.emoji, style: const TextStyle(fontSize: 12)),
                        Text(
                          '+${r.amount}',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ],
                    );
                  }).toList(),
                ),
            ],
          ),
          if (!isCompleted) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progressPercent.clamp(0.0, 1.0),
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation(difficultyColor),
                      minHeight: 6,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '$currentValue/${task.targetValue}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ==================== DİALOGLAR ====================

  void _showRewardDialog(List<RewardItem> rewards, AppLocalizations localizations) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF667eea), Color(0xFF764ba2)],
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🎉', style: TextStyle(fontSize: 50)),
              const SizedBox(height: 16),
              Text(
                localizations.get('rewards_received'),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: rewards.map((reward) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(reward.emoji, style: const TextStyle(fontSize: 24)),
                        const SizedBox(width: 8),
                        Text(
                          '+${reward.amount}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF667eea),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    localizations.get('awesome'),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDayRewardInfo(int day, StreakReward reward, AppLocalizations localizations) {
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
            Text(
              '${localizations.get("day")} $day ${localizations.get("rewards")}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (reward.isSpecial)
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amber.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '⭐ ${localizations.get("special_day")}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber.shade800,
                  ),
                ),
              ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: reward.rewards.map((r) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(r.emoji, style: const TextStyle(fontSize: 28)),
                      const SizedBox(width: 8),
                      Text(
                        '+${r.amount}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// ==================== ÇARK PAİNTER ====================

/// Günlük çark dilimleri — ödül emoji + miktar dilimin üzerinde çizilir.
class DailyWheelPainter extends CustomPainter {
  DailyWheelPainter({
    required this.slices,
    required this.colorForIndex,
  });

  final List<WheelSlice> slices;
  final Color Function(int index) colorForIndex;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2;
    final n = slices.length;
    final sliceAngle = 2 * pi / n;

    for (var i = 0; i < n; i++) {
      final path = Path()
        ..moveTo(center.dx, center.dy)
        ..arcTo(
          Rect.fromCircle(center: center, radius: radius),
          -pi / 2 + i * sliceAngle,
          sliceAngle,
          false,
        )
        ..close();

      final fill = Paint()
        ..color = colorForIndex(slices[i].colorIndex)
        ..style = PaintingStyle.fill;

      canvas.drawPath(path, fill);
    }

    final divider = Paint()
      ..color = Colors.white.withOpacity(0.92)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    for (var i = 0; i < n; i++) {
      final a = -pi / 2 + i * sliceAngle;
      final outer = center + Offset.fromDirection(a, radius);
      canvas.drawLine(center, outer, divider);
    }

    canvas.drawCircle(
      center,
      radius - 1.5,
      Paint()
        ..color = const Color(0xFFE6C200)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7,
    );

    for (var i = 0; i < n; i++) {
      final midAngle = -pi / 2 + i * sliceAngle + sliceAngle / 2;
      final labelR = radius * 0.52;
      final pos = center + Offset.fromDirection(midAngle, labelR);
      final r = slices[i].reward;

      canvas.save();
      canvas.translate(pos.dx, pos.dy);
      canvas.rotate(midAngle + pi / 2);

      final tp = TextPainter(
        text: TextSpan(
          children: [
            TextSpan(
              text: '${r.emoji}\n',
              style: TextStyle(
                fontSize: radius * 0.13,
                height: 1.05,
              ),
            ),
            TextSpan(
              text: '+${r.amount}',
              style: TextStyle(
                fontSize: radius * 0.09,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                shadows: const [
                  Shadow(
                    color: Colors.black45,
                    blurRadius: 3,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
            ),
          ],
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: radius * 0.55);

      tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant DailyWheelPainter oldDelegate) =>
      oldDelegate.slices != slices;
}

class _WheelPointerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width / 2, size.height)
      ..lineTo(0, 0)
      ..lineTo(size.width, 0)
      ..close();

    canvas.drawShadow(path, Colors.black38, 3, false);
    canvas.drawPath(path, Paint()..color = const Color(0xFFFFD700));
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = const Color(0xFFFFF8DC),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

