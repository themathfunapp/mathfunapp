import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  // Static method to get the instance
  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  // Helper method to get string
  String get(String key) {
    return _localizedValues[locale.languageCode]?[key] ?? key;
  }

  // =========================
  // Getter methods
  // =========================
  String get homeTitle => get('home_title');
  String get homeSubtitle => get('home_subtitle');
  String get homeImproveSkills => get('home_improve_skills');
  String get homeLearnFun => get('home_learn_fun');
  String get startGame => get('start_game');
  String get storyMode => get('story_mode');
  String get miniGames => get('mini_games');
  String get miniGamesCount => get('mini_games_count');
  String get dailyRewards => get('daily_rewards');
  String get badges => get('badges');
  String get friends => get('friends');
  String get profile => get('profile');
  String get profileTitle => get('profile_title');

  // Profile related
  String get guestUser => get('guest_user');
  String get user => get('user');
  String get guest => get('guest');
  String get totalScore => get('total_score');
  String get coins => get('coins');
  String get characters => get('characters');
  String get statistics => get('statistics');
  String get totalGames => get('total_games');
  String get correctAnswers => get('correct_answers');
  String get streakRecord => get('streak_record');
  String get playTime => get('play_time');
  String get upcomingAchievements => get('upcoming_achievements');
  String get exitGuestMode => get('exit_guest_mode');
  String get signOut => get('sign_out');
  String get guestAccountInfo => get('guest_account_info');
  String get guestAccountDescription => get('guest_account_description');
  String get createAccount => get('create_account');
  String get convertToAccount => get('convert_to_account');
  String get convertAccountDescription => get('convert_account_description');
  String get displayName => get('display_name');
  String get email => get('email');
  String get password => get('password');
  String get confirmPassword => get('confirm_password');
  String get cancel => get('cancel');
  String get convert => get('convert');
  String get fillAllFields => get('fill_all_fields');
  String get passwordsDoNotMatch => get('passwords_do_not_match');
  String get accountCreatedSuccessfully => get('account_created_successfully');
  String get exitGuestModeDescription => get('exit_guest_mode_description');
  String get signOutDescription => get('sign_out_description');
  String get yes => get('yes');
  String get error => get('error');

  // Welcome
  String get appName => get('app_name');
  String get appMotto => get('app_motto');
  String get welcomeTitle => get('welcome_title');
  String get welcomeDescription => get('welcome_description');
  String get continueButton => get('continue_button');

  // Login
  String get signInApple => get('sign_in_apple');
  String get signInGoogle => get('sign_in_google');
  String get signInEmail => get('sign_in_email');
  String get signInLater => get('sign_in_later');
  String get appleSigninTitle => get('apple_signin_title');
  String get appleSigninDesc => get('apple_signin_desc');
  String get googleSigninTitle => get('google_signin_title');
  String get googleSigninDesc => get('google_signin_desc');
  String get welcomeSubtitle => get('welcome_subtitle');
  String get emailSignupDesc => get('email_signup_desc');

  // Guest
  String get signInGuest => get('sign_in_guest');
  String get guestSigninDesc => get('guest_signin_desc');
  String get continueAsGuest => get('continue_as_guest');

  // Privacy
  String get privacyTermsAgreement => get('privacy_terms_agreement');
  String get alreadyHaveAccount => get('already_have_account');
  String get noAccountSignup => get('no_account_signup');
  String get signUp => get('sign_up');
  String get loginError => get('login_error');
  String get skipDescription => get('skip_description');

  // =========================
  // Localization Map
  // =========================
  static const Map<String, Map<String, String>> _localizedValues = {
    // ========================= TR =========================
    'tr': {
      // Home
      'home_title': 'Matematik Macerası',
      'home_subtitle': 'Eğlenerek Öğren',
      'home_improve_skills': 'Matematik Becerilerini Geliştir!',
      'home_learn_fun': 'Matematik öğrenmek hiç bu kadar eğlenceli olmamıştı!',
      'start_game': 'Oyuna Başla! 🚀',
      'story_mode': 'Hikaye Modu',
      'mini_games': 'Mini Oyunlar',
      'mini_games_count': '10+ oyun',
      'daily_rewards': 'Günlük Ödüller',
      'badges': 'Rozetlerim',
      'friends': 'Arkadaşlar',
      'profile': 'Profil',
      'profile_title': 'Profil',

      // Profile
      'guest_user': 'Misafir Kullanıcı',
      'user': 'Kullanıcı',
      'guest': 'Misafir',
      'total_score': 'Toplam Puan',
      'coins': 'Jetonlar',
      'characters': 'Karakterler',
      'statistics': 'İstatistikler',
      'total_games': 'Toplam Oyun',
      'correct_answers': 'Doğru Cevaplar',
      'streak_record': 'Seri Rekoru',
      'play_time': 'Oyun Süresi',
      'upcoming_achievements': 'Yaklaşan Başarılar',
      'exit_guest_mode': 'Misafir Modundan Çık',
      'sign_out': 'Çıkış Yap',
      'guest_account_info': 'Misafir Hesabı Bilgisi',
      'guest_account_description': 'Misafir hesabınız geçicidir. '
          'Hesap oluşturarak verilerinizi kaydedebilirsiniz.',
      'create_account': 'Hesap Oluştur',
      'convert_to_account': 'Hesaba Dönüştür',
      'convert_account_description': 'Misafir hesabınızı kalıcı bir hesaba dönüştürün.',
      'display_name': 'Görünen Ad',
      'email': 'E-posta',
      'password': 'Şifre',
      'confirm_password': 'Şifre Tekrar',
      'cancel': 'İptal',
      'convert': 'Dönüştür',
      'fill_all_fields': 'Lütfen tüm alanları doldurun',
      'passwords_do_not_match': 'Şifreler eşleşmiyor',
      'account_created_successfully': 'Hesap başarıyla oluşturuldu!',
      'exit_guest_mode_description': 'Misafir modundan çıkmak istediğinizden emin misiniz? '
          'Geçici verileriniz silinecek.',
      'sign_out_description': 'Çıkış yapmak istediğinizden emin misiniz?',
      'yes': 'Evet',
      'error': 'Hata',

      // Welcome
      'app_name': 'Matematik Macerası',
      'app_motto': 'Eğlenerek Öğren',
      'welcome_title': 'Matematiğe Hoş Geldiniz!',
      'welcome_description':
      'Matematik becerilerinizi geliştirmek için eğlenceli bir yolculuğa çıkın. '
          'Hesabınızla giriş yaparak ilerlemenizi kaydedin ve daha fazla özelliğe erişin.',
      'continue_button': 'Devam Et',

      // Login
      'apple_signin_title': 'Apple ID ile Devam Et',
      'icloud_signin_title': 'iCloud ile Devam Et',
      'google_signin_title': 'Google ile Devam Et',
      'apple_signin_desc': 'Apple kimliğinizle kolayca giriş yapın.',
      'google_signin_desc': 'Google hesabınızla hızlıca başlayın.',
      'welcome_subtitle': 'Hesabınızla giriş yaparak öğrenme sürecinizi kaydedin.',
      'email_signup_desc': 'E-posta ile kaydolun',

      'sign_in_apple': 'Apple ile Devam Et',
      'sign_in_google': 'Google ile Devam Et',
      'sign_in_email': 'E-posta ile Kaydol',
      'sign_in_later': 'Sonra Giriş Yap',

      // Guest
      'sign_in_guest': 'Misafir Olarak Devam Et',
      'guest_signin_desc': 'Geçici hesap ile hemen başlayın',
      'continue_as_guest': 'Misafir Olarak Devam Et',

      // Additional
      'already_have_account': 'Zaten hesabınız var mı? Giriş yapın',
      'no_account_signup': 'Hesabınız yok mu? Kaydolun',
      'sign_up': 'Kaydol',
      'login_error': 'Giriş hatası',
      'skip_description': 'Demo modunda göz atın',

      // Privacy
      'privacy_terms_agreement':
      'Devam ederek, Hizmet Şartlarımızı ve Gizlilik Politikamızı kabul etmiş olursunuz.',
    },

    // ========================= EN =========================
    'en': {
      'home_title': 'Math Adventure',
      'home_subtitle': 'Learn with Fun',
      'home_improve_skills': 'Improve Math Skills!',
      'home_learn_fun': 'Learning math has never been this fun!',
      'start_game': 'Start Game! 🚀',
      'story_mode': 'Story Mode',
      'mini_games': 'Mini Games',
      'mini_games_count': '10+ games',
      'daily_rewards': 'Daily Rewards',
      'badges': 'Badges',
      'friends': 'Friends',
      'profile': 'Profile',
      'profile_title': 'Profile',

      // Profile
      'guest_user': 'Guest User',
      'user': 'User',
      'guest': 'Guest',
      'total_score': 'Total Score',
      'coins': 'Coins',
      'characters': 'Characters',
      'statistics': 'Statistics',
      'total_games': 'Total Games',
      'correct_answers': 'Correct Answers',
      'streak_record': 'Streak Record',
      'play_time': 'Play Time',
      'upcoming_achievements': 'Upcoming Achievements',
      'exit_guest_mode': 'Exit Guest Mode',
      'sign_out': 'Sign Out',
      'guest_account_info': 'Guest Account Info',
      'guest_account_description': 'Your guest account is temporary. '
          'Create an account to save your data.',
      'create_account': 'Create Account',
      'convert_to_account': 'Convert to Account',
      'convert_account_description': 'Convert your guest account to a permanent account.',
      'display_name': 'Display Name',
      'email': 'Email',
      'password': 'Password',
      'confirm_password': 'Confirm Password',
      'cancel': 'Cancel',
      'convert': 'Convert',
      'fill_all_fields': 'Please fill all fields',
      'passwords_do_not_match': 'Passwords do not match',
      'account_created_successfully': 'Account created successfully!',
      'exit_guest_mode_description': 'Are you sure you want to exit guest mode? '
          'Your temporary data will be deleted.',
      'sign_out_description': 'Are you sure you want to sign out?',
      'yes': 'Yes',
      'error': 'Error',

      'app_name': 'Math Adventure',
      'app_motto': 'Learn with Fun',
      'welcome_title': 'Welcome to Mathematics!',
      'welcome_description':
      'Embark on a fun journey to improve your math skills. '
          'Sign in to save your progress and unlock more features.',
      'continue_button': 'Continue',

      'sign_in_apple': 'Continue with Apple',
      'sign_in_google': 'Continue with Google',
      'sign_in_email': 'Sign up with Email',
      'sign_in_later': 'Sign in Later',

      // Guest
      'sign_in_guest': 'Continue as Guest',
      'guest_signin_desc': 'Start instantly with a temporary account',
      'continue_as_guest': 'Continue as Guest',

      // Additional
      'already_have_account': 'Already have an account? Sign in',
      'no_account_signup': 'No account? Sign up',
      'sign_up': 'Sign Up',
      'login_error': 'Login Error',
      'skip_description': 'Browse in demo mode',

      'privacy_terms_agreement':
      'By continuing, you agree to our Terms of Service and Privacy Policy.',
    },

    // ========================= DE =========================
    'de': {
      'home_title': 'Mathe-Abenteuer',
      'home_subtitle': 'Lernen mit Spaß',
      'home_improve_skills': 'Mathefähigkeiten verbessern!',
      'home_learn_fun': 'Mathe lernen war noch nie so spaßig!',
      'start_game': 'Spiel starten! 🚀',
      'story_mode': 'Geschichtenmodus',
      'mini_games': 'Mini-Spiele',
      'mini_games_count': '10+ Spiele',
      'daily_rewards': 'Tägliche Belohnungen',
      'badges': 'Abzeichen',
      'friends': 'Freunde',
      'profile': 'Profil',
      'profile_title': 'Profil',

      // Profile
      'guest_user': 'Gastbenutzer',
      'user': 'Benutzer',
      'guest': 'Gast',
      'total_score': 'Gesamtpunktzahl',
      'coins': 'Münzen',
      'characters': 'Charaktere',
      'statistics': 'Statistiken',
      'total_games': 'Gesamtspiele',
      'correct_answers': 'Richtige Antworten',
      'streak_record': 'Serienrekord',
      'play_time': 'Spielzeit',
      'upcoming_achievements': 'Kommende Erfolge',
      'exit_guest_mode': 'Gastmodus verlassen',
      'sign_out': 'Abmelden',
      'guest_account_info': 'Gastkontoinformationen',
      'guest_account_description': 'Ihr Gastkonto ist temporär. '
          'Erstellen Sie ein Konto, um Ihre Daten zu speichern.',
      'create_account': 'Konto erstellen',
      'convert_to_account': 'In Konto umwandeln',
      'convert_account_description': 'Wandeln Sie Ihr Gastkonto in ein permanentes Konto um.',
      'display_name': 'Anzeigename',
      'email': 'E-Mail',
      'password': 'Passwort',
      'confirm_password': 'Passwort bestätigen',
      'cancel': 'Abbrechen',
      'convert': 'Umwandeln',
      'fill_all_fields': 'Bitte füllen Sie alle Felder aus',
      'passwords_do_not_match': 'Passwörter stimmen nicht überein',
      'account_created_successfully': 'Konto erfolgreich erstellt!',
      'exit_guest_mode_description': 'Sind Sie sicher, dass Sie den Gastmodus verlassen möchten? '
          'Ihre temporären Daten werden gelöscht.',
      'sign_out_description': 'Sind Sie sicher, dass Sie sich abmelden möchten?',
      'yes': 'Ja',
      'error': 'Fehler',

      'app_name': 'Mathe-Abenteuer',
      'app_motto': 'Lernen mit Spaß',
      'welcome_title': 'Willkommen zur Mathematik!',
      'welcome_description':
      'Begib dich auf eine unterhaltsame Reise, um deine Mathefähigkeiten zu verbessern. '
          'Melde dich an, um deinen Fortschritt zu speichern.',
      'continue_button': 'Weiter',

      'sign_in_apple': 'Weiter mit Apple',
      'sign_in_google': 'Weiter mit Google',
      'sign_in_email': 'Mit E-Mail registrieren',
      'sign_in_later': 'Später anmelden',

      // Guest
      'sign_in_guest': 'Als Gast fortfahren',
      'guest_signin_desc': 'Sofort starten mit temporärem Konto',
      'continue_as_guest': 'Als Gast fortfahren',

      // Additional
      'already_have_account': 'Haben Sie bereits ein Konto? Anmelden',
      'no_account_signup': 'Kein Konto? Registrieren',
      'sign_up': 'Registrieren',
      'login_error': 'Anmeldefehler',
      'skip_description': 'Im Demo-Modus stöbern',

      'privacy_terms_agreement':
      'Durch die Fortsetzung stimmen Sie unseren Nutzungsbedingungen und der Datenschutzrichtlinie zu.',
    },
  };
}

class AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      ['tr', 'en', 'de'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
}