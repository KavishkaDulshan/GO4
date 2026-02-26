import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_theme.dart';
import '../../models/product.dart';
import '../../providers/search_provider.dart';

class ResultsScreen extends ConsumerWidget {
  const ResultsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(searchProvider);
    final result = state.result;

    if (result == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Results')),
        body: const Center(
          child:
              Text('No results yet.', style: TextStyle(color: Colors.white54)),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(result.tags.productName),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
        bottom: result.tags.chips.isNotEmpty
            ? PreferredSize(
                preferredSize: const Size.fromHeight(48),
                child: SizedBox(
                  height: 44,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    children: result.tags.chips
                        .map((c) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: Chip(label: Text(c)),
                            ))
                        .toList(),
                  ),
                ),
              )
            : null,
      ),
      body: result.results.isEmpty
          ? _EmptyResults(query: result.tags.searchQuery)
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: result.results.length,
              itemBuilder: (ctx, i) => _ProductCard(product: result.results[i]),
            ),
    );
  }
}

class _EmptyResults extends StatelessWidget {
  final String query;
  const _EmptyResults({required this.query});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off, size: 64, color: Colors.white24),
            const SizedBox(height: 16),
            Text(
              'No results found for "$query"\nin your region.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white54, fontSize: 15),
            ),
            const SizedBox(height: 8),
            const Text(
              'Try a broader description or different image.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white38, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Product product;
  const _ProductCard({required this.product});

  Future<void> _openLink() async {
    if (product.link == null) return;
    final uri = Uri.parse(product.link!);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      // Silently ignore if URL cannot be launched
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: product.link != null ? _openLink : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 72,
                  height: 72,
                  child: product.thumbnail != null
                      ? CachedNetworkImage(
                          imageUrl: product.thumbnail!,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => const Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                          errorWidget: (_, __, ___) => const Icon(
                            Icons.image_not_supported_outlined,
                            size: 32,
                            color: Colors.white24,
                          ),
                        )
                      : const Icon(Icons.shopping_bag_outlined,
                          size: 40, color: AppTheme.primary),
                ),
              ),
              const SizedBox(width: 12),

              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: AppTheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (product.price != null)
                      Text(
                        product.price!,
                        style: const TextStyle(
                          color: AppTheme.accent,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    const SizedBox(height: 2),
                    if (product.source != null)
                      Text(
                        product.source!,
                        style:
                            const TextStyle(color: Colors.white38, fontSize: 12),
                      ),
                    if (product.rating != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.star, size: 14, color: Colors.amber),
                          const SizedBox(width: 2),
                          Text(
                            '${product.rating!.toStringAsFixed(1)}'
                            '${product.ratingCount != null ? ' (${product.ratingCount})' : ''}',
                            style: const TextStyle(
                                color: Colors.white54, fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // Right column: verified badge + optional link icon
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const _VerifiedBadge(),
                  if (product.link != null) ...[
                    const SizedBox(height: 6),
                    const Icon(
                      Icons.open_in_new,
                      size: 14,
                      color: Colors.white38,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VerifiedBadge extends StatelessWidget {
  const _VerifiedBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.withValues(alpha: 0.4)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified, size: 11, color: Colors.green),
          SizedBox(width: 3),
          Text(
            'Live',
            style: TextStyle(
                color: Colors.green, fontSize: 10, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
