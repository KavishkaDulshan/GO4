import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/wishlist_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth         = ref.watch(authProvider);
    final wishlistCount = ref.watch(wishlistProvider).length;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Column(
        children: [
          Expanded(
            child: auth.isLoading
                ? const Center(child: CircularProgressIndicator())
                : auth.isSignedIn
                    ? _SignedInView(auth: auth, ref: ref)
                    : _SignedOutView(ref: ref, errorMessage: auth.errorMessage),
          ),
          const Divider(height: 1, color: Colors.white12),
          ListTile(
            leading: const Icon(Icons.favorite_outline, color: Colors.pinkAccent),
            title: const Text('Saved Items'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (wishlistCount > 0)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.pinkAccent.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$wishlistCount',
                      style: const TextStyle(
                          color: Colors.pinkAccent,
                          fontSize: 12,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right, color: Colors.white38),
              ],
            ),
            onTap: () => context.push('/wishlist'),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ── Signed-out ─────────────────────────────────────────────────────────────────

class _SignedOutView extends StatelessWidget {
  final WidgetRef ref;
  final String? errorMessage;
  const _SignedOutView({required this.ref, this.errorMessage});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.person_outline, size: 80, color: Colors.white24),
            const SizedBox(height: 24),
            const Text(
              'Sign in to save your search history\nand access it across devices.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white54, fontSize: 14),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              icon: const Icon(Icons.login),
              label: const Text('Sign in with Google'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              ),
              onPressed: () => ref.read(authProvider.notifier).signIn(),
            ),
            if (errorMessage != null) ...[
              const SizedBox(height: 16),
              Text(
                errorMessage!,
                style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Signed-in ──────────────────────────────────────────────────────────────────

class _SignedInView extends StatelessWidget {
  final AuthState auth;
  final WidgetRef ref;
  const _SignedInView({required this.auth, required this.ref});

  @override
  Widget build(BuildContext context) {
    final user = auth.user!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Avatar
            CircleAvatar(
              radius: 48,
              backgroundColor: Colors.white12,
              backgroundImage: user.photoUrl != null
                  ? CachedNetworkImageProvider(user.photoUrl!)
                  : null,
              child: user.photoUrl == null
                  ? const Icon(Icons.person, size: 48, color: Colors.white54)
                  : null,
            ),
            const SizedBox(height: 20),

            // Display name
            if (user.displayName != null)
              Text(
                user.displayName!,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            const SizedBox(height: 6),

            // Email
            Text(
              user.email,
              style: const TextStyle(color: Colors.white54, fontSize: 14),
            ),
            const SizedBox(height: 32),

            // Sign out
            TextButton.icon(
              icon: const Icon(Icons.logout, size: 18),
              label: const Text('Sign out'),
              style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
              onPressed: () => ref.read(authProvider.notifier).signOut(),
            ),
          ],
        ),
      ),
    );
  }
}
