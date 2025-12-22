import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart';

import 'parallel_scraper_service.dart';

// =============================================================================
// ISOLATE-SAFE PARSING FUNCTIONS
// 
// These are TOP-LEVEL functions that can be passed to Isolate.run()
// They must NOT capture any closures or reference instance methods.
// All data needed for parsing must be passed as parameters.
// =============================================================================

// -----------------------------------------------------------------------------
// NTV PARSING
// -----------------------------------------------------------------------------

/// Parse NTV article HTML - TOP-LEVEL function for Isolate
ParsedArticleData? parseNtvArticle(String html, String url) {
  try {
    final document = html_parser.parse(html);
    
    // Extract from meta tags
    final title = _getMetaContent(document, 'og:title') ??
        _getMetaContent(document, 'title') ??
        document.querySelector('h1')?.text.trim() ??
        '';

    // Clean title
    final cleanTitle = title.replaceAll(RegExp(r'\s*\|\s*NTV\s*Haber\s*$'), '').trim();
    if (cleanTitle.isEmpty) return null;

    final description = _getMetaContent(document, 'description') ?? 
        _getMetaContent(document, 'og:description') ?? '';

    final author = _getMetaContent(document, 'author') ?? 
        _getMetaContent(document, 'articleAuthor');

    final datePublished = _getMetaContent(document, 'datePublished');
    final dateModified = _getMetaContent(document, 'dateModified');

    final imageUrl = _getMetaContent(document, 'og:image');

    final keywordsStr = _getMetaContent(document, 'keywords') ?? '';
    final keywords = keywordsStr.isNotEmpty 
        ? keywordsStr.split(',').map((k) => k.trim()).toList() 
        : <String>[];

    // Extract category
    final category = _getMetaContent(document, 'dyg:category') ?? 
        _getMetaContent(document, 'articleSection') ?? 'Genel';

    // Extract article ID from URL
    final articleId = _extractNtvArticleId(url);

    // Extract article content
    final content = _extractNtvArticleContent(document);
    final finalContent = content.isNotEmpty ? content : description;

    return ParsedArticleData(
      id: articleId,
      title: cleanTitle,
      url: url,
      imageUrl: imageUrl,
      content: finalContent,
      category: category,
      author: author,
      keywords: keywords,
      publishedAtIso: _parseDateToIso(datePublished),
      modifiedAtIso: _parseDateToIso(dateModified),
    );
  } catch (e) {
    return null;
  }
}

String _extractNtvArticleId(String url) {
  final idMatch = RegExp(r'-(\d{7})$').firstMatch(url);
  if (idMatch != null) {
    return idMatch.group(1)!;
  }
  return DateTime.now().millisecondsSinceEpoch.toString();
}

String _extractNtvArticleContent(Document document) {
  final contentBuffer = StringBuffer();

  // NTV uses Next.js and embeds content in script tags as JSON
  final scripts = document.querySelectorAll('script');
  for (final script in scripts) {
    final scriptText = script.text;

    if (scriptText.contains('\\u003cp\\u003e')) {
      final contentMatch = RegExp(r'"((?:\\u003cp\\u003e.+?\\u003c/p\\u003e)+)"').firstMatch(scriptText);
      if (contentMatch != null) {
        var encodedContent = contentMatch.group(1) ?? '';

        encodedContent = encodedContent
            .replaceAll(r'\u003c', '<')
            .replaceAll(r'\u003e', '>')
            .replaceAll(r'\u0026', '&')
            .replaceAll(r'\\u0026nbsp;', ' ')
            .replaceAll(r'\u0026nbsp;', ' ')
            .replaceAll(r'&nbsp;', ' ')
            .replaceAll(r'\"', '"')
            .replaceAll(r'\/', '/');

        final contentDoc = html_parser.parse(encodedContent);
        final paragraphs = contentDoc.querySelectorAll('p');

        for (final p in paragraphs) {
          final text = p.text.trim();
          if (text.isNotEmpty && text.length > 20) {
            contentBuffer.writeln(text);
            contentBuffer.writeln();
          }
        }

        if (contentBuffer.isNotEmpty) break;
      }
    }
  }

  // Fallback: Try standard content containers
  if (contentBuffer.isEmpty) {
    final selectors = [
      'article[property="articleBody"]',
      '.article-content',
      '.news-content',
      'div[itemprop="articleBody"]',
      '.ck-content',
      '.text-black.ck',
    ];

    for (final selector in selectors) {
      final container = document.querySelector(selector);
      if (container != null) {
        final paragraphs = container.querySelectorAll('p');
        for (final p in paragraphs) {
          final text = p.text.trim();
          if (text.isNotEmpty && text.length > 20) {
            contentBuffer.writeln(text);
            contentBuffer.writeln();
          }
        }
        if (contentBuffer.isNotEmpty) break;
      }
    }
  }

  return contentBuffer.toString().trim();
}

