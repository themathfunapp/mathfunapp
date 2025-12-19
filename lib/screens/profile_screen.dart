import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/badge_service.dart';
import '../models/app_user.dart';
import '../models/badge.dart';
import '../localization/app_localizations.dart';
import 'badges_screen.dart';

class ProfileScreen extends StatefulWidget {
  final VoidCallback onBack;
  final VoidCallback onSettings;

  const ProfileScreen({
    super.key,
    required this.onBack,
    required this.onSettings,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUser;
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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // GERİ BUTONU
                    _buildBackButton(localizations),
                    // BAŞLIK
                    Text(
                      localizations.get('profile_title'),
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    // AYARLAR BUTONU
                    _buildSettingsButton(localizations),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ANA İÇERİK
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      if (user != null) ...[
                        // PROFİL KARTI
                        _buildProfileCard(user, localizations),
                        const SizedBox(height: 24),

                        // MİSAFİR BİLGİSİ
                        if (user.isGuest)
                          _buildGuestInfoCard(user, localizations),
                        const SizedBox(height: 24),

                        // İSTATİSTİKLER
                        _buildStatisticsCard(localizations),
                        const SizedBox(height: 24),

                        // BAŞARILAR
                        _buildAchievementsCard(localizations),
                        const SizedBox(height: 24),

                        // ÇIKIŞ BUTONU
                        _buildSignOutButton(authService, user, localizations),
                        const SizedBox(height: 40),
                      ] else ...[
                        // KULLANICI YOKSA
                        const SizedBox(height: 200),
                        const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        ),
                      ],
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

  Widget _buildBackButton(AppLocalizations localizations) {
    return GestureDetector(
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
              Text(
                '👑',
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsButton(AppLocalizations localizations) {
    return GestureDetector(
      onTap: widget.onSettings,
      child: Container(
        width: 55,
        height: 55,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFA726), Color(0xFFFFEB3B)],
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
          child: Text(
            '⚙️',
            style: TextStyle(fontSize: 20, color: Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileCard(AppUser user, AppLocalizations localizations) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // AVATAR
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: user.isGuest ? Colors.orange : Colors.blue,
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: user.isGuest
                        ? [Colors.orange.shade400, Colors.orange.shade700]
                        : [Colors.blue.shade400, Colors.blue.shade700],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (user.isGuest ? Colors.orange : Colors.blue)
                          .withOpacity(0.3),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    user.isGuest ? Icons.person_outline : Icons.person,
                    size: 50,
                    color: Colors.white,
                  ),
                ),
              ),
              // SEVİYE GÖSTERGESİ
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: const Color(0xFF5A4FCF),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 5,
                    ),
                  ],
                ),
                child: const Center(
                  child: Text(
                    '1',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // KULLANICI BİLGİLERİ
          Text(
            user.isGuest
                ? localizations.get('guest_user')
                : user.displayName ?? localizations.get('user'),
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2d3436),
            ),
          ),

          const SizedBox(height: 8),

          if (user.isGuest)
            Text(
              'ID: ${user.guestId}',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.orange,
                fontWeight: FontWeight.w600,
              ),
            )
          else if (user.email != null)
            Text(
              user.email!,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.blue,
                fontWeight: FontWeight.w500,
              ),
            ),

