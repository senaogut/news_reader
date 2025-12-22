/// Represents a news source that can be scraped
class NewsSource {
  final String id;
  final String name;
  final String url;
  final String logoUrl;
  final String category;
  final bool isEnabled;
  final int maxArticles; // Maximum number of articles to fetch per scrape

  const NewsSource({
    required this.id,
    required this.name,
    required this.url,
    required this.logoUrl,
    required this.category,
    this.isEnabled = false,
    this.maxArticles = 15, // Default to 15 articles
  });

  NewsSource copyWith({
    String? id,
    String? name,
    String? url,
    String? logoUrl,
    String? category,
    bool? isEnabled,
    int? maxArticles,
  }) {
    return NewsSource(
      id: id ?? this.id,
      name: name ?? this.name,
      url: url ?? this.url,
      logoUrl: logoUrl ?? this.logoUrl,
      category: category ?? this.category,
      isEnabled: isEnabled ?? this.isEnabled,
      maxArticles: maxArticles ?? this.maxArticles,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'url': url,
      'logoUrl': logoUrl,
      'category': category,
      'isEnabled': isEnabled,
      'maxArticles': maxArticles,
    };
  }

  factory NewsSource.fromJson(Map<String, dynamic> json) {
    return NewsSource(
      id: json['id'] as String,
      name: json['name'] as String,
      url: json['url'] as String,
      logoUrl: json['logoUrl'] as String,
      category: json['category'] as String,
      isEnabled: json['isEnabled'] as bool? ?? false,
      maxArticles: json['maxArticles'] as int? ?? 15,
    );
  }
}
