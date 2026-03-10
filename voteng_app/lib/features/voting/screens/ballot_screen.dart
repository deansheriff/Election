import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/providers.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/models/models.dart';

class BallotScreen extends ConsumerStatefulWidget {
  final String electionType;
  const BallotScreen({super.key, required this.electionType});

  @override
  ConsumerState<BallotScreen> createState() => _BallotScreenState();
}

class _BallotScreenState extends ConsumerState<BallotScreen> {
  int? _selectedCandidateId;
  bool _voting = false;

  @override
  Widget build(BuildContext context) {
    final candidatesAsync = ref.watch(candidatesProvider(widget.electionType));
    final label = kElectionTypeLabels[widget.electionType] ?? widget.electionType;

    return Scaffold(
      appBar: AppBar(
        title: Text('$label 2027'),
        leading: IconButton(icon: const Icon(Icons.close), onPressed: () => context.go('/home')),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(40),
          child: Container(
            color: AppColors.surface,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(children: [
                const Icon(Icons.how_to_vote_outlined, color: AppColors.green, size: 16),
                const SizedBox(width: 8),
                Text('Select one candidate to vote', style: Theme.of(context).textTheme.bodyMedium),
              ]),
            ),
          ),
        ),
      ),
      body: candidatesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.error_outline, color: AppColors.pdpRed, size: 48),
            const SizedBox(height: 12),
            Text('Could not load candidates\n$e', textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: () => ref.invalidate(candidatesProvider(widget.electionType)), child: const Text('Retry')),
          ]),
        ),
        data: (candidates) => _BallotList(
          candidates: candidates,
          selectedId: _selectedCandidateId,
          onSelect: (id) => setState(() => _selectedCandidateId = id),
        ),
      ),
      bottomNavigationBar: _BottomConfirmBar(
        selectedId: _selectedCandidateId,
        voting: _voting,
        onConfirm: _showConfirmation,
      ),
    );
  }

  Future<void> _showConfirmation() async {
    if (_selectedCandidateId == null) return;
    final candidates = ref.read(candidatesProvider(widget.electionType)).value;
    final selected = candidates?.firstWhere((c) => c['id'] == _selectedCandidateId);
    if (selected == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        title: const Text('Confirm Your Vote'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('You are voting for:'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.green.withOpacity(0.3)),
              ),
              child: Row(children: [
                const Icon(Icons.person_rounded, color: AppColors.green, size: 32),
                const SizedBox(width: 12),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(selected['full_name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w700)),
                  Text('${selected['party_name'] ?? ''} (${selected['party_abbr'] ?? ''})',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                ]),
              ]),
            ),
            const SizedBox(height: 12),
            const Text('⚠️ This cannot be undone.',
                style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.w600)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Cast Vote')),
        ],
      ),
    );

    if (confirmed == true) await _castVote();
  }

  Future<void> _castVote() async {
    setState(() => _voting = true);
    try {
      final api = ref.read(apiServiceProvider);
      await api.castVote(_selectedCandidateId!, widget.electionType);
      ref.invalidate(voteStatusProvider);
      if (mounted) context.go('/receipt/${widget.electionType}');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.pdpRed),
        );
      }
    } finally {
      if (mounted) setState(() => _voting = false);
    }
  }
}

class _BallotList extends StatelessWidget {
  final List<dynamic> candidates;
  final int? selectedId;
  final ValueChanged<int?> onSelect;

  const _BallotList({required this.candidates, this.selectedId, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: candidates.length,
      itemBuilder: (ctx, i) {
        final c = candidates[i];
        final colorHex = c['party_color'] ?? c['color_hex'] ?? '#008751';
        final color = Color(int.parse('0xFF${colorHex.replaceAll('#', '')}'));
        final isSelected = selectedId == c['id'];

        return GestureDetector(
          onTap: () => onSelect(c['id']),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: isSelected ? color.withOpacity(0.12) : AppColors.cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? color : AppColors.textMuted.withOpacity(0.15),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                // Left color accent bar
                Container(
                  width: 6,
                  height: 90,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), bottomLeft: Radius.circular(16)),
                  ),
                ),
                const SizedBox(width: 12),
                // Candidate photo
                CircleAvatar(
                  radius: 28,
                  backgroundColor: color.withOpacity(0.2),
                  child: Text(
                    (c['full_name'] as String? ?? 'C')[0],
                    style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 20),
                  ),
                ),
                const SizedBox(width: 12),
                // Candidate info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(c['full_name'] ?? '',
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                      if (c['running_mate_name'] != null)
                        Text('Running mate: ${c['running_mate_name']}',
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                      const SizedBox(height: 4),
                      Row(children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(c['party_abbr'] ?? '', style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 11)),
                        ),
                        const SizedBox(width: 6),
                        Text(c['party_name'] ?? '',
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                      ]),
                    ],
                  ),
                ),
                // Radio
                Radio<int>(
                  value: c['id'],
                  groupValue: selectedId,
                  onChanged: onSelect,
                  activeColor: color,
                ),
              ],
            ),
          ),
        ).animate().fadeIn(delay: Duration(milliseconds: i * 80)).slideY(begin: 0.1);
      },
    );
  }
}

class _BottomConfirmBar extends StatelessWidget {
  final int? selectedId;
  final bool voting;
  final VoidCallback onConfirm;

  const _BottomConfirmBar({this.selectedId, required this.voting, required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.textMuted.withOpacity(0.15))),
      ),
      child: ElevatedButton(
        onPressed: selectedId != null && !voting ? onConfirm : null,
        child: voting
            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : Text(selectedId == null ? 'Select a Candidate to Vote' : 'Confirm & Cast Vote'),
      ),
    );
  }
}
