import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/download_item.dart';
import 'download_queue_service.dart';

class DownloadService {
  DownloadService._();

  static final Dio _dio = Dio();

  // Everything the downloads screen shows (name, size, status, file
  // path...) is written to disk here, so the list survives an app
  // restart or phone reboot instead of resetting to empty.
  static const String _prefsKey = 'nexa_downloads_v1';

  /// Loads previously saved downloads from disk. Call once, early in
  /// main() — see main.dart.
  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw == null || raw.isEmpty) return;

      final list = (jsonDecode(raw) as List)
          .map((e) => DownloadItem.fromJson(e as Map<String, dynamic>))
          .toList();

      downloadsNotifier.value = list;
    } catch (_) {
      // A corrupted or outdated save shouldn't crash startup — just
      // start with an empty list, same as a fresh install.
    }
  }

  static Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = jsonEncode(
        downloadsNotifier.value.map((e) => e.toJson()).toList(),
      );
      await prefs.setString(_prefsKey, raw);
    } catch (_) {
      // Best-effort: a failed save shouldn't interrupt the download itself.
    }
  }

  /// Reactive source of truth for the downloads list.
  ///
  /// Replaces the V2 Timer-based polling: the UI listens to this via
  /// [ValueListenableBuilder] and only rebuilds when downloads are
  /// added/removed. Per-item progress updates are handled separately by
  /// each [DownloadItem] being a [ChangeNotifier] itself, so a single
  /// progress tick never rebuilds the whole list.
  static final ValueNotifier<List<DownloadItem>> downloadsNotifier =
      ValueNotifier<List<DownloadItem>>(<DownloadItem>[]);

  /// Preserved for backward compatibility with V2 call sites that read
  /// `DownloadService.downloads` directly.
  static List<DownloadItem> get downloads => downloadsNotifier.value;

  static final DownloadQueueService _queue = DownloadQueueService(
    runner: _runDownload,
    maxConcurrentDownloads: 3,
  );

  static void _publish() {
    downloadsNotifier.value = List<DownloadItem>.from(downloadsNotifier.value);
    _persist();
  }

  static Future<Directory> _downloadDirectory() async {
    final dir = await getExternalStorageDirectory();

    final downloadDir = Directory("${dir!.path}/Download");

    if (!await downloadDir.exists()) {
      await downloadDir.create(recursive: true);
    }

    return downloadDir;
  }

  /// Starts a new download and enqueues it. Behaves exactly like V2 from the
  /// caller's perspective (fire-and-await), but now returns the created
  /// [DownloadItem] so callers that want it can use it immediately.
  static Future<DownloadItem> startDownload(
    String url, {
    String? suggestedName,
  }) async {
    final rawName = suggestedName ?? url.split('/').last.split('?').first;
    final fileName =
        rawName.isEmpty ? "download_${DateTime.now().millisecondsSinceEpoch}" : rawName;

    final item = DownloadItem(
      fileName: fileName,
      url: url,
    );

    final dir = await _downloadDirectory();
    item.filePath = "${dir.path}/$fileName";

    downloadsNotifier.value = [item, ...downloadsNotifier.value];
    _persist();

    _queue.enqueue(item);

    return item;
  }

  /// Runs (or resumes) a single download. Invoked exclusively by
  /// [DownloadQueueService] so concurrency stays centralized.
  static Future<void> _runDownload(
    DownloadItem item, {
    bool resume = false,
  }) async {
    item.markDownloading();
    _publish();

    final savePath = item.filePath!;
    final file = File(savePath);

    final resumeOffset =
        (resume && await file.exists()) ? await file.length() : 0;

    if (resumeOffset > 0) {
      item.receivedBytes = resumeOffset;
    }

    try {
      await _dio.download(
        item.url,
        savePath,
        cancelToken: item.cancelToken,
        deleteOnError: false,
        fileAccessMode:
            resumeOffset > 0 ? FileAccessMode.append : FileAccessMode.write,
        options: resumeOffset > 0
            ? Options(headers: {"range": "bytes=$resumeOffset-"})
            : null,
        onReceiveProgress: (received, total) {
          final effectiveReceived = resumeOffset + received;
          final effectiveTotal =
              total > 0 ? resumeOffset + total : item.totalBytes;

          item.updateProgress(effectiveReceived, effectiveTotal);
        },
      );

      item.markCompleted();
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) {
        // If the item was explicitly paused, keep it paused instead of
        // overwriting the status with "cancelled".
        if (item.status != DownloadStatus.paused) {
          item.markCancelled();
        }
      } else {
        item.markFailed(e.message);
      }
    } catch (e) {
      item.markFailed(e.toString());
    } finally {
      _publish();
      _queue.onFinished(item);
    }
  }

  /// Pauses an in-progress download. The partially downloaded file is kept
  /// on disk so [resumeDownload] can continue it with an HTTP range request.
  static void pauseDownload(DownloadItem item) {
    if (!item.canPause) return;

    item.markPaused();

    if (!item.cancelToken.isCancelled) {
      item.cancelToken.cancel("paused");
    }

    _publish();
  }

  /// Resumes a paused download from where it left off.
  static Future<void> resumeDownload(DownloadItem item) async {
    if (!item.canResume) return;

    item.cancelToken = CancelToken();
    _queue.enqueue(item, resume: true);
    _publish();
  }

  static void cancelDownload(DownloadItem item) {
    if (item.canCancel && !item.cancelToken.isCancelled) {
      item.cancelToken.cancel();
    }

    item.markCancelled();
    _queue.remove(item);
    _publish();
  }

  static void removeDownload(DownloadItem item) {
    downloadsNotifier.value =
        downloadsNotifier.value.where((e) => e != item).toList();
    _persist();
    item.dispose();
  }

  static Future<void> deleteFile(DownloadItem item) async {
    try {
      if (item.filePath != null) {
        final file = File(item.filePath!);

        if (await file.exists()) {
          await file.delete();
        }
      }
    } catch (_) {
      // Intentionally ignored: the item is removed from the list regardless
      // so the UI never gets stuck on a file that no longer matters.
    }

    removeDownload(item);
  }

  static Future<void> retryDownload(DownloadItem item) async {
    item.resetForRetry();
    _publish();
    _queue.enqueue(item);
  }

  /// Opens a completed download with the platform's default handler.
  static Future<void> openFile(DownloadItem item) async {
    if (item.filePath == null) return;
    await OpenFilex.open(item.filePath!);
  }

  static void clearCompleted() {
    final removed = downloadsNotifier.value
        .where((e) => e.status == DownloadStatus.completed)
        .toList();

    downloadsNotifier.value = downloadsNotifier.value
        .where((e) => e.status != DownloadStatus.completed)
        .toList();
    _persist();

    for (final item in removed) {
      item.dispose();
    }
  }
}