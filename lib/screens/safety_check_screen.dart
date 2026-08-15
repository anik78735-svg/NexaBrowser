import 'package:flutter/material.dart';
import '../services/browser_prefs.dart';
import '../services/password_service.dart';
import 'password_manager_screen.dart';

class SafetyCheckScreen extends StatefulWidget {
  const SafetyCheckScreen({super.key});
  @override
  State<SafetyCheckScreen> createState() => _SafetyCheckScreenState();
}

class _SafetyCheckScreenState extends State<SafetyCheckScreen> {
  bool _checking = true;
  bool adBlockOn = true;
  bool jsOn = true;
  int savedPasswordCount = 0;

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    adBlockOn = await BrowserPrefs.getAdBlockEnabled();
    jsOn = await BrowserPrefs.getJsEnabled();
    final list = await PasswordService.getAll();
    savedPasswordCount = list.length;
    if (mounted) setState(() => _checking = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Safety check")),
      body: _checking
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _statusTile(
                  Icons.shield_outlined,
                  "Ad & tracker blocking",
                  adBlockOn ? "Enabled" : "Disabled — turn on in Privacy and security",
                  adBlockOn,
                ),
                _statusTile(
                  Icons.javascript_outlined,
                  "JavaScript",
                  jsOn ? "Enabled (recommended for most sites)" : "Disabled",
                  true,
                ),
                _statusTile(
                  Icons.lock_outline,
                  "Saved passwords",
                  "$savedPasswordCount saved — review any you don't recognise",
                  true,
                ),
                const SizedBox(height: 8),
                ListTile(
                  leading: const Icon(Icons.password),
                  title: const Text("Open Password Manager"),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PasswordManagerScreen()),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _statusTile(IconData icon, String title, String subtitle, bool good) {
    return ListTile(
      leading: Icon(icon, color: good ? Colors.greenAccent : Colors.orangeAccent),
      title: Text(title),
      subtitle: Text(subtitle),
    );
  }
}