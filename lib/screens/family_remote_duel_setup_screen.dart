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

class _FamilyRemoteDuelSetupScreenState extends State<FamilyRemoteDuelSetupScreen> {
  final Set<String> _selectedChildIds = {};
  TopicType? _topic;
  bool _busy = false;
  Set<String> _linkedChildIds = {};
  bool _loadingLinkedIds = true;

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
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadLinkedChildIds());
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

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final loc = AppLocalizations(Provider.of<LocaleProvider>(context).locale);
    final hostDisplay = auth.currentUser?.displayName ??
        auth.currentUser?.username ??
        loc.get('family_remote_duel_host_default');

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1B2838), Color(0xFF2E5266)],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: widget.onBack,
                  ),
                  Expanded(
                    child: Text(
                      loc.get('family_remote_duel_title'),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
              Expanded(
                child: Consumer<FamilyService>(
                  builder: (context, family, _) {
                    if (_loadingLinkedIds) {
                      return const Center(
                        child: CircularProgressIndicator(color: Colors.white70),
                      );
                    }

                    final kids = _children(family);
                    final eligible = _eligibleChildren(family);

                    if (kids.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.family_restroom,
                                  size: 56, color: Colors.white54),
                              const SizedBox(height: 16),
                              Text(
                                loc.get('family_remote_duel_add_child_hint'),
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.white70, fontSize: 16),
                              ),
                              const SizedBox(height: 24),
                              FilledButton(
                                onPressed: widget.onBack,
                                child: Text(loc.get('back')),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    if (eligible.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.phonelink_lock, size: 56, color: Colors.amber),
                              const SizedBox(height: 16),
                              Text(
                                loc.get('family_remote_duel_wrong_account_hint'),
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.white70, fontSize: 15, height: 1.35),
                              ),
                              const SizedBox(height: 24),
                              FilledButton(
                                onPressed: widget.onBack,
                                child: Text(loc.get('back')),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return ListView(
                      padding: const EdgeInsets.all(20),
                      children: [
                        Text(
                          loc.get('family_remote_duel_intro').replaceAll('{0}', hostDisplay),
                          style: const TextStyle(color: Colors.white70, fontSize: 15),
                        ),
                        const SizedBox(height: 16),
                        ...eligible.map((c) {
                          final sel = _selectedChildIds.contains(c.userId);
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Material(
                              color: sel
                                  ? Colors.amber.withValues(alpha: 0.35)
                                  : Colors.white.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(14),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(14),
                                onTap: () {
                                  setState(() {
                                    if (sel) {
                                      _selectedChildIds.remove(c.userId);
                                    } else {
                                      _selectedChildIds.add(c.userId);
                                    }
                                  });
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Row(
                                    children: [
                                      const Text('🧒', style: TextStyle(fontSize: 26)),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          c.displayName,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 17,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      Icon(
                                        sel ? Icons.check_circle : Icons.circle_outlined,
                                        color: sel ? Colors.amber : Colors.white38,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                        const SizedBox(height: 20),
                        if (widget.initialTopic == null) ...[
                          Text(
                            loc.get('family_remote_duel_topic_heading'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _topics.map((t) {
                              final sel = _topic == t;
                              final col = _topicColor(t);
                              return FilterChip(
                                selected: sel,
                                label: Text(_topicLabel(loc, t)),
                                onSelected: (_) => setState(() => _topic = t),
                                selectedColor: col.withValues(alpha: 0.5),
                                checkmarkColor: Colors.white,
                                labelStyle: const TextStyle(color: Colors.white),
                              );
                            }).toList(),
                          ),
                        ] else ...[
                          Text(
                            loc.get('family_remote_duel_selected_topic'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: _topicColor(widget.initialTopic!).withValues(alpha: 0.35),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _topicColor(widget.initialTopic!).withValues(alpha: 0.85),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.lock, color: Colors.white70, size: 16),
                                const SizedBox(width: 8),
                                Text(
                                  _topicLabel(loc, widget.initialTopic!),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 28),
                        FilledButton.icon(
                          onPressed: _busy ? null : _sendInvite,
                          icon: _busy
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.send),
                          label: Text(
                            _busy
                                ? loc.get('family_remote_duel_sending')
                                : loc
                                    .get('family_remote_duel_send_invite')
                                    .replaceAll('{0}', '${_selectedChildIds.length}'),
                          ),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            backgroundColor: Colors.teal.shade600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          loc.get('family_remote_duel_footer_rule'),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.65),
                            fontSize: 13,
                            height: 1.35,
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
      ),
    );
  }
}
