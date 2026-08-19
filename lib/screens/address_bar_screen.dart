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

  Future<void> _set(bool top) async {
    setState(() => _top = top);
    await BrowserPrefs.setAddressBarTop(top);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text("Address bar")),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Card(
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  RadioListTile<bool>(
                    secondary: Icon(Icons.vertical_align_top_rounded, color: colors.onSurfaceVariant),
                    title: const Text("Top"),
                    value: true,
                    groupValue: _top,
                    onChanged: (v) => _set(v!),
                  ),
                  const Divider(height: 1, indent: 56),
                  RadioListTile<bool>(
                    secondary: Icon(Icons.vertical_align_bottom_rounded, color: colors.onSurfaceVariant),
                    title: const Text("Bottom"),
                    value: false,
                    groupValue: _top,
                    onChanged: (v) => _set(v!),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            child: Text(
              "Applies immediately across all your tabs.",
              style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
