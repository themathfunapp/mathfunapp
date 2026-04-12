# Legal text templates (draft only — not legal advice)

**English:** These are starting outlines for your lawyer or DPO to adapt. They are **not** ready-to-publish legal documents. Replace all `«…»` placeholders and remove sections that do not apply.

---

## A. Privacy policy (Gizlilik Politikası) — Turkish outline

**Başlık:** «Uygulama Adı» Gizlilik Politikası  
**Son güncelleme:** «Tarih»  
**Veri sorumlusu:** «Şirket / Kişi adı», «Adres», «E-posta»

1. **Amaç:** Bu uygulamanın hangi kişisel verileri hangi amaçlarla işlediği.  
2. **Toplanan veriler (örnekler — uygulamanıza göre silin veya ekleyin):**  
   - Hesap: e-posta, görünen ad, profil fotoğrafı (varsa), dil tercihi.  
   - Misafir / çocuk profili: takma ad, oyun ilerlemesi, istatistikler.  
   - Ebeveyn paneli: PIN veya biyometri ile korunan yerel ayarlar; uzaktan hatırlatma / düello ile ilişkili tanımlayıcılar.  
   - Firebase (Auth, Firestore, Cloud Functions, FCM): kimlik doğrulama ve senkronizasyon, bildirim token’ı.  
   - Reklamlar (AdMob): reklam kimliği, cihaz bilgisi; GDPR/EEA için UMP ile rıza.  
   - Ödeme: Google Play / App Store — ödeme ayrıntıları genelde mağaza tarafında kalır; makbuz / abonelik durumu.  
   - Analytics (kullanıyorsanız): hangi araç, hangi olaylar.  
3. **Hukuki sebepler (KVKK):** açık rıza, sözleşmenin ifası, meşru menfaat, hukuki yükümlülük (avukatınız seçsin).  
4. **Saklama süresi:** hesap silindiğinde / süre dolduğunda ne olur.  
5. **Üçüncü taraflar:** Google Firebase, Google Ads, Apple/Google ödeme, barındırma.  
6. **Haklar:** erişim, düzeltme, silme, itiraz, veri taşınabilirliği (KVKK m. 11 ve ilgili düzenlemeler).  
7. **Çocuklar:** yaş sınırı, ebeveyn onayı, hangi verilerin çocuktan **toplanmadığı** veya ebeveyn üzerinden yönetildiği.  
8. **Uluslararası aktarım:** Firebase bölgesi / ABD vb. ve Standard Sözleşme Maddeleri veya uygun önlemler.  
9. **İletişim:** KVKK başvuru kanalı.

**Mağaza:** Play Console ve (ileride) App Store Connect’te bu metnin yayınlandığı **HTTPS URL**’sini girin.

---

## B. Terms of use (Kullanım Koşulları) — Turkish outline

1. Taraflar ve kabul.  
2. Lisans (kişisel, devredilemez kullanım).  
3. Hesap, misafir kullanım, ebeveyn gözetimi.  
4. Premium / abonelik: otomatik yenileme, iptal (mağaza kurallarına uyumlu metin).  
5. Kullanıcı içeriği ve davranış kuralları.  
6. Hizmet değişikliği / sonlandırma.  
7. Sorumluluk reddi / sorumluluk sınırı (hukuken geçerli çerçevede).  
8. Uygulanacak hukuk ve uyuşmazlık çözümü.

---

## C. Short English notice (for store description or footer)

«AppName» collects account and gameplay data as described in our Privacy Policy at «URL». Ads use Google’s ad services where applicable; you can adjust choices in your device or in-app settings when available. Parents: please review the Privacy Policy before your child uses the app.

---

## D. Checklist before publishing

- [ ] Replace every placeholder; remove unused data types.  
- [ ] Privacy URL is live **HTTPS** and matches in-app links.  
- [ ] Age rating and “Designed for Families” / children’s policies on Google Play match your data practices.  
- [ ] IAP / subscription disclosure text matches actual behavior.  
- [ ] Contact email in the policy is monitored.
