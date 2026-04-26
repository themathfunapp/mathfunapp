import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Ebeveynin hikâye modundan bir dünya/bölüm için ailedeki çocuğa gönderdiği davet.
class FamilyStoryInviteService {
  FamilyStoryInviteService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  static const String invitesCol = 'familyStoryInvites';
  static const String sessionsCol = 'familyStoryInviteSessions';
  static const int inviteTtlMs = 90000;

  Stream<QuerySnapshot<Map<String, dynamic>>> recipientInvitesStream(String toUserId) {
    return _db
        .collection(invitesCol)
        .where('toUserId', isEqualTo: toUserId)
        .snapshots();
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> sessionStream(String sessionId) {
    return _db.collection(sessionsCol).doc(sessionId).snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> senderUpdatesStream(String fromUserId) {
    return _db
        .collection(invitesCol)
        .where('fromUserId', isEqualTo: fromUserId)
        .where('status', whereIn: const ['declined', 'expired'])
        .snapshots();
  }

  Future<bool> createInvite({
    required String fromUserId,
    required String fromDisplayName,
    required String toUserId,
    required String toDisplayName,
    required String worldId,
    required String worldNameKey,
    required String chapterId,
    required String chapterNameKey,
    String levelId = '',
  }) async {
    return createGroupInvites(
      fromUserId: fromUserId,
      fromDisplayName: fromDisplayName,
      invites: [
        StoryInviteTarget(userId: toUserId, displayName: toDisplayName),
      ],
      worldId: worldId,
      worldNameKey: worldNameKey,
      chapterId: chapterId,
      chapterNameKey: chapterNameKey,
      levelId: levelId,
    );
  }

  Future<bool> createGroupInvites({
    required String fromUserId,
    required String fromDisplayName,
    required List<StoryInviteTarget> invites,
    required String worldId,
    required String worldNameKey,
    required String chapterId,
    required String chapterNameKey,
    String levelId = '',
  }) async {
    if (fromUserId.isEmpty ||
        invites.isEmpty ||
        worldId.isEmpty ||
        chapterId.isEmpty) {
      return false;
    }
    try {
      final validTargets = invites
          .where((i) => i.userId.isNotEmpty && i.userId != fromUserId)
          .toList();
      if (validTargets.isEmpty) return false;

      final sessionRef = _db.collection(sessionsCol).doc();
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      final expiresAtMs = nowMs + inviteTtlMs;

      final batch = _db.batch();
      batch.set(sessionRef, {
        'fromUserId': fromUserId,
        'fromDisplayName': fromDisplayName,
        'worldId': worldId,
        'worldNameKey': worldNameKey,
        'chapterId': chapterId,
        'chapterNameKey': chapterNameKey,
        'levelId': levelId,
        'invitedUserIds': validTargets.map((e) => e.userId).toList(),
        'acceptedUserIds': <String>[],
        'status': 'pending',
        'expiresAtMs': expiresAtMs,
        'createdAt': FieldValue.serverTimestamp(),
      });

      for (final t in validTargets) {
        final inviteRef = _db.collection(invitesCol).doc();
        batch.set(inviteRef, {
          'sessionId': sessionRef.id,
          'fromUserId': fromUserId,
          'fromDisplayName': fromDisplayName,
          'toUserId': t.userId,
          'toDisplayName': t.displayName,
          'worldId': worldId,
          'worldNameKey': worldNameKey,
          'chapterId': chapterId,
          'chapterNameKey': chapterNameKey,
          'levelId': levelId,
          'status': 'pending',
          'expiresAtMs': expiresAtMs,
          'senderAckAt': null,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
      return true;
    } catch (e) {
      debugPrint('FamilyStoryInvite createGroupInvites: $e');
      return false;
    }
  }

  Future<void> dismissInvite(String inviteId, String actingUserId) async {
    if (inviteId.isEmpty || actingUserId.isEmpty) return;
    try {
      final ref = _db.collection(invitesCol).doc(inviteId);
      final snap = await ref.get();
      if (!snap.exists) return;
      final d = snap.data()!;
      if (d['toUserId'] != actingUserId) return;
      if (d['status'] != 'pending') return;
      await ref.update({
        'status': 'dismissed',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('FamilyStoryInvite dismissInvite: $e');
    }
  }

  Future<bool> acceptInvite(String inviteId, String actingUserId) async {
    if (inviteId.isEmpty || actingUserId.isEmpty) return false;
    try {
      final ref = _db.collection(invitesCol).doc(inviteId);
      final ok = await _db.runTransaction<bool>((tx) async {
        final snap = await tx.get(ref);
        if (!snap.exists) return false;
        final d = snap.data()!;
        if (d['toUserId'] != actingUserId) return false;
        if ((d['status'] as String?) != 'pending') return false;

        final nowMs = DateTime.now().millisecondsSinceEpoch;
        final expiresAtMs = (d['expiresAtMs'] as num?)?.toInt() ?? 0;
        if (expiresAtMs > 0 && expiresAtMs <= nowMs) {
          tx.update(ref, {
            'status': 'expired',
            'updatedAt': FieldValue.serverTimestamp(),
          });
          return false;
        }

        final sessionId = (d['sessionId'] as String?) ?? '';
        if (sessionId.isEmpty) {
          tx.update(ref, {
            'status': 'accepted',
            'updatedAt': FieldValue.serverTimestamp(),
            'acceptedAt': FieldValue.serverTimestamp(),
            'startAtMs': nowMs + 5000,
          });
          return true;
        }
        final sessionRef = _db.collection(sessionsCol).doc(sessionId);
        final sessionSnap = await tx.get(sessionRef);
        if (!sessionSnap.exists) return false;
        final session = sessionSnap.data()!;
        final sessionStatus = (session['status'] as String?) ?? 'pending';
        if (sessionStatus != 'pending') {
          tx.update(ref, {
            'status': 'cancelled',
            'updatedAt': FieldValue.serverTimestamp(),
          });
          return false;
        }
        final invited = List<String>.from(session['invitedUserIds'] as List? ?? const []);
        final accepted = List<String>.from(session['acceptedUserIds'] as List? ?? const []);
        if (!accepted.contains(actingUserId)) {
          accepted.add(actingUserId);
        }
        final allAccepted = invited.isNotEmpty && accepted.length >= invited.length;
        final startAtMs = allAccepted ? nowMs + 5000 : null;
        tx.update(ref, {
          'status': 'accepted',
          'updatedAt': FieldValue.serverTimestamp(),
          'acceptedAt': FieldValue.serverTimestamp(),
          if (startAtMs != null) 'startAtMs': startAtMs,
        });
        tx.update(sessionRef, {
          'acceptedUserIds': accepted,
          if (allAccepted) ...{
            'status': 'active',
            'startAtMs': startAtMs,
          },
          'updatedAt': FieldValue.serverTimestamp(),
        });
        return true;
      });
      if (ok) {
        await _syncGroupStartIfReady(inviteId);
      }
      return ok;
    } catch (e) {
      debugPrint('FamilyStoryInvite acceptInvite: $e');
      return false;
    }
  }

  Future<void> declineInvite(String inviteId, String actingUserId) async {
    if (inviteId.isEmpty || actingUserId.isEmpty) return;
    try {
      final ref = _db.collection(invitesCol).doc(inviteId);
      final snap = await ref.get();
      if (!snap.exists) return;
      final d = snap.data()!;
      if (d['toUserId'] != actingUserId) return;
      if ((d['status'] as String?) != 'pending') return;
      final sessionId = (d['sessionId'] as String?) ?? '';
      await ref.update({
        'status': 'declined',
        'updatedAt': FieldValue.serverTimestamp(),
        'declinedAt': FieldValue.serverTimestamp(),
      });
      if (sessionId.isNotEmpty) {
        await _db.collection(sessionsCol).doc(sessionId).set({
          'status': 'cancelled',
          'cancelledBy': actingUserId,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint('FamilyStoryInvite declineInvite: $e');
    }
  }

  Future<void> expireInviteIfNeeded(String inviteId) async {
    if (inviteId.isEmpty) return;
    try {
      final ref = _db.collection(invitesCol).doc(inviteId);
      final snap = await ref.get();
      if (!snap.exists) return;
      final d = snap.data()!;
      if ((d['status'] as String?) != 'pending') return;
      final expiresAtMs = (d['expiresAtMs'] as num?)?.toInt() ?? 0;
      if (expiresAtMs > 0 && expiresAtMs <= DateTime.now().millisecondsSinceEpoch) {
        await ref.update({
          'status': 'expired',
          'updatedAt': FieldValue.serverTimestamp(),
        });
        final sessionId = (d['sessionId'] as String?) ?? '';
        if (sessionId.isNotEmpty) {
          await _db.collection(sessionsCol).doc(sessionId).set({
            'status': 'expired',
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        }
      }
    } catch (e) {
      debugPrint('FamilyStoryInvite expireInviteIfNeeded: $e');
    }
  }

  Future<void> cancelInviteForUser({
    required String inviteId,
    required String actingUserId,
  }) async {
    if (inviteId.isEmpty || actingUserId.isEmpty) return;
    try {
      final ref = _db.collection(invitesCol).doc(inviteId);
      final snap = await ref.get();
      if (!snap.exists) return;
      final d = snap.data()!;
      if (d['toUserId'] != actingUserId) return;
      final status = d['status'] as String? ?? '';
      if (status != 'pending' && status != 'accepted') return;
      await ref.update({
        'status': 'cancelled',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('FamilyStoryInvite cancelInviteForUser: $e');
    }
  }

  Future<void> acknowledgeSenderUpdate({
    required String inviteId,
    required String actingUserId,
  }) async {
    if (inviteId.isEmpty || actingUserId.isEmpty) return;
    try {
      final ref = _db.collection(invitesCol).doc(inviteId);
      final snap = await ref.get();
      if (!snap.exists) return;
      final d = snap.data()!;
      if (d['fromUserId'] != actingUserId) return;
      final status = d['status'] as String? ?? '';
      if (status != 'declined' && status != 'expired') return;
      if (d['senderAckAt'] != null) return;
      await ref.update({
        'senderAckAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('FamilyStoryInvite acknowledgeSenderUpdate: $e');
    }
  }

  Future<void> _syncGroupStartIfReady(String inviteId) async {
    try {
      final invite = await _db.collection(invitesCol).doc(inviteId).get();
      if (!invite.exists) return;
      final sessionId = (invite.data()?['sessionId'] as String?) ?? '';
      if (sessionId.isEmpty) return;
      final session = await _db.collection(sessionsCol).doc(sessionId).get();
      if (!session.exists) return;
      final data = session.data()!;
      final status = (data['status'] as String?) ?? '';
      final startAtMs = (data['startAtMs'] as num?)?.toInt();
      if (status != 'active' || startAtMs == null) return;
      final accepted = await _db
          .collection(invitesCol)
          .where('sessionId', isEqualTo: sessionId)
          .where('status', isEqualTo: 'accepted')
          .get();
      final batch = _db.batch();
      for (final d in accepted.docs) {
        batch.update(d.reference, {
          'startAtMs': startAtMs,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
    } catch (e) {
      debugPrint('FamilyStoryInvite _syncGroupStartIfReady: $e');
    }
  }
}

class StoryInviteTarget {
  const StoryInviteTarget({
    required this.userId,
    required this.displayName,
  });

  final String userId;
  final String displayName;
}
