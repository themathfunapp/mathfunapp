import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/friend_request.dart';
import '../models/friendship.dart';
import '../models/friend_duel_invite.dart';
import 'friend_duel_service.dart';
import '../models/app_user.dart';

class FriendService extends ChangeNotifier {
  FriendService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const String _friendDuelInvitesCol = 'friendDuelInvites';
  static const String _friendRequestsCol = 'friendRequests';

  /// Gönderen_alıcı — bileşik sorgu / indeks gerektirmez.
  static String friendRequestDocId(String senderId, String receiverId) =>
      '${senderId}_$receiverId';
  
  // Current user info
  String? _currentUserId;
  String? _currentUserName;
  String? _currentUserPhotoUrl;
  String? _currentUserCode;
  bool _isGuest = true;

  // Lists
  List<Friendship> _friends = [];
  List<FriendRequest> _incomingRequests = [];
  List<FriendRequest> _outgoingRequests = [];
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _incomingRequestsSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _friendsSub;
  bool _friendsHydrated = false;

  // Getters
  List<Friendship> get friends => _friends;
  bool get friendsHydrated => _friendsHydrated;
  List<FriendRequest> get incomingRequests => _incomingRequests;
  List<FriendRequest> get outgoingRequests => _outgoingRequests;
  bool get isGuest => _isGuest;
  int get pendingRequestsCount => _incomingRequests.length;
  String? get currentUserCode => _currentUserCode;

  // Initialize with user
  void initialize(AppUser? user) {
    _incomingRequestsSub?.cancel();
    _incomingRequestsSub = null;
    _friendsSub?.cancel();
    _friendsSub = null;
    _friendsHydrated = false;

    if (user == null) {
      _currentUserId = null;
      _currentUserName = null;
      _currentUserPhotoUrl = null;
      _currentUserCode = null;
      _isGuest = true;
      _friends = [];
      _incomingRequests = [];
      _outgoingRequests = [];
      notifyListeners();
      return;
    }

    _currentUserId = user.uid;
    _currentUserName = user.displayName ?? user.email?.split('@').first ?? 'Kullanıcı';
    _currentUserPhotoUrl = user.photoURL;
    _currentUserCode = user.userCode;
    _isGuest = user.isGuest;

    if (!_isGuest) {
      _loadFriends();
      _loadIncomingRequests();
      _loadOutgoingRequests();
      _watchIncomingRequests();
      _watchFriends();
    }
  }

  List<FriendRequest> _parseRequestDocs(
    Iterable<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final list = <FriendRequest>[];
    for (final doc in docs) {
      try {
        list.add(FriendRequest.fromMap(doc.data(), doc.id));
      } catch (e) {
        debugPrint('friend request parse ${doc.id}: $e');
      }
    }
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  void _watchIncomingRequests() {
    _incomingRequestsSub?.cancel();
    if (_currentUserId == null || _isGuest) return;

    _incomingRequestsSub = _firestore
        .collection(_friendRequestsCol)
        .where('receiverId', isEqualTo: _currentUserId)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .listen(
      (snapshot) {
        _incomingRequests = _parseRequestDocs(snapshot.docs);
        notifyListeners();
      },
      onError: (Object e) {
        debugPrint('Incoming requests watch error: $e');
        _loadIncomingRequestsFallback();
      },
    );
  }

  // ------------- ARKADAŞ LİSTESİ -------------

  Future<void> _loadFriends() async {
    if (_currentUserId == null || _isGuest) return;

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('friends')
          .orderBy('friendName')
          .get();

      _friends = snapshot.docs
          .map((doc) => Friendship.fromMap(doc.data(), doc.id))
          .toList();
      _friendsHydrated = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Load friends error: $e');
    }
  }

  void _watchFriends() {
    _friendsSub?.cancel();
    if (_currentUserId == null || _isGuest) return;

    _friendsSub = _firestore
        .collection('users')
        .doc(_currentUserId)
        .collection('friends')
        .orderBy('friendName')
        .snapshots()
        .listen(
      (snapshot) {
        _friends = snapshot.docs
            .map((doc) => Friendship.fromMap(doc.data(), doc.id))
            .toList();
        _friendsHydrated = true;
        notifyListeners();
      },
      onError: (Object e) {
        debugPrint('Friends watch error: $e');
        unawaited(_loadFriends());
      },
    );
  }

  // Real-time friends stream (önbellekli — her build'de yeni dinleyici açılmasın)
  Stream<List<Friendship>>? _friendsStreamCache;
  String? _friendsStreamUserId;

