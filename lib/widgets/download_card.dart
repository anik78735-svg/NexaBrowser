import 'package:flutter/material.dart';

import '../models/download_item.dart';
import '../services/download_service.dart';
import 'download_action_bar.dart';

class DownloadCard extends StatelessWidget {
  const DownloadCard({super.key, required this.item});

  final DownloadItem item;

  Color _statusColor(BuildContext context, DownloadStatus status) {
    final scheme = Theme.of(context).colorScheme;

    switch (status) {
      case DownloadStatus.completed:
        return Colors.green;
      case DownloadStatus.failed:
        return scheme.error;
      case DownloadStatus.cancelled:
        return scheme.outline;
      case DownloadStatus.paused:
        return Colors.amber.shade700;
      case DownloadStatus.downloading:
        return scheme.primary;
      case DownloadStatus.queued:
        return scheme.secondary;
    }
  }

  IconData _statusIcon(DownloadStatus status) {
    switch (status) {
      case DownloadStatus.completed:
        return Icons.check_circle_rounded;
      case DownloadStatus.failed:
        return Icons.error_rounded;
      case DownloadStatus.cancelled:
        return Icons.cancel_rounded;
      case DownloadStatus.paused:
        return Icons.pause_circle_rounded;
      case DownloadStatus.downloading:
        return Icons.downloading_rounded;
      case DownloadStatus.queued:
        return Icons.schedule_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    // ListenableBuilder scopes rebuilds to THIS card only, whenever this
    // item's own notifyListeners() fires (progress, status changes, etc).
    return ListenableBuilder(
      listenable: item,
      builder: (context, _) {
        final theme = Theme.of(context);
        final color = _statusColor(context, item.status);

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 0,
          color: theme.colorScheme.surfaceContainerHigh,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: theme.colorScheme.outlineVariant),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: color.withOpacity(0.15),
                      child: Icon(_statusIcon(item.status), color: color),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.fileName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          _StatusChip(item: item, color: color),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    // Indeterminate while queued, determinate once it starts.
                    value: item.status == DownloadStatus.queued
                        ? null
                        : item.progress,
                    minHeight: 6,
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    color: color,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      item.status == DownloadStatus.queued
                          ? "Waiting in queue (#${item.queuePosition})"
                          : "${item.progressText} \u00b7 ${item.downloadedText}",
                      style: theme.textTheme.bodySmall,
                    ),
                    if (item.status == DownloadStatus.downloading)
                      Text(item.speedText, style: theme.textTheme.bodySmall),
                  ],
                ),
                if (item.status == DownloadStatus.downloading) ...[
                  const SizedBox(height: 2),
                  Text(item.etaText, style: theme.textTheme.bodySmall),
                ],
                if (item.status == DownloadStatus.failed &&
                    item.errorMessage != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    item.errorMessage!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.error),
                  ),
                ],
                const SizedBox(height: 12),
                DownloadActionBar(
                  item: item,
                  onPause: () => DownloadService.pauseDownload(item),
                  onResume: () => DownloadService.resumeDownload(item),
                  onCancel: () => DownloadService.cancelDownload(item),
                  onRetry: () => DownloadService.retryDownload(item),
                  onDelete: () => DownloadService.deleteFile(item),
                  onOpen: () => DownloadService.openFile(item),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.item, required this.color});

  final DownloadItem item;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        item.statusText,
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}