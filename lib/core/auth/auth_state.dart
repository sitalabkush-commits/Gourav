import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../network/api_client.dart';
import '../network/api_error.dart';
import '../push/push_service.dart';
import '../utils/version.dart';
import 'auth_service.dart';
import 'role.dart';

enum AuthStatus { loading, loadFailed, signedOut, newPasswordRequired, ready, updateRequired, inactive }

class AuthState {
  const AuthState({
    required this.status,
    this.role,
    this.username,
    this.name,
    this.config = const {},
    this.error,
    this.busy = false,
  });
  final AuthStatus status;
  final Role? role;
  final String? username;
  final String? name;
  final Map<String, dynamic> config;
  final String? error;
  final bool busy; // a button is working; keeps the current screen in place

  AuthState copyWith({bool? busy, String? error}) => AuthState(
        status: status,
        role: role,
        username: username,
        name: name,
        config: config,
        error: error,
        busy: busy ?? this.busy,
      );
}

class AuthNotifier extends Notifier<AuthState> {
  AuthService get _svc => ref.read(authServiceProvider);

  @override
  AuthState build() {
    Future.microtask(restore);
    return const AuthState(status: AuthStatus.loading);
  }

  Future<void> restore() async {
    state = const AuthState(status: AuthStatus.loading);
    if (await _svc.restore()) {
      await _loadMe();
    } else {
      state = const AuthState(status: AuthStatus.signedOut);
    }
  }

  Future<void> login(String username, String password) async {
    state = state.copyWith(busy: true, error: null);
    try {
      final r = await _svc.login(username, password);
      if (r == LoginResult.newPasswordRequired) {
        state = const AuthState(status: AuthStatus.newPasswordRequired);
      } else {
        await _loadMe();
      }
    } on AuthException catch (e) {
      state = AuthState(status: AuthStatus.signedOut, error: e.message);
    }
  }

  Future<void> setNewPassword(String newPassword) async {
    state = state.copyWith(busy: true, error: null);
    try {
      await _svc.completeNewPassword(newPassword);
      await _loadMe();
    } on AuthException catch (e) {
      state = AuthState(status: AuthStatus.newPasswordRequired, error: e.message);
    }
  }

  /// GET /me decides the role (group `admin` or `student`) and carries config incl. minAppVersion.
  Future<void> _loadMe() async {
    try {
      final res = await ref.read(mainDioProvider).get('/me');
      final d = Map<String, dynamic>.from(res.data as Map);
      final role = switch (d['role']) {
        'admin' => Role.admin,
        'student' => Role.student,
        _ => null,
      };
      if (role == null) {
        await signOut(error: 'Unknown account type.', unregister: false);
        return;
      }
      final cfg = Map<String, dynamic>.from((d['config'] as Map?) ?? {});
      final info = await PackageInfo.fromPlatform();
      final minV = (cfg['minAppVersion'] ?? '1.0.0').toString();
      final base = AuthState(
        status: AuthStatus.ready,
        role: role,
        username: d['username']?.toString(),
        name: d['name']?.toString(),
        config: cfg,
      );
      if (isOlderVersion(info.version, minV)) {
        state = AuthState(status: AuthStatus.updateRequired, role: role, config: cfg);
        return;
      }
      state = base;
      unawaited(ref.read(pushServiceProvider).register());
    } on DioException catch (e) {
      final ex = ApiException.from(e);
      if (ex.isInactive) {
        state = const AuthState(status: AuthStatus.inactive);
      } else if (ex.status == 401) {
        await signOut(unregister: false);
      } else {
        state = AuthState(status: AuthStatus.loadFailed, error: ex.message);
      }
    }
  }

  Future<void> markInactive() async {
    await _svc.signOut();
    state = const AuthState(status: AuthStatus.inactive);
  }

  Future<void> signOut({String? error, bool unregister = true}) async {
    if (unregister) await ref.read(pushServiceProvider).unregister();
    await _svc.signOut();
    state = AuthState(status: AuthStatus.signedOut, error: error);
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
