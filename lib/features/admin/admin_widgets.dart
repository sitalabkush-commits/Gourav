import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/network/api_error.dart';
import 'admin_api.dart';

const kMuted = Color(0xFF9A9A9A);
const kLine = Color(0xFF2E2E2E);
const kSurface = Color(0xFF111111);

String errText(Object e) =>
    e is ApiException ? '${e.message}' : 'Something went wrong. Try again.';

void snack(BuildContext context, String text) {
  final m = ScaffoldMessenger.of(context);
  m.hideCurrentSnackBar();
  m.showSnackBar(SnackBar(content: Text(text)));
}

class AdminAvatar extends StatelessWidget {
  const AdminAvatar(this.name, {super.key, this.radius = 20});
  final String name;
  final double radius;

  String get _initials {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    String first(String s) => String.fromCharCode(s.runes.first);
    final a = first(parts.first);
    return (parts.length > 1 ? a + first(parts[1]) : a).toUpperCase();
  }

  @override
  Widget build(BuildContext context) => CircleAvatar(
        radius: radius,
        backgroundColor: const Color(0xFF2A2A2A),
        foregroundColor: Colors.white,
        child: Text(_initials, style: TextStyle(fontSize: radius * 0.7)),
      );
}

class CenterLoader extends StatelessWidget {
  const CenterLoader({super.key});
  @override
  Widget build(BuildContext context) => const Center(
        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
      );
}

class ErrorBox extends StatelessWidget {
  const ErrorBox({super.key, required this.error, required this.onRetry});
  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(errText(error),
                textAlign: TextAlign.center,
                style: const TextStyle(color: kMuted)),
            const SizedBox(height: 16),
            SizedBox(
              width: 160,
              child: OutlinedButton(
                  onPressed: onRetry, child: const Text('Retry')),
            ),
          ]),
        ),
      );
}

class SheetAction extends StatelessWidget {
  const SheetAction(this.icon, this.label, this.onTap, {super.key});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
        leading: Icon(icon, color: Colors.white),
        title: Text(label),
        onTap: onTap,
      );
}

Future<bool> confirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Confirm',
}) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(message, style: const TextStyle(color: kMuted)),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel')),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size(88, 44)),
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return r ?? false;
}

/// Shows username + temporary password. The password is never shown again.
Future<void> showCredentialsDialog(
  BuildContext context, {
  required String title,
  required Credentials creds,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => PopScope(
      canPop: false,
      child: AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Username', style: TextStyle(color: kMuted)),
              SelectableText(creds.username,
                  style: const TextStyle(fontSize: 18)),
              const SizedBox(height: 14),
              const Text('Temporary password',
                  style: TextStyle(color: kMuted)),
              SelectableText(creds.tempPassword,
                  style: const TextStyle(fontSize: 18)),
              const SizedBox(height: 16),
              const Text(
                'This password is shown only once and cannot be seen again. '
                'Copy it now and give it to the student. They must choose a '
                'new password at first login.',
                style: TextStyle(color: kMuted, fontSize: 13),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(
                  text:
                      'Username: ${creds.username}\nPassword: ${creds.tempPassword}'));
              if (ctx.mounted) snack(ctx, 'Copied');
            },
            child: const Text('Copy both'),
          ),
          TextButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: creds.tempPassword));
              if (ctx.mounted) snack(ctx, 'Password copied');
            },
            child: const Text('Copy password'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(80, 44)),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Done'),
          ),
        ],
      ),
    ),
  );
}
