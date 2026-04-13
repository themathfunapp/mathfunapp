# Güvenlik ve dağıtım (kaynak / tersine mühendislik)

İstemci uygulaması **asla tam gizlenemez**; amaç sırları korumak, analizi zorlaştırmak ve suistimali azaltmaktır.

## 1. Dart şifrelemesi (obfuscation) — zorunlu sayılır (store AAB/APK)

Yayın derlemelerinde Flutter’ın obfuscation özelliğini kullanın. İsimler ve akış okunabilirliği azalır; **stack trace** için sembol dosyaları ayrı üretilir.

```bash
# Proje kökünden (Linux/macOS/Git Bash)
flutter build appbundle --release --obfuscate --split-debug-info=./symbols/app_bundle

# veya APK
flutter build apk --release --obfuscate --split-debug-info=./symbols/apk
```

**Önemli:** `symbols/` içeriğini **repoya eklemeyin**. Crash raporlarını (Firebase Crashlytics, Sentry vb.) okuyabilmek için bu klasörü **güvenli bir yerde** (şifreli yedek, CI artifact, şirket içi depolama) saklayın; sızıntıda obfuscation anlamını yitirir.

Windows’ta hazır betik: `scripts/build_release_appbundle.ps1`, `scripts/build_release_apk.ps1`.

## 2. iOS (Mac’te derleme)

```bash
flutter build ipa --release --obfuscate --split-debug-info=./symbols/ios
```

Aynı sembol yedekleme kuralı geçerli.

## 3. Repoda asla tutulmaması gerekenler

| Öğe | Neden |
|------|--------|
| `android/key.properties`, `*.jks` | İmza çalınması = sahte güncelleme |
| Google Play **service account** JSON | API / IAP suistimali |
| `--split-debug-info` çıktıları | Obfuscation’ı geri açar |
| Üçüncü parti **API secret**’ları | İstemciden çıkarılabilir |

`google-services.json` istemcide bulunur; bu normaldir. **Asıl güvenlik** Firestore kuralları, Cloud Functions ve sunucu tarafı doğrulamadadır.

## 4. İş mantığı ve premium

- **Premium / ödeme doğrulaması** mümkünse Play Developer API + backend veya Cloud Functions ile sunucuda doğrulanmalı; yalnızca istemci güvenilmez.
- Hassas iş kuralları (oranlar, hile önleme) mümkünse sunucu veya kurallarda.

## 5. Android ek sıkılaştırma

`android/gradle.properties` içinde `android.enableR8.fullMode=true` açık: R8 daha agresif küçültme/şaşırtma (nadiren üçüncü parti kütüphanede ek ProGuard kuralı gerekebilir).

`android/app/build.gradle` içinde release için zaten `minifyEnabled` / `shrinkResources` kullanılıyor.

## 6. Mağaza / cihaz bütünlüğü (isteğe bağlı, ileri seviye)

- **Google Play Integrity**: root / yeniden imzalanmış APK / emülatör tespiti; kaynak gizlemez, suistimali azaltır.
- **Apple App Attest**: Benzer amaç.

## 7. Hukuk ve süreç

- Lisans / telif metni, mağaza ihlal bildirimleri.
- Ekip içi: sembol paketlerine erişim sınırlı olsun.

---

Özet: **Obfuscation + sembolleri güvenli saklama + sırları istemciden çıkarma + sunucu doğrulama** pratikte yapılabilecek ana pakettir.
