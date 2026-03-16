import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/providers.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/api_service.dart';

class AdminShell extends ConsumerStatefulWidget {
  const AdminShell({super.key});

  @override
  ConsumerState<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends ConsumerState<AdminShell> {
  int _navIdx = 0;

  final List<String> _titles = ['Dashboard', 'Candidates', 'Parties', 'Election Config', 'Users', 'Simulate', 'Vote Log', 'Actual Results', 'Notifications', 'SMTP Settings'];
  final List<IconData> _icons = [
    Icons.dashboard_outlined, Icons.people_outline, Icons.groups_outlined,
    Icons.settings_outlined, Icons.manage_accounts_outlined,
    Icons.science_outlined, Icons.receipt_long_outlined, Icons.compare_arrows_outlined,
    Icons.notifications_outlined, Icons.email_outlined,
  ];

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    if (auth.user?.isAdmin != true) {
      return Scaffold(
        appBar: AppBar(title: const Text('Admin Panel')),
        body: const Center(child: Text('Access Denied', style: TextStyle(color: AppColors.pdpRed, fontSize: 24))),
      );
    }

    final pages = [
      const _AdminDashboardPage(),
      const _AdminCandidatesPage(),
      const _AdminPartiesPage(),
      const _ElectionConfigPage(),
      const _AdminUsersPage(),
      const _SimulationPage(),
      const _VoteLogPage(),
      const _ActualResultsPage(),
      const _NotificationsPage(),
      const _SmtpSettingsPage(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text('Admin — ${_titles[_navIdx]}'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/home')),
        actions: [
          Chip(
            label: const Text('ADMIN', style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.w800, fontSize: 11)),
            backgroundColor: AppColors.gold.withOpacity(0.1),
            side: BorderSide(color: AppColors.gold.withOpacity(0.3)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: Drawer(
        backgroundColor: AppColors.surface,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: AppColors.surfaceElevated),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.end, children: [
                const Icon(Icons.admin_panel_settings, color: AppColors.green, size: 36),
                const SizedBox(height: 8),
                Text('Admin Panel', style: Theme.of(context).textTheme.headlineMedium),
                Text(auth.user?.fullName ?? '', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ]),
            ),
            for (int i = 0; i < _titles.length; i++)
              ListTile(
                leading: Icon(_icons[i], color: _navIdx == i ? AppColors.green : AppColors.textMuted),
                title: Text(_titles[i], style: TextStyle(color: _navIdx == i ? AppColors.green : AppColors.textPrimary)),
                selected: _navIdx == i,
                selectedTileColor: AppColors.green.withOpacity(0.08),
                onTap: () { setState(() => _navIdx = i); Navigator.pop(context); },
              ),
          ],
        ),
      ),
      body: pages[_navIdx],
    );
  }
}

// ═══════════════════════════════════════════════════════
// ── Dashboard Overview
// ═══════════════════════════════════════════════════════
class _AdminDashboardPage extends ConsumerWidget {
  const _AdminDashboardPage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(adminStatsProvider);
    return statsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (stats) => GridView(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, childAspectRatio: 1.4, crossAxisSpacing: 12, mainAxisSpacing: 12,
        ),
        children: [
          _StatCard('Registered Voters', _fmt(stats['total_registered'] ?? 0), Icons.people_rounded, AppColors.green),
          _StatCard('Total Votes Cast', _fmt(stats['total_votes_cast'] ?? 0), Icons.how_to_vote_rounded, AppColors.adcBlue),
          _StatCard('Open Tiers', '${(stats['open_tiers'] as List?)?.length ?? 0}', Icons.check_circle_outline_rounded, AppColors.lpOrange),
          _StatCard('Flagged Accounts', '${stats['flagged_accounts'] ?? 0}', Icons.flag_outlined, AppColors.pdpRed),
        ],
      ),
    );
  }

  String _fmt(dynamic n) {
    final i = (n as num?)?.toInt() ?? 0;
    if (i >= 1000000) return '${(i / 1000000).toStringAsFixed(1)}M';
    if (i >= 1000) return '${(i / 1000).toStringAsFixed(1)}K';
    return i.toString();
  }
}

