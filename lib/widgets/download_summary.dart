import 'package:flutter/material.dart';

import '../models/download_item.dart';

/// Chrome/Brave-style summary strip shown above the downloads list.
class DownloadSummary extends StatelessWidget {
  const DownloadSummary({super.key, required this.downloads});

  final List<DownloadItem> downloads;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final downloading = downloads
        .where((e) =>
            e.status == DownloadStatus.downloading ||
            e.status == DownloadStatus.queued)
        .length;

    final completed =
        downloads.where((e) => e.status == DownloadStatus.completed).length;

    final failed = downloads
        .where((e) =>
            e.status == DownloadStatus.failed ||
            e.status == DownloadStatus.cancelled)
        .length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        border: Border(
          bottom: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _SummaryTile(
            label: "Downloading",
            value: downloading,
            icon: Icons.downloading_rounded,
            color: theme.colorScheme.primary,
          ),
          _SummaryTile(
            label: "Completed",
            value: completed,
            icon: Icons.check_circle_rounded,
            color: Colors.green,
          ),
          _SummaryTile(
            label: "Failed",
            value: failed,
            icon: Icons.error_rounded,
            color: theme.colorScheme.error,
          ),
        ],
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final int value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 6),
        Text(
          "$value",
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}