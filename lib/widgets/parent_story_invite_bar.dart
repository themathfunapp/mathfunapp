import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../localization/app_localizations.dart';
import '../models/app_user.dart';
import '../models/family_member.dart';
import '../models/story_invite_payload.dart';
import '../services/auth_service.dart';
import '../services/family_service.dart';
import '../services/family_story_invite_service.dart';

/// Ebeveyn paneli hikâye önizlemesinde: kayıtlı aile üyesine hikâye daveti gönderir.
class ParentStoryInviteBar extends StatelessWidget {
  final StoryInvitePayload payload;

  const ParentStoryInviteBar({super.key, required this.payload});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context, listen: false);
    final loc = AppLocalizations(Locale(auth.currentUser?.selectedLanguage ?? 'tr'));
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: const BorderSide(color: Colors.white54),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        ),
        icon: const Icon(Icons.send_to_mobile, color: Colors.lightGreenAccent),
        label: Text(
          loc.get('family_story_invite_button'),
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        onPressed: () => FamilyStoryInviteFlow.run(context, payload, loc),
      ),
    );
  }
}

class FamilyStoryInviteFlow {
  FamilyStoryInviteFlow._();

  static Future<void> run(
    BuildContext context,
    StoryInvitePayload payload,
    AppLocalizations localizations,
  ) async {
    final auth = Provider.of<AuthService>(context, listen: false);
    final user = auth.currentUser;
    if (user == null || user.isGuest) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(localizations.get('family_story_invite_login_required'))),
        );
      }
      return;
    }

    final family = Provider.of<FamilyService>(context, listen: false);
    final candidates = family.members.where((m) => m.userId != user.uid).toList();
    if (candidates.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(localizations.get('family_story_invite_no_members'))),
        );
      }
      return;
    }

    if (candidates.length == 1) {
      await _send(context, payload, localizations, user, candidates.first);
      return;
    }

    if (!context.mounted) return;
    final picked = await showModalBottomSheet<FamilyMember>(
      context: context,
      backgroundColor: const Color(0xFF1a1a2e),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  localizations.get('family_story_invite_pick_member'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ...candidates.map(
                (m) => ListTile(
                  leading: Icon(
                    m.isParent ? Icons.person : Icons.child_care,
                    color: Colors.amber,
                  ),
                  title: Text(m.displayName, style: const TextStyle(color: Colors.white)),
                  onTap: () => Navigator.pop(ctx, m),
                ),
              ),
            ],
          ),
        );
      },
    );
    if (picked != null && context.mounted) {
      await _send(context, payload, localizations, user, picked);
    }
  }

  static Future<void> _send(
    BuildContext context,
    StoryInvitePayload payload,
    AppLocalizations localizations,
    AppUser user,
    FamilyMember member,
  ) async {
    final fromName = user.displayName ?? user.username ?? 'Ebeveyn';
    final inviteSvc = Provider.of<FamilyStoryInviteService>(context, listen: false);
    final ok = await inviteSvc.createInvite(
      fromUserId: user.uid,
      fromDisplayName: fromName,
      toUserId: member.userId,
      toDisplayName: member.displayName,
      worldId: payload.worldId,
      worldNameKey: payload.worldNameKey,
      chapterId: payload.chapterId,
      chapterNameKey: payload.chapterNameKey,
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? localizations.get('family_story_invite_sent').replaceAll('{0}', member.displayName)
              : localizations.get('family_story_invite_failed'),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
