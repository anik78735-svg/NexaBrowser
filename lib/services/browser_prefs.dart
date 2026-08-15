import 'package:shared_preferences/shared_preferences.dart';

class BrowserPrefs {
  //---------------------------------------------------------------------
  // Search engine
  //---------------------------------------------------------------------
  static const Map<String, String> searchEngineUrls = {
    'google': 'https://www.google.com/search?q=',
    'bing': 'https://www.bing.com/search?q=',
    'duckduckgo': 'https://duckduckgo.com/?q=',
    'yahoo': 'https://search.yahoo.com/search?p=',
  };

  static const Map<String, String> searchEngineLabels = {
    'google': 'Google',
    'bing': 'Bing',
    'duckduckgo': 'DuckDuckGo',
    'yahoo': 'Yahoo',
  };

  static Future<String> getSearchEngine() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('search_engine') ?? 'google';
  }

  static Future<void> setSearchEngine(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('search_engine', key);
  }

  //---------------------------------------------------------------------
  // Address bar position (saved now; actually repositioning the toolbar
  // needs a change inside nexa_toolbar.dart / browser_home.dart).
  //---------------------------------------------------------------------
  static Future<bool> getAddressBarTop() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('address_bar_top') ?? true;
  }

  static Future<void> setAddressBarTop(bool top) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('address_bar_top', top);
  }

  //---------------------------------------------------------------------
  // Accessibility: page text size, applied as the WebView's textZoom.
  //---------------------------------------------------------------------
  static Future<int> getTextZoom() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('text_zoom') ?? 100;
  }

  static Future<void> setTextZoom(int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('text_zoom', value);
  }

  //---------------------------------------------------------------------
  // Site settings: JavaScript, Camera, Microphone, Location.
  //---------------------------------------------------------------------
  static Future<bool> getJsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('site_js_enabled') ?? true;
  }

  static Future<void> setJsEnabled(bool v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('site_js_enabled', v);
  }

  static Future<bool> getCameraAllowed() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('site_camera_enabled') ?? false;
  }

  static Future<void> setCameraAllowed(bool v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('site_camera_enabled', v);
  }

  static Future<bool> getMicAllowed() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('site_mic_enabled') ?? false;
  }

  static Future<void> setMicAllowed(bool v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('site_mic_enabled', v);
  }

  static Future<bool> getLocationAllowed() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('site_location_enabled') ?? false;
  }

  static Future<void> setLocationAllowed(bool v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('site_location_enabled', v);
  }

  //---------------------------------------------------------------------
  // Ad block flag (also used by browser_home.dart already).
  //---------------------------------------------------------------------
  static Future<bool> getAdBlockEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('ad_block_enabled') ?? true;
  }

  //---------------------------------------------------------------------
  // Tabs
  //---------------------------------------------------------------------
  static Future<bool> getWarnBeforeCloseAll() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('tabs_warn_close_all') ?? true;
  }

  static Future<void> setWarnBeforeCloseAll(bool v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('tabs_warn_close_all', v);
  }

  static Future<bool> getShowTabCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('tabs_show_count') ?? true;
  }

  static Future<void> setShowTabCount(bool v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('tabs_show_count', v);
  }

  //---------------------------------------------------------------------
  // Notifications (in-app toggle; OS-level permission is separate).
  //---------------------------------------------------------------------
  static Future<bool> getNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('notifications_enabled') ?? true;
  }

  static Future<void> setNotificationsEnabled(bool v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', v);
  }

  //---------------------------------------------------------------------
  // Language (stored only for now — full UI translation needs Flutter's
  // localization/.arb setup, which is a separate task).
  //---------------------------------------------------------------------
  static Future<String> getLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('app_language') ?? 'en';
  }

  static Future<void> setLanguage(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_language', code);
  }

  // Add these two methods inside the BrowserPrefs class in browser_prefs.dart
  // (anywhere among the other static methods is fine).

  //---------------------------------------------------------------------
  // Whether new tabs should open in desktop mode by default.
  // Used by Settings > Basics > "Desktop site (default)" and by
  // browser_home.dart's addNewTab().
  //---------------------------------------------------------------------
  static Future<bool> getDefaultDesktopMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('default_desktop_mode') ?? false;
  }

  static Future<void> setDefaultDesktopMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('default_desktop_mode', value);
  }
}