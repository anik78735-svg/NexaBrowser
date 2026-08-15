import 'package:flutter/material.dart';
import '../services/browser_prefs.dart';

class LanguagesScreen extends StatefulWidget {
  const LanguagesScreen({super.key});
  @override
  State<LanguagesScreen> createState() => _LanguagesScreenState();
}

class _LanguagesScreenState extends State<LanguagesScreen> {
  String _lang = 'en';

  static const _options = {
    'en': 'English',
    'hi': 'हिन्दी (Hindi)',
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final v = await BrowserPrefs.getLanguage();
    if (mounted) setState(() => _lang = v);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Languages")),
      body: Column(
        children: [
          ..._options.entries.map(
            (e) => RadioListTile<String>(
              title: Text(e.value),
              value: e.key,
              groupValue: _lang,
              onChanged: (v) {
                setState(() => _lang = v!);
                BrowserPrefs.setLanguage(v!);
              },
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              "Saves your preferred language. Translating the app's own "
              "menus and screens needs Flutter's localization setup "
              "(.arb files) — a separate task, just say the word and "
              "we'll add it.",
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}