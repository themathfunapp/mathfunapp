import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/friend_request.dart';
import '../models/friendship.dart';
import '../models/app_user.dart';

class FriendService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
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

  // Getters
  List<Friendship> get friends => _friends;
  List<FriendRequest> get incomingRequests => _incomingRequests;
  List<FriendRequest> get outgoingRequests => _outgoingRequests;
  bool get isGuest => _isGuest;
  int get pendingRequestsCount => _incomingRequests.length;
  String? get currentUserCode => _currentUserCode;

  // Initialize with user
  void initialize(AppUser? user) {
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
    }
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
      
      notifyListeners();
    } catch (e) {
      debugPrint('Load friends error: $e');
    }
  }

  // Real-time friends stream
  Stream<List<Friendship>> friendsStream() {
    if (_currentUserId == null || _isGuest) {
      return Stream.value([]);
    }

    return _firestore
        .collection('users')
        .doc(_currentUserId)
        .collection('friends')
        .orderBy('friendName')
        .snapshots()
        .map((snapshot) {
          _friends = snapshot.docs
              .map((doc) => Friendship.fromMap(doc.data(), doc.id))
              .toList();
          return _friends;
        });
  }

  // ------------- GELEN İSTEKLER -------------

  Future<void> _loadIncomingRequests() async {
    if (_currentUserId == null || _isGuest) return;

    try {
      final snapshot = await _firestore
          .collection('friendRequests')
          .where('receiverId', isEqualTo: _currentUserId)
          .where('status', isEqualTo: 'pending')
          .orderBy('createdAt', descending: true)
          .get();

      _incomingRequests = snapshot.docs
          .map((doc) => FriendRequest.fromMap(doc.data(), doc.id))
          .toList();
      
      notifyListeners();
    } catch (e) {
      debugPrint('Load incoming requests error: $e');
    }
  }

  // Real-time incoming requests stream
  Stream<List<FriendRequest>> incomingRequestsStream() {
    if (_currentUserId == null || _isGuest) {
      return Stream.value([]);
    }

    return _firestore
        .collection('friendRequests')
        .where('receiverId', isEqualTo: _currentUserId)
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          _incomingRequests = snapshot.docs
              .map((doc) => FriendRequest.fromMap(doc.data(), doc.id))
              .toList();
          return _incomingRequests;
        });
  }

  // ------------- GİDEN İSTEKLER -------------

  Future<void> _loadOutgoingRequests() async {
    if (_currentUserId == null || _isGuest) return;

    try {
      final snapshot = await _firestore
          .collection('friendRequests')
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

  // RKN kodu ile kullanıcı ara
  Future<AppUser?> searchUserByCode(String userCode) async {
    if (_isGuest) return null;

    try {
      final normalizedCode = userCode.toUpperCase().trim();
      
      // userCode alanında ara
      final snapshot = await _firestore
          .collection('users')
          .where('userCode', isEqualTo: normalizedCode)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return AppUser.fromMap(snapshot.docs.first.data());
      }

      // userCodeLower alanında da ara (küçük harf)
      final snapshotLower = await _firestore
          .collection('users')
          .where('userCodeLower', isEqualTo: normalizedCode.toLowerCase())
          .limit(1)
          .get();

      if (snapshotLower.docs.isNotEmpty) {
        return AppUser.fromMap(snapshotLower.docs.first.data());
      }

      return null;
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

  // Genel arama (RKN kodu, ID veya isim)
  Future<List<AppUser>> searchUsers(String query) async {
    if (_isGuest || query.trim().isEmpty) return [];

    final trimmedQuery = query.trim();

    // RKN kodu ile ara (RKN ile başlıyorsa)
    if (trimmedQuery.toUpperCase().startsWith('RKN')) {
      final userByCode = await searchUserByCode(trimmedQuery);
      if (userByCode != null && userByCode.uid != _currentUserId && !userByCode.isGuest) {
        return [userByCode];
      }
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

  Future<bool> sendFriendRequest(AppUser targetUser) async {
    if (_isGuest || _currentUserId == null) {
      debugPrint('Guest users cannot send friend requests');
      return false;
    }

    if (targetUser.isGuest) {
      debugPrint('Cannot send friend request to guest user');
      return false;
    }

    if (targetUser.uid == _currentUserId) {
      debugPrint('Cannot send friend request to yourself');
      return false;
    }

    try {
      // Zaten arkadaş mı kontrol et
      final existingFriend = await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('friends')
          .doc(targetUser.uid)
          .get();

      if (existingFriend.exists) {
        debugPrint('Already friends');
        return false;
      }

      // Bekleyen istek var mı kontrol et
      final existingRequest = await _firestore
          .collection('friendRequests')
          .where('senderId', isEqualTo: _currentUserId)
          .where('receiverId', isEqualTo: targetUser.uid)
          .where('status', isEqualTo: 'pending')
          .get();

      if (existingRequest.docs.isNotEmpty) {
        debugPrint('Friend request already sent');
        return false;
      }

      // Karşı taraftan gelen istek var mı kontrol et
      final incomingRequest = await _firestore
          .collection('friendRequests')
          .where('senderId', isEqualTo: targetUser.uid)
          .where('receiverId', isEqualTo: _currentUserId)
          .where('status', isEqualTo: 'pending')
          .get();

      if (incomingRequest.docs.isNotEmpty) {
        // Karşı taraftan istek var, otomatik kabul et
        await acceptFriendRequest(incomingRequest.docs.first.id);
        return true;
      }

      // Yeni istek oluştur
      final request = FriendRequest(
        id: '',
        senderId: _currentUserId!,
        senderName: _currentUserName ?? 'Kullanıcı',
        senderPhotoUrl: _currentUserPhotoUrl,
        senderUserCode: _currentUserCode,
        receiverId: targetUser.uid,
        receiverName: targetUser.displayName ?? targetUser.email?.split('@').first ?? 'Kullanıcı',
        receiverPhotoUrl: targetUser.photoURL,
        receiverUserCode: targetUser.userCode,
        status: FriendRequestStatus.pending,
        createdAt: DateTime.now(),
      );

      await _firestore.collection('friendRequests').add(request.toMap());
      
      await _loadOutgoingRequests();
      return true;
    } catch (e) {
      debugPrint('Send friend request error: $e');
      return false;
    }
  }

  // ------------- ARKADAŞLIK İSTEĞİ KABUL ET -------------

  Future<bool> acceptFriendRequest(String requestId) async {
    if (_isGuest || _currentUserId == null) return false;

    try {
      final requestDoc = await _firestore
          .collection('friendRequests')
          .doc(requestId)
          .get();

      if (!requestDoc.exists) return false;

      final request = FriendRequest.fromMap(requestDoc.data()!, requestDoc.id);

      // İsteği güncelle
      await _firestore.collection('friendRequests').doc(requestId).update({
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
      await _firestore.collection('friendRequests').doc(requestId).update({
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
      await _firestore.collection('friendRequests').doc(requestId).delete();
      
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
      // Zaten arkadaş mı?
      final friendDoc = await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('friends')
          .doc(userId)
          .get();

      if (friendDoc.exists) {
        return FriendshipStatus.friends;
      }

      // Gönderilen istek var mı?
      final sentRequest = await _firestore
          .collection('friendRequests')
          .where('senderId', isEqualTo: _currentUserId)
          .where('receiverId', isEqualTo: userId)
          .where('status', isEqualTo: 'pending')
          .get();

      if (sentRequest.docs.isNotEmpty) {
        return FriendshipStatus.requestSent;
      }

      // Gelen istek var mı?
      final receivedRequest = await _firestore
          .collection('friendRequests')
          .where('senderId', isEqualTo: userId)
          .where('receiverId', isEqualTo: _currentUserId)
          .where('status', isEqualTo: 'pending')
          .get();

      if (receivedRequest.docs.isNotEmpty) {
        return FriendshipStatus.requestReceived;
      }

      return FriendshipStatus.none;
    } catch (e) {
      debugPrint('Check friendship status error: $e');
      return FriendshipStatus.none;
    }
  }

  // Verileri yenile
  Future<void> refresh() async {
    if (_isGuest) return;
    
    await _loadFriends();
    await _loadIncomingRequests();
    await _loadOutgoingRequests();
  }
}

enum FriendshipStatus {
  none,           // Hiçbir ilişki yok
  friends,        // Zaten arkadaş
  requestSent,    // İstek gönderildi
  requestReceived // İstek alındı
}

