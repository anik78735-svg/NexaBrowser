import 'package:flutter/material.dart';
import '../services/browser_prefs.dart';

class AddressBarScreen extends StatefulWidget {
  const AddressBarScreen({super.key});
  @override
  State<AddressBarScreen> createState() => _AddressBarScreenState();
}

class _AddressBarScreenState extends State<AddressBarScreen> {
  bool _top = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final v = await BrowserPrefs.getAddressBarTop();
    if (mounted) setState(() => _top = v);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Address bar")),
      body: Column(
        children: [
          RadioListTile<bool>(
            title: const Text("Top"),
            value: true,
            groupValue: _top,
            onChanged: (v) {
              setState(() => _top = v!);
              BrowserPrefs.setAddressBarTop(v!);
            },
          ),
          RadioListTile<bool>(
            title: const Text("Bottom"),
            value: false,
            groupValue: _top,
            onChanged: (v) {
              setState(() => _top = v!);
              BrowserPrefs.setAddressBarTop(v!);
            },
          ),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              "Your choice is saved now. To actually move the toolbar to "
              "the bottom of the screen, send nexa_toolbar.dart — it needs "
              "a small change there since it's currently built as an "
              "AppBar.",
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}