import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/providers.dart';

// Screen imports
import '../../features/auth/screens/splash_screen.dart';
import '../../features/auth/screens/onboarding_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/auth/screens/otp_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/voting/screens/ballot_screen.dart';
import '../../features/voting/screens/vote_receipt_screen.dart';
import '../../features/analytics/screens/analytics_dashboard.dart';
import '../../features/analytics/screens/comparison_screen.dart';
import '../../features/admin/screens/admin_shell.dart';

/// Listens to [authProvider] and notifies GoRouter to re-run [redirect]
/// without ever rebuilding the router itself.
class RouterNotifier extends ChangeNotifier {
  final Ref _ref;
  RouterNotifier(this._ref) {
    _ref.listen<AuthState>(authProvider, (_, __) => notifyListeners());
  }

  String? redirect(BuildContext context, GoRouterState state) {
    final auth = _ref.read(authProvider);

    // While the token check is still in flight, stay on splash
    if (auth.isInitialising) {
      return state.matchedLocation == '/splash' ? null : '/splash';
    }

    final isAuth = auth.isAuthenticated;
    final loc = state.matchedLocation;
    final isAuthRoute = loc.startsWith('/auth') || loc == '/splash' || loc == '/onboarding';

    if (!isAuth && !isAuthRoute) return '/auth/login';
    if (isAuth && (loc == '/auth/login' || loc == '/onboarding' || loc == '/splash')) return '/home';
    return null;
  }
}

final routerNotifierProvider = ChangeNotifierProvider<RouterNotifier>(
  (ref) => RouterNotifier(ref),
);

/// The router is created ONCE and never rebuilt.
/// Auth-triggered redirects happen via refreshListenable.
final routerProvider = Provider<GoRouter>((ref) {
  final notifier = ref.watch(routerNotifierProvider);
  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: notifier,
    redirect: notifier.redirect,
    routes: [
      GoRoute(path: '/splash', builder: (c, s) => const SplashScreen()),
      GoRoute(path: '/onboarding', builder: (c, s) => const OnboardingScreen()),
      GoRoute(
        path: '/auth',
        builder: (c, s) => const LoginScreen(),
        routes: [
          GoRoute(path: 'login', builder: (c, s) => const LoginScreen()),
          GoRoute(path: 'register', builder: (c, s) => const RegisterScreen()),
          GoRoute(
            path: 'otp',
            builder: (c, s) {
              final email = s.uri.queryParameters['email'] ?? '';
              final phone = s.uri.queryParameters['phone'] ?? '';
              return OtpScreen(email: email, phone: phone);
            },
          ),
        ],
      ),
      GoRoute(path: '/home', builder: (c, s) => const HomeScreen()),
      GoRoute(
        path: '/ballot/:type',
        builder: (c, s) => BallotScreen(electionType: s.pathParameters['type']!),
      ),
      GoRoute(
        path: '/receipt/:type',
        builder: (c, s) => VoteReceiptScreen(electionType: s.pathParameters['type']!),
      ),
      GoRoute(path: '/analytics', builder: (c, s) => const AnalyticsDashboard()),
      GoRoute(path: '/comparison', builder: (c, s) => const ComparisonScreen()),
      GoRoute(path: '/admin', builder: (c, s) => const AdminShell()),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('Page not found: ${state.error}')),
    ),
  );
});
