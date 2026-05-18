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
    this.sessionId = '',
    this.expiresAtMs = 0,
  });

  final String id;
  final String fromUserId;
  final String fromDisplayName;
  final String? fromUserCode;
  final String toUserId;
  final DateTime createdAt;
  final String status;
  final String sessionId;
  final int expiresAtMs;

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
      sessionId: m['sessionId'] as String? ?? '',
      expiresAtMs: (m['expiresAtMs'] as num?)?.toInt() ?? 0,
    );
  }

  int get secondsRemaining {
    if (expiresAtMs <= 0) return 0;
    final left = expiresAtMs - DateTime.now().millisecondsSinceEpoch;
    return (left / 1000).ceil().clamp(0, FriendDuelInvite.ttlSeconds);
  }

  static const int ttlSeconds = 90;

  bool get isExpired {
    final now = DateTime.now().millisecondsSinceEpoch;
    if (expiresAtMs > 0) return now > expiresAtMs;
    return DateTime.now().difference(createdAt).inSeconds > ttlSeconds;
  }
}
