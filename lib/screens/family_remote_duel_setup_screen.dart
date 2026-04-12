import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/family_member.dart';
import '../models/game_mechanics.dart';
import '../services/auth_service.dart';
import '../services/family_remote_duel_service.dart';
import '../services/family_service.dart';
import 'family_remote_duel_waiting_screen.dart';

/// Premium: ailedeki çocuğa uzaktan düello daveti (aynı sorular, iki telefon).
class FamilyRemoteDuelSetupScreen extends StatefulWidget {
  final VoidCallback onBack;

  const FamilyRemoteDuelSetupScreen({super.key, required this.onBack});

  @override
  State<FamilyRemoteDuelSetupScreen> createState() => _FamilyRemoteDuelSetupScreenState();
}

class _FamilyRemoteDuelSetupScreenState extends State<FamilyRemoteDuelSetupScreen> {
  FamilyMember? _child;
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

  String _topicLabel(TopicType t) {
    switch (t) {
      case TopicType.counting:
        return 'Sayma';
      case TopicType.addition:
        return 'Toplama';
      case TopicType.subtraction:
        return 'Çıkarma';
      case TopicType.multiplication:
        return 'Çarpma';
      case TopicType.division:
        return 'Bölme';
      case TopicType.geometry:
        return 'Geometri';
      case TopicType.fractions:
        return 'Kesirler';
      case TopicType.time:
        return 'Saat';
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
      if (_child != null && !_linkedChildIds.contains(_child!.userId)) {
        _child = null;
      }
    });
  }

  Future<void> _sendInvite() async {
    final auth = context.read<AuthService>();
    final child = _child;
    final topic = _topic;
    final uid = auth.currentUser?.uid;
    if (child == null || topic == null || uid == null || uid.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Çocuk ve konu seçin.')),
      );
      return;
    }

    final svc = context.read<FamilyRemoteDuelService>();
    final linkedOk = await svc.hostHasLinkedChildOnAccount(uid, child.userId);
    if (!linkedOk) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Bu hesaptan uzaktan düello gönderilemez. Aynı cihazda çocuk hesabıyla oturum açıksanız, '
            'daveti ebeveyn hesabınızla (aile verisinin bulunduğu hesap) göndermeniz gerekir.',
          ),
        ),
      );
      return;
    }

    setState(() => _busy = true);
    final hostName =
        auth.currentUser?.displayName ?? auth.currentUser?.username ?? 'Ebeveyn';

    final res = await svc.createInvite(
      hostUserId: uid,
      hostDisplayName: hostName,
      guestUserId: child.userId,
      guestDisplayName: child.displayName,
      topic: topic,
    );

    if (!mounted) return;
    setState(() => _busy = false);

    if (res == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Davet gönderilemedi. Her iki hesapta Premium olmalı ve Firestore\'da isPremium güncel olmalı.',
          ),
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
                  const Expanded(
                    child: Text(
                      'Uzaktan aile düellosu',
                      textAlign: TextAlign.center,
                      style: TextStyle(
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
                              const Text(
                                'Önce ebeveyn hesabından çocuğunuzu aileye ekleyin (Ebeveyn Paneli → Aile).',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.white70, fontSize: 16),
                              ),
                              const SizedBox(height: 24),
                              FilledButton(
                                onPressed: widget.onBack,
                                child: const Text('Geri'),
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
                              const Text(
                                'Uzaktan düello daveti, Firestore kuralları gereği yalnızca '
                                'aile bağlantısının tutulduğu ebeveyn hesabından gönderilebilir.\n\n'
                                'Şu an çocuk hesabıyla oturum açmış olabilirsiniz; ebeveyn hesabınızla '
                                'giriş yapıp tekrar deneyin.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.white70, fontSize: 15, height: 1.35),
                              ),
                              const SizedBox(height: 24),
                              FilledButton(
                                onPressed: widget.onBack,
                                child: const Text('Geri'),
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
                          'Merhaba ${auth.currentUser?.displayName ?? 'Ebeveyn'} — davet gönderilecek çocuğu seçin '
                          '(yalnızca hesabınıza bağlı çocuklar).',
                          style: const TextStyle(color: Colors.white70, fontSize: 15),
                        ),
                        const SizedBox(height: 16),
                        ...eligible.map((c) {
                          final sel = _child?.userId == c.userId;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Material(
                              color: sel
                                  ? Colors.amber.withValues(alpha: 0.35)
                                  : Colors.white.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(14),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(14),
                                onTap: () => setState(() => _child = c),
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
                                      if (sel)
                                        const Icon(Icons.check_circle, color: Colors.amber),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                        const SizedBox(height: 20),
                        const Text(
                          'Konu',
                          style: TextStyle(
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
                              label: Text(_topicLabel(t)),
                              onSelected: (_) => setState(() => _topic = t),
                              selectedColor: col.withValues(alpha: 0.5),
                              checkmarkColor: Colors.white,
                              labelStyle: const TextStyle(color: Colors.white),
                            );
                          }).toList(),
                        ),
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
                          label: Text(_busy ? 'Gönderiliyor…' : 'Davet gönder'),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            backgroundColor: Colors.teal.shade600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Çocuğun hesabında ana sayfanın üstünde bildirim çıkar; kabul edince aynı 5 soruyu kendi telefonunuzdan oynarsınız.',
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
