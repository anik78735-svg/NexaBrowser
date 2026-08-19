//lib/widgets/nexa_toolbar.dart//
import 'package:flutter/material.dart';

class NexaToolbar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback onHome;
  final String addressText;
  final VoidCallback onAddressTap;
  final VoidCallback onNewTab;
  final int tabCount;
  final VoidCallback onTabSwitcherTap;
  final VoidCallback onMenuTap;
  final bool isIncognito;

  // True while the active tab is showing the native New Tab / home page,
  // which already has its own large "Search Nexa or type a URL" pill.
  // When true, this toolbar's own address chip is rendered as a compact
  // icon-only button instead of repeating the exact same placeholder
  // text — otherwise the home page visibly showed two search bars
  // stacked on top of each other with identical text.
  final bool isHomePage;

  const NexaToolbar({
    super.key,
    required this.onHome,
    required this.addressText,
    required this.onAddressTap,
    required this.onNewTab,
    required this.tabCount,
    required this.onTabSwitcherTap,
    required this.onMenuTap,
    this.isIncognito = false,
    this.isHomePage = false,
  });

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return SafeArea(
      child: Container(
        // Fully theme-driven: light mode -> white/near-white surface,
        // dark mode -> the app's dark surface. Incognito tabs get a
        // distinct purple tint layered on top either way.
        color: isIncognito
            ? Color.alphaBlend(const Color(0x332B1B3D), colors.surface)
            : colors.surface,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: [
              IconButton(
                icon: Icon(Icons.home, size: 20, color: colors.onSurfaceVariant),
                onPressed: onHome,
              ),
              Expanded(
                child: GestureDetector(
                  onTap: onAddressTap,
                  child: isHomePage
                      ? Container(
                          height: 38,
                          alignment: Alignment.centerLeft,
                          child: Icon(
                            Icons.search_rounded,
                            size: 18,
                            color: colors.onSurfaceVariant,
                          ),
                        )
                      : Container(
                          height: 38,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: colors.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                addressText.startsWith('https://')
                                    ? Icons.lock_outline_rounded
                                    : Icons.search_rounded,
                                size: 14,
                                color: colors.onSurfaceVariant,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  addressText.isEmpty
                                      ? "Search Nexa or type a URL"
                                      : addressText,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: addressText.isEmpty
                                        ? colors.onSurfaceVariant
                                        : colors.onSurface,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.add, size: 20, color: colors.onSurfaceVariant),
                onPressed: onNewTab,
              ),
              InkWell(
                onTap: onTabSwitcherTap,
                borderRadius: BorderRadius.circular(5),
                child: Container(
                  width: 24,
                  height: 24,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    border: Border.all(color: colors.onSurfaceVariant, width: 1.2),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    "$tabCount",
                    style: TextStyle(fontSize: 10, color: colors.onSurface),
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.more_vert, size: 20, color: colors.onSurfaceVariant),
                onPressed: onMenuTap,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
