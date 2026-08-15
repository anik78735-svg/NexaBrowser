import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpFeedbackScreen extends StatefulWidget {
  const HelpFeedbackScreen({super.key});

  // Single source of truth for the support inbox — every "send feedback"
  // entry point in the app (Settings > Help icon, Settings > Send
  // feedback, and this screen) routes through here so they can never
  // drift out of sync again.
  static const String supportEmail = "nexaaibrowser@gmail.com";

  @override
  State<HelpFeedbackScreen> createState() => _HelpFeedbackScreenState();
}

class _HelpTopic {
  final IconData icon;
  final String title;
  final String answer;
  const _HelpTopic(this.icon, this.title, this.answer);
}

class _HelpFeedbackScreenState extends State<HelpFeedbackScreen> {
  String _query = "";
  final _searchController = TextEditingController();

  static const _topics = [
    _HelpTopic(
      Icons.lock_outline_rounded,
      "Check if a site's connection is secure",
      "Look at the address bar: a padlock icon means the connection to "
          "that site is encrypted (HTTPS). If you see \"Not secure\" "
          "instead, avoid entering passwords or payment details on that "
          "page.",
    ),
    _HelpTopic(
      Icons.system_update_rounded,
      "Update Nexa Browser",
      "Open the app store you installed Nexa from (Play Store or App "
          "Store), search for \"Nexa Browser\", and tap Update if one is "
          "available. You can also turn on auto-updates from the store's "
          "settings.",
    ),
    _HelpTopic(
      Icons.cookie_outlined,
      "Delete, allow and manage cookies",
      "Go to Settings > Site settings to control cookies and permissions "
          "per site, or Settings > Privacy and security > \"Delete browsing "
          "data…\" from the History screen to clear everything at once.",
    ),
    _HelpTopic(
      Icons.wifi_off_rounded,
      "Fix connection and loading errors",
      "Check your Wi-Fi/mobile data, then pull down on the page to "
          "refresh. If one specific site fails, try clearing its cookies "
          "in Site settings, or reload in Desktop site mode from the "
          "browser menu.",
    ),
    _HelpTopic(
      Icons.download_outlined,
      "Download a file",
      "Tap a download link, or use the browser menu's Download option "
          "on the page you're viewing. Track progress and open finished "
          "files any time from Settings > Downloads.",
    ),
  ];

  List<_HelpTopic> get _filtered {
    if (_query.trim().isEmpty) return _topics;
    final q = _query.toLowerCase();
    return _topics.where((t) => t.title.toLowerCase().contains(q)).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openFeedbackEmail(BuildContext context) async {
    final uri = Uri(
      scheme: 'mailto',
      path: HelpFeedbackScreen.supportEmail,
      query: 'subject=${Uri.encodeComponent("Nexa Browser Feedback")}'
          '&body=${Uri.encodeComponent("Hi Nexa team,\n\n")}',
    );

    final launched = await launchUrl(uri);
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't open an email app")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final topics = _filtered;

    return Scaffold(
      appBar: AppBar(title: const Text("Help")),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: "Search help",
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
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Text(
              "Popular help resources",
              style: TextStyle(color: colors.onSurface, fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
          if (topics.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: Center(
                child: Text(
                  "No results for \"$_query\"",
                  style: TextStyle(color: colors.onSurfaceVariant),
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    for (int i = 0; i < topics.length; i++) ...[
                      if (i != 0) const Divider(height: 1, indent: 56),
                      _helpTile(context, topics[i]),
                    ],
                  ],
                ),
              ),
            ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Card(
              clipBehavior: Clip.antiAlias,
              child: ListTile(
                leading: CircleAvatar(
                  radius: 18,
                  backgroundColor: colors.primaryContainer,
                  child: Icon(Icons.feedback_rounded, color: colors.onPrimaryContainer, size: 18),
                ),
                title: const Text("Send feedback"),
                subtitle: const Text("Report a bug or share a suggestion — opens your email app"),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => _openFeedbackEmail(context),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _helpTile(BuildContext context, _HelpTopic topic) {
    final colors = Theme.of(context).colorScheme;
    return ExpansionTile(
      leading: CircleAvatar(
        radius: 18,
        backgroundColor: colors.surfaceContainerHighest,
        child: Icon(topic.icon, color: colors.onSurfaceVariant, size: 18),
      ),
      title: Text(topic.title, style: const TextStyle(fontSize: 14)),
      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      expandedAlignment: Alignment.centerLeft,
      children: [
        Text(
          topic.answer,
          style: TextStyle(color: colors.onSurfaceVariant, fontSize: 13, height: 1.5),
        ),
      ],
    );
  }
}
