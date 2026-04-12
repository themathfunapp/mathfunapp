import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'app_local_notifications.dart';

/// Uzaktan aile düellosu FCM `data` yükü (Cloud Function ile aynı anahtarlar).
class RemoteDuelInvitePayload {
  const RemoteDuelInvitePayload({
    required this.inviteId,
    required this.sessionId,
  });

  final String inviteId;
  final String sessionId;
}

/// FCM jetonunu Firestore’a yazar; Cloud Function davet bildirimi için okur.
/// Davet bildirimine tıklanınca yükü kuyruğa alır — [HomeScreen] tüketir.
/// Ön planda gelen FCM için yerel bildirim gösterir.
/// Ayrıntılar: docs/FIRESTORE_AND_FCM.md
class PushNotificationService {
  PushNotificationService._();
  static final instance = PushNotificationService._();

  static const String _remoteDuelPayloadPrefix = 'frd';

  bool _started = false;

  final ValueNotifier<int> remoteDuelInviteQueueVersion = ValueNotifier<int>(0);

  final List<RemoteDuelInvitePayload> _remoteDuelInviteQueue = <RemoteDuelInvitePayload>[];

  /// Ana sayfa açıldığında bir kez veya kuyruk güncellenince dinleyicide çağrılır.
  List<RemoteDuelInvitePayload> drainRemoteDuelInvites() {
    if (_remoteDuelInviteQueue.isEmpty) {
      return const <RemoteDuelInvitePayload>[];
    }
    final out = List<RemoteDuelInvitePayload>.from(_remoteDuelInviteQueue);
    _remoteDuelInviteQueue.clear();
    return out;
  }

  void _enqueueRemoteDuelInvite(RemoteDuelInvitePayload payload) {
    _remoteDuelInviteQueue.add(payload);
    remoteDuelInviteQueueVersion.value = remoteDuelInviteQueueVersion.value + 1;
  }

  void _decodeRemoteDuelPayloadAndEnqueue(String? payload) {
    if (payload == null || !payload.startsWith('$_remoteDuelPayloadPrefix|')) {
      return;
    }
    final parts = payload.split('|');
    if (parts.length < 3) return;
    final inviteId = parts[1].trim();
    final sessionId = parts[2].trim();
    if (inviteId.isEmpty || sessionId.isEmpty) return;
    _enqueueRemoteDuelInvite(
      RemoteDuelInvitePayload(inviteId: inviteId, sessionId: sessionId),
    );
  }

  String _encodeRemoteDuelPayload(String inviteId, String sessionId) {
    return '$_remoteDuelPayloadPrefix|$inviteId|$sessionId';
  }

  void _handleNotificationOpen(RemoteMessage message) {
    final data = message.data;
    if (data['type'] != 'family_remote_duel_invite') {
      return;
    }
    final inviteId = '${data['inviteId'] ?? ''}'.trim();
    final sessionId = '${data['sessionId'] ?? ''}'.trim();
    if (inviteId.isEmpty || sessionId.isEmpty) {
      debugPrint('PushNotificationService: eksik inviteId/sessionId');
      return;
    }
    _enqueueRemoteDuelInvite(
      RemoteDuelInvitePayload(inviteId: inviteId, sessionId: sessionId),
    );
  }

  Future<void> _initLocalNotifications() async {
    try {
      await AppLocalNotifications.initialize(
        onSelect: (NotificationResponse r) {
          _decodeRemoteDuelPayloadAndEnqueue(r.payload);
        },
      );
    } catch (e) {
      debugPrint('PushNotificationService local init: $e');
    }
  }

  Future<void> _showForegroundFamilyRemoteDuel(RemoteMessage message) async {
    final data = message.data;
    if (data['type'] != 'family_remote_duel_invite') return;
    final inviteId = '${data['inviteId'] ?? ''}'.trim();
    final sessionId = '${data['sessionId'] ?? ''}'.trim();
    if (inviteId.isEmpty || sessionId.isEmpty) return;

    const android = AndroidNotificationDetails(
      'family_remote_duel',
      'Aile düellosu',
      channelDescription: 'Uzaktan düello davetleri',
      importance: Importance.high,
      priority: Priority.high,
    );
    const ios = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    const details = NotificationDetails(android: android, iOS: ios);

    try {
      await AppLocalNotifications.plugin.show(
        91001,
        message.notification?.title ?? 'MathFun',
        message.notification?.body ?? 'Uzaktan düello davetin var.',
        details,
        payload: _encodeRemoteDuelPayload(inviteId, sessionId),
      );
    } catch (e) {
      debugPrint('PushNotificationService foreground show: $e');
    }
  }

  Future<void> initialize() async {
    if (_started) return;
    _started = true;
    if (kIsWeb) {
      return;
    }

    await _initLocalNotifications();

    FirebaseMessaging.instance.onTokenRefresh.listen((t) {
      final u = FirebaseAuth.instance.currentUser;
      if (u != null) {
        _persistToken(u.uid, t);
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationOpen);

    FirebaseMessaging.onMessage.listen((RemoteMessage m) {
      if (m.data['type'] == 'family_remote_duel_invite') {
        _showForegroundFamilyRemoteDuel(m);
      }
    });

    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        _syncTokenForFirebaseUser(user);
      }
    });

    final current = FirebaseAuth.instance.currentUser;
    if (current != null) {
      await _syncTokenForFirebaseUser(current);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final initial = await FirebaseMessaging.instance.getInitialMessage();
      if (initial != null) {
        _handleNotificationOpen(initial);
      }
    });
  }

  Future<void> _syncTokenForFirebaseUser(User user) async {
    try {
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission();
      final token = await messaging.getToken();
      await _persistToken(user.uid, token);
    } catch (e) {
      debugPrint('PushNotificationService: $e');
    }
  }

  Future<void> _persistToken(String uid, String? token) async {
    if (token == null || token.isEmpty) return;
    try {
      await FirebaseFirestore.instance
          .doc('users/$uid/private/fcm/current')
          .set(
        {
          'token': token,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    } catch (e) {
      debugPrint('PushNotificationService persist: $e');
    }
  }
}