  Stream<List<Friendship>> friendsStream() {
    if (_currentUserId == null || _isGuest) {
      return Stream.value(const []);
    }
    if (_friendsStreamCache != null && _friendsStreamUserId == _currentUserId) {
      return _friendsStreamCache!;
    }
    _friendsStreamUserId = _currentUserId;
    _friendsStreamCache = _firestore
        .collection('users')
        .doc(_currentUserId)
        .collection('friends')
        .orderBy('friendName')
        .snapshots()
        .map((snapshot) {
          _friends = snapshot.docs
              .map((doc) => Friendship.fromMap(doc.data(), doc.id))
              .toList();
          _friendsHydrated = true;
          return _friends;
        });
    return _friendsStreamCache!;
  }

  // ------------- GELEN İSTEKLER -------------

  Future<void> _loadIncomingRequests() async {
    await _loadIncomingRequestsFallback();
  }

  Future<void> _loadIncomingRequestsFallback() async {
    if (_currentUserId == null || _isGuest) return;
    try {
      final snapshot = await _firestore
          .collection(_friendRequestsCol)
          .where('receiverId', isEqualTo: _currentUserId)
          .where('status', isEqualTo: 'pending')
          .get();
      _incomingRequests = _parseRequestDocs(snapshot.docs);
      notifyListeners();
    } catch (e) {
      debugPrint('Load incoming requests fallback error: $e');
    }
  }

  /// Rozet ve liste aynı kaynaktan ([incomingRequests]) beslenir.
  Stream<List<FriendRequest>> incomingRequestsStream() async* {
    yield _incomingRequests;
  }

  // ------------- GİDEN İSTEKLER -------------

  Future<void> _loadOutgoingRequests() async {
    if (_currentUserId == null || _isGuest) return;

    try {
      final snapshot = await _firestore
          .collection(_friendRequestsCol)
          .where('senderId', isEqualTo: _currentUserId)
          .where('status', isEqualTo: 'pending')
          .orderBy('createdAt', descending: true)
          .get();

      _outgoingRequests = snapshot.docs
          .map((doc) => FriendRequest.fromMap(doc.data(), doc.id))
          .toList();
      
      notifyListeners();
    } catch (e) {
      debugPrint('Load outgoing requests error: $e');
      await _loadOutgoingRequestsFallback();
    }
  }

  Future<void> _loadOutgoingRequestsFallback() async {
    if (_currentUserId == null || _isGuest) return;
    try {
      final snapshot = await _firestore
          .collection(_friendRequestsCol)
          .where('senderId', isEqualTo: _currentUserId)
          .where('status', isEqualTo: 'pending')
          .get();
      _outgoingRequests = snapshot.docs
          .map((doc) => FriendRequest.fromMap(doc.data(), doc.id))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      notifyListeners();
    } catch (e) {
      debugPrint('Load outgoing requests fallback error: $e');
    }
  }

  // ------------- KULLANICI ARAMA -------------

  // ID ile kullanıcı ara
  Future<AppUser?> searchUserById(String userId) async {
    if (_isGuest) return null;

    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      
      if (doc.exists && doc.data() != null) {
        return AppUser.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      debugPrint('Search user by ID error: $e');
      return null;
    }
  }

  Future<AppUser?> _fetchUserByExactUserCode(String codeUpper) async {
    final snapshot = await _firestore
        .collection('users')
        .where('userCode', isEqualTo: codeUpper)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      return AppUser.fromMap(snapshot.docs.first.data());
    }

    final snapshotLower = await _firestore
        .collection('users')
        .where('userCodeLower', isEqualTo: codeUpper.toLowerCase())
        .limit(1)
        .get();

