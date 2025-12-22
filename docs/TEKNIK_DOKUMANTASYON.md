# Smart Reader - Kapsamlı Teknik Dokümantasyon

> **Versiyon:** 2.0.0  
> **Son Güncelleme:** Aralık 2025  
> **Durum:** Gerçek web kazıma ve yapay zeka özetleme ile üretime hazır

---

## 📖 Proje Genel Bakış

**Smart Reader**, aşağıdaki özelliklere sahip, üretime hazır bir Flutter haber toplama uygulamasıdır:
- 4 büyük Türk haber sitesinden gerçek zamanlı haber kazıma
- Akıllı özetler oluşturmak için **Google Gemini AI** kullanımı
- Farklı kaynaklardan benzer haberleri gruplama
- Yapay zeka destekli sınıflandırma ile haber kategorileme

---

## 🏗️ Tam Mimari Yapı

```
lib/
├── main.dart                           # ProviderScope ile uygulama giriş noktası
│
├── core/                               # Paylaşılan kaynaklar
│   ├── constants/
│   │   └── app_constants.dart          # Boşluk, boyut sabitleri
│   ├── services/
│   │   ├── prompt_service.dart         # LLM prompt oluşturma ✅
│   │   └── storage_service.dart        # Tercihler için yerel depolama
│   ├── theme/
│   │   ├── app_colors.dart             # Renk paleti
│   │   ├── app_text_styles.dart        # Tipografi
│   │   └── app_theme.dart              # Material tema
│   └── widgets/                        # Yeniden kullanılabilir UI bileşenleri
│
└── features/
    ├── news/                           # 📰 Ana özellik
    │   ├── data/
    │   │   ├── models/
    │   │   │   ├── news_source.dart        # Kaynak yapılandırması
    │   │   │   ├── news_article.dart       # Makale modeli
    │   │   │   ├── grouped_news.dart       # Gruplanmış makaleler
    │   │   │   ├── article_cluster.dart    # Kümeleme modeli
    │   │   │   ├── news_category.dart      # 13 önceden tanımlı kategori
    │   │   │   └── scraping_config.dart    # Kazıma ayarları
    │   │   ├── repositories/
    │   │   │   ├── news_source_repository.dart   # Kaynak yönetimi
    │   │   │   ├── news_scraper_repository.dart  # Kazıma orkestrasyon
    │   │   │   └── llm_repository.dart           # AI entegrasyonu ✅
    │   │   └── services/
    │   │       ├── haberturk_scraper.dart    # ✅ Gerçek kazıyıcı
    │   │       ├── hurriyet_scraper.dart     # ✅ Gerçek kazıyıcı
    │   │       ├── ntv_scraper.dart          # ✅ Gerçek kazıyıcı
    │   │       ├── sozcu_scraper.dart        # ✅ Gerçek kazıyıcı
    │   │       ├── article_grouper.dart      # Aynı haber tespiti
    │   │       └── parallel_scraper_service.dart  # Isolate desteği
    │   │
    │   └── presentation/
    │       ├── providers/
    │       │   ├── news_source_provider.dart
    │       │   └── news_feed_provider.dart
    │       ├── screens/
    │       └── widgets/
    │
    └── history/                        # 📚 Geçmiş özelliği
        ├── data/
        └── presentation/
```

---

## 🔧 Web Kazıma Sistemi

### Genel Bakış

Uygulama, HTTP istekleri için **Dio** ve HTML ayrıştırma için **html** paketini kullanır. Her haber kaynağının özel bir kazıyıcı sınıfı vardır.

### Desteklenen Haber Kaynakları

| Kaynak | URL | Kazıyıcı Sınıfı | Durum |
|--------|-----|-----------------|-------|
| **Habertürk** | haberturk.com | `HaberturkScraper` | ✅ Aktif |
| **NTV** | ntv.com.tr | `NtvScraper` | ✅ Aktif |
| **Sözcü** | sozcu.com.tr | `SozcuScraper` | ✅ Aktif |
| **Hürriyet** | hurriyet.com.tr | `HurriyetScraper` | ✅ Aktif |

### Web Kazıma Nasıl Çalışır

