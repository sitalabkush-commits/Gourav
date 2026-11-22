import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/auth/auth_state.dart';
import 'admin_widgets.dart';
import 'batches_screen.dart';
import 'students_screen.dart';

class AdminHome extends ConsumerWidget {
  const AdminHome({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(authProvider);

    void open(Widget page) =>
        Navigator.push(context, MaterialPageRoute(builder: (_) => page));
    void soon() => snack(context, 'Coming in the next step.');

    final items = <(IconData, String, String, VoidCallback)>[
      (Icons.school_outlined, 'Students', 'Add, reset, disable',
          () => open(const StudentsScreen())),
      (Icons.groups_outlined, 'Batches', 'Create and manage batches',
          () => open(const BatchesScreen())),
      (Icons.currency_rupee, 'Fees', 'Dues and payments', soon),
      (Icons.campaign_outlined, 'Notices', 'Circulars and dashboard messages',
          soon),
      (Icons.folder_outlined, 'Content', 'Notes, tutorials, files', soon),
      (Icons.flag_outlined, 'Reports', 'Reported chat messages', soon),
      (Icons.tune, 'Settings', 'Limits and contact options', soon),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gourab Sir'),
        actions: [
          IconButton(
            tooltip: 'Log out',
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final ok = await confirmDialog(context,
                  title: 'Log out',
                  message: 'Log out of the admin account?',
                  confirmLabel: 'Log out');
              if (ok) ref.read(authProvider.notifier).signOut();
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: Text(
              'Logged in as ${s.name ?? s.username ?? '-'}',
              style: const TextStyle(color: kMuted),
            ),
          ),
          for (final it in items) ...[
            ListTile(
              leading: Icon(it.$1),
              title: Text(it.$2),
              subtitle:
                  Text(it.$3, style: const TextStyle(color: kMuted)),
              trailing: const Icon(Icons.chevron_right, color: kMuted),
              onTap: it.$4,
            ),
            const Divider(height: 1, color: kLine),
          ],
        ],
      ),
    );
  }
}
