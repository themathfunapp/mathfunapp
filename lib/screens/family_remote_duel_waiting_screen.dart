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
                      return Text(
                        widget.isHost
                            ? _waitText(ctx, 'waiting_host')
                            : _waitText(ctx, 'waiting_guest'),
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
                      _waitText(
                        context,
                        'accepted_count',
                        {'accepted': '$acceptedCount', 'invited': '$invitedCount'},
                      ),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.92),
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _waitText(
                        context,
                        'remaining_seconds',
                        {'seconds': '${secondsLeft.clamp(0, 999)}'},
                      ),
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

  String _waitText(
    BuildContext context,
    String key, [
    Map<String, String> params = const {},
  ]) {
    final lang = Provider.of<LocaleProvider>(context, listen: false)
        .locale
        .languageCode
        .toLowerCase();
    const map = <String, Map<String, String>>{
      'en': {
        'waiting_host':
            'Invite sent.\nWait for the other player to accept on their phone or computer.',
        'waiting_guest': 'Invite accepted.\nConnecting to the duel...',
        'accepted_count': 'Accepted: {accepted} / {invited}',
        'remaining_seconds': 'Time left: {seconds} s',
      },
      'tr': {
        'waiting_host':
            'Davet gönderildi.\nDiğer oyuncunun telefonundan veya bilgisayarından kabul etmesini bekleyin.',
        'waiting_guest': 'Davet kabul edildi.\nDüelloya bağlanılıyor...',
        'accepted_count': 'Kabul: {accepted} / {invited}',
        'remaining_seconds': 'Kalan süre: {seconds} sn',
      },
      'de': {
        'waiting_host':
            'Einladung gesendet.\nWarte, bis der andere Spieler auf seinem Handy oder Computer annimmt.',
        'waiting_guest': 'Einladung angenommen.\nVerbindung zum Duell wird hergestellt...',
        'accepted_count': 'Akzeptiert: {accepted} / {invited}',
        'remaining_seconds': 'Verbleibende Zeit: {seconds} s',
      },
      'es': {
        'waiting_host':
            'Invitacion enviada.\nEspera a que el otro jugador la acepte en su telefono o computadora.',
        'waiting_guest': 'Invitacion aceptada.\nConectando al duelo...',
        'accepted_count': 'Aceptadas: {accepted} / {invited}',
        'remaining_seconds': 'Tiempo restante: {seconds} s',
      },
      'fr': {
        'waiting_host':
            'Invitation envoyee.\nAttendez que l’autre joueur accepte sur son telephone ou son ordinateur.',
        'waiting_guest': 'Invitation acceptee.\nConnexion au duel...',
        'accepted_count': 'Acceptees: {accepted} / {invited}',
        'remaining_seconds': 'Temps restant: {seconds} s',
      },
      'ar': {
        'waiting_host':
            'تم ارسال الدعوة.\nانتظر حتى يقبل اللاعب الاخر من الهاتف او الكمبيوتر.',
        'waiting_guest': 'تم قبول الدعوة.\nجاري الاتصال بالمواجهة...',
        'accepted_count': 'تم القبول: {accepted} / {invited}',
        'remaining_seconds': 'الوقت المتبقي: {seconds} ث',
      },
      'fa': {
        'waiting_host':
            'دعوت ارسال شد.\nمنتظر بمانيد تا بازيکن ديگر در تلفن يا رايانه قبول کند.',
        'waiting_guest': 'دعوت پذيرفته شد.\nدر حال اتصال به دوئل...',
        'accepted_count': 'پذيرش: {accepted} / {invited}',
        'remaining_seconds': 'زمان باقي مانده: {seconds} ث',
      },
      'zh': {
        'waiting_host': '邀请已发送。\n请等待对方在手机或电脑上接受邀请。',
        'waiting_guest': '邀请已接受。\n正在连接对战...',
        'accepted_count': '已接受: {accepted} / {invited}',
        'remaining_seconds': '剩余时间: {seconds} 秒',
      },
      'id': {
        'waiting_host':
            'Undangan terkirim.\nTunggu pemain lain menerima di ponsel atau komputer mereka.',
        'waiting_guest': 'Undangan diterima.\nMenghubungkan ke duel...',
        'accepted_count': 'Diterima: {accepted} / {invited}',
        'remaining_seconds': 'Sisa waktu: {seconds} dtk',
      },
      'ku': {
        'waiting_host':
            'Bangewazek hat.\nLi benda ku lîstikvanê din li telefon an komputerê xwe qebul bike.',
        'waiting_guest': 'Bangewaz qebul bû.\nGirêdan bo duelê...',
        'accepted_count': 'Qebulkirî: {accepted} / {invited}',
        'remaining_seconds': 'Demê mayî: {seconds} ç',
      },
      'ru': {
        'waiting_host':
            'Приглашение отправлено.\nПодождите, пока другой игрок примет его на телефоне или компьютере.',
        'waiting_guest': 'Приглашение принято.\nПодключение к дуэли...',
        'accepted_count': 'Принято: {accepted} / {invited}',
        'remaining_seconds': 'Осталось времени: {seconds} с',
      },
      'ja': {
        'waiting_host': '招待を送信しました。\n相手がスマホまたはPCで承認するのを待ってください。',
        'waiting_guest': '招待が承認されました。\n対戦に接続中...',
        'accepted_count': '承認: {accepted} / {invited}',
        'remaining_seconds': '残り時間: {seconds} 秒',
      },
      'ko': {
        'waiting_host': '초대가 전송되었습니다.\n상대가 휴대폰이나 컴퓨터에서 수락할 때까지 기다리세요.',
        'waiting_guest': '초대가 수락되었습니다.\n대결에 연결 중...',
        'accepted_count': '수락: {accepted} / {invited}',
        'remaining_seconds': '남은 시간: {seconds}초',
      },
      'hi': {
        'waiting_host':
            'निमंत्रण भेज दिया गया है।\nदूसरे खिलाड़ी के फोन या कंप्यूटर पर स्वीकार करने का इंतजार करें।',
        'waiting_guest': 'निमंत्रण स्वीकार हो गया।\nड्यूल से कनेक्ट हो रहा है...',
        'accepted_count': 'स्वीकृत: {accepted} / {invited}',
        'remaining_seconds': 'शेष समय: {seconds} से',
      },
      'ur': {
        'waiting_host':
            'دعوت بھیج دی گئی ہے۔\nدوسرے کھلاڑی کے فون یا کمپیوٹر پر قبول کرنے کا انتظار کریں۔',
        'waiting_guest': 'دعوت قبول ہوگئی۔\nدوئل سے رابطہ ہو رہا ہے...',
        'accepted_count': 'قبول: {accepted} / {invited}',
        'remaining_seconds': 'باقی وقت: {seconds} س',
      },
      'pt': {
        'waiting_host':
            'Convite enviado.\nAguarde o outro jogador aceitar no celular ou computador.',
        'waiting_guest': 'Convite aceito.\nConectando ao duelo...',
        'accepted_count': 'Aceitos: {accepted} / {invited}',
        'remaining_seconds': 'Tempo restante: {seconds} s',
      },
      'it': {
        'waiting_host':
            'Invito inviato.\nAttendi che l’altro giocatore accetti dal telefono o computer.',
        'waiting_guest': 'Invito accettato.\nConnessione al duello...',
        'accepted_count': 'Accettati: {accepted} / {invited}',
        'remaining_seconds': 'Tempo rimanente: {seconds} s',
      },
      'pl': {
        'waiting_host':
            'Zaproszenie wyslane.\nPoczekaj, az drugi gracz zaakceptuje na telefonie lub komputerze.',
        'waiting_guest': 'Zaproszenie zaakceptowane.\nLaczenie z pojedynkiem...',
        'accepted_count': 'Zaakceptowano: {accepted} / {invited}',
        'remaining_seconds': 'Pozostaly czas: {seconds} s',
      },
    };
    final selected = map[lang] ?? map['en']!;
    var text = selected[key] ?? map['en']![key] ?? key;
    params.forEach((k, v) {
      text = text.replaceAll('{$k}', v);
    });
    return text;
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
                ).get('ok'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
