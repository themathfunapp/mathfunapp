/// Uzaktan aile düellosu — 18 dil (app dil kodları ile uyumlu).
/// Ana [AppLocalizations] haritalarında eksik kalan anahtarlar burada tamamlanır.

String _normLang(String? code) {
  final raw = (code ?? '').trim().toLowerCase();
  if (raw.isEmpty) return 'en';
  if (raw.startsWith('zh')) return 'zh';
  if (raw.length >= 2) return raw.substring(0, 2);
  return raw;
}

/// Dil haritasında anahtar yoksa İngilizce değere düşer; o da yoksa null.
String? familyRemoteDuelString(String? languageCode, String key) {
  final lang = _normLang(languageCode);
  final primary = _familyRemoteDuel[lang];
  final fromLang = primary?[key];
  if (fromLang != null) return fromLang;
  return _familyRemoteDuel['en']?[key];
}

const Map<String, Map<String, String>> _familyRemoteDuel = {
  'en': _enDuel,
  'tr': _trDuel,
  'de': _deDuel,
  'es': _esDuel,
  'fr': _frDuel,
  'ar': _arDuel,
  'fa': _faDuel,
  'zh': _zhDuel,
  'id': _idDuel,
  'ku': _kuDuel,
  'ru': _ruDuel,
  'ja': _jaDuel,
  'ko': _koDuel,
  'hi': _hiDuel,
  'ur': _urDuel,
  'pt': _ptDuel,
  'it': _itDuel,
  'pl': _plDuel,
};

// Ortak anahtarlar (İngilizce kaynak)
const _enDuel = {
  'family_remote_duel_title': 'Remote family duel',
  'family_remote_duel_intro':
      'Hello {0} — select family members to invite (only children linked to your account). The request lasts 90 seconds.',
  'family_remote_duel_topic_heading': 'Topic',
  'family_remote_duel_selected_topic': 'Selected topic',
  'family_remote_duel_send_invite': 'Send invitation ({0})',
  'family_remote_duel_sending': 'Sending…',
  'family_remote_duel_footer_rule':
      'The game will not start until all selected members accept within 90 seconds. If time runs out, send the invitation again.',
  'family_remote_duel_add_child_hint':
      'First add your child to the family from the parent account (Parent Panel → Family).',
  'family_remote_duel_wrong_account_hint':
      'For Firestore security rules, remote duel invites can only be sent from the parent account that holds the family link.\n\nYou may be signed in with a child account; please sign in with your parent account and try again.',
  'family_remote_duel_host_default': 'Parent',
  'family_remote_duel_snackbar_need_selection':
      'Select at least one family member and a topic.',
  'family_remote_duel_snackbar_wrong_account':
      'Remote duels cannot be sent from this account. If you are logged in with a child account on the same device, send the invite from your parent account (the account where family data is stored).',
  'family_remote_duel_snackbar_send_failed':
      'Could not send invite. Both accounts need Premium and isPremium must be up to date in Firestore.',
  'family_remote_duel_play_ribbon': 'Remote duel',
  'family_remote_duel_play_summary': 'Summary',
  'family_remote_duel_round': 'Round {current} / {total}',
  'family_remote_duel_your_correct': 'Your correct answers: {n}',
  'family_remote_duel_turn_you': 'Your turn — pick an answer.',
  'family_remote_duel_turn_opponent': '{name} is answering — ~{n}s left',
  'family_remote_duel_wait_your_turn':
      'Not your turn right now. The same question will appear here when it is your turn.',
  'family_remote_duel_seconds_hint': 'Time left: {n}s',
  'family_remote_duel_seconds_compact': '{n}s',
  'family_remote_duel_turn_wait': 'Answer saved — waiting for the other player.',
  'family_remote_duel_summary_title': 'Duel finished',
  'family_remote_duel_summary_winner': 'Winner: {name}',
  'family_remote_duel_summary_tie': 'Tie: {names}',
  'family_remote_duel_summary_scores': 'Correct answers:',
  'family_remote_duel_summary_gold': 'You earned {n} gold coins!',
  'family_remote_duel_summary_ok': 'OK',
  'family_remote_duel_forfeit_win':
      'Congratulations, you won! Your opponent left the duel.',
  'family_remote_duel_forfeit_you_left': 'You left this duel.',
  'family_remote_duel_forfeit_failed':
      'Could not notify the server you left. Check your connection and try again.',
  'family_remote_duel_quit_confirm_title': 'Leave this duel?',
  'family_remote_duel_quit_confirm_body':
      'If you leave, the duel ends and your opponent wins.',
  'family_remote_duel_quit_confirm_stay': 'Keep playing',
  'family_remote_duel_quit_confirm_leave': 'Leave',
  'family_remote_duel_waiting_declined': 'The invite was declined.',
  'family_remote_duel_waiting_expired':
      'The invite expired (90 seconds). Please send a new invite.',
  'family_remote_duel_waiting_cancelled': 'The duel was cancelled.',
  'family_remote_duel_waiting_host':
      'Invite sent.\nWait for the other player to accept on their phone or computer.',
  'family_remote_duel_waiting_guest':
      'Invite received.\nWaiting for other selected family members to accept…',
  'family_remote_duel_answer_failed': 'Could not save your answer. Try again.',
};

const _trDuel = {
  'family_remote_duel_title': 'Uzaktan aile düellosu',
  'family_remote_duel_intro':
      'Merhaba {0} — davet gönderilecek aile üyelerini seçin (yalnızca hesabınıza bağlı çocuklar). İstek süresi 90 saniyedir.',
  'family_remote_duel_topic_heading': 'Konu',
  'family_remote_duel_selected_topic': 'Seçilen Konu',
  'family_remote_duel_send_invite': 'Davet gönder ({0})',
  'family_remote_duel_sending': 'Gönderiliyor…',
  'family_remote_duel_footer_rule':
      'Tüm seçilen üyeler 90 saniye içinde kabul etmeden oyun başlamaz. Süre dolarsa yeniden davet gönderin.',
  'family_remote_duel_add_child_hint':
      'Önce ebeveyn hesabından çocuğunuzu aileye ekleyin (Ebeveyn Paneli → Aile).',
  'family_remote_duel_wrong_account_hint':
      'Uzaktan düello daveti, Firestore kuralları gereği yalnızca aile bağlantısının tutulduğu ebeveyn hesabından gönderilebilir.\n\nŞu an çocuk hesabıyla oturum açmış olabilirsiniz; ebeveyn hesabınızla giriş yapıp tekrar deneyin.',
  'family_remote_duel_host_default': 'Ebeveyn',
  'family_remote_duel_snackbar_need_selection':
      'En az bir aile üyesi ve konu seçin.',
  'family_remote_duel_snackbar_wrong_account':
      'Bu hesaptan uzaktan düello gönderilemez. Aynı cihazda çocuk hesabıyla oturum açıksanız, daveti ebeveyn hesabınızla (aile verisinin bulunduğu hesap) göndermeniz gerekir.',
  'family_remote_duel_snackbar_send_failed':
      'Davet gönderilemedi. Her iki hesapta Premium olmalı ve Firestore\'da isPremium güncel olmalı.',
  'family_remote_duel_play_ribbon': 'Uzaktan düello',
  'family_remote_duel_play_summary': 'Özet',
  'family_remote_duel_round': 'Tur {current} / {total}',
  'family_remote_duel_your_correct': 'Doğru cevabın: {n}',
  'family_remote_duel_turn_you': 'Sıra sende — şıkkını seç.',
  'family_remote_duel_turn_opponent': '{name} cevaplıyor — kalan süre ~{n} sn',
  'family_remote_duel_wait_your_turn':
      'Şu an sıra sizde değil. Aynı soru, sıranız geldiğinde burada açılacak.',
  'family_remote_duel_seconds_hint': 'Kalan süre: {n} sn',
  'family_remote_duel_seconds_compact': '{n} sn',
  'family_remote_duel_turn_wait': 'Cevabın kaydedildi; diğer oyuncu bekleniyor.',
  'family_remote_duel_summary_title': 'Düello bitti',
  'family_remote_duel_summary_winner': 'Kazanan: {name}',
  'family_remote_duel_summary_tie': 'Berabere: {names}',
  'family_remote_duel_summary_scores': 'Doğru cevaplar:',
  'family_remote_duel_summary_gold': '{n} altın kazandın!',
  'family_remote_duel_summary_ok': 'Tamam',
  'family_remote_duel_forfeit_win':
      'Tebrikler, kazandınız! Rakibiniz oyundan ayrıldı.',
  'family_remote_duel_forfeit_you_left': 'Bu düelloyu terk ettiniz.',
  'family_remote_duel_forfeit_failed':
      'Oyundan çıkış sunucuya iletilemedi. Ağı kontrol edip tekrar deneyin.',
  'family_remote_duel_quit_confirm_title': 'Oyundan çıkmak istiyor musun?',
  'family_remote_duel_quit_confirm_body':
      'Çıkarsan düello biter ve karşı taraf kazanmış sayılır.',
  'family_remote_duel_quit_confirm_stay': 'Oyuna dön',
  'family_remote_duel_quit_confirm_leave': 'Çık',
  'family_remote_duel_waiting_declined': 'Davet reddedildi.',
  'family_remote_duel_waiting_expired':
      'Davet süresi doldu (90 sn). Yeni bir davet gönderin.',
  'family_remote_duel_waiting_cancelled': 'Düello iptal edildi.',
  'family_remote_duel_waiting_host':
      'Davet gönderildi.\nKarşı tarafın telefonunda veya bilgisayarında bildirimden kabul etmesini bekleyin.',
  'family_remote_duel_waiting_guest':
      'Davet alındı.\nDiğer seçilen aile üyelerinin de kabul etmesi bekleniyor…',
  'family_remote_duel_answer_failed': 'Cevap kaydedilemedi. Tekrar deneyin.',
};

