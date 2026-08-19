import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/browser_tab.dart';
import '../models/bookmark.dart';
import 'package:share_plus/share_plus.dart';
import '../services/bookmark_service.dart';
import 'bookmarks_screen.dart';
import '../services/history_service.dart';
import 'history_screen.dart';
import '../services/download_service.dart';
import 'downloads_screen.dart';
import 'new_tab_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'profile_screen.dart';
import 'search_screen.dart';
import 'ai_chat_screen.dart';
import '../widgets/nexa_toolbar.dart';
import '../widgets/browser_menu_sheet.dart';
import '../widgets/delete_browsing_data_dialog.dart';
import '../widgets/notification_prompt_overlay.dart';
import 'tab_switcher_screen.dart';
import 'settings_screen.dart';
import '../widgets/find_in_page_bar.dart';
import '../services/adblock_service.dart';
import '../services/browser_prefs.dart';
import '../widgets/default_browser_prompt.dart';
import 'help_feedback_screen.dart';
import 'incognito_home_page.dart';
import '../services/screenshot_blocker_service.dart';
import '../theme_controller.dart';

class BrowserHome extends StatefulWidget {
  const BrowserHome({super.key});
  @override
  State<BrowserHome> createState() => _BrowserHomeState();
}

class _BrowserHomeState extends State<BrowserHome> {
  final TextEditingController urlController = TextEditingController();
  double progress = 0;
  bool isFocused = false;
  bool showTabSwitcher = false;
  bool currentIsBookmarked = false;

  bool showFindBar = false;
  int findMatchCount = 0;
  int findActiveIndex = 0;

  bool adBlockEnabled = true;

  //---------------------------------------------------------------------
  // Whether the address bar/toolbar sits at the top or bottom of the
  // screen. Loaded from Settings > Basics > "Address bar" and re-read
  // every time Settings is closed (see the .then() after pushing
  // SettingsScreen below), so a change applies immediately.
  //---------------------------------------------------------------------
  bool addressBarTop = true;

  //---------------------------------------------------------------------
  // Whether newly-created tabs should default to desktop mode. Set from
  // Settings > Basics > "Desktop site (default)". Loaded in initState.
  //---------------------------------------------------------------------
  bool defaultDesktopMode = false;

  static const String _desktopUserAgent =
      "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 "
      "(KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36";

  //---------------------------------------------------------------------
  // Forces a real desktop-width viewport via JS. Needed because sites like
  // YouTube set their own <meta name="viewport" content="width=device-width">
  // tag, which keeps the page in its mobile breakpoint even when the
  // User-Agent and useWideViewPort/loadWithOverviewMode are already set
  // for desktop. Used by _toggleDesktopMode() and onLoadStop() below.
  //---------------------------------------------------------------------
  //---------------------------------------------------------------------
  // Deliberately does NOT hard-code "initial-scale=1": that forced the
  // page to render at a literal 1:1 pixel scale, so a 1280px-wide
  // desktop layout simply ran off the right edge of a ~360-410px-wide
  // phone screen (cut-off text, no ability to see the rest without a
  // manual pinch-zoom or a reload — matches the "desktop mode looks
  // broken, needs a refresh to fix itself" report). Instead this
  // computes the actual scale needed to fit the 1280px layout to the
  // device's real screen width and sets that as initial-scale, which is
  // what "Desktop site" does in real Chrome/Brave/etc — the whole
  // desktop page shrinks to fit, in view immediately, no reload needed.
  //---------------------------------------------------------------------
  static const String _forceDesktopViewportScript = '''
(function() {
  var DESKTOP_WIDTH = 1280;
  var deviceWidth = window.screen && window.screen.width ? window.screen.width : window.innerWidth;
  var scale = Math.min(1, deviceWidth / DESKTOP_WIDTH);
  if (!isFinite(scale) || scale <= 0) scale = 0.3;

  var meta = document.querySelector('meta[name="viewport"]');
  if (!meta) {
    meta = document.createElement('meta');
    meta.name = 'viewport';
    document.head.appendChild(meta);
  }
  meta.setAttribute(
    'content',
    'width=' + DESKTOP_WIDTH + ', initial-scale=' + scale + ', minimum-scale=' + scale + ', user-scalable=yes'
  );
})();
''';

  //---------------------------------------------------------------------
  // Makes the loaded page follow the app's own Light/Dark choice instead
  // of the device's OS-level dark mode setting. Sites like Google use
  // the CSS `prefers-color-scheme` media query, which reads the OS
  // setting directly — completely independent of what theme is picked
  // inside Nexa's Settings > Appearance, which is why switching the app
  // to Light didn't change Google results (or other theme-aware sites)
  // back to a light look. Setting the `color-scheme` meta/CSS property
  // is the standard way sites let a host app override that.
  //---------------------------------------------------------------------
  static String _forceColorSchemeScript(bool dark) {
    final scheme = dark ? 'dark' : 'light';
    return '''
(function() {
  var meta = document.querySelector('meta[name="color-scheme"]');
  if (!meta) {
    meta = document.createElement('meta');
    meta.name = 'color-scheme';
    document.head.appendChild(meta);
  }
  meta.setAttribute('content', '$scheme');
  document.documentElement.style.colorScheme = '$scheme';
})();
''';
  }

