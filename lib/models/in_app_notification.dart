import 'package:cloud_firestore/cloud_firestore.dart';

class InAppNotificationItem {
  final String id;
  final String type;
  final String fromUid;
  final String oldDisplayName;
  final String newDisplayName;
  final bool read;
  final DateTime? createdAt;

  const InAppNotificationItem({
    required this.id,
    required this.type,
    required this.fromUid,
    required this.oldDisplayName,
    required this.newDisplayName,
    required this.read,
    this.createdAt,
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
    );
  }
}
