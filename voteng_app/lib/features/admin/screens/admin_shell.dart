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

  final List<String> _titles = ['Dashboard', 'Candidates', 'Election Config', 'Users', 'Notifications', 'SMTP Settings'];
  final List<IconData> _icons = [
    Icons.dashboard_outlined, Icons.people_outline, Icons.settings_outlined,
    Icons.manage_accounts_outlined, Icons.notifications_outlined, Icons.email_outlined,
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
      const _ElectionConfigPage(),
      const _AdminUsersPage(),
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
      drawer: NavigationDrawer(
        selectedIndex: _navIdx,
        onDestinationSelected: (i) { setState(() => _navIdx = i); Navigator.pop(context); },
        children: [
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('VoteNG 2027', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: AppColors.green)),
              Text('Admin Control Panel', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            ]),
          ),
          const SizedBox(height: 8),
          const Divider(),
          ...List.generate(_titles.length, (i) => NavigationDrawerDestination(
            icon: Icon(_icons[i]),
            label: Text(_titles[i]),
          )),
        ],
      ),
      body: pages[_navIdx],
    );
  }
}

// ── Dashboard Overview
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

// ── Candidates Management
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
                label: const Text('Add Candidate'),
                style: ElevatedButton.styleFrom(minimumSize: const Size(0, 40)),
                onPressed: () => _showAddDialog(context, ref),
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
                  subtitle: Text('${kElectionTypeLabels[c['election_type']] ?? c['election_type']} • ${c['party_abbr'] ?? ''}'),
                  trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                    IconButton(icon: const Icon(Icons.edit_outlined, color: AppColors.textSecondary), onPressed: () {}),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: AppColors.pdpRed),
                      onPressed: () async {
                        final api = ref.read(apiServiceProvider);
                        await api.deleteCandidate(c['id']);
                        ref.invalidate(adminCandidatesProvider);
                      },
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

  void _showAddDialog(BuildContext context, WidgetRef ref) {
    showDialog(context: context, builder: (_) => const _AddCandidateDialog());
  }
}

class _AddCandidateDialog extends ConsumerStatefulWidget {
  const _AddCandidateDialog();

  @override
  ConsumerState<_AddCandidateDialog> createState() => _AddCandidateDialogState();
}

class _AddCandidateDialogState extends ConsumerState<_AddCandidateDialog> {
  final _nameCtrl = TextEditingController();
  String _type = 'presidential';
  int _partyId = 1;
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surfaceElevated,
      title: const Text('Add Candidate'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Full Name')),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _type,
          dropdownColor: AppColors.surfaceElevated,
          decoration: const InputDecoration(labelText: 'Election Type'),
          items: kElectionTypes.map((t) => DropdownMenuItem(value: t, child: Text(kElectionTypeLabels[t] ?? t))).toList(),
          onChanged: (v) => setState(() => _type = v!),
        ),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _loading ? null : () async {
            setState(() => _loading = true);
            final api = ref.read(apiServiceProvider);
            await api.addCandidate({'full_name': _nameCtrl.text, 'party_id': _partyId, 'election_type': _type});
            ref.invalidate(adminCandidatesProvider);
            if (context.mounted) Navigator.pop(context);
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}

// ── Election Config
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

// ── Users
class _AdminUsersPage extends ConsumerWidget {
  const _AdminUsersPage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder(
      future: ref.read(apiServiceProvider).getAdminUsers(),
      builder: (ctx, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final users = snap.data!['users'] as List<dynamic>? ?? [];
        return ListView.builder(
          itemCount: users.length,
          itemBuilder: (ctx, i) {
            final u = users[i];
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.green.withOpacity(0.1),
                child: Text(u['full_name'][0], style: const TextStyle(color: AppColors.green)),
              ),
              title: Text(u['full_name']),
              subtitle: Text('${u['state']} • ${u['phone']}'),
              trailing: u['is_flagged'] == 1
                  ? const Icon(Icons.flag_rounded, color: AppColors.pdpRed)
                  : null,
            );
          },
        );
      },
    );
  }
}

// ── Notifications
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
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.gold.withOpacity(0.07),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.gold.withOpacity(0.2)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline, color: AppColors.gold, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'For Gmail: enable 2FA then generate an App Password at myaccount.google.com/apppasswords and use it here.\n\nSettings are saved to the server environment and take effect on next API startup.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.gold, fontSize: 12),
                  ),
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
      setState(() { _statusMsg = 'SMTP settings saved. Restart the API for changes to take effect.'; _statusOk = true; });
    } catch (e) {
      setState(() { _statusMsg = 'Failed to save: $e'; _statusOk = false; });
    } finally {
      setState(() => _saving = false);
    }
  }
}
