import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

void showBrowserMenu(
  BuildContext context, {
  required VoidCallback onBack,
  required VoidCallback onShare,
  required VoidCallback onForward,
  required VoidCallback onReload,
  required VoidCallback onAIMode,
  required bool isBookmarked,
  required VoidCallback onToggleBookmark,
  required VoidCallback onNewTab,
  required VoidCallback onNewIncognitoTab,
  required bool isDesktop,
  required VoidCallback onToggleDesktop,
  required bool isAdBlockEnabled,
  required VoidCallback onToggleAdBlock,
  required VoidCallback onHistory,
  required VoidCallback onDeleteBrowsingData,
  required VoidCallback onDownloads,
  required VoidCallback onBookmarks,
  required VoidCallback onFindInPage,
  required VoidCallback onTranslate,
  required VoidCallback onProfile,
  required VoidCallback onSettings,
  required VoidCallback onHelpFeedback,
}) {
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: "menu",
    barrierColor: Colors.black.withOpacity(0.3),
    transitionDuration: const Duration(milliseconds: 150),
    pageBuilder: (ctx, anim1, anim2) {
      final colors = Theme.of(ctx).colorScheme;
      return SafeArea(
        child: Align(
          alignment: Alignment.topRight,
          child: Padding(
            padding: const EdgeInsets.only(top: 50, right: 6),
            child: Material(
              color: colors.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(16),
              elevation: 6,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 270, maxHeight: 600),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _circleIcon(ctx, Icons.arrow_back, "Back", () {
                            Navigator.pop(ctx);
                            onBack();
                          }),
                          _circleIcon(ctx, Icons.arrow_forward, "Forward", () {
                            Navigator.pop(ctx);
                            onForward();
                          }),
                          _circleIcon(ctx, Icons.refresh, "Reload", () {
                            Navigator.pop(ctx);
                            onReload();
                          }),
                          _circleIcon(
                            ctx,
                            isBookmarked ? Icons.star_rounded : Icons.star_border_rounded,
                            "Bookmark",
                            () {
                              Navigator.pop(ctx);
                              onToggleBookmark();
                            },
                            color: isBookmarked ? Colors.amber : null,
                          ),
                          _circleIcon(ctx, Icons.share_rounded, "Share", () {
                            Navigator.pop(ctx);
                            onShare();
                          }),
                        ],
                      ),
                      const Divider(height: 20),
                      _tile(ctx, Icons.auto_awesome_rounded, "AI Mode", () {
                        Navigator.pop(ctx);
                        onAIMode();
                      }, color: colors.tertiary),
                      _tile(ctx, Icons.add_rounded, "New Tab", () {
                        Navigator.pop(ctx);
                        onNewTab();
                      }),
                      _tile(ctx, Icons.visibility_off_rounded, "New Incognito Tab", () {
                        Navigator.pop(ctx);
                        onNewIncognitoTab();
                      }),
                      _tile(ctx, Icons.history_rounded, "History", () {
                        Navigator.pop(ctx);
                        onHistory();
                      }),
                      _tile(ctx, Icons.delete_outline_rounded, "Delete browsing data", () {
                        Navigator.pop(ctx);
                        onDeleteBrowsingData();
                      }),
                      _tile(ctx, Icons.search_rounded, "Find in page", () {
                        Navigator.pop(ctx);
                        onFindInPage();
                      }),
                      _tile(ctx, Icons.translate_rounded, "Translate...", () {
                        Navigator.pop(ctx);
                        onTranslate();
                      }),
                      _tile(ctx, Icons.bookmark_border_rounded, "Bookmarks", () {
                        Navigator.pop(ctx);
                        onBookmarks();
                      }),
                      _tile(ctx, Icons.download_rounded, "Downloads", () {
                        Navigator.pop(ctx);
                        onDownloads();
                      }),
                      const Divider(height: 20),
                      //-------------------------------------------------
                      // Desktop site tile — with a tick/untick checkbox
                      // alongside it (checked = desktop mode, unchecked
                      // = mobile mode). Tapping anywhere on the row (or
                      // the checkbox itself) toggles it.
                      //-------------------------------------------------
                      ListTile(
                        dense: true,
                        leading: Icon(
                          isDesktop ? Icons.desktop_windows_rounded : Icons.smartphone_rounded,
                          size: 20,
                        ),
                        title: const Text("Desktop site", style: TextStyle(fontSize: 13)),
                        trailing: Checkbox(
                          value: isDesktop,
                          activeColor: colors.primary,
                          onChanged: (_) {
                            Navigator.pop(ctx);
                            onToggleDesktop();
                          },
                        ),
                        onTap: () {
                          Navigator.pop(ctx);
                          onToggleDesktop();
                        },
                      ),
                      //-------------------------------------------------
                      // Ad blocker — same pattern as Desktop site above,
                      // so it's a one-tap toggle right from the menu
                      // instead of a trip through Settings.
                      //-------------------------------------------------
                      ListTile(
                        dense: true,
                        leading: Icon(
                          isAdBlockEnabled ? Icons.block_rounded : Icons.block_outlined,
                          size: 20,
                          color: isAdBlockEnabled ? colors.primary : null,
                        ),
                        title: const Text("Ad blocker", style: TextStyle(fontSize: 13)),
                        trailing: Switch(
                          value: isAdBlockEnabled,
                          onChanged: (_) {
                            Navigator.pop(ctx);
                            onToggleAdBlock();
                          },
                        ),
                        onTap: () {
                          Navigator.pop(ctx);
                          onToggleAdBlock();
                        },
                      ),
                      const Divider(height: 20),
                      _tile(ctx, Icons.settings_outlined, "Settings", () {
                        Navigator.pop(ctx);
                        onSettings();
                      }),
                      _tile(ctx, Icons.help_outline_rounded, "Help and feedback", () {
                        Navigator.pop(ctx);
                        onHelpFeedback();
                      }),
                      ListTile(
                        dense: true,
                        leading: FirebaseAuth.instance.currentUser?.photoURL != null
                            ? CircleAvatar(
                                radius: 14,
                                backgroundImage: NetworkImage(
                                    FirebaseAuth.instance.currentUser!.photoURL!),
                              )
                            : const Icon(Icons.account_circle_outlined),
                        title: Text(
                          FirebaseAuth.instance.currentUser?.email ?? "Sign in",
                          style: const TextStyle(fontSize: 13),
                        ),
                        onTap: () {
                          Navigator.pop(ctx);
                          onProfile();
                        },
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    },
    transitionBuilder: (ctx, anim, secAnim, child) {
      return FadeTransition(opacity: anim, child: child);
    },
  );
}

Widget _tile(BuildContext context, IconData icon, String label, VoidCallback onTap, {Color? color}) {
  final colors = Theme.of(context).colorScheme;
  return ListTile(
    dense: true,
    leading: Icon(icon, color: color ?? colors.onSurfaceVariant, size: 20),
    title: Text(label, style: const TextStyle(fontSize: 13)),
    onTap: onTap,
  );
}

Widget _circleIcon(BuildContext context, IconData icon, String label, VoidCallback onTap,
    {Color? color}) {
  final colors = Theme.of(context).colorScheme;
  return Column(
    children: [
      InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: CircleAvatar(
          radius: 20,
          backgroundColor: colors.surfaceContainerHighest,
          child: Icon(icon, color: color ?? colors.onSurfaceVariant, size: 18),
        ),
      ),
      const SizedBox(height: 4),
      Text(label, style: TextStyle(color: colors.onSurfaceVariant, fontSize: 10)),
    ],
  );
}
