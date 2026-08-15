import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'profile_screen.dart';
import 'downloads_screen.dart';
import 'search_engine_screen.dart';
import 'address_bar_screen.dart';
import 'safety_check_screen.dart';
import 'password_manager_screen.dart';
import 'autofill_settings_screen.dart';
import 'tabs_settings_screen.dart';
import 'notifications_settings_screen.dart';
import 'appearance_screen.dart';
import 'accessibility_screen.dart';
import 'site_settings_screen.dart';
import 'languages_screen.dart';
import 'help_feedback_screen.dart';
import '../services/browser_prefs.dart';
import '../services/default_browser_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool homepageOn = true;
  String searchEngineLabel = "Google";
  String addressBarLabel = "Top";

  //---------------------------------------------------------------------
  // Ad blocker — controls both the app's native WebView content
  // blockers (see AdBlockService in browser_home.dart) AND the Nexa
  // home page's own ad units (synced via JS injection in
  // browser_home.dart's onLoadStop). Same 'ad_block_enabled' key that
  // Privacy and security's "Block ads" toggle also reads/writes, so
  // both stay in sync no matter which one the user changes.
  //---------------------------------------------------------------------
  bool adBlockEnabled = true;

  //---------------------------------------------------------------------
  // Whether newly-opened tabs should start in desktop mode by default.
  //---------------------------------------------------------------------
  bool desktopSiteDefault = false;

  bool? isDefaultBrowser;

  String _query = "";
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final engine = await BrowserPrefs.getSearchEngine();
    final addressTop = await BrowserPrefs.getAddressBarTop();
    final defaultDesktop = await BrowserPrefs.getDefaultDesktopMode();
    final isDefault = await DefaultBrowserService.isDefault();
    if (!mounted) return;
    setState(() {
      homepageOn = prefs.getBool('homepage_enabled') ?? true;
      adBlockEnabled = prefs.getBool('ad_block_enabled') ?? true;
      searchEngineLabel = BrowserPrefs.searchEngineLabels[engine] ?? "Google";
      addressBarLabel = addressTop ? "Top" : "Bottom";
      desktopSiteDefault = defaultDesktop;
      isDefaultBrowser = isDefault;
    });
  }

  Future<void> _setAsDefaultBrowser() async {
    await DefaultBrowserService.openSettings();
    // The OS dialog/settings screen is async and may take the user a
    // moment to act on, so re-check status once they're back here.
    if (mounted) _load();
  }

  Future<void> _toggleHomepage(bool v) async {
    setState(() => homepageOn = v);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('homepage_enabled', v);
  }

  Future<void> _toggleAdBlock(bool v) async {
    setState(() => adBlockEnabled = v);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('ad_block_enabled', v);
  }

  Future<void> _toggleDesktopDefault(bool v) async {
    setState(() => desktopSiteDefault = v);
    await BrowserPrefs.setDefaultDesktopMode(v);
  }

  void _openHelp() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const HelpFeedbackScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final colors = Theme.of(context).colorScheme;

    // A tiny set of (keyword -> row) pairs so the search box above
    // actually filters, Chrome-style, instead of just sitting there.
    bool matches(String label) =>
        _query.isEmpty || label.toLowerCase().contains(_query.toLowerCase());

    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
        actions: [
          IconButton(
            tooltip: "Help & feedback",
            icon: const Icon(Icons.help_outline_rounded),
            onPressed: _openHelp,
          ),
        ],
      ),
      body: ListView(
        children: [
          //-----------------------------------------------------------
          // Search settings — now actually filters the rows below.
          //-----------------------------------------------------------
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: "Search settings",
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = "");
                        },
                      ),
              ),
            ),
          ),

          //-----------------------------------------------------------
          // You and Nexa
          //-----------------------------------------------------------
          if (matches("You and Nexa account sign in $searchEngineLabel"))
            _sectionHeader(context, "You and Nexa"),
          if (matches("You and Nexa account sign in"))
            _card(context, [
              ListTile(
                leading: CircleAvatar(
                  radius: 20,
                  backgroundColor: colors.primary,
                  backgroundImage: user?.photoURL != null
                      ? NetworkImage(user!.photoURL!)
                      : null,
                  child: user?.photoURL == null
                      ? Text(
                          (user?.displayName?.isNotEmpty == true
                                  ? user!.displayName![0]
                                  : (user?.email?.isNotEmpty == true
                                      ? user!.email![0]
                                      : "?"))
                              .toUpperCase(),
                          style: TextStyle(color: colors.onPrimary, fontWeight: FontWeight.w600),
                        )
                      : null,
                ),
                title: Text(
                  user?.displayName ??
                      (user == null ? "Sign in to Nexa" : "Nexa user"),
                ),
                subtitle: user?.email != null
                    ? Text(user!.email!)
                    : const Text("Sync bookmarks, history and passwords"),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                ).then((_) => _load()),
              ),
              _divider(),
              ListTile(
                leading: CircleAvatar(
                  radius: 20,
                  backgroundColor: colors.tertiaryContainer,
                  child: Icon(Icons.apps_rounded, color: colors.onTertiaryContainer, size: 20),
                ),
                title: const Text("Nexa services"),
                subtitle: const Text("Manage your account and privacy settings"),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                ).then((_) => _load()),
              ),
            ]),

          //-----------------------------------------------------------
          // Basics
          //-----------------------------------------------------------
          if (matches("Basics search engine address bar ad blocker desktop site default browser"))
            _sectionHeader(context, "Basics"),
          if (matches("Set as default browser"))
            _card(context, [
              ListTile(
                leading: CircleAvatar(
                  radius: 18,
                  backgroundColor: isDefaultBrowser == true
                      ? colors.primaryContainer
                      : colors.surfaceContainerHighest,
                  child: Icon(
                    isDefaultBrowser == true ? Icons.check_circle_rounded : Icons.public_rounded,
                    size: 18,
                    color: isDefaultBrowser == true
                        ? colors.onPrimaryContainer
                        : colors.onSurfaceVariant,
                  ),
                ),
                title: const Text("Default browser app"),
                subtitle: Text(
                  isDefaultBrowser == true
                      ? "Nexa is your default browser"
                      : "Set Nexa to open links automatically",
                ),
                trailing: isDefaultBrowser == true
                    ? null
                    : FilledButton(
                        onPressed: _setAsDefaultBrowser,
                        child: const Text("Set"),
                      ),
                onTap: isDefaultBrowser == true ? null : _setAsDefaultBrowser,
              ),
            ]),
          _card(context, [
            if (matches("Search engine"))
              _tile(
                context,
                icon: Icons.search_rounded,
                title: "Search engine",
                subtitle: searchEngineLabel,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SearchEngineScreen()),
                ).then((_) => _load()),
              ),
            if (matches("Address bar"))
              _tile(
                context,
                icon: Icons.dns_rounded,
                title: "Address bar",
                subtitle: addressBarLabel,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddressBarScreen()),
                ).then((_) => _load()),
              ),
            if (matches("Ad blocker"))
              _switchTile(
                context,
                icon: Icons.block_rounded,
                title: "Ad blocker",
                subtitle: "Blocks ads on the home page and in-app browsing",
                value: adBlockEnabled,
                onChanged: _toggleAdBlock,
              ),
            if (matches("Desktop site default"))
              _switchTile(
                context,
                icon: Icons.desktop_windows_rounded,
                title: "Desktop site (default)",
                subtitle: "New tabs open showing the desktop version of sites",
                value: desktopSiteDefault,
                onChanged: _toggleDesktopDefault,
              ),
          ], filter: matches("Search engine Address bar Ad blocker Desktop site")),

          if (matches("Privacy and security safety check"))
            _card(context, [
              _tile(
                context,
                icon: Icons.privacy_tip_rounded,
                title: "Privacy and security",
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const _PrivacySecurityScreen()),
                ).then((_) => _load()),
              ),
              _divider(),
              _tile(
                context,
                icon: Icons.shield_rounded,
                title: "Safety check",
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SafetyCheckScreen()),
                ),
              ),
            ]),

          //-----------------------------------------------------------
          // Passwords and autofill
          //-----------------------------------------------------------
          if (matches("Passwords and autofill password manager autofill services"))
            _sectionHeader(context, "Passwords and autofill"),
          if (matches("Nexa Password Manager Autofill services"))
            _card(context, [
              _tile(
                context,
                icon: Icons.key_rounded,
                title: "Nexa Password Manager",
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PasswordManagerScreen()),
                ),
              ),
              _divider(),
              _tile(
                context,
                icon: Icons.auto_awesome_rounded,
                title: "Autofill services",
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AutofillSettingsScreen()),
                ),
              ),
            ]),

          //-----------------------------------------------------------
          // Advanced
          //-----------------------------------------------------------
          if (matches("Advanced tabs homepage notifications appearance accessibility site settings languages downloads about"))
            _sectionHeader(context, "Advanced"),
          _card(context, [
            if (matches("Tabs and tab groups"))
              _tile(
                context,
                icon: Icons.tab_rounded,
                title: "Tabs and tab groups",
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TabsSettingsScreen()),
                ),
              ),
            if (matches("Homepage")) ...[
              _divider(),
              _switchTile(
                context,
                icon: Icons.home_rounded,
                title: "Homepage",
                subtitle: homepageOn ? "On" : "Off",
                value: homepageOn,
                onChanged: _toggleHomepage,
              ),
            ],
            if (matches("Notifications")) ...[
              _divider(),
              _tile(
                context,
                icon: Icons.notifications_rounded,
                title: "Notifications",
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const NotificationsSettingsScreen()),
                ),
              ),
            ],
            if (matches("Appearance theme dark light colour")) ...[
              _divider(),
              _tile(
                context,
                icon: Icons.palette_rounded,
                title: "Appearance",
                badge: "New",
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AppearanceScreen()),
                ),
              ),
            ],
            if (matches("Accessibility")) ...[
              _divider(),
              _tile(
                context,
                icon: Icons.accessibility_new_rounded,
                title: "Accessibility",
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AccessibilityScreen()),
                ),
              ),
            ],
            if (matches("Site settings")) ...[
              _divider(),
              _tile(
                context,
                icon: Icons.public_rounded,
                title: "Site settings",
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SiteSettingsScreen()),
                ),
              ),
            ],
            if (matches("Languages")) ...[
              _divider(),
              _tile(
                context,
                icon: Icons.translate_rounded,
                title: "Languages",
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LanguagesScreen()),
                ),
              ),
            ],
            if (matches("Downloads")) ...[
              _divider(),
              _tile(
                context,
                icon: Icons.download_rounded,
                title: "Downloads",
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const DownloadsScreen()),
                ),
              ),
            ],
            if (matches("About Nexa version")) ...[
              _divider(),
              _tile(
                context,
                icon: Icons.info_rounded,
                title: "About Nexa",
                subtitle: "Version 1.0.0",
                onTap: () => showAboutDialog(
                  context: context,
                  applicationName: "Nexa Browser",
                  applicationVersion: "1.0.0",
                  applicationIcon: Icon(Icons.public_rounded, color: colors.primary, size: 32),
                ),
              ),
            ],
          ]),

          //-----------------------------------------------------------
          // Send feedback
          //-----------------------------------------------------------
          if (matches("Send feedback help support bug"))
            _card(context, [
              _tile(
                context,
                icon: Icons.feedback_rounded,
                title: "Send feedback",
                subtitle: "Report a bug or share a suggestion",
                onTap: _openHelp,
              ),
            ]),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  //-----------------------------------------------------------------------
  // Small shared builders that keep every row visually consistent and
  // theme-aware (light + dark) instead of hard-coding colors per row.
  //-----------------------------------------------------------------------

  Widget _sectionHeader(BuildContext context, String title) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 8),
      child: Text(
        title,
        style: TextStyle(
          color: colors.primary,
          fontSize: 13,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _card(BuildContext context, List<Widget> children, {bool filter = true}) {
    if (!filter || children.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(children: children),
      ),
    );
  }

  Widget _divider() => const Divider(height: 1, indent: 56);

  Widget _tile(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    String? badge,
    required VoidCallback onTap,
  }) {
    final colors = Theme.of(context).colorScheme;
    return ListTile(
      leading: CircleAvatar(
        radius: 18,
        backgroundColor: colors.surfaceContainerHighest,
        child: Icon(icon, size: 18, color: colors.onSurfaceVariant),
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title),
          if (badge != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: colors.primaryContainer,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                badge,
                style: TextStyle(
                  color: colors.onPrimaryContainer,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: Icon(Icons.chevron_right_rounded, color: colors.outline),
      onTap: onTap,
    );
  }

  Widget _switchTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final colors = Theme.of(context).colorScheme;
    return SwitchListTile(
      secondary: CircleAvatar(
        radius: 18,
        backgroundColor: colors.surfaceContainerHighest,
        child: Icon(icon, size: 18, color: colors.onSurfaceVariant),
      ),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle) : null,
      value: value,
      onChanged: onChanged,
    );
  }
}

