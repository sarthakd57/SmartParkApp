import 'package:shared_preferences/shared_preferences.dart';

class ConfigService {
  static const String _baseUrlKey = 'api_base_url';
  static const String _defaultBaseUrl = 'http://4.145.90.51:5000';

  static late SharedPreferences _prefs;

  // Initialize SharedPreferences
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Get the base URL
  static String getBaseUrl() {
    final url = _prefs.getString(_baseUrlKey);
    return (url != null && url.isNotEmpty) ? url : _defaultBaseUrl;
  }

  // Set the base URL
  static Future<void> setBaseUrl(String baseUrl) async {
    await _prefs.setString(_baseUrlKey, baseUrl);
  }

  // Reset to default URL
  static Future<void> resetToDefault() async {
    await _prefs.remove(_baseUrlKey);
  }

  // Get the saved URL with validation
  static String getSavedUrl() {
    final url = _prefs.getString(_baseUrlKey);
    if (url == null || url.isEmpty) {
      return _defaultBaseUrl;
    }
    return url;
  }
}
