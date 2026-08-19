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
                constraints: const BoxConstraints(maxWidth: 280, maxHeight: 640),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 8),
                      //-------------------------------------------------
                      // Page actions — one per line now, each with a
                      // soft outline-circle icon, same visual language
                      // as every other row below instead of a separate
                      // horizontal icon strip.
                      //-------------------------------------------------
                      _tile(ctx, Icons.arrow_back_rounded, "Back", () {
                        Navigator.pop(ctx);
                        onBack();
                      }),
                      _tile(ctx, Icons.arrow_forward_rounded, "Forward", () {
                        Navigator.pop(ctx);
                        onForward();
                      }),
                      _tile(ctx, Icons.refresh_rounded, "Reload", () {
                        Navigator.pop(ctx);
                        onReload();
                      }),
                      _tile(
                        ctx,
                        isBookmarked ? Icons.star_rounded : Icons.star_border_rounded,
                        isBookmarked ? "Bookmarked" : "Bookmark",
                        () {
                          Navigator.pop(ctx);
                          onToggleBookmark();
                        },
                        color: isBookmarked ? Colors.amber : null,
                      ),
                      _tile(ctx, Icons.share_rounded, "Share", () {
                        Navigator.pop(ctx);
                        onShare();
                      }),
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
                        leading: _softCircle(
                          ctx,
                          isDesktop ? Icons.desktop_windows_rounded : Icons.smartphone_rounded,
                          color: isDesktop ? colors.primary : null,
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
                        leading: _softCircle(
                          ctx,
                          isAdBlockEnabled ? Icons.block_rounded : Icons.block_outlined,
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
                                radius: 16,
                                backgroundImage: NetworkImage(
                                    FirebaseAuth.instance.currentUser!.photoURL!),
                              )
                            : _softCircle(ctx, Icons.account_circle_outlined),
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

//---------------------------------------------------------------------
// A single menu row: soft-bordered circle icon + label, one per line.
// Every row in the menu (page actions included) now shares this exact
// look instead of the old separate icon-strip style.
//---------------------------------------------------------------------
Widget _tile(BuildContext context, IconData icon, String label, VoidCallback onTap, {Color? color}) {
  return ListTile(
    dense: true,
    leading: _softCircle(context, icon, color: color),
    title: Text(label, style: const TextStyle(fontSize: 13)),
    onTap: onTap,
  );
}

//---------------------------------------------------------------------
// The light/soft outline-circle treatment: a thin, low-contrast border
// with a transparent (or barely-tinted) fill — not a solid filled
// circle — so the icon reads as gently outlined rather than a heavy
// filled badge.
//---------------------------------------------------------------------
Widget _softCircle(BuildContext context, IconData icon, {Color? color}) {
  final colors = Theme.of(context).colorScheme;
  final iconColor = color ?? colors.onSurfaceVariant;
  return Container(
    width: 32,
    height: 32,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: (color ?? colors.onSurface).withOpacity(0.05),
      border: Border.all(
        color: (color ?? colors.outline).withOpacity(0.35),
        width: 1,
      ),
    ),
    child: Icon(icon, size: 16, color: iconColor),
  );
}
