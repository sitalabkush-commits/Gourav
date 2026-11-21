import 'package:amazon_cognito_identity_dart_2/cognito.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config.dart';

class SecureCognitoStorage extends CognitoStorage {
  SecureCognitoStorage(this._s);
  final FlutterSecureStorage _s;

  @override
  Future getItem(String key) => _s.read(key: key);

  @override
  Future setItem(String key, value) async {
    await _s.write(key: key, value: value?.toString());
    return value;
  }

  @override
  Future removeItem(String key) async {
    final v = await _s.read(key: key);
    await _s.delete(key: key);
    return v;
  }

  @override
  Future<void> clear() => _s.deleteAll();
}

enum LoginResult { ok, newPasswordRequired }

class AuthException implements Exception {
  AuthException(this.message);
  final String message;
  @override
  String toString() => message;
}

class AuthService {
  AuthService() {
    _storage = SecureCognitoStorage(const FlutterSecureStorage());
    _pool = CognitoUserPool(AppConfig.userPoolId, AppConfig.clientId, storage: _storage);
  }

  late final SecureCognitoStorage _storage;
  late final CognitoUserPool _pool;
  CognitoUser? _user;

  /// Restore a saved session (refreshes automatically if the access token expired).
  Future<bool> restore() async {
    try {
      final u = await _pool.getCurrentUser();
      if (u == null) return false;
      final s = await u.getSession();
      if (s == null || !s.isValid()) return false;
      _user = u;
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<LoginResult> login(String username, String password) async {
    final name = username.trim();
    final user = CognitoUser(name, _pool, storage: _storage);
    final details = AuthenticationDetails(username: name, password: password);
    try {
      await user.authenticateUser(details); // SRP
      _user = user;
      return LoginResult.ok;
    } on CognitoUserNewPasswordRequiredException {
      _user = user; // first login after admin-create-user or reset
      return LoginResult.newPasswordRequired;
    } on CognitoClientException catch (e) {
      throw AuthException(_message(e));
    } catch (_) {
      throw AuthException('Could not connect. Check your internet and try again.');
    }
  }

  Future<void> completeNewPassword(String newPassword) async {
    final u = _user;
    if (u == null) throw AuthException('Session expired. Please log in again.');
    try {
      await u.sendNewPasswordRequiredAnswer(newPassword);
    } on CognitoClientException catch (e) {
      throw AuthException(_message(e));
    } catch (_) {
      throw AuthException('Could not connect. Check your internet and try again.');
    }
  }

  /// Access token is what the API expects as `Authorization: Bearer`.
  Future<String?> accessToken() async {
    try {
      final s = await _user?.getSession();
      return s?.getAccessToken().getJwtToken();
    } catch (_) {
      return null;
    }
  }

  /// Force a refresh (used after a 401). Returns null if the refresh token is no longer valid.
  Future<String?> refresh() async {
    try {
      final u = _user;
      final s = await u?.getSession();
      final rt = s?.refreshToken;
      if (u == null || rt == null) return null;
      final ns = await u.refreshSession(rt);
      return ns?.getAccessToken().getJwtToken();
    } catch (_) {
      return null;
    }
  }

  Future<void> signOut() async {
    try {
      await _user?.signOut();
    } catch (_) {}
    await _storage.clear();
    _user = null;
  }

  String _message(CognitoClientException e) {
    switch (e.code) {
      case 'NotAuthorizedException':
      case 'UserNotFoundException':
        return 'Wrong username or password.';
      case 'InvalidPasswordException':
      case 'InvalidParameterException':
        return 'Password needs 8+ characters with upper case, lower case and a digit.';
      case 'TooManyRequestsException':
      case 'LimitExceededException':
        return 'Too many attempts. Wait a few minutes and try again.';
      default:
        return e.message ?? 'Login failed. Try again.';
    }
  }
}
