import 'package:flutter/material.dart';
import '../services/browser_prefs.dart';

class TabsSettingsScreen extends StatefulWidget {
  const TabsSettingsScreen({super.key});
  @override
  State<TabsSettingsScreen> createState() => _TabsSettingsScreenState();
}

class _TabsSettingsScreenState extends State<TabsSettingsScreen> {
  bool warnClose = true, showCount = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    warnClose = await BrowserPrefs.getWarnBeforeCloseAll();
    showCount = await BrowserPrefs.getShowTabCount();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Tabs and tab groups")),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text("Warn before closing all tabs"),
            value: warnClose,
            onChanged: (v) {
              setState(() => warnClose = v);
              BrowserPrefs.setWarnBeforeCloseAll(v);
            },
          ),
          SwitchListTile(
            title: const Text("Show tab count on icon"),
            value: showCount,
            onChanged: (v) {
              setState(() => showCount = v);
              BrowserPrefs.setShowTabCount(v);
            },
          ),
        ],
      ),
    );
  }
}