# Android release checklist (Google Play)

Use this before uploading an AAB/APK. iOS / App Store steps are intentionally omitted here.

## 1. Signing (upload key)

1. Create an upload keystore (once), e.g.  
   `keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload`
2. Place `upload-keystore.jks` under `android/` (or another path you prefer).
3. Copy `android/key.properties.example` to `android/key.properties` and fill in passwords, alias, and `storeFile` (paths in `key.properties` are resolved relative to `android/app/` — e.g. `../upload-keystore.jks` for a file in `android/`).
4. `android/key.properties` and `*.jks` must **not** be committed (see `android/.gitignore`).

Release builds use `signingConfigs.release` when `key.properties` exists; otherwise Gradle falls back to the debug keystore (fine for local tests only — **not** for Play uploads).

## 2. Version numbers

- Canonical version: `pubspec.yaml` → `version: x.y.z+build` (`+build` = Android `versionCode`).
- `android/app/build.gradle` uses `flutter.versionCode` / `flutter.versionName` from the Flutter Gradle plugin (aligned with `pubspec.yaml`).
- Bump both before each store submission when required by Play policy or your release process.

## 3. Firebase (production)

- Deploy Firestore rules and indexes to the **production** project (`firebase deploy --only firestore`).
- Confirm `google-services.json` in `android/app/` matches the production Firebase app.
- See `docs/FIRESTORE_AND_FCM.md` for FCM and data paths.

## 4. Ads (AdMob) and consent (UMP)

- Production ad unit IDs live in `lib/services/ad_service.dart`. For local testing with Google test units, build with:  
  `--dart-define=USE_TEST_ADS=true`
- User Messaging Platform (UMP) runs before `MobileAds.instance.initialize()`; `tagForUnderAgeOfConsent` is set for a child-directed posture — have legal/product confirm this matches your store age rating and actual audience.
- To force EEA-like consent UI in **debug** builds:  
  `flutter run --dart-define=UMP_DEBUG_EEA=true`
- Reklam gizliliği: Ayarlar ekranında **Reklam gizliliği seçenekleri** satırı `AdService.showPrivacyOptionsFormIfAvailable()` çağırır (mobil; web’de yok).

## 5. In-app purchases (Premium)

- Client-side purchase flow exists; **store-compliant** verification is typically done with Play Developer API (backend or Cloud Functions). Plan this before treating premium as fully trusted server-side.

## 6. Legal URLs on the store

- Host a **privacy policy** (and terms if you use them) at a stable HTTPS URL; paste the URL in Play Console (and inside the app where required).
- Uygulama içi tarayıcı açılışı: `lib/config/legal_urls.dart` — derlemede tanımlayın (HTTPS önerilir):

```bash
flutter build appbundle --release \
  --dart-define=PRIVACY_POLICY_URL=https://example.com/gizlilik \
  --dart-define=TERMS_OF_USE_URL=https://example.com/kosullar
```

URL verilmezse aynı ekranlarda uygulama içi özet metin (`privacy_content` / `terms_content`) gösterilir.

- Draft outlines: `docs/LEGAL_TEMPLATES.md` — replace placeholders, have counsel review (especially KVKK / children’s data).

## 7. Smoke tests (non-exhaustive)

- Guest vs signed-in user; parent gate / parent panel; premium vs ads; offline start; friend duel invite; notification permission; daily challenge with ads (non-premium).

## 8. Build commands

**Önerilen (obfuscation + sembol ayrımı — mağaza için):**

```bash
flutter build appbundle --release --obfuscate --split-debug-info=./symbols/app_bundle
```

Windows: `.\scripts\build_release_appbundle.ps1` (isteğe bağlı `-PrivacyUrl` / `-TermsUrl`).

`symbols/` **repoya eklenmez** (`.gitignore`); crash analizi için güvenli yerde yedekleyin. Ayrıntı: `docs/SECURITY_RELEASE.md`.

Basit derleme (obfuscation olmadan):

```bash
flutter build appbundle --release
# or
flutter build apk --release
```

After adding `key.properties`, confirm the release artifact is signed with your upload certificate (Play Console or `jarsigner` / `apksigner` verification).