```
┌─────────────────────────────────────────────────────────────────┐
│                    NewsScraperRepository                         │
│                    scrapeSources()                               │
└─────────────────────────────────────────────────────────────────┘
                              │
              ┌───────────────┼───────────────┐
              ▼               ▼               ▼
     ┌────────────┐   ┌────────────┐   ┌────────────┐
     │ Habertürk  │   │    NTV     │   │   Sözcü    │  ... (paralel)
     │  Kazıyıcı  │   │  Kazıyıcı  │   │  Kazıyıcı  │
     └────────────┘   └────────────┘   └────────────┘
              │               │               │
              ▼               ▼               ▼
     ┌────────────────────────────────────────────┐
     │           Future.wait() (TAM PARALEL)      │
     │   Tüm kaynaklar aynı anda kazınır!         │
     └────────────────────────────────────────────┘
```

### Kazıma Süreci (Her Kaynak İçin)

1. **Ana Sayfa Getirme**: Haber sitesi ana sayfasından HTML indirme
2. **Makale Bağlantılarını Çıkarma**: Makale URL'lerini bulmak için CSS seçicileri kullanma
3. **URL Filtreleme**: Videoları, galerileri, makale olmayan sayfaları atlama
4. **Makale Sayfalarını Getirme**: Eşzamanlı getirme (aynı anda 5 makale)
5. **İçerik Ayrıştırma**: Başlık, içerik, görsel, yazar, tarih çıkarma
6. **Model Oluşturma**: `NewsArticle` nesneleri oluşturma

### Kazıyıcı Uygulama Detayları

```dart
// Örnek: HaberturkScraper
class HaberturkScraper {
  final Dio _dio;
  static const String baseUrl = 'https://www.haberturk.com';
  static const int _concurrentFetches = 5;

  Future<List<NewsArticle>> scrapeMainPage({
    required NewsSource source, 
    required ScrapingConfig config
  }) async {
    // 1. Ana sayfayı getir
    final response = await _dio.get(baseUrl);
    final document = html_parser.parse(response.data);
    
    // 2. CSS seçicileri kullanarak makale bağlantılarını çıkar
    final articleLinks = _extractArticleLinks(document, maxCount);
    
    // 3. Makaleleri paralel gruplar halinde getir
    for (int i = 0; i < articleLinks.length; i += _concurrentFetches) {
      final results = await Future.wait(
        batch.map((link) => _scrapeArticleDetail(url: link['url']!))
      );
      articles.addAll(results.whereType<NewsArticle>());
    }
    
    return articles;
  }
}
```

### Kullanılan CSS Seçicileri

| Kaynak | Seçici Stratejisi |
|--------|-------------------|
| **Habertürk** | `a.gtm-tracker[href][data-newsid]`, yedek olarak `a[data-newsid]` |
| **NTV** | `a[href*="/turkiye/"]`, `a[href*="/dunya/"]`, vb. kategoriye göre |
| **Hürriyet** | `.home-carousel .swiper-slide a[href]` 8 haneli ID deseni ile |
| **Sözcü** | `a[href]` `-pXXXXXX` URL deseni ile |

### İçerik Çıkarma

Her kazıyıcı şunları çıkarır:
- **Başlık**: `og:title` meta etiketinden veya `<h1>`'den
- **Açıklama**: `description` meta etiketinden
- **Yazar**: `articleAuthor` veya `author` meta etiketlerinden
- **Tarih**: `datePublished` / `dateModified` meta etiketlerinden
- **Görsel**: `og:image` meta etiketinden
- **İçerik**: Makale gövde konteynerlerinden (`.cms-container`, `.news-content`, vb.)
- **Anahtar Kelimeler**: `keywords` meta etiketinden

### HTTP Yapılandırması

```dart
Dio(BaseOptions(
  connectTimeout: Duration(seconds: 30),
  receiveTimeout: Duration(seconds: 30),
  headers: {
    'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)...',
    'Accept': 'text/html,application/xhtml+xml,application/xml...',
    'Accept-Language': 'tr-TR,tr;q=0.9,en-US;q=0.8,en;q=0.7',
  },
))
```

### Kazıma Yapılandırması

```dart
class ScrapingConfig {
  final int? maxArticlesPerSource;     // Varsayılan: kaynak başına 15
  final int requestDelayMs;            // Varsayılan: 500ms
  final int requestTimeoutSeconds;     // Varsayılan: 30 saniye
  final bool fetchFullContent;         // Varsayılan: true
  final int maxConcurrentSources;      // Varsayılan: 3
}

// Hazır Ayarlar
ScrapingConfig.defaultConfig  // Dengeli
ScrapingConfig.quickFetch     // 5 makale, tam içerik yok
ScrapingConfig.fullFetch      // 20 makale, tam içerik
```

