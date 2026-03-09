# PIN Sıfırlama - E-posta Doğrulama Kurulumu

PIN sıfırlama artık e-posta adresine gönderilen 6 haneli doğrulama kodu ile çalışır.

## Gereksinimler

1. **Firebase Blaze planı** (ücretli - e-posta göndermek için)
2. **Trigger Email from Firestore** extension kurulumu
3. **Cloud Functions** deploy

## Adımlar

### 1. Firebase Blaze Planı

Firebase Console → Project Settings → Usage and billing → Upgrade to Blaze

### 2. Trigger Email Extension Kurulumu

1. [Firebase Extensions](https://console.firebase.google.com/project/mathfunapp-1460b/extensions) sayfasına gidin
2. "Trigger Email from Firestore" extension'ını kurun
3. SMTP ayarlarını yapılandırın (Gmail, SendGrid, Mailgun vb.)
   - Gmail için: Uygulama şifresi oluşturup SMTP kullanın
   - SendGrid: Ücretsiz tier ile günde 100 e-posta

### 3. Cloud Functions Deploy

```bash
cd functions
npm install
npm run build
firebase deploy --only functions
```

### 4. Firestore Kuralları

`pinResetCodes` ve `mail` koleksiyonları için güvenlik kuralları Cloud Functions tarafından yönetilir. `mail` koleksiyonu extension tarafından kullanılır.

## Akış

1. Kullanıcı "PIN Unuttum" tıklar
2. E-posta adresi gösterilir, "Kod Gönder" tıklanır
3. Cloud Function kod üretir, Firestore'a yazar, `mail` koleksiyonuna e-posta dokümanı ekler
4. Trigger Email extension e-postayı gönderir
5. Kullanıcı kodu girer, doğrular
6. Yeni PIN belirler
