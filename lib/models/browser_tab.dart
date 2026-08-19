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

  // Tracks whether this tab's WebView is currently scrolled all the way
  // to the top. Pull-to-refresh is only enabled while this is true, so
  // a normal upward scroll on a page that's already midway down doesn't
  // get mistaken for a refresh gesture (see browser_home.dart).
  bool isAtTop = true;

  BrowserTab({
    this.title = "New Tab",
    this.url = kNexaNewTabUrl,
    this.isIncognito = false,
    this.isDesktopMode = false,
  });
}

