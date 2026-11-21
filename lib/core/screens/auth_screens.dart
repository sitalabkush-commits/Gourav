import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/auth_state.dart';
import '../widgets/app_widgets.dart';

class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(authProvider);
    return Scaffold(
      body: s.status == AuthStatus.loadFailed
          ? ErrorView(
              message: s.error ?? 'Could not load your account.',
              onRetry: () => ref.read(authProvider.notifier).restore(),
            )
          : const AppLoader(),
    );
  }
}

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _user = TextEditingController();
  final _pass = TextEditingController();
  bool _hide = true;

  @override
  void dispose() {
    _user.dispose();
    _pass.dispose();
    super.dispose();
  }

  void _submit() {
    if (_user.text.trim().isEmpty || _pass.text.isEmpty) return;
    ref.read(authProvider.notifier).login(_user.text, _pass.text);
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(authProvider);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Text('Gourab Sir', textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 4),
              const Text('Coaching Center',
                  textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF9A9A9A))),
              const SizedBox(height: 36),
              TextField(
                controller: _user,
                autocorrect: false,
                enableSuggestions: false,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(labelText: 'Username'),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _pass,
                obscureText: _hide,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
                decoration: InputDecoration(
                  labelText: 'Password',
                  suffixIcon: IconButton(
                    icon: Icon(_hide ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                    onPressed: () => setState(() => _hide = !_hide),
                  ),
                ),
              ),
              if (s.error != null) ...[
                const SizedBox(height: 12),
                Text(s.error!, style: const TextStyle(color: Color(0xFFBDBDBD))),
              ],
              const SizedBox(height: 22),
              FilledButton(
                onPressed: s.busy ? null : _submit,
                child: s.busy
                    ? const SizedBox(
                        width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                    : const Text('Log in'),
              ),
              const SizedBox(height: 18),
              const Text(
                'Lost your password? Ask Gourab to reset it.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF9A9A9A), fontSize: 12),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

class NewPasswordScreen extends ConsumerStatefulWidget {
  const NewPasswordScreen({super.key});
  @override
  ConsumerState<NewPasswordScreen> createState() => _NewPasswordScreenState();
}

class _NewPasswordScreenState extends ConsumerState<NewPasswordScreen> {
  final _p1 = TextEditingController();
  final _p2 = TextEditingController();
  String? _local;

  @override
  void dispose() {
    _p1.dispose();
    _p2.dispose();
    super.dispose();
  }

  String? _validate(String p) {
    if (p.length < 8) return 'Use at least 8 characters.';
    if (!RegExp(r'[A-Z]').hasMatch(p)) return 'Add an upper case letter.';
    if (!RegExp(r'[a-z]').hasMatch(p)) return 'Add a lower case letter.';
    if (!RegExp(r'\d').hasMatch(p)) return 'Add a digit.';
    return null;
  }

  void _submit() {
    final err = _validate(_p1.text) ?? (_p1.text != _p2.text ? 'Passwords do not match.' : null);
    setState(() => _local = err);
    if (err == null) ref.read(authProvider.notifier).setNewPassword(_p1.text);
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(authProvider);
    final error = _local ?? s.error;
    return Scaffold(
      appBar: AppBar(title: const Text('Choose a new password')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const Text('Set your own password to continue. Minimum 8 characters with upper case, lower case and a digit.',
                style: TextStyle(color: Color(0xFF9A9A9A))),
            const SizedBox(height: 22),
            TextField(controller: _p1, obscureText: true, decoration: const InputDecoration(labelText: 'New password')),
            const SizedBox(height: 14),
            TextField(
                controller: _p2, obscureText: true, decoration: const InputDecoration(labelText: 'Confirm password')),
            if (error != null) ...[
              const SizedBox(height: 12),
              Text(error, style: const TextStyle(color: Color(0xFFBDBDBD))),
            ],
            const SizedBox(height: 22),
            FilledButton(onPressed: s.busy ? null : _submit, child: const Text('Save and continue')),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => ref.read(authProvider.notifier).signOut(unregister: false),
              child: const Text('Cancel'),
            ),
          ]),
        ),
      ),
    );
  }
}

class UpdateRequiredScreen extends StatelessWidget {
  const UpdateRequiredScreen({super.key});
  @override
  Widget build(BuildContext context) => const Scaffold(
        body: ErrorView(message: 'Update required.\nPlease install the latest version of the app to continue.'),
      );
}

class InactiveScreen extends ConsumerWidget {
  const InactiveScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.lock_outline, size: 36, color: Color(0xFF9A9A9A)),
              const SizedBox(height: 12),
              const Text('Your account is not active.\nPlease contact Gourab.', textAlign: TextAlign.center),
              const SizedBox(height: 18),
              OutlinedButton(
                onPressed: () => ref.read(authProvider.notifier).signOut(unregister: false),
                child: const Text('Back to login'),
              ),
            ]),
          ),
        ),
      );
}
