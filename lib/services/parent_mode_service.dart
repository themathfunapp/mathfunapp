import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Ebeveyn modu: ana menüde yalnızca aile odaklı girişler gösterilir.
class ParentModeService extends ChangeNotifier {
  static const _prefKey = 'parent_mode_enabled_v1';

  bool _isParentMode = false;
  bool _loaded = false;

  bool get isParentMode => _isParentMode;
  bool get isLoaded => _loaded;

  ParentModeService() {
    _load();
  }

  Future<void> _load() async {
    try {
      final p = await SharedPreferences.getInstance();
      _isParentMode = p.getBool(_prefKey) ?? false;
    } catch (e) {
      debugPrint('ParentModeService load: $e');
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> setParentMode(bool value) async {
    _isParentMode = value;
    notifyListeners();
    try {
      final p = await SharedPreferences.getInstance();
      await p.setBool(_prefKey, value);
    } catch (e) {
      debugPrint('ParentModeService save: $e');
    }
  }
}