// -----------------------------------------------------------------------------
// HABERTÜRK PARSING
// -----------------------------------------------------------------------------

/// Parse Habertürk article HTML - TOP-LEVEL function for Isolate
ParsedArticleData? parseHaberturkArticle(String html, String url) {
  try {
    final document = html_parser.parse(html);

    final title = _getMetaContent(document, 'title') ??
        _getMetaContent(document, 'og:title') ??
        document.querySelector('h1')?.text.trim() ??
        '';

    if (title.isEmpty) return null;

    final description = _getMetaContent(document, 'description') ?? 
        _getMetaContent(document, 'og:description') ?? '';

    final author = _getMetaContent(document, 'articleAuthor');

    final datePublished = _getMetaContent(document, 'datePublished');
    final dateModified = _getMetaContent(document, 'dateModified');

    final imageUrl = _getMetaContent(document, 'og:image');

    final keywordsStr = _getMetaContent(document, 'keywords') ?? '';
    final keywords = keywordsStr.isNotEmpty 
        ? keywordsStr.split(',').map((k) => k.trim()).toList() 
        : <String>[];

    final category = _extractHaberturkCategory(document);
    final articleId = _extractHaberturkArticleId(url, document);
    final content = _extractHaberturkArticleContent(document);
    final finalContent = content.isNotEmpty ? content : description;

    return ParsedArticleData(
      id: articleId,
      title: title,
      url: url,
      imageUrl: imageUrl,
      content: finalContent,
      category: category,
      author: author,
      keywords: keywords,
      publishedAtIso: _parseDateToIso(datePublished),
      modifiedAtIso: _parseDateToIso(dateModified),
    );
  } catch (e) {
    return null;
  }
}

String _extractHaberturkCategory(Document document) {
  final metaCategory = _getMetaContent(document, 'articleSection');
  if (metaCategory != null && metaCategory.isNotEmpty) {
    return metaCategory;
  }

  final breadcrumbs = document.querySelectorAll('.widget-breadcrumb a');
  if (breadcrumbs.length >= 2) {
    return breadcrumbs[1].text.trim();
  }

  final scripts = document.querySelectorAll('script');
  for (final script in scripts) {
    final text = script.text;
    if (text.contains('customdimension')) {
      final categoryMatch = RegExp(r'"category1"\s*=\s*"([^"]+)"').firstMatch(text);
      if (categoryMatch != null) {
        return categoryMatch.group(1) ?? 'Genel';
      }
    }
  }

  return 'Genel';
}

String _extractHaberturkArticleId(String url, Document document) {
  final article = document.querySelector('article[data-id]');
  if (article != null) {
    final id = article.attributes['data-id'];
    if (id != null && id.isNotEmpty) return id;
  }

  final idMatch = RegExp(r'-(\d{6,})(?:\?|$)').firstMatch(url);
  if (idMatch != null) {
    return idMatch.group(1) ?? '';
  }

  return DateTime.now().millisecondsSinceEpoch.toString();
}

String _extractHaberturkArticleContent(Document document) {
  final contentBuffer = StringBuffer();

  final container = document.querySelector('.cms-container');
  if (container != null) {
    final elements = container.querySelectorAll('p, h2');
    for (final element in elements) {
      final text = element.text.trim();
      if (text.isNotEmpty) {
        contentBuffer.writeln(text);
        contentBuffer.writeln();
      }
    }
  }

  if (contentBuffer.isEmpty) {
    final articleBody = document.querySelector('article[property="articleBody"]');
    if (articleBody != null) {
      final paragraphs = articleBody.querySelectorAll('p');
      for (final p in paragraphs) {
        final text = p.text.trim();
        if (text.isNotEmpty) {
          contentBuffer.writeln(text);
          contentBuffer.writeln();
        }
      }
    }
  }

  return contentBuffer.toString().trim();
}

