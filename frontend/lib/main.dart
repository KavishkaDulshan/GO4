import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'providers/auth_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Restore persisted JWT + user profile before the first frame.
  final container = ProviderContainer();
  await container.read(authProvider.notifier).restore();

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const Go4App(),
    ),
  );
}

class Go4App extends StatelessWidget {
  const Go4App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Go4',
      theme: AppTheme.dark,
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}
