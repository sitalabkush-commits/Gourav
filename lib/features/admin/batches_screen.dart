import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'admin_api.dart';
import 'admin_widgets.dart';

class BatchesScreen extends ConsumerWidget {
  const BatchesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final batches = ref.watch(batchesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Batches')),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add),
        label: const Text('New batch'),
        onPressed: () => _create(context, ref),
      ),
      body: batches.when(
        loading: () => const CenterLoader(),
        error: (e, _) => ErrorBox(
            error: e, onRetry: () => ref.invalidate(batchesProvider)),
        data: (list) => RefreshIndicator(
          color: Colors.black,
          backgroundColor: Colors.white,
          onRefresh: () async {
            ref.invalidate(batchesProvider);
            await ref.read(batchesProvider.future);
          },
          child: list.isEmpty
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: const [
                    SizedBox(height: 120),
                    Center(
                      child: Text('No batches yet.',
                          style: TextStyle(color: kMuted)),
                    ),
                  ],
                )
              : ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 100),
                  itemCount: list.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, color: kLine),
                  itemBuilder: (_, i) {
                    final b = list[i];
                    final desc = (b.description ?? '').trim();
                    return ListTile(
                      leading: const Icon(Icons.groups_outlined),
                      title: Text(b.name),
                      subtitle: Text(
                        '${desc.isEmpty ? '' : desc}'
                        '${b.active ? '' : (desc.isEmpty ? 'Inactive' : '  ·  Inactive')}',
                        style: const TextStyle(color: kMuted),
                      ),
                      onTap: () => _openActions(context, ref, b),
                    );
                  },
                ),
        ),
      ),
    );
  }

  void _openActions(BuildContext context, WidgetRef ref, Batch b) {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheet) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(b.name, style: const TextStyle(fontSize: 18)),
              ),
            ),
            SheetAction(Icons.people_outline, 'View members', () {
              Navigator.pop(sheet);
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => MembersScreen(batch: b)));
            }),
            SheetAction(Icons.edit_outlined, 'Edit name / description', () {
              Navigator.pop(sheet);
              _edit(context, ref, b);
            }),
            SheetAction(
                b.active ? Icons.pause_circle_outline : Icons.play_circle_outline,
                b.active ? 'Mark inactive' : 'Mark active', () {
              Navigator.pop(sheet);
              _toggle(context, ref, b);
            }),
            SheetAction(Icons.delete_outline, 'Delete batch', () {
              Navigator.pop(sheet);
              _delete(context, ref, b);
            }),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _create(BuildContext context, WidgetRef ref) async {
    final r = await showDialog<(String, String)>(
        context: context, builder: (_) => const _BatchDialog());
    if (r == null || !context.mounted) return;
    try {
      await ref
          .read(adminApiProvider)
          .createBatch(name: r.$1, description: r.$2);
      ref.invalidate(batchesProvider);
      if (context.mounted) snack(context, 'Batch created.');
    } catch (e) {
      if (context.mounted) snack(context, errText(e));
    }
  }

  Future<void> _edit(BuildContext context, WidgetRef ref, Batch b) async {
    final r = await showDialog<(String, String)>(
        context: context, builder: (_) => _BatchDialog(batch: b));
    if (r == null || !context.mounted) return;
    try {
      await ref
          .read(adminApiProvider)
          .updateBatch(b.id, name: r.$1, description: r.$2);
      ref.invalidate(batchesProvider);
      if (context.mounted) snack(context, 'Batch updated.');
    } catch (e) {
      if (context.mounted) snack(context, errText(e));
    }
  }

  Future<void> _toggle(BuildContext context, WidgetRef ref, Batch b) async {
    try {
      await ref.read(adminApiProvider).updateBatch(b.id, active: !b.active);
      ref.invalidate(batchesProvider);
    } catch (e) {
      if (context.mounted) snack(context, errText(e));
    }
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, Batch b) async {
    final ok = await confirmDialog(context,
        title: 'Delete batch',
        message:
            'Delete "${b.name}"? A batch with students in it cannot be deleted.',
        confirmLabel: 'Delete');
    if (!ok || !context.mounted) return;
    try {
      await ref.read(adminApiProvider).deleteBatch(b.id);
      ref.invalidate(batchesProvider);
      if (context.mounted) snack(context, 'Batch deleted.');
    } catch (e) {
      if (context.mounted) snack(context, errText(e));
    }
  }
}

class _BatchDialog extends StatefulWidget {
  const _BatchDialog({this.batch});
  final Batch? batch;

  @override
  State<_BatchDialog> createState() => _BatchDialogState();
}

class _BatchDialogState extends State<_BatchDialog> {
  late final TextEditingController _name;
  late final TextEditingController _desc;
  String? _error;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.batch?.name ?? '');
    _desc = TextEditingController(text: widget.batch?.description ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _desc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text(widget.batch == null ? 'New batch' : 'Edit batch'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _name,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Batch name'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _desc,
                decoration: const InputDecoration(
                    labelText: 'Description (optional)'),
              ),
              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(_error!,
                    style: const TextStyle(color: Color(0xFFBDBDBD))),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(88, 44)),
            onPressed: () {
              final n = _name.text.trim();
              if (n.isEmpty) {
                setState(() => _error = 'Enter a batch name.');
                return;
              }
              Navigator.pop(context, (n, _desc.text.trim()));
            },
            child: const Text('Save'),
          ),
        ],
      );
}

class MembersScreen extends ConsumerWidget {
  const MembersScreen({super.key, required this.batch});
  final Batch batch;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final members = ref.watch(membersProvider(batch.id));
    return Scaffold(
      appBar: AppBar(title: Text(batch.name)),
      body: members.when(
        loading: () => const CenterLoader(),
        error: (e, _) => ErrorBox(
            error: e, onRetry: () => ref.invalidate(membersProvider(batch.id))),
        data: (list) => list.isEmpty
            ? const Center(
                child: Text('No members in this batch.',
                    style: TextStyle(color: kMuted)))
            : ListView.separated(
                itemCount: list.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, color: kLine),
                itemBuilder: (_, i) => ListTile(
                  leading: AdminAvatar(list[i].name),
                  title: Text(list[i].name),
                ),
              ),
      ),
    );
  }
}
