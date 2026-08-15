import 'package:flutter/material.dart';
import '../services/browser_prefs.dart';

class NotificationsSettingsScreen extends StatefulWidget {
  const NotificationsSettingsScreen({super.key});
  @override
  State<NotificationsSettingsScreen> createState() =>
      _NotificationsSettingsScreenState();
}

class _NotificationsSettingsScreenState extends State<NotificationsSettingsScreen> {
  bool enabled = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    enabled = await BrowserPrefs.getNotificationsEnabled();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Notifications")),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text("Nexa notifications"),
            subtitle: const Text("Downloads, sync, and other in-app alerts"),
            value: enabled,
            onChanged: (v) {
              setState(() => enabled = v);
              BrowserPrefs.setNotificationsEnabled(v);
            },
          ),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              "To allow or block notifications at the phone's system level, "
              "go to Settings > Apps > Nexa Browser > Notifications.",
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}