import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

class AppUser {
  final String uid;
  final String? email;
  final String? displayName;
  final String? photoURL;

  // Dil
  final String? selectedLanguage;

  // Zaman bilgileri
  final DateTime? createdAt;
  final DateTime? lastSignInTime;

  // Auth bilgileri
  final bool? emailVerified;

  // 🔥 GUEST (MİSAFİR) KULLANICI ALANLARI
  final bool isGuest;
  final String? guestId;

  // 🎮 OYUNCU KODU - Her kullanıcı için benzersiz MTN ID 
  final String? userCode;

  // 👑 PREMİUM ÜYELİK
  final bool isPremium;
  final DateTime? premiumExpiresAt;

  AppUser({
    required this.uid,
    this.email,
    this.displayName,
    this.photoURL,
    this.selectedLanguage,
    this.createdAt,
    this.lastSignInTime,
    this.emailVerified,
    this.isGuest = false,
    this.guestId,
    this.userCode,
    this.isPremium = false,
    this.premiumExpiresAt,
  });

  // =========================
  // Firebase User → AppUser
  // =========================
  factory AppUser.fromFirebaseUser(firebase_auth.User user, {String? existingUserCode}) {
    return AppUser(
      uid: user.uid,
      email: user.email,
      displayName: user.displayName,
      photoURL: user.photoURL,
      selectedLanguage: 'tr',
      createdAt: user.metadata.creationTime,
      lastSignInTime: user.metadata.lastSignInTime,
      emailVerified: user.emailVerified,
      isGuest: false,
      guestId: null,
      userCode: existingUserCode ?? _generateUserCode(),
    );
  }

