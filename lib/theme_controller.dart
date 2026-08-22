import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Nexa is dark-only now (see the Appearance screen — the Light/System
/// picker was removed on request, along with defaulting to Light).
/// This still goes through SharedPreferences so a device that was
/// previously saved as "light" or "system" from an older build also
/// comes back up in Dark instead of silently reverting to a light look.
class ThemeController {
  static final ValueNotifier<ThemeMode> themeMode = ValueNotifier(ThemeMode.dark);

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    // Always dark — but still write it below so a fresh install and an
    // upgraded one converge on the same stored value.
    themeMode.value = ThemeMode.dark;
    await prefs.setString('theme_mode', 'dark');
  }

  /// Kept for API compatibility with anything still calling it, but
  /// Nexa no longer offers a way to leave Dark mode.
  static Future<void> setThemeMode(ThemeMode mode) async {
    themeMode.value = ThemeMode.dark;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_mode', 'dark');
  }
}