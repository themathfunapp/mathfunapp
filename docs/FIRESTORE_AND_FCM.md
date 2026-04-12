# Firestore kuralları ve FCM (uzaktan aile düellosu)

## 1. Firestore kuralları (`firestore.rules`)

Üretim dosyası **geniş catch-all içermez**. Özet:

| Alan | Kural özeti |
|------|----------------|
| **`pinResetCodes`**, **`mail`** | İstemci erişimi kapalı (yalnızca Cloud Functions / Admin SDK). |
| **`guests/{guestId}`** | Misafir kaydı: `auth == null`, `guestId == data.uid`, `isGuest == true`. Okuma/silme: giriş yapmış kullanıcı (dönüşümde silme vb.). |
| **`friendRequests`** | Gönderen oluşturur; alıcı/gönderen okur; alıcı `accepted`/`rejected` günceller; gönderen bekleyen isteği silebilir. |
| **`friendDuelInvites`** | Gönderen oluşturur; taraflar okur; gönderen veya alıcı (yalnızca `pending`) silebilir. |
| **`users/{userId}`** | Okuma: giriş yapmış herkes (arkadaş araması). Oluşturma/güncelleme/silme: yalnızca sahibi. |
| **`users/.../friends`**, **`rewards`**, **`stats`**, **`badges`**, **`game_stats`**, **`game_history`**, **`family/members`**, **`private/fcm`** | Sahip veya (friends için) arkadaşlığın iki tarafı yazabilir (istek kabulü senkronu). |
| **`familyRemoteDuelSessions` / `Invites`** | Katılımcı + `childUserIds` ile ebeveyn–çocuk doğrulaması (önceki tasarım). |
| **`story_progress`**, **`mini_game_progress`** | Kayıtlı: `docId == auth.uid`. Misafir MTN kimliği: `auth == null` ve `docId` MTN biçimi. |
| **`user_mechanics`** | Yalnızca `docId == auth.uid`. |
| **`user_quests/{userId}/active`** | Kayıtlı veya misafir MTN `userId` yolu. |
| **`daily_challenges`** | Okuma/yazma: giriş yapmış (şablon istemci üretir; ileride Cloud Function önerilir). |
| **`user_challenges`** | Belge kimliği `auth.uid_` ile başlamalı. |
| **`purchases`** | Oluşturma: `data.userId == auth.uid`; okuma: yalnızca kendi kayıtları. |

### Deploy

```bash
firebase deploy --only firestore:rules,firestore:indexes
```

Yeni sorgular için `firestore.indexes.json` içinde bileşik indeksler tanımlıdır (ör. `friendDuelInvites`).

## 2. `childUserIds` alanı

- Çocuk eklenince `members` ile birlikte yazılır.
- Ebeveyn `loadMembers` çalıştığında `members` ile uyumsuzsa `childUserIds` otomatik düzeltilir (eski veriler için).

## 3. FCM mimarisi

### 3.1 İstemci (Flutter)

- Paketler: `firebase_messaging`, `flutter_local_notifications`.
- **Jeton**: `getToken()`, `onTokenRefresh` → `users/{uid}/private/fcm/current`.
- **Arka plan / kapalı**: `onMessageOpenedApp` ve `getInitialMessage` → davet `inviteId` / `sessionId` [HomeScreen] kuyruğuna alınır (`PushNotificationService`).
- **Ön plan**: `onMessage` ile `family_remote_duel_invite` gelince yerel bildirim; kullanıcı bildirime basınca aynı kuyruk (`payload`: `frd|inviteId|sessionId`).
- Web: `PushNotificationService` `kIsWeb` ise erken çıkış.

### 3.2 Sunucu (Cloud Functions)

- Tetikleyici: `familyRemoteDuelInvites` **onCreate** (`status == pending`).
- `users/{toUserId}/private/fcm/current` okunur; `token` varsa `admin.messaging().send(...)`.
- `data`: `type`, `inviteId`, `sessionId`.

### 3.3 Operasyonel kontrol listesi

1. Firebase projesi **Blaze** (Functions + FCM).
2. **Cloud Function** deploy: `firebase deploy --only functions:onFamilyRemoteDuelInviteCreated` (veya tüm functions).
3. **Android**: `POST_NOTIFICATIONS` (API 33+) manifestte; kullanıcıdan bildirim izni.
4. **iOS**: APNs anahtarı; Xcode’da Push Notifications; arka planda bildirim seçenekleri.
5. **Firestore**: kurallar + indeks deploy (yukarıdaki komut).

### 3.4 Fonksiyon derleme ve deploy

```bash
cd functions && npm run build && cd .. && firebase deploy --only functions:onFamilyRemoteDuelInviteCreated
```

## 4. Davet tıklanınca uygulama içi yönlendirme

- Ana sayfa şeridinden kabul (mevcut).
- **Push (FCM veya yerel bildirim)**: `PushNotificationService` kuyruğu → `HomeScreen` dinleyicisi `acceptInvite` + `FamilyRemoteDuelPlayScreen`.
