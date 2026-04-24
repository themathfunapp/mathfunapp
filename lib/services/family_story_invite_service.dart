import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Ebeveynin hikâye modundan bir dünya/bölüm için ailedeki çocuğa gönderdiği davet.
class FamilyStoryInviteService {
  FamilyStoryInviteService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  static const String invitesCol = 'familyStoryInvites';

  Stream<QuerySnapshot<Map<String, dynamic>>> pendingInvitesStream(String toUserId) {
    return _db
        .collection(invitesCol)
        .where('toUserId', isEqualTo: toUserId)
        .where('status', isEqualTo: 'pending')
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
    if (fromUserId.isEmpty ||
        toUserId.isEmpty ||
        fromUserId == toUserId ||
        worldId.isEmpty ||
        chapterId.isEmpty) {
      return false;
    }
    try {
      await _db.collection(invitesCol).add({
        'fromUserId': fromUserId,
        'fromDisplayName': fromDisplayName,
        'toUserId': toUserId,
        'toDisplayName': toDisplayName,
        'worldId': worldId,
        'worldNameKey': worldNameKey,
        'chapterId': chapterId,
        'chapterNameKey': chapterNameKey,
        'levelId': levelId,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      debugPrint('FamilyStoryInvite createInvite: $e');
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
}
