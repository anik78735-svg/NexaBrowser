import 'package:flutter/material.dart';
import '../services/browser_prefs.dart';

class SiteSettingsScreen extends StatefulWidget {
  const SiteSettingsScreen({super.key});
  @override
  State<SiteSettingsScreen> createState() => _SiteSettingsScreenState();
}

class _SiteSettingsScreenState extends State<SiteSettingsScreen> {
  bool js = true, camera = false, mic = false, location = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    js = await BrowserPrefs.getJsEnabled();
    camera = await BrowserPrefs.getCameraAllowed();
    mic = await BrowserPrefs.getMicAllowed();
    location = await BrowserPrefs.getLocationAllowed();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Site settings")),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text("JavaScript"),
            subtitle: const Text("Most sites need this to work correctly"),
            value: js,
            onChanged: (v) {
              setState(() => js = v);
              BrowserPrefs.setJsEnabled(v);
            },
          ),
          SwitchListTile(
            title: const Text("Camera"),
            subtitle: const Text("Allow sites to ask for camera access"),
            value: camera,
            onChanged: (v) {
              setState(() => camera = v);
              BrowserPrefs.setCameraAllowed(v);
            },
          ),
          SwitchListTile(
            title: const Text("Microphone"),
            subtitle: const Text("Allow sites to ask for microphone access"),
            value: mic,
            onChanged: (v) {
              setState(() => mic = v);
              BrowserPrefs.setMicAllowed(v);
            },
          ),
          SwitchListTile(
            title: const Text("Location"),
            subtitle: const Text("Allow sites to ask for your location"),
            value: location,
            onChanged: (v) {
              setState(() => location = v);
              BrowserPrefs.setLocationAllowed(v);
            },
          ),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              "New tabs use these settings the next time they're opened.",
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}