import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../data/models/grouped_news.dart';
import '../../data/models/news_article.dart';

/// Screen showing detailed view of grouped news from multiple sources
class GroupedNewsDetailScreen extends StatefulWidget {
  final GroupedNews groupedNews;

  const GroupedNewsDetailScreen({super.key, required this.groupedNews});

  @override
  State<GroupedNewsDetailScreen> createState() => _GroupedNewsDetailScreenState();
}

class _GroupedNewsDetailScreenState extends State<GroupedNewsDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: widget.groupedNews.articles.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            // App bar with image - shows current tab's image
            SliverAppBar(
              expandedHeight: 250,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                background: AnimatedBuilder(
                  animation: _tabController,
                  builder: (context, child) {
                    final currentArticle = widget.groupedNews.articles[_tabController.index];
                    return currentArticle.imageUrl != null
                        ? CachedNetworkImage(
                            imageUrl: currentArticle.imageUrl!,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: AppColors.containerBg,
                              child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: AppColors.containerBg,
                              child: const Icon(Icons.image_not_supported, size: 64, color: AppColors.textTertiary),
                            ),
                          )
                        : Container(
                            color: AppColors.containerBg,
                            child: const Icon(Icons.article, size: 64, color: AppColors.textTertiary),
                          );
                  },
                ),
              ),
            ),
            // Aggregated summary section (shown once, above tabs)
            SliverToBoxAdapter(
              child: Container(
                color: AppColors.surface,
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Multi-source indicator
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [AppColors.primary.withAlpha(26), AppColors.secondary.withAlpha(26)],
                            ),
                            borderRadius: BorderRadius.circular(AppBorderRadius.xs),
                            border: Border.all(color: AppColors.primary.withAlpha(77)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.merge_type, color: AppColors.primary, size: 14),
                              const SizedBox(width: AppSpacing.xs),
                              Text(
                                '${widget.groupedNews.sourceCount} Sources',
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          widget.groupedNews.categoryDisplay,
                          style: const TextStyle(
                            color: AppColors.textTertiary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          _formatDate(widget.groupedNews.articles.first.publishedAt),
                          style: const TextStyle(color: AppColors.textTertiary, fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    // Title
                    Text(
                      widget.groupedNews.articles.first.title,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    // Aggregated AI Summary
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.primary.withAlpha(20), AppColors.secondary.withAlpha(20)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(AppBorderRadius.md),
                        border: Border.all(color: AppColors.primary.withAlpha(51)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withAlpha(38),
                                  borderRadius: BorderRadius.circular(AppBorderRadius.xs),
                                ),
                                child: const Icon(Icons.auto_awesome, color: AppColors.primary, size: 18),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              const Text(
                                'AI Overview',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.primary),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withAlpha(38),
                                  borderRadius: BorderRadius.circular(AppBorderRadius.xs),
                                ),
                                child: const Text(
                                  'All Sources',
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.primary),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            widget.groupedNews.groupedSummary,
                            style: const TextStyle(fontSize: 15, color: AppColors.textPrimary, height: 1.6),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                  ],
                ),
              ),
            ),
            // Source tabs
            SliverPersistentHeader(
              pinned: true,
              delegate: _SourceTabsDelegate(tabController: _tabController, articles: widget.groupedNews.articles),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: widget.groupedNews.articles.map((article) {
            return _ArticleContentView(article: article, groupedNews: widget.groupedNews);
          }).toList(),
        ),
      ),
    );
  }

  String _formatDate(DateTime dateTime) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[dateTime.month - 1]} ${dateTime.day}, ${dateTime.year}';
  }
}

/// Widget for displaying individual article content
class _ArticleContentView extends StatelessWidget {
  final NewsArticle article;
  final GroupedNews groupedNews;

  const _ArticleContentView({required this.article, required this.groupedNews});

  @override
  Widget build(BuildContext context) {
    final articleIndex = groupedNews.articles.indexOf(article);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Source badge header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            decoration: BoxDecoration(
              color: _getSourceColor(articleIndex).withAlpha(26),
              borderRadius: BorderRadius.circular(AppBorderRadius.md),
              border: Border.all(color: _getSourceColor(articleIndex).withAlpha(77), width: 1.5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(color: _getSourceColor(articleIndex), shape: BoxShape.circle),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  article.sourceName,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _getSourceColor(articleIndex)),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  '• ${_formatDate(article.publishedAt)}',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Source-specific perspective
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: _getSourceColor(articleIndex).withAlpha(15),
              borderRadius: BorderRadius.circular(AppBorderRadius.md),
              border: Border.all(color: _getSourceColor(articleIndex).withAlpha(51)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.auto_awesome, color: _getSourceColor(articleIndex), size: 18),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      '${article.sourceName}\'s Perspective',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: _getSourceColor(articleIndex)),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(article.summary, style: const TextStyle(fontSize: 15, color: AppColors.textPrimary, height: 1.6)),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Full content section
          Row(
            children: [
              Icon(Icons.article_outlined, size: 20, color: _getSourceColor(articleIndex)),
              const SizedBox(width: AppSpacing.sm),
              const Text(
                'Full Article',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(article.content, style: const TextStyle(fontSize: 16, color: AppColors.textPrimary, height: 1.7)),
          const SizedBox(height: AppSpacing.lg),

          // Actions
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: article.url));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Link copied to clipboard'), duration: Duration(seconds: 2)),
                    );
                  },
                  icon: const Icon(Icons.link, size: 18),
                  label: const Text('Copy Link'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                    side: BorderSide(color: _getSourceColor(articleIndex).withAlpha(77)),
                    foregroundColor: _getSourceColor(articleIndex),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: article.summary));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Summary copied to clipboard'), duration: Duration(seconds: 2)),
                    );
                  },
                  icon: const Icon(Icons.copy, size: 18),
                  label: const Text('Copy Summary'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                    side: BorderSide(color: _getSourceColor(articleIndex).withAlpha(77)),
                    foregroundColor: _getSourceColor(articleIndex),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }

  Color _getSourceColor(int index) {
    final colors = [
      AppColors.primary,
      AppColors.secondary,
      const Color(0xFF10B981),
      const Color(0xFFF59E0B),
      const Color(0xFFEF4444),
    ];
    return colors[index % colors.length];
  }

  String _formatDate(DateTime dateTime) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[dateTime.month - 1]} ${dateTime.day}, ${dateTime.year}';
  }
}

/// Delegate for persistent source tabs header
class _SourceTabsDelegate extends SliverPersistentHeaderDelegate {
  final TabController tabController;
  final List<NewsArticle> articles;

  _SourceTabsDelegate({required this.tabController, required this.articles});

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: AppColors.surface,
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.xs),
          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: TabBar(
              controller: tabController,
              isScrollable: true,
              indicatorColor: AppColors.primary,
              indicatorWeight: 3,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              unselectedLabelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              tabAlignment: TabAlignment.start,
              tabs: articles.asMap().entries.map((entry) {
                final index = entry.key;
                final article = entry.value;
                return Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(color: _getSourceColor(index), shape: BoxShape.circle),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(article.sourceName),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          const Divider(height: 1),
        ],
      ),
    );
  }

  Color _getSourceColor(int index) {
    final colors = [
      AppColors.primary,
      AppColors.secondary,
      const Color(0xFF10B981),
      const Color(0xFFF59E0B),
      const Color(0xFFEF4444),
    ];
    return colors[index % colors.length];
  }

  @override
  double get maxExtent => 57;

  @override
  double get minExtent => 57;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) => false;
}
