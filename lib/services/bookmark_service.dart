import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/bookmark.dart';

class BookmarkService {
  static const String _key = "nexa_bookmarks";

  static Future<List<Bookmark>> getBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    return raw.map((s) => Bookmark.fromJson(jsonDecode(s))).toList();
  }

  static Future<void> addBookmark(Bookmark bookmark) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    raw.add(jsonEncode(bookmark.toJson()));
    await prefs.setStringList(_key, raw);
  }

  static Future<void> removeBookmark(String url) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    raw.removeWhere((s) => jsonDecode(s)["url"] == url);
    await prefs.setStringList(_key, raw);
  }

  static Future<bool> isBookmarked(String url) async {
    final bookmarks = await getBookmarks();
    return bookmarks.any((b) => b.url == url);
  }
}