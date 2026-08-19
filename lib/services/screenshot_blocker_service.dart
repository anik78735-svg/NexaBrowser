import 'dart:io';
import 'package:flutter/services.dart';

/// Blocks/unblocks screenshots and screen recording for the whole app
/// window (Android's FLAG_SECURE — there's no per-tab equivalent, so
/// this is toggled on whenever the active tab is incognito and off the
/// moment it isn't). See MainActivity.kt for the native side.
class ScreenshotBlockerService {
  ScreenshotBlockerService._();

  static const MethodChannel _channel = MethodChannel('nexa.browser/screenshot');
  static bool _lastState = false;

  /// Call whenever the active tab changes. No-ops if the requested state
  /// already matches, so switching between two incognito tabs (or two
  /// normal tabs) doesn't spam the platform channel.
  static Future<void> setBlocked(bool blocked) async {
    if (!Platform.isAndroid) return;
    if (blocked == _lastState) return;
    _lastState = blocked;
    try {
      await _channel.invokeMethod('setBlocked', {'blocked': blocked});
    } catch (_) {
      // Best-effort — a failure here shouldn't crash tab switching.
    }
  }
}
