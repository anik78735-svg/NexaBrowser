import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/history_entry.dart';
import '../services/history_service.dart';

class HistoryScreen extends StatefulWidget {
  final Function(String url) onOpen;
  const HistoryScreen({super.key, required this.onOpen});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<HistoryEntry> history = [];
  bool _searching = false;
  String _query = "";
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final list = await HistoryService.getHistory();
    if (!mounted) return;
    setState(() => history = list);
  }

  String _dayLabel(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final that = DateTime(dt.year, dt.month, dt.day);
    final diff = today.difference(that).inDays;
    final dateStr = DateFormat("d MMM yyyy").format(dt);
    if (diff == 0) return "Today - $dateStr";
    if (diff == 1) return "Yesterday - $dateStr";
    return dateStr;
  }

  String _favicon(String url) {
    final host = Uri.tryParse(url)?.host ?? "";
    return host.isNotEmpty ? host[0].toUpperCase() : "?";
  }

  List<HistoryEntry> get _filtered {
    if (_query.trim().isEmpty) return history;
    final q = _query.toLowerCase();
    return history
        .where((h) =>
            h.title.toLowerCase().contains(q) || h.url.toLowerCase().contains(q))
        .toList();
  }

  Map<String, List<HistoryEntry>> _grouped(List<HistoryEntry> source) {
    final map = <String, List<HistoryEntry>>{};
    for (final h in source) {
      final key = _dayLabel(h.visitedAt);
      map.putIfAbsent(key, () => []).add(h);
    }
    return map;
  }

  void _startSearch() {
    setState(() => _searching = true);
  }

  void _stopSearch() {
    setState(() {
      _searching = false;
      _query = "";
      _searchController.clear();
    });
  }

  void _showInfo() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("About browsing history"),
        content: const Text(
          "Nexa keeps a list of pages you've visited so you can find them "
          "again quickly. Entries older than 3 days are removed "
          "automatically, and you can clear everything at any time from "
          "\"Delete browsing data…\" below.",
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Got it")),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteAll() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete all history?"),
        content: const Text("This will clear your browsing history."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Delete")),
        ],
      ),
    );
    if (ok == true) {
      await HistoryService.clearAll();
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final filtered = _filtered;
    final grouped = _grouped(filtered);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: _searching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                onChanged: (v) => setState(() => _query = v),
                decoration: const InputDecoration(
                  hintText: "Search your history",
                  border: InputBorder.none,
                  filled: false,
                  contentPadding: EdgeInsets.zero,
                ),
                style: TextStyle(color: colors.onSurface, fontSize: 18),
              )
            : const Text("History"),
        actions: _searching
            ? [
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: _stopSearch,
                ),
              ]
            : [
                IconButton(
                  tooltip: "About history",
                  icon: const Icon(Icons.info_outline_rounded),
                  onPressed: _showInfo,
                ),
                IconButton(
                  tooltip: "Search history",
                  icon: const Icon(Icons.search_rounded),
                  onPressed: _startSearch,
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
      ),
      body: history.isEmpty
          ? _buildEmptyState(context)
          : filtered.isEmpty
              ? _buildNoResults(context)
              : ListView(
                  children: [
                    if (!_searching) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        child: Text(
                          "You may see history from other apps that open links here.",
                          style: TextStyle(color: colors.onSurfaceVariant, fontSize: 13, height: 1.4),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                        child: GestureDetector(
                          onTap: _confirmDeleteAll,
                          child: Text(
                            "Delete browsing data...",
                            style: TextStyle(color: colors.primary, fontSize: 14, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Divider(height: 1),
                    ],
                    for (final entry in grouped.entries) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                        child: Text(
                          entry.key,
                          style: TextStyle(
                            color: colors.primary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      for (final h in entry.value)
                        ListTile(
                          leading: CircleAvatar(
                            radius: 16,
                            backgroundColor: colors.surfaceContainerHighest,
                            child: Text(
                              _favicon(h.url),
                              style: TextStyle(color: colors.onSurfaceVariant, fontSize: 13),
                            ),
                          ),
                          title: Text(
                            h.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            Uri.tryParse(h.url)?.host ?? h.url,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: IconButton(
                            icon: Icon(Icons.close_rounded, color: colors.outline, size: 20),
                            onPressed: () async {
                              await HistoryService.deleteEntry(h.id!);
                              _load();
                            },
                          ),
                          onTap: () {
                            widget.onOpen(h.url);
                            Navigator.pop(context);
                          },
                        ),
                    ],
                    const SizedBox(height: 20),
                  ],
                ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.history_rounded, size: 56, color: colors.outline),
          const SizedBox(height: 12),
          Text(
            "No history yet",
            style: TextStyle(color: colors.onSurface, fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 4),
          Text(
            "History older than 3 days is auto-deleted",
            style: TextStyle(color: colors.onSurfaceVariant, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResults(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off_rounded, size: 56, color: colors.outline),
          const SizedBox(height: 12),
          Text(
            "No matches for \"$_query\"",
            style: TextStyle(color: colors.onSurfaceVariant, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