const _zhDuel = {
  'family_remote_duel_title': '远程家庭对战',
  'family_remote_duel_intro':
      '你好 {0} — 请选择要邀请的家庭成员（仅限与您账户关联的孩子）。邀请有效期为 90 秒。',
  'family_remote_duel_topic_heading': '主题',
  'family_remote_duel_selected_topic': '所选主题',
  'family_remote_duel_send_invite': '发送邀请（{0}）',
  'family_remote_duel_sending': '发送中…',
  'family_remote_duel_footer_rule':
      '所有被选成员必须在 90 秒内接受，游戏才会开始。若超时，请重新发送邀请。',
  'family_remote_duel_add_child_hint':
      '请先在家长账户中将孩子加入家庭（家长专区 → 家庭）。',
  'family_remote_duel_wrong_account_hint':
      '根据 Firestore 安全规则，远程对战邀请只能从保存家庭关联的家长账户发送。\n\n您可能正在使用儿童账户登录；请改用家长账户后重试。',
  'family_remote_duel_host_default': '家长',
  'family_remote_duel_snackbar_need_selection': '请至少选择一名家庭成员和一个主题。',
  'family_remote_duel_snackbar_wrong_account':
      '无法从此账户发送远程对战。若在同一设备上使用儿童账户登录，请用家长账户（保存家庭数据的账户）发送邀请。',
  'family_remote_duel_snackbar_send_failed':
      '无法发送邀请。双方账户都需为 Premium，且 Firestore 中的 isPremium 需为最新。',
  'family_remote_duel_play_ribbon': '远程对战',
  'family_remote_duel_play_summary': '摘要',
  'family_remote_duel_round': '第 {current} / {total} 轮',
  'family_remote_duel_your_correct': '你答对的题数：{n}',
  'family_remote_duel_turn_you': '轮到你了 — 选择一个答案。',
  'family_remote_duel_turn_opponent': '{name} 正在作答 — 剩余约 {n} 秒',
  'family_remote_duel_wait_your_turn': '现在不是你的回合。轮到你时，同一题目会显示在这里。',
  'family_remote_duel_seconds_hint': '剩余时间：{n} 秒',
  'family_remote_duel_seconds_compact': '{n}秒',
  'family_remote_duel_turn_wait': '答案已保存 — 正在等待另一位玩家。',
  'family_remote_duel_summary_title': '对战结束',
  'family_remote_duel_summary_winner': '获胜者：{name}',
  'family_remote_duel_summary_tie': '平局：{names}',
  'family_remote_duel_summary_scores': '答对题数：',
  'family_remote_duel_summary_gold': '你获得了 {n} 枚金币！',
  'family_remote_duel_summary_ok': '好的',
  'family_remote_duel_forfeit_win': '恭喜你赢了！对手已离开对战。',
  'family_remote_duel_forfeit_you_left': '你已离开本场对战。',
  'family_remote_duel_forfeit_failed': '无法向服务器报告离开。请检查网络后重试。',
  'family_remote_duel_quit_confirm_title': '要离开对战吗？',
  'family_remote_duel_quit_confirm_body': '若离开，对战将结束，对手获胜。',
  'family_remote_duel_quit_confirm_stay': '继续玩',
  'family_remote_duel_quit_confirm_leave': '离开',
  'family_remote_duel_waiting_declined': '邀请已被拒绝。',
  'family_remote_duel_waiting_expired': '邀请已过期（90 秒）。请重新发送邀请。',
  'family_remote_duel_waiting_cancelled': '对战已取消。',
  'family_remote_duel_waiting_host': '邀请已发送。\n请等待对方在手机或电脑上接受。',
  'family_remote_duel_waiting_guest': '已收到邀请。\n正在等待其他所选家庭成员接受…',
  'family_remote_duel_answer_failed': '无法保存答案。请重试。',
};

const _deDuel = {
  'family_remote_duel_title': 'Familien-Duell aus der Ferne',
  'family_remote_duel_intro':
      'Hallo {0} — wählen Sie Familienmitglieder für die Einladung (nur mit Ihrem Konto verknüpfte Kinder). Die Anfrage gilt 90 Sekunden.',
  'family_remote_duel_topic_heading': 'Thema',
  'family_remote_duel_selected_topic': 'Ausgewähltes Thema',
  'family_remote_duel_send_invite': 'Einladung senden ({0})',
  'family_remote_duel_sending': 'Wird gesendet…',
  'family_remote_duel_footer_rule':
      'Das Spiel startet erst, wenn alle ausgewählten Mitglieder innerhalb von 90 Sekunden akzeptieren. Bei Ablauf der Zeit senden Sie die Einladung erneut.',
  'family_remote_duel_add_child_hint':
      'Fügen Sie Ihr Kind zuerst über das Elternkonto zur Familie hinzu (Eltern-Panel → Familie).',
  'family_remote_duel_wrong_account_hint':
      'Aus Sicherheitsgründen (Firestore-Regeln) können Einladungen zum Fern-Duell nur vom Elternkonto gesendet werden, das die Familienverknüpfung enthält.\n\nMöglicherweise sind Sie mit einem Kinderkonto angemeldet; melden Sie sich mit dem Elternkonto an und versuchen Sie es erneut.',
  'family_remote_duel_host_default': 'Elternteil',
  'family_remote_duel_snackbar_need_selection':
      'Wählen Sie mindestens ein Familienmitglied und ein Thema.',
  'family_remote_duel_snackbar_wrong_account':
      'Remote-Duelle können von diesem Konto nicht gesendet werden. Wenn Sie mit einem Kinderkonto auf demselben Gerät angemeldet sind, senden Sie die Einladung von Ihrem Elternkonto (dem Konto mit den Familiendaten).',
  'family_remote_duel_snackbar_send_failed':
      'Einladung konnte nicht gesendet werden. Beide Konten benötigen Premium und isPremium muss in Firestore aktuell sein.',
  'family_remote_duel_play_ribbon': 'Fern-Duell',
  'family_remote_duel_play_summary': 'Zusammenfassung',
  'family_remote_duel_round': 'Runde {current} / {total}',
  'family_remote_duel_your_correct': 'Deine richtigen Antworten: {n}',
  'family_remote_duel_turn_you': 'Du bist dran — wähle eine Antwort.',
  'family_remote_duel_turn_opponent': '{name} antwortet — noch ~{n} s',
  'family_remote_duel_wait_your_turn':
      'Gerade nicht dein Zug. Dieselbe Frage erscheint hier, wenn du dran bist.',
  'family_remote_duel_seconds_hint': 'Verbleibende Zeit: {n} s',
  'family_remote_duel_seconds_compact': '{n} s',
  'family_remote_duel_turn_wait': 'Antwort gespeichert — warte auf den anderen Spieler.',
  'family_remote_duel_summary_title': 'Duell beendet',
  'family_remote_duel_summary_winner': 'Gewinner: {name}',
  'family_remote_duel_summary_tie': 'Unentschieden: {names}',
  'family_remote_duel_summary_scores': 'Richtige Antworten:',
  'family_remote_duel_summary_gold': 'Du hast {n} Goldmünzen erhalten!',
  'family_remote_duel_summary_ok': 'OK',
  'family_remote_duel_forfeit_win':
      'Glückwunsch, du hast gewonnen! Dein Gegner hat das Duell verlassen.',
  'family_remote_duel_forfeit_you_left': 'Du hast dieses Duell verlassen.',
  'family_remote_duel_forfeit_failed':
      'Konnte dem Server den Abbruch nicht mitteilen. Prüfe deine Verbindung.',
  'family_remote_duel_quit_confirm_title': 'Dieses Duell verlassen?',
  'family_remote_duel_quit_confirm_body':
      'Wenn du gehst, endet das Duell und dein Gegner gewinnt.',
  'family_remote_duel_quit_confirm_stay': 'Weiterspielen',
  'family_remote_duel_quit_confirm_leave': 'Verlassen',
  'family_remote_duel_waiting_declined': 'Die Einladung wurde abgelehnt.',
  'family_remote_duel_waiting_expired':
      'Die Einladung ist abgelaufen (90 Sekunden). Bitte neu einladen.',
  'family_remote_duel_waiting_cancelled': 'Das Duell wurde abgebrochen.',
  'family_remote_duel_waiting_host':
      'Einladung gesendet.\nWarte, bis der andere Spieler auf dem Handy oder Computer akzeptiert.',
  'family_remote_duel_waiting_guest':
      'Einladung erhalten.\nWarte auf andere ausgewählte Familienmitglieder…',
  'family_remote_duel_answer_failed':
      'Antwort konnte nicht gespeichert werden. Bitte erneut versuchen.',
};

