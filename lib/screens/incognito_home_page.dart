import 'package:flutter/material.dart';
import 'search_screen.dart';

/// Shown as the "home" of every incognito tab — same information Chrome
/// shows on its own incognito new-tab page, so the user actually knows
/// what is and isn't private before they start browsing.
class IncognitoHomePage extends StatelessWidget {
  final Function(String url) onOpenUrl;

  const IncognitoHomePage({super.key, required this.onOpenUrl});

  Future<void> _openSearch(BuildContext context) async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => const SearchScreen(),
        fullscreenDialog: true,
      ),
    );
    if (result != null && result.isNotEmpty) onOpenUrl(result);
  }

  @override
  Widget build(BuildContext context) {
    // Deliberately fixed dark palette regardless of app theme — this is
    // how every browser's incognito surface signals "different mode"
    // at a glance, light or dark theme otherwise.
    const bg = Color(0xFF1F1F1F);
    const card = Color(0xFF2A2A2A);
    const textPrimary = Colors.white;
    const textSecondary = Color(0xFFB0B0B0);
    const accent = Color(0xFF8AB4F8);

    return Container(
      color: bg,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            children: [
              const SizedBox(height: 24),
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: card,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.theater_comedy_rounded, color: textPrimary, size: 34),
              ),
              const SizedBox(height: 20),
              const Text(
                "You've gone incognito",
                textAlign: TextAlign.center,
                style: TextStyle(color: textPrimary, fontSize: 22, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 14),
              const Text(
                "Now you can browse privately, and other people who use "
                "this device won't see your activity. Screenshots and "
                "screen recording are blocked in this tab.",
                textAlign: TextAlign.center,
                style: TextStyle(color: textSecondary, fontSize: 13, height: 1.5),
              ),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: card,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _bulletHeader("Nexa won't save", textPrimary),
                    const SizedBox(height: 6),
                    _bullet("Your browsing history", textSecondary),
                    _bullet("Cookies and site data", textSecondary),
                    _bullet("Information entered in forms", textSecondary),
                    const SizedBox(height: 14),
                    _bulletHeader("Your activity might still be visible to", textPrimary),
                    const SizedBox(height: 6),
                    _bullet("Websites that you visit", textSecondary),
                    _bullet("Your employer or school network", textSecondary),
                    _bullet("Your internet service provider", textSecondary),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              GestureDetector(
                onTap: () => _openSearch(context),
                child: Container(
                  height: 46,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: card,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.search_rounded, size: 18, color: textSecondary),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          "Search privately",
                          style: TextStyle(color: textSecondary, fontSize: 14),
                        ),
                      ),
                      Icon(Icons.visibility_off_rounded, size: 16, color: accent),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bulletHeader(String text, Color color) => Text(
        text,
        style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w600),
      );

  Widget _bullet(String text, Color color) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("•  ", style: TextStyle(color: color, fontSize: 12)),
            Expanded(child: Text(text, style: TextStyle(color: color, fontSize: 12, height: 1.4))),
          ],
        ),
      );
}
