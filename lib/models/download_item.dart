import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';

enum DownloadStatus {
  queued,
  downloading,
  paused,
  completed,
  failed,
  cancelled,
}

/// Represents a single download.
///
/// This now extends [ChangeNotifier] so a single item can notify only the
/// widget that is displaying it (e.g. its [DownloadCard]) instead of forcing
/// a rebuild of the entire downloads list on every progress tick.
///
/// All original public fields and getters from V2 are preserved:
/// [fileName], [url], [filePath], [progress], [receivedBytes], [totalBytes],
/// [speed], [startTime], [status], [cancelToken], [progressText],
/// [downloadedText], [speedText], [completed], [downloading], [paused],
/// [failed], [cancelled].
class DownloadItem extends ChangeNotifier {
  final String fileName;
  final String url;

  String? filePath;

  double progress;
  int receivedBytes;
  int totalBytes;

  /// Smoothed transfer speed in bytes/sec.
  double speed;

  DateTime? startTime;

  DownloadStatus status;

  CancelToken cancelToken;

  /// Number of times this download has been retried.
  int retryCount;

  /// Human readable error captured on failure, if any.
  String? errorMessage;

  /// 1-based position in the pending queue. 0 when not queued.
  int queuePosition;

  DateTime? _lastTickTime;
  int _lastTickBytes;
  Duration? _eta;

  DownloadItem({
    required this.fileName,
    required this.url,
    this.filePath,
    this.progress = 0,
    this.receivedBytes = 0,
    this.totalBytes = 0,
    this.speed = 0,
    this.startTime,
    this.status = DownloadStatus.queued,
    CancelToken? cancelToken,
    this.retryCount = 0,
    this.errorMessage,
    this.queuePosition = 0,
  })  : cancelToken = cancelToken ?? CancelToken(),
        _lastTickBytes = receivedBytes;

  // --- status booleans (preserved from V2) ---

  bool get completed => status == DownloadStatus.completed;
  bool get downloading => status == DownloadStatus.downloading;
  bool get paused => status == DownloadStatus.paused;
  bool get failed => status == DownloadStatus.failed;
  bool get cancelled => status == DownloadStatus.cancelled;
  bool get queued => status == DownloadStatus.queued;

  // --- new capability helpers used by the V3 UI ---

  bool get isActive =>
      status == DownloadStatus.downloading || status == DownloadStatus.queued;

  bool get canPause => status == DownloadStatus.downloading;
  bool get canResume => status == DownloadStatus.paused;

  bool get canCancel =>
      status == DownloadStatus.downloading ||
      status == DownloadStatus.paused ||
      status == DownloadStatus.queued;

  bool get canRetry =>
      status == DownloadStatus.failed || status == DownloadStatus.cancelled;

  bool get canDelete =>
      status == DownloadStatus.completed ||
      status == DownloadStatus.failed ||
      status == DownloadStatus.cancelled;

  bool get canOpen => status == DownloadStatus.completed;

  Duration? get eta => _eta;

  // --- display strings ---

  String get progressText =>
      "${(progress * 100).clamp(0, 100).toStringAsFixed(0)}%";

  String get downloadedText =>
      "${_formatBytes(receivedBytes)} / ${_formatBytes(totalBytes)}";

  String get speedText {
    if (speed <= 0 || status != DownloadStatus.downloading) return "--";
    return "${_formatBytes(speed.round())}/s";
  }

  String get etaText {
    if (_eta == null || status != DownloadStatus.downloading) return "--";

    final minutes = _eta!.inMinutes;
    final seconds = _eta!.inSeconds % 60;

    if (minutes > 0) {
      return "${minutes}m ${seconds}s remaining";
    }
    return "${seconds}s remaining";
  }

  String get statusText {
    switch (status) {
      case DownloadStatus.queued:
        return "Queued";
      case DownloadStatus.downloading:
        return "Downloading";
      case DownloadStatus.paused:
        return "Paused";
      case DownloadStatus.completed:
        return "Completed";
      case DownloadStatus.failed:
        return "Failed";
      case DownloadStatus.cancelled:
        return "Cancelled";
    }
  }

  // --- mutators (called by DownloadService / DownloadQueueService only) ---

