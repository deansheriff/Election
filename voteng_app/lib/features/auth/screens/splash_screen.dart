import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/providers.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(milliseconds: 2500));
    if (!mounted) return;
    final auth = ref.read(authProvider);
    if (auth.isAuthenticated) {
      context.go('/home');
    } else {
      context.go('/onboarding');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.2,
            colors: [Color(0xFF0D2818), AppColors.bgDark],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Ballot box icon
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.green.withOpacity(0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.green.withOpacity(0.4), width: 2),
                ),
                child: const Icon(Icons.how_to_vote_rounded, color: AppColors.green, size: 52),
              ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
              const SizedBox(height: 24),
              Text(
                'VoteNG 2027',
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      color: AppColors.white,
                      letterSpacing: 1.5,
                    ),
              ).animate().fadeIn(delay: 300.ms, duration: 600.ms).slideY(begin: 0.2),
              const SizedBox(height: 8),
              Text(
                "Nigeria's Social Election Experiment",
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.gold.withOpacity(0.8),
                      letterSpacing: 0.5,
                    ),
              ).animate().fadeIn(delay: 600.ms, duration: 600.ms),
              const SizedBox(height: 8),
              Text(
                'Your Vote, Your Prediction.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ).animate().fadeIn(delay: 800.ms, duration: 600.ms),
              const SizedBox(height: 60),
              // Loading indicator
              SizedBox(
                width: 40,
                child: LinearProgressIndicator(
                  backgroundColor: AppColors.green.withOpacity(0.2),
                  color: AppColors.green,
                  minHeight: 2,
                ),
              ).animate().fadeIn(delay: 1000.ms),
            ],
          ),
        ),
      ),
    );
  }
}
