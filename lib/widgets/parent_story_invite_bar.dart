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

    if (!context.mounted) return;
    final picked = await showModalBottomSheet<List<FamilyMember>>(
      context: context,
      backgroundColor: const Color(0xFF1a1a2e),
      builder: (ctx) {
        final selectedIds = <String>{};
        if (candidates.length == 1) {
          selectedIds.add(candidates.first.userId);
        }
        return SafeArea(
          child: StatefulBuilder(
            builder: (context, setState) => Column(
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
                  (m) => CheckboxListTile(
                    value: selectedIds.contains(m.userId),
                    activeColor: Colors.lightGreenAccent,
                    checkColor: Colors.black,
                    title: Text(m.displayName, style: const TextStyle(color: Colors.white)),
                    secondary: Icon(
                      m.isParent ? Icons.person : Icons.child_care,
                      color: Colors.amber,
                    ),
                    onChanged: (_) {
                      setState(() {
                        if (selectedIds.contains(m.userId)) {
                          selectedIds.remove(m.userId);
                        } else {
                          selectedIds.add(m.userId);
                        }
                      });
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: FilledButton.icon(
                    onPressed: selectedIds.isEmpty
                        ? null
                        : () {
                            final selected = candidates
                                .where((m) => selectedIds.contains(m.userId))
                                .toList();
                            Navigator.pop(ctx, selected);
                          },
                    icon: const Icon(Icons.send_rounded),
                    label: Text('Davet gönder (${selectedIds.length})'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (picked != null && picked.isNotEmpty && context.mounted) {
      await _sendGroup(context, payload, localizations, user, picked);
    }
  }

  static Future<void> _sendGroup(
    BuildContext context,
    StoryInvitePayload payload,
    AppLocalizations localizations,
    AppUser user,
    List<FamilyMember> members,
  ) async {
    final fromName = user.displayName ?? user.username ?? 'Ebeveyn';
    final inviteSvc = Provider.of<FamilyStoryInviteService>(context, listen: false);
    final ok = await inviteSvc.createGroupInvites(
      fromUserId: user.uid,
      fromDisplayName: fromName,
      invites: members
          .map((m) => StoryInviteTarget(userId: m.userId, displayName: m.displayName))
          .toList(),
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
              ? (members.length == 1
                  ? localizations.get('family_story_invite_sent').replaceAll('{0}', members.first.displayName)
                  : '${members.length} aile üyesine hikâye daveti gönderildi.')
              : localizations.get('family_story_invite_failed'),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
