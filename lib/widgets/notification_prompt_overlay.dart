import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Shows a Chrome-style "notifications make things easier" card once,
/// the first time the user reaches the home page. Safe to call every time
/// BrowserHome loads -- it checks the SharedPreferences flag internally
/// and no-ops if already shown.
Future<void> maybeShowNotificationPrompt(BuildContext context) async {
  final prefs = await SharedPreferences.getInstance();
  final alreadyShown = prefs.getBool('has_seen_notification_prompt') ?? false;
  if (alreadyShown) return;

  await prefs.setBool('has_seen_notification_prompt', true);
  if (!context.mounted) return;

  await showDialog(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => const _NotificationPromptCard(),
  );
}

class _NotificationPromptCard extends StatelessWidget {
  const _NotificationPromptCard();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: colors.outlineVariant),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  _mockRow(context, Icons.volume_up_rounded, const Color(0xFF4285F4)),
                  const SizedBox(height: 10),
                  _mockRow(context, Icons.theater_comedy_rounded, const Color(0xFF34A853)),
                  const SizedBox(height: 10),
                  _mockRow(context, Icons.file_download_rounded, const Color(0xFFFBBC05)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "Nexa notifications make things easier",
              style: TextStyle(
                color: colors.onSurface,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "You'll be able to easily manage media controls, "
              "incognito sessions, downloads and more",
              style: TextStyle(color: colors.onSurfaceVariant, fontSize: 14, height: 1.4),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("No, thanks"),
                ),
                const SizedBox(width: 6),
                FilledButton(
                  onPressed: () {
                    Navigator.pop(context);
                    // If you later add the `permission_handler` package,
                    // request the real OS notification permission here.
                  },
                  child: const Text("Continue"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _mockRow(BuildContext context, IconData icon, Color color) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      children: [
        CircleAvatar(radius: 14, backgroundColor: color, child: Icon(icon, size: 14, color: Colors.white)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 8,
                color: colors.surfaceContainerHighest,
                margin: const EdgeInsets.only(bottom: 4),
              ),
              Container(height: 8, width: 100, color: colors.surfaceContainerHighest),
            ],
          ),
        ),
      ],
    );
  }
}