class _StatCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _StatCard(this.label, this.value, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: color, size: 28),
        const Spacer(),
        Text(value, style: TextStyle(color: color, fontSize: 26, fontWeight: FontWeight.w800)),
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════
// ── Candidates Management (with Edit + Delete)
// ═══════════════════════════════════════════════════════
class _AdminCandidatesPage extends ConsumerWidget {
  const _AdminCandidatesPage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final candidatesAsync = ref.watch(adminCandidatesProvider);
    return candidatesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (candidates) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(children: [
              Expanded(child: Text('${candidates.length} candidates', style: Theme.of(context).textTheme.bodyMedium)),
              ElevatedButton.icon(
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add'),
                style: ElevatedButton.styleFrom(minimumSize: const Size(0, 40)),
                onPressed: () => _showCandidateDialog(context, ref, null),
              ),
            ]),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: candidates.length,
              itemBuilder: (ctx, i) {
                final c = candidates[i];
                final colorHex = c['party_color'] ?? c['color_hex'] ?? '#008751';
                final color = Color(int.parse('0xFF${colorHex.replaceAll('#', '')}'));
                return ListTile(
                  leading: CircleAvatar(backgroundColor: color.withOpacity(0.2),
                      child: Text(c['full_name'][0], style: TextStyle(color: color, fontWeight: FontWeight.w700))),
                  title: Text(c['full_name'] ?? ''),
                  subtitle: Text('${kElectionTypeLabels[c['election_type']] ?? c['election_type']} • ${c['party_abbr'] ?? c['abbreviation'] ?? ''}'),
                  trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, color: AppColors.textSecondary),
                      onPressed: () => _showCandidateDialog(context, ref, c),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: AppColors.pdpRed),
                      onPressed: () => _confirmDelete(context, ref, c),
                    ),
                  ]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showCandidateDialog(BuildContext context, WidgetRef ref, Map<String, dynamic>? existing) {
    showDialog(context: context, builder: (_) => _CandidateFormDialog(existing: existing));
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, Map<String, dynamic> c) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        title: const Text('Delete Candidate?'),
        content: Text('Remove ${c['full_name']}? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.pdpRed),
            onPressed: () async {
              final api = ref.read(apiServiceProvider);
              await api.deleteCandidate(c['id']);
              ref.invalidate(adminCandidatesProvider);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _CandidateFormDialog extends ConsumerStatefulWidget {
  final Map<String, dynamic>? existing;
  const _CandidateFormDialog({this.existing});

  @override
  ConsumerState<_CandidateFormDialog> createState() => _CandidateFormDialogState();
}

class _CandidateFormDialogState extends ConsumerState<_CandidateFormDialog> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _bioCtrl;
  late final TextEditingController _ageCtrl;
  late final TextEditingController _runningMateCtrl;
  late String _type;
  int? _partyId;
  bool _isIncumbent = false;
  bool _loading = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameCtrl = TextEditingController(text: e?['full_name'] ?? '');
    _bioCtrl = TextEditingController(text: e?['bio'] ?? '');
    _ageCtrl = TextEditingController(text: e?['age']?.toString() ?? '');
    _runningMateCtrl = TextEditingController(text: e?['running_mate_name'] ?? '');
    _type = e?['election_type'] ?? 'presidential';
    _partyId = e?['party_id'];
    _isIncumbent = e?['is_incumbent'] == 1 || e?['is_incumbent'] == true;
  }

  @override
  Widget build(BuildContext context) {
    final partiesAsync = ref.watch(adminPartiesProvider);
    return AlertDialog(
      backgroundColor: AppColors.surfaceElevated,
      title: Text(_isEdit ? 'Edit Candidate' : 'Add Candidate'),
      content: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Full Name')),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _type,
            dropdownColor: AppColors.surfaceElevated,
            decoration: const InputDecoration(labelText: 'Election Type'),
            items: kElectionTypes.map((t) => DropdownMenuItem(value: t, child: Text(kElectionTypeLabels[t] ?? t))).toList(),
            onChanged: (v) => setState(() => _type = v!),
          ),
          const SizedBox(height: 12),
          partiesAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text('Error loading parties: $e'),
            data: (parties) {
              if (_partyId == null && parties.isNotEmpty) _partyId = parties[0]['id'];
              return DropdownButtonFormField<int>(
                value: _partyId,
                dropdownColor: AppColors.surfaceElevated,
                decoration: const InputDecoration(labelText: 'Party'),
                items: parties.map<DropdownMenuItem<int>>((p) =>
                    DropdownMenuItem(value: p['id'] as int, child: Text('${p['abbreviation']} — ${p['name']}'))).toList(),
                onChanged: (v) => setState(() => _partyId = v),
              );
            },
          ),
          const SizedBox(height: 12),
          TextField(controller: _runningMateCtrl, decoration: const InputDecoration(labelText: 'Running Mate (optional)')),
          const SizedBox(height: 12),
          TextField(controller: _ageCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Age (optional)')),
          const SizedBox(height: 12),
          TextField(controller: _bioCtrl, maxLines: 3, decoration: const InputDecoration(labelText: 'Bio (optional)')),
          const SizedBox(height: 8),
          CheckboxListTile(
            value: _isIncumbent,
            title: const Text('Incumbent'),
            onChanged: (v) => setState(() => _isIncumbent = v!),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
          ),
        ]),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _loading ? null : _submit,
          child: Text(_isEdit ? 'Save' : 'Add'),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (_nameCtrl.text.trim().isEmpty || _partyId == null) return;
    setState(() => _loading = true);
    final api = ref.read(apiServiceProvider);
    final data = {
      'full_name': _nameCtrl.text.trim(),
      'party_id': _partyId,
      'election_type': _type,
      'running_mate_name': _runningMateCtrl.text.trim().isNotEmpty ? _runningMateCtrl.text.trim() : null,
      'age': int.tryParse(_ageCtrl.text),
      'bio': _bioCtrl.text.trim().isNotEmpty ? _bioCtrl.text.trim() : null,
      'is_incumbent': _isIncumbent,
    };
    if (_isEdit) {
      await api.updateCandidate(widget.existing!['id'], data);
    } else {
      await api.addCandidate(data);
    }
    ref.invalidate(adminCandidatesProvider);
    if (mounted) Navigator.pop(context);
  }
}

