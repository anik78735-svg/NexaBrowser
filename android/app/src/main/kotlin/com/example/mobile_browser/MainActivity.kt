package com.example.mobile_browser

import android.app.role.RoleManager
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/// Backs lib/services/default_browser_service.dart: lets Flutter ask
/// "am I the default browser?" and "open the screen to change that",
/// using the APIs Android actually exposes for this (RoleManager on
/// Android 10+, the Default apps settings screen on 7-9, PackageManager
/// to check the current status on every version).
class MainActivity : FlutterActivity() {
    private val channelName = "nexa.browser/default_browser"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "isDefaultBrowser" -> result.success(isDefaultBrowser())
                    "openDefaultBrowserSettings" -> {
                        openDefaultBrowserSettings()
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
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

    private fun openDefaultBrowserSettings() {
        // Android 10+ (API 29): the proper "Set Nexa as default browser?"
        // system dialog, via the Role Manager.
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val roleManager = getSystemService(RoleManager::class.java)
            if (roleManager != null && roleManager.isRoleAvailable(RoleManager.ROLE_BROWSER)) {
                if (!roleManager.isRoleHeld(RoleManager.ROLE_BROWSER)) {
                    try {
                        startActivity(roleManager.createRequestRoleIntent(RoleManager.ROLE_BROWSER))
                        return
                    } catch (e: Exception) {
                        // Fall through to the manual settings screens below.
                    }
                } else {
                    // Already the default — still take the user somewhere
                    // useful instead of doing nothing.
                    openAppDetailsSettings()
                    return
                }
            }
        }

        // Android 7–9 (API 24-28): the system-wide "Default apps" screen,
        // where the user taps "Browser app" and picks Nexa themselves.
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            try {
                startActivity(Intent(Settings.ACTION_MANAGE_DEFAULT_APPS_SETTINGS))
                return
            } catch (e: Exception) {
                // Some OEM ROMs don't ship this screen — fall through.
            }
        }

        // Last resort for everything else: this app's own info page,
        // which on most ROMs still has an "Open by default" section.
        openAppDetailsSettings()
    }

    private fun openAppDetailsSettings() {
        val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS)
        intent.data = Uri.parse("package:$packageName")
        startActivity(intent)
    }
}
