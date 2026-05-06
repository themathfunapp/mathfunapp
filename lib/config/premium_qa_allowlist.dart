/// Geçici: belirli MTN oyuncu kodları test için her zaman premium sayılır.
/// Mağaza / production öncesi [kPremiumQaAllowlistEnabled] değerini `false` yapın.
const bool kPremiumQaAllowlistEnabled = true;

const Set<String> kPremiumQaUserCodes = {
  'MTN7216978380', // Metin Baran
  'MTN2632882160', // Bozkus
};

String? _dynamicToCodeString(dynamic v) {
  if (v == null) return null;
  if (v is String) return v.trim();
  return v.toString().trim();
}

bool premiumQaAllowlistedUserCode(String? code) {
  if (!kPremiumQaAllowlistEnabled) return false;
  final c = code?.trim();
  if (c == null || c.isEmpty) return false;
  return kPremiumQaUserCodes.contains(c.toUpperCase());
}

/// Firestore `users` belgesinden güvenli okuma (userCode bazen eksik / farklı tipte olabiliyor).
bool premiumQaAllowlistedFromUserDoc(Map<String, dynamic>? data) {
  if (!kPremiumQaAllowlistEnabled || data == null) return false;
  final keys = ['userCode', 'userCodeLower', 'guestId'];
  for (final k in keys) {
    if (premiumQaAllowlistedUserCode(_dynamicToCodeString(data[k]))) {
      return true;
    }
  }
  return false;
}