  //---------------------------------------------------------------------
  // Defines window.FlutterInterface.postMessage(msg) BEFORE any page
  // script runs, so the home page's existing
  //   window.FlutterInterface.postMessage("open_ai_chat")
  // call (see openFlutterAIChat() in the home page HTML) actually reaches
  // Flutter instead of falling back to its alert("AI Mode click
  // detected!"). Routed through flutter_inappwebview's own JS-handler
  // bridge, registered as 'FlutterInterface' in onWebViewCreated below.
  //---------------------------------------------------------------------
  static const String _flutterInterfaceShimScript = '''
(function() {
  window.FlutterInterface = {
    postMessage: function(msg) {
      if (window.flutter_inappwebview) {
        window.flutter_inappwebview.callHandler('FlutterInterface', msg);
      }
    }
  };
})();
''';

  List<BrowserTab> tabs = [BrowserTab()];
  int activeTabIndex = 0;

  // Native pull-to-refresh, one controller per tab (they all live in an
  // IndexedStack). Deliberately NOT the old SmartRefresher-wraps-a-WebView
  // approach: that Flutter-side gesture recognizer sat "on top of" the
  // WebView PlatformView and won gesture arbitration for almost any
  // vertical drag near the top of the page, including a normal scroll
  // back up through a long results page — so scrolling up didn't scroll,
  // it triggered a refresh instead. flutter_inappwebview's own
  // PullToRefreshController is wired into the native WebView's real
  // scroll state on each platform, so it only engages on a genuine
  // overscroll-at-top gesture and gets out of the way of normal scrolling.
  final Map<int, PullToRefreshController> pullToRefreshControllers = {};

  //---------------------------------------------------------------------
  // Gets (or lazily creates) the pull-to-refresh controller for tab [index].
  //---------------------------------------------------------------------
  PullToRefreshController _getPullToRefreshController(int index) {
    return pullToRefreshControllers.putIfAbsent(
      index,
      () => PullToRefreshController(
        settings: PullToRefreshSettings(color: const Color(0xFF2DE1B0)),
        onRefresh: () async {
          await tabs[index].controller?.reload();
        },
      ),
    );
  }

  BrowserTab get activeTab => tabs[activeTabIndex];

  //---------------------------------------------------------------------
  // Turns whatever the user typed into the address bar into a real URL:
  // adds https:// if missing, or falls back to a Google search if it
  // doesn't look like a domain at all.
  //---------------------------------------------------------------------
  String _formatUrl(String input) {
    String url = input.trim();
    if (!url.startsWith("http")) {
      if (url.contains(".") && !url.contains(" ")) {
        url = "https://$url";
      } else {
        url = "https://www.google.com/search?q=${Uri.encodeComponent(url)}";
      }
    }
    return url;
  }

