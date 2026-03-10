import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_theme.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _ctrl = PageController();
  int _page = 0;

  final List<_SlideData> _slides = const [
    _SlideData(
      icon: Icons.how_to_vote_rounded,
      color: AppColors.green,
      title: 'Cast Your Mock Vote',
      description: 'Participate in Nigeria\'s biggest social experiment. Vote for your preferred candidates across all 5 election tiers — Presidential, Senate, House of Reps, Governorship, and State Assembly.',
    ),
    _SlideData(
      icon: Icons.bar_chart_rounded,
      color: AppColors.gold,
      title: 'Track Real-time Results',
      description: 'Watch live vote tallies, interactive state maps, and demographic breakdowns as millions of Nigerians cast their predictions. Updated every 30 seconds.',
    ),
    _SlideData(
      icon: Icons.compare_arrows_rounded,
      color: AppColors.lpOrange,
      title: 'Compare with INEC Results',
      description: 'After February 20, 2027, see how crowd-sourced predictions matched INEC\'s official outcome. Discover the accuracy of Nigeria\'s collective wisdom.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: () => context.go('/auth/login'),
                child: Text('Skip', style: TextStyle(color: AppColors.textMuted)),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _ctrl,
                itemCount: _slides.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (ctx, i) => _SlidePage(data: _slides[i]),
              ),
            ),
            // Dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _slides.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _page == i ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _page == i ? AppColors.green : AppColors.textMuted.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _page < _slides.length - 1
                  ? ElevatedButton(
                      onPressed: () => _ctrl.nextPage(duration: 400.ms, curve: Curves.easeInOut),
                      child: const Text('Next'),
                    )
                  : ElevatedButton(
                      onPressed: () => context.go('/auth/register'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.green,
                        foregroundColor: AppColors.white,
                      ),
                      child: const Text('Get Started — Register Now'),
                    ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => context.go('/auth/login'),
              child: Text('Already have an account? Sign in', style: TextStyle(color: AppColors.textSecondary)),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _SlideData {
  final IconData icon;
  final Color color;
  final String title;
  final String description;
  const _SlideData({required this.icon, required this.color, required this.title, required this.description});
}

class _SlidePage extends StatelessWidget {
  final _SlideData data;
  const _SlidePage({required this.data});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              color: data.color.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(color: data.color.withOpacity(0.3), width: 2),
            ),
            child: Icon(data.icon, color: data.color, size: 72),
          ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
          const SizedBox(height: 40),
          Text(
            data.title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineLarge,
          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),
          const SizedBox(height: 16),
          Text(
            data.description,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.6),
          ).animate().fadeIn(delay: 400.ms),
        ],
      ),
    );
  }
}