---

## 🤖 Yapay Zeka Özetleme Sistemi

### Genel Bakış

Uygulama, akıllı özetleme ve kategorileme için **Google Gemini 2.5 Flash** API kullanır.

### API Yapılandırması

```dart
class GeminiLlmRepository implements LlmRepository {
  static const String _apiKey = 'API_ANAHTARINIZ';
  
  late final GenerativeModel _model;
  
  GeminiLlmRepository() {
    _model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: _apiKey,
      generationConfig: GenerationConfig(
        temperature: 0.3,      // Olgusal özetler için düşük
        maxOutputTokens: 4096,
        topP: 0.95,
      ),
    );
  }
}
```

### LLM Repository Arayüzü

```dart
abstract class LlmRepository {
  /// Haber kartları için kısa özet oluştur (1-2 cümle)
  Future<String> generateBriefSummary(String content);

  /// Makale detay ekranı için ayrıntılı özet oluştur
  Future<String> generateDetailedSummary(String content);

  /// Birden fazla makaleden birleşik özet oluştur
  Future<String> generateCombinedSummary(List<NewsArticle> articles);

  /// Makale kümesini özetler + kategori ile işle
  Future<ClusterSummaryResult> processCluster(ArticleCluster cluster);

  /// Birden fazla kümeyi eşzamanlı olarak toplu işle
  Future<List<ClusterSummaryResult>> batchProcessClusters(List<ArticleCluster> clusters);
}
```

### AI İşleme Akışı

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│ Kazınan Makaleler────▶│ ArticleGrouper  │────▶│ Makale Kümeleri │
│    (ham veri)   │     │  (aynı haber)   │     │  (gruplanmış)   │
└─────────────────┘     └─────────────────┘     └─────────────────┘
                                                        │
                                                        ▼
                              ┌────────────────────────────────────┐
                              │        LlmRepository               │
                              │     batchProcessClusters()         │
                              │                                    │
                              │  ┌──────────────────────────────┐  │
                              │  │   Future.wait() (PARALEL)    │  │
                              │  │   Tüm kümeler Gemini API     │  │
                              │  │   ile aynı anda işlenir      │  │
                              │  └──────────────────────────────┘  │
                              └────────────────────────────────────┘
                                                        │
                                                        ▼
                              ┌────────────────────────────────────┐
                              │        Her küme için:              │
                              │  • Makale başına kısa özet         │
                              │  • Makale başına ayrıntılı özet    │
                              │  • Grup özeti (çoklu kaynak ise)   │
                              │  • AI tarafından belirlenen kategori│
                              └────────────────────────────────────┘
```

### Prompt Servisi

`PromptService`, optimize edilmiş Türkçe promptlar oluşturur:

```dart
class PromptService {
  /// Gruplanmış makaleler için (aynı haber, birden fazla kaynak)
  String groupedArticlesPrompt(List<NewsArticle> articles) {
    return '''Aynı haberi ${articles.length} farklı kaynaktan özetle ve kategorize et.

$articlesText

KATEGORİLER: $_categoryList

SADECE JSON dön (``` KULLANMA). KISA TUT:

{
  "category": "kategori_id",
  "groupSummary": "Birleşik özet (max 40 kelime)",
  "articles": [
    {"sourceId": "id", "briefSummary": "1 cümle", "detailedSummary": "2 cümle"}
  ]
}''';
  }

  /// Tekil makaleler için
  String singleArticlePrompt(NewsArticle article) {
    return '''Haberi özetle ve kategorize et:
Başlık: ${article.title}
İçerik: $truncatedContent

KATEGORİLER: $_categoryList

SADECE JSON dön:
{"category": "id", "briefSummary": "...", "detailedSummary": "..."}''';
  }
}
```

### JSON Yanıt İşleme

LLM repository güçlü JSON ayrıştırma içerir:

```dart
// Kontrol karakterlerini temizle ve JSON çıkar
String _extractAndCleanJson(String text) {
  // Markdown kod bloklarını kaldır
  // String içindeki kaçırılmamış tırnakları düzelt
  // Kesik yanıtları işle
}