  //---------------------------------------------------------------------
  // If [url] is a YouTube mobile-subdomain link, rewrites it to the
  // www. desktop subdomain. Used whenever a tab is in desktop mode, since
  // YouTube only serves its real desktop layout from www.youtube.com â€”
  // the m.youtube.com pages stay mobile-styled no matter the User-Agent.
  //---------------------------------------------------------------------
  String _desktopifyYouTubeUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return url;
    if (uri.host == 'm.youtube.com') {
      return uri.replace(host: 'www.youtube.com').toString();
    }
    return url;
  }

  //---------------------------------------------------------------------
  // The reverse of the above â€” for sites that serve a genuinely
  // different mobile layout from their own subdomain (YouTube,
  // Facebook, X/Twitter, Wikipedia, Reddit, Quora), rewrites the URL
  // back to that mobile subdomain. Without this, unchecking "Desktop
  // site" only reloaded the *same* www./desktop URL with a mobile
  // User-Agent â€” the page still looked like the desktop layout because
  // the URL itself, not just the UA, decides which layout these sites
  // serve. Used by _toggleDesktopMode() and shouldOverrideUrlLoading()
  // below so unchecking behaves exactly like Chrome's own toggle.
  //---------------------------------------------------------------------
  String _mobileifyUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return url;

    switch (uri.host) {
      case 'www.youtube.com':
      case 'youtube.com':
        return uri.replace(host: 'm.youtube.com').toString();
      case 'www.facebook.com':
      case 'facebook.com':
        return uri.replace(host: 'm.facebook.com').toString();
      case 'www.twitter.com':
      case 'twitter.com':
      case 'www.x.com':
      case 'x.com':
        return uri.replace(host: 'mobile.twitter.com').toString();
      case 'www.reddit.com':
      case 'reddit.com':
        return uri.replace(host: 'm.reddit.com').toString();
      case 'www.quora.com':
        return uri.replace(host: 'm.quora.com').toString();
      default:
        // Wikipedia's mobile subdomain is "<lang>.m.wikipedia.org" â€”
        // the language code sits in front of "wikipedia.org", so it
        // needs a small rewrite rather than a straight host swap.
        if (uri.host.endsWith('.wikipedia.org') && !uri.host.contains('.m.')) {
          final lang = uri.host.split('.').first;
          return uri.replace(host: '$lang.m.wikipedia.org').toString();
        }
        return url;
    }
  }

  //---------------------------------------------------------------------
  // Runs once when BrowserHome is first built:
  //  - loads the saved ad-block preference and default-desktop-mode pref
  //  - shows the one-time "Nexa notifications" prompt (only ever fires
  //    once, on the very first launch, thanks to the SharedPreferences
  //    flag checked inside maybeShowNotificationPrompt()).
  //---------------------------------------------------------------------
  //---------------------------------------------------------------------
  // Syncs FLAG_SECURE with whether the currently active tab is
  // incognito. Called after every place activeTabIndex or the tabs list
  // can change (switching tabs, opening/closing a tab).
  //---------------------------------------------------------------------
  void _syncScreenshotBlock() {
    ScreenshotBlockerService.setBlocked(activeTab.isIncognito);
  }

  @override
  void initState() {
    super.initState();
    _loadAdBlockPref();
    _loadDefaultDesktopPref();
    _loadAddressBarPref();
    _syncScreenshotBlock();
    // Re-applies the light/dark color-scheme override (see
    // _forceColorSchemeScript) to every currently-open page as soon as
    // the user changes Settings > Appearance, instead of only picking it
    // up the next time each tab happens to reload.
    ThemeController.themeMode.addListener(_onThemeChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await maybeShowNotificationPrompt(context);
      if (!mounted) return;
      // Shown after the notifications card so the two first-run prompts
      // never race each other for the same frame.
      await maybeShowDefaultBrowserPrompt(context);
    });
  }

  void _onThemeChanged() {
    if (!mounted) return;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    for (final tab in tabs) {
      final controller = tab.controller;
      if (controller != null && tab.url != kNexaNewTabUrl) {
        controller.evaluateJavascript(source: _forceColorSchemeScript(isDark));
      }
    }
  }

  //---------------------------------------------------------------------
  // Loads "Address bar" position (top/bottom) from Settings.
  //---------------------------------------------------------------------
  Future<void> _loadAddressBarPref() async {
    final top = await BrowserPrefs.getAddressBarTop();
    if (!mounted) return;
    setState(() => addressBarTop = top);
  }

  //---------------------------------------------------------------------
  // Loads "Desktop site (default)" from Settings and applies it to the
  // very first tab (later tabs pick it up in addNewTab()).
  //---------------------------------------------------------------------
  Future<void> _loadDefaultDesktopPref() async {
    final value = await BrowserPrefs.getDefaultDesktopMode();
    if (!mounted) return;
    setState(() {
      defaultDesktopMode = value;
      if (value) {
        tabs.first.isDesktopMode = true;
      }
    });
  }

  //---------------------------------------------------------------------
  // Navigates the active tab's WebView to whatever is in the address bar.
  // If the tab is currently showing the native home page (no WebView
  // exists yet for it), switches it to a real page first.
  //---------------------------------------------------------------------
  void navigate() {
    final text = urlController.text.trim();
    if (text.isEmpty) return;
    loadUrlInActiveTab(text);
  }

  //---------------------------------------------------------------------
  // Loads [input] in the active tab, whether it's currently a real
  // WebView tab or the native home page. Used by the address bar,
  // History, Bookmarks, and anywhere else a URL can be opened — so
  // tapping a link from the home tab always works instead of silently
  // doing nothing (there's no WebView controller for the home tab).
  //---------------------------------------------------------------------
  void loadUrlInActiveTab(String input) {
    final url = _formatUrl(input);
    if (activeTab.url == kNexaNewTabUrl || activeTab.controller == null) {
      setState(() {
        activeTab.url = url;
        urlController.text = url;
      });
    } else {
      activeTab.controller?.loadUrl(urlRequest: URLRequest(url: WebUri(url)));
    }
    FocusScope.of(context).unfocus();
  }

  //---------------------------------------------------------------------
  // Sends the active tab back to the real Nexa home page (the native
  // shortcuts/most-visited screen — see new_tab_page.dart), not a
  // hosted web page. Switching a tab's url to kNexaNewTabUrl makes the
  // IndexedStack below swap that slot from a WebView to NewTabPage.
  //---------------------------------------------------------------------
  void goHome() {
    setState(() {
      activeTab.url = kNexaNewTabUrl;
      activeTab.controller = null;
      urlController.text = "";
    });
  }

  //---------------------------------------------------------------------
  // Opens a new tab. Pass incognito: true for a private tab. New tabs
  // start in desktop mode if that's the user's default (Settings).
  //---------------------------------------------------------------------
  void addNewTab({bool incognito = false}) {
    setState(() {
      final tab = BrowserTab(isIncognito: incognito);
      tab.isDesktopMode = defaultDesktopMode;
      tabs.add(tab);
      activeTabIndex = tabs.length - 1;
      urlController.text = "";
      showTabSwitcher = false;
    });
    _syncScreenshotBlock();
  }

  //---------------------------------------------------------------------
  // Switches the visible tab to [index] (called from the tab switcher).
  //---------------------------------------------------------------------
  void switchToTab(int index) {
    setState(() {
      activeTabIndex = index;
      urlController.text =
          tabs[index].url == kNexaNewTabUrl ? "" : tabs[index].url;
      showTabSwitcher = false;
    });
    _checkBookmarkStatus();
    _syncScreenshotBlock();
  }

  //---------------------------------------------------------------------
  // Opens the native share sheet for the current page's URL.
  //---------------------------------------------------------------------
  void shareCurrentPage() {
    final url = activeTab.url;
    final title = activeTab.title;
    Share.share(url, subject: title);
  }

  //---------------------------------------------------------------------
  // Closes tab [index]. If it was the last tab, opens a fresh blank one
  // instead of leaving the browser with zero tabs.
  //---------------------------------------------------------------------
  void closeTab(int index) {
    setState(() {
      pullToRefreshControllers.remove(index);

      tabs.removeAt(index);
      if (tabs.isEmpty) {
        tabs.add(BrowserTab());
        activeTabIndex = 0;
      } else if (activeTabIndex >= tabs.length) {
        activeTabIndex = tabs.length - 1;
      }
      urlController.text =
          tabs[activeTabIndex].url == kNexaNewTabUrl ? "" : tabs[activeTabIndex].url;
    });
    _syncScreenshotBlock();
  }

  //---------------------------------------------------------------------
  // Refreshes currentIsBookmarked to match whether the active tab's URL
  // is already saved as a bookmark.
  //---------------------------------------------------------------------
  Future<void> _checkBookmarkStatus() async {
    final result = await BookmarkService.isBookmarked(activeTab.url);
    if (mounted) setState(() => currentIsBookmarked = result);
  }

  //---------------------------------------------------------------------
  // Adds or removes the active tab's URL from bookmarks (star icon /
  // menu toggle).
  //---------------------------------------------------------------------
  Future<void> toggleBookmark() async {
    if (currentIsBookmarked) {
      await BookmarkService.removeBookmark(activeTab.url);
    } else {
      await BookmarkService.addBookmark(
        Bookmark(title: activeTab.title, url: activeTab.url),
      );
    }
    _checkBookmarkStatus();
  }

  //---------------------------------------------------------------------
  // Opens the Bookmarks screen; loads whichever bookmark the user taps
  // into the active tab.
  //---------------------------------------------------------------------
  void openBookmarksScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BookmarksScreen(
          onOpen: (url) => loadUrlInActiveTab(url),
        ),
      ),
    ).then((_) => _checkBookmarkStatus());
  }

  //---------------------------------------------------------------------
  // "Translate..." from the browser menu — reloads the active tab's page
  // through Google Translate's web proxy, which doesn't need any API
  // key. Uses the device's own language as the target.
  //---------------------------------------------------------------------
  void translateCurrentPage() {
    if (activeTab.url == kNexaNewTabUrl || activeTab.url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Open a page first to translate it")),
      );
      return;
    }
    final targetLang = WidgetsBinding.instance.platformDispatcher.locale.languageCode;
    final translateUrl =
        "https://translate.google.com/translate?sl=auto&tl=$targetLang&u=${Uri.encodeComponent(activeTab.url)}";
    loadUrlInActiveTab(translateUrl);
  }

  //---------------------------------------------------------------------
  // Shows the in-page "Find" search bar.
  //---------------------------------------------------------------------
  void openFindInPage() {    setState(() => showFindBar = true);
  }

  //---------------------------------------------------------------------
  // Hides the "Find" bar and clears any highlighted matches.
  //---------------------------------------------------------------------
  void closeFindInPage() {
    activeTab.controller?.clearMatches();
    setState(() {
      showFindBar = false;
      findMatchCount = 0;
      findActiveIndex = 0;
    });
  }

  //---------------------------------------------------------------------
  // Runs a find-in-page search for whatever the user typed in the Find bar.
  //---------------------------------------------------------------------
  void _onFindQuery(String query) {
    if (query.isEmpty) {
      activeTab.controller?.clearMatches();
      setState(() {
        findMatchCount = 0;
        findActiveIndex = 0;
      });
      return;
    }
    activeTab.controller?.findAll(find: query);
  }

  //---------------------------------------------------------------------
  // Toggles the active tab between mobile and desktop rendering:
  //  - swaps the User-Agent and preferredContentMode
  //  - re-applies zoom/viewport settings so the page actually scales like
  //    a desktop page instead of staying "fullscreen mobile"
  //  - if the current page is YouTube's mobile subdomain, rewrites the
  //    URL to www.youtube.com so it actually gets the desktop layout
  //  - after reload, force-overrides the page's own viewport meta tag
  //    (needed for sites like YouTube that ignore the UA change alone)
  //---------------------------------------------------------------------
  Future<void> _toggleDesktopMode() async {
    final tab = activeTab;
    final controller = tab.controller;

    tab.isDesktopMode = !tab.isDesktopMode;

    if (controller != null) {
      final currentSettings = await controller.getSettings();

      if (currentSettings != null) {
        currentSettings.userAgent = tab.isDesktopMode ? _desktopUserAgent : "";
        currentSettings.preferredContentMode = tab.isDesktopMode
            ? UserPreferredContentMode.DESKTOP
            : UserPreferredContentMode.RECOMMENDED;
        currentSettings.useWideViewPort = true;
        currentSettings.loadWithOverviewMode = true;
        currentSettings.supportZoom = true;
        currentSettings.builtInZoomControls = true;
        currentSettings.displayZoomControls = false;
        currentSettings.textZoom = 100;

        await controller.setSettings(settings: currentSettings);

        if (tab.isDesktopMode) {
          final desktopUrl = _desktopifyYouTubeUrl(tab.url);
          if (desktopUrl != tab.url) {
            // YouTube mobile URL -> rewrite to www. and navigate there
            // directly instead of just reloading the same m. URL.
            await controller.loadUrl(
              urlRequest: URLRequest(url: WebUri(desktopUrl)),
            );
          } else {
            await controller.reload();
          }
        } else {
          final mobileUrl = _mobileifyUrl(tab.url);
          if (mobileUrl != tab.url) {
            // Reverse of the above — send known sites back to their
            // actual mobile subdomain instead of just reloading the
            // desktop URL with a mobile User-Agent.
            await controller.loadUrl(
              urlRequest: URLRequest(url: WebUri(mobileUrl)),
            );
          } else {
            await controller.reload();
          }
        }

        // After the reload/navigation settles, force a real desktop
        // viewport width so responsive sites (e.g. YouTube) don't stay
        // stuck in their mobile breakpoint.
        if (tab.isDesktopMode) {
          Future.delayed(const Duration(milliseconds: 600), () async {
            await controller.evaluateJavascript(
              source: _forceDesktopViewportScript,
            );
          });
        }
      }
    }

    if (mounted) setState(() {});
  }

  //---------------------------------------------------------------------
  // Turns the ad-blocker on/off, saves the choice, and reloads the page
  // so the new content-blocker rules take effect. Also re-syncs the ad
  // toggle on the Nexa home page (see _syncHomePageAdBlockState below).
  //---------------------------------------------------------------------
  Future<void> toggleAdBlock(bool value) async {
    setState(() => adBlockEnabled = value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('ad_block_enabled', value);
    await activeTab.controller?.reload();
  }

  //---------------------------------------------------------------------
  // Loads the saved ad-block preference on startup (called from initState).
  //---------------------------------------------------------------------
  Future<void> _loadAdBlockPref() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() => adBlockEnabled = prefs.getBool('ad_block_enabled') ?? true);
  }

  //---------------------------------------------------------------------
  // Returns the JS injected into Google pages that swaps the Google logo
  // for the Nexa brand badge. Called from onLoadStop() whenever the
  // loaded page's host is a google.com domain.
  //---------------------------------------------------------------------
  String _buildGoogleBrandingScript() {
    return '''
(function() {
  const BRAND_TEXT = 'Nexa';
  const badgeStyle = "display:inline-flex;align-items:center;justify-content:center;padding:10px 16px;border-radius:999px;background:linear-gradient(135deg,#2DE1B0 0%,#1A73E8 100%);box-shadow:0 10px 24px rgba(0,0,0,0.16);font-size:30px;font-weight:700;color:#ffffff;letter-spacing:1px;line-height:1;white-space:nowrap;font-family:Arial,Helvetica,sans-serif;";
  if (window.__nexaBrandingInjected) return;
  window.__nexaBrandingInjected = true;

  function createBadge() {
    const badge = document.createElement('span');
    badge.className = 'nexa-brand-mark';
    badge.textContent = BRAND_TEXT;
    badge.setAttribute('aria-label', BRAND_TEXT);
    badge.style.cssText = badgeStyle;
    return badge;
  }

  function replaceLogoTarget(target) {
    if (!target || target.dataset.nexaInjected === 'true') return;
    target.dataset.nexaInjected = 'true';

    if (target.matches('img[alt="Google"], #logo img, .logo img, a[href^="/?"] img')) {
      target.replaceWith(createBadge());
      return;
    }

    if (target.matches('#logocont, .logocont, #logo, .logo')) {
      target.innerHTML = '';
      target.appendChild(createBadge());
    }
  }

  function applyBranding() {
    const selectors = ['img[alt="Google"]', '#logo img', '.logo img', 'a[href^="/?"] img', '#logocont', '.logocont', '#logo', '.logo'];
    const seen = new WeakSet();

    selectors.forEach((selector) => {
      document.querySelectorAll(selector).forEach((node) => {
        if (seen.has(node)) return;
        seen.add(node);
        replaceLogoTarget(node);
      });
    });
  }

  function init() {
    applyBranding();
    const observer = new MutationObserver(() => applyBranding());
    const targetRoot = document.documentElement || document.body;

    if (targetRoot) {
      observer.observe(targetRoot, {
        childList: true,
        subtree: true,
        attributes: true,
        attributeFilter: ['alt', 'src', 'href', 'class', 'id']
      });
    }

    window.addEventListener('load', applyBranding, { once: true });
    setTimeout(applyBranding, 250);
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init, { once: true });
  } else {
    init();
  }
})();
''';
  }

  //---------------------------------------------------------------------
  // Handles the Android hardware/gesture back button:
  //  1) closes the tab switcher if it's open
  //  2) otherwise goes back in the active tab's web history
  //  3) otherwise closes the current tab if there are other tabs open
  //  4) otherwise exits the app
  //---------------------------------------------------------------------
  Future<void> _handleBackPress() async {
    if (showTabSwitcher) {
      setState(() => showTabSwitcher = false);
      return;
    }

    final canGoBack = await activeTab.controller?.canGoBack() ?? false;
    if (canGoBack) {
      activeTab.controller?.goBack();
      return;
    }

    if (tabs.length > 1) {
      closeTab(activeTabIndex);
      return;
    }

    SystemNavigator.pop();
  }

  //---------------------------------------------------------------------
  // Opens the Chrome-style "Delete browsing data" bottom sheet and, based
  // on what the user selected, clears history (within the chosen time
  // range), cookies/site data, and/or closes all open tabs.
  //---------------------------------------------------------------------
  Future<void> _deleteBrowsingData() async {
    final result = await showDeleteBrowsingDataDialog(
      context,
      openTabCount: tabs.length,
    );
    if (result == null) return;

    if (result.clearHistory) {
      await HistoryService.clearSince(result.range.duration);
    }

    if (result.clearCookiesAndSiteData) {
      await CookieManager.instance().deleteAllCookies();
      await WebStorageManager.instance().deleteAllData();
    }

    if (result.clearOpenTabs) {
      setState(() {
        pullToRefreshControllers.clear();
        tabs.clear();
        tabs.add(BrowserTab());
        activeTabIndex = 0;
        urlController.text = "";
      });
    }

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Browsing data deleted')));
    }
  }

  //---------------------------------------------------------------------
  // Cleans up all pull-to-refresh controllers and the address bar
  // controller when BrowserHome is removed from the widget tree.
  //---------------------------------------------------------------------
  @override
  void dispose() {
    ThemeController.themeMode.removeListener(_onThemeChanged);
    pullToRefreshControllers.clear();
    urlController.dispose();
    super.dispose();
  }

  //---------------------------------------------------------------------
  // Top-level build: intercepts the back button via PopScope, and shows
  // either the Tab Switcher screen or the normal browser UI.
  //---------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _handleBackPress();
      },
      child: showTabSwitcher
          ? TabSwitcherScreen(
              tabs: tabs,
              activeTabIndex: activeTabIndex,
              onAddNewTab: addNewTab,
              onClose: () => setState(() => showTabSwitcher = false),
              onSwitchToTab: switchToTab,
              onCloseTab: closeTab,
            )
          : _buildBrowserScreen(),
    );
  }

  //---------------------------------------------------------------------
  // Builds the main browser UI: toolbar (address bar + menu), the Find
  // bar, the loading progress indicator, and the stack of WebViews (one
  // per tab, kept alive via IndexedStack so switching tabs doesn't reload
  // them).
  //---------------------------------------------------------------------
  Widget _buildBrowserScreen() {
    final toolbar = NexaToolbar(
      onHome: goHome,
      addressText: urlController.text,
      isIncognito: activeTab.isIncognito,
      isHomePage: activeTab.url == kNexaNewTabUrl,
      onAddressTap: () async {
        final result = await Navigator.push<String>(
          context,
          MaterialPageRoute(
            builder: (_) => SearchScreen(initialText: urlController.text),
            fullscreenDialog: true,
          ),
        );
        if (result != null && result.isNotEmpty) {
          urlController.text = result;
          navigate();
        }
      },
      onNewTab: addNewTab,
      tabCount: tabs.length,
      onTabSwitcherTap: () => setState(() => showTabSwitcher = true),
      onMenuTap: () => showBrowserMenu(
        context,
        onBack: () => activeTab.controller?.goBack(),
        onForward: () => activeTab.controller?.goForward(),
        onReload: () => activeTab.controller?.reload(),
        isBookmarked: currentIsBookmarked,
        onToggleBookmark: toggleBookmark,
        onNewTab: addNewTab,
        onNewIncognitoTab: () => addNewTab(incognito: true),
        isDesktop: activeTab.isDesktopMode,
        onToggleDesktop: _toggleDesktopMode,
        isAdBlockEnabled: adBlockEnabled,
        onToggleAdBlock: () => toggleAdBlock(!adBlockEnabled),
        onFindInPage: openFindInPage,
        onTranslate: translateCurrentPage,
        onShare: shareCurrentPage,
        onHistory: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => HistoryScreen(
              onOpen: (url) => loadUrlInActiveTab(url),
            ),
          ),
        ),
        onDeleteBrowsingData: _deleteBrowsingData,
        onDownloads: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const DownloadsScreen()),
        ),
        onBookmarks: openBookmarksScreen,
        onProfile: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ProfileScreen()),
        ).then((_) => setState(() {})),
        onHelpFeedback: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const HelpFeedbackScreen()),
        ),
        onSettings: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SettingsScreen()),
        ).then((_) {
          // Settings may have changed ad-block, the default desktop mode,
          // or the address bar position — reload them so they apply
          // without needing to restart the app.
          _loadAdBlockPref();
          _loadDefaultDesktopPref();
          _loadAddressBarPref();
        }),
        onAIMode: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AIChatScreen()),
        ),
      ),
    );

    return Scaffold(
      appBar: addressBarTop ? toolbar : null,
      bottomNavigationBar: addressBarTop ? null : toolbar,
      body: Column(
        children: [
          //-----------------------------------------------------------
          // In-page "Find" search bar (only visible when showFindBar).
          //-----------------------------------------------------------
          if (showFindBar)
            FindInPageBar(
              onSearch: _onFindQuery,
              onNext: () => activeTab.controller?.findNext(forward: true),
              onPrevious: () => activeTab.controller?.findNext(forward: false),
              onClose: closeFindInPage,
              currentMatch: findActiveIndex,
              totalMatches: findMatchCount,
            ),
          //-----------------------------------------------------------
          // Page load progress bar.
          //-----------------------------------------------------------
          if (progress < 1.0)
            LinearProgressIndicator(value: progress, minHeight: 2),
          //-----------------------------------------------------------
          // One WebView per tab, stacked via IndexedStack so switching
          // tabs is instant and doesn't reload the page underneath.
          //-----------------------------------------------------------
          Expanded(
            child: IndexedStack(
              index: activeTabIndex,
              children: tabs.asMap().entries.map((entry) {
                int i = entry.key;
                BrowserTab tab = entry.value;

                // Special-case: the "new tab" placeholder page (shortcuts /
                // most-visited grid) instead of a real WebView.
                if (tab.url == kNexaNewTabUrl) {
                  if (tab.isIncognito) {
                    return IncognitoHomePage(
                      onOpenUrl: (url) => loadUrlInActiveTab(url),
                    );
                  }
                  return NewTabPage(
                    onOpenUrl: (url) => loadUrlInActiveTab(url),
                    onOpenIncognito: () => addNewTab(incognito: true),
                  );
                }

                return InAppWebView(
                    initialUrlRequest: URLRequest(url: WebUri(tab.url)),
                    // Native pull-to-refresh — see pullToRefreshControllers
                    // above for why this replaced the old SmartRefresher
                    // wrapper (that one fought with normal page scrolling
                    // and turned "scroll up" into "refresh the page").
                    pullToRefreshController: _getPullToRefreshController(i),
                    //-----------------------------------------------
                    // Injects the FlutterInterface shim (see the
                    // constant above) before ANY page script runs, so
                    // the home page's AI Mode button can reach Flutter.
                    //-----------------------------------------------
                    initialUserScripts: UnmodifiableListView<UserScript>([
                      UserScript(
                        source: _flutterInterfaceShimScript,
                        injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
                      ),
                    ]),
                    onWebViewCreated: (controller) {
                      tab.controller = controller;
                      //-------------------------------------------
                      // Handles messages sent from the page via
                      // window.FlutterInterface.postMessage(...).
                      // Currently only "open_ai_chat" is used (AI
                      // Mode button on the home page).
                      //-------------------------------------------
                      controller.addJavaScriptHandler(
                        handlerName: 'FlutterInterface',
                        callback: (args) {
                          final message = args.isNotEmpty ? args[0].toString() : '';
                          if (message == 'open_ai_chat') {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const AIChatScreen()),
                            );
                          }
                          return null;
                        },
                      );
                    },
                    //-----------------------------------------------
                    // Drives the top loading progress bar.
                    //-----------------------------------------------
                    onProgressChanged: (controller, p) {
                      if (i == activeTabIndex) {
                        setState(() => progress = p / 100);
                      }
                    },
                    //-----------------------------------------------
                    // Per-tab WebView settings: ad-block content
                    // blockers, incognito mode, and desktop/mobile
                    // rendering (UA + viewport/zoom settings) based on
                    // this tab's isDesktopMode flag.
                    //-----------------------------------------------
                    initialSettings: InAppWebViewSettings(
                      useOnDownloadStart: true,
                      incognito: tab.isIncognito,
                      contentBlockers: adBlockEnabled
                          ? AdBlockService.getContentBlockers()
                          : [],
                      userAgent: tab.isDesktopMode ? _desktopUserAgent : "",
                      preferredContentMode: tab.isDesktopMode
                          ? UserPreferredContentMode.DESKTOP
                          : UserPreferredContentMode.RECOMMENDED,
                      useWideViewPort: true,
                      loadWithOverviewMode: true,
                      supportZoom: true,
                      builtInZoomControls: true,
                      displayZoomControls: false,
                      textZoom: 100,
                    ),
                    //-----------------------------------------------
                    // Keeps navigation consistent with the current
                    // desktop/mobile toggle: while in desktop mode,
                    // bounces m.youtube.com etc. over to the desktop
                    // subdomain (some sites redirect back to mobile
                    // even with a desktop User-Agent); while in mobile
                    // mode, does the reverse for sites whose desktop
                    // subdomain doesn't respect the mobile User-Agent.
                    //-----------------------------------------------
                    shouldOverrideUrlLoading: (controller, navigationAction) async {
                      final requestUrl = navigationAction.request.url?.toString();
                      if (requestUrl == null) return NavigationActionPolicy.ALLOW;

                      if (tab.isDesktopMode) {
                        final desktopUrl = _desktopifyYouTubeUrl(requestUrl);
                        if (desktopUrl != requestUrl) {
                          await controller.loadUrl(
                            urlRequest: URLRequest(url: WebUri(desktopUrl)),
                          );
                          return NavigationActionPolicy.CANCEL;
                        }
                      } else {
                        final mobileUrl = _mobileifyUrl(requestUrl);
                        if (mobileUrl != requestUrl) {
                          await controller.loadUrl(
                            urlRequest: URLRequest(url: WebUri(mobileUrl)),
                          );
                          return NavigationActionPolicy.CANCEL;
                        }
                      }
                      return NavigationActionPolicy.ALLOW;
                    },
                    //-----------------------------------------------
                    // Handles file downloads triggered from the page.
                    //-----------------------------------------------
                    onDownloadStartRequest: (controller, request) async {
                      final messenger = ScaffoldMessenger.of(context);

                      try {
                        await DownloadService.startDownload(
                          request.url.toString(),
                          suggestedName: request.suggestedFilename,
                        );

                        if (!mounted) return;

                        messenger.showSnackBar(
                          const SnackBar(content: Text("Download started")),
                        );
                      } catch (e) {
                        if (!mounted) return;

                        messenger.showSnackBar(
                          SnackBar(
                            content: Text("Could not start download: $e"),
                          ),
                        );
                      }
                    },
                    //-----------------------------------------------
                    // Updates the Find-in-page match counter/position.
                    //-----------------------------------------------
                    onFindResultReceived:
                        (
                          controller,
                          activeMatchOrdinal,
                          numberOfMatches,
                          isDoneCounting,
                        ) {
                          if (isDoneCounting && i == activeTabIndex) {
                            setState(() {
                              findMatchCount = numberOfMatches;
                              findActiveIndex = activeMatchOrdinal + 1;
                            });
                          }
                        },
                    //-----------------------------------------------
                    // Runs once a page finishes loading:
                    //  - updates tab title/url + saves it to History
                    //  - injects the Nexa branding script on Google pages
                    //  - syncs the ad-block toggle on the Nexa home page
                    //  - re-applies the forced desktop viewport if this
                    //    tab is in desktop mode
                    //  - captures a thumbnail for the tab switcher
                    //  - refreshes the bookmark star state
                    //-----------------------------------------------
                    onLoadStop: (controller, url) async {
                      tab.url = url.toString();
                      tab.title = await controller.getTitle() ?? tab.url;

                      if (!tab.isIncognito) {
                        HistoryService.addEntry(tab.title, tab.url);
                      }

                      final isGooglePage =
                          url != null &&
                          (url.host == 'google.com' ||
                              url.host == 'www.google.com' ||
                              url.host.endsWith('.google.com'));

                      if (isGooglePage) {
                        await controller.evaluateJavascript(
                          source: _buildGoogleBrandingScript(),
                        );
                      }

                      if (tab.isDesktopMode) {
                        await controller.evaluateJavascript(
                          source: _forceDesktopViewportScript,
                        );
                      }

                      if (mounted) {
                        await controller.evaluateJavascript(
                          source: _forceColorSchemeScript(
                            Theme.of(context).brightness == Brightness.dark,
                          ),
                        );
                      }

                      // Wait for the page to settle before capturing, so the
                      // screenshot isn't taken mid-render (blank/partial).
                      await Future.delayed(const Duration(milliseconds: 300));
                      final screenshot = await controller.takeScreenshot();

                      if (mounted) {
                        setState(() {
                          if (screenshot != null) {
                            tab.thumbnail = screenshot;
                          }
                          if (i == activeTabIndex) {
                            urlController.text = tab.url;
                          }
                        });
                      }

                      if (i == activeTabIndex) {
                        _checkBookmarkStatus();
                      }

                      // Tell the native pull-to-refresh spinner the
                      // refresh (if one was in progress) is done.
                      _getPullToRefreshController(i).endRefreshing();
                    },
                  );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}