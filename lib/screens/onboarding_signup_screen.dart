import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import 'browser_home.dart';
import 'onboarding_sync_screen.dart';

class OnboardingSignupScreen extends StatefulWidget {
  const OnboardingSignupScreen({super.key});

  @override
  State<OnboardingSignupScreen> createState() => _OnboardingSignupScreenState();
}

class _OnboardingSignupScreenState extends State<OnboardingSignupScreen> {
  bool _loading = false;

  Future<void> _markOnboardingSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_onboarding', true);
  }

  Future<void> _skip() async {
    await _markOnboardingSeen();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const BrowserHome()),
    );
  }

  Future<void> _signUp() async {
    setState(() => _loading = true);
    final user = await AuthService.signInWithGoogle();
    if (!mounted) return;
    setState(() => _loading = false);

    if (user != null) {
      // Signed up successfully -> show the sync screen next.
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const OnboardingSyncScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Sign up cancelled or failed")),
      );
    }
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
              Hero(
                tag: 'nexa_icon',
                child: Image.asset('assets/icon/icon.png', width: 110, height: 110),
              ),
              const SizedBox(height: 40),
              Text(
                "Make Nexa your own",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colors.onSurface,
                  fontSize: 26,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                "Sign up to get your bookmarks, history and\nmore on all your devices",
                textAlign: TextAlign.center,
                style: TextStyle(color: colors.onSurfaceVariant, fontSize: 15, height: 1.4),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: colors.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.phonelink_lock_rounded, size: 16, color: colors.onSurfaceVariant),
                    const SizedBox(width: 8),
                    Text(
                      "Your data stays on this device either way",
                      style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const Spacer(flex: 4),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: _loading ? null : _signUp,
                  child: _loading
                      ? SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: colors.onPrimary,
                          ),
                        )
                      : const Text(
                          "Sign Up",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                ),
              ),
              const SizedBox(height: 18),
              TextButton(
                onPressed: _loading ? null : _skip,
                child: const Text("Skip", style: TextStyle(fontSize: 16)),
              ),
              const SizedBox(height: 24),
              Text(
                "By continuing, you agree to the Terms of Service.",
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
