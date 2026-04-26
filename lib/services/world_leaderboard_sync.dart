import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore koleksiyonları — sorguda `.limit(100)` ile en iyi 100 oyuncu listelenir.
const String kWorldCoinsLeaderboard = 'worldCoinsLeaderboard';
const String kWorldDiamondsLeaderboard = 'worldDiamondsLeaderboard';

const int kWorldLeaderboardQueryLimit = 100;

/// Altın ve elmas bakiyelerini dünya sıralama koleksiyonlarına yazar (yalnızca giriş yapmış UID).
Future<void> publishWorldLeaderboardScores({
  required FirebaseFirestore firestore,
  required String userId,
  required int coins,
  required int diamonds,
  String? displayName,
  String? profileEmoji,
}) async {
  if (userId.isEmpty) return;

  var name = (displayName ?? '').trim();
  String? emoji = profileEmoji;
  if (name.isEmpty) {
    try {
      final snap = await firestore.collection('users').doc(userId).get();
      final m = snap.data();
      name = (m?['displayName'] as String?)?.trim() ?? '';
      if (name.isEmpty && m?['email'] is String) {
        final em = m!['email'] as String;
        final at = em.indexOf('@');
        if (at > 0) name = em.substring(0, at);
      }
      emoji ??= m?['profileEmoji'] as String?;
    } catch (_) {}
  }
  if (name.isEmpty) name = 'Oyuncu';
  if (name.length > 80) name = name.substring(0, 80);

  final c = coins < 0 ? 0 : coins;
  final d = diamonds < 0 ? 0 : diamonds;

  final batch = firestore.batch();
  batch.set(
    firestore.collection(kWorldCoinsLeaderboard).doc(userId),
    {
      'displayName': name,
      'profileEmoji': emoji,
      'coins': c,
      'updatedAt': FieldValue.serverTimestamp(),
    },
    SetOptions(merge: true),
  );
  batch.set(
    firestore.collection(kWorldDiamondsLeaderboard).doc(userId),
    {
      'displayName': name,
      'profileEmoji': emoji,
      'diamonds': d,
      'updatedAt': FieldValue.serverTimestamp(),
    },
    SetOptions(merge: true),
  );
  await batch.commit();
}
