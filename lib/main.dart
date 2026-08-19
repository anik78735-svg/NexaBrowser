import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/splash_screen.dart';
import 'services/download_service.dart';
import 'services/history_service.dart';
import 'theme/app_theme.dart';
import 'theme_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await ThemeController.load();
  // Restores the downloads list that was saved to the device on the
  // previous run, so it doesn't come back empty after a restart.
  await DownloadService.init();
  // One-time cleanup of the old Vercel-hosted "home page" History rows
  // left over from a previous build (see HistoryService for details) —
  // safe/no-op once they're gone.
  await HistoryService.purgeLegacyHomeUrl();
  runApp(const NexaBrowserApp());
}

class NexaBrowserApp extends StatelessWidget {
  const NexaBrowserApp({super.key});
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.themeMode,
      builder: (context, mode, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: "Nexa Browser",
          themeMode: mode,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          home: const SplashScreen(),
        );
      },
    );
  }
}