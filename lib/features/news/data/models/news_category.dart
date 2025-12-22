/// Predefined news categories for AI-based classification
enum NewsCategory {
  politics('politics', 'Siyaset', '🏛️'),
  economy('economy', 'Ekonomi', '💰'),
  world('world', 'Dünya', '🌍'),
  sports('sports', 'Spor', '⚽'),
  technology('technology', 'Teknoloji', '💻'),
  health('health', 'Sağlık', '🏥'),
  culture('culture', 'Kültür & Sanat', '🎭'),
  science('science', 'Bilim', '🔬'),
  entertainment('entertainment', 'Magazin', '🎬'),
  education('education', 'Eğitim', '📚'),
  environment('environment', 'Çevre', '🌱'),
  crime('crime', 'Asayiş', '🚔'),
  other('other', 'Diğer', '📰');

  final String id;
  final String displayName;
  final String emoji;

  const NewsCategory(this.id, this.displayName, this.emoji);

  /// Get display name with emoji
  String get displayWithEmoji => '$emoji $displayName';

  /// Parse category from string (case-insensitive)
  static NewsCategory fromString(String? value) {
    if (value == null || value.isEmpty) return NewsCategory.other;

    final normalized = value.toLowerCase().trim();

    // Try exact match first
    for (final category in NewsCategory.values) {
      if (category.id == normalized || category.displayName.toLowerCase() == normalized) {
        return category;
      }
    }

    // Try partial match / common aliases
    return _matchAlias(normalized);
  }

  /// Match common Turkish aliases and variations
  static NewsCategory _matchAlias(String value) {
    // Politics
    if (_matches(value, ['siyaset', 'politika', 'gündem', 'politik', 'hükümet', 'meclis', 'seçim'])) {
      return NewsCategory.politics;
    }

    // Economy
    if (_matches(value, ['ekonomi', 'finans', 'borsa', 'dolar', 'euro', 'piyasa', 'iş', 'ticaret'])) {
      return NewsCategory.economy;
    }

    // World
    if (_matches(value, ['dünya', 'world', 'uluslararası', 'dış', 'global', 'yurtdışı'])) {
      return NewsCategory.world;
    }

    // Sports
    if (_matches(value, ['spor', 'futbol', 'basketbol', 'voleybol', 'tenis', 'formula'])) {
      return NewsCategory.sports;
    }

    // Technology
    if (_matches(value, ['teknoloji', 'tech', 'bilişim', 'yapay zeka', 'ai', 'internet', 'dijital', 'siber'])) {
      return NewsCategory.technology;
    }

    // Health
    if (_matches(value, ['sağlık', 'health', 'tıp', 'hastane', 'doktor', 'ilaç', 'covid', 'pandemi'])) {
      return NewsCategory.health;
    }

    // Culture & Arts
    if (_matches(value, ['kültür', 'sanat', 'kultur', 'müze', 'sergi', 'tiyatro', 'konser', 'edebiyat'])) {
      return NewsCategory.culture;
    }

    // Science
    if (_matches(value, ['bilim', 'science', 'araştırma', 'uzay', 'nasa', 'keşif', 'deney'])) {
      return NewsCategory.science;
    }

    // Entertainment / Magazine
    if (_matches(value, ['magazin', 'eğlence', 'ünlü', 'dizi', 'film', 'televizyon', 'müzik', 'oyuncu'])) {
      return NewsCategory.entertainment;
    }

    // Education
    if (_matches(value, ['eğitim', 'education', 'okul', 'üniversite', 'öğrenci', 'yks', 'sınav'])) {
      return NewsCategory.education;
    }

    // Environment
    if (_matches(value, ['çevre', 'iklim', 'doğa', 'environment', 'yeşil', 'enerji', 'karbon'])) {
      return NewsCategory.environment;
    }

    // Crime / Security
    if (_matches(value, ['asayiş', 'suç', 'polis', 'cinayet', 'kaza', 'adliye', 'mahkeme', 'hukuk', '3. sayfa'])) {
      return NewsCategory.crime;
    }

    return NewsCategory.other;
  }

  static bool _matches(String value, List<String> keywords) {
    for (final keyword in keywords) {
      if (value.contains(keyword)) return true;
    }
    return false;
  }

  /// Get all category IDs as a list (for prompt)
  static String get allCategoryIds => NewsCategory.values.map((c) => c.id).join(', ');
}