const _esDuel = {
  'family_remote_duel_title': 'Duelo familiar a distancia',
  'family_remote_duel_intro':
      'Hola {0} — elige a los familiares a invitar (solo niños vinculados a tu cuenta). La solicitud dura 90 segundos.',
  'family_remote_duel_topic_heading': 'Tema',
  'family_remote_duel_selected_topic': 'Tema seleccionado',
  'family_remote_duel_send_invite': 'Enviar invitación ({0})',
  'family_remote_duel_sending': 'Enviando…',
  'family_remote_duel_footer_rule':
      'El juego no empezará hasta que todos los miembros elegidos acepten en 90 segundos. Si se acaba el tiempo, envía de nuevo la invitación.',
  'family_remote_duel_add_child_hint':
      'Primero añade a tu hijo a la familia desde la cuenta de padres (Panel de padres → Familia).',
  'family_remote_duel_wrong_account_hint':
      'Por las reglas de Firestore, las invitaciones solo pueden enviarse desde la cuenta de padres que tiene el enlace familiar.\n\nQuizá iniciaste sesión con una cuenta infantil; usa la cuenta de padres e inténtalo de nuevo.',
  'family_remote_duel_host_default': 'Padre / madre',
  'family_remote_duel_snackbar_need_selection':
      'Selecciona al menos un familiar y un tema.',
  'family_remote_duel_snackbar_wrong_account':
      'No se pueden enviar duelos remotos desde esta cuenta. Si usas una cuenta infantil en el mismo dispositivo, envía la invitación desde la cuenta de padres.',
  'family_remote_duel_snackbar_send_failed':
      'No se pudo enviar la invitación. Ambas cuentas necesitan Premium y isPremium actualizado en Firestore.',
  'family_remote_duel_play_ribbon': 'Duelo remoto',
  'family_remote_duel_play_summary': 'Resumen',
  'family_remote_duel_round': 'Ronda {current} / {total}',
  'family_remote_duel_your_correct': 'Tus aciertos: {n}',
  'family_remote_duel_turn_you': 'Es tu turno — elige una respuesta.',
  'family_remote_duel_turn_opponent': '{name} está respondiendo — ~{n} s restantes',
  'family_remote_duel_wait_your_turn':
      'Ahora no es tu turno. La misma pregunta aparecerá aquí cuando te toque.',
  'family_remote_duel_seconds_hint': 'Tiempo restante: {n} s',
  'family_remote_duel_seconds_compact': '{n} s',
  'family_remote_duel_turn_wait': 'Respuesta guardada — esperando al otro jugador.',
  'family_remote_duel_summary_title': 'Duelo terminado',
  'family_remote_duel_summary_winner': 'Ganador: {name}',
  'family_remote_duel_summary_tie': 'Empate: {names}',
  'family_remote_duel_summary_scores': 'Respuestas correctas:',
  'family_remote_duel_summary_gold': '¡Has ganado {n} monedas de oro!',
  'family_remote_duel_summary_ok': 'Vale',
  'family_remote_duel_forfeit_win':
      '¡Enhorabuena, has ganado! Tu rival abandonó el duelo.',
  'family_remote_duel_forfeit_you_left': 'Has abandonado este duelo.',
  'family_remote_duel_forfeit_failed':
      'No se pudo avisar al servidor. Comprueba la conexión.',
  'family_remote_duel_quit_confirm_title': '¿Salir del duelo?',
  'family_remote_duel_quit_confirm_body':
      'Si sales, el duelo termina y gana tu rival.',
  'family_remote_duel_quit_confirm_stay': 'Seguir jugando',
  'family_remote_duel_quit_confirm_leave': 'Salir',
  'family_remote_duel_waiting_declined': 'La invitación fue rechazada.',
  'family_remote_duel_waiting_expired':
      'La invitación caducó (90 s). Envía una nueva.',
  'family_remote_duel_waiting_cancelled': 'El duelo fue cancelado.',
  'family_remote_duel_waiting_host':
      'Invitación enviada.\nEspera a que el otro jugador acepte en su móvil u ordenador.',
  'family_remote_duel_waiting_guest':
      'Invitación recibida.\nEsperando a otros familiares seleccionados…',
  'family_remote_duel_answer_failed': 'No se pudo guardar la respuesta. Inténtalo de nuevo.',
};

const _frDuel = {
  'family_remote_duel_title': 'Duel familial à distance',
  'family_remote_duel_intro':
      'Bonjour {0} — choisis les membres de la famille à inviter (uniquement les enfants liés à ton compte). La demande dure 90 secondes.',
  'family_remote_duel_topic_heading': 'Thème',
  'family_remote_duel_selected_topic': 'Thème choisi',
  'family_remote_duel_send_invite': 'Envoyer l’invitation ({0})',
  'family_remote_duel_sending': 'Envoi…',
  'family_remote_duel_footer_rule':
      'Le jeu ne commence pas tant que tous les membres choisis n’ont pas accepté sous 90 secondes. Si le temps est écoulé, renvoie l’invitation.',
  'family_remote_duel_add_child_hint':
      'Ajoute d’abord ton enfant à la famille depuis le compte parent (Espace parents → Famille).',
  'family_remote_duel_wrong_account_hint':
      'Pour les règles Firestore, les invitations ne peuvent être envoyées que depuis le compte parent qui détient le lien familial.\n\nTu es peut-être connecté avec un compte enfant ; connecte-toi avec le compte parent et réessaie.',
  'family_remote_duel_host_default': 'Parent',
  'family_remote_duel_snackbar_need_selection':
      'Sélectionne au moins un membre de la famille et un thème.',
  'family_remote_duel_snackbar_wrong_account':
      'Les duels à distance ne peuvent pas être envoyés depuis ce compte. Si tu es connecté avec un compte enfant sur l’appareil, envoie l’invitation depuis le compte parent.',
  'family_remote_duel_snackbar_send_failed':
      'Impossible d’envoyer l’invitation. Les deux comptes doivent être Premium et isPremium à jour dans Firestore.',
  'family_remote_duel_play_ribbon': 'Duel à distance',
  'family_remote_duel_play_summary': 'Résumé',
  'family_remote_duel_round': 'Manche {current} / {total}',
  'family_remote_duel_your_correct': 'Tes bonnes réponses : {n}',
  'family_remote_duel_turn_you': 'À toi de jouer — choisis une réponse.',
  'family_remote_duel_turn_opponent': '{name} répond — ~{n} s restantes',
  'family_remote_duel_wait_your_turn':
      'Ce n’est pas ton tour. La même question s’affichera ici quand ce sera à toi.',
  'family_remote_duel_seconds_hint': 'Temps restant : {n} s',
  'family_remote_duel_seconds_compact': '{n} s',
  'family_remote_duel_turn_wait': 'Réponse enregistrée — en attente de l’autre joueur.',
  'family_remote_duel_summary_title': 'Duel terminé',
  'family_remote_duel_summary_winner': 'Gagnant : {name}',
  'family_remote_duel_summary_tie': 'Égalité : {names}',
  'family_remote_duel_summary_scores': 'Bonnes réponses :',
  'family_remote_duel_summary_gold': 'Tu as gagné {n} pièces d’or !',
  'family_remote_duel_summary_ok': 'OK',
  'family_remote_duel_forfeit_win':
      'Bravo, tu as gagné ! Ton adversaire a quitté le duel.',
  'family_remote_duel_forfeit_you_left': 'Tu as quitté ce duel.',
  'family_remote_duel_forfeit_failed':
      'Impossible d’avertir le serveur. Vérifie ta connexion.',
  'family_remote_duel_quit_confirm_title': 'Quitter le duel ?',
  'family_remote_duel_quit_confirm_body':
      'Si tu pars, le duel se termine et ton adversaire gagne.',
  'family_remote_duel_quit_confirm_stay': 'Continuer',
  'family_remote_duel_quit_confirm_leave': 'Quitter',
  'family_remote_duel_waiting_declined': 'L’invitation a été refusée.',
  'family_remote_duel_waiting_expired':
      'L’invitation a expiré (90 s). Envoie-en une nouvelle.',
  'family_remote_duel_waiting_cancelled': 'Le duel a été annulé.',
  'family_remote_duel_waiting_host':
      'Invitation envoyée.\nAttends que l’autre joueur accepte sur son téléphone ou ordinateur.',
  'family_remote_duel_waiting_guest':
      'Invitation reçue.\nEn attente des autres membres sélectionnés…',
  'family_remote_duel_answer_failed':
      'Impossible d’enregistrer la réponse. Réessaie.',
};

const _arDuel = {
  'family_remote_duel_title': 'مبارزة عائلية عن بُعد',
  'family_remote_duel_intro':
      'مرحبًا {0} — اختر أفراد العائلة لإرسال الدعوة إليهم (الأطفال المرتبطون بحسابك فقط). مدة الطلب 90 ثانية.',
  'family_remote_duel_topic_heading': 'الموضوع',
  'family_remote_duel_selected_topic': 'الموضوع المحدد',
  'family_remote_duel_send_invite': 'إرسال الدعوة ({0})',
  'family_remote_duel_sending': 'جارٍ الإرسال…',
  'family_remote_duel_footer_rule':
      'لن يبدأ اللعب حتى يقبل جميع الأعضاء المحددين خلال 90 ثانية. إذا انتهى الوقت، أرسل الدعوة مرة أخرى.',
  'family_remote_duel_add_child_hint':
      'أضف طفلك إلى العائلة أولاً من حساب الوالد (لوحة الوالدين ← العائلة).',
  'family_remote_duel_wrong_account_hint':
      'وفقًا لقواعد أمان Firestore، يمكن إرسال دعوات المبارزة عن بُعد فقط من حساب الوالد الذي يحتوي على رابط العائلة.\n\nقد تكون مسجلاً الدخول بحساب طفل؛ سجّل الدخول بحساب الوالد وحاول مرة أخرى.',
  'family_remote_duel_host_default': 'والد',
  'family_remote_duel_snackbar_need_selection': 'اختر عضو عائلة واحد على الأقل وموضوعًا.',
  'family_remote_duel_snackbar_wrong_account':
      'لا يمكن إرسال مبارزات عن بُعد من هذا الحساب. إذا كنت مسجلاً الدخول بحساب طفل على نفس الجهاز، أرسل الدعوة من حساب الوالد.',
  'family_remote_duel_snackbar_send_failed':
      'تعذر إرسال الدعوة. يجب أن يكون لدى الحسابين بريميوم وisPremium محدث في Firestore.',
  'family_remote_duel_play_ribbon': 'مبارزة عن بُعد',
  'family_remote_duel_play_summary': 'ملخص',
  'family_remote_duel_round': 'الجولة {current} / {total}',
  'family_remote_duel_your_correct': 'إجاباتك الصحيحة: {n}',
  'family_remote_duel_turn_you': 'دورك — اختر إجابة.',
  'family_remote_duel_turn_opponent': '{name} يجيب — متبقي ~{n} ث',
  'family_remote_duel_wait_your_turn':
      'ليس دورك الآن. ستظهر نفس السؤال هنا عندما يحين دورك.',
  'family_remote_duel_seconds_hint': 'الوقت المتبقي: {n} ث',
  'family_remote_duel_seconds_compact': '{n} ث',
  'family_remote_duel_turn_wait': 'تم حفظ الإجابة — في انتظار اللاعب الآخر.',
  'family_remote_duel_summary_title': 'انتهت المبارزة',
  'family_remote_duel_summary_winner': 'الفائز: {name}',
  'family_remote_duel_summary_tie': 'تعادل: {names}',
  'family_remote_duel_summary_scores': 'الإجابات الصحيحة:',
  'family_remote_duel_summary_gold': 'ربحت {n} عملة ذهبية!',
  'family_remote_duel_summary_ok': 'حسنًا',
  'family_remote_duel_forfeit_win': 'مبروك، لقد فزت! غادر خصمك المبارزة.',
  'family_remote_duel_forfeit_you_left': 'لقد غادرت هذه المبارزة.',
  'family_remote_duel_forfeit_failed': 'تعذر إخطار الخادم. تحقق من الاتصال.',
  'family_remote_duel_quit_confirm_title': 'مغادرة المبارزة؟',
  'family_remote_duel_quit_confirm_body': 'إذا غادرت، تنتهي المبارزة ويفوز خصمك.',
  'family_remote_duel_quit_confirm_stay': 'متابعة اللعب',
  'family_remote_duel_quit_confirm_leave': 'مغادرة',
  'family_remote_duel_waiting_declined': 'تم رفض الدعوة.',
  'family_remote_duel_waiting_expired': 'انتهت صلاحية الدعوة (90 ث). أرسل دعوة جديدة.',
  'family_remote_duel_waiting_cancelled': 'تم إلغاء المبارزة.',
  'family_remote_duel_waiting_host':
      'تم إرسال الدعوة.\nانتظر قبول اللاعب الآخر على هاتفه أو جهازه.',
  'family_remote_duel_waiting_guest':
      'تم استلام الدعوة.\nفي انتظار قبول أفراد العائلة الآخرين…',
  'family_remote_duel_answer_failed': 'تعذر حفظ الإجابة. حاول مرة أخرى.',
};

