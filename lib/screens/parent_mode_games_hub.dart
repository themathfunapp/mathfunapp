import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../localization/app_localizations.dart';
import '../models/game_mechanics.dart' show TopicType;
import '../services/parent_mode_service.dart';
import '../utils/constants.dart';
import '../widgets/bottom_action_button.dart';
import '../widgets/parent_mode_regions_map.dart';
import '../widgets/shiny_button.dart';
import 'family_duel_race_screen.dart';

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
        const SizedBox(height: 28),
        ParentModeRegionsMap(
          onExploreAll: () => _openFamilyRace(context),
          onPickRegion: (TopicType t) => _openFamilyRace(context, presetTopic: t),
        ),
        const SizedBox(height: 28),
        ShinyButton(
          text: '🏁 Birlikte yarış',
          onPressed: () => _openFamilyRace(context),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: BottomActionButton(
                text: _embeddedInPanel ? 'Gelişim özeti' : localizations.parentPanel,
                emoji: _embeddedInPanel ? '📊' : '👨‍👩‍👧',
                onPressed: () {
                  if (_embeddedInPanel) {
                    _onJumpToGelisimTab?.call();
                  } else {
                    _onOpenParentPanelFromHome?.call();
                  }
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
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
