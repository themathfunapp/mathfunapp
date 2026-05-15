import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/app_user.dart';
import '../models/in_app_notification.dart';

/// Aile üyeleri için uygulama içi bildirimler (`users/{uid}/in_app_notifications`).
class InAppNotificationService extends ChangeNotifier {
  InAppNotificationService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sub;
  List<InAppNotificationItem> _items = [];
  String? _userId;

  List<InAppNotificationItem> get items => List.unmodifiable(_items);

  int get unreadCount => _items.where((e) => !e.read).length;

  /// Aile bildirimleri ebeveyn / Premium kapsamındadır; [premiumActive] false iken dinlenmez.
  void initialize(AppUser? user, {bool premiumActive = false}) {
    _sub?.cancel();
    _sub = null;
    _userId = user?.uid;

    if (user == null ||
        user.isGuest ||
        user.uid.isEmpty ||
        !premiumActive) {
      _items = [];
      notifyListeners();
      return;
    }

    _sub = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('in_app_notifications')
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots()
        .listen(
      (snap) {
        _items = snap.docs.map(InAppNotificationItem.fromDoc).toList();
        notifyListeners();
      },
      onError: (Object e) {
        debugPrint('InAppNotificationService stream error: $e');
        // PERMISSION_DENIED vb. sürekli hata → kare başına log/notify döngüsünü kes
        _sub?.cancel();
        _sub = null;
        _items = [];
        notifyListeners();
      },
    );
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> markAllRead() async {
    final uid = _userId;
    if (uid == null || uid.isEmpty) return;

    final unread = _items.where((e) => !e.read).toList();
    if (unread.isEmpty) return;

    var batch = _firestore.batch();
    var n = 0;
    for (final item in unread) {
      final ref = _firestore
          .collection('users')
          .doc(uid)
          .collection('in_app_notifications')
          .doc(item.id);
      batch.update(ref, {'read': true});
      n++;
      if (n >= 400) {
        await batch.commit();
        batch = _firestore.batch();
        n = 0;
      }
    }
    if (n > 0) {
      await batch.commit();
    }
  }

  Future<void> markOneRead(String docId) async {
    final uid = _userId;
    if (uid == null || uid.isEmpty) return;
    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('in_app_notifications')
          .doc(docId)
          .update({'read': true});
    } catch (e) {
      debugPrint('InAppNotificationService markOneRead: $e');
    }
  }

  Future<void> deleteById(String docId) async {
    final uid = _userId;
    if (uid == null || uid.isEmpty) return;
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('in_app_notifications')
        .doc(docId)
        .delete();
  }

  Future<void> deleteAll() async {
    final uid = _userId;
    if (uid == null || uid.isEmpty) return;
    if (_items.isEmpty) return;

    var batch = _firestore.batch();
    var n = 0;
    for (final item in _items) {
      final ref = _firestore
          .collection('users')
          .doc(uid)
          .collection('in_app_notifications')
          .doc(item.id);
      batch.delete(ref);
      n++;
      if (n >= 400) {
        await batch.commit();
        batch = _firestore.batch();
        n = 0;
      }
    }
    if (n > 0) {
      await batch.commit();
    }
  }

