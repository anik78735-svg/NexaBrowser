//lib/models/browser_tab.dart//
import 'dart:typed_data';

class BrowserTab {
  dynamic controller;
  String title;
  String url;
  Uint8List? thumbnail;
  bool isIncognito;
  bool isDesktopMode;

  BrowserTab({
    this.title = "New Tab",
    this.url = "https://nexa-home-iota.vercel.app/",
    this.isIncognito = false,
    this.isDesktopMode = false,
  });
}