// ═══════════════════════════════════════════════════════
// ── Parties Management (full CRUD)
// ═══════════════════════════════════════════════════════
class _AdminPartiesPage extends ConsumerWidget {
  const _AdminPartiesPage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final partiesAsync = ref.watch(adminPartiesProvider);
    return partiesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (parties) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(children: [
              Expanded(child: Text('${parties.length} parties', style: Theme.of(context).textTheme.bodyMedium)),
              ElevatedButton.icon(
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Party'),
                style: ElevatedButton.styleFrom(minimumSize: const Size(0, 40)),
                onPressed: () => _showPartyDialog(context, ref, null),
              ),
            ]),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: parties.length,
              itemBuilder: (ctx, i) {
                final p = parties[i];
                final hex = (p['color_hex'] ?? '#008751').replaceAll('#', '');
                final color = Color(int.parse('0xFF$hex'));
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: color,
                    child: Text(p['abbreviation']?[0] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                  ),
                  title: Text(p['name'] ?? ''),
                  subtitle: Text(p['abbreviation'] ?? ''),
                  trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, color: AppColors.textSecondary),
                      onPressed: () => _showPartyDialog(context, ref, p),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: AppColors.pdpRed),
                      onPressed: () => _confirmDelete(context, ref, p),
                    ),
                  ]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showPartyDialog(BuildContext context, WidgetRef ref, Map<String, dynamic>? existing) {
    showDialog(context: context, builder: (_) => _PartyFormDialog(existing: existing));
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, Map<String, dynamic> p) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        title: const Text('Delete Party?'),
        content: Text('Remove ${p['name']}? Candidates under this party will lose their party link.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.pdpRed),
            onPressed: () async {
              final api = ref.read(apiServiceProvider);
              await api.deleteParty(p['id']);
              ref.invalidate(adminPartiesProvider);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _PartyFormDialog extends ConsumerStatefulWidget {
  final Map<String, dynamic>? existing;
  const _PartyFormDialog({this.existing});

  @override
  ConsumerState<_PartyFormDialog> createState() => _PartyFormDialogState();
}

class _PartyFormDialogState extends ConsumerState<_PartyFormDialog> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _abbrCtrl;
  late final TextEditingController _colorCtrl;
  late final TextEditingController _manifestoCtrl;
  bool _loading = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameCtrl = TextEditingController(text: e?['name'] ?? '');
    _abbrCtrl = TextEditingController(text: e?['abbreviation'] ?? '');
    _colorCtrl = TextEditingController(text: e?['color_hex'] ?? '#008751');
    _manifestoCtrl = TextEditingController(text: e?['manifesto'] ?? '');
  }

  @override
  Widget build(BuildContext context) {
    final previewHex = _colorCtrl.text.replaceAll('#', '');
    Color previewColor;
    try { previewColor = Color(int.parse('0xFF$previewHex')); } catch (_) { previewColor = AppColors.green; }

    return AlertDialog(
      backgroundColor: AppColors.surfaceElevated,
      title: Text(_isEdit ? 'Edit Party' : 'Add Party'),
      content: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Party Name')),
          const SizedBox(height: 12),
          TextField(controller: _abbrCtrl, decoration: const InputDecoration(labelText: 'Abbreviation (e.g. APC)')),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: TextField(
                controller: _colorCtrl,
                decoration: const InputDecoration(labelText: 'Color Hex (e.g. #008751)'),
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(width: 8),
            Container(width: 40, height: 40, decoration: BoxDecoration(color: previewColor, borderRadius: BorderRadius.circular(8))),
          ]),
          const SizedBox(height: 12),
          TextField(controller: _manifestoCtrl, maxLines: 3, decoration: const InputDecoration(labelText: 'Manifesto (optional)')),
        ]),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _loading ? null : _submit,
          child: Text(_isEdit ? 'Save' : 'Add'),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (_nameCtrl.text.trim().isEmpty || _abbrCtrl.text.trim().isEmpty) return;
    setState(() => _loading = true);
    final api = ref.read(apiServiceProvider);
    final data = {
      'name': _nameCtrl.text.trim(),
      'abbreviation': _abbrCtrl.text.trim().toUpperCase(),
      'color_hex': _colorCtrl.text.trim(),
      'manifesto': _manifestoCtrl.text.trim().isNotEmpty ? _manifestoCtrl.text.trim() : null,
    };
    if (_isEdit) {
      await api.updateParty(widget.existing!['id'], data);
    } else {
      await api.addParty(data);
    }
    ref.invalidate(adminPartiesProvider);
    if (mounted) Navigator.pop(context);
  }
}

