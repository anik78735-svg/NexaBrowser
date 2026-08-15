import 'package:flutter/material.dart';
import '../services/browser_prefs.dart';

class SearchEngineScreen extends StatefulWidget {
  const SearchEngineScreen({super.key});
  @override
  State<SearchEngineScreen> createState() => _SearchEngineScreenState();
}

class _SearchEngineScreenState extends State<SearchEngineScreen> {
  String _selected = 'google';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final e = await BrowserPrefs.getSearchEngine();
    if (mounted) setState(() => _selected = e);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Search engine")),
      body: ListView(
        children: BrowserPrefs.searchEngineLabels.entries.map((e) {
          return RadioListTile<String>(
            title: Text(e.value),
            value: e.key,
            groupValue: _selected,
            onChanged: (v) {
              setState(() => _selected = v!);
              BrowserPrefs.setSearchEngine(v!);
            },
          );
        }).toList(),
      ),
    );
  }
}