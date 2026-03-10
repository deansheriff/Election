import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/providers.dart';
import '../../../core/constants/app_constants.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _navIndex = 0;

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final user = auth.user;

    return Scaffold(
      body: IndexedStack(
        index: _navIndex,
        children: [
          _HomeFeed(user: user),
          const _MiniAnalytics(),
          _ProfilePage(user: user),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _navIndex,
        onDestinationSelected: (i) => setState(() => _navIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.bar_chart_outlined), selectedIcon: Icon(Icons.bar_chart), label: 'Results'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

class _HomeFeed extends ConsumerWidget {
  final dynamic user;
  const _HomeFeed({this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final voteStatusAsync = ref.watch(voteStatusProvider);
    final electionDate = DateTime(2027, 2, 20);
    final remaining = electionDate.difference(DateTime.now());

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          floating: true,
          backgroundColor: AppColors.surface,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Good day, ${user?.fullName.split(' ').first ?? 'Voter'}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              Text('${user?.state ?? ''} • Mock Voter', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
            ],
          ),
          actions: [
            IconButton(icon: const Icon(Icons.notifications_outlined), onPressed: () {}),
            if (user?.isAdmin == true)
              IconButton(
                icon: const Icon(Icons.admin_panel_settings_outlined, color: AppColors.gold),
                onPressed: () => context.go('/admin'),
              ),
          ],
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Countdown card
                _CountdownCard(remaining: remaining).animate().fadeIn().slideY(begin: 0.2),
                const SizedBox(height: 20),

                // Voting status grid
                Text('Your Voting Status', style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 12),
                voteStatusAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => _VotingStatusGrid(status: {}),
                  data: (status) => _VotingStatusGrid(status: status),
                ),
                const SizedBox(height: 24),

                // Live Leaderboard
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Live Leaderboard', style: Theme.of(context).textTheme.headlineMedium),
                    TextButton(
                      onPressed: () => context.go('/analytics'),
                      child: const Text('View All', style: TextStyle(color: AppColors.green)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const _LiveLeaderboard(),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CountdownCard extends StatelessWidget {
  final Duration remaining;
  const _CountdownCard({required this.remaining});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.darkGreen, Color(0xFF004D2A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.green.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.calendar_today_outlined, color: AppColors.gold, size: 16),
            const SizedBox(width: 8),
            Text('Presidential Election', style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.w600)),
          ]),
          const Text('February 20, 2027', style: TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _CountUnit('${remaining.inDays}', 'DAYS'),
              _Divider(),
              _CountUnit('${remaining.inHours.remainder(24)}', 'HRS'),
              _Divider(),
              _CountUnit('${remaining.inMinutes.remainder(60)}', 'MIN'),
              _Divider(),
              _CountUnit('${remaining.inSeconds.remainder(60)}', 'SEC'),
            ],
          ),
        ],
      ),
    );
  }
}

class _CountUnit extends StatelessWidget {
  final String value;
  final String label;
  const _CountUnit(this.value, this.label);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800)),
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 10, letterSpacing: 1.5)),
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const Text(':', style: TextStyle(color: Colors.white54, fontSize: 28, fontWeight: FontWeight.w300));
}

class _VotingStatusGrid extends ConsumerWidget {
  final Map<String, dynamic> status;
  const _VotingStatusGrid({required this.status});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final types = kElectionTypes;
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: types.map((type) {
        final s = status[type];
        final voted = s != null && s['voted'] == true;
        final color = voted ? AppColors.green : AppColors.textMuted;
        return GestureDetector(
          onTap: () => voted ? context.go('/receipt/$type') : context.go('/ballot/$type'),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(kElectionTypeIcons[type] ?? '🗳️', style: const TextStyle(fontSize: 16)),
                    Icon(voted ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                        color: color, size: 18),
                  ],
                ),
                const Spacer(),
                Text(kElectionTypeLabels[type] ?? type,
                    style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
                Text(voted ? 'Voted ✓' : 'Tap to Vote',
                    style: TextStyle(color: color, fontSize: 11)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _LiveLeaderboard extends ConsumerWidget {
  const _LiveLeaderboard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resultsAsync = ref.watch(resultsProvider('presidential'));
    return resultsAsync.when(
      loading: () => const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator())),
      error: (e, _) => const Text('Could not load leaderboard', style: TextStyle(color: AppColors.textMuted)),
      data: (data) {
        final results = (data['results'] as List<dynamic>? ?? []).take(3).toList();
        return Column(
          children: results.asMap().entries.map((entry) {
            final i = entry.key;
            final r = entry.value;
            final pct = (r['percentage'] as num?)?.toDouble() ?? 0.0;
            final colorHex = r['party_color'] ?? r['color_hex'] ?? '#008751';
            final color = Color(int.parse('0xFF${colorHex.replaceAll('#', '')}'));

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: color.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  // Rank
                  Container(
                    width: 28, height: 28,
                    decoration: BoxDecoration(
                      color: i == 0 ? AppColors.gold.withOpacity(0.2) : AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text('#${i + 1}',
                          style: TextStyle(color: i == 0 ? AppColors.gold : AppColors.textMuted, fontWeight: FontWeight.w700, fontSize: 12)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Party badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(6)),
                    child: Text(r['party_abbr'] ?? '', style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 11)),
                  ),
                  const SizedBox(width: 10),
                  // Name + bar
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(r['full_name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        const SizedBox(height: 4),
                        LinearProgressIndicator(
                          value: pct / 100,
                          backgroundColor: color.withOpacity(0.1),
                          color: color,
                          minHeight: 4,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text('${pct.toStringAsFixed(1)}%',
                      style: TextStyle(color: color, fontWeight: FontWeight.w700)),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

// Stub screens for nav tabs
class _MiniAnalytics extends StatelessWidget {
  const _MiniAnalytics();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Results & Analytics')),
      body: Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.bar_chart_rounded, size: 64, color: AppColors.green),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => context.go('/analytics'),
            child: const Text('Open Full Analytics Dashboard'),
          ),
        ]),
      ),
    );
  }
}

class _ProfilePage extends ConsumerWidget {
  final dynamic user;
  const _ProfilePage({this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          TextButton(
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) context.go('/auth/login');
            },
            child: const Text('Sign Out', style: TextStyle(color: AppColors.pdpRed)),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            CircleAvatar(radius: 48, backgroundColor: AppColors.green.withOpacity(0.2),
                child: Text(user?.fullName[0] ?? 'V', style: const TextStyle(fontSize: 40, color: AppColors.green))),
            const SizedBox(height: 16),
            Text(user?.fullName ?? '', style: Theme.of(context).textTheme.headlineMedium),
            Text('${user?.state ?? ''} • ${user?.lga ?? ''}', style: Theme.of(context).textTheme.bodyMedium),
            if (user?.isAdmin == true) ...[
              const SizedBox(height: 8),
              Chip(label: const Text('Admin', style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.w700)),
                  backgroundColor: AppColors.gold.withOpacity(0.1)),
            ],
            const SizedBox(height: 32),
            ListTile(
              leading: const Icon(Icons.bar_chart_rounded, color: AppColors.green),
              title: const Text('Analytics Dashboard'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.go('/analytics'),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.compare_arrows_rounded, color: AppColors.gold),
              title: const Text('Platform vs INEC Comparison'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.go('/comparison'),
            ),
          ],
        ),
      ),
    );
  }
}
