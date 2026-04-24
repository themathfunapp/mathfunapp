import 'package:flutter/material.dart';

import '../models/story_invite_payload.dart';
import 'parent_story_invite_bar.dart';

/// Ebeveyn paneli hikâye önizlemesinde tam ekran dünya oyunlarının üstüne yerleştirilir.
Widget storyParentInviteStrip(StoryInvitePayload? payload) {
  if (payload == null) return const SizedBox.shrink();
  return Padding(
    padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
    child: ParentStoryInviteBar(payload: payload),
  );
}