// -----------------------------------------------------------------------------
// HÜRRİYET PARSING
// -----------------------------------------------------------------------------

/// Parse Hürriyet article HTML - TOP-LEVEL function for Isolate
ParsedArticleData? parseHurriyetArticle(String html, String url) {
  try {
    final document = html_parser.parse(html);

    final title = _getMetaContent(document, 'og:title') ??
        _getMetaContent(document, 'title') ??
        document.querySelector('h1')?.text.trim() ??
        '';

    final cleanTitle = title.replaceAll(RegExp(r'\s*-\s*Hürriyet.*$'), '').trim();
    if (cleanTitle.isEmpty) return null;

    final description = _getMetaContent(document, 'description') ?? 
        _getMetaContent(document, 'og:description') ?? '';

    final author = _getMetaContent(document, 'article:author') ?? 
        _getMetaContent(document, 'author') ?? 'Hürriyet';

    final datePublished = _getMetaContent(document, 'datePublished') ?? 
        _getMetaContent(document, 'article:published_time');
    final dateModified = _getMetaContent(document, 'dateModified') ?? 
        _getMetaContent(document, 'article:modified_time');

    final imageUrl = _getMetaContent(document, 'og:image');

    final keywordsStr = _getMetaContent(document, 'keywords') ?? '';
    final keywords = keywordsStr.isNotEmpty 
        ? keywordsStr.split(',').map((k) => k.trim()).toList() 
        : <String>[];

    final category = _getMetaContent(document, 'article:section') ?? 'Genel';
    final articleId = _getMetaContent(document, 'article:id') ?? _extractHurriyetArticleId(url);
    final content = _extractHurriyetArticleContent(document);
    final finalContent = content.isNotEmpty ? content : description;

    return ParsedArticleData(
      id: articleId,
      title: cleanTitle,
      url: url,
      imageUrl: imageUrl,
      content: finalContent,
      category: category,
      author: author,
      keywords: keywords,
      publishedAtIso: _parseDateToIso(datePublished),
      modifiedAtIso: _parseDateToIso(dateModified),
    );
  } catch (e) {
    return null;
  }
}

String _extractHurriyetArticleId(String url) {
  final idMatch = RegExp(r'-(\d{8})(?:\?|$)').firstMatch(url);
  if (idMatch != null) {
    return idMatch.group(1) ?? '';
  }

  final fallbackMatch = RegExp(r'-(\d+)').allMatches(url).lastOrNull;
  if (fallbackMatch != null) {
    return fallbackMatch.group(1)!;
  }

  return url.hashCode.abs().toString();
}

String _extractHurriyetArticleContent(Document document) {
  final contentBuffer = StringBuffer();

  final container = document.querySelector('.news-content');
  if (container != null) {
    final paragraphs = container.querySelectorAll('p');
    for (final p in paragraphs) {
      final text = p.text.trim();
      if (text.isNotEmpty && 
          !text.startsWith('Haberin Devamı') && 
          !text.contains('Reklam') && 
          text.length > 20) {
        contentBuffer.writeln(text);
        contentBuffer.writeln();
      }
    }
  }

  if (contentBuffer.isEmpty) {
    final detailContent = document.querySelector('.news-detail-content');
    if (detailContent != null) {
      final paragraphs = detailContent.querySelectorAll('p');
      for (final p in paragraphs) {
        final text = p.text.trim();
        if (text.isNotEmpty && text.length > 20) {
          contentBuffer.writeln(text);
          contentBuffer.writeln();
        }
      }
    }
  }

  if (contentBuffer.isEmpty) {
    final h2Elements = document.querySelectorAll('h2');
    for (final h2 in h2Elements) {
      final text = h2.text.trim();
      if (text.isNotEmpty && text.length > 20) {
        contentBuffer.writeln(text);
        contentBuffer.writeln();
      }
    }
  }

  return contentBuffer.toString().trim();
}

// -----------------------------------------------------------------------------
// SÖZCÜ PARSING
// -----------------------------------------------------------------------------

