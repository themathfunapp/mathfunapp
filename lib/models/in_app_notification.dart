import 'package:cloud_firestore/cloud_firestore.dart';

class InAppNotificationItem {
  final String id;
  final String type;
  final String fromUid;
  final String oldDisplayName;
  final String newDisplayName;
  final bool read;
  final DateTime? createdAt;
  /// Çocuk / ebeveyn görünen adı (rozet, günlük görev, hikâye, rapor metinleri için).
  final String actorDisplayName;
  final String badgeNameKey;
  final String worldNameKey;
  final String chapterNameKey;
  /// Bazı bildirim tipleri için ek sayısal değer (örn. seviye).
  final int numberValue;
  /// Bazı bildirim tipleri için anahtar (örn. düello konu anahtarı).
  final String topicKey;

  const InAppNotificationItem({
    required this.id,
    required this.type,
    required this.fromUid,
    required this.oldDisplayName,
    required this.newDisplayName,
    required this.read,
    this.createdAt,
    this.actorDisplayName = '',
    this.badgeNameKey = '',
    this.worldNameKey = '',
    this.chapterNameKey = '',
    this.numberValue = 0,
    this.topicKey = '',
  });

  factory InAppNotificationItem.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    final created = data['createdAt'];
    DateTime? at;
    if (created is Timestamp) {
      at = created.toDate();
    }
    return InAppNotificationItem(
      id: doc.id,
      type: data['type'] as String? ?? '',
      fromUid: data['fromUid'] as String? ?? '',
      oldDisplayName: data['oldDisplayName'] as String? ?? '',
      newDisplayName: data['newDisplayName'] as String? ?? '',
      read: data['read'] as bool? ?? false,
      createdAt: at,
      actorDisplayName: data['actorDisplayName'] as String? ?? '',
      badgeNameKey: data['badgeNameKey'] as String? ?? '',
      worldNameKey: data['worldNameKey'] as String? ?? '',
      chapterNameKey: data['chapterNameKey'] as String? ?? '',
      numberValue: (data['numberValue'] as num?)?.toInt() ?? 0,
      topicKey: data['topicKey'] as String? ?? '',
    );
  }
}