    if (snapshotLower.docs.isNotEmpty) {
      return AppUser.fromMap(snapshotLower.docs.first.data());
    }
    return null;
  }

  // Oyuncu kodu (MTN) ile kullanıcı ara
  Future<AppUser?> searchUserByCode(String userCode) async {
    if (_isGuest) return null;

    try {
      final normalizedCode = userCode.toUpperCase().trim();
      return await _fetchUserByExactUserCode(normalizedCode);
    } catch (e) {
      debugPrint('Search user by code error: $e');
      return null;
    }
  }

  // İsim ile kullanıcı ara
  Future<List<AppUser>> searchUsersByName(String name) async {
    if (_isGuest || name.trim().isEmpty) return [];

    try {
      final searchTerm = name.toLowerCase().trim();
      
      // İsme göre arama
      final snapshot = await _firestore
          .collection('users')
          .where('isGuest', isEqualTo: false)
          .get();

      final users = snapshot.docs
          .map((doc) => AppUser.fromMap(doc.data()))
          .where((user) {
            // Kendini hariç tut
            if (user.uid == _currentUserId) return false;
            
            // İsim, email veya userCode ile eşleşme
            final displayName = user.displayName?.toLowerCase() ?? '';
            final email = user.email?.toLowerCase() ?? '';
            final userCode = user.userCode?.toLowerCase() ?? '';
            
            return displayName.contains(searchTerm) || 
                   email.contains(searchTerm) ||
                   userCode.contains(searchTerm);
          })
          .take(20) // Maximum 20 sonuç
          .toList();

      return users;
    } catch (e) {
      debugPrint('Search users by name error: $e');
      return [];
    }
  }

  // Genel arama (MTN oyuncu kodu, Firebase ID veya isim)
  Future<List<AppUser>> searchUsers(String query) async {
    if (_isGuest || query.trim().isEmpty) return [];

    final trimmedQuery = query.trim();

    final mergedCode = AppUser.mergePlayerCodeInput(trimmedQuery);
    if (mergedCode != null) {
      final userByCode = await searchUserByCode(mergedCode);
      if (userByCode != null && userByCode.uid != _currentUserId && !userByCode.isGuest) {
        return [userByCode];
      }
      return [];
    }

    // Firebase ID ile dene
    final userById = await searchUserById(trimmedQuery);
    if (userById != null && userById.uid != _currentUserId && !userById.isGuest) {
      return [userById];
    }

    // İsim ile ara
    return await searchUsersByName(trimmedQuery);
  }

  // ------------- ARKADAŞLIK İSTEĞİ GÖNDER -------------

  Future<String?> sendFriendRequest(AppUser targetUser) async {
    if (_isGuest || _currentUserId == null) {
      return 'guest';
    }

    if (targetUser.isGuest) {
      return 'target_guest';
    }

    if (targetUser.uid == _currentUserId) {
      return 'self';
    }

    try {
      final existingFriend = await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('friends')
          .doc(targetUser.uid)
          .get();

      if (existingFriend.exists) {
        return 'already_friends';
      }

      final outgoingId =
          friendRequestDocId(_currentUserId!, targetUser.uid);
      final incomingId =
          friendRequestDocId(targetUser.uid, _currentUserId!);

      final incomingSnap =
          await _firestore.collection(_friendRequestsCol).doc(incomingId).get();
      if (incomingSnap.exists &&
          incomingSnap.data()?['status'] == 'pending') {
        final ok = await acceptFriendRequest(incomingId);
        return ok ? null : 'accept_failed';
      }

      final outgoingSnap =
          await _firestore.collection(_friendRequestsCol).doc(outgoingId).get();
      if (outgoingSnap.exists &&
          outgoingSnap.data()?['status'] == 'pending') {
        return 'already_sent';
      }

      final request = FriendRequest(
        id: outgoingId,
        senderId: _currentUserId!,
        senderName: _currentUserName ?? 'Kullanıcı',
        senderPhotoUrl: _currentUserPhotoUrl,
        senderUserCode: _currentUserCode,
        receiverId: targetUser.uid,
        receiverName: targetUser.displayName ??
            targetUser.email?.split('@').first ??
            'Kullanıcı',
        receiverPhotoUrl: targetUser.photoURL,
        receiverUserCode: targetUser.userCode,
        status: FriendRequestStatus.pending,
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection(_friendRequestsCol)
          .doc(outgoingId)
          .set(request.toMap());

      await _loadOutgoingRequests();
      notifyListeners();
      return null;
    } catch (e, st) {
      debugPrint('Send friend request error: $e\n$st');
      return 'error';
    }
  }

  // ------------- ARKADAŞLIK İSTEĞİ KABUL ET -------------

  Future<bool> acceptFriendRequest(String requestId) async {
    if (_isGuest || _currentUserId == null) return false;

    try {
      final requestDoc = await _firestore
          .collection(_friendRequestsCol)
          .doc(requestId)
          .get();

      if (!requestDoc.exists) return false;

      final request = FriendRequest.fromMap(requestDoc.data()!, requestDoc.id);

      // İsteği güncelle
      await _firestore.collection(_friendRequestsCol).doc(requestId).update({
        'status': 'accepted',
        'respondedAt': Timestamp.now(),
      });

      final now = DateTime.now();

      // Her iki kullanıcının arkadaş listesine ekle
      // Gönderen için
      await _firestore
          .collection('users')
          .doc(request.senderId)
          .collection('friends')
          .doc(request.receiverId)
          .set(Friendship(
            id: request.receiverId,
            friendId: request.receiverId,
            friendName: request.receiverName,
            friendPhotoUrl: request.receiverPhotoUrl,
            friendUserCode: request.receiverUserCode,
            friendsSince: now,
          ).toMap());

      // Alıcı için (kendimiz)
      await _firestore
          .collection('users')
          .doc(request.receiverId)
          .collection('friends')
          .doc(request.senderId)
          .set(Friendship(
            id: request.senderId,
            friendId: request.senderId,
            friendName: request.senderName,
            friendPhotoUrl: request.senderPhotoUrl,
            friendUserCode: request.senderUserCode,
            friendsSince: now,
          ).toMap());

      await _loadFriends();
      await _loadIncomingRequests();
      return true;
    } catch (e) {
      debugPrint('Accept friend request error: $e');
      return false;
    }
  }

  // ------------- ARKADAŞLIK İSTEĞİ REDDET -------------

  Future<bool> rejectFriendRequest(String requestId) async {
    if (_isGuest || _currentUserId == null) return false;

    try {
      await _firestore.collection(_friendRequestsCol).doc(requestId).update({
        'status': 'rejected',
        'respondedAt': Timestamp.now(),
      });

      await _loadIncomingRequests();
      return true;
    } catch (e) {
      debugPrint('Reject friend request error: $e');
      return false;
    }
  }

  // ------------- ARKADAŞLIK İSTEĞİ İPTAL ET -------------

  Future<bool> cancelFriendRequest(String requestId) async {
    if (_isGuest || _currentUserId == null) return false;

    try {
      await _firestore.collection(_friendRequestsCol).doc(requestId).delete();
      
      await _loadOutgoingRequests();
      return true;
    } catch (e) {
      debugPrint('Cancel friend request error: $e');
      return false;
    }
  }

  // ------------- ARKADAŞI SİL -------------

  Future<bool> removeFriend(String friendId) async {
    if (_isGuest || _currentUserId == null) return false;

    try {
      // Her iki taraftan da sil
      await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('friends')
          .doc(friendId)
          .delete();

      await _firestore
          .collection('users')
          .doc(friendId)
          .collection('friends')
          .doc(_currentUserId)
          .delete();

      await _loadFriends();
      return true;
    } catch (e) {
      debugPrint('Remove friend error: $e');
      return false;
    }
  }

  // ------------- YARDIMCI METOTLAR -------------

  // Kullanıcının arkadaşlık durumunu kontrol et
  Future<FriendshipStatus> checkFriendshipStatus(String userId) async {
    if (_isGuest || _currentUserId == null) {
      return FriendshipStatus.none;
    }

    try {
      final friendDoc = await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('friends')
          .doc(userId)
          .get();

      if (friendDoc.exists) {
        return FriendshipStatus.friends;
      }

      final outgoingId = friendRequestDocId(_currentUserId!, userId);
      final outgoingDoc =
          await _firestore.collection(_friendRequestsCol).doc(outgoingId).get();
      if (outgoingDoc.exists && outgoingDoc.data()?['status'] == 'pending') {
        return FriendshipStatus.requestSent;
      }

      final incomingId = friendRequestDocId(userId, _currentUserId!);
      final incomingDoc =
          await _firestore.collection(_friendRequestsCol).doc(incomingId).get();
      if (incomingDoc.exists && incomingDoc.data()?['status'] == 'pending') {
        return FriendshipStatus.requestReceived;
      }

      return FriendshipStatus.none;
    } catch (e) {
      debugPrint('Check friendship status error: $e');
      return FriendshipStatus.none;
    }
  }

  // ------------- ARKADAŞ DÜELLO DAVETİ (friendDuelInvites) -------------

  Stream<List<FriendDuelInvite>> incomingFriendDuelInvitesStream() {
    if (_currentUserId == null || _isGuest) {
      return Stream.value([]);
    }
    return _firestore
        .collection(_friendDuelInvitesCol)
        .where('toUserId', isEqualTo: _currentUserId)
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => FriendDuelService.parsePendingInvitesFromSnapshot(snap));
  }

  /// Aynı arkadaşa bekleyen davet varsa false döner (Firestore oturumu ile).
  Future<bool> sendFriendDuelInvite(Friendship friend) async {
    if (_isGuest || _currentUserId == null) return false;
    final result = await FriendDuelService().createInvite(
      hostUserId: _currentUserId!,
      hostDisplayName: _currentUserName ?? 'Oyuncu',
      hostUserCode: _currentUserCode,
      guestUserId: friend.friendId,
      guestDisplayName: friend.friendName,
    );
    return result != null;
  }

  Future<void> deleteFriendDuelInvite(String inviteId) async {
    try {
      await _firestore.collection(_friendDuelInvitesCol).doc(inviteId).delete();
    } catch (e) {
      debugPrint('deleteFriendDuelInvite error: $e');
    }
  }

  // Verileri yenile
  Future<void> refresh() async {
    if (_isGuest) return;

    await _loadFriends();
    await _loadIncomingRequests();
    await _loadOutgoingRequests();
    _watchIncomingRequests();
  }

  @override
  void dispose() {
    _incomingRequestsSub?.cancel();
    _friendsSub?.cancel();
    super.dispose();
  }
}

enum FriendshipStatus {
  none,           // Hiçbir ilişki yok
  friends,        // Zaten arkadaş
  requestSent,    // İstek gönderildi
  requestReceived // İstek alındı
}

