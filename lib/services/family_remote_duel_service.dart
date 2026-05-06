import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../config/premium_qa_allowlist.dart';
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
  static const int winnerGoldCoins = 5;
  /// Her oyuncunun sırayla cevaplaması için süre penceresi (ms).
  static const int turnAnswerWindowMs = 10000;

  /// Oturum belgesindeki katılımcı UID'leri (feragat / UI); alan bozuksa host+davetlilerden türetilir.
  static List<String> duelParticipantIds(Map<String, dynamic> data) {
    final fromDoc = (data['participantUserIds'] as List<dynamic>? ?? const [])
        .map((e) => e.toString().trim())
        .where((e) => e.isNotEmpty)
        .toList();
    if (fromDoc.isNotEmpty) return fromDoc;
    return _answerOrderFromSession(data);
  }

  static List<String> _answerOrderFromSession(Map<String, dynamic> data) {
    final host = (data['hostUserId'] as String?) ?? '';
    final invited = (data['invitedUserIds'] as List<dynamic>? ?? const [])
        .map((e) => e.toString())
        .where((e) => e.isNotEmpty)
        .toList();
    final out = <String>[];
    final seen = <String>{};
    for (final id in <String>[host, ...invited]) {
      if (id.isEmpty || seen.contains(id)) continue;
      seen.add(id);
      out.add(id);
    }
    return out;
  }

  static String? _expectedAnswerer(List<String> order, Set<String> answered) {
    for (final id in order) {
      if (!answered.contains(id)) return id;
    }
    return null;
  }

  /// Süre doldu cevabı (şıklarda olmayan sayı — her zaman yanlış sayılır).
  static const int timeoutWrongPick = -999999999;

  /// Çocuk hesabı: davetler (istemci tarafında `status == pending` süzülür; ek indeks gerekmez).
  Stream<QuerySnapshot<Map<String, dynamic>>> pendingInvitesStream(String userId) {
    return _db.collection(invitesCol).where('toUserId', isEqualTo: userId).snapshots();
  }

  /// [clientUserCode]: Giriş yapmış kullanıcının bellekteki MTN kodu (Firestore ile uyumsuzluklarda QA listesi için).
  Future<bool> readUserPremiumFlag(String uid, {String? clientUserCode}) async {
    if (uid.isEmpty) return false;
    if (premiumQaAllowlistedUserCode(clientUserCode)) return true;
    try {
      final d = await _db.collection('users').doc(uid).get();
      final data = d.data();
      if (data == null) return false;
      if (premiumQaAllowlistedFromUserDoc(data)) return true;

      final isPremium = data['isPremium'] == true;
      final expiresRaw = data['premiumExpiresAt'];
      if (isPremium && expiresRaw != null) {
        try {
          final expiry = DateTime.parse(expiresRaw.toString());
          return expiry.isAfter(DateTime.now());
        } catch (_) {
          return false;
        }
      }
      return isPremium;
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

  /// Tek seferlik oturum durumu (kabul sonrası doğrudan oyuna geçiş için).
  Future<String?> readSessionStatus(String sessionId) async {
    if (sessionId.isEmpty) return null;
    try {
      final d = await _db.collection(sessionsCol).doc(sessionId).get();
      return d.data()?['status'] as String?;
    } catch (e) {
      debugPrint('FamilyRemoteDuel readSessionStatus: $e');
      return null;
    }
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
      debugPrint('FamilyRemoteDuel: host Premium (Firestore / QA) gerekli.');
      return null;
    }
    for (final guestUserId in normalizedGuests) {
      final guestPremium = await readUserPremiumFlag(guestUserId);
      if (!guestPremium) {
        debugPrint('FamilyRemoteDuel: davetli $guestUserId için Premium doğrulanamadı.');
        return null;
      }
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
          'rewardClaimedUserIds': <String>[],
          'expiresAtMs': expiresAtMs,
          'turnDeadlineAtMs': 0,
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
    String? acceptingUserCode,
  }) async {
    if (!await readUserPremiumFlag(
      acceptingUserId,
      clientUserCode: acceptingUserCode,
    )) {
      debugPrint(
        'FamilyRemoteDuel acceptInvite: premium yok (uid=$acceptingUserId, '
        'clientCode=$acceptingUserCode)',
      );
      return false;
    }
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
          if (everyoneAccepted) 'turnDeadlineAtMs': _nowMs() + turnAnswerWindowMs,
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

  /// Davet süresi (ör. 90 sn) dolduğunda davetli cihazdan çağrılır: davet `expired`, oturum `waiting_accept` ise `expired`, ebeveyne uygulama içi bildirim.
  /// [true]: davet gerçekten `expired` olarak güncellendi (ağ/kural hatasında [false]).
  Future<bool> expirePendingInviteDueToTimeout({
    required String inviteId,
    required String inviteeUserId,
    required String inviteeDisplayName,
  }) async {
    if (inviteId.isEmpty || inviteeUserId.isEmpty) return false;
    final inviteRef = _db.collection(invitesCol).doc(inviteId);
    String? hostUid;
    String sessionId = '';
    var expiredInvite = false;
    try {
      await _db.runTransaction((tx) async {
        final inv = await tx.get(inviteRef);
        if (!inv.exists) return;
        final d = inv.data()!;
        if (d['toUserId'] != inviteeUserId) return;
        if (d['status'] != 'pending') return;
        if (!_isExpiredFromData(d)) return;

        hostUid = d['fromUserId'] as String?;
        sessionId = (d['sessionId'] as String?) ?? '';

        tx.update(inviteRef, {
          'status': 'expired',
          'respondedAt': FieldValue.serverTimestamp(),
        });
        expiredInvite = true;

        if (sessionId.isEmpty) return;
        final sessionRef = _db.collection(sessionsCol).doc(sessionId);
        final s = await tx.get(sessionRef);
        if (!s.exists) return;
        final sd = s.data()!;
        if (sd['status'] != 'waiting_accept') return;
        tx.update(sessionRef, {
          'status': 'expired',
          'cancelReason': 'invite_timeout',
        });
      });

      if (expiredInvite &&
          hostUid != null &&
          hostUid!.isNotEmpty &&
          sessionId.isNotEmpty) {
        await _writeDuelInviteTimeoutNotification(
          hostUid: hostUid!,
          inviteId: inviteId,
          sessionId: sessionId,
          inviteeUserId: inviteeUserId,
          inviteeDisplayName: inviteeDisplayName,
        );
      }
      return expiredInvite;
    } catch (e) {
      debugPrint('FamilyRemoteDuel expirePendingInviteDueToTimeout: $e');
      return false;
    }
  }

  Future<void> _writeDuelInviteTimeoutNotification({
    required String hostUid,
    required String inviteId,
    required String sessionId,
    required String inviteeUserId,
    required String inviteeDisplayName,
  }) async {
    final docId = 'frd_invite_timeout_$sessionId';
    final ref = _db
        .collection('users')
        .doc(hostUid)
        .collection('in_app_notifications')
        .doc(docId);
    try {
      final existing = await ref.get();
      if (existing.exists) return;
      await ref.set({
        'type': 'family_remote_duel_invite_timeout',
        'fromUid': inviteeUserId,
        'oldDisplayName': inviteeDisplayName.trim().isEmpty
            ? 'Çocuk'
            : inviteeDisplayName.trim(),
        'newDisplayName': '',
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
        'inviteId': inviteId,
      });
    } catch (e) {
      debugPrint('FamilyRemoteDuel _writeDuelInviteTimeoutNotification: $e');
    }
  }

  /// Süre dolduysa sıradaki oyuncu cevap vermiyorsa (sekme kapalı vb.) herhangi bir katılımcı bu çağrıyla turu ilerletir.
  Future<bool> applyOverdueAnswerIfNeeded({
    required String sessionId,
    required String actingUserId,
  }) async {
    if (sessionId.isEmpty || actingUserId.isEmpty) return false;
    final sessionRef = _db.collection(sessionsCol).doc(sessionId);
    try {
      await _db.runTransaction((tx) async {
        final snap = await tx.get(sessionRef);
        if (!snap.exists) return;
        final data = snap.data()!;
        if (data['status'] != 'active') return;

        final participantUserIds = duelParticipantIds(data);
        if (!participantUserIds.contains(actingUserId.trim())) return;

        final answerOrder = _answerOrderFromSession(data);
        if (answerOrder.isEmpty) return;

        final roundIdx = (data['currentRoundIndex'] as num?)?.toInt() ?? 0;
        final questionsRaw = data['questions'];
        final questions = decodeQuestionsList(questionsRaw);
        if (questions.isEmpty || roundIdx >= questions.length) return;

        final answeredSet = (data['roundAnsweredUserIds'] as List<dynamic>? ?? const [])
            .map((e) => e.toString())
            .toSet();
        final expected = _expectedAnswerer(answerOrder, answeredSet);
        if (expected == null) return;

        final deadline = (data['turnDeadlineAtMs'] as num?)?.toInt() ?? 0;
        if (deadline <= 0) return;
        if (_nowMs() <= deadline) return;
        if (answeredSet.contains(expected)) return;

        _applyTurnProgressInTransaction(
          tx: tx,
          sessionRef: sessionRef,
          data: data,
          participantUserIds: participantUserIds,
          answerOrder: answerOrder,
          questions: questions,
          roundIdx: roundIdx,
          answeringUserId: expected,
          pickedValue: timeoutWrongPick,
          answeredSet: answeredSet,
        );
      });
      return true;
    } catch (e) {
      debugPrint('FamilyRemoteDuel applyOverdueAnswerIfNeeded: $e');
      return false;
    }
  }

  void _applyTurnProgressInTransaction({
    required Transaction tx,
    required DocumentReference<Map<String, dynamic>> sessionRef,
    required Map<String, dynamic> data,
    required List<String> participantUserIds,
    required List<String> answerOrder,
    required List<Map<String, dynamic>> questions,
    required int roundIdx,
    required String answeringUserId,
    required dynamic pickedValue,
    required Set<String> answeredSet,
  }) {
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
    if (correct) counts[answeringUserId] = (counts[answeringUserId] ?? 0) + 1;
    answeredSet.add(answeringUserId);

    var nextRound = roundIdx;
    var nextAnswered = answeredSet.toList();
    var nextDeadline = _nowMs() + turnAnswerWindowMs;

    if (answeredSet.length == answerOrder.length) {
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
          'turnDeadlineAtMs': 0,
        });
        return;
      }
      nextRound = roundIdx + 1;
      nextAnswered = <String>[];
      nextDeadline = _nowMs() + turnAnswerWindowMs;
    }

    tx.update(sessionRef, {
      'roundAnsweredUserIds': nextAnswered,
      'correctCounts': counts,
      'currentRoundIndex': nextRound,
      'turnDeadlineAtMs': nextDeadline,
    });
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

        final participantUserIds = duelParticipantIds(data);
        if (!participantUserIds.contains(userId.trim())) return;

        final answerOrder = _answerOrderFromSession(data);
        if (answerOrder.isEmpty) return;

        final roundIdx = (data['currentRoundIndex'] as num?)?.toInt() ?? 0;
        final questionsRaw = data['questions'];
        final questions = decodeQuestionsList(questionsRaw);
        if (questions.isEmpty || roundIdx >= questions.length) return;

        final answeredSet = (data['roundAnsweredUserIds'] as List<dynamic>? ?? const [])
            .map((e) => e.toString())
            .toSet();
        final uid = userId.trim();
        final expected = _expectedAnswerer(answerOrder, answeredSet);
        if (expected == null || expected != uid) return;
        if (answeredSet.contains(uid)) return;

        _applyTurnProgressInTransaction(
          tx: tx,
          sessionRef: sessionRef,
          data: data,
          participantUserIds: participantUserIds,
          answerOrder: answerOrder,
          questions: questions,
          roundIdx: roundIdx,
          answeringUserId: uid,
          pickedValue: pickedValue,
          answeredSet: answeredSet,
        );
      });

      return true;
    } catch (e) {
      debugPrint('FamilyRemoteDuel submitAnswer: $e');
      return false;
    }
  }

  Future<void> _cancelPendingInvitesForSession(String sessionId) async {
    if (sessionId.isEmpty) return;
    try {
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
    } catch (e) {
      debugPrint('FamilyRemoteDuel _cancelPendingInvitesForSession: $e');
    }
  }

  /// Oyuncu düello veya kabul bekleme ekranından çıktığında oturumu bitirir; diğer taraf kazanır bildirimi alır.
  /// `waiting_accept`: yalnızca daveti kabul etmiş davetli (acceptedUserIds içinde) çıkabilir; ebeveyn [cancelPendingSession] kullanır.
  /// [true] dönerse Firestore güncellemesi uygulandı.
  Future<bool> markSessionForfeited({
    required String sessionId,
    required String leavingUserId,
  }) async {
    final leaving = leavingUserId.trim();
    if (sessionId.isEmpty || leaving.isEmpty) return false;
    final ref = _db.collection(sessionsCol).doc(sessionId);
    try {
      final ok = await _db.runTransaction<bool>((tx) async {
        final snap = await tx.get(ref);
        if (!snap.exists) return false;
        final data = snap.data()!;
        final status = data['status'] as String? ?? '';

        if (status == 'waiting_accept') {
          final hostUid = data['hostUserId'] as String? ?? '';
          if (leaving == hostUid) return false;

          final invited = (data['invitedUserIds'] as List<dynamic>? ?? const [])
              .map((e) => e.toString().trim())
              .where((e) => e.isNotEmpty)
              .toSet();
          if (!invited.contains(leaving)) return false;

          final accepted = (data['acceptedUserIds'] as List<dynamic>? ?? const [])
              .map((e) => e.toString().trim())
              .where((e) => e.isNotEmpty)
              .toSet();
          if (!accepted.contains(leaving)) return false;

          var participantUserIds = duelParticipantIds(data);
          if (!participantUserIds.contains(leaving)) {
            final alt = _answerOrderFromSession(data);
            if (alt.contains(leaving)) {
              participantUserIds = alt;
            } else {
              return false;
            }
          }

          final countsRaw = (data['correctCounts'] as Map?) ?? const {};
          final counts = <String, int>{
            for (final entry in countsRaw.entries)
              entry.key.toString(): (entry.value as num?)?.toInt() ?? 0,
          };
          for (final id in participantUserIds) {
            counts.putIfAbsent(id, () => 0);
          }
          counts[leaving] = -9999;

          final guestUid = data['guestUserId'] as String? ?? '';
          tx.update(ref, {
            'correctCounts': counts,
            'hostCorrectCount': counts[hostUid] ?? 0,
            'guestCorrectCount': counts[guestUid] ?? 0,
            'status': 'finished',
            'finishedAt': FieldValue.serverTimestamp(),
            'turnDeadlineAtMs': 0,
            'forfeit': true,
            'forfeitedByUserId': leaving,
          });
          return true;
        }

        if (status != 'active') return false;

        var participantUserIds = duelParticipantIds(data);
        if (!participantUserIds.contains(leaving)) {
          final alt = _answerOrderFromSession(data);
          if (alt.contains(leaving)) {
            participantUserIds = alt;
          } else {
            debugPrint(
              'FamilyRemoteDuel markSessionForfeited: leaving $leaving not in '
              '$participantUserIds nor alt $alt',
            );
            return false;
          }
        }

        final countsRaw = (data['correctCounts'] as Map?) ?? const {};
        final counts = <String, int>{
          for (final entry in countsRaw.entries)
            entry.key.toString(): (entry.value as num?)?.toInt() ?? 0,
        };
        for (final id in participantUserIds) {
          counts.putIfAbsent(id, () => 0);
        }
        counts[leaving] = -9999;

        final hostUid = data['hostUserId'] as String? ?? '';
        final guestUid = data['guestUserId'] as String? ?? '';
        tx.update(ref, {
          'correctCounts': counts,
          'hostCorrectCount': counts[hostUid] ?? 0,
          'guestCorrectCount': counts[guestUid] ?? 0,
          'status': 'finished',
          'finishedAt': FieldValue.serverTimestamp(),
          'turnDeadlineAtMs': 0,
          'forfeit': true,
          'forfeitedByUserId': leaving,
        });
        return true;
      });
      if (ok) {
        await _cancelPendingInvitesForSession(sessionId);
      }
      return ok;
    } catch (e) {
      debugPrint('FamilyRemoteDuel markSessionForfeited: $e');
      return false;
    }
  }

  /// Kazanan(lar) için tek seferlik altın ödülü — [rewardClaimedUserIds] ile çifte ödül engellenir.
  Future<int> claimRemoteDuelWinnerGold({
    required String sessionId,
    required String userId,
  }) async {
    if (sessionId.isEmpty || userId.isEmpty) return 0;
    final ref = _db.collection(sessionsCol).doc(sessionId);
    try {
      final granted = await _db.runTransaction<int>((tx) async {
        final snap = await tx.get(ref);
        if (!snap.exists) return 0;
        final data = snap.data()!;
        if (data['status'] != 'finished') return 0;

        final claimed = (data['rewardClaimedUserIds'] as List<dynamic>? ?? const [])
            .map((e) => e.toString())
            .where((e) => e.isNotEmpty)
            .toSet();
        if (claimed.contains(userId)) return 0;

        final countsRaw = (data['correctCounts'] as Map?) ?? const {};
        final counts = <String, int>{
          for (final e in countsRaw.entries)
            e.key.toString(): (e.value as num?)?.toInt() ?? 0,
        };
        if (counts.isEmpty || !counts.containsKey(userId)) return 0;
        final best = counts.values.fold<int>(0, (a, b) => math.max(a, b));
        if (counts[userId] != best) return 0;

        claimed.add(userId);
        tx.update(ref, {
          'rewardClaimedUserIds': claimed.toList(),
        });
        return winnerGoldCoins;
      });
      return granted;
    } catch (e) {
      debugPrint('FamilyRemoteDuel claimRemoteDuelWinnerGold: $e');
      return 0;
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
