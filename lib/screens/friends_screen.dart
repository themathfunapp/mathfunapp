import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/friend_service.dart';
import '../models/app_user.dart';
import '../models/friend_request.dart';
import '../models/friendship.dart';
import '../localization/app_localizations.dart';

class FriendsScreen extends StatefulWidget {
  final VoidCallback onBack;

  const FriendsScreen({
    super.key,
    required this.onBack,
  });

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  List<AppUser> _searchResults = [];
  bool _isSearching = false;
  Map<String, FriendshipStatus> _friendshipStatuses = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      final friendService = Provider.of<FriendService>(context, listen: false);
      final results = await friendService.searchUsers(query);
      
      // Her kullanıcı için arkadaşlık durumunu kontrol et
      final statuses = <String, FriendshipStatus>{};
      for (final user in results) {
        statuses[user.uid] = await friendService.checkFriendshipStatus(user.uid);
      }

      setState(() {
        _searchResults = results;
        _friendshipStatuses = statuses;
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _isSearching = false;
      });
      _showErrorSnackbar('Arama hatası: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final friendService = Provider.of<FriendService>(context);
    final locale = Localizations.localeOf(context);
    final localizations = AppLocalizations(locale);
    final isGuest = authService.isGuest;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF667eea), Color(0xFF764ba2)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ÜST BAR
              _buildTopBar(localizations),
              
              const SizedBox(height: 8),

              // MİSAFİR UYARISI
              if (isGuest) _buildGuestWarning(localizations),

              // TAB BAR
              if (!isGuest) _buildTabBar(localizations, friendService),

