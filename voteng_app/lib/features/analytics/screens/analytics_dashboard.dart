import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/providers.dart';
import '../../../core/constants/app_constants.dart';

class AnalyticsDashboard extends ConsumerStatefulWidget {
  const AnalyticsDashboard({super.key});

  @override
  ConsumerState<AnalyticsDashboard> createState() => _AnalyticsDashboardState();
}

class _AnalyticsDashboardState extends ConsumerState<AnalyticsDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final List<String> _tabs = ['Presidential', 'Senate', 'HoR', 'Gov'];
  final List<String> _types = ['presidential', 'senate', 'house', 'governorship'];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: _tabs.length, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Results & Analytics'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/home')),
        actions: [
          IconButton(
            icon: const Icon(Icons.compare_arrows_rounded, color: AppColors.gold),
            onPressed: () => context.go('/comparison'),
            tooltip: 'Platform vs INEC Comparison',
          ),
        ],
        bottom: TabBar(
          controller: _tabCtrl,
          tabs: _tabs.map((t) => Tab(text: t)).toList(),
          indicatorColor: AppColors.green,
          labelColor: AppColors.green,
          unselectedLabelColor: AppColors.textMuted,
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: _types.map((type) => _AnalyticsTab(electionType: type)).toList(),
      ),
    );
  }
}

class _AnalyticsTab extends ConsumerWidget {
  final String electionType;
  const _AnalyticsTab({required this.electionType});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resultsAsync = ref.watch(resultsProvider(electionType));
    final demoAsync = ref.watch(demographicsProvider(electionType));

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(resultsProvider(electionType));
        ref.invalidate(demographicsProvider(electionType));
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Results section
          Text('Live Vote Count', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 12),
          resultsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Error: $e', style: const TextStyle(color: AppColors.pdpRed)),
            data: (data) => _ResultBars(data: data),
          ),

          // Threshold tracker (presidential only)
          if (electionType == 'presidential') ...[
            const SizedBox(height: 24),
            Text('25% Threshold Rule', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 4),
            Text('Must win 25% in at least 24 states to win outright',
                style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 12),
            _ThresholdTracker(),
          ],

          // Zone breakdown
          const SizedBox(height: 24),
          Text('Geopolitical Zone Breakdown', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 12),
          demoAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => const SizedBox(),
            data: (data) => _ZoneBreakdown(zones: data['zones'] ?? []),
          ),

          // Demographics
          const SizedBox(height: 24),
          Text('Voter Demographics', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 12),
          demoAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => const SizedBox(),
            data: (data) => _Demographics(gender: data['gender'] ?? [], ageGroups: data['age_groups'] ?? []),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

class _ResultBars extends StatelessWidget {
  final Map<String, dynamic> data;
  const _ResultBars({required this.data});

