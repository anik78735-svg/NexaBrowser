import 'package:flutter/material.dart';

class AutofillSettingsScreen extends StatelessWidget {
  const AutofillSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Autofill services")),
      body: const Padding(
        padding: EdgeInsets.all(20),
        child: Text(
          "Form autofill (name, address, payment info) is managed by "
          "Android's system Autofill service, not by individual apps — "
          "this can't be switched from inside Nexa Browser.\n\n"
          "To choose or manage your autofill service: phone Settings > "
          "System > Languages & input > Autofill service.\n\n"
          "For website passwords specifically, use the Nexa Password "
          "Manager under Settings > Passwords and autofill instead.",
          style: TextStyle(color: Colors.grey, fontSize: 14, height: 1.5),
        ),
      ),
    );
  }
}