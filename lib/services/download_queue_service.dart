import 'dart:collection';

import '../models/download_item.dart';

/// Executes a single download. [resume] tells the runner whether it should
/// continue an existing partially-downloaded file instead of starting over.
typedef DownloadRunner = Future<void> Function(
  DownloadItem item, {
  bool resume,
});

/// Coordinates how many downloads run at the same time.
///
/// [DownloadService] enqueues items here instead of starting them directly.
/// This keeps the concurrency policy in one place and makes it possible to
/// bump [maxConcurrentDownloads] up to support true parallel downloads later
/// without changing any calling code.
class DownloadQueueService {
  DownloadQueueService({
    required this.runner,
    this.maxConcurrentDownloads = 3,
  });

  final DownloadRunner runner;
  final int maxConcurrentDownloads;

  final Queue<_QueueEntry> _pending = Queue<_QueueEntry>();
  final Set<DownloadItem> _active = <DownloadItem>{};

  /// Adds [item] to the queue (or moves it back into the queue if it was
  /// already active/pending) and attempts to start it right away if a slot
  /// is free.
  void enqueue(DownloadItem item, {bool resume = false}) {
    _pending.removeWhere((entry) => entry.item == item);
    _active.remove(item);

    _pending.addLast(_QueueEntry(item, resume));
    item.markQueued(position: _pending.length);

    _refreshQueuePositions();
    _tryStartNext();
  }

  /// Removes [item] from the queue entirely (used on cancel).
  void remove(DownloadItem item) {
    _pending.removeWhere((entry) => entry.item == item);
    _active.remove(item);

    _refreshQueuePositions();
    _tryStartNext();
  }

  /// Must be called by the runner once a download finishes, fails, or is
  /// cancelled so the next queued item can start.
  void onFinished(DownloadItem item) {
    _active.remove(item);
    _tryStartNext();
  }

  int get activeCount => _active.length;
  int get pendingCount => _pending.length;

  void _tryStartNext() {
    while (_active.length < maxConcurrentDownloads && _pending.isNotEmpty) {
      final entry = _pending.removeFirst();
      _active.add(entry.item);

      runner(entry.item, resume: entry.resume);
    }

    _refreshQueuePositions();
  }

  void _refreshQueuePositions() {
    var position = 1;
    for (final entry in _pending) {
      entry.item.updateQueuePosition(position);
      position++;
    }
  }
}

class _QueueEntry {
  _QueueEntry(this.item, this.resume);

  final DownloadItem item;
  final bool resume;
}