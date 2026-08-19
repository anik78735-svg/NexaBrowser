//lib/models/browser_tab.dart//
import 'dart:typed_data';

/// The special "URL" used for a tab that's showing the native Nexa home
/// page (see new_tab_page.dart) instead of a real WebView. Kept here so
/// every screen that needs to check/set it uses the exact same constant.
const String kNexaNewTabUrl = "nexa://newtab";

class BrowserTab {
  dynamic controller;
  String title;
  String url;
  Uint8List? thumbnail;
  bool isIncognito;
  bool isDesktopMode;

  BrowserTab({
    this.title = "New Tab",
    this.url = kNexaNewTabUrl,
    this.isIncognito = false,
    this.isDesktopMode = false,
  });
}

