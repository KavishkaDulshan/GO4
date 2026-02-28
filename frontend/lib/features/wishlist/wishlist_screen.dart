import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../models/wishlist_item.dart';
import '../../providers/wishlist_provider.dart';

class WishlistScreen extends ConsumerWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(wishlistProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Saved  (${items.length})'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.maybePop(context),
        ),
        actions: [
          if (items.isNotEmpty)
            TextButton(
              onPressed: () => _confirmClear(context, ref),
              child: const Text('Clear all',
                  style: TextStyle(color: Colors.redAccent)),
            ),
        ],
      ),
      body: items.isEmpty
          ? const _EmptyWishlist()
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: items.length,
              itemBuilder: (ctx, i) => _WishlistCard(item: items[i]),
            ),
    );
  }

  Future<void> _confirmClear(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Clear wishlist?'),
        content: const Text('All saved items will be removed.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Clear',
                  style: TextStyle(color: Colors.redAccent))),
        ],
      ),
    );
    if (ok == true) {
      final notifier = ref.read(wishlistProvider.notifier);
      final copy = List.of(ref.read(wishlistProvider));
      for (final item in copy) {
        notifier.remove(item.product);
      }
    }
  }
}

// ─── Empty state ──────────────────────────────────────────────────────────────

class _EmptyWishlist extends StatelessWidget {
  const _EmptyWishlist();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.favorite_border, size: 72, color: Colors.white24),
            SizedBox(height: 20),
            Text(
              'No saved items yet',
              style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 8),
            Text(
              'Tap the heart icon on any product to save it here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white38, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Wishlist card ────────────────────────────────────────────────────────────

class _WishlistCard extends ConsumerWidget {
  final WishlistItem item;
  const _WishlistCard({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final product = item.product;
    final img = product.displayImage;

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
                            child: CircularProgressIndicator(strokeWidth: 2),
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
                    if (product.price != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        product.price!,
                        style: const TextStyle(
                          color: AppTheme.accent,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ],
                    if (product.source != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        product.source!,
                        style: const TextStyle(
                            color: Colors.white38, fontSize: 12),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      'Saved ${_relativeDate(item.savedAt)}',
                      style:
                          const TextStyle(color: Colors.white24, fontSize: 11),
                    ),
                  ],
                ),
              ),

              // Remove button
              IconButton(
                icon: const Icon(Icons.favorite,
                    color: Colors.pinkAccent, size: 22),
                onPressed: () =>
                    ref.read(wishlistProvider.notifier).remove(product),
                tooltip: 'Remove',
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _relativeDate(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays == 0) return 'today';
    if (diff.inDays == 1) return 'yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return '${(diff.inDays / 7).floor()} week${(diff.inDays / 7).floor() == 1 ? '' : 's'} ago';
  }
}
