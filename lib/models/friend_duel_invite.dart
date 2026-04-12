import 'package:cloud_firestore/cloud_firestore.dart';

/// Arkadaşlar arası düello daveti (`friendDuelInvites` koleksiyonu).
class FriendDuelInvite {
  FriendDuelInvite({
    required this.id,
    required this.fromUserId,
    required this.fromDisplayName,
    this.fromUserCode,
    required this.toUserId,
    required this.createdAt,
    this.status = 'pending',
  });

  final String id;
  final String fromUserId;
  final String fromDisplayName;
  final String? fromUserCode;
  final String toUserId;
  final DateTime createdAt;
  final String status;

  factory FriendDuelInvite.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final m = doc.data() ?? {};
    final created = m['createdAt'];
    return FriendDuelInvite(
      id: doc.id,
      fromUserId: m['fromUserId'] as String? ?? '',
      fromDisplayName: m['fromDisplayName'] as String? ?? '',
      fromUserCode: m['fromUserCode'] as String?,
      toUserId: m['toUserId'] as String? ?? '',
      createdAt: created is Timestamp
          ? created.toDate()
          : DateTime.tryParse(created?.toString() ?? '') ?? DateTime.now(),
      status: m['status'] as String? ?? 'pending',
    );
  }

  Map<String, dynamic> toCreateMap() {
    return {
      'fromUserId': fromUserId,
      'fromDisplayName': fromDisplayName,
      'fromUserCode': fromUserCode,
      'toUserId': toUserId,
      'status': status,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
