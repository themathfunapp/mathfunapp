import 'package:cloud_firestore/cloud_firestore.dart';

enum FriendRequestStatus {
  pending,
  accepted,
  rejected,
}

class FriendRequest {
  final String id;
  final String senderId;
  final String senderName;
  final String? senderPhotoUrl;
  final String? senderUserCode;
  final String receiverId;
  final String receiverName;
  final String? receiverPhotoUrl;
  final String? receiverUserCode;
  final FriendRequestStatus status;
  final DateTime createdAt;
  final DateTime? respondedAt;

  FriendRequest({
    required this.id,
    required this.senderId,
    required this.senderName,
    this.senderPhotoUrl,
    this.senderUserCode,
    required this.receiverId,
    required this.receiverName,
    this.receiverPhotoUrl,
    this.receiverUserCode,
    this.status = FriendRequestStatus.pending,
    required this.createdAt,
    this.respondedAt,
  });

  factory FriendRequest.fromMap(Map<String, dynamic> map, String docId) {
    return FriendRequest(
      id: docId,
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'] ?? '',
      senderPhotoUrl: map['senderPhotoUrl'],
      senderUserCode: map['senderUserCode'],
      receiverId: map['receiverId'] ?? '',
      receiverName: map['receiverName'] ?? '',
      receiverPhotoUrl: map['receiverPhotoUrl'],
      receiverUserCode: map['receiverUserCode'],
      status: FriendRequestStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => FriendRequestStatus.pending,
      ),
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.parse(map['createdAt']),
      respondedAt: map['respondedAt'] != null
          ? (map['respondedAt'] is Timestamp
              ? (map['respondedAt'] as Timestamp).toDate()
              : DateTime.parse(map['respondedAt']))
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'senderName': senderName,
      'senderPhotoUrl': senderPhotoUrl,
      'senderUserCode': senderUserCode,
      'receiverId': receiverId,
      'receiverName': receiverName,
      'receiverPhotoUrl': receiverPhotoUrl,
      'receiverUserCode': receiverUserCode,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'respondedAt': respondedAt != null ? Timestamp.fromDate(respondedAt!) : null,
    };
  }

  FriendRequest copyWith({
    String? id,
    String? senderId,
    String? senderName,
    String? senderPhotoUrl,
    String? senderUserCode,
    String? receiverId,
    String? receiverName,
    String? receiverPhotoUrl,
    String? receiverUserCode,
    FriendRequestStatus? status,
    DateTime? createdAt,
    DateTime? respondedAt,
  }) {
    return FriendRequest(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderPhotoUrl: senderPhotoUrl ?? this.senderPhotoUrl,
      senderUserCode: senderUserCode ?? this.senderUserCode,
      receiverId: receiverId ?? this.receiverId,
      receiverName: receiverName ?? this.receiverName,
      receiverPhotoUrl: receiverPhotoUrl ?? this.receiverPhotoUrl,
      receiverUserCode: receiverUserCode ?? this.receiverUserCode,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      respondedAt: respondedAt ?? this.respondedAt,
    );
  }
}

