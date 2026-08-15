import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/default_browser_service.dart';

/// Shows a "Set Nexa as your default browser?" card once, the first time
/// the user reaches the home page. Safe to call every time BrowserHome
/// loads — it checks the SharedPreferences flag internally and no-ops if
/// already shown, and also skips itself entirely if Nexa is already the
/// default (or on iOS, where this can't be asked for up front).
Future<void> maybeShowDefaultBrowserPrompt(BuildContext context) async {
  final prefs = await SharedPreferences.getInstance();
  final alreadyShown = prefs.getBool('has_seen_default_browser_prompt') ?? false;
  if (alreadyShown) return;

  final alreadyDefault = await DefaultBrowserService.isDefault();
  await prefs.setBool('has_seen_default_browser_prompt', true);
  if (alreadyDefault) return;
  if (!context.mounted) return;

  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => const _DefaultBrowserPromptCard(),
  );
}

class _DefaultBrowserPromptCard extends StatelessWidget {
  const _DefaultBrowserPromptCard();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: colors.primaryContainer,
              child: Icon(Icons.public_rounded, color: colors.onPrimaryContainer, size: 28),
            ),
            const SizedBox(height: 20),
            Text(
              "Make Nexa your default browser",
              style: TextStyle(
                color: colors.onSurface,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "Links from emails, messages and other apps will open "
              "straight in Nexa — with ad blocking already built in.",
              style: TextStyle(color: colors.onSurfaceVariant, fontSize: 14, height: 1.4),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Not now"),
                ),
                const SizedBox(width: 6),
                FilledButton(
                  onPressed: () {
                    Navigator.pop(context);
                    DefaultBrowserService.openSettings();
                  },
                  child: const Text("Set as default"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
