import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/history_entry.dart';

class HistoryService {
  static Database? _db;

  // An older build's "New Tab" used to load this hosted Vercel page as
  // the home page (instead of today's native NewTabPage). Devices that
  // were on that build have real History rows pointing at it, which is
  // why it kept showing up as a duplicated "Nexa New Tab" suggestion in
  // the address bar and as a stale shortcut on the home screen even
  // though nothing in the current app ever navigates there anymore.
  static const String _legacyHomeUrlHost = 'nexa-home-iota.vercel.app';

  static Future<Database> get database async {
    if (_db != null) return _db!;

    final path = join(await getDatabasesPath(), 'nexa_history.db');

    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE history(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT,
            url TEXT,
            visitedAt INTEGER
          )
        ''');
      },
    );

    return _db!;
  }

  //---------------------------------------------------------------------
  // One-time cleanup for devices upgrading from the old build that used
  // the hosted Vercel page as "home" — removes those leftover rows so
  // they stop appearing as duplicated suggestions / shortcuts. Safe to
  // call on every app start; it's a no-op once those rows are gone.
  //---------------------------------------------------------------------
  static Future<void> purgeLegacyHomeUrl() async {
    final db = await database;
    await db.delete(
      'history',
      where: 'url LIKE ?',
      whereArgs: ['%$_legacyHomeUrlHost%'],
    );
  }

  static Future<void> addEntry(String title, String url) async {
    final db = await database;

    // Guards against duplicate rows for the same page: onLoadStop can
    // legitimately fire more than once for one visit (redirects, a
    // pull-to-refresh, a same-page navigation), which used to insert a
    // brand new row every time and made the same URL show up twice in
    // History / search suggestions. If the very last entry is the same
    // URL and happened recently, just bump its timestamp instead.
    final recent = await db.query(
      'history',
      orderBy: 'visitedAt DESC',
      limit: 1,
    );

    final now = DateTime.now().millisecondsSinceEpoch;
    if (recent.isNotEmpty &&
        recent.first['url'] == url &&
        now - (recent.first['visitedAt'] as int) < 10000) {
      await db.update(
        'history',
        {'visitedAt': now, 'title': title},
        where: 'id = ?',
        whereArgs: [recent.first['id']],
      );
      return;
    }

    await db.insert('history', {
      'title': title,
      'url': url,
      'visitedAt': now,
    });

    await _cleanOldEntries();
  }

  static Future<void> _cleanOldEntries() async {
    final db = await database;

    final cutoff = DateTime.now()
        .subtract(const Duration(days: 3))
        .millisecondsSinceEpoch;

    await db.delete(
      'history',
      where: 'visitedAt < ?',
      whereArgs: [cutoff],
    );
  }

  static Future<List<HistoryEntry>> getHistory() async {
    await _cleanOldEntries();

    final db = await database;

    final maps = await db.query(
      'history',
      orderBy: 'visitedAt DESC',
    );

    return maps.map((e) => HistoryEntry.fromMap(e)).toList();
  }

  static Future<void> clearAll() async {
    final db = await database;
    await db.delete('history');
  }

  /// Deletes history entries visited within [range] of now.
  /// Pass null for [range] to delete everything ("All time").
  static Future<void> clearSince(Duration? range) async {
    final db = await database;
    if (range == null) {
      await db.delete('history');
      return;
    }
    final cutoff = DateTime.now().subtract(range).millisecondsSinceEpoch;
    await db.delete(
      'history',
      where: 'visitedAt >= ?',
      whereArgs: [cutoff],
    );
  }

  static Future<void> deleteEntry(int id) async {
    final db = await database;

    await db.delete(
      'history',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<List<Map<String, dynamic>>> getMostVisited({int limit = 8}) async {
  await _cleanOldEntries();
  final db = await database;
  final raw = await db.rawQuery('''
    SELECT url, title, visitedAt FROM history ORDER BY visitedAt DESC
  ''');

  final Map<String, Map<String, dynamic>> domainMap = {};

  for (final row in raw) {
    final url = row['url'] as String;
    if (_isSearchResultUrl(url)) continue;
    if (url.contains(_legacyHomeUrlHost)) continue;

    final domain = _extractDomain(url);
    if (domain.isEmpty) continue;

    if (!domainMap.containsKey(domain)) {
      domainMap[domain] = {
        'domain': domain,
        'url': url,
        'title': row['title'],
        'count': 1,
      };
    } else {
      domainMap[domain]!['count'] = (domainMap[domain]!['count'] as int) + 1;
    }
  }

  final list = domainMap.values.toList();
  list.sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));
  return list.take(limit).toList();
}

static bool _isSearchResultUrl(String url) {
  try {
    final uri = Uri.parse(url);
    return uri.host.contains('google.com') && uri.path.startsWith('/search');
  } catch (_) {
    return false;
  }
}

static String _extractDomain(String url) {
  try {
    final uri = Uri.parse(url);
    return uri.host.replaceFirst('www.', '');
  } catch (_) {
    return '';
  }
}

  //---------------------------------------------------------------------
  // Address bar / New Tab search suggestions. Deduplicated by URL — the
  // dedup in addEntry() only collapses repeat visits that land within
  // 10 seconds of each other, so revisiting the same page later in the
  // day still adds a new row and the raw query used to return the same
  // URL multiple times in a row here (e.g. three identical "Nexa New
  // Tab" suggestions). Keeping only the most recent row per URL fixes
  // that without touching History itself, where every visit should
  // still count.
  //---------------------------------------------------------------------
  static Future<List<Map<String, dynamic>>> searchHistory(String query) async {
    await _cleanOldEntries();
    final db = await database;
    final rows = query.trim().isEmpty
        ? await db.query('history', orderBy: 'visitedAt DESC', limit: 60)
        : await db.query(
            'history',
            where: 'title LIKE ? OR url LIKE ?',
            whereArgs: ['%$query%', '%$query%'],
            orderBy: 'visitedAt DESC',
            limit: 60,
          );

    final seenUrls = <String>{};
    final deduped = <Map<String, dynamic>>[];
    for (final row in rows) {
      final url = row['url'] as String;
      if (url.contains(_legacyHomeUrlHost)) continue;
      if (!seenUrls.add(url)) continue;
      deduped.add(row);
      if (deduped.length >= 20) break;
    }
    return deduped;
  }
}