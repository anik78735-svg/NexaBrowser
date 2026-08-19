//lib/screens/search_screen.dart//
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../services/history_service.dart';

class SearchScreen extends StatefulWidget {
  final String initialText;
  const SearchScreen({super.key, this.initialText = ""});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late TextEditingController controller;
  List<Map<String, dynamic>> suggestions = [];
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _speechAvailable = false;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    controller = TextEditingController(text: widget.initialText);
    controller.addListener(() => setState(() {})); // refreshes the clear (X) button
    _loadSuggestions("");
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    _speechAvailable = await _speech.initialize(
      onStatus: (status) {
        if (status == "done" || status == "notListening") {
          setState(() => _isListening = false);
        }
      },
      onError: (error) => setState(() => _isListening = false),
    );
    if (mounted) setState(() {});
  }

  Future<void> _toggleListening() async {
    if (!_speechAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Microphone not available')),
      );
      return;
    }
    if (_isListening) {
      await _speech.stop();
      setState(() => _isListening = false);
      return;
    }
    setState(() => _isListening = true);
    await _speech.listen(
      onResult: (result) {
        controller.text = result.recognizedWords;
        controller.selection = TextSelection.fromPosition(
          TextPosition(offset: controller.text.length),
        );
        _loadSuggestions(result.recognizedWords);
        if (result.finalResult) {
          setState(() => _isListening = false);
        }
      },
    );
  }

  Future<void> _loadSuggestions(String query) async {
    final results = await HistoryService.searchHistory(query);
    if (mounted) setState(() => suggestions = results);
  }

  void _clearText() {
    controller.clear();
    _loadSuggestions("");
  }

  void _submit(String text) {
    if (text.trim().isEmpty) return;
    _speech.stop();
    Navigator.pop(context, text.trim());
  }

  @override
  void dispose() {
    _speech.stop();
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back, size: 20, color: colors.onSurface),
                  onPressed: () => Navigator.pop(context),
                ),
                Expanded(
                  child: Container(
                    height: 40,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: colors.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: colors.primary, width: 1.2),
                      boxShadow: [
                        BoxShadow(color: colors.primary.withOpacity(0.15), blurRadius: 8),
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.search, size: 16, color: colors.onSurfaceVariant),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: controller,
                            autofocus: true,
                            style: TextStyle(color: colors.onSurface, fontSize: 14),
                            decoration: InputDecoration(
                              hintText: "Search Nexa or type a URL",
                              hintStyle: TextStyle(color: colors.onSurfaceVariant),
                              border: InputBorder.none,
                              isDense: true,
                              filled: false,
                              contentPadding: EdgeInsets.zero,
                            ),
                            onChanged: _loadSuggestions,
                            onSubmitted: _submit,
                          ),
                        ),
                        //-------------------------------------------
                        // Clear (X) button — wipes the whole field in
                        // one tap instead of holding backspace.
                        //-------------------------------------------
                        if (controller.text.isNotEmpty)
                          GestureDetector(
                            onTap: _clearText,
                            child: Icon(Icons.close_rounded, size: 18, color: colors.onSurfaceVariant),
                          ),
                        const SizedBox(width: 10),
                        GestureDetector(
                          onTap: _toggleListening,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _isListening
                                  ? colors.primary.withOpacity(0.2)
                                  : Colors.transparent,
                            ),
                            child: Icon(
                              _isListening ? Icons.mic : Icons.mic_none,
                              size: 18,
                              color: _isListening ? colors.primary : colors.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          if (_isListening)
            Container(
              width: double.infinity,
              color: colors.primary.withOpacity(0.08),
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text(
                "Listening...",
                textAlign: TextAlign.center,
                style: TextStyle(color: colors.primary, fontSize: 13),
              ),
            ),
          Expanded(
            child: suggestions.isEmpty
                ? Center(
                    child: Text(
                      controller.text.isEmpty ? "Your recent history will show up here" : "No matches",
                      style: TextStyle(color: colors.onSurfaceVariant, fontSize: 13),
                    ),
                  )
                : ListView.builder(
                    itemCount: suggestions.length,
                    itemBuilder: (context, index) {
                      final s = suggestions[index];
                      return ListTile(
                        leading: Icon(Icons.history, color: colors.onSurfaceVariant, size: 20),
                        title: Text(
                          s['title'] ?? s['url'],
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: colors.onSurface, fontSize: 14),
                        ),
                        subtitle: Text(
                          s['url'],
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12),
                        ),
                        onTap: () => Navigator.pop(context, s['url']),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
