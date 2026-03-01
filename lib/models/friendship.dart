import 'package:cloud_firestore/cloud_firestore.dart';

class Friendship {
  final String id;
  final String friendId; // Arkadaşın kullanıcı ID'si
  final String friendName; // Arkadaşın adı
  final String? friendPhotoUrl;
  final String? friendEmail;
  final String? friendUserCode; // Arkadaşın RKN kodu
  final DateTime friendsSince;
  final bool isOnline;
  final DateTime? lastSeen;

  Friendship({
    required this.id,
    required this.friendId,
    required this.friendName,
    this.friendPhotoUrl,
    this.friendEmail,
    this.friendUserCode,
    required this.friendsSince,
    this.isOnline = false,
    this.lastSeen,
  });

  factory Friendship.fromMap(Map<String, dynamic> map, String docId) {
    return Friendship(
      id: docId,
      friendId: map['friendId'] ?? '',
      friendName: map['friendName'] ?? '',
      friendPhotoUrl: map['friendPhotoUrl'],
      friendEmail: map['friendEmail'],
      friendUserCode: map['friendUserCode'],
      friendsSince: map['friendsSince'] is Timestamp
          ? (map['friendsSince'] as Timestamp).toDate()
          : DateTime.parse(map['friendsSince']),
      isOnline: map['isOnline'] ?? false,
      lastSeen: map['lastSeen'] != null
          ? (map['lastSeen'] is Timestamp
              ? (map['lastSeen'] as Timestamp).toDate()
              : DateTime.parse(map['lastSeen']))
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'friendId': friendId,
      'friendName': friendName,
      'friendPhotoUrl': friendPhotoUrl,
      'friendEmail': friendEmail,
      'friendUserCode': friendUserCode,
      'friendsSince': Timestamp.fromDate(friendsSince),
      'isOnline': isOnline,
      'lastSeen': lastSeen != null ? Timestamp.fromDate(lastSeen!) : null,
    };
  }

  Friendship copyWith({
    String? id,
    String? friendId,
    String? friendName,
    String? friendPhotoUrl,
    String? friendEmail,
    String? friendUserCode,
    DateTime? friendsSince,
    bool? isOnline,
    DateTime? lastSeen,
  }) {
    return Friendship(
      id: id ?? this.id,
      friendId: friendId ?? this.friendId,
      friendName: friendName ?? this.friendName,
      friendPhotoUrl: friendPhotoUrl ?? this.friendPhotoUrl,
      friendEmail: friendEmail ?? this.friendEmail,
      friendUserCode: friendUserCode ?? this.friendUserCode,
      friendsSince: friendsSince ?? this.friendsSince,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen ?? this.lastSeen,
    );
  }
}