// ═══════════════════════════════════════════════════════
// ── Election Config
// ═══════════════════════════════════════════════════════
class _ElectionConfigPage extends ConsumerWidget {
  const _ElectionConfigPage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final configAsync = ref.watch(electionConfigProvider);
    return configAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (config) => ListView(
        padding: const EdgeInsets.all(16),
        children: config.map<Widget>((c) {
          final isOpen = c['is_open'] == 1 || c['is_open'] == true;
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isOpen ? AppColors.green.withOpacity(0.3) : AppColors.textMuted.withOpacity(0.15)),
            ),
            child: Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(c['label'] ?? kElectionTypeLabels[c['election_type']] ?? '', style: const TextStyle(fontWeight: FontWeight.w700)),
                Text(c['election_type'], style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: isOpen ? AppColors.green.withOpacity(0.15) : AppColors.textMuted.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(isOpen ? 'OPEN' : 'CLOSED',
                      style: TextStyle(color: isOpen ? AppColors.green : AppColors.textMuted, fontWeight: FontWeight.w700, fontSize: 11)),
                ),
              ])),
              Switch(
                value: isOpen,
                activeColor: AppColors.green,
                onChanged: (val) async {
                  final api = ref.read(apiServiceProvider);
                  await api.updateElectionConfig(c['election_type'], {'is_open': val});
                  ref.invalidate(electionConfigProvider);
                },
              ),
            ]),
          );
        }).toList(),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
// ── Users (with Flag/Unflag + Delete)
// ═══════════════════════════════════════════════════════
class _AdminUsersPage extends ConsumerStatefulWidget {
  const _AdminUsersPage();

