import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../services/family_remote_duel_service.dart';

/// Gelen uzaktan düello daveti — [Stack] içinde [Positioned.fill] ile kullanın.
/// Süre dolunca (sunucu [expiresAtMs]) kart istemcide gizlenir ve tek seferlik süre sonu işlemi tetiklenir.
class FamilyRemoteDuelInviteOverlay extends StatefulWidget {
  final String userId;
  final Future<void> Function(String sessionId) onAcceptNavigate;

  const FamilyRemoteDuelInviteOverlay({
    super.key,
    required this.userId,
    required this.onAcceptNavigate,
  });

  static const double _squareBtn = 88;

  @override
  State<FamilyRemoteDuelInviteOverlay> createState() =>
      _FamilyRemoteDuelInviteOverlayState();
}

class _FamilyRemoteDuelInviteOverlayState extends State<FamilyRemoteDuelInviteOverlay>
    with WidgetsBindingObserver {
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sub;
  Timer? _poll;
  QuerySnapshot<Map<String, dynamic>>? _latest;
  final Set<String> _handledExpireIds = {};
  final Set<String> _expireInFlight = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final svc = context.read<FamilyRemoteDuelService>();
    _sub = svc.pendingInvitesStream(widget.userId).listen(_onInvites);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _sub?.cancel();
    _poll?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final s = _latest;
      if (s != null) {
        _processExpired(s);
        if (mounted) setState(() {});
      }
    }
  }

  void _onInvites(QuerySnapshot<Map<String, dynamic>> snap) {
    _latest = snap;
    _processExpired(snap);
    _adjustPollTimer(snap);
    if (mounted) setState(() {});
  }

  void _processExpired(QuerySnapshot<Map<String, dynamic>> snap) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final svc = context.read<FamilyRemoteDuelService>();
    for (final d in snap.docs) {
      final m = d.data();
      if ((m['status'] as String?) != 'pending') continue;
      final exp = (m['expiresAtMs'] as num?)?.toInt() ?? 0;
      if (exp <= 0 || now <= exp) continue;
      if (_handledExpireIds.contains(d.id)) continue;
      if (_expireInFlight.contains(d.id)) continue;
      _expireInFlight.add(d.id);
      final name = m['toDisplayName'] as String? ?? '';
      unawaited(_runExpireOnce(svc, d.id, name));
    }
  }

  Future<void> _runExpireOnce(
    FamilyRemoteDuelService svc,
    String inviteId,
    String inviteeDisplayName,
  ) async {
    try {
      final ok = await svc.expirePendingInviteDueToTimeout(
        inviteId: inviteId,
        inviteeUserId: widget.userId,
        inviteeDisplayName: inviteeDisplayName,
      );
      if (!mounted) return;
      if (ok) {
        _handledExpireIds.add(inviteId);
      }
    } finally {
      _expireInFlight.remove(inviteId);
      if (mounted) setState(() {});
    }
  }

  void _adjustPollTimer(QuerySnapshot<Map<String, dynamic>> snap) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final needsPoll = snap.docs.any((d) {
      final m = d.data();
      if ((m['status'] as String?) != 'pending') return false;
      final exp = (m['expiresAtMs'] as num?)?.toInt() ?? 0;
      return exp > 0 && now < exp;
    });
    if (needsPoll) {
      _poll ??= Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        final s = _latest;
        if (s != null) _processExpired(s);
        if (mounted) setState(() {});
      });
    } else {
      _poll?.cancel();
      _poll = null;
    }
  }

  bool _docStillShown(QueryDocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data();
    if ((m['status'] as String?) != 'pending') return false;
    final exp = (m['expiresAtMs'] as num?)?.toInt() ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    if (exp > 0 && now > exp) return false;
    return true;
  }

  String _t(String key, {Map<String, String> params = const {}}) {
    final lang = Localizations.localeOf(context).languageCode.toLowerCase();
    const tr = {
      'invite_text': '{from} seni uzaktan duelloya davet etti.',
      'remaining': 'Kalan sure: ~{seconds} sn',
      'accept': 'Kabul',
      'decline': 'Reddet',
      'accept_failed': 'Kabul edilemedi. Premium veya ag/Firestore kurallarini kontrol edin.',
      'family_default': 'Ailen',
    };
    const en = {
      'invite_text': '{from} invited you to a remote duel.',
      'remaining': 'Time left: ~{seconds}s',
      'accept': 'Accept',
      'decline': 'Decline',
      'accept_failed': 'Could not accept. Check Premium or network/Firestore rules.',
      'family_default': 'Your family',
    };
    const de = {
      'invite_text': '{from} hat dich zu einem Remote-Duell eingeladen.',
      'remaining': 'Verbleibende Zeit: ~{seconds}s',
      'accept': 'Annehmen',
      'decline': 'Ablehnen',
      'accept_failed': 'Annahme fehlgeschlagen. Premium oder Netzwerk/Firestore-Regeln pruefen.',
      'family_default': 'Deine Familie',
    };
    const es = {
      'invite_text': '{from} te invito a un duelo remoto.',
      'remaining': 'Tiempo restante: ~{seconds}s',
      'accept': 'Aceptar',
      'decline': 'Rechazar',
      'accept_failed': 'No se pudo aceptar. Revisa Premium o reglas de red/Firestore.',
      'family_default': 'Tu familia',
    };
    const fr = {
      'invite_text': '{from} t’a invite a un duel a distance.',
      'remaining': 'Temps restant: ~{seconds}s',
      'accept': 'Accepter',
      'decline': 'Refuser',
      'accept_failed':
          'Impossible d’accepter. Verifie Premium ou les regles reseau/Firestore.',
      'family_default': 'Ta famille',
    };
    const ar = {
      'invite_text': '{from} دعاك الى مواجهة عن بُعد.',
      'remaining': 'الوقت المتبقي: ~{seconds}ث',
      'accept': 'قبول',
      'decline': 'رفض',
      'accept_failed':
          'تعذر القبول. تحقق من Premium او قواعد الشبكة/Firestore.',
      'family_default': 'عائلتك',
    };
    const fa = {
      'invite_text': '{from} شما را به دوئل از راه دور دعوت کرد.',
      'remaining': 'زمان باقي‌مانده: ~{seconds}ث',
      'accept': 'پذيرش',
      'decline': 'رد',
      'accept_failed': 'پذيرش انجام نشد. Premium يا قوانين شبکه/Firestore را بررسي کنيد.',
      'family_default': 'خانواده‌ات',
    };
    const zh = {
      'invite_text': '{from} 邀请你进行远程对战。',
      'remaining': '剩余时间: ~{seconds}秒',
      'accept': '接受',
      'decline': '拒绝',
      'accept_failed': '无法接受。请检查 Premium 或网络/Firestore 规则。',
      'family_default': '你的家人',
    };
    const id = {
      'invite_text': '{from} mengundangmu ke duel jarak jauh.',
      'remaining': 'Sisa waktu: ~{seconds} dtk',
      'accept': 'Terima',
      'decline': 'Tolak',
      'accept_failed': 'Gagal menerima. Periksa Premium atau aturan jaringan/Firestore.',
      'family_default': 'Keluargamu',
    };
    const ku = {
      'invite_text': '{from} te bo duel a dûr vexwend.',
      'remaining': 'Demê mayî: ~{seconds}ç',
      'accept': 'Qebul bike',
      'decline': 'Redd bike',
      'accept_failed':
          'Qebul nehat. Premium an rêzikên tor/Firestore kontrol bike.',
      'family_default': 'Malbata te',
    };
    const ru = {
      'invite_text': '{from} пригласил(а) тебя на удалённую дуэль.',
      'remaining': 'Осталось: ~{seconds}с',
      'accept': 'Принять',
      'decline': 'Отклонить',
      'accept_failed':
          'Не удалось принять. Проверь Premium или правила сети/Firestore.',
      'family_default': 'Твоя семья',
    };
    const ja = {
      'invite_text': '{from} がリモートデュエルに招待しました。',
      'remaining': '残り時間: ~{seconds}秒',
      'accept': '承認',
      'decline': '拒否',
      'accept_failed': '承認できませんでした。Premium またはネット/Firestore 設定を確認してください。',
      'family_default': 'あなたの家族',
    };
    const ko = {
      'invite_text': '{from}님이 원격 대결에 초대했어요.',
      'remaining': '남은 시간: ~{seconds}초',
      'accept': '수락',
      'decline': '거절',
      'accept_failed': '수락할 수 없어요. Premium 또는 네트워크/Firestore 규칙을 확인하세요.',
      'family_default': '가족',
    };
    const hi = {
      'invite_text': '{from} ने तुम्हें रिमोट ड्यूल में बुलाया है।',
      'remaining': 'बाकी समय: ~{seconds}से',
      'accept': 'स्वीकार',
      'decline': 'अस्वीकार',
      'accept_failed': 'स्वीकार नहीं हो सका। Premium या network/Firestore नियम जांचें।',
      'family_default': 'तुम्हारा परिवार',
    };
    const ur = {
      'invite_text': '{from} نے آپ کو ريموٹ دوئل کے لئے مدعو کيا ہے۔',
      'remaining': 'باقی وقت: ~{seconds}س',
      'accept': 'قبول',
      'decline': 'مسترد',
      'accept_failed':
          'قبول نہيں ہوا۔ Premium يا network/Firestore قواعد چيک کريں۔',
      'family_default': 'آپ کا خاندان',
    };
    const pt = {
      'invite_text': '{from} convidou voce para um duelo remoto.',
      'remaining': 'Tempo restante: ~{seconds}s',
      'accept': 'Aceitar',
      'decline': 'Recusar',
      'accept_failed': 'Nao foi possivel aceitar. Verifique Premium ou regras de rede/Firestore.',
      'family_default': 'Sua familia',
    };
    const it = {
      'invite_text': '{from} ti ha invitato a un duello remoto.',
      'remaining': 'Tempo rimasto: ~{seconds}s',
      'accept': 'Accetta',
      'decline': 'Rifiuta',
      'accept_failed':
          'Impossibile accettare. Controlla Premium o regole rete/Firestore.',
      'family_default': 'La tua famiglia',
    };
    const pl = {
      'invite_text': '{from} zaprosil(a) cie do zdalnego pojedynku.',
      'remaining': 'Pozostaly czas: ~{seconds}s',
      'accept': 'Akceptuj',
      'decline': 'Odrzuc',
      'accept_failed': 'Nie mozna zaakceptowac. Sprawdz Premium lub zasady sieci/Firestore.',
      'family_default': 'Twoja rodzina',
    };
    final dict = switch (lang) {
      'tr' => tr,
      'de' => de,
      'es' => es,
      'fr' => fr,
      'ar' => ar,
      'fa' => fa,
      'zh' => zh,
      'id' => id,
      'ku' => ku,
      'ru' => ru,
      'ja' => ja,
      'ko' => ko,
      'hi' => hi,
      'ur' => ur,
      'pt' => pt,
      'it' => it,
      'pl' => pl,
      _ => en,
    };
    var out = dict[key] ?? en[key] ?? key;
    params.forEach((k, v) => out = out.replaceAll('{$k}', v));
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final svc = context.read<FamilyRemoteDuelService>();
    final snap = _latest;
    if (snap == null) {
      return const IgnorePointer(
        ignoring: true,
        child: SizedBox.expand(),
      );
    }
    final pending = snap.docs.where(_docStillShown).toList();
    if (pending.isEmpty) {
      return const IgnorePointer(
        ignoring: true,
        child: SizedBox.expand(),
      );
    }

    final doc = pending.first;
    final m = doc.data();
    final from = m['fromDisplayName'] as String? ?? _t('family_default');
    final sessionId = m['sessionId'] as String? ?? '';
    final exp = (m['expiresAtMs'] as num?)?.toInt() ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    final secsLeft = exp > 0 ? ((exp - now) / 1000).ceil().clamp(0, 9999) : null;

    return Positioned.fill(
      child: Material(
        type: MaterialType.transparency,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              child: IgnorePointer(
                ignoring: true,
                child: ColoredBox(
                  color: Colors.black.withValues(alpha: 0.45),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Card(
                  elevation: 14,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.sports_martial_arts,
                            size: 44, color: Color(0xFF5C6BC0)),
                        const SizedBox(height: 12),
                        Text(
                          _t('invite_text', params: {'from': from}),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            height: 1.35,
                          ),
                        ),
                        if (secsLeft != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            _t('remaining', params: {'seconds': '$secsLeft'}),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                        const SizedBox(height: 22),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: FamilyRemoteDuelInviteOverlay._squareBtn,
                              height: FamilyRemoteDuelInviteOverlay._squareBtn,
                              child: FilledButton(
                                onPressed: () async {
                                  final auth = Provider.of<AuthService>(
                                    context,
                                    listen: false,
                                  );
                                  final ok = await svc.acceptInvite(
                                    inviteId: doc.id,
                                    acceptingUserId: widget.userId,
                                    acceptingUserCode:
                                        auth.currentUser?.userCode,
                                  );
                                  if (!context.mounted) return;
                                  if (!ok) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(_t('accept_failed'))),
                                    );
                                    return;
                                  }
                                  if (sessionId.isEmpty) return;
                                  await widget.onAcceptNavigate(sessionId);
                                },
                                style: FilledButton.styleFrom(
                                  backgroundColor: Colors.green.shade600,
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.zero,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: Text(
                                  _t('accept'),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 18),
                            SizedBox(
                              width: FamilyRemoteDuelInviteOverlay._squareBtn,
                              height: FamilyRemoteDuelInviteOverlay._squareBtn,
                              child: OutlinedButton(
                                onPressed: () =>
                                    svc.declineInvite(doc.id, widget.userId),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.red.shade800,
                                  side: BorderSide(
                                      color: Colors.red.shade400, width: 2),
                                  padding: EdgeInsets.zero,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: Text(
                                  _t('decline'),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.red.shade800,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
