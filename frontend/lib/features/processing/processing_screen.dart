import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/search_provider.dart';

class ProcessingScreen extends ConsumerStatefulWidget {
  const ProcessingScreen({super.key});

  @override
  ConsumerState<ProcessingScreen> createState() => _ProcessingScreenState();
}

class _ProcessingScreenState extends ConsumerState<ProcessingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);

    // Navigate when the search completes — must run after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.listenManual(
        searchProvider.select((s) => s.status),
        (_, status) {
          if (!mounted) return;
          if (status == SearchStatus.success) {
            context.go('/results');
          } else if (status == SearchStatus.error) {
            final msg =
                ref.read(searchProvider).errorMessage ?? 'Search failed';
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(msg)),
            );
            context.pop();
          }
        },
      );
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(searchProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Analyzing…'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Pulsing icon
              FadeTransition(
                opacity: _pulseController,
                child: const Icon(
                  Icons.auto_awesome,
                  size: 64,
                  color: AppTheme.primary,
                ),
              ),
              const SizedBox(height: 32),

              const CircularProgressIndicator(color: AppTheme.primary),
              const SizedBox(height: 24),

              const Text(
                'AI is browsing local inventory…',
                style: TextStyle(color: Colors.white70, fontSize: 15),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Tag chips appear as soon as Gemini responds
              if (state.result != null &&
                  state.result!.tags.chips.isNotEmpty) ...[
                const Text(
                  'Detected attributes:',
                  style: TextStyle(color: Colors.white38, fontSize: 12),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  alignment: WrapAlignment.center,
                  children: state.result!.tags.chips
                      .map((chip) => Chip(label: Text(chip)))
                      .toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
