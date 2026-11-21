import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/auth/auth_state.dart';
import 'core/router/app_router.dart';
import 'core/theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(ProviderScope(
    overrides: [
      // Claude D replaces this with features/admin/admin_home.dart
      adminHomeProvider.overrideWithValue(const _Placeholder('Admin')),
      // Claude E replaces this with the student UI
      studentHomeProvider.overrideWithValue(const _Placeholder('Student')),
    ],
    child: const GourabApp(),
  ));
}

class GourabApp extends ConsumerWidget {
  const GourabApp({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => MaterialApp.router(
        title: 'Gourab Sir',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        themeMode: ThemeMode.dark,
        routerConfig: ref.watch(routerProvider),
      );
}

class _Placeholder extends ConsumerWidget {
  const _Placeholder(this.label);
  final String label;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(authProvider);
    return Scaffold(
      appBar: AppBar(title: Text('$label home')),
      body: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('Logged in as ${s.name ?? s.username ?? '-'}'),
        const SizedBox(height: 16),
        SizedBox(
          width: 200,
          child: OutlinedButton(
            onPressed: () => ref.read(authProvider.notifier).signOut(),
            child: const Text('Log out'),
          ),
        ),
      ])),
    );
  }
}
