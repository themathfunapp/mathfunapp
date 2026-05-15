import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

import '../firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'app_local_notifications.dart';
import 'parent_panel_notification_scheduler.dart';

const String _taskParentPanelDailyNudge = 'parent_panel_daily_nudge_check';
const String _uniqueParentPanelDailyNudge = 'parent_panel_daily_nudge_unique';

@pragma('vm:entry-point')
void parentPanelNudgeCallbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    WidgetsFlutterBinding.ensureInitialized();
    if (kIsWeb) return true;
    if (task != _taskParentPanelDailyNudge) return true;

    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      await AppLocalNotifications.initialize();

      final prefs = await SharedPreferences.getInstance();
      final parentUid = prefs.getString(ParentPanelNotificationScheduler.prefParentUid) ?? '';
      final lc = prefs.getString(ParentPanelNotificationScheduler.prefLanguageCode) ?? 'en';
      if (parentUid.isEmpty) return true;

      final firestore = FirebaseFirestore.instance;
      final membersDoc = await firestore
          .collection('users')
          .doc(parentUid)
          .collection('family')
          .doc('members')
          .get();
      final raw = membersDoc.data()?['members'] as List<dynamic>? ?? const [];

      final entries = <ParentPanelFamilySnapshotEntry>[
        ParentPanelFamilySnapshotEntry(
          userId: parentUid,
          displayName: '',
          lastPlayedAt: null,
          earnedBadges: 0,
          isParent: true,
        ),
      ];

      for (final item in raw) {
        if (item is! Map) continue;
        final m = Map<String, dynamic>.from(item);
        final uid = (m['userId'] as String? ?? '').trim();
        if (uid.isEmpty) continue;

        DateTime? lastPlayedAt;
        int earnedBadges = 0;
        try {
          final stats = await firestore
              .collection('users')
              .doc(uid)
              .collection('stats')
              .doc('gameStats')
              .get();
          final lp = stats.data()?['lastPlayedAt'];
          if (lp is Timestamp) {
            lastPlayedAt = lp.toDate();
          }
        } catch (_) {}

        try {
          final badges =
              await firestore.collection('users').doc(uid).collection('badges').get();
          earnedBadges = badges.docs.length;
        } catch (_) {}

        entries.add(
          ParentPanelFamilySnapshotEntry(
            userId: uid,
            displayName: (m['displayName'] as String? ?? '').trim(),
            lastPlayedAt: lastPlayedAt,
            earnedBadges: earnedBadges,
            isParent: (m['isParent'] as bool?) ?? false,
          ),
        );
      }

      await ParentPanelNotificationScheduler.instance.maybeShowContextualFromFamily(
        languageCode: lc,
        entries: entries,
        telemetrySource: 'workmanager',
      );
    } catch (e) {
      debugPrint('ParentPanelBackgroundNudge task error: $e');
    }
    return true;
  });
}

class ParentPanelBackgroundNudgeService {
  ParentPanelBackgroundNudgeService._();

  static Future<void> initialize() async {
    if (kIsWeb) return;
    await Workmanager().initialize(
      parentPanelNudgeCallbackDispatcher,
      isInDebugMode: false,
    );
  }

  static Future<void> syncRegistrationFromPrefs() async {
    if (kIsWeb) return;
    final prefs = await SharedPreferences.getInstance();
    final master = prefs.getBool(ParentPanelNotificationScheduler.prefMaster) ?? true;
    final inactivity = prefs.getBool(ParentPanelNotificationScheduler.prefInactivity) ?? true;
    final success = prefs.getBool(ParentPanelNotificationScheduler.prefSuccess) ?? true;
    final parentUid = prefs.getString(ParentPanelNotificationScheduler.prefParentUid) ?? '';

    final shouldRun = master && (inactivity || success) && parentUid.isNotEmpty;
    if (!shouldRun) {
      await Workmanager().cancelByUniqueName(_uniqueParentPanelDailyNudge);
      return;
    }

    await Workmanager().registerPeriodicTask(
      _uniqueParentPanelDailyNudge,
      _taskParentPanelDailyNudge,
      frequency: const Duration(hours: 24),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.update,
      constraints: Constraints(networkType: NetworkType.connected),
      initialDelay: const Duration(hours: 2),
    );
  }
}

