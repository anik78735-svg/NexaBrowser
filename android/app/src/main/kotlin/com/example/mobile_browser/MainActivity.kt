package com.example.mobile_browser

import android.app.role.RoleManager
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.provider.Settings
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/// Backs two Flutter services:
///  - default_browser_service.dart: "am I the default browser?" / "open
///    the screen to change that" (RoleManager on Android 10+, the
///    Default apps settings screen on 7-9, PackageManager to check
///    status on every version).
///  - screenshot_blocker_service.dart: toggles FLAG_SECURE so incognito
///    tabs can't be screenshotted or screen-recorded.
class MainActivity : FlutterActivity() {
    private val defaultBrowserChannel = "nexa.browser/default_browser"
    private val screenshotChannel = "nexa.browser/screenshot"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, defaultBrowserChannel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "isDefaultBrowser" -> result.success(isDefaultBrowser())
                    "openDefaultBrowserSettings" -> result.success(openDefaultBrowserSettings())
                    else -> result.notImplemented()
                }
            }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, screenshotChannel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "setBlocked" -> {
                        val blocked = call.argument<Boolean>("blocked") ?: false
                        setScreenshotBlocked(blocked)
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun setScreenshotBlocked(blocked: Boolean) {
        if (blocked) {
            window.setFlags(WindowManager.LayoutParams.FLAG_SECURE, WindowManager.LayoutParams.FLAG_SECURE)
        } else {
            window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
        }
    }

    /// Resolves who currently handles a plain https link and compares it
    /// to our own package name. Works on every Android version, unlike
    /// RoleManager (which only exists from API 29).
    private fun isDefaultBrowser(): Boolean {
        val intent = Intent(Intent.ACTION_VIEW, Uri.parse("https://example.com"))
        val resolveInfo = packageManager.resolveActivity(intent, PackageManager.MATCH_DEFAULT_ONLY)
        return resolveInfo?.activityInfo?.packageName == packageName
    }

    /// Tries every OS mechanism for letting the user set Nexa as their
    /// default browser, in order of "most direct" to "most universal".
    /// Returns true the moment ANY screen was successfully opened —
    /// false only if every single one of them failed (which the Dart
    /// side then treats as a sign to show manual instructions, since
    /// that means this device's ROM doesn't expose any of them).
    private fun openDefaultBrowserSettings(): Boolean {
        // Android 10+ (API 29): the proper "Set Nexa as default browser?"
        // system dialog, via the Role Manager.
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            try {
                val roleManager = getSystemService(RoleManager::class.java)
                if (roleManager != null && roleManager.isRoleAvailable(RoleManager.ROLE_BROWSER)) {
                    if (!roleManager.isRoleHeld(RoleManager.ROLE_BROWSER)) {
                        startActivity(roleManager.createRequestRoleIntent(RoleManager.ROLE_BROWSER))
                        return true
                    }
                    // Already the default — still take the user somewhere
                    // useful instead of doing nothing.
                    return openAppDetailsSettings()
                }
            } catch (e: Exception) {
                // Fall through to the manual settings screens below.
            }
        }

        // Android 7–9 (API 24-28), and a fallback for 10+ ROMs whose
        // RoleManager implementation is incomplete (common on some OEM
        // skins): the system-wide "Default apps" screen.
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            try {
                startActivity(Intent(Settings.ACTION_MANAGE_DEFAULT_APPS_SETTINGS))
                return true
            } catch (e: Exception) {
                // Some OEM ROMs don't ship this screen — fall through.
            }
        }

        // Last resort for everything else: this app's own info page,
        // which on most ROMs still has an "Open by default" section.
        return openAppDetailsSettings()
    }

    private fun openAppDetailsSettings(): Boolean {
        return try {
            val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS)
            intent.data = Uri.parse("package:$packageName")
            startActivity(intent)
            true
        } catch (e: Exception) {
            false
        }
    }
}
