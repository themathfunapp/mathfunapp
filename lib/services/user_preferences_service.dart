import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_user.dart';

class UserPreferencesService {
  static const String _languageKey = 'user_language';
  static const String _userIdKey = 'current_user_id';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // LOCAL STORAGE - App başlangıcı için
  Future<String?> getSavedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_languageKey);
  }

  Future<void> saveLanguageLocally(String languageCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, languageCode);
  }

  Future<void> saveUserId(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userIdKey, userId);
  }

  Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userIdKey);
  }

  // FIREBASE - Kullanıcı veritabanı
  Future<void> saveLanguageToFirebase(String userId, String languageCode) async {
    try {
      await _firestore.collection('users').doc(userId).set(
        {
          'selectedLanguage': languageCode,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      // Local'e de kaydet
      await saveLanguageLocally(languageCode);
    } catch (e) {
      print('Firebase dil kaydetme hatası: $e');
      // Sadece local'e kaydet
      await saveLanguageLocally(languageCode);
    }
  }

  Future<String?> getLanguageFromFirebase(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        return doc.data()?['selectedLanguage'] as String?;
      }
    } catch (e) {
      print('Firebase dil okuma hatası: $e');
    }
    return null;
  }

  Future<String> getLanguageForUser(String userId) async {
    // Önce Firebase'den dene
    final firebaseLang = await getLanguageFromFirebase(userId);
    if (firebaseLang != null) {
      await saveLanguageLocally(firebaseLang);
      return firebaseLang;
    }

    // Sonra local'den dene
    final localLang = await getSavedLanguage();
    return localLang ?? 'tr'; // Default Türkçe
  }
}