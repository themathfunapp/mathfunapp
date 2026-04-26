import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/game_mechanics.dart';
import '../models/age_group_selection.dart';
import '../utils/family_duel_question_utils.dart';

/// Uzaktan aile düellosu: Firestore üzerinden aynı soru seti, iki cihaz.
///
/// Güvenlik: Üretimde Firestore kurallarında yalnızca `hostUserId` / `guestUserId`
/// olan kullanıcıların ilgili oturum ve davet belgelerini okuyup yazmasına izin verin.
class FamilyRemoteDuelService {
  FamilyRemoteDuelService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  static const String invitesCol = 'familyRemoteDuelInvites';
  static const String sessionsCol = 'familyRemoteDuelSessions';
  static const int inviteTtlSeconds = 90;
  static const int remoteQuestionCount = 10;

  /// Çocuk hesabı: davetler (istemci tarafında `status == pending` süzülür; ek indeks gerekmez).
  Stream<QuerySnapshot<Map<String, dynamic>>> pendingInvitesStream(String userId) {
    return _db.collection(invitesCol).where('toUserId', isEqualTo: userId).snapshots();
  }

  Future<bool> readUserPremiumFlag(String uid) async {
    if (uid.isEmpty) return false;
    try {
      final d = await _db.collection('users').doc(uid).get();
      return d.data()?['isPremium'] == true;
    } catch (e) {
      debugPrint('FamilyRemoteDuel readUserPremiumFlag: $e');
      return false;
    }
  }

  /// `users/{hostUid}/family/members` → `childUserIds` içinde çocuk var mı? (Firestore kuralları ile uyumlu.)
  Future<bool> hostHasLinkedChildOnAccount(String hostUid, String childUid) async {
    if (hostUid.isEmpty || childUid.isEmpty) return false;
    try {
      final doc = await _db
          .collection('users')
          .doc(hostUid)
          .collection('family')
          .doc('members')
          .get();
      if (!doc.exists) return false;
      final raw = doc.data()?['childUserIds'];
      if (raw is! List) return false;
      for (final e in raw) {
        if (e?.toString() == childUid) return true;
      }
      return false;
    } catch (e) {
      debugPrint('FamilyRemoteDuel hostHasLinkedChildOnAccount: $e');
      return false;
    }
  }

