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

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final isAuth = authState.isAuthenticated;
      final isAuthRoute = state.matchedLocation.startsWith('/auth') || state.matchedLocation == '/splash' || state.matchedLocation == '/onboarding';

      if (!isAuth && !isAuthRoute) return '/auth/login';
      if (isAuth && (state.matchedLocation == '/auth/login' || state.matchedLocation == '/onboarding')) return '/home';
      return null;
    },
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
              final phone = s.uri.queryParameters['phone'] ?? '';
              return OtpScreen(phone: phone);
            },
          ),
        ],
      ),
      GoRoute(path: '/home', builder: (c, s) => const HomeScreen()),
      GoRoute(
        path: '/ballot/:type',
        builder: (c, s) {
          final type = s.pathParameters['type']!;
          return BallotScreen(electionType: type);
        },
      ),
      GoRoute(
        path: '/receipt/:type',
        builder: (c, s) {
          final type = s.pathParameters['type']!;
          return VoteReceiptScreen(electionType: type);
        },
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
