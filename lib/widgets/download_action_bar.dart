import 'package:flutter/material.dart';

import '../models/download_item.dart';

/// Renders only the actions that are valid for [item]'s current status,
/// mirroring how Chrome/Brave surface contextual download actions.
class DownloadActionBar extends StatelessWidget {
  const DownloadActionBar({
    super.key,
    required this.item,
    required this.onPause,
    required this.onResume,
    required this.onCancel,
    required this.onRetry,
    required this.onDelete,
    required this.onOpen,
  });

  final DownloadItem item;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onCancel;
  final VoidCallback onRetry;
  final VoidCallback onDelete;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final buttons = <Widget>[];

    if (item.canOpen) {
      buttons.add(
        FilledButton.icon(
          onPressed: onOpen,
          icon: const Icon(Icons.open_in_new_rounded, size: 18),
          label: const Text("Open"),
        ),
      );
    }

    if (item.canPause) {
      buttons.add(
        OutlinedButton.icon(
          onPressed: onPause,
          icon: const Icon(Icons.pause_rounded, size: 18),
          label: const Text("Pause"),
        ),
      );
    }

    if (item.canResume) {
      buttons.add(
        FilledButton.icon(
          onPressed: onResume,
          icon: const Icon(Icons.play_arrow_rounded, size: 18),
          label: const Text("Resume"),
        ),
      );
    }

    if (item.canRetry) {
      buttons.add(
        FilledButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh_rounded, size: 18),
          label: const Text("Retry"),
        ),
      );
    }

    if (item.canCancel) {
      buttons.add(
        TextButton.icon(
          onPressed: onCancel,
          icon: const Icon(Icons.close_rounded, size: 18),
          label: const Text("Cancel"),
        ),
      );
    }

    if (item.canDelete) {
      buttons.add(
        TextButton.icon(
          onPressed: onDelete,
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.error,
          ),
          icon: const Icon(Icons.delete_outline_rounded, size: 18),
          label: const Text("Delete"),
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: buttons,
    );
  }
}