              // İÇERİK
              Expanded(
                child: isGuest
                    ? _buildGuestContent(localizations)
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          _buildFriendsTab(friendService, localizations),
                          _buildRequestsTab(friendService, localizations),
                          _buildSearchTab(friendService, localizations),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(AppLocalizations localizations) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // GERİ BUTONU
          GestureDetector(
            onTap: widget.onBack,
            child: Container(
              width: 55,
              height: 55,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFFFD93D), Color(0xFFFF6B6B)],
                ),
                borderRadius: BorderRadius.circular(27.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '←',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text('👑', style: TextStyle(fontSize: 16)),
                  ],
                ),
              ),
            ),
          ),
          // BAŞLIK
          Text(
            localizations.get('friends'),
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          // PLACEHOLDER
          const SizedBox(width: 55),
        ],
      ),
    );
  }

  Widget _buildGuestWarning(AppLocalizations localizations) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.shade300),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              localizations.get('guest_cannot_add_friends'),
              style: TextStyle(
                color: Colors.orange.shade800,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuestContent(AppLocalizations localizations) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(32),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🔒', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            Text(
              localizations.get('friends_locked_title'),
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2d3436),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              localizations.get('friends_locked_description'),
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, '/welcome');
              },
              icon: const Icon(Icons.person_add),
              label: Text(localizations.get('create_account')),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF667eea),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar(AppLocalizations localizations, FriendService friendService) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        indicatorPadding: const EdgeInsets.all(4),
        labelColor: const Color(0xFF667eea),
        unselectedLabelColor: Colors.white,
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
        tabs: [
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.people, size: 18),
                const SizedBox(width: 4),
                Text(localizations.get('friends_tab')),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.mail, size: 18),
                const SizedBox(width: 4),
                Text(localizations.get('requests_tab')),
                if (friendService.pendingRequestsCount > 0) ...[
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${friendService.pendingRequestsCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.search, size: 18),
                const SizedBox(width: 4),
                Text(localizations.get('search_tab')),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ------------- ARKADAŞLAR TAB -------------

  Widget _buildFriendsTab(FriendService friendService, AppLocalizations localizations) {
    return StreamBuilder<List<Friendship>>(
      stream: friendService.friendsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.white),
          );
        }

        final friends = snapshot.data ?? [];

        if (friends.isEmpty) {
          return _buildEmptyState(
            emoji: '👥',
            title: localizations.get('no_friends_title'),
            description: localizations.get('no_friends_description'),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: friends.length,
          itemBuilder: (context, index) {
            return _buildFriendCard(friends[index], friendService, localizations);
          },
        );
      },
    );
  }

  Widget _buildFriendCard(Friendship friend, FriendService friendService, AppLocalizations localizations) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // AVATAR
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF667eea), Color(0xFF764ba2)],
              ),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                friend.friendName.isNotEmpty 
                    ? friend.friendName[0].toUpperCase() 
                    : '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // BİLGİLER
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  friend.friendName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2d3436),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'ID: ${friend.friendId.length > 12 ? '${friend.friendId.substring(0, 12)}...' : friend.friendId}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          // SİL BUTONU
          IconButton(
            onPressed: () => _showRemoveFriendDialog(friend, friendService, localizations),
            icon: Icon(Icons.person_remove, color: Colors.red.shade400),
            tooltip: localizations.get('remove_friend'),
          ),
        ],
      ),
    );
  }

  // ------------- İSTEKLER TAB -------------

  Widget _buildRequestsTab(FriendService friendService, AppLocalizations localizations) {
    return StreamBuilder<List<FriendRequest>>(
      stream: friendService.incomingRequestsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.white),
          );
        }

        final requests = snapshot.data ?? [];

        if (requests.isEmpty) {
          return _buildEmptyState(
            emoji: '📭',
            title: localizations.get('no_requests_title'),
            description: localizations.get('no_requests_description'),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: requests.length,
          itemBuilder: (context, index) {
            return _buildRequestCard(requests[index], friendService, localizations);
          },
        );
      },
    );
  }

  Widget _buildRequestCard(FriendRequest request, FriendService friendService, AppLocalizations localizations) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // AVATAR
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.orange.shade400, Colors.orange.shade700],
              ),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                request.senderName.isNotEmpty 
                    ? request.senderName[0].toUpperCase() 
                    : '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // BİLGİLER
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  request.senderName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2d3436),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  localizations.get('wants_to_be_friend'),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          // BUTONLAR
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // KABUL
              IconButton(
                onPressed: () async {
                  final success = await friendService.acceptFriendRequest(request.id);
                  if (success) {
                    _showSuccessSnackbar(localizations.get('friend_request_accepted'));
                  }
                },
                icon: const Icon(Icons.check_circle, color: Colors.green, size: 32),
                tooltip: localizations.get('accept'),
              ),
              // REDDET
              IconButton(
                onPressed: () async {
                  final success = await friendService.rejectFriendRequest(request.id);
                  if (success) {
                    _showSuccessSnackbar(localizations.get('friend_request_rejected'));
                  }
                },
                icon: Icon(Icons.cancel, color: Colors.red.shade400, size: 32),
                tooltip: localizations.get('reject'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ------------- ARAMA TAB -------------

  Widget _buildSearchTab(FriendService friendService, AppLocalizations localizations) {
    return Column(
      children: [
        // ARAMA KUTUSU
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: localizations.get('search_hint'),
                    border: InputBorder.none,
                    icon: const Icon(Icons.search, color: Color(0xFF667eea)),
                  ),
                  onSubmitted: (_) => _performSearch(),
                ),
              ),
              if (_searchController.text.isNotEmpty)
                IconButton(
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchResults = [];
                    });
                  },
                  icon: const Icon(Icons.clear, color: Colors.grey),
                ),
              ElevatedButton(
                onPressed: _performSearch,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF667eea),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                child: Text(
                  localizations.get('search'),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),

        // SONUÇLAR
        Expanded(
          child: _isSearching
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                )
              : _searchResults.isEmpty
                  ? _buildEmptyState(
                      emoji: '🔍',
                      title: localizations.get('search_users_title'),
                      description: localizations.get('search_users_description'),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        return _buildSearchResultCard(
                          _searchResults[index],
                          friendService,
                          localizations,
                        );
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildSearchResultCard(AppUser user, FriendService friendService, AppLocalizations localizations) {
    final status = _friendshipStatuses[user.uid] ?? FriendshipStatus.none;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // AVATAR
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF667eea), Color(0xFF764ba2)],
              ),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: user.photoURL != null
                  ? ClipOval(
                      child: Image.network(
                        user.photoURL!,
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Text(
                          (user.displayName ?? user.email ?? '?')[0].toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    )
                  : Text(
                      (user.displayName ?? user.email ?? '?')[0].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          // BİLGİLER
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.displayName ?? user.email?.split('@').first ?? 'Kullanıcı',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2d3436),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user.email ?? 'ID: ${user.uid.length > 12 ? '${user.uid.substring(0, 12)}...' : user.uid}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          // AKSIYON BUTONU
          _buildActionButton(user, status, friendService, localizations),
        ],
      ),
    );
  }

  Widget _buildActionButton(AppUser user, FriendshipStatus status, FriendService friendService, AppLocalizations localizations) {
    switch (status) {
      case FriendshipStatus.friends:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.green.shade100,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check, color: Colors.green.shade700, size: 16),
              const SizedBox(width: 4),
              Text(
                localizations.get('already_friends'),
                style: TextStyle(
                  color: Colors.green.shade700,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      
      case FriendshipStatus.requestSent:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.orange.shade100,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.hourglass_empty, color: Colors.orange.shade700, size: 16),
              const SizedBox(width: 4),
              Text(
                localizations.get('request_sent'),
                style: TextStyle(
                  color: Colors.orange.shade700,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      
      case FriendshipStatus.requestReceived:
        return ElevatedButton.icon(
          onPressed: () async {
            // İstekler tabına git
            _tabController.animateTo(1);
          },
          icon: const Icon(Icons.mail, size: 16),
          label: Text(localizations.get('view_request')),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        );
      
      case FriendshipStatus.none:
        return ElevatedButton.icon(
          onPressed: () async {
            final success = await friendService.sendFriendRequest(user);
            if (success) {
              _showSuccessSnackbar(localizations.get('friend_request_sent'));
              // Durumu güncelle
              setState(() {
                _friendshipStatuses[user.uid] = FriendshipStatus.requestSent;
              });
            } else {
              _showErrorSnackbar(localizations.get('friend_request_failed'));
            }
          },
          icon: const Icon(Icons.person_add, size: 16),
          label: Text(localizations.get('add_friend')),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF667eea),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        );
    }
  }

  Widget _buildEmptyState({
    required String emoji,
    required String title,
    required String description,
  }) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(32),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2d3436),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showRemoveFriendDialog(Friendship friend, FriendService friendService, AppLocalizations localizations) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(localizations.get('remove_friend')),
        content: Text(
          localizations.get('remove_friend_confirm').replaceAll('{name}', friend.friendName),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(localizations.get('cancel')),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await friendService.removeFriend(friend.friendId);
              if (success) {
                _showSuccessSnackbar(localizations.get('friend_removed'));
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(localizations.get('remove')),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}

