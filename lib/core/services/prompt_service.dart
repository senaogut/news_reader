import '../../features/news/data/models/news_article.dart';
import '../../features/news/data/models/news_category.dart';

/// Service for creating Turkish-optimized prompts for LLM summarization
class PromptService {
  PromptService();

  /// All available category IDs for prompts
  static final String _categoryList = NewsCategory.allCategoryIds;

  /// Generates prompt for multiple articles covering the same story from different sources
  /// Returns structured JSON with brief summaries for each article + combined group summary
  String groupedArticlesPrompt(List<NewsArticle> articles) {
    final articlesText = articles
        .map((article) {
          // Truncate content to avoid excessive token usage
          final truncatedContent = article.content.length > 800
              ? '${article.content.substring(0, 800)}...'
              : article.content;
          return '''
Kaynak: ${article.sourceId}
Başlık: ${article.title}
İçerik: $truncatedContent
---''';
        })
        .join('\n');

    return '''Aynı haberi ${articles.length} farklı kaynaktan özetle ve kategorize et.

$articlesText

KATEGORİLER: $_categoryList

SADECE JSON dön (``` KULLANMA). KISA TUT:

{
  "category": "kategori_id",
  "groupSummary": "Birleşik özet (max 40 kelime)",
  "articles": [
    {"sourceId": "id", "briefSummary": "1 cümle (max 15 kelime)", "detailedSummary": "2 cümle (max 30 kelime)"}
  ]
}

Kurallar: KISA YAZ, JSON'u TAMAMLA, ``` kullanma, category listeden seç''';
  }

  /// Generates prompt for a single ungrouped article
  /// Returns structured JSON with brief and detailed summaries
  String singleArticlePrompt(NewsArticle article) {
    // Truncate content to avoid excessive token usage
    final truncatedContent = article.content.length > 1000
        ? '${article.content.substring(0, 1000)}...'
        : article.content;

    return '''Haberi özetle ve kategorize et:

Başlık: ${article.title}
İçerik: $truncatedContent

KATEGORİLER: $_categoryList

SADECE JSON dön (``` KULLANMA):

{"category": "kategori_id", "briefSummary": "1 cümle (max 15 kelime)", "detailedSummary": "2 cümle (max 30 kelime)"}

Kurallar: KISA YAZ, JSON'u TAMAMLA, category listeden seç''';
  }

  /// Generates prompt for overall daily summary across all articles
  String overallSummaryPrompt(List<String> articleSummaries, DateTime date) {
    final summariesText = articleSummaries
        .asMap()
        .entries
        .map((entry) {
          return '${entry.key + 1}. ${entry.value}';
        })
        .join('\n\n');

    return '''${date.day}/${date.month}/${date.year} tarihli ${articleSummaries.length} haberin özetlerini veriyorum. Günün genel özeti için kapsamlı bir metin oluştur:

$summariesText

ÇOK ÖNEMLİ: Yanıtını SADECE JSON formatında ver. Markdown kod bloğu kullanma (```json gibi). Sadece { ile başlayan düz JSON objesi dön.

JSON formatı:

{
  "overallSummary": "Günün tüm haberlerini kapsayan genel özet (4-5 paragraf)"
}

Önemli kurallar:
- En önemli haberleri vurgula
- Ana temaları ve gelişmeleri grupla
- Profesyonel haber diliyle yaz
- 4-5 paragraf uzunluğunda olmalı
- SADECE JSON dön, ``` veya açıklama ekleme''';
  }

  /// Generates batch prompt for processing all articles at once (for ≤20 articles)
  /// Handles both grouped and ungrouped articles
  String batchArticlesPrompt(List<NewsArticle> groupedArticles, List<NewsArticle> singleArticles) {
    final buffer = StringBuffer();
    buffer.writeln('Sana haber makaleleri veriyorum. İki kategori var:');
    buffer.writeln();

    if (groupedArticles.isNotEmpty) {
      buffer.writeln('A) GRUPLANAN HABERLER (aynı haberi farklı kaynaklardan aktaran):');
      buffer.writeln('${groupedArticles.length} makale');
      for (var article in groupedArticles) {
        buffer.writeln('''
Kaynak: ${article.sourceId}
Başlık: ${article.title}
İçerik: ${article.content}
---''');
      }
      buffer.writeln();
    }

    if (singleArticles.isNotEmpty) {
      buffer.writeln('B) TEKİL HABERLER (başka kaynaktan benzer haber yok):');
      buffer.writeln('${singleArticles.length} makale');
      for (var article in singleArticles) {
        buffer.writeln('''
Kaynak: ${article.sourceId}
Başlık: ${article.title}
İçerik: ${article.content}
---''');
      }
    }

    buffer.writeln('''

ÇOK ÖNEMLİ: Yanıtını SADECE JSON formatında ver. Markdown kod bloğu kullanma (```json gibi). Sadece { ile başlayan düz JSON objesi dön.

JSON formatı:

{
  "groupedArticles": [
    {
      "sourceId": "kaynak_id",
      "briefSummary": "TEK CÜMLE (max 20 kelime)",
      "detailedSummary": "2-3 cümle (max 50 kelime)"
    }
  ],
  "groupSummary": "Birleşik özet (max 3 cümle, 60 kelime)",
  "singleArticles": [
    {
      "sourceId": "kaynak_id",
      "briefSummary": "TEK CÜMLE (max 20 kelime)",
      "detailedSummary": "2-3 cümle (max 50 kelime)"
    }
  ]
}

Kurallar:
- briefSummary: SADECE 1 cümle, max 20 kelime
- detailedSummary: 2-3 cümle, max 50 kelime
- KISA VE ÖZ TUT
- Açık, net Türkçe
- SADECE JSON dön, ``` veya açıklama ekleme''');

    return buffer.toString();
  }
}
