class Bookmark {
  final String title;
  final String url;
  Bookmark({required this.title, required this.url});

  Map<String, String> toJson() => {"title": title, "url": url};
  factory Bookmark.fromJson(Map<String, dynamic> json) =>
      Bookmark(title: json["title"], url: json["url"]);
}