  @override
  Widget build(BuildContext context) {
    final results = (data['results'] as List<dynamic>? ?? []);
    final total = (data['total_votes'] as num?)?.toInt() ?? 0;

    if (results.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: AppColors.cardBg, borderRadius: BorderRadius.circular(16)),
        child: Column(children: [
          const Icon(Icons.how_to_vote_outlined, color: AppColors.textMuted, size: 40),
          const SizedBox(height: 8),
          Text('No votes cast yet', style: Theme.of(context).textTheme.bodyMedium),
        ]),
      );
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: AppColors.surfaceElevated, borderRadius: BorderRadius.circular(12)),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.people_outline, color: AppColors.textSecondary, size: 16),
            const SizedBox(width: 6),
            Text('Total Votes: ${_fmt(total)}', style: const TextStyle(fontWeight: FontWeight.w700)),
          ]),
        ),
        const SizedBox(height: 12),
        ...results.asMap().entries.map((entry) {
          final r = entry.value;
          final pct = (r['percentage'] as num?)?.toDouble() ?? 0.0;
          final colorHex = r['party_color'] ?? r['color_hex'] ?? '#008751';
          final color = Color(int.parse('0xFF${colorHex.replaceAll('#', '')}'));

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.cardBg, borderRadius: BorderRadius.circular(14)),
            child: Column(
              children: [
                Row(children: [
                  CircleAvatar(radius: 18, backgroundColor: color.withOpacity(0.2),
                      child: Text((r['full_name'] as String? ?? 'C')[0], style: TextStyle(color: color, fontWeight: FontWeight.w700))),
                  const SizedBox(width: 10),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(r['full_name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                    Text(r['party_abbr'] ?? '', style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
                  ])),
                  Text(_fmt((r['vote_count'] as num?)?.toInt() ?? 0), style: const TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(width: 8),
                  Text('${pct.toStringAsFixed(1)}%', style: TextStyle(color: color, fontWeight: FontWeight.w800)),
                ]),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: pct / 100,
                    backgroundColor: color.withOpacity(0.1),
                    color: color,
                    minHeight: 8,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  String _fmt(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }
}

class _ThresholdTracker extends ConsumerWidget {
  const _ThresholdTracker();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final thresholdAsync = ref.watch(thresholdProvider);
    return thresholdAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => const SizedBox(),
      data: (threshold) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: AppColors.cardBg, borderRadius: BorderRadius.circular(16)),
        child: Column(
          children: [
            Wrap(
              spacing: 16,
              runSpacing: 16,
              alignment: WrapAlignment.center,
              children: threshold.map<Widget>((t) {
                final colorHex = t['color_hex'] ?? '#008751';
                final color = Color(int.parse('0xFF${colorHex.replaceAll('#', '')}'));
                final count = (t['qualifying_states_count'] as num?)?.toInt() ?? 0;
                final meets = t['meets_threshold'] == true;

                return Column(
                  main AxisSize: MainAxisSize.min,
                  children: [
                    CircularPercentIndicator(
                      radius: 44,
                      lineWidth: 6,
                      percent: (count / 37).clamp(0.0, 1.0),
                      backgroundColor: color.withOpacity(0.1),
                      progressColor: meets ? color : color.withOpacity(0.5),
                      center: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Text('$count', style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 18)),
                        Text('/37', style: const TextStyle(color: AppColors.textMuted, fontSize: 10)),
                      ]),
                    ),
                    const SizedBox(height: 6),
                    Text(t['party_abbr'] ?? '', style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12)),
                    Text(meets ? '✓ Qualified' : '${24 - count} more needed',
                        style: TextStyle(color: meets ? AppColors.green : AppColors.textMuted, fontSize: 10)),
                  ],
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: AppColors.surfaceElevated, borderRadius: BorderRadius.circular(10)),
              child: Row(children: [
                const Icon(Icons.info_outline, color: AppColors.gold, size: 16),
                const SizedBox(width: 8),
                Expanded(child: Text(
                  'Must win 25%+ in 24 of 37 states. Numbers show qualifying states.',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                )),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

class _ZoneBreakdown extends StatelessWidget {
  final List<dynamic> zones;
  const _ZoneBreakdown({required this.zones});

  static const _zoneColors = {
    'North-West': AppColors.zoneNW,
    'North-East': AppColors.zoneNE,
    'North-Central': AppColors.zoneNC,
    'South-West': AppColors.zoneSW,
    'South-East': AppColors.zoneSE,
    'South-South': AppColors.zoneSS,
  };

  @override
  Widget build(BuildContext context) {
    final total = zones.fold<int>(0, (s, z) => s + ((z['count'] as num?)?.toInt() ?? 0));

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: kGeopoliticalZones.map((zone) {
        final data = zones.firstWhere((z) => z['zone'] == zone, orElse: () => {'zone': zone, 'count': 0});
        final count = (data['count'] as num?)?.toInt() ?? 0;
        final pct = total > 0 ? (count / total * 100).toStringAsFixed(1) : '0';
        final color = _zoneColors[zone] ?? AppColors.green;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 6),
            Text(zone.split('-').map((w) => w[0]).join(), style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 11)),
            const SizedBox(width: 4),
            Text('$pct%', style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
          ]),
        );
      }).toList(),
    );
  }
}

class _Demographics extends StatelessWidget {
  final List<dynamic> gender;
  final List<dynamic> ageGroups;
  const _Demographics({required this.gender, required this.ageGroups});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Gender pie chart
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: AppColors.cardBg, borderRadius: BorderRadius.circular(16)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('By Gender', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              if (gender.isNotEmpty) ...[
                SizedBox(
                  height: 140,
                  child: PieChart(PieChartData(
                    sections: gender.asMap().entries.map((e) {
                      final g = e.value;
                      final colors = [AppColors.green, AppColors.lpOrange, AppColors.nnppPurple];
                      return PieChartSectionData(
                        value: (g['count'] as num?)?.toDouble() ?? 0,
                        title: '${g['gender']}',
                        color: colors[e.key % colors.length],
                        radius: 50,
                        titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white),
                      );
                    }).toList(),
                    sectionsSpace: 2,
                  )),
                ),
              ] else const Text('No data yet', style: TextStyle(color: AppColors.textMuted)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Age groups
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: AppColors.cardBg, borderRadius: BorderRadius.circular(16)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('By Age Group', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              ...ageGroups.map((ag) {
                final total = ageGroups.fold<int>(0, (s, a) => s + ((a['count'] as num?)?.toInt() ?? 0));
                final count = (ag['count'] as num?)?.toInt() ?? 0;
                final pct = total > 0 ? count / total : 0.0;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(children: [
                    SizedBox(width: 50, child: Text(ag['age_group'] ?? '', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
                    const SizedBox(width: 8),
                    Expanded(
                      child: LinearProgressIndicator(
                        value: pct, color: AppColors.green, backgroundColor: AppColors.green.withOpacity(0.1), minHeight: 8,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('${(pct * 100).toStringAsFixed(0)}%', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  ]),
                );
              }).toList(),
            ],
          ),
        ),
      ],
    );
  }
}