const _faDuel = {
  'family_remote_duel_title': 'دوئل خانوادگی از راه دور',
  'family_remote_duel_intro':
      'سلام {0} — اعضای خانواده برای دعوت را انتخاب کنید (فقط کودکان مرتبط با حساب شما). درخواست ۹۰ ثانیه اعتبار دارد.',
  'family_remote_duel_topic_heading': 'موضوع',
  'family_remote_duel_selected_topic': 'موضوع انتخاب‌شده',
  'family_remote_duel_send_invite': 'ارسال دعوتنامه ({0})',
  'family_remote_duel_sending': 'در حال ارسال…',
  'family_remote_duel_footer_rule':
      'بازی تا زمانی که همه اعضای انتخاب‌شده ظرف ۹۰ ثانیه نپذیرند شروع نمی‌شود. اگر وقت تمام شد، دوباره دعوت بفرستید.',
  'family_remote_duel_add_child_hint':
      'ابتدا از حساب والد، فرزند را به خانواده اضافه کنید (پنل والدین ← خانواده).',
  'family_remote_duel_wrong_account_hint':
      'طبق قوانین Firestore، دعوت دوئل فقط از حساب والدی که پیوند خانواده در آن است قابل ارسال است.\n\nممکن است با حساب کودک وارد شده باشید؛ با حساب والد دوباره تلاش کنید.',
  'family_remote_duel_host_default': 'والد',
  'family_remote_duel_snackbar_need_selection': 'حداقل یک عضو خانواده و یک موضوع انتخاب کنید.',
  'family_remote_duel_snackbar_wrong_account':
      'از این حساب نمی‌توان دوئل از راه دور فرستاد. اگر با حساب کودک در همین دستگاه هستید، از حساب والد دعوت بفرستید.',
  'family_remote_duel_snackbar_send_failed':
      'ارسال دعوت ناموفق بود. هر دو حساب باید پریمیوم باشند و isPremium در Firestore به‌روز باشد.',
  'family_remote_duel_play_ribbon': 'دوئل از راه دور',
  'family_remote_duel_play_summary': 'خلاصه',
  'family_remote_duel_round': 'دور {current} / {total}',
  'family_remote_duel_your_correct': 'پاسخ‌های درست تو: {n}',
  'family_remote_duel_turn_you': 'نوبت توست — یک پاسخ انتخاب کن.',
  'family_remote_duel_turn_opponent': '{name} در حال پاسخ — ~{n} ث مانده',
  'family_remote_duel_wait_your_turn':
      'الان نوبت تو نیست. وقتی نوبتت شد همین سؤال اینجا نمایش داده می‌شود.',
  'family_remote_duel_seconds_hint': 'زمان باقی‌مانده: {n} ث',
  'family_remote_duel_seconds_compact': '{n} ث',
  'family_remote_duel_turn_wait': 'پاسخ ذخیره شد — در انتظار بازیکن دیگر.',
  'family_remote_duel_summary_title': 'دوئل تمام شد',
  'family_remote_duel_summary_winner': 'برنده: {name}',
  'family_remote_duel_summary_tie': 'مساوی: {names}',
  'family_remote_duel_summary_scores': 'پاسخ‌های درست:',
  'family_remote_duel_summary_gold': '{n} سکه طلا گرفتی!',
  'family_remote_duel_summary_ok': 'باشه',
  'family_remote_duel_forfeit_win': 'تبریک، بردی! حریف دوئل را ترک کرد.',
  'family_remote_duel_forfeit_you_left': 'این دوئل را ترک کردی.',
  'family_remote_duel_forfeit_failed': 'خبر ترک به سرور نرسید. اتصال را بررسی کن.',
  'family_remote_duel_quit_confirm_title': 'خروج از دوئل؟',
  'family_remote_duel_quit_confirm_body': 'با خروج، دوئل تمام می‌شود و حریف برنده است.',
  'family_remote_duel_quit_confirm_stay': 'ادامه بازی',
  'family_remote_duel_quit_confirm_leave': 'خروج',
  'family_remote_duel_waiting_declined': 'دعوت رد شد.',
  'family_remote_duel_waiting_expired': 'دعوت منقضی شد (۹۰ ث). دعوت جدید بفرست.',
  'family_remote_duel_waiting_cancelled': 'دوئل لغو شد.',
  'family_remote_duel_waiting_host':
      'دعوت ارسال شد.\nمنتظر بمان تا طرف مقابل روی گوشی یا کامپیوتر بپذیرد.',
  'family_remote_duel_waiting_guest':
      'دعوت دریافت شد.\nدر انتظار پذیرش سایر اعضای انتخاب‌شده…',
  'family_remote_duel_answer_failed': 'ذخیره پاسخ نشد. دوباره تلاش کن.',
};

const _idDuel = {
  'family_remote_duel_title': 'Duel keluarga jarak jauh',
  'family_remote_duel_intro':
      'Halo {0} — pilih anggota keluarga untuk diundang (hanya anak yang terhubung ke akun Anda). Permintaan berlaku 90 detik.',
  'family_remote_duel_topic_heading': 'Topik',
  'family_remote_duel_selected_topic': 'Topik terpilih',
  'family_remote_duel_send_invite': 'Kirim undangan ({0})',
  'family_remote_duel_sending': 'Mengirim…',
  'family_remote_duel_footer_rule':
      'Permainan tidak dimulai sampai semua anggota terpilih menerima dalam 90 detik. Jika waktu habis, kirim undangan lagi.',
  'family_remote_duel_add_child_hint':
      'Tambahkan anak ke keluarga dari akun orang tua terlebih dahulu (Panel Orang Tua → Keluarga).',
  'family_remote_duel_wrong_account_hint':
      'Untuk aturan keamanan Firestore, undangan duel jarak jauh hanya bisa dikirim dari akun orang tua yang memegang tautan keluarga.\n\nAnda mungkin masuk dengan akun anak; silakan masuk dengan akun orang tua dan coba lagi.',
  'family_remote_duel_host_default': 'Orang tua',
  'family_remote_duel_snackbar_need_selection':
      'Pilih setidaknya satu anggota keluarga dan satu topik.',
  'family_remote_duel_snackbar_wrong_account':
      'Duel jarak jauh tidak bisa dikirim dari akun ini. Jika Anda masuk dengan akun anak di perangkat yang sama, kirim undangan dari akun orang tua (akun tempat data keluarga disimpan).',
  'family_remote_duel_snackbar_send_failed':
      'Undangan tidak terkirim. Kedua akun harus Premium dan isPremium harus mutakhir di Firestore.',
  'family_remote_duel_play_ribbon': 'Duel jarak jauh',
  'family_remote_duel_play_summary': 'Ringkasan',
  'family_remote_duel_round': 'Babak {current} / {total}',
  'family_remote_duel_your_correct': 'Jawaban benarmu: {n}',
  'family_remote_duel_turn_you': 'Giliranmu — pilih jawaban.',
  'family_remote_duel_turn_opponent': '{name} sedang menjawab — ~{n} dtk tersisa',
  'family_remote_duel_wait_your_turn':
      'Bukan giliranmu sekarang. Pertanyaan yang sama akan muncul di sini saat giliranmu.',
  'family_remote_duel_seconds_hint': 'Sisa waktu: {n} dtk',
  'family_remote_duel_seconds_compact': '{n} dtk',
  'family_remote_duel_turn_wait': 'Jawaban disimpan — menunggu pemain lain.',
  'family_remote_duel_summary_title': 'Duel selesai',
  'family_remote_duel_summary_winner': 'Pemenang: {name}',
  'family_remote_duel_summary_tie': 'Seri: {names}',
  'family_remote_duel_summary_scores': 'Jawaban benar:',
  'family_remote_duel_summary_gold': 'Kamu mendapat {n} koin emas!',
  'family_remote_duel_summary_ok': 'Oke',
  'family_remote_duel_forfeit_win':
      'Selamat, kamu menang! Lawan meninggalkan duel.',
  'family_remote_duel_forfeit_you_left': 'Kamu meninggalkan duel ini.',
  'family_remote_duel_forfeit_failed':
      'Tidak bisa memberi tahu server bahwa kamu keluar. Periksa koneksi dan coba lagi.',
  'family_remote_duel_quit_confirm_title': 'Keluar dari duel?',
  'family_remote_duel_quit_confirm_body':
      'Jika kamu keluar, duel berakhir dan lawan menang.',
  'family_remote_duel_quit_confirm_stay': 'Lanjut bermain',
  'family_remote_duel_quit_confirm_leave': 'Keluar',
  'family_remote_duel_waiting_declined': 'Undangan ditolak.',
  'family_remote_duel_waiting_expired':
      'Undangan kedaluwarsa (90 detik). Kirim undangan baru.',
  'family_remote_duel_waiting_cancelled': 'Duel dibatalkan.',
  'family_remote_duel_waiting_host':
      'Undangan terkirim.\nTunggu pemain lain menerima di ponsel atau komputer mereka.',
  'family_remote_duel_waiting_guest':
      'Undangan diterima.\nMenunggu anggota keluarga terpilih lainnya menerima…',
  'family_remote_duel_answer_failed': 'Jawaban tidak tersimpan. Coba lagi.',
};