          const SizedBox(height: 8),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.language, size: 16, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                (user.selectedLanguage ?? 'tr').toUpperCase(),
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF5A4FCF),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 8),
              if (user.isGuest)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    localizations.get('guest'),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange.shade800,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 24),

          // HIZLI İSTATİSTİKLER
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatItem('🏆', '0', localizations.get('total_score')),
              _buildStatItem('🪙', '0', localizations.get('coins')),
              _buildStatItem('👤', '1', localizations.get('characters')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String emoji, String value, String label) {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: const Color(0xFFF0F4F8),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 5,
              ),
            ],
          ),
          child: Center(
            child: Text(
              emoji,
              style: const TextStyle(fontSize: 20),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2d3436),
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildGuestInfoCard(AppUser user, AppLocalizations localizations) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.orange.shade200, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.orange, size: 20),
              const SizedBox(width: 8),
              Text(
                localizations.get('guest_account_info'),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            localizations.get('guest_account_description'),
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _isLoading ? null : () => _showConvertToAccountDialog(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.person_add, size: 18),
                      const SizedBox(width: 8),
                      Text(localizations.get('create_account')),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsCard(AppLocalizations localizations) {
    final stats = [
      {'emoji': '🎯', 'label': localizations.get('total_games'), 'value': '0'},
      {'emoji': '✅', 'label': localizations.get('correct_answers'), 'value': '0%'},
      {'emoji': '🔥', 'label': localizations.get('streak_record'), 'value': '0'},
      {'emoji': '⏱️', 'label': localizations.get('play_time'), 'value': '0dk'},
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('📊', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Text(
                localizations.get('statistics'),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2d3436),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: stats.map((stat) {
              return Container(
                width: (MediaQuery.of(context).size.width - 80) / 2,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(stat['emoji']!, style: const TextStyle(fontSize: 16)),
                        const SizedBox(width: 8),
                        Text(
                          stat['value']!,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF5A4FCF),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      stat['label']!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementsCard(AppLocalizations localizations) {
    final badgeService = Provider.of<BadgeService>(context);
    final earnedBadges = badgeService.earnedBadges;
    final totalBadges = badgeService.totalBadgesCount;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🏅', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Text(
                localizations.get('badges_title'),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2d3436),
                ),
              ),
              const Spacer(),
              Text(
                '${earnedBadges.length}/$totalBadges',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          if (earnedBadges.isEmpty) ...[
            // Rozet yok
            Center(
              child: Column(
                children: [
                  const Text('🎯', style: TextStyle(fontSize: 40)),
                  const SizedBox(height: 12),
                  Text(
                    localizations.get('no_earned_badges_title'),
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    localizations.get('no_earned_badges_desc'),
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            // Kazanılan rozetler
            SizedBox(
              height: 80,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: earnedBadges.length > 5 ? 6 : earnedBadges.length,
                itemBuilder: (context, index) {
                  if (index == 5 && earnedBadges.length > 5) {
                    // Daha fazla göster butonu
                    return GestureDetector(
                      onTap: () => _openBadgesScreen(),
                      child: Container(
                        width: 70,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '+${earnedBadges.length - 5}',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[600],
                                ),
                              ),
                              Text(
                                'daha',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }
                  
                  final earned = earnedBadges[index];
                  final badgeDef = badgeService.getBadgeDefinition(earned.badgeId);
                  if (badgeDef == null) return const SizedBox();
                  
                  return _buildMiniBadge(badgeDef, localizations);
                },
              ),
            ),
          ],
          
          const SizedBox(height: 16),
          // Tüm rozetleri gör butonu
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => _openBadgesScreen(),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF5A4FCF),
                side: const BorderSide(color: Color(0xFF5A4FCF)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.emoji_events, size: 18),
                  const SizedBox(width: 8),
                  Text(localizations.get('all_badges')),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniBadge(BadgeDefinition badge, AppLocalizations localizations) {
    final colors = badge.colors;
    
    return Container(
      width: 70,
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Color(colors['secondary'] as int).withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Color(colors['glow'] as int),
            blurRadius: 6,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 40,
            height: 40,
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
              child: Text(badge.emoji, style: const TextStyle(fontSize: 20)),
            ),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              localizations.get(badge.nameKey),
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2d3436),
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  void _openBadgesScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BadgesScreen(
          onBack: () => Navigator.pop(context),
        ),
      ),
    );
  }

  Widget _buildSignOutButton(AuthService authService, AppUser user, AppLocalizations localizations) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: ElevatedButton(
        onPressed: () => _showSignOutDialog(authService, user, localizations),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red.shade50,
          foregroundColor: Colors.red,
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.red.shade200),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.exit_to_app, size: 18),
            const SizedBox(width: 8),
            Text(
              user.isGuest
                  ? localizations.get('exit_guest_mode')
                  : localizations.get('sign_out'),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  void _showConvertToAccountDialog(BuildContext context) {
    final locale = Localizations.localeOf(context);
    final localizations = AppLocalizations(locale);
    final TextEditingController emailController = TextEditingController();
    final TextEditingController passwordController = TextEditingController();
    final TextEditingController confirmPasswordController = TextEditingController();
    final TextEditingController displayNameController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: Text(localizations.get('convert_to_account')),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  localizations.get('convert_account_description'),
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: displayNameController,
                  decoration: InputDecoration(
                    labelText: localizations.get('display_name'),
                    prefixIcon: const Icon(Icons.person),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: emailController,
                  decoration: InputDecoration(
                    labelText: localizations.get('email'),
                    prefixIcon: const Icon(Icons.email),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: localizations.get('password'),
                    prefixIcon: const Icon(Icons.lock),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: confirmPasswordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: localizations.get('confirm_password'),
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(localizations.get('cancel')),
            ),
            ElevatedButton(
              onPressed: () async {
                final email = emailController.text.trim();
                final password = passwordController.text.trim();
                final confirmPassword = confirmPasswordController.text.trim();
                final displayName = displayNameController.text.trim();

                if (email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
                  _showErrorSnackbar(localizations.get('fill_all_fields'));
                  return;
                }

                if (password != confirmPassword) {
                  _showErrorSnackbar(localizations.get('passwords_do_not_match'));
                  return;
                }

                setState(() {
                  _isLoading = true;
                });

                try {
                  final authService = Provider.of<AuthService>(context, listen: false);

                  await authService.convertGuestToUser(
                    email: email,
                    password: password,
                    displayName: displayName.isNotEmpty ? displayName : null,
                  );

                  Navigator.pop(context);
                  _showSuccessSnackbar(localizations.get('account_created_successfully'));

                  if (mounted) {
                    setState(() {});
                  }
                } catch (e) {
                  _showErrorSnackbar('Hata: $e');
                } finally {
                  setState(() {
                    _isLoading = false;
                  });
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: Text(localizations.get('convert')),
            ),
          ],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        );
      },
    );
  }

  void _showSignOutDialog(AuthService authService, AppUser user, AppLocalizations localizations) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            user.isGuest
                ? localizations.get('exit_guest_mode')
                : localizations.get('sign_out'),
          ),
          content: Text(
            user.isGuest
                ? localizations.get('exit_guest_mode_description')
                : localizations.get('sign_out_description'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(localizations.get('cancel')),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await authService.signOut();

                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/welcome',
                      (route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: Text(localizations.get('yes')),
            ),
          ],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        );
      },
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}