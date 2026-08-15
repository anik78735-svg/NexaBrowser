import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'browser_home.dart';

class OnboardingSyncScreen extends StatefulWidget {
  const OnboardingSyncScreen({super.key});

  @override
  State<OnboardingSyncScreen> createState() => _OnboardingSyncScreenState();
}

class _OnboardingSyncScreenState extends State<OnboardingSyncScreen> {
  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_onboarding', true);
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const BrowserHome()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              const Spacer(flex: 3),
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.sync_rounded, color: colors.onPrimaryContainer, size: 44),
              ),
              const SizedBox(height: 40),
              Text(
                "Save time, type less",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colors.onSurface,
                  fontSize: 26,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                "To quickly get back to sites that you've visited,\nsync your history and tabs",
                textAlign: TextAlign.center,
                style: TextStyle(color: colors.onSurfaceVariant, fontSize: 15, height: 1.4),
              ),
              const Spacer(flex: 4),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: _finish,
                  child: const Text(
                    "Yes, I'm in",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              TextButton(
                onPressed: _finish,
                child: const Text("No, thanks", style: TextStyle(fontSize: 16)),
              ),
              const SizedBox(height: 24),
              Text(
                "You can stop syncing at any time in Settings.",
                textAlign: TextAlign.center,
                style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
