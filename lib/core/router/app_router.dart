import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../auth/auth_state.dart';
import '../auth/role.dart';
import '../screens/auth_screens.dart';

/// Overridden in main.dart so core/ never imports feature code.
final adminHomeProvider = Provider<Widget>((_) => throw UnimplementedError());
final studentHomeProvider = Provider<Widget>((_) => throw UnimplementedError());

/// The guard is UX only. The server checks the role on every route.
final routerProvider = Provider<GoRouter>((ref) {
  final tick = ValueNotifier<int>(0);
  ref.listen(authProvider, (_, __) => tick.value++);
  ref.onDispose(tick.dispose);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: tick,
    redirect: (context, state) {
      final s = ref.read(authProvider);
      final loc = state.matchedLocation;
      final String target = switch (s.status) {
        AuthStatus.loading || AuthStatus.loadFailed => '/splash',
        AuthStatus.signedOut => '/login',
        AuthStatus.newPasswordRequired => '/new-password',
        AuthStatus.updateRequired => '/update',
        AuthStatus.inactive => '/inactive',
        AuthStatus.ready => s.role == Role.admin ? '/admin' : '/student',
      };
      final ok = s.status == AuthStatus.ready ? loc.startsWith(target) : loc == target;
      return ok ? null : target;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/new-password', builder: (_, __) => const NewPasswordScreen()),
      GoRoute(path: '/update', builder: (_, __) => const UpdateRequiredScreen()),
      GoRoute(path: '/inactive', builder: (_, __) => const InactiveScreen()),
      // Admin/student shells own their sub-routes (add child routes here later).
      GoRoute(path: '/admin', builder: (_, __) => ref.read(adminHomeProvider)),
      GoRoute(path: '/student', builder: (_, __) => ref.read(studentHomeProvider)),
    ],
  );
});