const _kuDuel = {
  'family_remote_duel_title': 'Duela malbatê ji dûr',
  'family_remote_duel_intro':
      'Silav {0} — endamên malbatê hilbijêre ku vexwendinê bişînî (tenê zarokên girêdayî hesabê te). Daxwaz 90 çeşeyan derbas dibe.',
  'family_remote_duel_topic_heading': 'Mijar',
  'family_remote_duel_selected_topic': 'Mijara hilbijartî',
  'family_remote_duel_send_invite': 'Vexwendinê bişîne ({0})',
  'family_remote_duel_sending': 'Tê şandin…',
  'family_remote_duel_footer_rule':
      'Lîstik dest pê nake heta hemû endamên hilbijartî di nav 90 ç de qebul nekin. Dem derbas bibe, vexwendinê dîsa bişîne.',
  'family_remote_duel_add_child_hint':
      'Pêşî zarokê xwe ji hesabê dê/bav re malbatê zêde bike (Panela Dê/Bav → Malbat).',
  'family_remote_duel_wrong_account_hint':
      'Ji bo rêzikên ewlehiya Firestore, vexwendinên duelê ji dûr tenê dikarin ji hesabê dê/bav ê girêdana malbatê digire werin şandin.\n\nBelkî bi hesabê zarok têketî yî; bi hesabê dê/bav têkeve û dîsa biceribîne.',
  'family_remote_duel_host_default': 'Dê/Bav',
  'family_remote_duel_snackbar_need_selection':
      'Bi kêmanî yek endam û yek mijar hilbijêre.',
  'family_remote_duel_snackbar_wrong_account':
      'Ji vê hesabê duel ji dûr nayê şandin. Heke bi hesabê zarok li heman cîhazê têketî yî, vexwendinê ji hesabê dê/bav bişîne (hesabê ku daneyên malbatê tê de ne).',
  'family_remote_duel_snackbar_send_failed':
      'Vexwendin nehat şandin. Her du hesab Premium divê û isPremium li Firestore nû be.',
  'family_remote_duel_play_ribbon': 'Duel ji dûr',
  'family_remote_duel_play_summary': 'Kurte',
  'family_remote_duel_round': 'Dor {current} / {total}',
  'family_remote_duel_your_correct': 'Bersivên rast ê te: {n}',
  'family_remote_duel_turn_you': 'Dora te ye — bersivekê hilbijêre.',
  'family_remote_duel_turn_opponent':
      '{name} bersiv dide — ~{n} ç maye',
  'family_remote_duel_wait_your_turn':
      'Niha dora te nîne. Heman pirs dema dora te bû li vir dê xuya bibe.',
  'family_remote_duel_seconds_hint': 'Demê mayî: {n} ç',
  'family_remote_duel_seconds_compact': '{n} ç',
  'family_remote_duel_turn_wait': 'Bersiv hat tomarkirin — li lîstikvanê din tê payin.',
  'family_remote_duel_summary_title': 'Duel qediya',
  'family_remote_duel_summary_winner': 'Serketî: {name}',
  'family_remote_duel_summary_tie': 'Wekhev: {names}',
  'family_remote_duel_summary_scores': 'Bersivên rast:',
  'family_remote_duel_summary_gold': 'Te {n} zêrîna qezenc kir!',
  'family_remote_duel_summary_ok': 'Baş e',
  'family_remote_duel_forfeit_win':
      'Pîroz be, te bû serketî! Reqîb duelê terk kir.',
  'family_remote_duel_forfeit_you_left': 'Te vê duelê terk kir.',
  'family_remote_duel_forfeit_failed':
      'Nikare serverê agahdar bike ku te derket. Girêdanê kontrol bike û dîsa biceribîne.',
  'family_remote_duel_quit_confirm_title': 'Ji vê duelê derkeve?',
  'family_remote_duel_quit_confirm_body':
      'Heke derkevî, duel diqede û reqîb serketî ye.',
  'family_remote_duel_quit_confirm_stay': 'Bilîze berdewam bike',
  'family_remote_duel_quit_confirm_leave': 'Derkeve',
  'family_remote_duel_waiting_declined': 'Vexwendin hate redkirin.',
  'family_remote_duel_waiting_expired':
      'Vexwendin derbas bû (90 ç). Vexwendinekê nû bişîne.',
  'family_remote_duel_waiting_cancelled': 'Duel hate betalkirin.',
  'family_remote_duel_waiting_host':
      'Vexwendin hat şandin.\nLi benda ku lîstikvanê din li telefon an komputerê xwe qebul bike.',
  'family_remote_duel_waiting_guest':
      'Vexwendin hat wergirtin.\nLi endamên malbatê yên din ên hilbijartî tê payin ku qebul bikin…',
  'family_remote_duel_answer_failed': 'Bersiv nehat tomarkirin. Dîsa biceribîne.',
};

const _ruDuel = {
  'family_remote_duel_title': 'Семейная дуэль на расстоянии',
  'family_remote_duel_intro':
      'Привет, {0} — выбери членов семьи для приглашения (только дети, привязанные к твоему аккаунту). Запрос действует 90 секунд.',
  'family_remote_duel_topic_heading': 'Тема',
  'family_remote_duel_selected_topic': 'Выбранная тема',
  'family_remote_duel_send_invite': 'Отправить приглашение ({0})',
  'family_remote_duel_sending': 'Отправка…',
  'family_remote_duel_footer_rule':
      'Игра не начнётся, пока все выбранные участники не примут приглашение за 90 секунд. Если время вышло — отправь приглашение снова.',
  'family_remote_duel_add_child_hint':
      'Сначала добавь ребёнка в семью из родительского аккаунта (Панель родителя → Семья).',
  'family_remote_duel_wrong_account_hint':
      'По правилам безопасности Firestore приглашения на удалённую дуэль можно отправлять только с родительского аккаунта, где хранится связь семьи.\n\nВозможно, ты вошёл в детский аккаунт; войди в родительский и попробуй снова.',
  'family_remote_duel_host_default': 'Родитель',
  'family_remote_duel_snackbar_need_selection':
      'Выбери хотя бы одного члена семьи и тему.',
  'family_remote_duel_snackbar_wrong_account':
      'С этого аккаунта нельзя отправить удалённую дуэль. Если на устройстве открыт детский аккаунт, отправь приглашение с родительского (где хранятся данные семьи).',
  'family_remote_duel_snackbar_send_failed':
      'Не удалось отправить приглашение. У обоих аккаунтов должен быть Premium и актуальный isPremium в Firestore.',
  'family_remote_duel_play_ribbon': 'Удалённая дуэль',
  'family_remote_duel_play_summary': 'Итог',
  'family_remote_duel_round': 'Раунд {current} / {total}',
  'family_remote_duel_your_correct': 'Твои верные ответы: {n}',
  'family_remote_duel_turn_you': 'Твой ход — выбери ответ.',
  'family_remote_duel_turn_opponent':
      '{name} отвечает — осталось ~{n} с',
  'family_remote_duel_wait_your_turn':
      'Сейчас не твой ход. Тот же вопрос появится здесь, когда наступит твоя очередь.',
  'family_remote_duel_seconds_hint': 'Осталось времени: {n} с',
  'family_remote_duel_seconds_compact': '{n} с',
  'family_remote_duel_turn_wait': 'Ответ сохранён — ждём другого игрока.',
  'family_remote_duel_summary_title': 'Дуэль окончена',
  'family_remote_duel_summary_winner': 'Победитель: {name}',
  'family_remote_duel_summary_tie': 'Ничья: {names}',
  'family_remote_duel_summary_scores': 'Верные ответы:',
  'family_remote_duel_summary_gold': 'Ты получил(а) {n} золотых монет!',
  'family_remote_duel_summary_ok': 'ОК',
  'family_remote_duel_forfeit_win':
      'Поздравляем, ты выиграл(а)! Соперник покинул дуэль.',
  'family_remote_duel_forfeit_you_left': 'Ты покинул(а) эту дуэль.',
  'family_remote_duel_forfeit_failed':
      'Не удалось сообщить серверу о выходе. Проверь соединение и попробуй снова.',
  'family_remote_duel_quit_confirm_title': 'Выйти из дуэли?',
  'family_remote_duel_quit_confirm_body':
      'Если выйдешь, дуэль закончится и победит соперник.',
  'family_remote_duel_quit_confirm_stay': 'Продолжить игру',
  'family_remote_duel_quit_confirm_leave': 'Выйти',
  'family_remote_duel_waiting_declined': 'Приглашение отклонено.',
  'family_remote_duel_waiting_expired':
      'Приглашение истекло (90 с). Отправь новое.',
  'family_remote_duel_waiting_cancelled': 'Дуэль отменена.',
  'family_remote_duel_waiting_host':
      'Приглашение отправлено.\nДождись, пока другой игрок примет его на телефоне или компьютере.',
  'family_remote_duel_waiting_guest':
      'Приглашение получено.\nОжидаем, пока остальные выбранные члены семьи примут…',
  'family_remote_duel_answer_failed': 'Не удалось сохранить ответ. Попробуй снова.',
};

