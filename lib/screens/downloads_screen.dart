import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';

import '../models/download_item.dart';
import '../services/download_service.dart';
import '../widgets/download_card.dart';

enum _Filter { all, videos, audio, images }

/// Chrome-style downloads screen: active downloads as compact progress
/// rows up top, everything finished laid out as a thumbnail grid grouped
/// by day, with filter chips and a running "space used" line — same
/// visual language as Chrome's own Downloads page.
class DownloadsScreen extends StatefulWidget {
  const DownloadsScreen({super.key});

  @override
  State<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends State<DownloadsScreen> {
  _Filter _filter = _Filter.all;
  bool _searching = false;
  String _query = "";
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _dayLabel(DateTime dt) {
    final now = DateTime.now();
    if (now.difference(dt).inMinutes < 60) return "Just now";
    final today = DateTime(now.year, now.month, now.day);
    final that = DateTime(dt.year, dt.month, dt.day);
    final diff = today.difference(that).inDays;
    final dateStr = DateFormat("d MMM yyyy").format(dt);
    if (diff == 0) return "Today";
    if (diff == 1) return "Yesterday - $dateStr";
    return dateStr;
  }

  bool _matchesFilter(DownloadItem item) {
    switch (_filter) {
      case _Filter.all:
        return true;
      case _Filter.videos:
        return item.isVideo;
      case _Filter.audio:
        return item.isAudio;
      case _Filter.images:
        return item.isImage;
    }
  }

  bool _matchesQuery(DownloadItem item) =>
      _query.isEmpty || item.fileName.toLowerCase().contains(_query.toLowerCase());

  void _openSettingsSheet(List<DownloadItem> downloads) {
    final hasCompleted = downloads.any((e) => e.status == DownloadStatus.completed);
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.delete_sweep_rounded),
              title: const Text("Clear completed downloads"),
              enabled: hasCompleted,
              onTap: hasCompleted
                  ? () {
                      Navigator.pop(ctx);
                      DownloadService.clearCompleted();
                    }
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: ValueListenableBuilder<List<DownloadItem>>(
          valueListenable: DownloadService.downloadsNotifier,
          builder: (context, downloads, _) {
            final active = downloads.where((d) => d.isActive || d.paused).toList();
            final finished = downloads
                .where((d) => d.status == DownloadStatus.completed)
                .where(_matchesFilter)
                .where(_matchesQuery)
                .toList();

            final usedBytes = downloads
                .where((d) => d.status == DownloadStatus.completed)
                .fold<int>(0, (sum, d) => sum + d.totalBytes);

            final grouped = <String, List<DownloadItem>>{};
            for (final item in finished) {
              final key = _dayLabel(item.startTime ?? DateTime.now());
              grouped.putIfAbsent(key, () => []).add(item);
            }

            return Column(
              children: [
                _buildHeader(context, downloads, usedBytes),
                if (!_searching) _buildFilterChips(context),
                const Divider(height: 1),
                Expanded(
                  child: downloads.isEmpty
                      ? const _EmptyState()
                      : ListView(
                          padding: const EdgeInsets.only(bottom: 24),
                          children: [
                            if (active.isNotEmpty && !_searching) ...[
                              Padding(
                                padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                                child: Text(
                                  "In progress",
                                  style: TextStyle(
                                    color: colors.primary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              ...active.map(
                                (item) => Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  child: DownloadCard(
                                    key: ValueKey("${item.url}_${item.fileName}"),
                                    item: item,
                                  ),
                                ),
                              ),
                            ],
                            if (finished.isEmpty && active.isEmpty)
                              const _EmptyState()
                            else if (finished.isEmpty && _query.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 40),
                                child: Center(
                                  child: Text(
                                    "No matches for \"$_query\"",
                                    style: TextStyle(color: colors.onSurfaceVariant),
                                  ),
                                ),
                              )
                            else
                              for (final entry in grouped.entries) ...[
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                                  child: Text(
                                    entry.key,
                                    style: TextStyle(
                                      color: colors.onSurface,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  child: GridView.builder(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      crossAxisSpacing: 8,
                                      mainAxisSpacing: 8,
                                      childAspectRatio: 1.4,
                                    ),
                                    itemCount: entry.value.length,
                                    itemBuilder: (context, i) => _DownloadTile(item: entry.value[i]),
                                  ),
                                ),
                              ],
                          ],
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, List<DownloadItem> downloads, int usedBytes) {
    final colors = Theme.of(context).colorScheme;

    if (_searching) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () => setState(() {
                _searching = false;
                _query = "";
                _searchController.clear();
              }),
            ),
            Expanded(
              child: TextField(
                controller: _searchController,
                autofocus: true,
                onChanged: (v) => setState(() => _query = v),
                decoration: const InputDecoration(
                  hintText: "Search downloads",
                  border: InputBorder.none,
                  filled: false,
                  contentPadding: EdgeInsets.zero,
                ),
                style: TextStyle(color: colors.onSurface, fontSize: 17),
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 12, 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Downloads",
                  style: TextStyle(
                    color: colors.onSurface,
                    fontSize: 26,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (downloads.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    "Using ${DownloadItem.formatBytesPublic(usedBytes)}",
                    style: TextStyle(color: colors.onSurfaceVariant, fontSize: 13),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            tooltip: "Downloads options",
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => _openSettingsSheet(downloads),
          ),
          IconButton(
            tooltip: "Search downloads",
            icon: const Icon(Icons.search_rounded),
            onPressed: () => setState(() => _searching = true),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    Widget chip(String label, IconData icon, _Filter value) {
      final selected = _filter == value;
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: ChoiceChip(
          selected: selected,
          onSelected: (_) => setState(() => _filter = value),
          avatar: selected
              ? Icon(Icons.check_rounded, size: 16, color: colors.onPrimaryContainer)
              : Icon(icon, size: 16, color: colors.onSurfaceVariant),
          label: Text(label),
          selectedColor: colors.primaryContainer,
          labelStyle: TextStyle(
            color: selected ? colors.onPrimaryContainer : colors.onSurface,
            fontSize: 13,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            chip("All", Icons.apps_rounded, _Filter.all),
            chip("Videos", Icons.videocam_rounded, _Filter.videos),
            chip("Audio", Icons.music_note_rounded, _Filter.audio),
            chip("Images", Icons.image_rounded, _Filter.images),
          ],
        ),
      ),
    );
  }
}

class _DownloadTile extends StatelessWidget {
  final DownloadItem item;
  const _DownloadTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final hasPreview = item.isImage && item.filePath != null && File(item.filePath!).existsSync();

    return GestureDetector(
      onTap: () {
        if (item.filePath != null) OpenFilex.open(item.filePath!);
      },
      onLongPress: () => _showActions(context),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Container(
          color: colors.surfaceContainerHigh,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (hasPreview)
                Image.file(File(item.filePath!), fit: BoxFit.cover)
              else
                Center(
                  child: Icon(
                    item.isVideo
                        ? Icons.movie_rounded
                        : item.isAudio
                            ? Icons.audiotrack_rounded
                            : Icons.insert_drive_file_rounded,
                    size: 34,
                    color: colors.onSurfaceVariant,
                  ),
                ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(8, 14, 8, 6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black.withOpacity(0.55)],
                    ),
                  ),
                  child: Text(
                    item.fileName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontSize: 11),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showActions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.open_in_new_rounded),
              title: const Text("Open"),
              onTap: () {
                Navigator.pop(ctx);
                if (item.filePath != null) OpenFilex.open(item.filePath!);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded),
              title: const Text("Remove from list"),
              onTap: () {
                Navigator.pop(ctx);
                DownloadService.removeDownload(item);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.download_rounded,
            size: 56,
            color: theme.colorScheme.outline,
          ),
          const SizedBox(height: 12),
          Text(
            "No downloads yet",
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