  @override
  ConsumerState<_AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends ConsumerState<_AdminUsersPage> {
  List<dynamic>? _users;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final data = await ref.read(apiServiceProvider).getAdminUsers();
    if (mounted) setState(() { _users = data['users'] as List<dynamic>? ?? []; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    final users = _users ?? [];
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        itemCount: users.length,
        itemBuilder: (ctx, i) {
          final u = users[i];
          final isFlagged = u['is_flagged'] == 1 || u['is_flagged'] == true;
          final isAdmin = u['is_admin'] == 1 || u['is_admin'] == true;
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: isFlagged ? AppColors.pdpRed.withOpacity(0.15) : AppColors.green.withOpacity(0.1),
              child: Text(
                (u['full_name'] ?? '?')[0],
                style: TextStyle(color: isFlagged ? AppColors.pdpRed : AppColors.green, fontWeight: FontWeight.w700),
              ),
            ),
            title: Row(children: [
              Flexible(child: Text(u['full_name'] ?? '', overflow: TextOverflow.ellipsis)),
              if (isAdmin) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(color: AppColors.gold.withOpacity(0.15), borderRadius: BorderRadius.circular(4)),
                  child: const Text('ADMIN', style: TextStyle(color: AppColors.gold, fontSize: 9, fontWeight: FontWeight.w800)),
                ),
              ],
            ]),
            subtitle: Text('${u['state'] ?? ''} • ${u['phone'] ?? u['email'] ?? ''}', style: const TextStyle(fontSize: 12)),
            trailing: isAdmin ? null : Row(mainAxisSize: MainAxisSize.min, children: [
              IconButton(
                tooltip: isFlagged ? 'Unflag' : 'Flag',
                icon: Icon(
                  isFlagged ? Icons.flag_rounded : Icons.flag_outlined,
                  color: isFlagged ? AppColors.pdpRed : AppColors.textMuted,
                ),
                onPressed: () async {
                  await ref.read(apiServiceProvider).flagUser(u['id'], !isFlagged);
                  _load();
                },
              ),
              IconButton(
                tooltip: 'Delete user',
                icon: const Icon(Icons.delete_outline, color: AppColors.pdpRed),
                onPressed: () => _confirmDeleteUser(u),
              ),
            ]),
          );
        },
      ),
    );
  }

  void _confirmDeleteUser(Map<String, dynamic> u) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        title: const Text('Delete User?'),
        content: Text('Permanently delete ${u['full_name']} and all their votes? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.pdpRed),
            onPressed: () async {
              await ref.read(apiServiceProvider).deleteUser(u['id']);
              if (context.mounted) Navigator.pop(context);
              _load();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
// ── Notifications
// ═══════════════════════════════════════════════════════
class _NotificationsPage extends ConsumerStatefulWidget {
  const _NotificationsPage();

  @override
  ConsumerState<_NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends ConsumerState<_NotificationsPage> {
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  bool _sending = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Broadcast Message', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 16),
          TextField(controller: _titleCtrl, decoration: const InputDecoration(labelText: 'Notification Title')),
          const SizedBox(height: 12),
          TextField(controller: _bodyCtrl, maxLines: 4, decoration: const InputDecoration(labelText: 'Message Body')),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            icon: const Icon(Icons.send_rounded),
            label: Text(_sending ? 'Sending...' : 'Broadcast to All Users'),
            onPressed: _sending ? null : () async {
              setState(() => _sending = true);
              try {
                await ref.read(apiServiceProvider).sendNotification(_titleCtrl.text, _bodyCtrl.text);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Notification sent!')));
                  _titleCtrl.clear();
                  _bodyCtrl.clear();
                }
              } finally {
                if (mounted) setState(() => _sending = false);
              }
            },
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
// ── SMTP Settings
// ═══════════════════════════════════════════════════════
class _SmtpSettingsPage extends ConsumerStatefulWidget {
  const _SmtpSettingsPage();
  @override
  ConsumerState<_SmtpSettingsPage> createState() => _SmtpSettingsPageState();
}

class _SmtpSettingsPageState extends ConsumerState<_SmtpSettingsPage> {
  final _hostCtrl   = TextEditingController();
  final _portCtrl   = TextEditingController(text: '587');
  final _userCtrl   = TextEditingController();
  final _passCtrl   = TextEditingController();
  final _fromCtrl   = TextEditingController();
  bool _saving = false;
  bool _obscurePass = true;
  String? _statusMsg;
  bool _statusOk = true;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('SMTP Email Settings', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 4),
          Text(
            'Configure the email server used to send OTP verification codes.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.green.withOpacity(0.15)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('SMTP Server', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700, color: AppColors.green)),
                const SizedBox(height: 16),
                _field(_hostCtrl, 'SMTP Host', 'e.g. smtp.gmail.com', Icons.dns_outlined),
                const SizedBox(height: 12),
                _field(_portCtrl, 'Port', '587 (TLS) or 465 (SSL)', Icons.tag_outlined, keyboard: TextInputType.number),
                const SizedBox(height: 24),
                Text('Authentication', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700, color: AppColors.green)),
                const SizedBox(height: 16),
                _field(_userCtrl, 'SMTP Username / Email', 'your@email.com', Icons.person_outline),
                const SizedBox(height: 12),
                TextField(
                  controller: _passCtrl,
                  obscureText: _obscurePass,
                  decoration: InputDecoration(
                    labelText: 'SMTP Password / App Password',
                    prefixIcon: const Icon(Icons.lock_outline, color: AppColors.textMuted),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePass ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: AppColors.textMuted),
                      onPressed: () => setState(() => _obscurePass = !_obscurePass),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text('Sender', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700, color: AppColors.green)),
                const SizedBox(height: 16),
                _field(_fromCtrl, 'From Address', 'no-reply@voteng.ng', Icons.alternate_email_outlined),
                const SizedBox(height: 24),
                if (_statusMsg != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: (_statusOk ? AppColors.green : AppColors.pdpRed).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(children: [
                      Icon(_statusOk ? Icons.check_circle_outline : Icons.error_outline,
                          color: _statusOk ? AppColors.green : AppColors.pdpRed, size: 18),
                      const SizedBox(width: 8),
                      Expanded(child: Text(_statusMsg!, style: TextStyle(color: _statusOk ? AppColors.green : AppColors.pdpRed, fontSize: 13))),
                    ]),
                  ),
                  const SizedBox(height: 16),
                ],
                ElevatedButton.icon(
                  icon: _saving
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.save_outlined),
                  label: Text(_saving ? 'Saving...' : 'Save SMTP Settings'),
                  onPressed: _saving ? null : _save,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label, String hint, IconData icon, {TextInputType? keyboard}) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboard,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 12),
        prefixIcon: Icon(icon, color: AppColors.textMuted),
      ),
    );
  }

  Future<void> _save() async {
    if (_hostCtrl.text.isEmpty || _userCtrl.text.isEmpty || _passCtrl.text.isEmpty) {
      setState(() { _statusMsg = 'Host, username, and password are required.'; _statusOk = false; });
      return;
    }
    setState(() => _saving = true);
    try {
      final api = ref.read(apiServiceProvider);
      await api.updateSmtpSettings({
        'host': _hostCtrl.text.trim(),
        'port': int.tryParse(_portCtrl.text) ?? 587,
        'user': _userCtrl.text.trim(),
        'pass': _passCtrl.text,
        'from': _fromCtrl.text.trim().isNotEmpty ? _fromCtrl.text.trim() : _userCtrl.text.trim(),
      });
      setState(() { _statusMsg = 'SMTP settings saved successfully.'; _statusOk = true; });
    } catch (e) {
      setState(() { _statusMsg = 'Failed to save: $e'; _statusOk = false; });
    } finally {
      setState(() => _saving = false);
    }
  }
}

