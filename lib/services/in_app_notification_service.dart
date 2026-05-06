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

  void initialize(AppUser? user) {
    _sub?.cancel();
    _sub = null;
    _userId = user?.uid;

    if (user == null || user.isGuest || user.uid.isEmpty) {
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
}