const _jaDuel = {
  'family_remote_duel_title': 'リモート家族デュエル',
  'family_remote_duel_intro':
      'こんにちは、{0}さん — 招待する家族メンバーを選んでください（アカウントに紐づいたお子様のみ）。リクエストの有効時間は90秒です。',
  'family_remote_duel_topic_heading': 'トピック',
  'family_remote_duel_selected_topic': '選んだトピック',
  'family_remote_duel_send_invite': '招待を送る ({0})',
  'family_remote_duel_sending': '送信中…',
  'family_remote_duel_footer_rule':
      '選んだ全員が90秒以内に承認するまでゲームは始まりません。時間切れの場合は招待を送り直してください。',
  'family_remote_duel_add_child_hint':
      'まず保護者アカウントからお子様を家族に追加してください（保護者パネル → 家族）。',
  'family_remote_duel_wrong_account_hint':
      'Firestore のセキュリティのため、リモートデュエルの招待は家族リンクを保持する保護者アカウントからのみ送信できます。\n\nお子様アカウントでログインしている可能性があります。保護者アカウントで再度お試しください。',
  'family_remote_duel_host_default': '保護者',
  'family_remote_duel_snackbar_need_selection':
      '家族メンバーとトピックをそれぞれ1つ以上選んでください。',
  'family_remote_duel_snackbar_wrong_account':
      'このアカウントからはリモートデュエルを送信できません。同じ端末でお子様アカウントの場合は、家族データがある保護者アカウントから招待してください。',
  'family_remote_duel_snackbar_send_failed':
      '招待を送信できませんでした。両方のアカウントで Premium が必要で、Firestore の isPremium が最新である必要があります。',
  'family_remote_duel_play_ribbon': 'リモートデュエル',
  'family_remote_duel_play_summary': '結果',
  'family_remote_duel_round': 'ラウンド {current} / {total}',
  'family_remote_duel_your_correct': '正解数: {n}',
  'family_remote_duel_turn_you': 'あなたの番です — 答えを選んでください。',
  'family_remote_duel_turn_opponent':
      '{name} が解答中 — 残り約{n}秒',
  'family_remote_duel_wait_your_turn':
      '今はあなたの番ではありません。順番が来たら同じ問題がここに表示されます。',
  'family_remote_duel_seconds_hint': '残り時間: {n}秒',
  'family_remote_duel_seconds_compact': '{n}秒',
  'family_remote_duel_turn_wait': '解答を保存しました — 相手を待っています。',
  'family_remote_duel_summary_title': 'デュエル終了',
  'family_remote_duel_summary_winner': '勝者: {name}',
  'family_remote_duel_summary_tie': '引き分け: {names}',
  'family_remote_duel_summary_scores': '正解:',
  'family_remote_duel_summary_gold': '{n} ゴールドコインを獲得しました！',
  'family_remote_duel_summary_ok': 'OK',
  'family_remote_duel_forfeit_win':
      'おめでとう、勝ちました！相手がデュエルを退出しました。',
  'family_remote_duel_forfeit_you_left': 'このデュエルを退出しました。',
  'family_remote_duel_forfeit_failed':
      '退出をサーバーに通知できませんでした。接続を確認して再試行してください。',
  'family_remote_duel_quit_confirm_title': 'デュエルを退出しますか？',
  'family_remote_duel_quit_confirm_body':
      '退出するとデュエルは終了し、相手の勝ちになります。',
  'family_remote_duel_quit_confirm_stay': '続ける',
  'family_remote_duel_quit_confirm_leave': '退出',
  'family_remote_duel_waiting_declined': '招待が拒否されました。',
  'family_remote_duel_waiting_expired':
      '招待の期限が切れました（90秒）。新しい招待を送ってください。',
  'family_remote_duel_waiting_cancelled': 'デュエルはキャンセルされました。',
  'family_remote_duel_waiting_host':
      '招待を送信しました。\n相手がスマートフォンまたはPCで承認するまでお待ちください。',
  'family_remote_duel_waiting_guest':
      '招待を受け取りました。\n他の選ばれた家族メンバーの承認を待っています…',
  'family_remote_duel_answer_failed': '解答を保存できませんでした。もう一度お試しください。',
};

const _koDuel = {
  'family_remote_duel_title': '원격 가족 대결',
  'family_remote_duel_intro':
      '안녕하세요, {0}님 — 초대할 가족 구성원을 선택하세요 (계정에 연결된 자녀만 가능). 요청은 90초 동안 유효합니다.',
  'family_remote_duel_topic_heading': '주제',
  'family_remote_duel_selected_topic': '선택한 주제',
  'family_remote_duel_send_invite': '초대 보내기 ({0})',
  'family_remote_duel_sending': '보내는 중…',
  'family_remote_duel_footer_rule':
      '선택한 모든 구성원이 90초 안에 수락해야 게임이 시작됩니다. 시간이 지나면 초대를 다시 보내세요.',
  'family_remote_duel_add_child_hint':
      '먼저 부모 계정에서 자녀를 가족에 추가하세요 (부모 패널 → 가족).',
  'family_remote_duel_wrong_account_hint':
      'Firestore 보안 규칙상 원격 대결 초대는 가족 연결을 보유한 부모 계정에서만 보낼 수 있습니다.\n\n자녀 계정으로 로그인했을 수 있습니다. 부모 계정으로 다시 시도하세요.',
  'family_remote_duel_host_default': '부모',
  'family_remote_duel_snackbar_need_selection':
      '가족 구성원과 주제를 각각 하나 이상 선택하세요.',
  'family_remote_duel_snackbar_wrong_account':
      '이 계정에서는 원격 대결을 보낼 수 없습니다. 같은 기기에서 자녀 계정이면 가족 데이터가 있는 부모 계정에서 초대하세요.',
  'family_remote_duel_snackbar_send_failed':
      '초대를 보낼 수 없습니다. 두 계정 모두 Premium이어야 하며 Firestore의 isPremium이 최신이어야 합니다.',
  'family_remote_duel_play_ribbon': '원격 대결',
  'family_remote_duel_play_summary': '요약',
  'family_remote_duel_round': '라운드 {current} / {total}',
  'family_remote_duel_your_correct': '맞힌 개수: {n}',
  'family_remote_duel_turn_you': '당신 차례입니다 — 답을 고르세요.',
  'family_remote_duel_turn_opponent':
      '{name} 님이 답하는 중 — 약 {n}초 남음',
  'family_remote_duel_wait_your_turn':
      '지금은 당신 차례가 아닙니다. 차례가 오면 같은 문제가 여기에 표시됩니다.',
  'family_remote_duel_seconds_hint': '남은 시간: {n}초',
  'family_remote_duel_seconds_compact': '{n}초',
  'family_remote_duel_turn_wait': '답이 저장되었습니다 — 상대를 기다리는 중입니다.',
  'family_remote_duel_summary_title': '대결 종료',
  'family_remote_duel_summary_winner': '승자: {name}',
  'family_remote_duel_summary_tie': '무승부: {names}',
  'family_remote_duel_summary_scores': '정답:',
  'family_remote_duel_summary_gold': '금화 {n}개를 획득했습니다!',
  'family_remote_duel_summary_ok': '확인',
  'family_remote_duel_forfeit_win':
      '축하합니다, 승리했습니다! 상대가 대결을 나갔습니다.',
  'family_remote_duel_forfeit_you_left': '이 대결을 나갔습니다.',
  'family_remote_duel_forfeit_failed':
      '서버에 나감을 알리지 못했습니다. 연결을 확인하고 다시 시도하세요.',
  'family_remote_duel_quit_confirm_title': '대결을 나가시겠습니까?',
  'family_remote_duel_quit_confirm_body':
      '나가면 대결이 끝나고 상대가 이깁니다.',
  'family_remote_duel_quit_confirm_stay': '계속하기',
  'family_remote_duel_quit_confirm_leave': '나가기',
  'family_remote_duel_waiting_declined': '초대가 거절되었습니다.',
  'family_remote_duel_waiting_expired':
      '초대가 만료되었습니다(90초). 새 초대를 보내세요.',
  'family_remote_duel_waiting_cancelled': '대결이 취소되었습니다.',
  'family_remote_duel_waiting_host':
      '초대를 보냈습니다.\n상대가 휴대폰이나 컴퓨터에서 수락할 때까지 기다리세요.',
  'family_remote_duel_waiting_guest':
      '초대를 받았습니다.\n다른 선택된 가족 구성원의 수락을 기다리는 중…',
  'family_remote_duel_answer_failed': '답을 저장하지 못했습니다. 다시 시도하세요.',
};

const _hiDuel = {
  'family_remote_duel_title': 'दूरस्थ पारिवारिक द्वंद्व',
  'family_remote_duel_intro':
      'नमस्ते {0} — आमंत्रित करने के लिए परिवार के सदस्य चुनें (केवल आपके खाते से जुड़े बच्चे)। अनुरोध 90 सेकंड तक मान्य है।',
  'family_remote_duel_topic_heading': 'विषय',
  'family_remote_duel_selected_topic': 'चयनित विषय',
  'family_remote_duel_send_invite': 'आमंत्रण भेजें ({0})',
  'family_remote_duel_sending': 'भेजा जा रहा है…',
  'family_remote_duel_footer_rule':
      'जब तक सभी चयनित सदस्य 90 सेकंड में स्वीकार नहीं करते, खेल शुरू नहीं होगा। समय समाप्त होने पर फिर से आमंत्रण भेजें।',
  'family_remote_duel_add_child_hint':
      'पहले माता-पिता खाते से बच्चे को परिवार में जोड़ें (माता-पिता पैनल → परिवार)।',
  'family_remote_duel_wrong_account_hint':
      'Firestore सुरक्षा नियमों के कारण, दूरस्थ द्वंद्व आमंत्रण केवल उस माता-पिता खाते से भेजे जा सकते हैं जिसमें पारिवारिक लिंक हो।\n\nशायद आप बच्चे के खाते से लॉग इन हैं; माता-पिता खाते से प्रयास करें।',
  'family_remote_duel_host_default': 'माता-पिता',
  'family_remote_duel_snackbar_need_selection':
      'कम से कम एक परिवार सदस्य और एक विषय चुनें।',
  'family_remote_duel_snackbar_wrong_account':
      'इस खाते से दूरस्थ द्वंद्व नहीं भेजा जा सकता। यदि उसी डिवाइस पर बच्चे का खाता है, तो माता-पिता खाते से आमंत्रण भेजें।',
  'family_remote_duel_snackbar_send_failed':
      'आमंत्रण नहीं भेजा जा सका। दोनों खातों पर Premium होना चाहिए और Firestore में isPremium अद्यतन हो।',
  'family_remote_duel_play_ribbon': 'दूरस्थ द्वंद्व',
  'family_remote_duel_play_summary': 'सारांश',
  'family_remote_duel_round': 'राउंड {current} / {total}',
  'family_remote_duel_your_correct': 'आपके सही उत्तर: {n}',
  'family_remote_duel_turn_you': 'आपकी बारी — उत्तर चुनें।',
  'family_remote_duel_turn_opponent':
      '{name} उत्तर दे रहे हैं — ~{n} सेकंड शेष',
  'family_remote_duel_wait_your_turn':
      'अभी आपकी बारी नहीं है। जब बारी आएगी, वही प्रश्न यहाँ दिखेगा।',
  'family_remote_duel_seconds_hint': 'शेष समय: {n} से',
  'family_remote_duel_seconds_compact': '{n} से',
  'family_remote_duel_turn_wait': 'उत्तर सहेजा गया — दूसरे खिलाड़ी की प्रतीक्षा।',
  'family_remote_duel_summary_title': 'द्वंद्व समाप्त',
  'family_remote_duel_summary_winner': 'विजेता: {name}',
  'family_remote_duel_summary_tie': 'बराबरी: {names}',
  'family_remote_duel_summary_scores': 'सही उत्तर:',
  'family_remote_duel_summary_gold': 'आपने {n} सोने के सिक्के कमाए!',
  'family_remote_duel_summary_ok': 'ठीक',
  'family_remote_duel_forfeit_win':
      'बधाई, आप जीते! प्रतिद्वंद्वी ने द्वंद्व छोड़ दिया।',
  'family_remote_duel_forfeit_you_left': 'आपने यह द्वंद्व छोड़ दिया।',
  'family_remote_duel_forfeit_failed':
      'सर्वर को सूचित नहीं कर सके। कनेक्शन जाँचें और पुनः प्रयास करें।',
  'family_remote_duel_quit_confirm_title': 'द्वंद्व छोड़ें?',
  'family_remote_duel_quit_confirm_body':
      'छोड़ने पर द्वंद्व समाप्त होगा और प्रतिद्वंद्वी जीतेगा।',
  'family_remote_duel_quit_confirm_stay': 'खेलना जारी रखें',
  'family_remote_duel_quit_confirm_leave': 'छोड़ें',
  'family_remote_duel_waiting_declined': 'आमंत्रण अस्वीकृत।',
  'family_remote_duel_waiting_expired':
      'आमंत्रण समाप्त (90 सेकंड)। नया आमंत्रण भेजें।',
  'family_remote_duel_waiting_cancelled': 'द्वंद्व रद्द।',
  'family_remote_duel_waiting_host':
      'आमंत्रण भेजा गया।\nदूसरे खिलाड़ी के फोन या कंप्यूटर पर स्वीकार करने की प्रतीक्षा करें।',
  'family_remote_duel_waiting_guest':
      'आमंत्रण मिला।\nअन्य चयनित सदस्यों के स्वीकार करने की प्रतीक्षा…',
  'family_remote_duel_answer_failed': 'उत्तर सहेजा नहीं जा सका। पुनः प्रयास करें।',
};

