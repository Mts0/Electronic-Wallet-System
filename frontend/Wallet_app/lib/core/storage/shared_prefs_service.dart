import 'package:shared_preferences/shared_preferences.dart';

class SharedPrefsService {
  const SharedPrefsService(this._prefs);

  final SharedPreferences _prefs;

  Future<bool> setBool(String key, bool value) async {
    return _prefs.setBool(key, value);
  }

  bool? getBool(String key) {
    return _prefs.getBool(key);
  }

  Future<bool> setString(String key, String value) async {
    return _prefs.setString(key, value);
  }

  String? getString(String key) {
    return _prefs.getString(key);
  }

  Future<bool> remove(String key) async {
    return _prefs.remove(key);
  }
}