// ═══════════════════════════════════════════════════════
// ── Election Simulation
// ═══════════════════════════════════════════════════════
class _SimulationPage extends ConsumerStatefulWidget {
  const _SimulationPage();
  @override
  ConsumerState<_SimulationPage> createState() => _SimulationPageState();
}

class _SimulationPageState extends ConsumerState<_SimulationPage> {
  double _voterCount = 500;
  final Map<String, bool> _types = {
    'presidential': true,
    'senate': false,
    'house': false,
    'governorship': false,
    'state_assembly': false,
  };
  bool _running = false;
  bool _clearing = false;
  String? _resultMsg;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Simulate Election', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 4),
        Text('Generate fake voters and votes to test the analytics dashboard.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: 24),

        // Voter count slider
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.green.withOpacity(0.15)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Icon(Icons.people_rounded, color: AppColors.green),
              const SizedBox(width: 8),
              Text('Number of Simulated Voters', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: Slider(
                  value: _voterCount,
                  min: 50,
                  max: 5000,
                  divisions: 99,
                  activeColor: AppColors.green,
                  label: _voterCount.toInt().toString(),
                  onChanged: (v) => setState(() => _voterCount = v),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: AppColors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Text('${_voterCount.toInt()}', style: const TextStyle(color: AppColors.green, fontWeight: FontWeight.w800, fontSize: 18)),
              ),
            ]),
          ]),
        ),
        const SizedBox(height: 16),

        // Election type checkboxes
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.adcBlue.withOpacity(0.15)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Icon(Icons.how_to_vote_rounded, color: AppColors.adcBlue),
              const SizedBox(width: 8),
              Text('Election Types', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
            ]),
            const SizedBox(height: 8),
            ..._types.keys.map((type) => CheckboxListTile(
              value: _types[type],
              title: Text(kElectionTypeLabels[type] ?? type),
              onChanged: (v) => setState(() => _types[type] = v!),
              activeColor: AppColors.green,
              dense: true,
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            )),
          ]),
        ),
        const SizedBox(height: 24),

        // Result message
        if (_resultMsg != null) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.green.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.green.withOpacity(0.2)),
            ),
            child: Text(_resultMsg!, style: const TextStyle(color: AppColors.green, fontSize: 13)),
          ),
          const SizedBox(height: 16),
        ],

        // Action buttons
        Row(children: [
          Expanded(
            child: ElevatedButton.icon(
              icon: _running
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.play_arrow_rounded),
              label: Text(_running ? 'Generating...' : 'Run Simulation'),
              onPressed: _running ? null : _run,
            ),
          ),
          const SizedBox(width: 12),
          OutlinedButton.icon(
            icon: _clearing
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.delete_sweep_outlined, color: AppColors.pdpRed),
            label: Text(_clearing ? 'Clearing...' : 'Clear Data', style: const TextStyle(color: AppColors.pdpRed)),
            style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.pdpRed)),
            onPressed: _clearing ? null : _clear,
          ),
        ]),
      ]),
    );
  }

  Future<void> _run() async {
    final selected = _types.entries.where((e) => e.value).map((e) => e.key).toList();
    if (selected.isEmpty) {
      setState(() => _resultMsg = '⚠️ Select at least one election type.');
      return;
    }
    setState(() { _running = true; _resultMsg = null; });
    try {
      final api = ref.read(apiServiceProvider);
      final result = await api.runSimulation(voterCount: _voterCount.toInt(), electionTypes: selected);
      setState(() => _resultMsg = '✅ ${result['message']}\n• Voters created: ${result['voters_created']}\n• Votes cast: ${result['votes_cast']}\n• Types: ${(result['election_types'] as List).join(', ')}');
      ref.invalidate(adminStatsProvider);
    } catch (e) {
      setState(() => _resultMsg = '❌ Error: $e');
    } finally {
      setState(() => _running = false);
    }
  }

  Future<void> _clear() async {
    setState(() { _clearing = true; _resultMsg = null; });
    try {
      final api = ref.read(apiServiceProvider);
      final result = await api.clearSimulation();
      setState(() => _resultMsg = '🗑️ ${result['message']}\n• Voters removed: ${result['voters_removed']}');
      ref.invalidate(adminStatsProvider);
    } catch (e) {
      setState(() => _resultMsg = '❌ Error: $e');
    } finally {
      setState(() => _clearing = false);
    }
  }
}

