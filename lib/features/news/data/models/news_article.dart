/// Represents a scraped news article with its summary
class NewsArticle {
  final String id;
  final String sourceId;
  final String sourceName;
  final String title;
  final String url;
  final String? imageUrl;
  final String content;
  final String briefSummary; // Short summary for cards (1-2 sentences)
  final String summary; // Detailed summary for article detail screen
  final DateTime publishedAt;
  final DateTime? modifiedAt; // When the article was last updated
  final DateTime scrapedAt;
  final String category;
  final String? author; // Article author name
  final List<String> keywords; // Article keywords/tags

  const NewsArticle({
    required this.id,
    required this.sourceId,
    required this.sourceName,
    required this.title,
    required this.url,
    this.imageUrl,
    required this.content,
    required this.briefSummary,
    required this.summary,
    required this.publishedAt,
    this.modifiedAt,
    required this.scrapedAt,
    required this.category,
    this.author,
    this.keywords = const [],
  });

  NewsArticle copyWith({
    String? id,
    String? sourceId,
    String? sourceName,
    String? title,
    String? url,
    String? imageUrl,
    String? content,
    String? briefSummary,
    String? summary,
    DateTime? publishedAt,
    DateTime? modifiedAt,
    DateTime? scrapedAt,
    String? category,
    String? author,
    List<String>? keywords,
  }) {
    return NewsArticle(
      id: id ?? this.id,
      sourceId: sourceId ?? this.sourceId,
      sourceName: sourceName ?? this.sourceName,
      title: title ?? this.title,
      url: url ?? this.url,
      imageUrl: imageUrl ?? this.imageUrl,
      content: content ?? this.content,
      briefSummary: briefSummary ?? this.briefSummary,
      summary: summary ?? this.summary,
      publishedAt: publishedAt ?? this.publishedAt,
      modifiedAt: modifiedAt ?? this.modifiedAt,
      scrapedAt: scrapedAt ?? this.scrapedAt,
      category: category ?? this.category,
      author: author ?? this.author,
      keywords: keywords ?? this.keywords,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sourceId': sourceId,
      'sourceName': sourceName,
      'title': title,
      'url': url,
      'imageUrl': imageUrl,
      'content': content,
      'briefSummary': briefSummary,
      'summary': summary,
      'publishedAt': publishedAt.toIso8601String(),
      'modifiedAt': modifiedAt?.toIso8601String(),
      'scrapedAt': scrapedAt.toIso8601String(),
      'category': category,
      'author': author,
      'keywords': keywords,
    };
  }

  factory NewsArticle.fromJson(Map<String, dynamic> json) {
    return NewsArticle(
      id: json['id'] as String,
      sourceId: json['sourceId'] as String,
      sourceName: json['sourceName'] as String,
      title: json['title'] as String,
      url: json['url'] as String,
      imageUrl: json['imageUrl'] as String?,
      briefSummary: json['briefSummary'] as String,
      content: json['content'] as String,
      summary: json['summary'] as String,
      publishedAt: DateTime.parse(json['publishedAt'] as String),
      modifiedAt: json['modifiedAt'] != null ? DateTime.parse(json['modifiedAt'] as String) : null,
      scrapedAt: DateTime.parse(json['scrapedAt'] as String),
      category: json['category'] as String,
      author: json['author'] as String?,
      keywords: (json['keywords'] as List<dynamic>?)?.map((e) => e as String).toList() ?? const [],
    );
  }
}
