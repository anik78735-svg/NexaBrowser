import 'package:flutter/material.dart';
import '../models/bookmark.dart';
import '../services/bookmark_service.dart';

class BookmarksScreen extends StatefulWidget {
  final Function(String url) onOpen;
  const BookmarksScreen({super.key, required this.onOpen});

  @override
  State<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends State<BookmarksScreen> {
  List<Bookmark> bookmarks = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await BookmarkService.getBookmarks();
    setState(() => bookmarks = list);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Bookmarks")),
      body: bookmarks.isEmpty
          ? const Center(
              child: Text("No bookmarks yet",
                  style: TextStyle(color: Colors.grey)))
          : ListView.builder(
              itemCount: bookmarks.length,
              itemBuilder: (context, index) {
                final b = bookmarks[index];
                return ListTile(
                  leading: const Icon(Icons.star, color: Colors.amber),
                  title: Text(b.title,
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text(b.url,
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () async {
                      await BookmarkService.removeBookmark(b.url);
                      _load();
                    },
                  ),
                  onTap: () {
                    widget.onOpen(b.url);
                    Navigator.pop(context);
                  },
                );
              },
            ),
    );
  }
}