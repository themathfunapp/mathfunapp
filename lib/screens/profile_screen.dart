import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:file_selector/file_selector.dart' as file_selector;
import 'package:crop_your_image/crop_your_image.dart';
import '../services/auth_service.dart';
import '../services/badge_service.dart';
import '../services/daily_reward_service.dart';
import '../services/game_mechanics_service.dart';
import '../services/story_service.dart';
import '../models/app_user.dart';
import '../models/badge.dart';
import '../localization/app_localizations.dart';
import 'badges_screen.dart';
import '../widgets/bottom_action_button.dart';
import 'parent_panel_screen.dart';
import 'welcome_screen.dart';
import 'app_screen_wrappers.dart';
import 'world_leaderboard_screen.dart';

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
  bool _isUploadingPhoto = false;
  final ImagePicker _imagePicker = ImagePicker();

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
                          _buildGuestInfoCard(user, localizations, authService),
                        const SizedBox(height: 24),

                        // İSTATİSTİKLER
                        _buildStatisticsCard(localizations),
                        const SizedBox(height: 24),

                        if (!user.isGuest) ...[
                          _buildWorldLeaderboardCard(context, localizations),
                          const SizedBox(height: 24),
                        ],

                        // BAŞARILAR
                        _buildAchievementsCard(localizations),
                        const SizedBox(height: 24),

                        // EBEVEYN PANELİ (misafir giriş yapanlar erişemez)
                        _buildParentPanelCard(authService, localizations),
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
    final authService = Provider.of<AuthService>(context, listen: false);
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
              GestureDetector(
                onTap: (user.isGuest || _isUploadingPhoto)
                    ? null
                    : () => _pickAndSaveProfilePhoto(authService),
                child: Container(
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
                  child: ClipOval(
                    child: Stack(
                      children: [
                        Positioned.fill(child: _buildProfileAvatar(user)),
                        if (_isUploadingPhoto)
                          Positioned.fill(
                            child: Container(
                              color: Colors.black.withOpacity(0.28),
                              child: const Center(
                                child: SizedBox(
                                  width: 28,
                                  height: 28,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.6,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              // Fotoğraf değiştirme butonu (kullanıcı isteği: "1"e tıklayınca cihazdan seç)
              GestureDetector(
                onTap: (user.isGuest || _isUploadingPhoto)
                    ? null
                    : () => _pickAndSaveProfilePhoto(authService),
                child: Container(
                  width: 34,
                  height: 34,
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
              ),
            ],
          ),

          const SizedBox(height: 20),

          // KULLANICI BİLGİLERİ
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  user.isGuest
                      ? localizations.get('guest_user')
                      : user.displayName ?? localizations.get('user'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2d3436),
                  ),
                ),
              ),
              if (!user.isGuest) ...[
                const SizedBox(width: 6),
                InkWell(
                  onTap: () => _showEditNameDialog(authService, localizations),
                  borderRadius: BorderRadius.circular(14),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(
                      Icons.edit_rounded,
                      size: 18,
                      color: Color(0xFF5A4FCF),
                    ),
                  ),
                ),
              ],
            ],
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
          else ...[
            Text(
              '${localizations.playerCodeLabel}: ${user.userCode ?? user.playerCode}',
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey.shade800,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
          ],

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

          // HIZLI İSTATİSTİKLER - Gerçek verilerle (şans çarkı ödülleri dahil)
          Consumer4<BadgeService, GameMechanicsService, DailyRewardService, StoryService>(
            builder: (context, badgeService, mechanicsService, dailyRewardService, storyService, _) {
              final stats = badgeService.userStats;
              final coins = mechanicsService.inventory.coins;
              final diamonds = mechanicsService.inventory.gems;
              final lives = mechanicsService.currentLives;
              final maxLives = mechanicsService.maxLives;
              final storyStars = storyService.progress?.totalStars ?? 0;
              final bonusStars = dailyRewardService.profileBonusStars;
              final totalStars = storyStars + bonusStars;
              return Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 16,
                children: [
                  _buildStatItem(
                    '🏆',
                    '${stats?.totalScore ?? 0}',
                    localizations.get('total_score'),
                    infoMessage:
                        'Toplam Puan, oyunlarda yaptığın skorların birikimidir. Profil performansını gösterir.',
                  ),
                  _buildStatItem(
                    '⭐',
                    '$totalStars',
                    localizations.get('profile_total_stars'),
                    infoMessage:
                        'Yıldızlar hikaye ilerlemesi ve bonuslardan gelir. Bazı ödül/milestone sistemlerinde kullanılır.',
                  ),
                  _buildStatItem('🪙', '$coins', 'Altın'),
                  _buildStatItem('💎', '$diamonds', localizations.get('diamonds')),
                  _buildStatItem('❤️', '$lives/$maxLives', localizations.get('lives')),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProfileAvatar(AppUser user) {
    if (user.photoURL != null && user.photoURL!.isNotEmpty) {
      final photo = user.photoURL!;
      if (photo.startsWith('data:image')) {
        final parts = photo.split(',');
        if (parts.length == 2) {
          try {
            final bytes = base64Decode(parts[1]);
            return Image.memory(bytes, fit: BoxFit.cover, width: 100, height: 100);
          } catch (_) {}
        }
      }
      return Image.network(
        photo,
        fit: BoxFit.cover,
        width: 100,
        height: 100,
        errorBuilder: (_, __, ___) => Icon(
          user.isGuest ? Icons.person_outline : Icons.person,
          size: 62,
          color: Colors.white,
        ),
      );
    }
    return Center(
      child: Icon(
        user.isGuest ? Icons.person_outline : Icons.person,
        size: 62,
        color: Colors.white,
      ),
    );
  }

  Future<void> _pickAndSaveProfilePhoto(AuthService authService) async {
    final user = authService.currentUser;
    if (user == null || user.isGuest) return;
    try {
      final originalBytes = await _pickProfileImageBytes();
      if (originalBytes == null) return;
      final croppedBytes = await _openAvatarCropDialog(originalBytes);
      if (croppedBytes == null) return;

      if (mounted) setState(() => _isUploadingPhoto = true);
      final bytes = _createSmallAvatarBytes(croppedBytes);
      try {
        final uploadedUrl = await authService
            .uploadProfilePhoto(bytes)
            .timeout(const Duration(seconds: 20));
        await authService
            .updateProfile(photoURL: uploadedUrl)
            .timeout(const Duration(seconds: 20));
      } catch (storageError) {
        debugPrint('Profile photo storage upload failed: $storageError');
        // Fallback: Storage kural/erişim sorunu olursa base64 olarak kullanıcı profiline kaydet.
        // updateProfile içinde data:image URL Firebase Auth'a yazılmadan sadece Firestore'a kaydedilir.
        final dataUrl = 'data:image/jpeg;base64,${base64Encode(bytes)}';
        await authService
            .updateProfile(photoURL: dataUrl)
            .timeout(const Duration(seconds: 20));
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profil fotoğrafı güncellendi.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      debugPrint('Profile photo update failed: $e');
      if (!mounted) return;
      setState(() => _isUploadingPhoto = false);
      final isPluginIssue = e.toString().contains('MissingPluginException');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isPluginIssue
                ? 'Fotoğraf seçici hazır değil. Uygulamayı kapatıp yeniden aç ve tekrar dene.'
                : 'Fotoğraf yüklenemedi, lütfen tekrar dene.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isUploadingPhoto = false);
      }
    }
  }

  Future<Uint8List?> _openAvatarCropDialog(Uint8List originalBytes) async {
    final controller = CropController();
    final completer = Completer<Uint8List?>();

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.white,
          insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          child: SizedBox(
            width: 360,
            height: 470,
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF5A4FCF), Color(0xFF6F86FF)],
                    ),
                  ),
                  child: const Text(
                    'Fotoğrafı Yuvarlak Kırp',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                Expanded(
                  child: Crop(
                    image: originalBytes,
                    controller: controller,
                    withCircleUi: true,
                    baseColor: Colors.black,
                    maskColor: Colors.black.withOpacity(0.55),
                    onCropped: (result) {
                      if (result is CropSuccess) {
                        completer.complete(result.croppedImage);
                      } else if (result is CropFailure) {
                        completer.completeError(result.cause, result.stackTrace);
                      }
                      if (dialogContext.mounted) {
                        Navigator.pop(dialogContext);
                      }
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            if (!completer.isCompleted) completer.complete(null);
                            Navigator.pop(dialogContext);
                          },
                          child: const Text('Vazgeç'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => controller.crop(),
                          child: const Text('Kırp ve Kullan'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (!completer.isCompleted) return null;
    return completer.future;
  }

  Future<Uint8List?> _pickProfileImageBytes() async {
    // Mobil/web: image_picker ile galeri
    if (kIsWeb ||
        defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS) {
      final picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 75,
        maxWidth: 720,
      );
      return picked?.readAsBytes();
    }

    // Desktop (Windows/macOS/Linux): dosya seçici ile bilgisayardan seç
    try {
      final typeGroup = file_selector.XTypeGroup(
        label: 'images',
        extensions: ['jpg', 'jpeg', 'png', 'webp'],
      );
      final file = await file_selector.openFile(acceptedTypeGroups: [typeGroup]);
      if (file == null) return null;
      return file.readAsBytes();
    } on MissingPluginException {
      // Plugin sıcak yüklenmediyse geçici fallback.
      final picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 75,
        maxWidth: 720,
      );
      return picked?.readAsBytes();
    }
  }

  Uint8List _createSmallAvatarBytes(Uint8List source) {
    try {
      final decoded = img.decodeImage(source);
      if (decoded == null) return source;
      final resized = img.copyResize(
        decoded,
        width: decoded.width > decoded.height ? 256 : null,
        height: decoded.height >= decoded.width ? 256 : null,
        interpolation: img.Interpolation.cubic,
      );
      return Uint8List.fromList(img.encodeJpg(resized, quality: 50));
    } catch (_) {
      return source;
    }
  }

  Future<void> _showEditNameDialog(
    AuthService authService,
    AppLocalizations localizations,
  ) async {
    final user = authService.currentUser;
    if (user == null || user.isGuest) return;
    final controller = TextEditingController(text: user.displayName ?? '');
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: Container(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFFE0F7), Color(0xFFE3F2FD)],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.purple.withOpacity(0.18),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Text('✏️', style: TextStyle(fontSize: 24)),
                    const SizedBox(width: 8),
                    Text(
                      'Adını Güncelle',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF5A4FCF),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: controller,
                  maxLength: 24,
                  decoration: InputDecoration(
                    labelText: 'Yeni ad',
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.9),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFF5A4FCF), width: 1.5),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: Colors.purple.shade200, width: 1.4),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFF5A4FCF), width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF5A4FCF),
                          side: const BorderSide(color: Color(0xFF5A4FCF), width: 1.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          padding: const EdgeInsets.symmetric(vertical: 11),
                        ),
                        child: Text(localizations.get('cancel')),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          final nextName = controller.text.trim();
                          if (nextName.isEmpty) return;
                          await authService.updateProfile(displayName: nextName);
                          if (!mounted) return;
                          Navigator.pop(dialogContext);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5A4FCF),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          padding: const EdgeInsets.symmetric(vertical: 11),
                        ),
                        child: Text(localizations.get('ok')),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(
    String emoji,
    String value,
    String label, {
    String? infoMessage,
  }) {
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
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
            if (infoMessage != null) ...[
              const SizedBox(width: 4),
              InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => _showStatInfo(infoMessage),
                child: const Padding(
                  padding: EdgeInsets.all(2),
                  child: Icon(
                    Icons.help_outline_rounded,
                    size: 13,
                    color: Colors.grey,
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  void _showStatInfo(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Widget _buildGuestInfoCard(AppUser user, AppLocalizations localizations, AuthService authService) {
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
                  onPressed: _isLoading ? null : () => _navigateToLoginScreen(authService),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Row(
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

  Widget _buildWorldLeaderboardCard(BuildContext context, AppLocalizations localizations) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(25),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (context) => const WorldLeaderboardScreen(),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                const Text('🌍', style: TextStyle(fontSize: 28)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        localizations.get('world_leaderboard_title'),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2d3436),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        localizations.get('world_leaderboard_subtitle'),
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: Colors.grey.shade600, size: 28),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatisticsCard(AppLocalizations localizations) {
    final badgeService = Provider.of<BadgeService>(context);
    final userStats = badgeService.userStats;
    
    // Doğru cevap yüzdesini hesapla
    final totalAnswered = userStats?.totalQuestionsAnswered ?? 0;
    final correctAnswers = userStats?.totalCorrectAnswers ?? 0;
    final correctPercentage = totalAnswered > 0 
        ? ((correctAnswers / totalAnswered) * 100).round() 
        : 0;
    
    final stats = [
      {'emoji': '🎯', 'label': localizations.get('total_games'), 'value': '${userStats?.totalGamesPlayed ?? 0}'},
      {'emoji': '✅', 'label': localizations.get('correct_answers'), 'value': '$correctPercentage%'},
      {'emoji': '🔥', 'label': localizations.get('streak_record'), 'value': '${userStats?.bestStreak ?? 0}'},
      {'emoji': '🏆', 'label': localizations.get('total_score'), 'value': '${userStats?.totalScore ?? 0}'},
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
          LayoutBuilder(
            builder: (context, constraints) {
              const spacing = 6.0;
              final w = constraints.maxWidth;
              // Tek satırda 4 kutu; çok dar ekranda 2x2 (Wrap, genişlik kartın içinden hesaplanır).
              final useFourAcross = w >= 340;
              final tileWTwoCol = (w - spacing) / 2;

              Widget tile(Map<String, String> stat) {
                return SizedBox(
                  height: useFourAcross ? 70 : 80,
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(
                      vertical: useFourAcross ? 4 : 7,
                      horizontal: useFourAcross ? 3 : 7,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F9FA),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(stat['emoji']!, style: const TextStyle(fontSize: 11)),
                        const SizedBox(height: 1),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            stat['value']!,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF5A4FCF),
                            ),
                            maxLines: 1,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          stat['label']!,
                          style: TextStyle(
                            fontSize: useFourAcross ? 7.5 : 8.5,
                            color: const Color(0xFF1A1A1A),
                            height: 1.05,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: useFourAcross ? 1 : 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              }

              if (useFourAcross) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var i = 0; i < stats.length; i++) ...[
                      if (i > 0) const SizedBox(width: spacing),
                      Expanded(child: tile(stats[i])),
                    ],
                  ],
                );
              }

              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: stats
                    .map(
                      (stat) => SizedBox(
                        width: tileWTwoCol,
                        child: tile(stat),
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementsCard(AppLocalizations localizations) {
    final badgeService = Provider.of<BadgeService>(context);
    final mechanicsService = Provider.of<GameMechanicsService>(context);
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
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF4E5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFFD18A)),
            ),
            child: Row(
              children: [
                const Text('🔥', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Macera Serisi',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF8D5A00),
                    ),
                  ),
                ),
                Text(
                  '${mechanicsService.adventureWeeklyStreak}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF8D5A00),
                  ),
                ),
              ],
            ),
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

  Widget _buildParentPanelCard(AuthService authService, AppLocalizations localizations) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: InkWell(
        onTap: () {
          if (authService.currentUser?.isGuest == true) {
            _showParentPanelGuestDialog(localizations, authService);
            return;
          }
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ParentPanelScreen(
                onBack: () => Navigator.pop(context),
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF2C3E50), Color(0xFF3498DB)],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: ParentPanelLeadingIcon(),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      localizations.parentPanel,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      localizations.parentPanelDesc,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.white.withOpacity(0.8),
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showParentPanelGuestDialog(AppLocalizations localizations, AuthService authService) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2C3E50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.lock_outline, color: Colors.amber, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                localizations.parentPanelLoginRequired,
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ],
        ),
        content: Text(
          localizations.parentPanelLoginRequiredDesc,
          style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(localizations.close, style: const TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _navigateToLoginScreen(authService);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              foregroundColor: Colors.black87,
            ),
            child: Text(localizations.createAccount),
          ),
        ],
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

  /// Oturum açma sayfasına yönlendir (Google / e-posta / misafir)
  Future<void> _navigateToLoginScreen(AuthService authService) async {
    if (_isLoading) return;
    try {
      await authService.signOut();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => WelcomeScreen(
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
          SnackBar(content: Text('Bir hata oluştu: $e'), backgroundColor: Colors.red),
        );
      }
    }
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
                await _navigateToLoginScreen(authService);
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