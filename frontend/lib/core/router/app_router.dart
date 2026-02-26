import 'package:go_router/go_router.dart';
import '../../features/home/home_screen.dart';
import '../../features/processing/processing_screen.dart';
import '../../features/results/results_screen.dart';
import '../../features/map/map_screen.dart';
import '../../features/history/history_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/shell/app_shell.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    // ── Shell: screens that show the bottom nav bar ──────────────────────
    ShellRoute(
      builder: (context, state, child) => AppShell(child: child),
      routes: [
        GoRoute(path: '/', builder: (_, __) => const HomeScreen()),
        GoRoute(path: '/map', builder: (_, __) => const MapScreen()),
        GoRoute(path: '/history', builder: (_, __) => const HistoryScreen()),
        GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
      ],
    ),
    // ── Full-screen routes: no bottom nav bar ────────────────────────────
    GoRoute(path: '/processing', builder: (_, __) => const ProcessingScreen()),
    GoRoute(path: '/results', builder: (_, __) => const ResultsScreen()),
  ],
);
