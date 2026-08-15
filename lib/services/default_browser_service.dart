import 'dart:io';

import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

/// Talks to the native side (see MainActivity.kt) to check whether Nexa
/// is the phone's default browser, and to open the right OS screen for
/// the user to change it.
///
/// Android exposes this properly (RoleManager / "Default apps" settings);
/// iOS only lets an app deep-link into its own Settings page, where the
/// user can find "Default Browser App" themselves — Apple doesn't allow
/// querying or pre-selecting it programmatically.
class DefaultBrowserService {
  DefaultBrowserService._();

  static const MethodChannel _channel =
      MethodChannel('nexa.browser/default_browser');

  /// Returns true if Nexa is currently the OS default for opening links.
  /// Always false on platforms where this can't be determined (iOS).
  static Future<bool> isDefault() async {
    if (!Platform.isAndroid) return false;
    try {
      final result = await _channel.invokeMethod<bool>('isDefaultBrowser');
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Opens the OS flow to set Nexa as the default browser.
  /// Android: the "Set as default" role-request dialog (or the Default
  /// apps settings screen on older versions).
  /// iOS: the app's own page inside the Settings app.
  static Future<void> openSettings() async {
    if (Platform.isAndroid) {
      try {
        await _channel.invokeMethod('openDefaultBrowserSettings');
      } catch (_) {
        // Ignore — the settings tile still shows a manual fallback hint.
      }
      return;
    }

    if (Platform.isIOS) {
      final uri = Uri.parse('app-settings:');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    }
  }
}