// Bozuk JSON'dan kısmi veri kurtar
Map<String, dynamic> _tryRecoverPartialJson(String brokenJson) {
  // Kurtarılabilecek her veriyi çıkar
}
```

---

## 📊 Haber Kategorilendirme

### 13 Önceden Tanımlı Kategori

```dart
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
}
```

### Kategorilendirme Yöntemleri

1. **AI Tabanlı (Birincil)**: Gemini içeriği analiz eder ve kategori ID'si döndürür
2. **Anahtar Kelime Yedek**: AI başarısız olursa, `NewsCategory.fromString()` anahtar kelime eşleştirmesi kullanır:

```dart
static NewsCategory fromString(String? value) {
  if (_matches(value, ['siyaset', 'politics', 'meclis', 'cumhurbaşkan'])) {
    return NewsCategory.politics;
  }
  if (_matches(value, ['ekonomi', 'economy', 'borsa', 'dolar', 'euro'])) {
    return NewsCategory.economy;
  }
  // ... daha fazla desen
}
```

---

## 🔗 Makale Gruplama (Aynı Haber Tespiti)

### Genel Bakış

`ArticleGrouper` servisi, **aynı haber hikayesini** kapsayan **farklı kaynaklardan** makaleleri gruplar.

### Algoritma

```dart
class ArticleGrouper {
  static const double _similarityThreshold = 0.35;

  double _calculateSimilarity(NewsArticle a, NewsArticle b) {
    // Aynı kaynaktan makaleleri asla gruplama
    if (a.sourceId == b.sourceId) return 0.0;

    // Çok faktörlü benzerlik puanlaması:
    final titleSimilarity = _calculateTitleSimilarity(a.title, b.title);     // %30
    final entitySimilarity = _calculateEntityOverlap(a.title, b.title);      // %35
    final keywordSimilarity = _calculateKeywordOverlap(a.title, b.title);    // %25
    final categoryBonus = _calculateCategoryBonus(a.category, b.category);   // %10

    return (titleSimilarity * 0.30) + 
           (entitySimilarity * 0.35) + 
           (keywordSimilarity * 0.25) + 
           (categoryBonus * 0.10);
  }
}
```

### Benzerlik Faktörleri

| Faktör | Ağırlık | Yöntem |
|--------|---------|--------|
| Başlık Kelimeleri | %30 | Kelime kümelerinin Jaccard benzerliği |
| Özel İsimler | %35 | Özel isimlerin, adların örtüşmesi |
| Anahtar Kelimeler | %25 | Ortak önemli kelimeler |
| Kategori | %10 | Aynı kategoriyse bonus |

### Çıktı Yapısı

```dart
class ArticleCluster {
  final List<NewsArticle> articles;
  final double similarityScore;
  
  bool get isMultiSource => articles.length > 1;
  NewsArticle get representative => articles.first;
}
```

---

## 📦 Bağımlılıklar ve Teknolojiler

### Temel Bağımlılıklar

| Paket | Versiyon | Amaç |
|-------|----------|------|
| `flutter_riverpod` | 3.0.3 | Notifier'lar ile durum yönetimi |
| `dio` | 5.4.3+1 | Web kazıma için HTTP istemcisi |
| `html` | 0.15.6 | HTML DOM ayrıştırma |
| `google_generative_ai` | 0.4.6 | Gemini AI API istemcisi |
| `cached_network_image` | 3.4.1 | Görsel önbellekleme |
| `google_fonts` | 6.2.1 | Tipografi (Epilogue) |

### Depolama Bağımlılıkları

| Paket | Versiyon | Amaç |
|-------|----------|------|
| `sqflite` | 2.4.2 | Geçmiş kalıcılığı için SQLite |
| `flutter_secure_storage` | 9.2.4 | Güvenli API anahtarı depolama |

---

## ⚙️ Durum Yönetimi (Riverpod 3.0)

### Provider Mimarisi

```dart
// Repository Provider'ları (Bağımlılık Enjeksiyonu)
final newsScraperRepositoryProvider = Provider<NewsScraperRepository>((ref) {
  return DefaultNewsScraperRepository();
});

final llmRepositoryProvider = Provider<LlmRepository>((ref) {
  return GeminiLlmRepository();  // Gerçek Gemini uygulaması
});

// Durum Notifier'ları
final newsFeedNotifierProvider = NotifierProvider<NewsFeedNotifier, NewsFeedState>(() {
  return NewsFeedNotifier();
});
```

### Tam Veri Akışı

```
Kullanıcı "Haberleri Getir"e tıklar
        │
        ▼
