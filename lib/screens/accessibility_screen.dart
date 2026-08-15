import 'package:flutter/material.dart';
import '../services/browser_prefs.dart';

class AccessibilityScreen extends StatefulWidget {
  const AccessibilityScreen({super.key});
  @override
  State<AccessibilityScreen> createState() => _AccessibilityScreenState();
}

class _AccessibilityScreenState extends State<AccessibilityScreen> {
  double _zoom = 100;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final z = await BrowserPrefs.getTextZoom();
    if (mounted) setState(() => _zoom = z.toDouble());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Accessibility")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Page text size", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            const SizedBox(height: 6),
            const Text(
              "Applies to web pages you visit. Takes effect on the next page "
              "load or reload of open tabs.",
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            Slider(
              value: _zoom,
              min: 70,
              max: 150,
              divisions: 8,
              label: "${_zoom.round()}%",
              onChanged: (v) => setState(() => _zoom = v),
              onChangeEnd: (v) => BrowserPrefs.setTextZoom(v.round()),
            ),
            Center(
              child: Text("${_zoom.round()}%", style: const TextStyle(fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }
}