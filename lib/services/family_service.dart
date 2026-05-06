import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/family_member.dart';
import '../models/badge.dart' show UserStats;

/// Aile üyeleri ve liderlik tablosu servisi
class FamilyService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? _parentUid;
  String? _parentDisplayName;
  List<FamilyMember> _members = [];
  List<LeaderboardEntry> _leaderboard = [];
  LeaderboardFilter _currentFilter = LeaderboardFilter.allTime;
  bool _isLoading = false;

  final Map<String, StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>>
      _childProfileSubs = {};

  /// Oturumda bir kez: mevcut çocuk hesaplarına `familyAnchorParentUid` yazar (eski kurulumlar için).
  bool _sessionFamilyAnchorsWritten = false;

  List<FamilyMember> get members => _members;
  List<LeaderboardEntry> get leaderboard => _leaderboard;
  LeaderboardFilter get currentFilter => _currentFilter;
  bool get isLoading => _isLoading;

  /// Ebeveyn (mevcut kullanıcı) ile başlat
  void initialize(String? parentUid, {String? parentDisplayName}) {
    _cancelChildProfileListeners();
    _parentUid = parentUid;
    _parentDisplayName = parentDisplayName ?? 'Oyuncu';
    if (parentUid != null && parentUid.isNotEmpty) {
      loadMembers();
    } else {
      _sessionFamilyAnchorsWritten = false;
      _members = [];
      _leaderboard = [];
      notifyListeners();
    }
  }

  void _cancelChildProfileListeners() {
    for (final sub in _childProfileSubs.values) {
      unawaited(sub.cancel());
    }
    _childProfileSubs.clear();
  }

  void _attachChildProfileListeners() {
    _cancelChildProfileListeners();
    if (_parentUid == null || _parentUid!.isEmpty) return;

    for (final member in _members) {
      if (member.isParent) continue;
      final uid = member.userId;
      _childProfileSubs[uid] =
          _firestore.collection('users').doc(uid).snapshots().listen((snap) {
        if (!snap.exists) return;
        final data = snap.data();
        if (data == null) return;
        final name = data['displayName'] as String?;
        if (name == null || name.isEmpty) return;

        final idx = _members.indexWhere((m) => m.userId == uid);
        if (idx == -1) return;
        if (_members[idx].displayName == name) return;

        _members[idx] = FamilyMember(
          userId: uid,
          displayName: name,
          isParent: _members[idx].isParent,
          profileEmoji: _members[idx].profileEmoji,
        );
        notifyListeners();
        unawaited(_persistMemberDisplayName(uid, name));
        unawaited(_loadLeaderboard());
      });
    }
  }

  Future<void> _ensureFamilyAnchorsWritten() async {
    final hub = _parentUid;
    if (hub == null || hub.isEmpty) return;
    try {
      await _firestore.collection('users').doc(hub).set(
        {'familyAnchorParentUid': hub, 'updatedAt': Timestamp.now()},
        SetOptions(merge: true),
      );
      for (final m in _members) {
        if (m.isParent) continue;
        await _firestore.collection('users').doc(m.userId).set(
          {'familyAnchorParentUid': hub, 'updatedAt': Timestamp.now()},
          SetOptions(merge: true),
        );
      }
    } catch (e) {
      debugPrint('FamilyService ensureFamilyAnchors: $e');
    }
  }

  Future<void> _persistMemberDisplayName(String uid, String displayName) async {
    if (_parentUid == null || _parentUid!.isEmpty) return;
    try {
      final membersRef = _firestore
          .collection('users')
          .doc(_parentUid)
          .collection('family')
          .doc('members');
      final doc = await membersRef.get();
      final list = (doc.data()?['members'] as List<dynamic>? ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();

      var changed = false;
      for (var i = 0; i < list.length; i++) {
        if ((list[i]['userId'] as String?) == uid) {
          if (list[i]['displayName'] != displayName) {
            list[i]['displayName'] = displayName;
            changed = true;
          }
          break;
        }
      }

      if (changed) {
        await membersRef.set({'members': list}, SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint('FamilyService persist displayName: $e');
    }
  }

  @override
  void dispose() {
    _cancelChildProfileListeners();
    super.dispose();
  }

  /// Firestore güvenlik kuralları: `childUserIds` ile davet hedefi doğrulanır.
  List<String> _linkedChildUserIds(List<Map<String, dynamic>> memberMaps) {
    return memberMaps
        .map((m) => m['userId'] as String? ?? '')
        .where((id) => id.isNotEmpty && id != _parentUid)
        .toList();
  }

  bool _sameStringList(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    final sa = [...a]..sort();
    final sb = [...b]..sort();
    for (var i = 0; i < sa.length; i++) {
      if (sa[i] != sb[i]) return false;
    }
    return true;
  }

  /// Aile üyelerini yükle (mevcut kullanıcı + Firestore'dan eklenen çocuklar)
  Future<void> loadMembers() async {
    if (_parentUid == null || _parentUid!.isEmpty) return;

    _cancelChildProfileListeners();
    _isLoading = true;
    notifyListeners();

    try {
      _members = [];

      // 1. Ebeveyn (mevcut kullanıcı) her zaman ilk üye
      _members.add(FamilyMember(
        userId: _parentUid!,
        displayName: _parentDisplayName ?? 'Oyuncu',
        isParent: true,
        profileEmoji: null,
      ));

      // 2. Firestore'dan eklenen çocukları yükle
      final snapshot = await _firestore
          .collection('users')
          .doc(_parentUid)
          .collection('family')
          .doc('members')
          .get();

      if (snapshot.exists && snapshot.data() != null) {
        final data = snapshot.data()!;
        final list = data['members'] as List<dynamic>? ?? [];
        final memberMaps = <Map<String, dynamic>>[];
        for (final item in list) {
          if (item is Map<String, dynamic>) {
            memberMaps.add(item);
            final member = FamilyMember.fromMap(item);
            if (member.userId.isNotEmpty && member.userId != _parentUid) {
              _members.add(member);
            }
          } else if (item is Map) {
            final m = Map<String, dynamic>.from(item);
            memberMaps.add(m);
            final member = FamilyMember.fromMap(m);
            if (member.userId.isNotEmpty && member.userId != _parentUid) {
              _members.add(member);
            }
          }
        }

        final membersRef = _firestore
            .collection('users')
            .doc(_parentUid)
            .collection('family')
            .doc('members');
        final computedChildIds = _linkedChildUserIds(memberMaps);
        final existingChildIds = (data['childUserIds'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            <String>[];
        if (!_sameStringList(existingChildIds, computedChildIds)) {
          await membersRef.set(
            {'childUserIds': computedChildIds},
            SetOptions(merge: true),
          );
        }
      }

      await _loadLeaderboard();
      if (!_sessionFamilyAnchorsWritten && _members.length > 1) {
        _sessionFamilyAnchorsWritten = true;
        unawaited(_ensureFamilyAnchorsWritten());
      }
      _attachChildProfileListeners();
    } catch (e) {
      debugPrint('FamilyService loadMembers error: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  DocumentReference<Map<String, dynamic>>? get _aggregatesRef {
    if (_parentUid == null || _parentUid!.isEmpty) return null;
    return _firestore
        .collection('users')
        .doc(_parentUid)
        .collection('family')
        .doc('aggregates');
  }

  /// Aile düellolarından biriken bonus puanlar (ebeveyn hesabı altında tutulur).
  Future<Map<String, int>> _loadDuelBonusesMap() async {
    final ref = _aggregatesRef;
    if (ref == null) return {};
    try {
      final snap = await ref.get();
      if (!snap.exists) return {};
      final raw = snap.data()?['duelPointsByUser'];
      if (raw is! Map) return {};
      final out = <String, int>{};
      for (final e in raw.entries) {
        out[e.key.toString()] = (e.value as num?)?.toInt() ?? 0;
      }
      return out;
    } catch (e) {
      debugPrint('FamilyService duel bonuses: $e');
      return {};
    }
  }

  /// Birebir yarış sonucunu kaydet; liderlikte `totalScore + duel bonus` görünür.
  Future<void> recordFamilyDuelResult({
    required String childUserId,
    required String topicKey,
    required int parentCorrect,
    required int childCorrect,
    required int rounds,
  }) async {
    final ref = _aggregatesRef;
    if (ref == null || _parentUid == null) return;

    final parentPts = parentCorrect * 10;
    final childPts = childCorrect * 10;

    try {
      await _firestore.runTransaction((tx) async {
        final snap = await tx.get(ref);
        final data = snap.data() ?? <String, dynamic>{};
        final raw = data['duelPointsByUser'];
        final map = <String, int>{};
        if (raw is Map) {
          for (final e in raw.entries) {
            map[e.key.toString()] = (e.value as num?)?.toInt() ?? 0;
          }
        }
        map[_parentUid!] = (map[_parentUid!] ?? 0) + parentPts;
        map[childUserId] = (map[childUserId] ?? 0) + childPts;

        tx.set(
          ref,
          {
            'duelPointsByUser': map,
            'lastFamilyDuel': {
              'at': FieldValue.serverTimestamp(),
              'topic': topicKey,
              'parentCorrect': parentCorrect,
              'childCorrect': childCorrect,
              'rounds': rounds,
              'childUserId': childUserId,
            },
          },
          SetOptions(merge: true),
        );
      });
      await loadMembers();
    } catch (e) {
      debugPrint('FamilyService recordFamilyDuelResult: $e');
    }
  }

  /// Uzaktan düello: skorlar her zaman ebeveyn hesabındaki `family/aggregates` altına yazılır.
  Future<void> recordRemoteFamilyDuelResult({
    required String parentUserId,
    required String childUserId,
    required String topicKey,
    required int parentCorrect,
    required int childCorrect,
    required int rounds,
  }) async {
    if (parentUserId.isEmpty || childUserId.isEmpty) return;
    final ref = _firestore
        .collection('users')
        .doc(parentUserId)
        .collection('family')
        .doc('aggregates');

    final parentPts = parentCorrect * 10;
    final childPts = childCorrect * 10;
    final parentStatsRef =
        _firestore.collection('users').doc(parentUserId).collection('stats').doc('gameStats');
    final childStatsRef =
        _firestore.collection('users').doc(childUserId).collection('stats').doc('gameStats');

    try {
      await _firestore.runTransaction((tx) async {
        final snap = await tx.get(ref);
        final data = snap.data() ?? <String, dynamic>{};
        final raw = data['duelPointsByUser'];
        final map = <String, int>{};
        if (raw is Map) {
          for (final e in raw.entries) {
            map[e.key.toString()] = (e.value as num?)?.toInt() ?? 0;
          }
        }
        map[parentUserId] = (map[parentUserId] ?? 0) + parentPts;
        map[childUserId] = (map[childUserId] ?? 0) + childPts;

        tx.set(
          ref,
          {
            'duelPointsByUser': map,
            'lastFamilyDuel': {
              'at': FieldValue.serverTimestamp(),
              'topic': topicKey,
              'parentCorrect': parentCorrect,
              'childCorrect': childCorrect,
              'rounds': rounds,
              'childUserId': childUserId,
              'remote': true,
            },
          },
          SetOptions(merge: true),
        );
        tx.set(
          parentStatsRef,
          {
            'totalGamesPlayed': FieldValue.increment(1),
            'totalQuestionsAnswered': FieldValue.increment(rounds),
            'totalCorrectAnswers': FieldValue.increment(parentCorrect),
            'totalWrongAnswers': FieldValue.increment(rounds - parentCorrect),
            'totalScore': FieldValue.increment(parentPts),
            'lastPlayedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
        tx.set(
          childStatsRef,
          {
            'totalGamesPlayed': FieldValue.increment(1),
            'totalQuestionsAnswered': FieldValue.increment(rounds),
            'totalCorrectAnswers': FieldValue.increment(childCorrect),
            'totalWrongAnswers': FieldValue.increment(rounds - childCorrect),
            'totalScore': FieldValue.increment(childPts),
            'lastPlayedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      });
      if (_parentUid == parentUserId) {
        await loadMembers();
      }
    } catch (e) {
      debugPrint('FamilyService recordRemoteFamilyDuelResult: $e');
    }
  }

  /// Çoklu uzaktan düello: ebeveyn + birden çok çocuk için puanları yazar.
  Future<void> recordRemoteFamilyDuelGroupResult({
    required String parentUserId,
    required List<String> childUserIds,
    required Map<String, int> participantCorrectByUser,
    required String topicKey,
    required int rounds,
  }) async {
    if (parentUserId.isEmpty || participantCorrectByUser.isEmpty) return;
    final ref = _firestore
        .collection('users')
        .doc(parentUserId)
        .collection('family')
        .doc('aggregates');

    try {
      await _firestore.runTransaction((tx) async {
        final snap = await tx.get(ref);
        final data = snap.data() ?? <String, dynamic>{};
        final raw = data['duelPointsByUser'];
        final map = <String, int>{};
        if (raw is Map) {
          for (final e in raw.entries) {
            map[e.key.toString()] = (e.value as num?)?.toInt() ?? 0;
          }
        }

        for (final entry in participantCorrectByUser.entries) {
          final uid = entry.key;
          final points = entry.value * 10;
          map[uid] = (map[uid] ?? 0) + points;
        }

        tx.set(
          ref,
          {
            'duelPointsByUser': map,
            'lastFamilyDuel': {
              'at': FieldValue.serverTimestamp(),
              'topic': topicKey,
              'rounds': rounds,
              'childUserIds': childUserIds,
              'participantCorrectByUser': participantCorrectByUser,
              'remote': true,
              'group': true,
            },
          },
          SetOptions(merge: true),
        );

        for (final entry in participantCorrectByUser.entries) {
          final uid = entry.key;
          final correct = entry.value;
          final points = correct * 10;
          final statsRef =
              _firestore.collection('users').doc(uid).collection('stats').doc('gameStats');
          tx.set(
            statsRef,
            {
              'totalGamesPlayed': FieldValue.increment(1),
              'totalQuestionsAnswered': FieldValue.increment(rounds),
              'totalCorrectAnswers': FieldValue.increment(correct),
              'totalWrongAnswers': FieldValue.increment(rounds - correct),
              'totalScore': FieldValue.increment(points),
              'lastPlayedAt': FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true),
          );
        }
      });
      if (_parentUid == parentUserId) {
        await loadMembers();
      }
    } catch (e) {
      debugPrint('FamilyService recordRemoteFamilyDuelGroupResult: $e');
    }
  }

  /// Liderlik tablosu verilerini yükle
  Future<void> _loadLeaderboard() async {
    _leaderboard = [];

    final duelBonuses = await _loadDuelBonusesMap();

    for (final member in _members) {
      final entry = await _fetchMemberStats(
        member,
        duelBonus: duelBonuses[member.userId] ?? 0,
      );
      if (entry != null) {
        _leaderboard.add(entry);
      }
    }

    // Puana göre sırala (yüksekten düşüğe)
    _leaderboard.sort((a, b) => b.score.compareTo(a.score));

    // Sıra numarası ata
    _leaderboard = _leaderboard.asMap().entries.map((e) {
      return LeaderboardEntry(
        rank: e.key + 1,
        userId: e.value.userId,
        displayName: e.value.displayName,
        score: e.value.score,
        accuracy: e.value.accuracy,
        lastPlayedAt: e.value.lastPlayedAt,
        isParent: e.value.isParent,
        earnedBadges: e.value.earnedBadges,
        weeklyValues: e.value.weeklyValues,
        profileEmoji: e.value.profileEmoji,
      );
    }).toList();
  }

  Future<LeaderboardEntry?> _fetchMemberStats(
    FamilyMember member, {
    int duelBonus = 0,
  }) async {
    try {
      final statsDoc = await _firestore
          .collection('users')
          .doc(member.userId)
          .collection('stats')
          .doc('gameStats')
          .get();

      int score = 0;
      int accuracy = 0;
      DateTime? lastPlayedAt;
      int consecutiveDays = 0;

      if (statsDoc.exists && statsDoc.data() != null) {
        final data = statsDoc.data()!;
        final stats = UserStats.fromMap(data, member.userId);
        score = _getScoreForFilter(stats);
        final total = stats.totalQuestionsAnswered;
        accuracy = total > 0
            ? (stats.totalCorrectAnswers / total * 100).round()
            : 0;
        lastPlayedAt = stats.lastPlayedAt;
        consecutiveDays = stats.consecutiveDays;
      }

      score += duelBonus;

      // Rozet sayısı
      int earnedBadges = 0;
      try {
        final badgesSnap = await _firestore
            .collection('users')
            .doc(member.userId)
            .collection('badges')
            .get();
        earnedBadges = badgesSnap.docs.length;
      } catch (_) {}

      final weeklyValues = _getWeeklyProgress(consecutiveDays);

      return LeaderboardEntry(
        rank: 0,
        userId: member.userId,
        displayName: member.displayName,
        score: score,
        accuracy: accuracy,
        lastPlayedAt: lastPlayedAt,
        isParent: member.isParent,
        earnedBadges: earnedBadges,
        weeklyValues: weeklyValues,
        profileEmoji: member.profileEmoji,
      );
    } catch (e) {
      debugPrint('FamilyService fetch stats error for ${member.userId}: $e');
      return LeaderboardEntry(
        rank: 0,
        userId: member.userId,
        displayName: member.displayName,
        score: 0,
        accuracy: 0,
        lastPlayedAt: null,
        isParent: member.isParent,
        profileEmoji: member.profileEmoji,
      );
    }
  }

  List<int> _getWeeklyProgress(int consecutiveDays) {
    return List.generate(7, (i) {
      final daysFromEnd = 6 - i;
      return (consecutiveDays > daysFromEnd) ? 100 : 0;
    });
  }

  /// Filtreye göre puan (şimdilik hepsi totalScore)
  int _getScoreForFilter(UserStats stats) {
    switch (_currentFilter) {
      case LeaderboardFilter.weekly:
      case LeaderboardFilter.monthly:
        // Haftalık/aylık için ayrı veri yok - totalScore kullan
        return stats.totalScore;
      case LeaderboardFilter.allTime:
        return stats.totalScore;
    }
  }

  /// Filtre değiştir
  Future<void> setFilter(LeaderboardFilter filter) async {
    if (_currentFilter == filter) return;
    _currentFilter = filter;
    await _loadLeaderboard();
    notifyListeners();
  }

  /// Çocuk üye ekle (userCode ile)
  Future<bool> addChildByUserCode(String userCode, String displayName) async {
    if (_parentUid == null || userCode.isEmpty) return false;

    try {
      final normalized = userCode.trim().toUpperCase();
      final snapshot = await _firestore
          .collection('users')
          .where('userCode', isEqualTo: normalized)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return false;

      final childDoc = snapshot.docs.first;
      final childUid = childDoc.id;
      final childData = childDoc.data();
      final name = childData['displayName'] ?? childData['email']?.toString().split('@').first ?? displayName;

      if (childUid == _parentUid) return false;

      final membersRef = _firestore
          .collection('users')
          .doc(_parentUid)
          .collection('family')
          .doc('members');

      final doc = await membersRef.get();
      final list = <Map<String, dynamic>>[];
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        list.addAll((data['members'] as List<dynamic>? ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map)));
      }

      if (list.any((m) => m['userId'] == childUid)) return false;

      list.add({
        'userId': childUid,
        'displayName': name,
        'isParent': false,
        'profileEmoji': childData['profileEmoji'] as String?,
      });

      final childIds = _linkedChildUserIds(list);
      await membersRef.set({'members': list, 'childUserIds': childIds});

      await _firestore.collection('users').doc(childUid).set(
        {
          'familyAnchorParentUid': _parentUid,
          'updatedAt': Timestamp.now(),
        },
        SetOptions(merge: true),
      );
      await _firestore.collection('users').doc(_parentUid!).set(
        {
          'familyAnchorParentUid': _parentUid,
          'updatedAt': Timestamp.now(),
        },
        SetOptions(merge: true),
      );

      await loadMembers();
      return true;
    } catch (e) {
      debugPrint('FamilyService addChild error: $e');
      return false;
    }
  }

  /// Verileri yenile
  Future<void> refresh() async {
    await loadMembers();
  }

  Future<void> updateMemberEmoji({
    required String userId,
    required String profileEmoji,
  }) async {
    if (_parentUid == null || _parentUid!.isEmpty) return;
    if (userId.isEmpty || profileEmoji.trim().isEmpty) return;

    try {
      final membersRef = _firestore
          .collection('users')
          .doc(_parentUid)
          .collection('family')
          .doc('members');
      final doc = await membersRef.get();
      final current = doc.data();
      final list = (current?['members'] as List<dynamic>? ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();

      bool changed = false;
      for (var i = 0; i < list.length; i++) {
        if ((list[i]['userId'] as String?) == userId) {
          list[i]['profileEmoji'] = profileEmoji;
          changed = true;
          break;
        }
      }

      if (changed) {
        await membersRef.set({'members': list}, SetOptions(merge: true));
      }

      _members = _members
          .map((m) => m.userId == userId
              ? FamilyMember(
                  userId: m.userId,
                  displayName: m.displayName,
                  isParent: m.isParent,
                  profileEmoji: profileEmoji,
                )
              : m)
          .toList();

      _leaderboard = _leaderboard
          .map((e) => e.userId == userId
              ? LeaderboardEntry(
                  rank: e.rank,
                  userId: e.userId,
                  displayName: e.displayName,
                  score: e.score,
                  accuracy: e.accuracy,
                  lastPlayedAt: e.lastPlayedAt,
                  isParent: e.isParent,
                  earnedBadges: e.earnedBadges,
                  weeklyValues: e.weeklyValues,
                  profileEmoji: profileEmoji,
                )
              : e)
          .toList();

      notifyListeners();
    } catch (e) {
      debugPrint('FamilyService updateMemberEmoji error: $e');
    }
  }
}
