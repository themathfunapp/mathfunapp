import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tema Servisi
/// Seçilebilir temalar ve UI stilleri
class ThemeService extends ChangeNotifier {
  static const String _themeKey = 'selected_theme';
  
  AppTheme _currentTheme = AppTheme.classic;
  bool _isDarkMode = false;
  SharedPreferences? _prefs;

  AppTheme get currentTheme => _currentTheme;
  bool get isDarkMode => _isDarkMode;

  /// Tema verilerini al
  ThemeData get themeData => _buildThemeData();

  /// Gradient renkleri
  List<Color> get gradientColors => _currentTheme.gradientColors;

  /// Ana renk
  Color get primaryColor => _currentTheme.primaryColor;

  /// Arka plan rengi
  Color get backgroundColor => _currentTheme.backgroundColor;

  /// Yüzey rengi
  Color get surfaceColor => _currentTheme.surfaceColor;

  /// Vurgu rengi
  Color get accentColor => _currentTheme.accentColor;

  /// Servisi başlat
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    
    final themeName = _prefs?.getString(_themeKey);
    if (themeName != null) {
      _currentTheme = AppTheme.values.firstWhere(
        (t) => t.name == themeName,
        orElse: () => AppTheme.classic,
      );
    }
    
    _isDarkMode = _prefs?.getBool('dark_mode') ?? false;
    notifyListeners();
  }

  /// Tema değiştir
  Future<void> setTheme(AppTheme theme) async {
    _currentTheme = theme;
    await _prefs?.setString(_themeKey, theme.name);
    notifyListeners();
  }

  /// Karanlık modu değiştir
  Future<void> setDarkMode(bool enabled) async {
    _isDarkMode = enabled;
    await _prefs?.setBool('dark_mode', enabled);
    notifyListeners();
  }

  ThemeData _buildThemeData() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _currentTheme.primaryColor,
      brightness: _isDarkMode ? Brightness.dark : Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: _currentTheme.backgroundColor,
      fontFamily: _currentTheme.fontFamily,
      
      textTheme: TextTheme(
        displayLarge: TextStyle(
          color: _currentTheme.textColor,
          fontWeight: FontWeight.bold,
        ),
        bodyLarge: TextStyle(
          color: _currentTheme.textColor,
        ),
        bodyMedium: TextStyle(
          color: _currentTheme.textColor.withOpacity(0.8),
        ),
      ),
      
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _currentTheme.buttonColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_currentTheme.borderRadius),
          ),
        ),
      ),
      
      cardTheme: CardTheme(
        color: _currentTheme.cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_currentTheme.borderRadius),
        ),
        elevation: _currentTheme.elevation,
      ),
    );
  }
}

/// Uygulama Temaları
enum AppTheme {
  classic(
    name: 'Klasik',
    emoji: '🎨',
    primaryColor: Color(0xFF6366F1),
    backgroundColor: Color(0xFFF5F5F5),
    surfaceColor: Color(0xFFFFFFFF),
    accentColor: Color(0xFFF59E0B),
    textColor: Color(0xFF1F2937),
    buttonColor: Color(0xFF6366F1),
    cardColor: Color(0xFFFFFFFF),
    gradientColors: [Color(0xFF667eea), Color(0xFF764ba2)],
    fontFamily: null,
    borderRadius: 16,
    elevation: 2,
  ),
  
  galaxy(
    name: 'Galaksi',
    emoji: '🌟',
    primaryColor: Color(0xFF8B5CF6),
    backgroundColor: Color(0xFF0F172A),
    surfaceColor: Color(0xFF1E293B),
    accentColor: Color(0xFFFBBF24),
    textColor: Color(0xFFE2E8F0),
    buttonColor: Color(0xFF8B5CF6),
    cardColor: Color(0xFF1E293B),
    gradientColors: [Color(0xFF0F172A), Color(0xFF1E1B4B), Color(0xFF312E81)],
    fontFamily: null,
    borderRadius: 20,
    elevation: 4,
  ),
  
  nature(
    name: 'Doğa',
    emoji: '🌿',
    primaryColor: Color(0xFF10B981),
    backgroundColor: Color(0xFFECFDF5),
    surfaceColor: Color(0xFFD1FAE5),
    accentColor: Color(0xFFFBBF24),
    textColor: Color(0xFF064E3B),
    buttonColor: Color(0xFF10B981),
    cardColor: Color(0xFFD1FAE5),
    gradientColors: [Color(0xFF065F46), Color(0xFF10B981), Color(0xFF34D399)],
    fontFamily: null,
    borderRadius: 12,
    elevation: 1,
  ),
  