/// Parse Sözcü article HTML - TOP-LEVEL function for Isolate
ParsedArticleData? parseSozcuArticle(String html, String url) {
  try {
    final document = html_parser.parse(html);

    final title = _getMetaContent(document, 'og:title') ??
        _getMetaContent(document, 'title') ??
        document.querySelector('h1')?.text.trim() ??
        '';

    final cleanTitle = title.replaceAll(RegExp(r'\s*-\s*Sözcü\s*$'), '').trim();
    if (cleanTitle.isEmpty) return null;

    final description = _getMetaContent(document, 'description') ?? 
        _getMetaContent(document, 'og:description') ?? '';

    final author = _getMetaContent(document, 'author') ?? 
        _getMetaContent(document, 'articleAuthor');

    final datePublished = _getMetaContent(document, 'datePublished') ?? 
        _getMetaContent(document, 'article:published_time');
    final dateModified = _getMetaContent(document, 'dateModified') ?? 
        _getMetaContent(document, 'article:modified_time');

    final imageUrl = _getMetaContent(document, 'og:image');

    final keywordsStr = _getMetaContent(document, 'keywords') ?? 
        _getMetaContent(document, 'news_keywords') ?? '';
    final keywords = keywordsStr.isNotEmpty 
        ? keywordsStr.split(',').map((k) => k.trim()).toList() 
        : <String>[];

    final category = _getMetaContent(document, 'articleSection') ?? 
        _getMetaContent(document, 'article:section') ?? 'Genel';

    final articleId = _extractSozcuArticleId(url, document);
    final content = _extractSozcuArticleContent(document);
    final finalContent = content.isNotEmpty ? content : description;

    return ParsedArticleData(
      id: articleId,
      title: cleanTitle,
      url: url,
      imageUrl: imageUrl,
      content: finalContent,
      category: category,
      author: author,
      keywords: keywords,
      publishedAtIso: _parseDateToIso(datePublished),
      modifiedAtIso: _parseDateToIso(dateModified),
    );
  } catch (e) {
    return null;
  }
}

String _extractSozcuArticleId(String url, Document document) {
  final article = document.querySelector('article[data-id]');
  if (article != null) {
    final id = article.attributes['data-id'];
    if (id != null && id.isNotEmpty) return id;
  }

  final numberMatch = RegExp(r'-p(\d{6})$').firstMatch(url);
  if (numberMatch != null) {
    return numberMatch.group(1)!;
  }

  final fallbackMatch = RegExp(r'-(\d+)').allMatches(url).lastOrNull;
  if (fallbackMatch != null) {
    return fallbackMatch.group(1)!;
  }

  return url.hashCode.abs().toString();
}

String _extractSozcuArticleContent(Document document) {
  final contentBuffer = StringBuffer();

  final selectors = [
    '.article-body[property="articleBody"]',
    '.article-body',
    'article[property="articleBody"]',
    '.content-element',
    '.article-content',
    '.news-content',
    'div[itemprop="articleBody"]',
    '.news-detail-text',
  ];

  for (final selector in selectors) {
    final container = document.querySelector(selector);
    if (container != null) {
      final elements = container.querySelectorAll('p, h2, h3, h4');
      for (final element in elements) {
        final text = element.text.trim();
        if (text.isNotEmpty &&
            text.length > 10 &&
            !text.startsWith('<!--') &&
            !text.contains('StartFragment') &&
            !text.contains('EndFragment') &&
            text != '&nbsp;') {
          contentBuffer.writeln(text);
          contentBuffer.writeln();
        }
      }
      if (contentBuffer.isNotEmpty) break;
    }
  }

  return contentBuffer.toString().trim();
}

// -----------------------------------------------------------------------------
// SHARED UTILITIES (for use within Isolates)
// -----------------------------------------------------------------------------

/// Get content from a meta tag - works in Isolate
String? _getMetaContent(Document document, String name) {
  // Try name attribute
  var element = document.querySelector('meta[name="$name"]');
  if (element != null) {
    return element.attributes['content'];
  }

  // Try property attribute (for og: tags)
  element = document.querySelector('meta[property="$name"]');
  return element?.attributes['content'];
}

/// Parse date string to ISO format - works in Isolate
String? _parseDateToIso(String? dateStr) {
  if (dateStr == null || dateStr.isEmpty) return null;
  try {
    return DateTime.parse(dateStr).toIso8601String();
  } catch (e) {
    return null;
  }
}