  // =========================
  // Firestore Map → AppUser
  // =========================
  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      uid: map['uid'] ?? '',
      email: map['email'],
      displayName: map['displayName'],
      photoURL: map['photoURL'],
      selectedLanguage: map['selectedLanguage'] ?? 'tr',
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : null,
      lastSignInTime: map['lastSignInTime'] != null
          ? DateTime.parse(map['lastSignInTime'])
          : null,
      emailVerified: map['emailVerified'] ?? false,
      isGuest: map['isGuest'] ?? false,
      guestId: map['guestId'],
      userCode: map['userCode'],
      isPremium: map['isPremium'] ?? false,
      premiumExpiresAt: map['premiumExpiresAt'] != null
          ? DateTime.parse(map['premiumExpiresAt'])
          : null,
    );
  }

  // =========================
  // AppUser → Firestore Map
  // =========================
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoURL': photoURL,
      'selectedLanguage': selectedLanguage ?? 'tr',
      'createdAt': createdAt?.toIso8601String(),
      'lastSignInTime': lastSignInTime?.toIso8601String(),
      'emailVerified': emailVerified ?? false,
      'isGuest': isGuest,
      'guestId': guestId,
      'userCode': userCode,
      'userCodeLower': userCode?.toLowerCase(),
      'isPremium': isPremium,
      'premiumExpiresAt': premiumExpiresAt?.toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    };
  }

  // =========================
  // CopyWith
  // =========================
  AppUser copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoURL,
    String? selectedLanguage,
    DateTime? createdAt,
    DateTime? lastSignInTime,
    bool? emailVerified,
    bool? isGuest,
    String? guestId,
    String? userCode,
    bool? isPremium,
    DateTime? premiumExpiresAt,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoURL: photoURL ?? this.photoURL,
      selectedLanguage: selectedLanguage ?? this.selectedLanguage,
      createdAt: createdAt ?? this.createdAt,
      lastSignInTime: lastSignInTime ?? this.lastSignInTime,
      emailVerified: emailVerified ?? this.emailVerified,
      isGuest: isGuest ?? this.isGuest,
      guestId: guestId ?? this.guestId,
      userCode: userCode ?? this.userCode,
      isPremium: isPremium ?? this.isPremium,
      premiumExpiresAt: premiumExpiresAt ?? this.premiumExpiresAt,
    );
  }

  // =========================
  // 🔥 GUEST USER OLUŞTUR
  // =========================
  factory AppUser.guest({
    String languageCode = 'tr',
  }) {
    final code = _generateUserCode();
    return AppUser(
      uid: '',
      selectedLanguage: languageCode,
      isGuest: true,
      guestId: code,
      userCode: code,
      createdAt: DateTime.now(),
      emailVerified: false,
    );
  }

  static const String playerCodePrefix = 'MTN';
  /// MTN sonrası rakam sayısı (ilk rakam 1–9, diğerleri 0–9).
  static const int playerCodeSuffixLength = 10;
  static int get playerCodeTotalLength =>
      playerCodePrefix.length + playerCodeSuffixLength;

  /// Arkadaş araması: sorgu MTN oyuncu kodu gibi mi?
  static bool queryLooksLikePlayerCode(String query) {
    return query.trim().toUpperCase().startsWith(playerCodePrefix);
  }

  // MTN + 10 haneli ID (ilk rakam 1–9)
  static String _generateUserCode() {
    final random = Random();
    final first = random.nextInt(9) + 1;
    final rest = List.generate(playerCodeSuffixLength - 1, (_) => random.nextInt(10))
        .join();
    return '$playerCodePrefix$first$rest';
  }

  /// Yeni oyuncu kodu (kayıt / e-posta girişi vb.).
  static String generatePlayerUserCode() => _generateUserCode();

  /// Kayıtlı kullanıcı: MTN + 10 rakam; ilk rakam 1–9.
  static bool isValidAssignedUserCode(String? code) {
    if (code == null || code.length != playerCodeTotalLength) return false;
    final u = code.toUpperCase();
    if (!u.startsWith(playerCodePrefix)) return false;
    final suffix = u.substring(playerCodePrefix.length);
    return RegExp(r'^[1-9]\d{9}$').hasMatch(suffix);
  }

  /// Misafir ID (MTN + en az 10 rakam) → kayıtlı kod (ilk 10 rakam geçerliyse).
  static String? playerCodeDerivedFromGuestId(String? guestId) {
    if (guestId == null) return null;
    final u = guestId.trim();
    if (u.length < playerCodeTotalLength) return null;
    final up = u.toUpperCase();
    if (!up.startsWith(playerCodePrefix)) {
      return null;
    }
    final rest = u.substring(playerCodePrefix.length);
    if (!RegExp(r'^\d+$').hasMatch(rest)) return null;
    if (rest.length < playerCodeSuffixLength) return null;
    final ten = rest.substring(0, playerCodeSuffixLength);
    if (!RegExp(r'^[1-9]\d{9}$').hasMatch(ten)) return null;
    return '$playerCodePrefix$ten';
  }

  /// Senkron yedek: geçerli kod yoksa rastgele üretir (çakışma kontrolü yok).
  static String resolveUserCodeForRegistered({String? existing}) {
    if (isValidAssignedUserCode(existing)) return existing!;
    return _generateUserCode();
  }

  // =========================
  // Getter'lar
  // =========================
  bool get isEmpty => uid.isEmpty && !isGuest;
  bool get isNotEmpty => uid.isNotEmpty || isGuest;

  bool get hasSelectedLanguage =>
      selectedLanguage != null && selectedLanguage!.isNotEmpty;

  // Kullanıcı adı
  String get username {
    if (isGuest && guestId != null) {
      return guestId!;
    }
    if (displayName != null && displayName!.isNotEmpty) {
      return displayName!;
    }
    if (email != null && email!.isNotEmpty) {
      return email!.split('@').first;
    }
    return 'Kullanıcı';
  }

  // Oyuncu kodu (MTN ID) — geçersiz/placeholder gösterme
  String get playerCode => userCode ?? guestId ?? '';

  // Dil adı
  String getLanguageName() {
    switch (selectedLanguage) {
      case 'tr':
        return 'Türkçe';
      case 'en':
        return 'English';
      case 'de':
        return 'Deutsch';
      default:
        return 'Türkçe';
    }
  }

  // Bayrak
  String get flagEmoji {
    switch (selectedLanguage) {
      case 'tr':
        return '🇹🇷';
      case 'en':
        return '🇺🇸';
      case 'de':
        return '🇩🇪';
      default:
        return '🇹🇷';
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is AppUser &&
              runtimeType == other.runtimeType &&
              uid == other.uid &&
              guestId == other.guestId;

  @override
  int get hashCode => Object.hash(uid, guestId);

  @override
  String toString() {
    if (isGuest) {
      return 'GuestUser(guestId: $guestId, language: $selectedLanguage)';
    }
    return 'AppUser(uid: $uid, email: $email, displayName: $displayName)';
  }
}
