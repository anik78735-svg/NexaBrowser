import 'package:flutter/material.dart';
import '../models/browser_tab.dart';

class TabSwitcherScreen extends StatelessWidget {
  final List<BrowserTab> tabs;
  final int activeTabIndex;
  final VoidCallback onAddNewTab;
  final VoidCallback onClose;
  final Function(int index) onSwitchToTab;
  final Function(int index) onCloseTab;

  const TabSwitcherScreen({
    super.key,
    required this.tabs,
    required this.activeTabIndex,
    required this.onAddNewTab,
    required this.onClose,
    required this.onSwitchToTab,
    required this.onCloseTab,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        title: Text("${tabs.length} Tabs"),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: onAddNewTab,
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: onClose,
          ),
        ],
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(10),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.72,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: tabs.length,
        itemBuilder: (context, index) {
          final tab = tabs[index];
          final isActive = index == activeTabIndex;

          return GestureDetector(
            onTap: () => onSwitchToTab(index),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isActive
                      ? (tab.isIncognito
                          ? Colors.purpleAccent
                          : colors.primary)
                      : colors.outlineVariant,
                  width: isActive ? 2 : 1,
                ),
                color: colors.surfaceContainerHigh,
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          tab.isIncognito
                              ? Icons.visibility_off
                              : Icons.public,
                          size: 14,
                          color: tab.isIncognito
                              ? Colors.purpleAccent
                              : colors.onSurfaceVariant,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            tab.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: colors.onSurface,
                              fontSize: 11,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => onCloseTab(index),
                          child: Icon(
                            Icons.close,
                            size: 16,
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(11),
                      ),
                      // Real page thumbnail, captured after each page load
                      // (see browser_home.dart onLoadStop) — falls back to
                      // a plain icon only for tabs that haven't loaded a
                      // page yet (e.g. a freshly-opened tab still on the
                      // native New Tab page).
                      child: tab.thumbnail != null
                          ? Image.memory(
                              tab.thumbnail!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              gaplessPlayback: true,
                            )
                          : Container(
                              color: colors.surfaceContainerHighest,
                              alignment: Alignment.center,
                              child: Icon(
                                tab.isIncognito
                                    ? Icons.visibility_off
                                    : Icons.public,
                                color: tab.isIncognito
                                    ? Colors.purpleAccent
                                    : colors.onSurfaceVariant,
                                size: 32,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}