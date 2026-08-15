import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class AdBlockService {
  static final List<String> _blockedDomains = [
    "doubleclick.net",
    "googlesyndication.com",
    "googleadservices.com",
    "google-analytics.com",
    "adnxs.com",
    "adsafeprotected.com",
    "amazon-adsystem.com",
    "facebook.com/tr",
    "taboola.com",
    "outbrain.com",
    "pubmatic.com",
    "rubiconproject.com",
    "criteo.com",
    "moatads.com",
    "scorecardresearch.com",
    "adroll.com",
    "media.net",
    "propellerads.com",
    "popads.net",
    "exoclick.com",
  ];

  static List<ContentBlocker> getContentBlockers() {
    return _blockedDomains.map((domain) {
      return ContentBlocker(
        trigger: ContentBlockerTrigger(
          urlFilter: ".*$domain.*",
        ),
        action: ContentBlockerAction(
          type: ContentBlockerActionType.BLOCK,
        ),
      );
    }).toList();
  }
}