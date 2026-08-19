import 'package:flutter/material.dart';
import '../services/history_service.dart';
import '../services/browser_prefs.dart';
import 'search_screen.dart';
import 'ai_chat_screen.dart';
import 'address_bar_screen.dart';
import 'appearance_screen.dart';

/// The real Nexa home page — a native Flutter screen, not a hosted web
/// page. Shown whenever a tab's url is kNexaNewTabUrl (see
/// browser_tab.dart / browser_home.dart).
class NewTabPage extends StatefulWidget {
  final Function(String url) onOpenUrl;
  final VoidCallback? onOpenIncognito;

  const NewTabPage({super.key, required this.onOpenUrl, this.onOpenIncognito});

  @override
  State<NewTabPage> createState() => _NewTabPageState();
}

class _NewTabPageState extends State<NewTabPage> {
  List<Map<String, dynamic>> mostVisited = [];
  bool _addressBarTop = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await HistoryService.getMostVisited(limit: 8);
    final addressTop = await BrowserPrefs.getAddressBarTop();
    if (mounted) {
      setState(() {
        mostVisited = data;
        _addressBarTop = addressTop;
      });
    }
  }

  Future<void> _openSearch() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => const SearchScreen(),
        fullscreenDialog: true,
      ),
    );
    if (result != null && result.isNotEmpty) {
      widget.onOpenUrl(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      color: colors.surface,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 24),
          child: Column(
            children: [
              const SizedBox(height: 48),

              //-------------------------------------------------------
              // Wordmark — deliberately large, same visual weight as
              // "Google" on a real browser's home page.
              //-------------------------------------------------------
              RichText(
                text: TextSpan(
                  style: TextStyle(
                    fontSize: 46,
                    fontWeight: FontWeight.w700,
                    color: colors.onSurface,
                    letterSpacing: -1,
                  ),
                  children: [
                    const TextSpan(text: "Nexa"),
                    TextSpan(text: ".", style: TextStyle(color: colors.primary)),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              //-------------------------------------------------------
              // Search pill.
              //-------------------------------------------------------
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: GestureDetector(
                  onTap: _openSearch,
                  child: Container(
                    height: 50,
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    decoration: BoxDecoration(
                      color: colors.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(26),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.search_rounded, size: 20, color: colors.onSurfaceVariant),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            "Search Nexa or type a URL",
                            style: TextStyle(color: colors.onSurfaceVariant, fontSize: 15),
                          ),
                        ),
                        Icon(Icons.mic_none_rounded, size: 20, color: colors.onSurfaceVariant),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 14),

              //-------------------------------------------------------
              // AI Mode + Incognito pills, side by side.
              //-------------------------------------------------------
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: _pillButton(
                        context,
                        icon: Icons.auto_awesome_rounded,
                        label: "AI Mode",
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const AIChatScreen()),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _pillButton(
                        context,
                        icon: Icons.visibility_off_rounded,
                        label: "Incognito",
                        onTap: widget.onOpenIncognito,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              //-------------------------------------------------------
              // Shortcuts grid — real, from actual browsing history.
              //-------------------------------------------------------
              if (mostVisited.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    "Sites you visit often will show up here",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: colors.onSurfaceVariant, fontSize: 13),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 8,
                      childAspectRatio: 0.78,
                    ),
                    itemCount: mostVisited.length,
                    itemBuilder: (context, index) {
                      final entry = mostVisited[index];
                      final url = entry['url'] as String;
                      final domain = entry['domain'] as String;

                      return GestureDetector(
                        onTap: () => widget.onOpenUrl(url),
                        child: Column(
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: colors.surfaceContainerHigh,
                                shape: BoxShape.circle,
                              ),
                              child: ClipOval(
                                child: Stack(
                                  alignment: Alignment.center,
                                  fit: StackFit.expand,
                                  children: [
                                    Icon(Icons.public_rounded, color: colors.onSurfaceVariant, size: 22),
                                    Image.network(
                                      'https://www.google.com/s2/favicons?domain=$domain&sz=128',
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                                      loadingBuilder: (_, child, progress) =>
                                          progress == null ? child : const SizedBox.shrink(),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              domain,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: TextStyle(color: colors.onSurfaceVariant, fontSize: 11),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

              const SizedBox(height: 32),

              //-------------------------------------------------------
              // Nexa tips — real, tappable shortcuts into Settings,
              // not decorative placeholder text.
              //-------------------------------------------------------
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Card(
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
                        child: Row(
                          children: [
                            Text(
                              "Nexa tips",
                              style: TextStyle(
                                color: colors.onSurface,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ListTile(
                        leading: CircleAvatar(
                          radius: 18,
                          backgroundColor: colors.primaryContainer,
                          child: Icon(Icons.stay_current_portrait_rounded,
                              color: colors.onPrimaryContainer, size: 18),
                        ),
                        title: const Text("Choose address bar position", style: TextStyle(fontSize: 14)),
                        subtitle: Text(
                          "Currently: ${_addressBarTop ? 'Top' : 'Bottom'}",
                          style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12),
                        ),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const AddressBarScreen()),
                        ).then((_) => _load()),
                      ),
                      const Divider(height: 1, indent: 56),
                      ListTile(
                        leading: CircleAvatar(
                          radius: 18,
                          backgroundColor: colors.tertiaryContainer,
                          child: Icon(Icons.palette_rounded, color: colors.onTertiaryContainer, size: 18),
                        ),
                        title: const Text("Switch light or dark theme", style: TextStyle(fontSize: 14)),
                        subtitle: const Text("Pick what's comfortable for your eyes",
                            style: TextStyle(fontSize: 12)),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const AppearanceScreen()),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pillButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    VoidCallback? onTap,
  }) {
    final colors = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 42,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: colors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(21),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: colors.onSurfaceVariant),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(color: colors.onSurface, fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}
