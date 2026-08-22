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
  /// Returns true if some OS screen was actually opened, false if
  /// nothing on this device/ROM could be reached — callers should show
  /// manual instructions in that case.
  static Future<bool> openSettings() async {
    if (Platform.isAndroid) {
      try {
        final opened = await _channel.invokeMethod<bool>('openDefaultBrowserSettings');
        if (opened == true) return true;
      } catch (_) {
        // Falls through to the intent:// URL fallback below — this
        // catches MissingPluginException too, which happens if an
        // older build of the app (installed before this native channel
        // existed) is still on the device and hasn't been fully
        // reinstalled, so the "Set" button silently did nothing.
      }

      // Belt-and-braces fallback that doesn't depend on the native
      // channel at all: ask the OS to open its own "Default apps"
      // settings screen via an explicit intent URL. Works from Android
      // 7+ on stock AOSP and most OEM skins.
      try {
        final uri = Uri.parse(
          'intent:#Intent;action=android.settings.MANAGE_DEFAULT_APPS_SETTINGS;end',
        );
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
          return true;
        }
      } catch (_) {
        // Some ROMs don't expose this screen either — the caller shows
        // manual instructions if this whole method returns false.
      }

      return false;
    }

    if (Platform.isIOS) {
      final uri = Uri.parse('app-settings:');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        return true;
      }
      return false;
    }

    return false;
  }
}
