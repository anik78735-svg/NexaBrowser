class HistoryEntry {
  final int? id;
  final String title;
  final String url;
  final DateTime visitedAt;

  HistoryEntry({
    this.id,
    required this.title,
    required this.url,
    required this.visitedAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'url': url,
        'visitedAt': visitedAt.millisecondsSinceEpoch,
      };

  factory HistoryEntry.fromMap(Map<String, dynamic> map) => HistoryEntry(
        id: map['id'],
        title: map['title'],
        url: map['url'],
        visitedAt: DateTime.fromMillisecondsSinceEpoch(map['visitedAt']),
      );
}