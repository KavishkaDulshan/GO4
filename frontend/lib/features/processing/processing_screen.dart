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

    // Navigate on status changes — must run after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.listenManual(
        searchProvider.select((s) => s.status),
        (_, status) {
          if (!mounted) return;
          if (status == SearchStatus.analyzed) {
            // Analyze phase done → show filter screen
            context.go('/filters');
          } else if (status == SearchStatus.success) {
            // Search phase done → show results
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

    // Pick messaging based on current phase
    final isAnalyzing = state.status == SearchStatus.analyzing;
    final title   = isAnalyzing ? 'Understanding…' : 'Searching…';
    final message = isAnalyzing
        ? 'AI is understanding your inputs…'
        : 'AI is browsing products for you…';
    final subMessage = isAnalyzing
        ? 'Detecting product · Generating smart filters'
        : 'Searching across thousands of listings';

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(title),
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
                child: Icon(
                  isAnalyzing ? Icons.psychology_outlined : Icons.auto_awesome,
                  size: 64,
                  color: AppTheme.primary,
                ),
              ),
              const SizedBox(height: 32),

              const CircularProgressIndicator(color: AppTheme.primary),
              const SizedBox(height: 24),

              Text(
                message,
                style: const TextStyle(color: Colors.white70, fontSize: 15),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                subMessage,
                style: const TextStyle(color: Colors.white38, fontSize: 12),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Detected-attribute chips (search phase)
              if (!isAnalyzing &&
                  state.result != null &&
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

              // Analyzed product name (analyze phase in-progress)
              if (isAnalyzing && state.analyzedTags != null) ...[
                const SizedBox(height: 8),
                Text(
                  state.analyzedTags!['productName'] as String? ?? '',
                  style: const TextStyle(
                      color: AppTheme.primary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
