import 'package:flutter/material.dart';

import '../models/download_item.dart';
import '../services/download_service.dart';
import '../widgets/download_card.dart';
import '../widgets/download_summary.dart';

/// V3 downloads screen.
///
/// No Timer, no polling: the whole screen is driven by
/// [DownloadService.downloadsNotifier], and each [DownloadCard] additionally
/// listens to its own [DownloadItem] so progress ticks never rebuild
/// anything more than the single row that changed.
class DownloadsScreen extends StatelessWidget {
  const DownloadsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Downloads"),
        actions: [
          ValueListenableBuilder<List<DownloadItem>>(
            valueListenable: DownloadService.downloadsNotifier,
            builder: (context, downloads, _) {
              final hasCompleted =
                  downloads.any((e) => e.status == DownloadStatus.completed);

              if (!hasCompleted) return const SizedBox.shrink();

              return IconButton(
                tooltip: "Clear completed",
                icon: const Icon(Icons.delete_sweep_rounded),
                onPressed: DownloadService.clearCompleted,
              );
            },
          ),
        ],
      ),
      body: ValueListenableBuilder<List<DownloadItem>>(
        valueListenable: DownloadService.downloadsNotifier,
        builder: (context, downloads, _) {
          return Column(
            children: [
              DownloadSummary(downloads: downloads),
              Expanded(
                child: downloads.isEmpty
                    ? const _EmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: downloads.length,
                        itemBuilder: (context, index) {
                          final item = downloads[index];

                          // A stable key keeps each card's identity correct
                          // across list mutations (add/remove/reorder).
                          return DownloadCard(
                            key: ValueKey("${item.url}_${item.fileName}"),
                            item: item,
                          );
                        },
                      ),
              ),
            ],
          );
        },
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