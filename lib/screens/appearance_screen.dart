import 'package:flutter/material.dart';

class AppearanceScreen extends StatelessWidget {
  const AppearanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text("Appearance")),
      body: ListView(
        children: [
          ListTile(
            leading: Icon(Icons.dark_mode, color: colors.primary),
            title: const Text("Dark"),
            subtitle: const Text("Nexa currently only offers a dark theme."),
            trailing: Icon(Icons.check_circle, color: colors.primary),
          ),
        ],
      ),
    );
  }
}