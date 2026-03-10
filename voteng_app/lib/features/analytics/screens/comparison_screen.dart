import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/providers.dart';

class ComparisonScreen extends ConsumerWidget {
  const ComparisonScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final comparisonAsync = ref.watch(comparisonProvider('presidential'));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Platform vs INEC Results'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/analytics')),
      ),
      body: comparisonAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (data) {
          final comparison = data['comparison'] as List<dynamic>? ?? [];
          final accuracy = data['accuracy_score'];
          final hasActual = comparison.any((c) => c['actual_percentage'] != null);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Accuracy score card
              if (accuracy != null) ...[
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: accuracy >= 70
                          ? [AppColors.darkGreen, const Color(0xFF004D2A)]
                          : [const Color(0xFF3A1500), const Color(0xFF1A0A00)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: (accuracy >= 70 ? AppColors.green : AppColors.lpOrange).withOpacity(0.4)),
                  ),
                  child: Column(
                    children: [
                      Text('Platform Accuracy Score', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 12),
                      Text('${accuracy.toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 52, fontWeight: FontWeight.w900,
                            color: accuracy >= 70 ? AppColors.green : AppColors.lpOrange,
                          )),
                      const SizedBox(height: 4),
                      Text(
                        accuracy >= 80 ? '🎉 Excellent prediction accuracy!' :
                        accuracy >= 60 ? '👍 Good prediction accuracy' :
                        '📊 Interesting deviation from INEC results',
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              if (!hasActual) ...[
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.gold.withOpacity(0.3)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.access_time_rounded, color: AppColors.gold),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('INEC Results Not Yet Available', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.gold)),
                      const SizedBox(height: 4),
                      Text('Official results will be entered by admin after the February 20, 2027 election. '
                          'Check back post-election to see accuracy scores.',
                          style: Theme.of(context).textTheme.bodyMedium),
                    ])),
                  ]),
                ),
                const SizedBox(height: 20),
              ],

              // Header row
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(color: AppColors.surfaceElevated, borderRadius: BorderRadius.circular(10)),
                child: Row(children: [
                  Expanded(flex: 3, child: Text('Candidate', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12))),
                  Expanded(flex: 2, child: Text('Platform %', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AppColors.green), textAlign: TextAlign.center)),
                  Expanded(flex: 2, child: Text('INEC %', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AppColors.gold), textAlign: TextAlign.center)),
                  Expanded(flex: 2, child: Text('Diff', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12), textAlign: TextAlign.center)),
                ]),
              ),
              const SizedBox(height: 8),

              // Candidate rows
              ...comparison.map((c) {
                final colorHex = c['color_hex'] ?? '#008751';
                final color = Color(int.parse('0xFF${colorHex.replaceAll('#', '')}'));
                final diff = c['difference'] as double?;

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.cardBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border(left: BorderSide(color: color, width: 4)),
                  ),
                  child: Row(children: [
                    Expanded(flex: 3, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(c['full_name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13), overflow: TextOverflow.ellipsis),
                      Text(c['party_abbr'] ?? '', style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
                    ])),
                    Expanded(flex: 2, child: Text(
                      '${(c['platform_percentage'] as num?)?.toStringAsFixed(1) ?? '-'}%',
                      style: const TextStyle(color: AppColors.green, fontWeight: FontWeight.w700),
                      textAlign: TextAlign.center,
                    )),
                    Expanded(flex: 2, child: Text(
                      c['actual_percentage'] != null ? '${(c['actual_percentage'] as num).toStringAsFixed(1)}%' : 'TBD',
                      style: TextStyle(color: c['actual_percentage'] != null ? AppColors.gold : AppColors.textMuted, fontWeight: FontWeight.w700),
                      textAlign: TextAlign.center,
                    )),
                    Expanded(flex: 2, child: diff != null ? Text(
                      '${diff > 0 ? '+' : ''}${diff.toStringAsFixed(1)}%',
                      style: TextStyle(color: diff.abs() < 3 ? AppColors.green : diff.abs() < 10 ? AppColors.lpOrange : AppColors.pdpRed,
                          fontWeight: FontWeight.w700),
                      textAlign: TextAlign.center,
                    ) : const Text('—', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textMuted))),
                  ]),
                );
              }).toList(),

              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.surfaceElevated, borderRadius: BorderRadius.circular(10)),
                child: const Text(
                  '💡 This comparison shows how closely the crowd-sourced mock election predicted the real INEC outcome. A difference < 3% is considered excellent accuracy.',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
