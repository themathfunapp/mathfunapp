import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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

class _FamilyRemoteDuelWaitingScreenState extends State<FamilyRemoteDuelWaitingScreen> {
  bool _openedPlay = false;

  @override
  Widget build(BuildContext context) {
    final svc = context.read<FamilyRemoteDuelService>();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
          ),
        ),
        child: SafeArea(
          child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: svc.sessionStream(widget.sessionId),
            builder: (context, snap) {
              final data = snap.data?.data();
              final status = data?['status'] as String?;

              if (status == 'active' && !_openedPlay && context.mounted) {
                _openedPlay = true;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!mounted) return;
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute<void>(
                      builder: (ctx) => FamilyRemoteDuelPlayScreen(
                        sessionId: widget.sessionId,
                        onDone: () => Navigator.of(ctx).popUntil((r) => r.isFirst),
                      ),
                    ),
                  );
                });
              }

              if (status == 'cancelled') {
                return _Cancelled(onBack: widget.onBack);
              }

              return Column(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white70),
                      onPressed: () async {
                        if (widget.isHost) {
                          final uid = context.read<AuthService>().currentUser?.uid;
                          if (uid != null) {
                            await svc.cancelPendingSession(widget.sessionId, uid);
                          }
                        }
                        widget.onBack();
                      },
                    ),
                  ),
                  const Spacer(),
                  const Icon(Icons.hourglass_top, size: 72, color: Colors.white54),
                  const SizedBox(height: 20),
                  Text(
                    widget.isHost
                        ? 'Davet gönderildi.\nÇocuğun telefonunda bildirimden kabul etmesini bekleyin.'
                        : 'Oturum hazırlanıyor…',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const CircularProgressIndicator(color: Colors.white54),
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

  const _Cancelled({required this.onBack});

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
            const Text(
              'Düello iptal edildi veya reddedildi.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 17),
            ),
            const SizedBox(height: 24),
            FilledButton(onPressed: onBack, child: const Text('Tamam')),
          ],
        ),
      ),
    );
  }
}
