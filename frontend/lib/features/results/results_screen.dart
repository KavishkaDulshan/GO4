import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../models/product.dart';
import '../../providers/search_provider.dart';
import '../../providers/wishlist_provider.dart';

// ── Sort options ──────────────────────────────────────────────────────────────

enum _SortOption {
  relevance('Relevance'),
  priceLow('Price: Low → High'),
  priceHigh('Price: High → Low'),
  rating('Rating');

  final String label;
  const _SortOption(this.label);
}

double _parsePrice(String? price) {
  if (price == null || price.isEmpty) return double.infinity;
  final cleaned = price.replaceAll(RegExp(r'[^\d.]'), '');
  return double.tryParse(cleaned) ?? double.infinity;
}

List<Product> _sorted(List<Product> products, _SortOption opt) {
  final copy = List.of(products);
  switch (opt) {
    case _SortOption.relevance:
      return copy;
    case _SortOption.priceLow:
      copy.sort((a, b) => _parsePrice(a.price).compareTo(_parsePrice(b.price)));
    case _SortOption.priceHigh:
      copy.sort((a, b) => _parsePrice(b.price).compareTo(_parsePrice(a.price)));
    case _SortOption.rating:
      copy.sort((a, b) => (b.rating ?? 0).compareTo(a.rating ?? 0));
  }
  return copy;
}

// ── Screen ────────────────────────────────────────────────────────────────────

class ResultsScreen extends ConsumerStatefulWidget {
  const ResultsScreen({super.key});

  @override
  ConsumerState<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends ConsumerState<ResultsScreen> {
  _SortOption _sort = _SortOption.relevance;

  @override
  Widget build(BuildContext context) {
    final state  = ref.watch(searchProvider);
    final result = state.result;

    if (result == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Results')),
        body: const Center(
          child: Text('No results yet.',
              style: TextStyle(color: Colors.white54)),
        ),
      );
    }

    final products = _sorted(result.results, _sort);

    return Scaffold(
      appBar: AppBar(
        title: Text(result.tags.productName),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
        actions: [
          // Sort menu
          PopupMenuButton<_SortOption>(
            icon: const Icon(Icons.sort),
            tooltip: 'Sort',
            initialValue: _sort,
            onSelected: (opt) => setState(() => _sort = opt),
            itemBuilder: (_) => _SortOption.values
                .map((opt) => PopupMenuItem(
                      value: opt,
                      child: Row(
                        children: [
                          Icon(
                            _sort == opt
                                ? Icons.radio_button_checked
                                : Icons.radio_button_off,
                            size: 16,
                            color: _sort == opt
                                ? AppTheme.primary
                                : Colors.white38,
                          ),
                          const SizedBox(width: 8),
                          Text(opt.label),
                        ],
                      ),
                    ))
                .toList(),
          ),
          IconButton(
            icon: const Icon(Icons.map_outlined),
            tooltip: 'View on Map',
            onPressed: () => context.go('/map'),
          ),
        ],
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
      body: Column(
        children: [
          // Active sort indicator bar
          if (_sort != _SortOption.relevance)
            Container(
              color: AppTheme.primary.withValues(alpha: 0.1),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                children: [
                  const Icon(Icons.sort, size: 14, color: AppTheme.primary),
                  const SizedBox(width: 6),
                  Text(
                    'Sorted by: ${_sort.label}',
                    style: const TextStyle(
                        color: AppTheme.primary, fontSize: 12),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () =>
                        setState(() => _sort = _SortOption.relevance),
                    child: const Text('Reset',
                        style:
                            TextStyle(color: Colors.white38, fontSize: 12)),
                  ),
                ],
              ),
            ),

          Expanded(
            child: products.isEmpty
                ? _EmptyResults(query: result.tags.searchQuery)
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: products.length,
                    itemBuilder: (ctx, i) =>
                        _ProductCard(product: products[i]),
                  ),
          ),
        ],
      ),
    );
  }
}

// ─── Empty state ──────────────────────────────────────────────────────────────

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
              'No results found for "$query".',
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

// ─── Product card ─────────────────────────────────────────────────────────────

class _ProductCard extends ConsumerWidget {
  final Product product;
  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final img    = product.displayImage;
    final isSaved = ref.watch(
      wishlistProvider.select(
        (list) => list.any((item) => WishlistNotifier.sameProduct(item.product, product)),
      ),
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => context.push('/product', extra: product),
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
                  child: img != null
                      ? CachedNetworkImage(
                          imageUrl: img,
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
                      Row(
                        children: [
                          Text(
                            product.price!,
                            style: const TextStyle(
                              color: AppTheme.accent,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          if (product.originalPrice != null) ...[
                            const SizedBox(width: 6),
                            Text(
                              product.originalPrice!,
                              style: const TextStyle(
                                color: Colors.white38,
                                fontSize: 12,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                          ],
                        ],
                      ),
                    const SizedBox(height: 2),
                    if (product.source != null)
                      Text(
                        product.source!,
                        style: const TextStyle(
                            color: Colors.white38, fontSize: 12),
                      ),
                    if (product.delivery != null) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.local_shipping_outlined,
                              size: 12, color: Colors.green),
                          const SizedBox(width: 3),
                          Text(
                            product.delivery!,
                            style: const TextStyle(
                                color: Colors.green, fontSize: 11),
                          ),
                        ],
                      ),
                    ],
                    if (product.rating != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.star,
                              size: 14, color: Colors.amber),
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

              // Right column: wishlist heart + verified + chevron
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  GestureDetector(
                    onTap: () =>
                        ref.read(wishlistProvider.notifier).toggle(product),
                    child: Icon(
                      isSaved ? Icons.favorite : Icons.favorite_border,
                      size: 22,
                      color: isSaved ? Colors.pinkAccent : Colors.white38,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const _VerifiedBadge(),
                  const SizedBox(height: 6),
                  const Icon(Icons.chevron_right,
                      size: 18, color: Colors.white38),
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
                color: Colors.green,
                fontSize: 10,
                fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
