import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'admin_api.dart';
import 'admin_widgets.dart';

class StudentsScreen extends ConsumerWidget {
  const StudentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final students = ref.watch(studentsProvider);
    final batches = ref.watch(batchesProvider);
    final filter = ref.watch(studentFilterProvider);
    final batchList = batches.valueOrNull ?? const <Batch>[];
    final batchNames = {for (final b in batchList) b.id: b.name};

    return Scaffold(
      appBar: AppBar(title: const Text('Students')),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add),
        label: const Text('New student'),
        onPressed: () {
          if (batchList.isEmpty) {
            snack(context, 'Create a batch first.');
            return;
          }
          Navigator.push(context,
              MaterialPageRoute(builder: (_) => const StudentFormScreen()));
        },
      ),
      body: Column(
        children: [
          if (batchList.isNotEmpty)
            SizedBox(
              height: 52,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                children: [
                  _FilterChip(
                    label: 'All',
                    selected: filter == null,
                    onTap: () =>
                        ref.read(studentFilterProvider.notifier).state = null,
                  ),
                  for (final b in batchList)
                    _FilterChip(
                      label: b.name,
                      selected: filter == b.id,
                      onTap: () => ref
                          .read(studentFilterProvider.notifier)
                          .state = b.id,
                    ),
                ],
              ),
            ),
          Expanded(
            child: students.when(
              loading: () => const CenterLoader(),
              error: (e, _) => ErrorBox(
                  error: e, onRetry: () => ref.invalidate(studentsProvider)),
              data: (list) => RefreshIndicator(
                color: Colors.black,
                backgroundColor: Colors.white,
                onRefresh: () async {
                  ref.invalidate(batchesProvider);
                  ref.invalidate(studentsProvider);
                  await ref.read(studentsProvider.future);
                },
                child: list.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: const [
                          SizedBox(height: 120),
                          Center(
                            child: Text('No students yet.',
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
                          final s = list[i];
                          final bn = s.batchIds
                              .map((id) => batchNames[id] ?? '...')
                              .join(', ');
                          return ListTile(
                            leading: AdminAvatar(s.name),
                            title: Text(s.name),
                            subtitle: Text(
                              '${s.username}${bn.isEmpty ? '' : '  ·  $bn'}'
                              '${s.active ? '' : '  ·  Disabled'}',
                              style: const TextStyle(color: kMuted),
                            ),
                            onTap: () => _openActions(context, ref, s),
                          );
                        },
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openActions(BuildContext context, WidgetRef ref, Student s) {
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
                child: Text(s.name, style: const TextStyle(fontSize: 18)),
              ),
            ),
            SheetAction(Icons.edit_outlined, 'Edit name / batches', () {
              Navigator.pop(sheet);
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => StudentFormScreen(student: s)));
            }),
            SheetAction(Icons.lock_reset, 'Reset password', () {
              Navigator.pop(sheet);
              _reset(context, ref, s);
            }),
            SheetAction(
                s.active ? Icons.block : Icons.check_circle_outline,
                s.active ? 'Disable student' : 'Enable student', () {
              Navigator.pop(sheet);
              _toggle(context, ref, s);
            }),
            SheetAction(Icons.delete_outline, 'Delete student', () {
              Navigator.pop(sheet);
              _delete(context, ref, s);
            }),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _reset(BuildContext context, WidgetRef ref, Student s) async {
    final ok = await confirmDialog(context,
        title: 'Reset password',
        message:
            'A new temporary password will be created for ${s.name}. They will be signed out everywhere.',
        confirmLabel: 'Reset');
    if (!ok || !context.mounted) return;
    try {
      final c = await ref.read(adminApiProvider).resetPassword(s.userId);
      if (!context.mounted) return;
      await showCredentialsDialog(context,
          title: 'New password', creds: c);
    } catch (e) {
      if (context.mounted) snack(context, errText(e));
    }
  }

  Future<void> _toggle(BuildContext context, WidgetRef ref, Student s) async {
    try {
      await ref
          .read(adminApiProvider)
          .updateStudent(s.userId, status: s.active ? 'disabled' : 'active');
      ref.invalidate(studentsProvider);
      if (context.mounted) {
        snack(context, s.active ? 'Student disabled.' : 'Student enabled.');
      }
    } catch (e) {
      if (context.mounted) snack(context, errText(e));
    }
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, Student s) async {
    final ok = await confirmDialog(context,
        title: 'Delete student',
        message:
            'Delete ${s.name}? The login is removed. Fee records are kept. This cannot be undone.',
        confirmLabel: 'Delete');
    if (!ok || !context.mounted) return;
    try {
      await ref.read(adminApiProvider).deleteStudent(s.userId);
      ref.invalidate(studentsProvider);
      if (context.mounted) snack(context, 'Student deleted.');
    } catch (e) {
      if (context.mounted) snack(context, errText(e));
    }
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip(
      {required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(right: 8),
        child: ChoiceChip(
          label: Text(label),
          selected: selected,
          showCheckmark: false,
          onSelected: (_) => onTap(),
          selectedColor: Colors.white,
          backgroundColor: kSurface,
          side: const BorderSide(color: kLine),
          labelStyle: TextStyle(
              color: selected ? Colors.black : Colors.white, fontSize: 13),
        ),
      );
}

/// Create (student == null) or edit a student.
class StudentFormScreen extends ConsumerStatefulWidget {
  const StudentFormScreen({super.key, this.student});
  final Student? student;

  @override
  ConsumerState<StudentFormScreen> createState() => _StudentFormState();
}

class _StudentFormState extends ConsumerState<StudentFormScreen> {
  late final TextEditingController _name;
  final _hint = TextEditingController();
  late final Set<String> _selected;
  bool _saving = false;
  String? _error;

  bool get _editing => widget.student != null;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.student?.name ?? '');
    _selected = {...?widget.student?.batchIds};
  }

  @override
  void dispose() {
    _name.dispose();
    _hint.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Enter the student name.');
      return;
    }
    if (_selected.isEmpty) {
      setState(() => _error = 'Select at least one batch.');
      return;
    }
    if (_selected.length > 10) {
      setState(() => _error = 'A student can be in at most 10 batches.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final api = ref.read(adminApiProvider);
    try {
      if (_editing) {
        await api.updateStudent(widget.student!.userId,
            name: name, batchIds: _selected.toList());
        ref.invalidate(studentsProvider);
        if (!mounted) return;
        Navigator.pop(context);
      } else {
        final c = await api.createStudent(
          name: name,
          batchIds: _selected.toList(),
          usernameHint: _hint.text.trim(),
        );
        ref.invalidate(studentsProvider);
        if (!mounted) return;
        await showCredentialsDialog(context,
            title: 'Student created', creds: c);
        if (!mounted) return;
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = errText(e);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final batches = ref.watch(batchesProvider);
    return Scaffold(
      appBar: AppBar(title: Text(_editing ? 'Edit student' : 'New student')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _name,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Name'),
          ),
          if (!_editing) ...[
            const SizedBox(height: 14),
            TextField(
              controller: _hint,
              autocorrect: false,
              decoration: const InputDecoration(
                labelText: 'Username hint (optional)',
                helperText:
                    'One English word. Use it when the name is in Bengali.',
                helperStyle: TextStyle(color: kMuted),
              ),
            ),
          ],
          const SizedBox(height: 22),
          const Text('Batches', style: TextStyle(color: kMuted)),
          const SizedBox(height: 6),
          batches.when(
            loading: () => const Padding(
                padding: EdgeInsets.all(24), child: CenterLoader()),
            error: (e, _) => ErrorBox(
                error: e, onRetry: () => ref.invalidate(batchesProvider)),
            data: (list) => Column(
              children: [
                for (final b in list)
                  CheckboxListTile(
                    value: _selected.contains(b.id),
                    onChanged: (v) => setState(() {
                      if (v == true) {
                        _selected.add(b.id);
                      } else {
                        _selected.remove(b.id);
                      }
                    }),
                    title: Text(b.name),
                    subtitle: b.active
                        ? null
                        : const Text('Inactive',
                            style: TextStyle(color: kMuted)),
                    activeColor: Colors.white,
                    checkColor: Colors.black,
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.trailing,
                  ),
              ],
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: Color(0xFFBDBDBD))),
          ],
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.black),
                  )
                : Text(_editing ? 'Save' : 'Create student'),
          ),
        ],
      ),
    );
  }
}
