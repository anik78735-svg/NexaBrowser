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
    return Scaffold(
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

                // UPDATED BORDER
                border: Border.all(
                  color: isActive
                      ? (tab.isIncognito
                          ? Colors.purpleAccent
                          : Colors.blueAccent)
                      : Colors.grey.shade800,
                  width: isActive ? 2 : 1,
                ),

                color: const Color(0xFF303134),
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
                              : Colors.grey,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            tab.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => onCloseTab(index),
                          child: const Icon(
                            Icons.close,
                            size: 16,
                            color: Colors.grey,
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
                      child: tab.thumbnail != null
                          ? Image.memory(
                              tab.thumbnail!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                            )
                          : Container(
                              color: const Color(0xFF202124),
                              alignment: Alignment.center,
                              child: Icon(
                                tab.isIncognito
                                    ? Icons.visibility_off
                                    : Icons.public,
                                color: tab.isIncognito
                                    ? Colors.purpleAccent
                                    : Colors.grey,
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