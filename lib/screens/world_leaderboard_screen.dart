import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:mathfun/localization/app_localizations.dart';
import 'package:mathfun/services/auth_service.dart';
import 'package:mathfun/services/world_leaderboard_sync.dart';

class WorldLeaderboardScreen extends StatefulWidget {
  const WorldLeaderboardScreen({super.key});

  @override
  State<WorldLeaderboardScreen> createState() => _WorldLeaderboardScreenState();
}

class _WorldLeaderboardScreenState extends State<WorldLeaderboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final auth = context.watch<AuthService>();
    final myUid = auth.currentUser?.uid ?? '';

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
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    Expanded(
                      child: Text(
                        loc.get('world_leaderboard_title'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text(
                  loc.get('world_leaderboard_subtitle'),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 13,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicatorSize: TabBarIndicatorSize.label,
                  indicator: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: const Color(0xFF6F63C9).withOpacity(0.45),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.22),
                      width: 1,
                    ),
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white.withOpacity(0.82),
                  tabs: [
                    Tab(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: Text('${loc.get('world_leaderboard_gold_tab')} 🪙'),
                      ),
                    ),
                    Tab(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: Text('${loc.get('world_leaderboard_diamonds_tab')} 💎'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _LeaderboardList(
                      stream: FirebaseFirestore.instance
                          .collection(kWorldCoinsLeaderboard)
                          .orderBy('coins', descending: true)
                          .limit(kWorldLeaderboardQueryLimit)
                          .snapshots(),
                      scoreField: 'coins',
                      scoreEmoji: '🪙',
                      myUid: myUid,
                      loc: loc,
                    ),
                    _LeaderboardList(
                      stream: FirebaseFirestore.instance
                          .collection(kWorldDiamondsLeaderboard)
                          .orderBy('diamonds', descending: true)
                          .limit(kWorldLeaderboardQueryLimit)
                          .snapshots(),
                      scoreField: 'diamonds',
                      scoreEmoji: '💎',
                      myUid: myUid,
                      loc: loc,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LeaderboardList extends StatelessWidget {
  const _LeaderboardList({
    required this.stream,
    required this.scoreField,
    required this.scoreEmoji,
    required this.myUid,
    required this.loc,
  });

  final Stream<QuerySnapshot<Map<String, dynamic>>> stream;
  final String scoreField;
  final String scoreEmoji;
  final String myUid;
  final AppLocalizations loc;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                '${loc.get('error')}: ${snapshot.error}',
                style: const TextStyle(color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator(color: Colors.white));
        }
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return Center(
            child: Text(
              loc.get('world_leaderboard_empty'),
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final rank = index + 1;
            final doc = docs[index];
            final data = doc.data();
            final uid = doc.id;
            final name = (data['displayName'] as String?)?.trim().isNotEmpty == true
                ? data['displayName'] as String
                : 'Oyuncu';
            final photoUrl = (data['photoURL'] as String?)?.trim();
            final emoji = data['profileEmoji'] as String?;
            final score = (data[scoreField] is int) ? data[scoreField] as int : 0;
            final isMe = myUid.isNotEmpty && uid == myUid;

            return Card(
              elevation: isMe ? 4 : 1,
              color: isMe ? const Color(0xFFFFF8E1) : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: isMe
                    ? const BorderSide(color: Color(0xFFFFB300), width: 2)
                    : BorderSide.none,
              ),
              child: ListTile(
                leading: SizedBox(
                  width: 76,
                  child: Row(
                    children: [
                      if (rank <= 3)
                        Icon(
                          Icons.workspace_premium,
                          size: 14,
                          color: _worldLbMedalColor(rank),
                        ),
                      if (rank <= 3) const SizedBox(width: 4),
                      Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: _worldLbMedalColor(rank),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '$rank',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      _buildLeaderboardAvatarWithFallback(uid, photoUrl, emoji),
                    ],
                  ),
                ),
                title: Text(
                  isMe ? '$name (${loc.get('world_leaderboard_you')})' : name,
                  style: TextStyle(
                    fontWeight: isMe ? FontWeight.bold : FontWeight.w600,
                    color: Colors.deepPurple.shade900,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Text(
                  '$scoreEmoji $score',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.deepPurple.shade700,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildLeaderboardAvatar(String? photoUrl, String? emoji) {
    const avatarSize = 28.0;
    if (photoUrl != null && photoUrl.isNotEmpty) {
      if (photoUrl.startsWith('data:image')) {
        final parts = photoUrl.split(',');
        if (parts.length == 2) {
          try {
            final bytes = base64Decode(parts[1]);
            return ClipOval(
              child: Image.memory(
                bytes,
                width: avatarSize,
                height: avatarSize,
                fit: BoxFit.cover,
              ),
            );
          } catch (_) {}
        }
      }
      return CircleAvatar(
        radius: avatarSize / 2,
        backgroundColor: Colors.grey.shade200,
        backgroundImage: NetworkImage(photoUrl),
      );
    }

    if (emoji != null && emoji.isNotEmpty) {
      return CircleAvatar(
        radius: avatarSize / 2,
        backgroundColor: Colors.deepPurple.shade50,
        child: Text(emoji, style: const TextStyle(fontSize: 16)),
      );
    }

    return CircleAvatar(
      radius: avatarSize / 2,
      backgroundColor: Colors.deepPurple.shade50,
      child: const Icon(Icons.person, size: 16, color: Colors.deepPurple),
    );
  }

  Widget _buildLeaderboardAvatarWithFallback(
    String uid,
    String? leaderboardPhotoUrl,
    String? emoji,
  ) {
    if (leaderboardPhotoUrl != null && leaderboardPhotoUrl.isNotEmpty) {
      return _buildLeaderboardAvatar(leaderboardPhotoUrl, emoji);
    }

    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: FirebaseFirestore.instance.collection('users').doc(uid).get(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data();
        final photo = (data?['photoURL'] as String?)?.trim();
        if (photo != null && photo.isNotEmpty) {
          return _buildLeaderboardAvatar(photo, emoji);
        }
        return _buildLeaderboardAvatar(null, emoji);
      },
    );
  }
}

Color _worldLbMedalColor(int rank) {
  if (rank == 1) return const Color(0xFFFFD700);
  if (rank == 2) return const Color(0xFFC0C0C0);
  if (rank == 3) return const Color(0xFFCD7F32);
  return const Color(0xFF5A4FCF);
}