  fantasy(
    name: 'Fantazi',
    emoji: '🦄',
    primaryColor: Color(0xFFEC4899),
    backgroundColor: Color(0xFFFDF2F8),
    surfaceColor: Color(0xFFFCE7F3),
    accentColor: Color(0xFFA855F7),
    textColor: Color(0xFF831843),
    buttonColor: Color(0xFFEC4899),
    cardColor: Color(0xFFFCE7F3),
    gradientColors: [Color(0xFFEC4899), Color(0xFFA855F7), Color(0xFF6366F1)],
    fontFamily: null,
    borderRadius: 24,
    elevation: 3,
  ),
  
  futuristic(
    name: 'Gelecek',
    emoji: '⚡',
    primaryColor: Color(0xFF00D9FF),
    backgroundColor: Color(0xFF0A0A0A),
    surfaceColor: Color(0xFF1A1A1A),
    accentColor: Color(0xFFFF00E5),
    textColor: Color(0xFF00D9FF),
    buttonColor: Color(0xFF00D9FF),
    cardColor: Color(0xFF1A1A1A),
    gradientColors: [Color(0xFF0A0A0A), Color(0xFF1A1A2E), Color(0xFF0D0D1A)],
    fontFamily: null,
    borderRadius: 8,
    elevation: 0,
  ),
  
  fairytale(
    name: 'Masal',
    emoji: '🎭',
    primaryColor: Color(0xFFF97316),
    backgroundColor: Color(0xFFFFFBEB),
    surfaceColor: Color(0xFFFEF3C7),
    accentColor: Color(0xFFDC2626),
    textColor: Color(0xFF78350F),
    buttonColor: Color(0xFFF97316),
    cardColor: Color(0xFFFEF3C7),
    gradientColors: [Color(0xFFF97316), Color(0xFFFBBF24), Color(0xFFFDE68A)],
    fontFamily: null,
    borderRadius: 20,
    elevation: 2,
  ),
  
  ocean(
    name: 'Okyanus',
    emoji: '🌊',
    primaryColor: Color(0xFF0EA5E9),
    backgroundColor: Color(0xFFF0F9FF),
    surfaceColor: Color(0xFFE0F2FE),
    accentColor: Color(0xFF06B6D4),
    textColor: Color(0xFF0C4A6E),
    buttonColor: Color(0xFF0EA5E9),
    cardColor: Color(0xFFE0F2FE),
    gradientColors: [Color(0xFF0369A1), Color(0xFF0EA5E9), Color(0xFF38BDF8)],
    fontFamily: null,
    borderRadius: 16,
    elevation: 2,
  ),
  
  sunset(
    name: 'Gün Batımı',
    emoji: '🌅',
    primaryColor: Color(0xFFEF4444),
    backgroundColor: Color(0xFFFEF2F2),
    surfaceColor: Color(0xFFFEE2E2),
    accentColor: Color(0xFFF97316),
    textColor: Color(0xFF7F1D1D),
    buttonColor: Color(0xFFEF4444),
    cardColor: Color(0xFFFEE2E2),
    gradientColors: [Color(0xFFDC2626), Color(0xFFF97316), Color(0xFFFBBF24)],
    fontFamily: null,
    borderRadius: 14,
    elevation: 2,
  );

  final String name;
  final String emoji;
  final Color primaryColor;
  final Color backgroundColor;
  final Color surfaceColor;
  final Color accentColor;
  final Color textColor;
  final Color buttonColor;
  final Color cardColor;
  final List<Color> gradientColors;
  final String? fontFamily;
  final double borderRadius;
  final double elevation;

  const AppTheme({
    required this.name,
    required this.emoji,
    required this.primaryColor,
    required this.backgroundColor,
    required this.surfaceColor,
    required this.accentColor,
    required this.textColor,
    required this.buttonColor,
    required this.cardColor,
    required this.gradientColors,
    required this.fontFamily,
    required this.borderRadius,
    required this.elevation,
  });
}

/// Tema Seçici Widget'ı
class ThemeSelector extends StatelessWidget {
  final ThemeService themeService;

  const ThemeSelector({super.key, required this.themeService});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: AppTheme.values.length,
      itemBuilder: (context, index) {
        final theme = AppTheme.values[index];
        final isSelected = themeService.currentTheme == theme;

        return GestureDetector(
          onTap: () => themeService.setTheme(theme),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: theme.gradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? Colors.white : Colors.transparent,
                width: 3,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: theme.primaryColor.withOpacity(0.5),
                        blurRadius: 12,
                      ),
                    ]
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(theme.emoji, style: const TextStyle(fontSize: 28)),
                const SizedBox(height: 4),
                Text(
                  theme.name,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                if (isSelected)
                  const Icon(Icons.check_circle, color: Colors.white, size: 16),
              ],
            ),
          ),
        );
      },
    );
  }
}

