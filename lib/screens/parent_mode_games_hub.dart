import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../localization/app_localizations.dart';
import '../models/game_mechanics.dart' show TopicType;
import '../services/parent_mode_service.dart';
import '../services/auth_service.dart';
import '../services/family_remote_duel_service.dart';
import '../utils/constants.dart';
import '../widgets/bottom_action_button.dart';
import '../widgets/shiny_button.dart';
import 'family_duel_race_screen.dart';
import 'family_remote_duel_setup_screen.dart';
import 'story_mode_screen.dart';

/// Ebeveyn modu oyun merkezi — ana sayfa veya Ebeveyn Paneli → Oyun Oyna.
class ParentModeGamesHub extends StatelessWidget {
  final bool _embeddedInPanel;
  final VoidCallback? _onOpenParentPanelFromHome;
  final VoidCallback? _onJumpToGelisimTab;

  const ParentModeGamesHub._({
    required bool embeddedInPanel,
    VoidCallback? onOpenParentPanelFromHome,
    VoidCallback? onJumpToGelisimTab,
  })  : _embeddedInPanel = embeddedInPanel,
        _onOpenParentPanelFromHome = onOpenParentPanelFromHome,
        _onJumpToGelisimTab = onJumpToGelisimTab;

  /// Çocuk ana sayfasından (ebeveyn modu açıkken).
  factory ParentModeGamesHub.forHome({
    required VoidCallback onOpenParentPanel,
  }) {
    return ParentModeGamesHub._(
      embeddedInPanel: false,
      onOpenParentPanelFromHome: onOpenParentPanel,
    );
  }

  /// Ebeveyn Paneli içindeki “Oyun Oyna” sekmesi.
  factory ParentModeGamesHub.forParentPanelTab({
    required VoidCallback onJumpToGelisimTab,
  }) {
    return ParentModeGamesHub._(
      embeddedInPanel: true,
      onJumpToGelisimTab: onJumpToGelisimTab,
    );
  }

  void _openFamilyRace(BuildContext context, {TopicType? presetTopic}) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (ctx) => FamilyDuelRaceScreen(
          onBack: () => Navigator.of(ctx).pop(),
          presetTopic: presetTopic,
        ),
      ),
    );
  }

  Future<void> _openRemoteDuel(BuildContext context) async {
    final auth = Provider.of<AuthService>(context, listen: false);
    final uid = auth.currentUser?.uid;
    if (uid == null || uid.isEmpty) return;

    final duel = Provider.of<FamilyRemoteDuelService>(context, listen: false);
    final linked = await duel.linkedChildUserIdsForHost(uid);
    final hasLinkedChildren = linked.isNotEmpty;

    if (!context.mounted) return;
    if (!hasLinkedChildren) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Uzaktan düello için ebeveyn hesabınızla giriş yapın. '
            'Bu özellik, hesabınızdaki aile bağlantısı (childUserIds) ile çalışır.',
          ),
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

  Future<void> _exitToChildMode(BuildContext context) async {
    await Provider.of<ParentModeService>(context, listen: false).setParentMode(false);
    if (!context.mounted) return;
    if (_embeddedInPanel) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final actionCards = [
      _ActionCardData(
        title: 'Birlikte Yarış',
        subtitle: 'Aynı sorularda kafa kafaya eğlenceli yarış',
        icon: Icons.emoji_events,
        emoji: '🏁',
        onTap: () => _openFamilyRace(context),
        colors: const [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
      ),
      if (_embeddedInPanel)
        _ActionCardData(
          title: 'Hikaye Önizleme',
          subtitle: 'Çocuk ekranındaki hikaye modunu aç',
          icon: Icons.menu_book_outlined,
          emoji: '📖',
          onTap: () {
            Navigator.of(context).push<void>(
              MaterialPageRoute<void>(
                builder: (ctx) => const StoryModeScreen(
                  openedFromParentPanel: true,
                ),
              ),
            );
          },
          colors: const [Color(0xFF8360C3), Color(0xFF2EBF91)],
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Matematik Macerası',
          style: titleStyle,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          'Ebeveyn modu',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: Colors.amber.shade200,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Çocuğunuzla birlikte yarışın; sonuçlar aile liderliğine eklenir.',
          textAlign: TextAlign.center,
          style: subtitleStyle,
        ),
        const SizedBox(height: 18),
        Text(
          'Hızlı Başlat',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.95),
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        ...List.generate(actionCards.length, (index) {
          final card = actionCards[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: Duration(milliseconds: 320 + (index * 100)),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) => Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, (1 - value) * 14),
                  child: child,
                ),
              ),
              child: _ActionModeCard(data: card),
            ),
          );
        }),
        if (!_embeddedInPanel) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: BottomActionButton(
                  text: localizations.parentPanel,
                  emoji: '',
                  icon: const ParentPanelLeadingIcon(),
                  onPressed: () => _onOpenParentPanelFromHome?.call(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
        TextButton(
          onPressed: () => _exitToChildMode(context),
          child: Text(
            'Çocuk moduna dön',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.9)),
          ),
        ),
      ],
    );
  }
}

class _ActionCardData {
  final String title;
  final String subtitle;
  final IconData icon;
  final String emoji;
  final VoidCallback onTap;
  final List<Color> colors;

  const _ActionCardData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.emoji,
    required this.onTap,
    required this.colors,
  });
}

class _ActionModeCard extends StatefulWidget {
  final _ActionCardData data;
  const _ActionModeCard({required this.data});

  @override
  State<_ActionModeCard> createState() => _ActionModeCardState();
}

class _ActionModeCardState extends State<_ActionModeCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      onTap: data.onTap,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 110),
        scale: _pressed ? 0.98 : 1.0,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          height: 86,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: data.colors),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: data.colors.first.withValues(alpha: 0.32),
                blurRadius: 14,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Text(data.emoji, style: const TextStyle(fontSize: 22)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      data.subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.92),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(data.icon, color: Colors.white, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
