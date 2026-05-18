import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/friend_service.dart';
import '../services/friend_duel_service.dart';
import '../models/app_user.dart';
import '../models/friend_request.dart';
import '../models/friendship.dart';
import '../models/friend_duel_invite.dart';
import '../localization/app_localizations.dart';
import '../providers/locale_provider.dart';
import 'welcome_screen.dart';
import 'app_screen_wrappers.dart';
import '../utils/friend_duel_invite_flow.dart';
import '../widgets/player_code_visual.dart';
import '../widgets/animated_friends_search_button.dart';

class FriendsScreen extends StatefulWidget {
  final VoidCallback onBack;

  /// 0 = arkadaşlar, 1 = istekler; 2 = arama paneli (üst arama ikonu ile aynı)
  final int initialTabIndex;

  const FriendsScreen({
    super.key,
    required this.onBack,
    this.initialTabIndex = 0,
  });

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  List<AppUser> _searchResults = [];
  bool _isSearching = false;
  bool _searchPanelOpen = false;
  Map<String, FriendshipStatus> _friendshipStatuses = {};
  Stream<List<FriendDuelInvite>>? _duelInvitesStream;
  bool _duelStreamReady = false;

  @override
  void initState() {
    super.initState();
    _searchPanelOpen = widget.initialTabIndex == 2;
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTabIndex.clamp(0, 1),
    );
    _searchController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_duelStreamReady) return;
    final uid = context.read<AuthService>().currentUser?.uid ?? '';
    if (uid.isNotEmpty) {
      _duelInvitesStream =
          context.read<FriendDuelService>().incomingInvitesStream(uid);
    }
    _duelStreamReady = true;
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _navigateToCreateAccount() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    try {
      await authService.signOut();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => WelcomeScreen(
            onSignInComplete: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const HomeScreenWrapper()),
              );
            },
            onSkip: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const HomeScreenWrapper()),
              );
            },
          ),
        ),
        (route) => false,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppLocalizations.of(context).get('error_occurred')}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
      _showErrorSnackbar(
        AppLocalizations.of(context)
            .get('friends_search_error')
            .replaceAll('{error}', '$e'),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final friendService = Provider.of<FriendService>(context, listen: false);
    final locale = Provider.of<LocaleProvider>(context).locale;
    final localizations = AppLocalizations(locale);
    final isGuest = authService.isGuest;

    return Scaffold(
      resizeToAvoidBottomInset: true,
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

              // TAB BAR (yalnızca Arkadaşlar + İstekler; arama üst ikondan)
              if (!isGuest && !_searchPanelOpen)
                Selector<FriendService, int>(
                  selector: (_, fs) => fs.pendingRequestsCount,
                  builder: (context, pendingCount, _) =>
                      _buildTabBar(localizations, pendingCount),
                ),

              // İÇERİK
              Expanded(
                child: isGuest
                    ? _buildGuestContent(localizations)
                    : _searchPanelOpen
                        ? _buildSearchPanel(friendService, localizations)
                        : TabBarView(
                            controller: _tabController,
                            children: [
                              _buildFriendsTab(friendService, localizations),
                              _buildRequestsTab(friendService, localizations),
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
    final authService = Provider.of<AuthService>(context, listen: false);
    final currentUser = authService.currentUser;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
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
          // BAŞLIK ve oyuncu kodu (ön ek soluk)
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  localizations.get('friends'),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                if (currentUser != null && !authService.isGuest)
                  GestureDetector(
                    onTap: () => _copyUserCode(AppLocalizations.of(context), currentUser.playerCode),
                    child: Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.copy, size: 14, color: Colors.white70),
                          const SizedBox(width: 6),
                          PlayerCodeVisual(
                            fullCode: currentUser.playerCode,
                            fontSize: 12,
                            letterSpacing: 1,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (!authService.isGuest && !_searchPanelOpen)
            AnimatedFriendsSearchButton(
              tooltip: localizations.get('search_tab'),
              onPressed: () => setState(() => _searchPanelOpen = true),
            ),
          IconButton(
            onPressed: () => _showIdInfoDialog(localizations),
            icon: const Icon(Icons.info_outline, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Future<void> _copyUserCode(AppLocalizations localizations, String code) async {
    await Clipboard.setData(ClipboardData(text: code));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 2),
              child: Icon(Icons.check, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                localizations.friendsPlayerCodeCopied(code),
                maxLines: 4,
                softWrap: true,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showIdInfoDialog(AppLocalizations localizations) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final currentUser = authService.currentUser;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Text('🎮 '),
            Text(localizations.friendsPlayerCodeTitle),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (currentUser != null && !authService.isGuest) ...[
              Text(localizations.friendsPlayerCodeYourLabel, style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    PlayerCodeVisual(
                      fullCode: currentUser.playerCode,
                      fontSize: 24,
                      letterSpacing: 2,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            Text(
              localizations.friendsPlayerCodeInstructions,
              style: const TextStyle(height: 1.6),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF667eea),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(localizations.friendsPlayerCodeOk, style: const TextStyle(color: Colors.white)),
          ),
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
              onPressed: _navigateToCreateAccount,
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

  Widget _buildTabBar(AppLocalizations localizations, int pendingRequestsCount) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
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
        indicatorPadding: const EdgeInsets.fromLTRB(2, 4, 2, 4),
        labelColor: const Color(0xFF667eea),
        unselectedLabelColor: Colors.white,
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
        tabs: [
          Tab(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.center,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.people, size: 16),
                  const SizedBox(width: 3),
                  Text(localizations.get('friends_tab')),
                ],
              ),
            ),
          ),
          Tab(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.center,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.mail, size: 16),
                  const SizedBox(width: 3),
                  Text(localizations.get('requests_tab')),
                  if (pendingRequestsCount > 0) ...[
                    const SizedBox(width: 3),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$pendingRequestsCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _closeSearchPanel() {
    setState(() {
      _searchPanelOpen = false;
      _searchController.clear();
      _searchResults = [];
    });
  }

  Widget _buildSearchPanel(
    FriendService friendService,
    AppLocalizations localizations,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              IconButton(
                onPressed: _closeSearchPanel,
                icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
              ),
              Expanded(
                child: Text(
                  localizations.get('search_tab'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(child: _buildSearchTab(friendService, localizations)),
      ],
    );
  }

  // ------------- ARKADAŞLAR TAB -------------

  Widget _buildFriendsTab(FriendService friendService, AppLocalizations localizations) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_duelInvitesStream != null)
          StreamBuilder<List<FriendDuelInvite>>(
            stream: _duelInvitesStream,
            builder: (context, duelSnap) {
              if (duelSnap.connectionState == ConnectionState.waiting &&
                  !duelSnap.hasData) {
                return const SizedBox.shrink();
              }
              final invites = duelSnap.data ?? [];
              if (invites.isEmpty) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: invites
                      .map((i) => _IncomingDuelInviteCard(
                            invite: i,
                            localizations: localizations,
                            onAccept: () => _acceptFriendDuelInvite(i, friendService),
                            onDecline: () => _declineFriendDuelInvite(i),
                          ))
                      .toList(),
                ),
              );
            },
          ),
        Expanded(
          child: ListenableBuilder(
            listenable: friendService,
            builder: (context, _) {
              if (!friendService.friendsHydrated) {
                return const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                );
              }

              final friends = friendService.friends;

              if (friends.isEmpty) {
                return _buildEmptyState(
                  emoji: '👥',
                  title: localizations.get('no_friends_title'),
                  description: localizations.get('no_friends_description'),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                itemCount: friends.length,
                itemBuilder: (context, index) {
                  return _buildFriendCard(friends[index], friendService, localizations);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _declineFriendDuelInvite(FriendDuelInvite invite) async {
    final uid = context.read<AuthService>().currentUser?.uid;
    if (uid == null) return;
    await context.read<FriendDuelService>().declineInvite(invite.id, uid);
  }

  Future<void> _acceptFriendDuelInvite(FriendDuelInvite invite, FriendService friendService) async {
    await FriendDuelInviteFlow.openInviteeScreen(context, invite: invite);
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
      child: Column(
        children: [
          Row(
            children: [
              // AVATAR
              Container(
                width: 50,
                height: 50,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
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
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.purple.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: friend.friendUserCode != null &&
                              friend.friendUserCode!.isNotEmpty
                          ? PlayerCodeVisual(
                              fullCode: friend.friendUserCode!,
                              fontSize: 11,
                              letterSpacing: 1,
                              color: Colors.purple.shade700,
                              prefixOpacity: 0.38,
                            )
                          : Row(
                              mainAxisSize: MainAxisSize.min,
                              textDirection: TextDirection.ltr,
                              children: [
                                Opacity(
                                  opacity: 0.38,
                                  child: Text(
                                    AppUser.playerCodePrefix,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.purple.shade700,
                                    ),
                                  ),
                                ),
                                Text(
                                  '••••••••••',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.purple.shade700,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ],
                ),
              ),
              // SİL BUTONU
              IconButton(
                onPressed: () => _showRemoveFriendDialog(friend, friendService, localizations),
                icon: Icon(Icons.person_remove, color: Colors.red.shade400, size: 20),
                tooltip: localizations.get('remove_friend'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // DÜELLO BUTONU
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _challengeToDuel(friend),
              icon: const Icon(Icons.sports_mma, size: 18),
              label: Text(localizations.get('invite_friend_to_duel')),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _challengeToDuel(Friendship friend) {
    FriendDuelInviteFlow.showSendInviteDialog(context, friend: friend);
  }

  // ------------- İSTEKLER TAB -------------

  Widget _buildRequestsTab(FriendService friendService, AppLocalizations localizations) {
    return ListenableBuilder(
      listenable: friendService,
      builder: (context, _) {
        final requests = friendService.incomingRequests;

        if (requests.isEmpty) {
          return _buildEmptyState(
            emoji: '📭',
            title: localizations.get('no_requests_title'),
            description: localizations.get('no_requests_description'),
          );
        }

        return RefreshIndicator(
          onRefresh: friendService.refresh,
          color: const Color(0xFF667eea),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: requests.length,
            itemBuilder: (context, index) {
              return _buildRequestCard(requests[index], friendService, localizations);
            },
          ),
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
                child: Builder(
                  builder: (context) {
                    final q = _searchController.text.trim();
                    final idEntryMode =
                        q.isEmpty || RegExp(r'^\d{0,10}$').hasMatch(q);
                    return Row(
                      children: [
                        if (idEntryMode) ...[
                          Opacity(
                            opacity: 0.42,
                            child: Text(
                              AppUser.playerCodePrefix,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.grey.shade700,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: localizations.friendsSearchHint,
                              border: InputBorder.none,
                              icon: const Icon(Icons.search, color: Color(0xFF667eea)),
                            ),
                            keyboardType: idEntryMode
                                ? TextInputType.number
                                : TextInputType.text,
                            inputFormatters: idEntryMode
                                ? <TextInputFormatter>[
                                    FilteringTextInputFormatter.digitsOnly,
                                    LengthLimitingTextInputFormatter(
                                      AppUser.playerCodeSuffixLength,
                                    ),
                                  ]
                                : null,
                            onSubmitted: (_) => _performSearch(),
                          ),
                        ),
                      ],
                    );
                  },
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

        // SONUÇLAR (klavye açıkken taşmayı önlemek için kaydırılabilir boş durum)
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (_isSearching) {
                return const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                );
              }
              if (_searchResults.isEmpty) {
                return SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: Center(
                      child: _buildEmptyState(
                        emoji: '🔍',
                        title: localizations.get('search_users_title'),
                        description: localizations.get('search_users_description'),
                      ),
                    ),
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  return _buildSearchResultCard(
                    _searchResults[index],
                    friendService,
                    localizations,
                  );
                },
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
                  user.displayName ??
                      user.email?.split('@').first ??
                      localizations.get('default_player_name'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2d3436),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.purple.shade50,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: PlayerCodeVisual(
                        fullCode: user.playerCode,
                        fontSize: 10,
                        letterSpacing: 0.5,
                        color: Colors.purple.shade700,
                        prefixOpacity: 0.38,
                      ),
                    ),
                  ],
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
            final err = await friendService.sendFriendRequest(user);
            if (!mounted) return;
            if (err == null) {
              _showSuccessSnackbar(localizations.get('friend_request_sent'));
              setState(() {
                _friendshipStatuses[user.uid] = FriendshipStatus.requestSent;
              });
            } else if (err == 'already_sent') {
              _showSuccessSnackbar(localizations.get('request_sent'));
              setState(() {
                _friendshipStatuses[user.uid] = FriendshipStatus.requestSent;
              });
            } else if (err == 'already_friends') {
              setState(() {
                _friendshipStatuses[user.uid] = FriendshipStatus.friends;
              });
              _showSuccessSnackbar(localizations.get('already_friends'));
            } else if (err == 'guest') {
              _showErrorSnackbar(localizations.get('guest_cannot_add_friends'));
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
        content: Text(
          message,
          maxLines: 5,
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          maxLines: 5,
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}

class _IncomingDuelInviteCard extends StatefulWidget {
  const _IncomingDuelInviteCard({
    required this.invite,
    required this.localizations,
    required this.onAccept,
    required this.onDecline,
  });

  final FriendDuelInvite invite;
  final AppLocalizations localizations;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  @override
  State<_IncomingDuelInviteCard> createState() => _IncomingDuelInviteCardState();
}

class _IncomingDuelInviteCardState extends State<_IncomingDuelInviteCard> {
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sec = widget.invite.secondsRemaining;
    final loc = widget.localizations;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.orange.shade800,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Text('⚔️', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  loc.get('friend_duel_invite_banner')
                      .replaceAll('{name}', widget.invite.fromDisplayName),
                  style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.25),
                ),
              ),
              Text(
                '${sec}s',
                style: const TextStyle(
                  color: Colors.amber,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: widget.onDecline,
                child: Text(loc.get('decline'), style: const TextStyle(color: Colors.white70)),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.amber.shade300,
                  foregroundColor: Colors.black87,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                onPressed: sec > 0 ? widget.onAccept : null,
                child: Text(loc.get('accept')),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

