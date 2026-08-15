import 'package:flutter/material.dart';
import '../theme_controller.dart';

class AppearanceScreen extends StatelessWidget {
  const AppearanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Appearance")),
      body: ValueListenableBuilder<ThemeMode>(
        valueListenable: ThemeController.themeMode,
        builder: (context, mode, _) {
          return ListView(
            children: [
              RadioListTile<ThemeMode>(
                title: const Text("System default"),
                value: ThemeMode.system,
                groupValue: mode,
                onChanged: (v) => ThemeController.setThemeMode(v!),
              ),
              RadioListTile<ThemeMode>(
                title: const Text("Light"),
                value: ThemeMode.light,
                groupValue: mode,
                onChanged: (v) => ThemeController.setThemeMode(v!),
              ),
              RadioListTile<ThemeMode>(
                title: const Text("Dark"),
                value: ThemeMode.dark,
                groupValue: mode,
                onChanged: (v) => ThemeController.setThemeMode(v!),
              ),
            ],
          );
        },
      ),
    );
  }
}