// ═══════════════════════════════════════════════════════
// ── Vote Audit Log
// ═══════════════════════════════════════════════════════
class _VoteLogPage extends ConsumerStatefulWidget {
  const _VoteLogPage();
  @override
  ConsumerState<_VoteLogPage> createState() => _VoteLogPageState();
}

class _VoteLogPageState extends ConsumerState<_VoteLogPage> {
  List<dynamic> _votes = [];
  int _total = 0;
  int _page = 1;
  bool _loading = true;
  String? _filterType;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await ref.read(apiServiceProvider).getVoteLog(page: _page, limit: 50, type: _filterType);
      if (mounted) setState(() { _votes = data['votes'] ?? []; _total = data['total'] ?? 0; _loading = false; });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      // Filter bar
      Padding(
        padding: const EdgeInsets.all(12),
        child: Row(children: [
          Text('$_total votes', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
          const Spacer(),
          DropdownButton<String?>(
            value: _filterType,
            dropdownColor: AppColors.surfaceElevated,
            hint: const Text('All Types', style: TextStyle(fontSize: 13)),
            items: [
              const DropdownMenuItem(value: null, child: Text('All Types')),
              ...kElectionTypes.map((t) => DropdownMenuItem(value: t, child: Text(kElectionTypeLabels[t] ?? t, style: const TextStyle(fontSize: 13)))),
            ],
            onChanged: (v) { _filterType = v; _page = 1; _load(); },
          ),
        ]),
      ),
      // List
      Expanded(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _votes.isEmpty
                ? const Center(child: Text('No votes recorded yet', style: TextStyle(color: AppColors.textMuted)))
                : ListView.builder(
                    itemCount: _votes.length,
                    itemBuilder: (ctx, i) {
                      final v = _votes[i];
                      return ListTile(
                        dense: true,
                        leading: CircleAvatar(
                          radius: 16,
                          backgroundColor: AppColors.green.withOpacity(0.1),
                          child: Text('${v['party'] ?? '?'}'[0], style: const TextStyle(fontSize: 11, color: AppColors.green)),
                        ),
                        title: Text('${v['voter_name']} → ${v['candidate_name']}', style: const TextStyle(fontSize: 13)),
                        subtitle: Text(
                          '${kElectionTypeLabels[v['election_type']] ?? v['election_type']} • ${v['party']} • ${v['user_state'] ?? ''} • ${v['user_gender'] ?? ''}',
                          style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                        ),
                        trailing: Text(
                          _formatTime(v['cast_at']),
                          style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                        ),
                      );
                    },
                  ),
      ),
      // Pagination
      if (_total > 50)
        Padding(
          padding: const EdgeInsets.all(8),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: _page > 1 ? () { _page--; _load(); } : null,
            ),
            Text('Page $_page of ${(_total / 50).ceil()}', style: const TextStyle(fontSize: 13)),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: _page < (_total / 50).ceil() ? () { _page++; _load(); } : null,
            ),
          ]),
        ),
    ]);
  }

  String _formatTime(dynamic dt) {
    if (dt == null) return '';
    try {
      final d = DateTime.parse(dt.toString()).toLocal();
      return '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    } catch (_) { return dt.toString(); }
  }
}