const _urDuel = {
  'family_remote_duel_title': 'ریموٹ فیملی دوئل',
  'family_remote_duel_intro':
      'سلام {0} — دعوت کے لیے فیملی ممبرز منتخب کریں (صرف آپ کے اکاؤنٹ سے منسلک بچے)۔ درخواست 90 سیکنڈ تک درست ہے۔',
  'family_remote_duel_topic_heading': 'موضوع',
  'family_remote_duel_selected_topic': 'منتخب موضوع',
  'family_remote_duel_send_invite': 'دعوت بھیجیں ({0})',
  'family_remote_duel_sending': 'بھیجا جا رہا ہے…',
  'family_remote_duel_footer_rule':
      'جب تک تمام منتخب ممبرز 90 سیکنڈ میں قبول نہ کریں کھیل شروع نہیں ہوگا۔ وقت ختم ہو تو دوبارہ دعوت بھیجیں۔',
  'family_remote_duel_add_child_hint':
      'پہلے والدین کے اکاؤنٹ سے بچے کو فیملی میں شامل کریں (والدین پینل → فیملی)۔',
  'family_remote_duel_wrong_account_hint':
      'Firestore سیکیورٹی قواعد کے مطابق ریموٹ دوئل کی دعوت صرف اس والدین کے اکاؤنٹ سے بھیجی جا سکتی ہے جس میں فیملی لنک ہو۔\n\nشاید آپ بچے کے اکاؤنٹ سے لاگ ان ہیں؛ والدین کے اکاؤنٹ سے دوبارہ کوشش کریں۔',
  'family_remote_duel_host_default': 'والدین',
  'family_remote_duel_snackbar_need_selection':
      'کم از کم ایک فیملی ممبر اور ایک موضوع منتخب کریں۔',
  'family_remote_duel_snackbar_wrong_account':
      'اس اکاؤنٹ سے ریموٹ دوئل نہیں بھیجی جا سکتی۔ اگر اسی ڈیوائس پر بچے کا اکاؤنٹ ہے تو والدین کے اکاؤنٹ سے دعوت بھیجیں۔',
  'family_remote_duel_snackbar_send_failed':
      'دعوت نہیں بھیج سکے۔ دونوں اکاؤنٹس پر Premium ہونا چاہیے اور Firestore میں isPremium تازہ ہو۔',
  'family_remote_duel_play_ribbon': 'ریموٹ دوئل',
  'family_remote_duel_play_summary': 'خلاصہ',
  'family_remote_duel_round': 'راؤنڈ {current} / {total}',
  'family_remote_duel_your_correct': 'آپ کے صحیح جوابات: {n}',
  'family_remote_duel_turn_you': 'آپ کی باری — جواب منتخب کریں۔',
  'family_remote_duel_turn_opponent':
      '{name} جواب دے رہے ہیں — ~{n} سیکنڈ باقی',
  'family_remote_duel_wait_your_turn':
      'ابھی آپ کی باری نہیں۔ جب باری آئے گی وہی سوال یہاں نظر آئے گا۔',
  'family_remote_duel_seconds_hint': 'باقی وقت: {n} س',
  'family_remote_duel_seconds_compact': '{n} س',
  'family_remote_duel_turn_wait': 'جواب محفوظ — دوسرے کھلاڑی کا انتظار۔',
  'family_remote_duel_summary_title': 'دوئل ختم',
  'family_remote_duel_summary_winner': 'فاتح: {name}',
  'family_remote_duel_summary_tie': 'برابری: {names}',
  'family_remote_duel_summary_scores': 'صحیح جوابات:',
  'family_remote_duel_summary_gold': 'آپ نے {n} سونے کے سکے کمائے!',
  'family_remote_duel_summary_ok': 'ٹھیک',
  'family_remote_duel_forfeit_win':
      'مبارک، آپ جیت گئے! حریف نے دوئل چھوڑ دی۔',
  'family_remote_duel_forfeit_you_left': 'آپ نے یہ دوئل چھوڑ دی۔',
  'family_remote_duel_forfeit_failed':
      'سرور کو مطلع نہیں کر سکے۔ کنکشن چیک کریں اور دوبارہ کوشش کریں۔',
  'family_remote_duel_quit_confirm_title': 'دوئل چھوڑیں؟',
  'family_remote_duel_quit_confirm_body':
      'چھوڑنے پر دوئل ختم ہو جائے گی اور حریف جیت جائے گا۔',
  'family_remote_duel_quit_confirm_stay': 'کھیل جاری رکھیں',
  'family_remote_duel_quit_confirm_leave': 'چھوڑیں',
  'family_remote_duel_waiting_declined': 'دعوت مسترد۔',
  'family_remote_duel_waiting_expired':
      'دعوت ختم (90 سیکنڈ)۔ نئی دعوت بھیجیں۔',
  'family_remote_duel_waiting_cancelled': 'دوئل منسوخ۔',
  'family_remote_duel_waiting_host':
      'دعوت بھیج دی گئی۔\nدوسرے کھلاڑی کے فون یا کمپیوٹر پر قبول کرنے کا انتظار کریں۔',
  'family_remote_duel_waiting_guest':
      'دعوت موصول۔\nدیگر منتخب ممبرز کے قبول کرنے کا انتظار…',
  'family_remote_duel_answer_failed': 'جواب محفوظ نہیں ہو سکا۔ دوبارہ کوشش کریں۔',
};

const _ptDuel = {
  'family_remote_duel_title': 'Duelo familiar remoto',
  'family_remote_duel_intro':
      'Olá {0} — seleciona membros da família para convidar (apenas crianças ligadas à tua conta). O pedido dura 90 segundos.',
  'family_remote_duel_topic_heading': 'Tópico',
  'family_remote_duel_selected_topic': 'Tópico selecionado',
  'family_remote_duel_send_invite': 'Enviar convite ({0})',
  'family_remote_duel_sending': 'A enviar…',
  'family_remote_duel_footer_rule':
      'O jogo não começa até todos os membros selecionados aceitarem em 90 segundos. Se o tempo acabar, envia o convite de novo.',
  'family_remote_duel_add_child_hint':
      'Primeiro adiciona o teu filho à família na conta dos pais (Painel dos pais → Família).',
  'family_remote_duel_wrong_account_hint':
      'Pelas regras de segurança do Firestore, convites de duelo remoto só podem ser enviados da conta dos pais que detém a ligação da família.\n\nPodes estar com a conta da criança; entra com a conta dos pais e tenta de novo.',
  'family_remote_duel_host_default': 'Pais',
  'family_remote_duel_snackbar_need_selection':
      'Seleciona pelo menos um membro da família e um tópico.',
  'family_remote_duel_snackbar_wrong_account':
      'Não é possível enviar duelos remotos desta conta. Se estiveres com a conta da criança no mesmo dispositivo, envia o convite da conta dos pais.',
  'family_remote_duel_snackbar_send_failed':
      'Não foi possível enviar o convite. Ambas as contas precisam de Premium e isPremium atualizado no Firestore.',
  'family_remote_duel_play_ribbon': 'Duelo remoto',
  'family_remote_duel_play_summary': 'Resumo',
  'family_remote_duel_round': 'Ronda {current} / {total}',
  'family_remote_duel_your_correct': 'Tuas respostas certas: {n}',
  'family_remote_duel_turn_you': 'É a tua vez — escolhe uma resposta.',
  'family_remote_duel_turn_opponent':
      '{name} está a responder — ~{n}s restantes',
  'family_remote_duel_wait_your_turn':
      'Não é a tua vez agora. A mesma pergunta aparecerá aqui quando for a tua vez.',
  'family_remote_duel_seconds_hint': 'Tempo restante: {n}s',
  'family_remote_duel_seconds_compact': '{n} s',
  'family_remote_duel_turn_wait': 'Resposta guardada — a aguardar o outro jogador.',
  'family_remote_duel_summary_title': 'Duelo terminado',
  'family_remote_duel_summary_winner': 'Vencedor: {name}',
  'family_remote_duel_summary_tie': 'Empate: {names}',
  'family_remote_duel_summary_scores': 'Respostas certas:',
  'family_remote_duel_summary_gold': 'Ganhaste {n} moedas de ouro!',
  'family_remote_duel_summary_ok': 'OK',
  'family_remote_duel_forfeit_win':
      'Parabéns, ganhaste! O adversário saiu do duelo.',
  'family_remote_duel_forfeit_you_left': 'Saíste deste duelo.',
  'family_remote_duel_forfeit_failed':
      'Não foi possível avisar o servidor. Verifica a ligação e tenta de novo.',
  'family_remote_duel_quit_confirm_title': 'Sair do duelo?',
  'family_remote_duel_quit_confirm_body':
      'Se saíres, o duelo acaba e o adversário ganha.',
  'family_remote_duel_quit_confirm_stay': 'Continuar a jogar',
  'family_remote_duel_quit_confirm_leave': 'Sair',
  'family_remote_duel_waiting_declined': 'O convite foi recusado.',
  'family_remote_duel_waiting_expired':
      'O convite expirou (90 s). Envia um novo convite.',
  'family_remote_duel_waiting_cancelled': 'O duelo foi cancelado.',
  'family_remote_duel_waiting_host':
      'Convite enviado.\nEspera que o outro jogador aceite no telemóvel ou computador.',
  'family_remote_duel_waiting_guest':
      'Convite recebido.\nA aguardar que outros membros selecionados aceitem…',
  'family_remote_duel_answer_failed':
      'Não foi possível guardar a resposta. Tenta de novo.',
};

