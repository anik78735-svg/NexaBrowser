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

  // NEW
  final bool isIncognito;

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
  });

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        color: isIncognito ? const Color(0xFF2B1B3D) : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.home, size: 20),
                onPressed: onHome,
              ),
              Expanded(
                child: GestureDetector(
                  onTap: onAddressTap,
                  child: Container(
                    height: 38,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF303134),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.lock,
                          size: 14,
                          color: Colors.grey,
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
                                  ? Colors.grey
                                  : Colors.white,
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
                icon: const Icon(Icons.add, size: 20),
                onPressed: onNewTab,
              ),
              InkWell(
                onTap: onTabSwitcherTap,
                child: Container(
                  width: 24,
                  height: 24,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.grey,
                      width: 1.2,
                    ),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    "$tabCount",
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.more_vert, size: 20),
                onPressed: onMenuTap,
              ),
            ],
          ),
        ),
      ),
    );
  }
}