NewsFeedNotifier.fetchNews(enabledSources)
        │
        ├──▶ NewsScraperRepository.scrapeSources()
        │           │
        │           ▼
        │    [Paralel kazıma: Habertürk, NTV, Sözcü, Hürriyet]
        │           │
        │           ▼
        │    List<NewsArticle> (ham makaleler)
        │
        ├──▶ ArticleGrouper.groupArticles()
        │           │
        │           ▼
        │    List<ArticleCluster> (aynı habere göre gruplanmış)
        │
        ├──▶ LlmRepository.batchProcessClusters()
        │           │
        │           ▼
        │    [Paralel AI: tüm kümeler için özetler + kategoriler]
        │           │
        │           ▼
        │    List<ClusterSummaryResult>
        │
        ▼
NewsFeedState güncellenir → UI, GroupedNews kartları ile yeniden oluşturulur
```

---

## 🎨 UI Bileşenleri

### Ekran Yapısı

| Ekran | Amaç |
|-------|------|
| `HomeScreen` | 3 sekmeli navigasyon (Akış, Kaynaklar, Geçmiş) |
| `NewsSourcesScreen` | Haber kaynaklarını aç/kapat |
| `ArticleDetailScreen` | AI özetli tekil makale |
| `GroupedNewsDetailScreen` | Çoklu kaynak haber karşılaştırması |
| `HistoryScreen` | Geçmiş getirme oturumları |

### Önemli Widget'lar

| Widget | Amaç |
|--------|------|
| `GroupedNewsCard` | Kaynak rozetleri, AI özeti ile haber kartı |
| `NewsLoadingShimmer` | İskelet yükleme animasyonu |
| `CompareSourcesSheet` | Kaynak karşılaştırması için alt sayfa |

---

## 🔐 API Anahtarları ve Güvenlik

### Mevcut Kurulum

Gemini API anahtarı şu anda sabit kodlanmış (geliştirme için):

```dart
static const String _apiKey = 'AIzaSy...';
```

### Planlanan Güvenlik

- API anahtarlarını `flutter_secure_storage`'da sakla
- CI/CD için ortam değişkenlerini kullan
- Anahtar rotasyonu uygula

---

## 📈 Performans Optimizasyonları

### Paralel İşleme

1. **Kaynak Kazıma**: Tüm 4 kaynak `Future.wait()` ile eşzamanlı kazınır
2. **Makale Getirme**: Her kaynak içinde 5 makale eşzamanlı getirilir
3. **AI İşleme**: Tüm kümeler Gemini API üzerinden paralel işlenir

### Hız Sınırlaması

- **Kazıma**: Gruplar arası 500ms gecikme (yapılandırılabilir)
- **Gemini API**: Gemini 2.5 Flash ile 90 RPM kapasitesi

### Önbellekleme

- Görseller `cached_network_image` ile önbelleklenir
- Kaynak tercihleri yerel depolamaya kaydedilir

---

## ✅ Mevcut Durum

### Tamamlanan ✅

- [x] Gerçek web kazıma (4 Türk haber kaynağı)
- [x] Paralel kaynak kazıma
- [x] Gemini AI entegrasyonu (özetler + kategoriler)
- [x] Makale gruplama (aynı haber tespiti)
- [x] 13 kategorili sınıflandırma
- [x] Türkçe optimize promptlar
- [x] JSON yanıt kurtarma (kısmi yanıtları işler)
- [x] Yükleme durumları ile tam UI
- [x] Kaynak tercihi kalıcılığı
- [x] Geçmiş takibi (bellek içi)

### Planlanan 📋

- [ ] Geçmiş için SQLite kalıcılığı
- [ ] Güvenli API anahtarı depolama
- [ ] Karanlık mod
- [ ] Çekerek yenileme
- [ ] Çevrimdışı okuma modu
- [ ] Daha fazla haber kaynağı (uluslararası)

---

## 🚀 Başlarken

```bash
# Klonla ve Yükle
git clone https://github.com/senaogut/smart_reader.git
cd smart_reader
flutter pub get

# Çalıştır
flutter run
```

### API Anahtarı Kurulumu

`lib/features/news/data/repositories/llm_repository.dart` dosyasındaki Gemini API anahtarını değiştirin:

```dart
static const String _apiKey = 'GEMINI_API_ANAHTARINIZ';
```

---

*Dokümantasyon Aralık 2025'te oluşturulmuştur*