  /// `childUserIds` kümesi (boş olabilir).
  Future<Set<String>> linkedChildUserIdsForHost(String hostUid) async {
    if (hostUid.isEmpty) return {};
    try {
      final doc = await _db
          .collection('users')
          .doc(hostUid)
          .collection('family')
          .doc('members')
          .get();
      if (!doc.exists) return {};
      final raw = doc.data()?['childUserIds'];
      if (raw is! List) return {};
      return raw.map((e) => e?.toString() ?? '').where((s) => s.isNotEmpty).toSet();
    } catch (e) {
      debugPrint('FamilyRemoteDuel linkedChildUserIdsForHost: $e');
      return {};
    }
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> sessionStream(String sessionId) {
    return _db.collection(sessionsCol).doc(sessionId).snapshots();
  }

  List<Map<String, dynamic>> _generateQuestions(TopicType topic, int seed) {
    final out = <Map<String, dynamic>>[];
    for (var i = 0; i < remoteQuestionCount; i++) {
      final r = math.Random(seed + i * 1000003);
      final q = TopicGameManager.generateTopicQuestion(
        topic,
        AgeGroupSelection.elementary,
        r,
      );
      out.add(sanitizeQuestionForStorage(Map<String, dynamic>.from(q)));
    }
    return out;
  }

  int _nowMs() => DateTime.now().millisecondsSinceEpoch;

  bool _isExpiredFromData(Map<String, dynamic> data) {
    final expiresAtMs = (data['expiresAtMs'] as num?)?.toInt() ?? 0;
    return expiresAtMs > 0 && _nowMs() > expiresAtMs;
  }

  /// Premium ebeveyn bir veya daha fazla çocuğa davet oluşturur.
  /// Oturum, tüm davetliler kabul edince `active` olur.
  Future<({String sessionId, List<String> inviteIds})?> createInvite({
    required String hostUserId,
    required String hostDisplayName,
    required List<String> guestUserIds,
    required Map<String, String> guestDisplayNamesById,
    required TopicType topic,
  }) async {
    final normalizedGuests = guestUserIds
        .where((id) => id.isNotEmpty && id != hostUserId)
        .toSet()
        .toList();
    if (hostUserId.isEmpty || normalizedGuests.isEmpty) {
      return null;
    }

    final hostPremium = await readUserPremiumFlag(hostUserId);
    if (!hostPremium) {
      debugPrint('FamilyRemoteDuel: her iki hesapta da Premium (Firestore isPremium) gerekli.');
      return null;
    }
    for (final guestUserId in normalizedGuests) {
      final guestPremium = await readUserPremiumFlag(guestUserId);
      if (!guestPremium) return null;
    }

    final seed = DateTime.now().millisecondsSinceEpoch ^
        hostUserId.hashCode ^
        normalizedGuests.fold<int>(0, (a, b) => a ^ b.hashCode);
    final questions = _generateQuestions(topic, seed);
    final sessionRef = _db.collection(sessionsCol).doc();
    final expiresAtMs = _nowMs() + inviteTtlSeconds * 1000;
    final inviteRefs = normalizedGuests.map((_) => _db.collection(invitesCol).doc()).toList();

    try {
      await _db.runTransaction((tx) async {
        final participantUserIds = <String>[hostUserId, ...normalizedGuests];
        final participantDisplayNames = <String, String>{
          hostUserId: hostDisplayName,
          for (final id in normalizedGuests)
            id: guestDisplayNamesById[id] ?? 'Aile üyesi',
        };
        tx.set(sessionRef, {
          'hostUserId': hostUserId,
          'hostDisplayName': hostDisplayName,
          'guestUserId': normalizedGuests.first,
          'guestDisplayName': guestDisplayNamesById[normalizedGuests.first] ?? 'Çocuk',
          'invitedUserIds': normalizedGuests,
          'acceptedUserIds': <String>[],
          'participantUserIds': participantUserIds,
          'participantDisplayNames': participantDisplayNames,
          'topicKey': topic.name,
          'questionSeed': seed,
          'questions': questions,
          'status': 'waiting_accept',
          'currentRoundIndex': 0,
          'roundAnsweredUserIds': <String>[],
          'correctCounts': <String, int>{
            for (final id in participantUserIds) id: 0,
          },
          'leaderboardSynced': false,
          'expiresAtMs': expiresAtMs,
          'createdAt': FieldValue.serverTimestamp(),
        });

        for (var i = 0; i < normalizedGuests.length; i++) {
          final guestUserId = normalizedGuests[i];
          tx.set(inviteRefs[i], {
            'fromUserId': hostUserId,
            'fromDisplayName': hostDisplayName,
            'toUserId': guestUserId,
            'toDisplayName': guestDisplayNamesById[guestUserId] ?? 'Çocuk',
            'topicKey': topic.name,
            'sessionId': sessionRef.id,
            'status': 'pending',
            'expiresAtMs': expiresAtMs,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
      });
      return (
        sessionId: sessionRef.id,
        inviteIds: inviteRefs.map((e) => e.id).toList(),
      );
    } catch (e) {
      debugPrint('FamilyRemoteDuel createInvite: $e');
      return null;
    }
  }

  Future<bool> acceptInvite({
    required String inviteId,
    required String acceptingUserId,
  }) async {
    if (!await readUserPremiumFlag(acceptingUserId)) return false;
    final inviteRef = _db.collection(invitesCol).doc(inviteId);

    try {
      await _db.runTransaction((tx) async {
        final inv = await tx.get(inviteRef);
        if (!inv.exists) throw Exception('no_invite');
        final d = inv.data()!;
        if (d['toUserId'] != acceptingUserId) throw Exception('not_receiver');
        if (d['status'] != 'pending') throw Exception('not_pending');
        if (_isExpiredFromData(d)) {
          tx.update(inviteRef, {
            'status': 'expired',
            'respondedAt': FieldValue.serverTimestamp(),
          });
          throw Exception('invite_expired');
        }
        final sessionId = d['sessionId'] as String? ?? '';
        if (sessionId.isEmpty) throw Exception('no_session');

        final sessionRef = _db.collection(sessionsCol).doc(sessionId);
        final s = await tx.get(sessionRef);
        if (!s.exists) throw Exception('no_session_doc');
        final sd = s.data()!;
        if (sd['status'] != 'waiting_accept') throw Exception('bad_session_status');
        if (_isExpiredFromData(sd)) {
          tx.update(inviteRef, {
            'status': 'expired',
            'respondedAt': FieldValue.serverTimestamp(),
          });
          tx.update(sessionRef, {
            'status': 'expired',
            'cancelReason': 'invite_timeout',
          });
          throw Exception('session_expired');
        }

        final invited = (sd['invitedUserIds'] as List<dynamic>? ?? const [])
            .map((e) => e.toString())
            .where((e) => e.isNotEmpty)
            .toSet();
        if (!invited.contains(acceptingUserId)) throw Exception('not_invited');
        final accepted = (sd['acceptedUserIds'] as List<dynamic>? ?? const [])
            .map((e) => e.toString())
            .where((e) => e.isNotEmpty)
            .toSet();
        accepted.add(acceptingUserId);

        final everyoneAccepted = accepted.length == invited.length && invited.isNotEmpty;
        tx.update(inviteRef, {
          'status': 'accepted',
          'respondedAt': FieldValue.serverTimestamp(),
        });
        tx.update(sessionRef, {
          'acceptedUserIds': accepted.toList(),
          if (everyoneAccepted) 'status': 'active',
          if (everyoneAccepted) 'startedAt': FieldValue.serverTimestamp(),
        });
      });
      return true;
    } catch (e) {
      debugPrint('FamilyRemoteDuel acceptInvite: $e');
      return false;
    }
  }

  Future<void> declineInvite(String inviteId, String userId) async {
    try {
      final ref = _db.collection(invitesCol).doc(inviteId);
      String sessionId = '';
      await _db.runTransaction((tx) async {
        final inv = await tx.get(ref);
        if (!inv.exists) return;
        final d = inv.data()!;
        if (d['toUserId'] != userId) return;
        if (d['status'] != 'pending') return;
        sessionId = (d['sessionId'] as String?) ?? '';
        tx.update(ref, {
          'status': 'declined',
          'respondedAt': FieldValue.serverTimestamp(),
        });
        if (sessionId.isNotEmpty) {
          tx.update(_db.collection(sessionsCol).doc(sessionId), {
            'status': 'cancelled',
            'cancelReason': 'declined',
          });
        }
      });

      // Bir üye reddettiyse aynı oturuma ait diğer bekleyen davetleri de kapat.
      if (sessionId.isNotEmpty) {
        final pending = await _db
            .collection(invitesCol)
            .where('sessionId', isEqualTo: sessionId)
            .where('status', isEqualTo: 'pending')
            .get();
        for (final doc in pending.docs) {
          await doc.reference.update({
            'status': 'cancelled',
            'respondedAt': FieldValue.serverTimestamp(),
          });
        }
      }
    } catch (e) {
      debugPrint('FamilyRemoteDuel declineInvite: $e');
    }
  }

  /// Cevabı işler; doğruluk sunucu tarafında sorudan hesaplanır.
  Future<bool> submitAnswer({
    required String sessionId,
    required String userId,
    required dynamic pickedValue,
  }) async {
    final sessionRef = _db.collection(sessionsCol).doc(sessionId);

    try {
      await _db.runTransaction((tx) async {
        final snap = await tx.get(sessionRef);
        if (!snap.exists) return;
        final data = snap.data()!;
        if (data['status'] != 'active') return;

        final participantUserIds = (data['participantUserIds'] as List<dynamic>? ?? const [])
            .map((e) => e.toString())
            .where((e) => e.isNotEmpty)
            .toList();
        if (!participantUserIds.contains(userId)) return;

        final roundIdx = (data['currentRoundIndex'] as num?)?.toInt() ?? 0;
        final questionsRaw = data['questions'];
        final questions = decodeQuestionsList(questionsRaw);
        if (questions.isEmpty || roundIdx >= questions.length) return;

        final answeredSet = (data['roundAnsweredUserIds'] as List<dynamic>? ?? const [])
            .map((e) => e.toString())
            .toSet();
        if (answeredSet.contains(userId)) return;

        final q = questions[roundIdx];
        final correct = familyDuelIsCorrect(q, pickedValue);

        final countsRaw = (data['correctCounts'] as Map?) ?? const {};
        final counts = <String, int>{
          for (final entry in countsRaw.entries)
            entry.key.toString(): (entry.value as num?)?.toInt() ?? 0,
        };
        for (final id in participantUserIds) {
          counts.putIfAbsent(id, () => 0);
        }
        if (correct) counts[userId] = (counts[userId] ?? 0) + 1;
        answeredSet.add(userId);

        var nextRound = roundIdx;
        var nextAnswered = answeredSet.toList();

        if (answeredSet.length == participantUserIds.length) {
          if (roundIdx >= questions.length - 1) {
            final hostUid = data['hostUserId'] as String? ?? '';
            final guestUid = data['guestUserId'] as String? ?? '';
            tx.update(sessionRef, {
              'roundAnsweredUserIds': answeredSet.toList(),
              'correctCounts': counts,
              'hostCorrectCount': counts[hostUid] ?? 0,
              'guestCorrectCount': counts[guestUid] ?? 0,
              'status': 'finished',
              'finishedAt': FieldValue.serverTimestamp(),
            });
            return;
          }
          nextRound = roundIdx + 1;
          nextAnswered = <String>[];
        }

        tx.update(sessionRef, {
          'roundAnsweredUserIds': nextAnswered,
          'correctCounts': counts,
          'currentRoundIndex': nextRound,
        });
      });

      return true;
    } catch (e) {
      debugPrint('FamilyRemoteDuel submitAnswer: $e');
      return false;
    }
  }

  Future<void> markLeaderboardSynced(String sessionId) async {
    try {
      await _db.collection(sessionsCol).doc(sessionId).update({'leaderboardSynced': true});
    } catch (e) {
      debugPrint('FamilyRemoteDuel markLeaderboardSynced: $e');
    }
  }

  /// Ebeveyn beklemeden vazgeçerse.
  Future<void> cancelPendingSession(String sessionId, String hostUserId) async {
    try {
      final ref = _db.collection(sessionsCol).doc(sessionId);
      await _db.runTransaction((tx) async {
        final s = await tx.get(ref);
        if (!s.exists) return;
        final d = s.data()!;
        if (d['hostUserId'] != hostUserId) return;
        if (d['status'] != 'waiting_accept') return;
        tx.update(ref, {
          'status': 'cancelled',
          'cancelReason': 'host_cancelled',
        });
      });

      final inv = await _db
          .collection(invitesCol)
          .where('sessionId', isEqualTo: sessionId)
          .limit(20)
          .get();
      for (final doc in inv.docs) {
        final st = doc.data()['status'] as String?;
        if (st != 'pending') continue;
        await doc.reference.update({
          'status': 'cancelled',
          'respondedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      debugPrint('FamilyRemoteDuel cancelPendingSession: $e');
    }
  }
}