  void updateProgress(int received, int total) {
    receivedBytes = received;
    totalBytes = total;
    progress = total > 0 ? (received / total).clamp(0.0, 1.0) : 0.0;

    final now = DateTime.now();

    if (_lastTickTime == null) {
      _lastTickTime = now;
      _lastTickBytes = received;
      notifyListeners();
      return;
    }

    final elapsedMs = now.difference(_lastTickTime!).inMilliseconds;

    // Throttle speed/ETA recalculation to avoid noisy readings.
    if (elapsedMs >= 200) {
      final deltaBytes = received - _lastTickBytes;
      final instantSpeed = deltaBytes / (elapsedMs / 1000);

      // Exponential moving average for a smooth, Chrome-like speed readout.
      speed = speed <= 0 ? instantSpeed : (speed * 0.7) + (instantSpeed * 0.3);

      _lastTickTime = now;
      _lastTickBytes = received;

      if (speed > 0 && total > 0) {
        final remaining = total - received;
        _eta = Duration(seconds: (remaining / speed).round());
      }
    }

    notifyListeners();
  }

  void updateQueuePosition(int position) {
    queuePosition = position;
    notifyListeners();
  }

  void markQueued({int position = 0}) {
    status = DownloadStatus.queued;
    queuePosition = position;
    notifyListeners();
  }

  void markDownloading() {
    status = DownloadStatus.downloading;
    startTime ??= DateTime.now();
    _lastTickTime = null;
    errorMessage = null;
    notifyListeners();
  }

  void markPaused() {
    status = DownloadStatus.paused;
    speed = 0;
    _eta = null;
    notifyListeners();
  }

  void markCompleted() {
    status = DownloadStatus.completed;
    progress = 1;
    speed = 0;
    _eta = null;
    notifyListeners();
  }

  void markFailed([String? message]) {
    status = DownloadStatus.failed;
    speed = 0;
    _eta = null;
    errorMessage = message;
    notifyListeners();
  }

  void markCancelled() {
    status = DownloadStatus.cancelled;
    speed = 0;
    _eta = null;
    notifyListeners();
  }

  void resetForRetry() {
    status = DownloadStatus.queued;
    progress = 0;
    receivedBytes = 0;
    totalBytes = 0;
    speed = 0;
    _eta = null;
    startTime = null;
    _lastTickTime = null;
    _lastTickBytes = 0;
    errorMessage = null;
    cancelToken = CancelToken();
    retryCount += 1;
    notifyListeners();
  }

  // --- persistence (see DownloadService.init() / _persist()) ---
  //
  // Only the metadata needed to redraw a row is kept — the CancelToken
  // and in-flight speed/ETA numbers make no sense after the app has
  // restarted, so they're deliberately left out and re-defaulted.

  Map<String, dynamic> toJson() => {
        'fileName': fileName,
        'url': url,
        'filePath': filePath,
        'progress': progress,
        'receivedBytes': receivedBytes,
        'totalBytes': totalBytes,
        'status': status.name,
        'retryCount': retryCount,
        'errorMessage': errorMessage,
        'startTime': startTime?.millisecondsSinceEpoch,
      };

  factory DownloadItem.fromJson(Map<String, dynamic> json) {
    // A download that was still queued/downloading when the app last
    // closed can't actually continue (its network task is gone) — treat
    // it as paused if a partial file exists, so the user can resume it
    // with a tap, matching Chrome's own behaviour after a restart.
    final savedStatus = DownloadStatus.values.firstWhere(
      (s) => s.name == json['status'],
      orElse: () => DownloadStatus.cancelled,
    );
    final restoredStatus =
        (savedStatus == DownloadStatus.downloading || savedStatus == DownloadStatus.queued)
            ? DownloadStatus.paused
            : savedStatus;

    return DownloadItem(
      fileName: json['fileName'] as String,
      url: json['url'] as String,
      filePath: json['filePath'] as String?,
      progress: (json['progress'] as num?)?.toDouble() ?? 0,
      receivedBytes: json['receivedBytes'] as int? ?? 0,
      totalBytes: json['totalBytes'] as int? ?? 0,
      status: restoredStatus,
      retryCount: json['retryCount'] as int? ?? 0,
      errorMessage: json['errorMessage'] as String?,
      startTime: json['startTime'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['startTime'] as int)
          : null,
    );
  }

  static String _formatBytes(int bytes) {
    if (bytes <= 0) return "0 B";

    const suffixes = ["B", "KB", "MB", "GB", "TB"];

    double size = bytes.toDouble();
    int index = 0;

    while (size >= 1024 && index < suffixes.length - 1) {
      size /= 1024;
      index++;
    }

    return "${size.toStringAsFixed(1)} ${suffixes[index]}";
  }
}