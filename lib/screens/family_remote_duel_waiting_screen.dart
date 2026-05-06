import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';

import '../app_navigator.dart';
import '../localization/app_localizations.dart';
import '../providers/locale_provider.dart';
import '../services/auth_service.dart';
import '../services/family_remote_duel_service.dart';
import 'family_remote_duel_play_screen.dart';

/// Ebeveyn: çocuğun kabulünü bekler. Çocuk kabul edince otomatik oyuna geçer.
class FamilyRemoteDuelWaitingScreen extends StatefulWidget {
  final String sessionId;
  final bool isHost;
  final VoidCallback onBack;

  const FamilyRemoteDuelWaitingScreen({
    super.key,
    required this.sessionId,
    required this.isHost,
    required this.onBack,
  });

  @override
  State<FamilyRemoteDuelWaitingScreen> createState() => _FamilyRemoteDuelWaitingScreenState();
}

class _FamilyRemoteDuelWaitingScreenState extends State<FamilyRemoteDuelWaitingScreen>
    with SingleTickerProviderStateMixin {
  /// Oyun veya bitmiş oturum özeti ekranına geçildi mi (active / finished).
  bool _openedPlay = false;
  Timer? _ticker;
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final svc = context.read<FamilyRemoteDuelService>();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF5E35B1),
              Color(0xFFE91E63),
              Color(0xFFFF6F00),
              Color(0xFF00ACC1),
            ],
            stops: [0.0, 0.35, 0.7, 1.0],
          ),
        ),
        child: SafeArea(
          child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: svc.sessionStream(widget.sessionId),
            builder: (context, snap) {
              final data = snap.data?.data();
              final status = data?['status'] as String?;
              final expiresAtMs = (data?['expiresAtMs'] as num?)?.toInt() ?? 0;
              final secondsLeft = expiresAtMs <= 0
                  ? 0
                  : ((expiresAtMs - DateTime.now().millisecondsSinceEpoch) / 1000).ceil();

              if ((status == 'active' || status == 'finished') &&
                  !_openedPlay &&
                  context.mounted) {
                _openedPlay = true;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!mounted) return;
                  final nav = appRootNavigatorKey.currentState;
                  if (nav == null) return;
                  nav.pushReplacement(
                    MaterialPageRoute<void>(
                      builder: (ctx) => FamilyRemoteDuelPlayScreen(
                        sessionId: widget.sessionId,
                        onDone: () {
                          appRootNavigatorKey.currentState?.popUntil((r) => r.isFirst);
                        },
                      ),
                    ),
                  );
                });
              }

              if (status == 'cancelled') {
                final loc = AppLocalizations(
                  Provider.of<LocaleProvider>(context, listen: false).locale,
                );
                final reason = data?['cancelReason'] as String? ?? '';
                final msg = reason == 'declined'
                    ? loc.get('family_remote_duel_waiting_declined')
                    : loc.get('family_remote_duel_waiting_cancelled');
                return _Cancelled(onBack: widget.onBack, message: msg);
              }
              if (status == 'expired' || (status == 'waiting_accept' && secondsLeft <= 0)) {
                final loc = AppLocalizations(
                  Provider.of<LocaleProvider>(context, listen: false).locale,
                );
                return _Cancelled(
                  onBack: widget.onBack,
                  message: loc.get('family_remote_duel_waiting_expired'),
                );
              }

              final acceptedCount =
                  (data?['acceptedUserIds'] as List<dynamic>? ?? const []).length;
              final invitedCount =
                  (data?['invitedUserIds'] as List<dynamic>? ?? const []).length;

              return Column(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white),
                      onPressed: () async {
                        if (widget.isHost) {
                          final uid = context.read<AuthService>().currentUser?.uid;
                          if (uid != null) {
                            await svc.cancelPendingSession(widget.sessionId, uid);
                          }
                          if (!context.mounted) return;
                          widget.onBack();
                          return;
                        }
                        final uid = context.read<AuthService>().currentUser?.uid;
                        if (uid == null || uid.isEmpty) {
                          widget.onBack();
                          return;
                        }
                        final ok = await svc.markSessionForfeited(
                          sessionId: widget.sessionId,
                          leavingUserId: uid,
                        );
                        if (!context.mounted) return;
                        if (!ok) {
                          final loc = AppLocalizations(
                            Provider.of<LocaleProvider>(context, listen: false).locale,
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(loc.get('family_remote_duel_forfeit_failed')),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                          return;
                        }
                        if (_openedPlay) return;
                        _openedPlay = true;
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (!mounted) return;
                          final nav = appRootNavigatorKey.currentState;
                          if (nav == null) return;
                          nav.pushReplacement(
                            MaterialPageRoute<void>(
                              builder: (ctx) => FamilyRemoteDuelPlayScreen(
                                sessionId: widget.sessionId,
                                onDone: () {
                                  appRootNavigatorKey.currentState
                                      ?.popUntil((r) => r.isFirst);
                                },
                              ),
                            ),
                          );
                        });
                      },
                    ),
                  ),
                  const Spacer(),
                  AnimatedBuilder(
                    animation: _pulse,
                    builder: (context, child) {
                      final t = _pulse.value;
                      return Transform.scale(
                        scale: 0.94 + 0.06 * t,
                        child: child,
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.purple.shade900.withValues(alpha: 0.35),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.hourglass_top, size: 64, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Builder(
                    builder: (ctx) {
                      final loc = AppLocalizations(
                        Provider.of<LocaleProvider>(ctx, listen: false).locale,
                      );
                      return Text(
                        widget.isHost
                            ? loc.get('family_remote_duel_waiting_host')
                            : loc.get('family_remote_duel_waiting_guest'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          height: 1.4,
                          fontWeight: FontWeight.w700,
                          shadows: [
                            Shadow(color: Colors.black26, offset: Offset(0, 1), blurRadius: 4),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  if (status == 'waiting_accept') ...[
                    Text(
                      'Kabul: $acceptedCount / $invitedCount',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.92),
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Kalan süre: ${secondsLeft.clamp(0, 999)} sn',
                      style: TextStyle(
                        color: secondsLeft <= 15 ? const Color(0xFFFFEB3B) : Colors.white,
                        fontWeight: FontWeight.w800,
                        shadows: const [
                          Shadow(color: Colors.black26, offset: Offset(0, 1), blurRadius: 3),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
                  const CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 3,
                  ),
                  const Spacer(),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _Cancelled extends StatelessWidget {
  final VoidCallback onBack;
  final String? message;

  const _Cancelled({required this.onBack, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cancel_outlined, size: 64, color: Colors.orange),
            const SizedBox(height: 16),
            Text(
              message ??
                  AppLocalizations(
                    Provider.of<LocaleProvider>(context, listen: false).locale,
                  ).get('family_remote_duel_waiting_cancelled'),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 17),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: onBack,
              child: Text(
                AppLocalizations(
                  Provider.of<LocaleProvider>(context, listen: false).locale,
                ).get('family_remote_duel_summary_ok'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
