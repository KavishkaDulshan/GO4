import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/history_item.dart';
import '../../providers/auth_provider.dart';
import '../../providers/history_provider.dart';
import '../../providers/search_provider.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth    = ref.watch(authProvider);
    final history = ref.watch(historyProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('History')),
      body: history.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Failed to load history:\n$err',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.redAccent),
            ),
          ),
        ),
        data: (items) {
          if (!auth.isSignedIn) {
            return const _SignInNudge();
          }
          if (items.isEmpty) {
            return const _EmptyHistory();
          }
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 4),
            itemBuilder: (ctx, i) => _HistoryCard(
              item: items[i],
              onTap: () {
                // Load this history item into searchProvider and go to results
                ref.read(searchProvider.notifier).loadHistory(items[i]);
                ctx.push('/results');
              },
            ),
          );
        },
      ),
    );
  }
}

// ── Nudge for signed-out users ─────────────────────────────────────────────────

class _SignInNudge extends StatelessWidget {
  const _SignInNudge();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.history, size: 64, color: Colors.white24),
            SizedBox(height: 16),
            Text(
              'Sign in to see your search history.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white54, fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Empty state ────────────────────────────────────────────────────────────────

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.white24),
            SizedBox(height: 16),
            Text(
              'No searches yet.\nPoint your camera at a product to get started.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white54, fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }
}

// ── History card ───────────────────────────────────────────────────────────────

class _HistoryCard extends StatelessWidget {
  final HistoryItem item;
  final VoidCallback onTap;
  const _HistoryCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final thumbs = item.results
        .where((p) => p.thumbnail != null)
        .take(3)
        .map((p) => p.thumbnail!)
        .toList();
    final chips = item.tags.chips;

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Thumbnail stack (up to 3)
              SizedBox(
                width: 64,
                height: 64,
                child: thumbs.isEmpty
                    ? const Icon(Icons.shopping_bag_outlined,
                        size: 36, color: Colors.white24)
                    : _ThumbnailStack(urls: thumbs),
              ),
              const SizedBox(width: 12),

              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.tags.productName.isNotEmpty
                          ? item.tags.productName
                          : item.tags.searchQuery,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
                    if (chips.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 4,
                        children: chips
                            .map((c) => Chip(
                                  label: Text(c,
                                      style: const TextStyle(fontSize: 10)),
                                  padding: EdgeInsets.zero,
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  visualDensity: VisualDensity.compact,
                                ))
                            .toList(),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      '${item.results.length} result${item.results.length == 1 ? '' : 's'}',
                      style: const TextStyle(
                          color: Colors.white38, fontSize: 12),
                    ),
                  ],
                ),
              ),

              // Time ago
              Text(
                _timeAgo(item.createdAt),
                style: const TextStyle(color: Colors.white38, fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24)   return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

// ── Thumbnail stack ────────────────────────────────────────────────────────────

class _ThumbnailStack extends StatelessWidget {
  final List<String> urls; // 1–3 URLs
  const _ThumbnailStack({required this.urls});

  @override
  Widget build(BuildContext context) {
    const size = 48.0;
    final count = urls.length.clamp(1, 3);
    const overlap = 12.0;

    return SizedBox(
      width: size + (count - 1) * overlap,
      height: size,
      child: Stack(
        children: List.generate(
          count,
          (i) => Positioned(
            left: i * overlap,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: CachedNetworkImage(
                imageUrl: urls[i],
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => Container(
                  width: size,
                  height: size,
                  color: Colors.white10,
                  child: const Icon(Icons.image_not_supported_outlined,
                      size: 20, color: Colors.white24),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