// ═══════════════════════════════════════════════════════
// ── Actual Results Entry
// ═══════════════════════════════════════════════════════
class _ActualResultsPage extends ConsumerStatefulWidget {
  const _ActualResultsPage();
  @override
  ConsumerState<_ActualResultsPage> createState() => _ActualResultsPageState();
}

class _ActualResultsPageState extends ConsumerState<_ActualResultsPage> {
  String _selectedType = 'presidential';
  final Map<int, TextEditingController> _voteCountCtrls = {};
  final Map<int, TextEditingController> _pctCtrls = {};
  bool _saving = false;
  String? _statusMsg;

  @override
  Widget build(BuildContext context) {
    final candidatesAsync = ref.watch(adminCandidatesProvider);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Actual Election Results', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 4),
        Text('Enter the real INEC results for comparison with app votes.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: 16),

        DropdownButtonFormField<String>(
          value: _selectedType,
          dropdownColor: AppColors.surfaceElevated,
          decoration: const InputDecoration(labelText: 'Election Type'),
          items: kElectionTypes.map((t) => DropdownMenuItem(value: t, child: Text(kElectionTypeLabels[t] ?? t))).toList(),
          onChanged: (v) => setState(() => _selectedType = v!),
        ),
        const SizedBox(height: 16),

        candidatesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text('Error: $e'),
          data: (candidates) {
            final filtered = candidates.where((c) => c['election_type'] == _selectedType).toList();
            if (filtered.isEmpty) return const Text('No candidates for this election type.', style: TextStyle(color: AppColors.textMuted));
            return Column(
              children: filtered.map<Widget>((c) {
                final id = c['id'] as int;
                _voteCountCtrls.putIfAbsent(id, () => TextEditingController());
                _pctCtrls.putIfAbsent(id, () => TextEditingController());
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.cardBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.textMuted.withOpacity(0.1)),
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(c['full_name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w700)),
                    Text('${c['abbreviation'] ?? c['party_abbr'] ?? ''}', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                    const SizedBox(height: 10),
                    Row(children: [
                      Expanded(child: TextField(
                        controller: _voteCountCtrls[id],
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Vote Count', isDense: true),
                      )),
                      const SizedBox(width: 12),
                      Expanded(child: TextField(
                        controller: _pctCtrls[id],
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(labelText: 'Percentage (%)', isDense: true),
                      )),
                    ]),
                  ]),
                );
              }).toList(),
            );
          },
        ),

        const SizedBox(height: 16),
        if (_statusMsg != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(_statusMsg!, style: const TextStyle(color: AppColors.green, fontSize: 13)),
          ),
          const SizedBox(height: 12),
        ],

        ElevatedButton.icon(
          icon: _saving
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Icon(Icons.save_outlined),
          label: Text(_saving ? 'Saving...' : 'Save Actual Results'),
          onPressed: _saving ? null : _save,
        ),
      ]),
    );
  }

  Future<void> _save() async {
    setState(() { _saving = true; _statusMsg = null; });
    try {
      final results = <Map<String, dynamic>>[];
      for (final entry in _voteCountCtrls.entries) {
        final count = int.tryParse(entry.value.text) ?? 0;
        final pct = double.tryParse(_pctCtrls[entry.key]?.text ?? '') ?? 0.0;
        if (count > 0 || pct > 0) {
          results.add({
            'candidate_id': entry.key,
            'election_type': _selectedType,
            'real_vote_count': count,
            'real_percentage': pct,
          });
        }
      }
      if (results.isEmpty) {
        setState(() { _statusMsg = '⚠️ Enter at least one result.'; _saving = false; });
        return;
      }
      await ref.read(apiServiceProvider).submitActualResults(results);
      setState(() => _statusMsg = '✅ Saved ${results.length} result(s).');
    } catch (e) {
      setState(() => _statusMsg = '❌ Error: $e');
    } finally {
      setState(() => _saving = false);
    }
  }
}
