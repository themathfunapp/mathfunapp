import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../localization/app_localizations.dart';
import '../models/family_member.dart';
import '../models/game_mechanics.dart';
import '../providers/locale_provider.dart';
import '../services/auth_service.dart';
import '../services/family_remote_duel_service.dart';
import '../services/family_service.dart';
import 'family_remote_duel_waiting_screen.dart';

/// Premium: ailedeki çocuğa uzaktan düello daveti (aynı sorular, iki telefon).
class FamilyRemoteDuelSetupScreen extends StatefulWidget {
  final VoidCallback onBack;
  final TopicType? initialTopic;

  const FamilyRemoteDuelSetupScreen({
    super.key,
    required this.onBack,
    this.initialTopic,
  });

  @override
  State<FamilyRemoteDuelSetupScreen> createState() => _FamilyRemoteDuelSetupScreenState();
}

class _FamilyRemoteDuelSetupScreenState extends State<FamilyRemoteDuelSetupScreen>
    with TickerProviderStateMixin {
  final Set<String> _selectedChildIds = {};
  TopicType? _topic;
  bool _busy = false;
  Set<String> _linkedChildIds = {};
  bool _loadingLinkedIds = true;

  late final AnimationController _bgWave;
  late final AnimationController _gentlePulse;

  static const List<TopicType> _topics = [
    TopicType.counting,
    TopicType.addition,
    TopicType.subtraction,
    TopicType.multiplication,
    TopicType.division,
    TopicType.geometry,
    TopicType.fractions,
    TopicType.time,
  ];

  String _topicLabel(AppLocalizations loc, TopicType t) {
    switch (t) {
      case TopicType.counting:
        return loc.get('counting');
      case TopicType.addition:
        return loc.get('addition');
      case TopicType.subtraction:
        return loc.get('subtraction');
      case TopicType.multiplication:
        return loc.get('multiplication');
      case TopicType.division:
        return loc.get('division');
      case TopicType.geometry:
        return loc.get('geometry');
      case TopicType.fractions:
        return loc.get('fractions');
      case TopicType.time:
        return loc.get('time');
      default:
        return t.name;
    }
  }

  Color _topicColor(TopicType t) {
    final settings = TopicGameManager.getTopicSettings()[t];
    return settings?.color ?? Colors.deepPurple;
  }

  List<FamilyMember> _children(FamilyService f) =>
      f.members.where((m) => !m.isParent).toList();

  List<FamilyMember> _eligibleChildren(FamilyService f) =>
      _children(f).where((c) => _linkedChildIds.contains(c.userId)).toList();

  @override
  void initState() {
    super.initState();
    _topic = widget.initialTopic;
    _bgWave = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
    _gentlePulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadLinkedChildIds());
  }

  @override
  void dispose() {
    _bgWave.dispose();
    _gentlePulse.dispose();
    super.dispose();
  }

  Future<void> _loadLinkedChildIds() async {
    final auth = context.read<AuthService>();
    final uid = auth.currentUser?.uid;
    if (uid == null || uid.isEmpty) {
      if (mounted) setState(() => _loadingLinkedIds = false);
      return;
    }
    final ids = await context.read<FamilyRemoteDuelService>().linkedChildUserIdsForHost(uid);
    if (!mounted) return;
    setState(() {
      _linkedChildIds = ids;
      _loadingLinkedIds = false;
      _selectedChildIds.removeWhere((id) => !_linkedChildIds.contains(id));
    });
  }

  Future<void> _sendInvite() async {
    final loc = AppLocalizations(Provider.of<LocaleProvider>(context, listen: false).locale);
    final auth = context.read<AuthService>();
    final topic = _topic;
    final uid = auth.currentUser?.uid;
    if (_selectedChildIds.isEmpty || topic == null || uid == null || uid.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.get('family_remote_duel_snackbar_need_selection'))),
      );
      return;
    }

    final svc = context.read<FamilyRemoteDuelService>();
    for (final childId in _selectedChildIds) {
      final linkedOk = await svc.hostHasLinkedChildOnAccount(uid, childId);
      if (!linkedOk) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(loc.get('family_remote_duel_snackbar_wrong_account')),
          ),
        );
        return;
      }
    }

    setState(() => _busy = true);
    final hostName =
        auth.currentUser?.displayName ?? auth.currentUser?.username ?? 'Ebeveyn';
    final family = context.read<FamilyService>();
    final selectedMembers = family.members
        .where((m) => _selectedChildIds.contains(m.userId))
        .toList();
    final namesById = <String, String>{
      for (final m in selectedMembers) m.userId: m.displayName,
    };

    final res = await svc.createInvite(
      hostUserId: uid,
      hostDisplayName: hostName,
      guestUserIds: _selectedChildIds.toList(),
      guestDisplayNamesById: namesById,
      topic: topic,
    );

    if (!mounted) return;
    setState(() => _busy = false);

    if (res == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loc.get('family_remote_duel_snackbar_send_failed')),
        ),
      );
      return;
    }

    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (ctx) => FamilyRemoteDuelWaitingScreen(
          sessionId: res.sessionId,
          isHost: true,
          onBack: () => Navigator.of(ctx).pop(),
        ),
      ),
    );
  }

  Widget _partyFloaties() {
    return Positioned.fill(
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _bgWave,
          builder: (context, child) {
            final t = _bgWave.value;
            return Stack(
              children: [
                for (var i = 0; i < 12; i++)
                  Positioned(
                    left: (i * 73.0 + 40 * math.sin(t * math.pi * 2 + i)) % 340,
                    top: 80 + (i * 61.0 + 50 * math.cos(t * math.pi * 2 * 0.7 + i * 0.4)) % 420,
                    child: Opacity(
                      opacity: (0.12 + 0.1 * math.sin(t * math.pi * 2 + i)).clamp(0.0, 0.35),
                      child: Transform.rotate(
                        angle: t * math.pi * 0.25 * (i.isEven ? 1 : -1),
                        child: Text(
                          const ['⭐', '✨', '🎯', '🎮', '💫', '🌟'][i % 6],
                          style: const TextStyle(fontSize: 22),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _glassIntroCard(AppLocalizations loc, String hostDisplay) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.22),
            Colors.white.withValues(alpha: 0.08),
          ],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withValues(alpha: 0.25),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.92, end: 1),
            duration: const Duration(milliseconds: 900),
            curve: Curves.elasticOut,
            builder: (context, s, child) => Transform.scale(scale: s, child: child),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.25),
              ),
              child: const Text('⚔️', style: TextStyle(fontSize: 28)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              loc.get('family_remote_duel_intro').replaceAll('{0}', hostDisplay),
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.95),
                fontSize: 14.5,
                height: 1.45,
                fontWeight: FontWeight.w600,
                shadows: const [
                  Shadow(color: Colors.black26, offset: Offset(0, 1), blurRadius: 3),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 4),
      child: Row(
        children: [
          Icon(Icons.auto_awesome, color: Colors.amber.shade200, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.2,
                shadows: [
                  Shadow(color: Colors.black26, offset: Offset(0, 1), blurRadius: 4),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _childPickTile(FamilyMember c, bool sel) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AnimatedScale(
        scale: sel ? 1.02 : 1.0,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        child: Material(
          color: Colors.transparent,
          elevation: sel ? 10 : 2,
          shadowColor: sel ? Colors.amber.withValues(alpha: 0.65) : Colors.black38,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () {
              setState(() {
                if (sel) {
                  _selectedChildIds.remove(c.userId);
                } else {
                  _selectedChildIds.add(c.userId);
                }
              });
            },
            child: Ink(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: sel
                      ? [
                          const Color(0xFFFFCA28),
                          const Color(0xFFFF6F00),
                        ]
                      : [
                          Colors.white.withValues(alpha: 0.18),
                          Colors.white.withValues(alpha: 0.08),
                        ],
                ),
                border: Border.all(
                  color: sel ? Colors.white : Colors.white.withValues(alpha: 0.35),
                  width: sel ? 2.5 : 1,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: sel ? 0.35 : 0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Text('🧒', style: TextStyle(fontSize: 30)),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        c.displayName,
                        style: TextStyle(
                          color: sel ? const Color(0xFF4E342E) : Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        sel ? Icons.check_circle_rounded : Icons.add_circle_outline_rounded,
                        key: ValueKey<bool>(sel),
                        color: sel ? const Color(0xFF33691E) : Colors.white70,
                        size: 32,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _topicChip(TopicType t, bool sel, AppLocalizations loc) {
    final col = _topicColor(t);
    return Padding(
      padding: const EdgeInsets.only(right: 8, bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => _topic = t),
          borderRadius: BorderRadius.circular(24),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                colors: sel
                    ? [col, Color.lerp(col, Colors.white, 0.2)!]
                    : [
                        Colors.white.withValues(alpha: 0.16),
                        Colors.white.withValues(alpha: 0.06),
                      ],
              ),
              border: Border.all(
                color: sel ? Colors.white : Colors.white.withValues(alpha: 0.3),
                width: sel ? 2 : 1,
              ),
              boxShadow: sel
                  ? [
                      BoxShadow(
                        color: col.withValues(alpha: 0.55),
                        blurRadius: 14,
                        offset: const Offset(0, 5),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (sel) const Icon(Icons.star_rounded, color: Colors.white, size: 20),
                if (sel) const SizedBox(width: 6),
                Text(
                  _topicLabel(loc, t),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _lockedTopicPill(AppLocalizations loc) {
    final t = widget.initialTopic!;
    final col = _topicColor(t);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [col, Color.lerp(col, const Color(0xFF7C4DFF), 0.35)!],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.45), width: 2),
        boxShadow: [
          BoxShadow(color: col.withValues(alpha: 0.45), blurRadius: 16, offset: const Offset(0, 6)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🔒', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Text(
            _topicLabel(loc, t),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 17,
            ),
          ),
        ],
      ),
    );
  }

  Widget _rainbowSendButton(AppLocalizations loc) {
    return AnimatedBuilder(
      animation: _gentlePulse,
      builder: (context, child) {
        final p = 1.0 + 0.03 * _gentlePulse.value;
        return Transform.scale(scale: p, child: child);
      },
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            colors: [Color(0xFFFF6D00), Color(0xFFE91E63), Color(0xFF7C4DFF), Color(0xFF00BFA5)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.deepPurple.withValues(alpha: 0.45),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: FilledButton.icon(
          onPressed: _busy ? null : _sendInvite,
          icon: _busy
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.rocket_launch_rounded, size: 26),
          label: Text(
            _busy
                ? loc.get('family_remote_duel_sending')
                : loc.get('family_remote_duel_send_invite').replaceAll('{0}', '${_selectedChildIds.length}'),
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17, letterSpacing: 0.2),
          ),
          style: FilledButton.styleFrom(
            minimumSize: const Size(double.infinity, 56),
            padding: const EdgeInsets.symmetric(vertical: 16),
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
        ),
      ),
    );
  }

  Widget _emptyStateCard({
    required String emoji,
    required String message,
    required AppLocalizations loc,
  }) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            color: Colors.white.withValues(alpha: 0.16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 24),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.88, end: 1),
                duration: const Duration(milliseconds: 700),
                curve: Curves.elasticOut,
                builder: (context, s, child) => Transform.scale(scale: s, child: child),
                child: Text(emoji, style: const TextStyle(fontSize: 56)),
              ),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 16, height: 1.4),
              ),
              const SizedBox(height: 24),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF6A1B9A),
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                ),
                onPressed: widget.onBack,
                child: Text(loc.get('back'), style: const TextStyle(fontWeight: FontWeight.w800)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final loc = AppLocalizations(Provider.of<LocaleProvider>(context).locale);
    final hostDisplay = auth.currentUser?.displayName ??
        auth.currentUser?.username ??
        loc.get('family_remote_duel_host_default');

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedBuilder(
            animation: _bgWave,
            builder: (context, _) {
              final t = _bgWave.value;
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment(-0.8 + 0.5 * math.sin(t * math.pi * 2), -1),
                    end: Alignment(0.6 + 0.35 * math.cos(t * math.pi * 2 * 0.85), 1.15),
                    colors: [
                      Color.lerp(const Color(0xFF5E35B1), const Color(0xFFE91E63), t)!,
                      Color.lerp(const Color(0xFFFF6F00), const Color(0xFF00ACC1), 1 - t)!,
                      const Color(0xFF43A047),
                    ],
                    stops: const [0.0, 0.55, 1.0],
                  ),
                ),
              );
            },
          ),
          _partyFloaties(),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 6, 8, 8),
                  child: Row(
                    children: [
                      Material(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: const CircleBorder(),
                        clipBehavior: Clip.antiAlias,
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                          onPressed: widget.onBack,
                        ),
                      ),
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('⚔️', style: TextStyle(fontSize: 22)),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                loc.get('family_remote_duel_title'),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  shadows: [
                                    Shadow(color: Colors.black26, offset: Offset(0, 2), blurRadius: 4),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),
                Expanded(
                  child: Consumer<FamilyService>(
                    builder: (context, family, _) {
                      if (_loadingLinkedIds) {
                        return Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 56,
                                height: 56,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 4,
                                  strokeCap: StrokeCap.round,
                                ),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                '✨',
                                style: TextStyle(
                                  fontSize: 32,
                                  color: Colors.white.withValues(alpha: 0.9),
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      final kids = _children(family);
                      final eligible = _eligibleChildren(family);

                      if (kids.isEmpty) {
                        return _emptyStateCard(
                          emoji: '👨‍👩‍👧',
                          message: loc.get('family_remote_duel_add_child_hint'),
                          loc: loc,
                        );
                      }

                      if (eligible.isEmpty) {
                        return _emptyStateCard(
                          emoji: '🔐',
                          message: loc.get('family_remote_duel_wrong_account_hint'),
                          loc: loc,
                        );
                      }

                      return ListView(
                        padding: const EdgeInsets.fromLTRB(18, 0, 18, 28),
                        children: [
                          _glassIntroCard(loc, hostDisplay),
                          const SizedBox(height: 22),
                          ...eligible.map((c) => _childPickTile(c, _selectedChildIds.contains(c.userId))),
                          const SizedBox(height: 8),
                          if (widget.initialTopic == null) ...[
                            _sectionLabel(loc.get('family_remote_duel_topic_heading')),
                            Wrap(children: _topics.map((t) => _topicChip(t, _topic == t, loc)).toList()),
                          ] else ...[
                            _sectionLabel(loc.get('family_remote_duel_selected_topic')),
                            _lockedTopicPill(loc),
                          ],
                          const SizedBox(height: 28),
                          _rainbowSendButton(loc),
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                            ),
                            child: Text(
                              loc.get('family_remote_duel_footer_rule'),
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 13,
                                height: 1.4,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
