import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/providers.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/api_service.dart';

class VoteReceiptScreen extends ConsumerWidget {
  final String electionType;
  const VoteReceiptScreen({super.key, required this.electionType});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final api = ref.read(apiServiceProvider);
    final label = kElectionTypeLabels[electionType] ?? electionType;

    return Scaffold(
      appBar: AppBar(
        title: Text('Vote Receipt — $label'),
        leading: IconButton(icon: const Icon(Icons.home_outlined), onPressed: () => context.go('/home')),
      ),
      body: FutureBuilder(
        future: api.getVoteReceipt(electionType),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError || !snap.hasData) {
            return const Center(child: Text('Could not load receipt'));
          }
          final r = snap.data! as Map<String, dynamic>;
          final colorHex = r['color_hex'] ?? '#008751';
          final color = Color(int.parse('0xFF${colorHex.replaceAll('#', '')}'));
          final castAt = r['cast_at'] != null ? DateTime.parse(r['cast_at']) : DateTime.now();

          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.cardBg,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.green.withOpacity(0.4), width: 2),
                  ),
                  child: Column(
                    children: [
                      // Checkmark
                      Container(
                        width: 72, height: 72,
                        decoration: const BoxDecoration(color: AppColors.green, shape: BoxShape.circle),
                        child: const Icon(Icons.check_rounded, color: Colors.white, size: 40),
                      ),
                      const SizedBox(height: 16),
                      Text('Vote Cast Successfully!', style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: AppColors.green)),
                      const SizedBox(height: 4),
                      Text('VoteNG 2027 — Official Mock Ballot Receipt', style: Theme.of(context).textTheme.bodyMedium),
                      const Divider(height: 32),
                      _Row('Election', label),
                      _Row('Candidate', r['candidate_name'] ?? ''),
                      _Row('Party', '${r['party_name'] ?? ''} (${r['party_abbr'] ?? ''})'),
                      _Row('Date', DateFormat('dd MMM yyyy, HH:mm').format(castAt)),
                      _Row('Vote ID', '#${r['vote_id'] ?? ''}'),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                        child: Row(children: [
                          Container(width: 6, height: 40, color: color, margin: const EdgeInsets.only(right: 12)),
                          Text('${r['party_name'] ?? ''}', style: TextStyle(color: color, fontWeight: FontWeight.w700)),
                        ]),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  icon: const Icon(Icons.share_rounded),
                  label: const Text('Share My "I Voted" Card'),
                  onPressed: () {
                    Share.share(
                      '🗳️ I just cast my mock vote in the VoteNG 2027 Nigeria Election Experiment!\n\n'
                      'I voted in the $label election.\n\n'
                      'Join me at voteng.ng and add your voice to Nigeria\'s biggest political social experiment!\n'
                      '#VoteNG2027 #Nigeria2027 #SocialExperiment',
                    );
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.green),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => context.go('/analytics'),
                  child: const Text('View Live Results'),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => context.go('/home'),
                  child: const Text('Back to Home'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  const _Row(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary)),
          Flexible(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600), textAlign: TextAlign.right)),
        ],
      ),
    );
  }
}
