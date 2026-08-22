//lib/models/browser_tab.dart//
import 'dart:typed_data';
import 'package:flutter/widgets.dart';

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

  // Wraps whatever this tab is currently showing (the native New Tab
  // page OR a WebView) so a thumbnail can be captured for the tab
  // switcher grid regardless of which one it is. The New Tab page has
  // no WebView to screenshot the normal way, which is why it never
  // showed a thumbnail before — this key lets us grab a real
  // RepaintBoundary snapshot of it too (see browser_home.dart).
  final GlobalKey repaintKey = GlobalKey();

  BrowserTab({
    this.title = "New Tab",
    this.url = kNexaNewTabUrl,
    this.isIncognito = false,
    this.isDesktopMode = false,
  });
}