//---------------------------------------------------------------------
// Privacy and security sub-screen — the toggles that were previously on
// the main Settings screen (block pop-ups, save history, block ads).
// "Block ads" here reads/writes the SAME 'ad_block_enabled' key as the
// top-level "Ad blocker" toggle above, so they always stay in sync.
//---------------------------------------------------------------------
class _PrivacySecurityScreen extends StatefulWidget {
  const _PrivacySecurityScreen();

  @override
  State<_PrivacySecurityScreen> createState() => _PrivacySecurityScreenState();
}

class _PrivacySecurityScreenState extends State<_PrivacySecurityScreen> {
  bool blockPopups = true;
  bool saveHistory = true;
  bool adBlockEnabled = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      blockPopups = prefs.getBool('block_popups') ?? true;
      saveHistory = prefs.getBool('save_history') ?? true;
      adBlockEnabled = prefs.getBool('ad_block_enabled') ?? true;
    });
  }

  Future<void> _save(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text("Privacy and security")),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Card(
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  SwitchListTile(
                    secondary: Icon(Icons.web_asset_off_rounded, color: colors.onSurfaceVariant),
                    title: const Text("Block pop-ups"),
                    subtitle: const Text("Prevent unwanted pop-up windows"),
                    value: blockPopups,
                    onChanged: (v) {
                      setState(() => blockPopups = v);
                      _save('block_popups', v);
                    },
                  ),
                  const Divider(height: 1, indent: 56),
                  SwitchListTile(
                    secondary: Icon(Icons.history_rounded, color: colors.onSurfaceVariant),
                    title: const Text("Save browsing history"),
                    subtitle: const Text("Sites are auto-deleted after 3 days regardless"),
                    value: saveHistory,
                    onChanged: (v) {
                      setState(() => saveHistory = v);
                      _save('save_history', v);
                    },
                  ),
                  const Divider(height: 1, indent: 56),
                  SwitchListTile(
                    secondary: Icon(Icons.block_rounded, color: colors.onSurfaceVariant),
                    title: const Text("Block ads"),
                    subtitle: const Text("Blocks common ad and tracker domains"),
                    value: adBlockEnabled,
                    onChanged: (v) {
                      setState(() => adBlockEnabled = v);
                      _save('ad_block_enabled', v);
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
