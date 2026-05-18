import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/friend_duel_topics.dart';
import '../localization/app_localizations.dart';
import '../models/game_mechanics.dart';
import '../providers/locale_provider.dart';
import '../services/auth_service.dart';
import '../services/friend_duel_service.dart';
import 'friend_duel_play_screen.dart';

/// Konu seçimi + 10 sn hazırlık (Firestore senkron).
class FriendDuelTopicScreen extends StatefulWidget {
  const FriendDuelTopicScreen({
    super.key,
    required this.sessionId,
    required this.onBack,
  });

  final String sessionId;
  final VoidCallback onBack;

  @override
  State<FriendDuelTopicScreen> createState() => _FriendDuelTopicScreenState();
}

class _FriendDuelTopicScreenState extends State<FriendDuelTopicScreen> {
  final PageController _pageController = PageController(viewportFraction: 0.82);
  int _currentPage = 0;
  bool _picking = false;
  bool _openedPlay = false;
  Timer? _prepTicker;

  @override
  void dispose() {
    _prepTicker?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  String _topicTitle(TopicType t, AppLocalizations loc) {
    switch (t) {
      case TopicType.counting:
        return loc.get('topic_counting');
      case TopicType.addition:
        return loc.get('topic_addition');
      case TopicType.subtraction:
        return loc.get('topic_subtraction');
      case TopicType.multiplication:
        return loc.get('topic_multiplication');
      case TopicType.geometry:
        return loc.get('topic_geometry');
      default:
        return t.name;
    }
  }

  Color _topicColor(TopicType t) {
    switch (t) {
      case TopicType.counting:
        return const Color(0xFF43A047);
      case TopicType.addition:
        return const Color(0xFF1E88E5);
      case TopicType.subtraction:
        return const Color(0xFFE53935);
      case TopicType.multiplication:
        return const Color(0xFF8E24AA);
      case TopicType.geometry:
        return const Color(0xFFFB8C00);
      default:
        return Colors.blue;
    }
  }

  String _opponentName(Map<String, dynamic>? data, String myUid) {
    if (data == null) return '';
    final host = data['hostUserId'] as String? ?? '';
    if (myUid == host) {
      return data['guestDisplayName'] as String? ?? '';
    }
    return data['hostDisplayName'] as String? ?? '';
  }

  Future<void> _pickTopic(TopicType topic) async {
    if (_picking) return;
    final uid = context.read<AuthService>().currentUser?.uid;
    if (uid == null) return;
    setState(() => _picking = true);
    final ok = await context.read<FriendDuelService>().pickTopic(
          sessionId: widget.sessionId,
          userId: uid,
          topic: topic,
        );
    if (!mounted) return;
    setState(() => _picking = false);
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).get('friend_duel_topic_busy'))),
      );
    }
  }

  void _ensurePrepTicker() {
    _prepTicker ??= Timer.periodic(const Duration(milliseconds: 400), (_) async {
      if (!mounted) return;
      final uid = context.read<AuthService>().currentUser?.uid;
      if (uid == null) return;
      await context.read<FriendDuelService>().startPlayingIfPrepDone(
            sessionId: widget.sessionId,
            userId: uid,
          );
      setState(() {});
    });
  }

  void _openPlayIfNeeded(String? status) {
    if (_openedPlay || status != 'playing') return;
    _openedPlay = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (ctx) => FriendDuelPlayScreen(
            sessionId: widget.sessionId,
            onExit: () => Navigator.of(ctx).popUntil((r) => r.isFirst),
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations(context.watch<LocaleProvider>().locale);
    final svc = context.read<FriendDuelService>();
    final uid = context.read<AuthService>().currentUser?.uid ?? '';

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF2196F3), Color(0xFFE8F5E9)],
          ),
        ),
        child: SafeArea(
          child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: svc.sessionStream(widget.sessionId),
            builder: (context, snap) {
              final data = snap.data?.data();
              final status = data?['status'] as String?;
              final opponent = _opponentName(data, uid);
              final prepEnds = (data?['prepEndsAtMs'] as num?)?.toInt() ?? 0;
              final prepLeft = prepEnds <= 0
                  ? 0
                  : ((prepEnds - DateTime.now().millisecondsSinceEpoch) / 1000)
                      .ceil()
                      .clamp(0, FriendDuelService.prepCountdownSeconds);

              if (status == 'prep') {
                _ensurePrepTicker();
              }
              _openPlayIfNeeded(status);

              final topicKey = data?['topicKey'] as String?;
              final showPrep = status == 'prep' && prepLeft > 0;
              final topicPicked = topicKey != null && topicKey.isNotEmpty;

              return Stack(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Row(
                          children: [
                            IconButton(
                              onPressed: widget.onBack,
                              icon: const Icon(Icons.arrow_back_ios_new),
                            ),
                            Expanded(
                              child: Column(
                                children: [
                                  Text(
                                    loc.get('choose_topic'),
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  if (opponent.isNotEmpty)
                                    Text(
                                      '${loc.get('friend_duel_vs')} $opponent',
                                      style: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.9),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 48),
                          ],
                        ),
                      ),
                      if (topicPicked && !showPrep)
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            loc.get('friend_duel_topic_waiting_other'),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      Expanded(
                        child: PageView.builder(
                          controller: _pageController,
                          itemCount: kFriendDuelTopicTypes.length,
                          onPageChanged: (i) => setState(() => _currentPage = i),
                          itemBuilder: (context, index) {
                            final topic = kFriendDuelTopicTypes[index];
                            final color = _topicColor(topic);
                            final canPick = status == 'topic_pick' && !_picking;
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                              child: Card(
                                elevation: 8,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      CircleAvatar(
                                        radius: 40,
                                        backgroundColor: color.withValues(alpha: 0.2),
                                        child: Icon(Icons.calculate, color: color, size: 40),
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        _topicTitle(topic, loc),
                                        style: TextStyle(
                                          fontSize: 28,
                                          fontWeight: FontWeight.bold,
                                          color: color,
                                        ),
                                      ),
                                      const Spacer(),
                                      SizedBox(
                                        width: double.infinity,
                                        child: FilledButton(
                                          onPressed: canPick ? () => _pickTopic(topic) : null,
                                          style: FilledButton.styleFrom(
                                            backgroundColor: color,
                                            padding: const EdgeInsets.symmetric(vertical: 14),
                                          ),
                                          child: Text(
                                            _picking
                                                ? '...'
                                                : loc.get('play_button').toUpperCase(),
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          kFriendDuelTopicTypes.length,
                          (i) => Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: i == _currentPage ? Colors.white : Colors.white38,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                  if (showPrep)
                    Container(
                      color: Colors.black54,
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              loc.get('friend_duel_prep_title'),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              '$prepLeft',
                              style: const TextStyle(
                                color: Colors.amber,
                                fontSize: 72,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              loc.get('friend_duel_prep_subtitle'),
                              style: const TextStyle(color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
