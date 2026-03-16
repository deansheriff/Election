import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';

void main() {
  runApp(const ProviderScope(child: VoteNGApp()));
}

class VoteNGApp extends ConsumerWidget {
  const VoteNGApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // read (not watch) so the router is created once and never rebuilt.
    // GoRouter refreshes redirects via RouterNotifier.
    final router = ref.read(routerProvider);
    return MaterialApp.router(
      title: 'VoteNG 2027',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      routerConfig: router,
    );
  }
}
