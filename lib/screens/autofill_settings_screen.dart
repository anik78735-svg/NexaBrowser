import 'package:flutter/material.dart';

class AutofillSettingsScreen extends StatelessWidget {
  const AutofillSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text("Autofill services")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Text(
          "Nexa's WebView is now hooked up to Android's Autofill "
          "Framework, so saved addresses, cards and logins from your "
          "phone's autofill service will show up as suggestions when "
          "you tap a form field on a website — the same way they do in "
          "other apps.\n\n"
          "Which service provides those suggestions (Google, your "
          "password manager, etc.) is still chosen in Android itself, "
          "not per-app: phone Settings > System > Languages & input > "
          "Autofill service.\n\n"
          "For website passwords specifically, you can also use the "
          "Nexa Password Manager under Settings > Passwords and "
          "autofill.",
          style: TextStyle(color: colors.onSurfaceVariant, fontSize: 14, height: 1.5),
        ),
      ),
    );
  }
}