const _itDuel = {
  'family_remote_duel_title': 'Duello familiare a distanza',
  'family_remote_duel_intro':
      'Ciao {0} — seleziona i membri della famiglia da invitare (solo i figli collegati al tuo account). La richiesta dura 90 secondi.',
  'family_remote_duel_topic_heading': 'Argomento',
  'family_remote_duel_selected_topic': 'Argomento selezionato',
  'family_remote_duel_send_invite': 'Invia invito ({0})',
  'family_remote_duel_sending': 'Invio in corso…',
  'family_remote_duel_footer_rule':
      'Il gioco non inizia finché tutti i membri selezionati non accettano entro 90 secondi. Se il tempo scade, invia di nuovo l\'invito.',
  'family_remote_duel_add_child_hint':
      'Prima aggiungi il tuo bambino alla famiglia dall\'account genitore (Pannello genitori → Famiglia).',
  'family_remote_duel_wrong_account_hint':
      'Per le regole di sicurezza di Firestore, gli inviti al duello a distanza possono essere inviati solo dall\'account genitore che detiene il collegamento famiglia.\n\nPotresti essere connesso con l\'account del bambino; accedi con l\'account genitore e riprova.',
  'family_remote_duel_host_default': 'Genitore',
  'family_remote_duel_snackbar_need_selection':
      'Seleziona almeno un membro della famiglia e un argomento.',
  'family_remote_duel_snackbar_wrong_account':
      'Non puoi inviare duelli a distanza da questo account. Se sei con l\'account del bambino sullo stesso dispositivo, invia l\'invito dall\'account genitore.',
  'family_remote_duel_snackbar_send_failed':
      'Impossibile inviare l\'invito. Entrambi gli account devono avere Premium e isPremium aggiornato su Firestore.',
  'family_remote_duel_play_ribbon': 'Duello a distanza',
  'family_remote_duel_play_summary': 'Riepilogo',
  'family_remote_duel_round': 'Round {current} / {total}',
  'family_remote_duel_your_correct': 'Le tue risposte corrette: {n}',
  'family_remote_duel_turn_you': 'Tocca a te — scegli una risposta.',
  'family_remote_duel_turn_opponent':
      '{name} sta rispondendo — ~{n}s rimanenti',
  'family_remote_duel_wait_your_turn':
      'Non è il tuo turno. La stessa domanda apparirà qui quando sarai tu.',
  'family_remote_duel_seconds_hint': 'Tempo rimasto: {n}s',
  'family_remote_duel_seconds_compact': '{n} s',
  'family_remote_duel_turn_wait': 'Risposta salvata — in attesa dell\'altro giocatore.',
  'family_remote_duel_summary_title': 'Duello finito',
  'family_remote_duel_summary_winner': 'Vincitore: {name}',
  'family_remote_duel_summary_tie': 'Pareggio: {names}',
  'family_remote_duel_summary_scores': 'Risposte corrette:',
  'family_remote_duel_summary_gold': 'Hai guadagnato {n} monete d\'oro!',
  'family_remote_duel_summary_ok': 'OK',
  'family_remote_duel_forfeit_win':
      'Congratulazioni, hai vinto! L\'avversario ha lasciato il duello.',
  'family_remote_duel_forfeit_you_left': 'Hai lasciato questo duello.',
  'family_remote_duel_forfeit_failed':
      'Impossibile avvisare il server. Controlla la connessione e riprova.',
  'family_remote_duel_quit_confirm_title': 'Uscire dal duello?',
  'family_remote_duel_quit_confirm_body':
      'Se esci, il duello termina e vince l\'avversario.',
  'family_remote_duel_quit_confirm_stay': 'Continua a giocare',
  'family_remote_duel_quit_confirm_leave': 'Esci',
  'family_remote_duel_waiting_declined': 'L\'invito è stato rifiutato.',
  'family_remote_duel_waiting_expired':
      'L\'invito è scaduto (90 s). Invia un nuovo invito.',
  'family_remote_duel_waiting_cancelled': 'Il duello è stato annullato.',
  'family_remote_duel_waiting_host':
      'Invito inviato.\nAttendi che l\'altro giocatore accetti su telefono o computer.',
  'family_remote_duel_waiting_guest':
      'Invito ricevuto.\nIn attesa che gli altri membri selezionati accettino…',
  'family_remote_duel_answer_failed': 'Impossibile salvare la risposta. Riprova.',
};

const _plDuel = {
  'family_remote_duel_title': 'Rodzinny pojedynek zdalny',
  'family_remote_duel_intro':
      'Witaj {0} — wybierz czlonkow rodziny do zaproszenia (tylko dzieci powiazane z Twoim kontem). Zaproszenie wazne jest 90 sekund.',
  'family_remote_duel_topic_heading': 'Temat',
  'family_remote_duel_selected_topic': 'Wybrany temat',
  'family_remote_duel_send_invite': 'Wyslij zaproszenie ({0})',
  'family_remote_duel_sending': 'Wysylanie…',
  'family_remote_duel_footer_rule':
      'Gra nie rozpocznie sie, dopoki wszyscy wybrani czlonkowie nie zaakceptuja w 90 sekund. Po uplywie czasu wyslij zaproszenie ponownie.',
  'family_remote_duel_add_child_hint':
      'Najpierw dodaj dziecko do rodziny z konta rodzica (Panel rodzica → Rodzina).',
  'family_remote_duel_wrong_account_hint':
      'Ze wzgledu na reguly Firestore zaproszenia do pojedynku zdalnego mozna wysylac tylko z konta rodzica, ktore przechowuje polaczenie rodziny.\n\nMozesz byc zalogowany na koncie dziecka; zaloguj sie na konto rodzica i sprobuj ponownie.',
  'family_remote_duel_host_default': 'Rodzic',
  'family_remote_duel_snackbar_need_selection':
      'Wybierz co najmniej jednego czlonka rodziny i temat.',
  'family_remote_duel_snackbar_wrong_account':
      'Z tego konta nie mozna wyslac pojedynku zdalnego. Jesli na tym samym urzadzeniu jest konto dziecka, wyslij zaproszenie z konta rodzica.',
  'family_remote_duel_snackbar_send_failed':
      'Nie udalo sie wyslac zaproszenia. Oba konta musza miec Premium i aktualne isPremium w Firestore.',
  'family_remote_duel_play_ribbon': 'Pojedynek zdalny',
  'family_remote_duel_play_summary': 'Podsumowanie',
  'family_remote_duel_round': 'Runda {current} / {total}',
  'family_remote_duel_your_correct': 'Twoje poprawne odpowiedzi: {n}',
  'family_remote_duel_turn_you': 'Twoja kolej — wybierz odpowiedz.',
  'family_remote_duel_turn_opponent':
      '{name} odpowiada — pozostalo ~{n} s',
  'family_remote_duel_wait_your_turn':
      'Teraz nie Twoja kolej. To samo pytanie pojawi sie tutaj, gdy przyjdzie Twoja kolej.',
  'family_remote_duel_seconds_hint': 'Pozostaly czas: {n} s',
  'family_remote_duel_seconds_compact': '{n} s',
  'family_remote_duel_turn_wait': 'Odpowiedz zapisana — oczekiwanie na drugiego gracza.',
  'family_remote_duel_summary_title': 'Pojedynek zakonczony',
  'family_remote_duel_summary_winner': 'Zwyciezca: {name}',
  'family_remote_duel_summary_tie': 'Remis: {names}',
  'family_remote_duel_summary_scores': 'Poprawne odpowiedzi:',
  'family_remote_duel_summary_gold': 'Zdobyles {n} zlotych monet!',
  'family_remote_duel_summary_ok': 'OK',
  'family_remote_duel_forfeit_win':
      'Gratulacje, wygrales! Przeciwnik opuscil pojedynek.',
  'family_remote_duel_forfeit_you_left': 'Opusciles ten pojedynek.',
  'family_remote_duel_forfeit_failed':
      'Nie udalo sie powiadomic serwera. Sprawdz polaczenie i sprobuj ponownie.',
  'family_remote_duel_quit_confirm_title': 'Opuscic pojedynek?',
  'family_remote_duel_quit_confirm_body':
      'Jesli wyjdziesz, pojedynek sie konczy i wygrywa przeciwnik.',
  'family_remote_duel_quit_confirm_stay': 'Graj dalej',
  'family_remote_duel_quit_confirm_leave': 'Wyjdz',
  'family_remote_duel_waiting_declined': 'Zaproszenie odrzucone.',
  'family_remote_duel_waiting_expired':
      'Zaproszenie wygaslo (90 s). Wyslij nowe.',
  'family_remote_duel_waiting_cancelled': 'Pojedynek anulowany.',
  'family_remote_duel_waiting_host':
      'Zaproszenie wyslane.\nPoczekaj, az drugi gracz zaakceptuje na telefonie lub komputerze.',
  'family_remote_duel_waiting_guest':
      'Zaproszenie odebrane.\nOczekiwanie na akceptacje pozostalych wybranych czlonkow…',
  'family_remote_duel_answer_failed': 'Nie udalo sie zapisac odpowiedzi. Sprobuj ponownie.',
};