  /// İsim değişince ailedeki diğer hesaplara bildirim yazar.
  static Future<void> sendDisplayNameChangedToFamily({
    required FirebaseFirestore firestore,
    required String actorUid,
    required String oldDisplayName,
    required String newDisplayName,
  }) async {
    if (actorUid.isEmpty || oldDisplayName == newDisplayName) return;

    final recipients = await _collectFamilyRecipientUserIds(
      firestore: firestore,
      actorUid: actorUid,
    );
    if (recipients.isEmpty) return;

    var batch = firestore.batch();
    var n = 0;
    for (final targetUid in recipients) {
      final ref = firestore
          .collection('users')
          .doc(targetUid)
          .collection('in_app_notifications')
          .doc();
      batch.set(ref, {
        'type': 'display_name_changed',
        'fromUid': actorUid,
        'oldDisplayName': oldDisplayName,
        'newDisplayName': newDisplayName,
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
      n++;
      if (n >= 400) {
        await batch.commit();
        batch = firestore.batch();
        n = 0;
      }
    }
    if (n > 0) {
      await batch.commit();
    }
  }

  static Future<List<String>> _collectFamilyRecipientUserIds({
    required FirebaseFirestore firestore,
    required String actorUid,
  }) async {
    final out = <String>{};

    Future<void> addFromMembersDoc(DocumentSnapshot<Map<String, dynamic>>? doc) async {
      if (doc == null || !doc.exists) return;
      final list = doc.data()?['members'] as List<dynamic>? ?? [];
      for (final raw in list) {
        if (raw is! Map) continue;
        final m = Map<String, dynamic>.from(raw);
        final uid = m['userId'] as String? ?? '';
        if (uid.isNotEmpty && uid != actorUid) {
          out.add(uid);
        }
      }
    }

    try {
      final hubSnap = await firestore
          .collection('users')
          .doc(actorUid)
          .collection('family')
          .doc('members')
          .get();
      await addFromMembersDoc(hubSnap);
    } catch (e) {
      debugPrint('collect recipients hub: $e');
    }

    try {
      final actorSnap = await firestore.collection('users').doc(actorUid).get();
      final anchor = actorSnap.data()?['familyAnchorParentUid'] as String?;
      if (anchor != null && anchor.isNotEmpty && anchor != actorUid) {
        final parentSnap = await firestore
            .collection('users')
            .doc(anchor)
            .collection('family')
            .doc('members')
            .get();
        await addFromMembersDoc(parentSnap);
      }
    } catch (e) {
      debugPrint('collect recipients anchor: $e');
    }

    return out.toList();
  }

  static Future<String> _fetchDisplayName(
    FirebaseFirestore firestore,
    String uid,
  ) async {
    if (uid.isEmpty) return '';
    try {
      final snap = await firestore.collection('users').doc(uid).get();
      final d = snap.data();
      final n = d?['displayName'] as String?;
      if (n != null && n.trim().isNotEmpty) return n.trim();
      final email = d?['email'] as String?;
      if (email != null && email.contains('@')) {
        return email.split('@').first.trim();
      }
    } catch (e) {
      debugPrint('InAppNotification _fetchDisplayName: $e');
    }
    return '';
  }

  static Map<String, dynamic> _notificationPayload({
    required String type,
    required String fromUid,
    String actorDisplayName = '',
    String badgeNameKey = '',
    String worldNameKey = '',
    String chapterNameKey = '',
    String oldDisplayName = '',
    String newDisplayName = '',
    int numberValue = 0,
    String topicKey = '',
  }) {
    return {
      'type': type,
      'fromUid': fromUid,
      'actorDisplayName': actorDisplayName,
      'badgeNameKey': badgeNameKey,
      'worldNameKey': worldNameKey,
      'chapterNameKey': chapterNameKey,
      'oldDisplayName': oldDisplayName,
      'newDisplayName': newDisplayName,
      'numberValue': numberValue,
      'topicKey': topicKey,
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  /// Çocuk rozet kazandığında ailedeki diğer üyelere (ebeveyn vb.) bildirim.
  static Future<void> sendChildBadgeEarnedToFamily({
    required FirebaseFirestore firestore,
    required String childUid,
    required String badgeNameKey,
  }) async {
    if (childUid.isEmpty || badgeNameKey.isEmpty) return;
    final recipients = await _collectFamilyRecipientUserIds(
      firestore: firestore,
      actorUid: childUid,
    );
    if (recipients.isEmpty) return;
    final childName = await _fetchDisplayName(firestore, childUid);

    var batch = firestore.batch();
    var n = 0;
    for (final targetUid in recipients) {
      final ref = firestore
          .collection('users')
          .doc(targetUid)
          .collection('in_app_notifications')
          .doc();
      batch.set(
        ref,
        _notificationPayload(
          type: 'child_badge_earned',
          fromUid: childUid,
          actorDisplayName: childName,
          badgeNameKey: badgeNameKey,
        ),
      );
      n++;
      if (n >= 400) {
        await batch.commit();
        batch = firestore.batch();
        n = 0;
      }
    }
    if (n > 0) await batch.commit();
  }

  /// Günlük meydan okuma başarıyla bitince aile üyelerine.
  static Future<void> sendDailyChallengeCompletedToFamily({
    required FirebaseFirestore firestore,
    required String childUid,
    required String childDisplayName,
  }) async {
    if (childUid.isEmpty) return;
    final recipients = await _collectFamilyRecipientUserIds(
      firestore: firestore,
      actorUid: childUid,
    );
    if (recipients.isEmpty) return;
    final name = childDisplayName.trim().isNotEmpty
        ? childDisplayName.trim()
        : await _fetchDisplayName(firestore, childUid);

    var batch = firestore.batch();
    var n = 0;
    for (final targetUid in recipients) {
      final ref = firestore
          .collection('users')
          .doc(targetUid)
          .collection('in_app_notifications')
          .doc();
      batch.set(
        ref,
        _notificationPayload(
          type: 'child_daily_challenge_complete',
          fromUid: childUid,
          actorDisplayName: name,
        ),
      );
      n++;
      if (n >= 400) {
        await batch.commit();
        batch = firestore.batch();
        n = 0;
      }
    }
    if (n > 0) await batch.commit();
  }

  /// Ebeveynin gönderdiği hikâye önerisi — çocuğun bildirim kutusuna.
  static Future<void> sendFamilyStorySuggestedToRecipient({
    required FirebaseFirestore firestore,
    required String toUserId,
    required String fromUserId,
    required String fromDisplayName,
    required String sessionId,
    required String worldNameKey,
    required String chapterNameKey,
  }) async {
    if (toUserId.isEmpty || sessionId.isEmpty) return;
    final docId = 'fs_story_${sessionId}_$toUserId';
    final ref = firestore
        .collection('users')
        .doc(toUserId)
        .collection('in_app_notifications')
        .doc(docId);
    try {
      final existing = await ref.get();
      if (existing.exists) return;
      await ref.set(
        _notificationPayload(
          type: 'family_story_suggested',
          fromUid: fromUserId,
          actorDisplayName: fromDisplayName.trim(),
          worldNameKey: worldNameKey,
          chapterNameKey: chapterNameKey,
        ),
      );
    } catch (e) {
      debugPrint('sendFamilyStorySuggestedToRecipient: $e');
    }
  }

  /// Ebeveyn PDF haftalık raporu oluşturduktan sonra kendi bildirimine kayıt.
  static Future<void> sendWeeklyReportReadyNotification({
    required FirebaseFirestore firestore,
    required String parentUid,
    required String childName,
  }) async {
    if (parentUid.isEmpty || childName.trim().isEmpty) return;
    final ref = firestore
        .collection('users')
        .doc(parentUid)
        .collection('in_app_notifications')
        .doc();
    try {
      await ref.set(
        _notificationPayload(
          type: 'weekly_report_ready',
          fromUid: parentUid,
          actorDisplayName: childName.trim(),
        ),
      );
    } catch (e) {
      debugPrint('sendWeeklyReportReadyNotification: $e');
    }
  }

  /// Çocuk seviye atlayınca ailedeki diğer üyelere (ebeveyn vb.) bildirim.
  static Future<void> sendChildLevelUpToFamily({
    required FirebaseFirestore firestore,
    required String childUid,
    required int newLevel,
  }) async {
    if (childUid.isEmpty || newLevel <= 1) return;
    final recipients = await _collectFamilyRecipientUserIds(
      firestore: firestore,
      actorUid: childUid,
    );
    if (recipients.isEmpty) return;
    final childName = await _fetchDisplayName(firestore, childUid);

    var batch = firestore.batch();
    var n = 0;
    for (final targetUid in recipients) {
      final ref = firestore
          .collection('users')
          .doc(targetUid)
          .collection('in_app_notifications')
          .doc();
      batch.set(
        ref,
        _notificationPayload(
          type: 'child_level_up',
          fromUid: childUid,
          actorDisplayName: childName,
          numberValue: newLevel,
        ),
      );
      n++;
      if (n >= 400) {
        await batch.commit();
        batch = firestore.batch();
        n = 0;
      }
    }
    if (n > 0) await batch.commit();
  }
}
