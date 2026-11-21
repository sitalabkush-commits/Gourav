import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/auth_service.dart';
import '../auth/auth_state.dart';
import '../config.dart';

final authServiceProvider = Provider<AuthService>((_) => AuthService());

Dio _build(Ref ref, String baseUrl) {
  final auth = ref.read(authServiceProvider);
  final dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 30),
    headers: {'Content-Type': 'application/json'},
  ));

  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (o, h) async {
      final t = await auth.accessToken();
      if (t != null) o.headers['Authorization'] = 'Bearer $t';
      h.next(o);
    },
    onError: (e, h) async {
      final res = e.response;
      final req = e.requestOptions;
      final code = (res?.data is Map && (res!.data as Map)['error'] is Map)
          ? ((res.data as Map)['error'] as Map)['code']
          : null;

      if (res?.statusCode == 401) {
        if (req.extra['retried'] != true) {
          final t = await auth.refresh();
          if (t != null) {
            req.extra['retried'] = true;
            try {
              h.resolve(await dio.fetch(req));
            } on DioException catch (e2) {
              h.next(e2);
            }
            return;
          }
        }
        await ref.read(authProvider.notifier).signOut(unregister: false);
      } else if (res?.statusCode == 403 && code == 'inactive') {
        await ref.read(authProvider.notifier).markInactive();
      }
      h.next(e);
    },
  ));
  return dio;
}

/// Main stack (users, batches, content, fees, config, reports).
final mainDioProvider = Provider<Dio>((ref) => _build(ref, AppConfig.mainApi));

/// AI stack. Routes are not in the contract yet: do not use.
final aiDioProvider = Provider<Dio>((ref) => _build(ref, AppConfig.aiApi));

/// For S3 presigned POST/GET: no Authorization header, no JSON content type.
final plainDioProvider = Provider<Dio>((_) => Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(minutes: 5),
      sendTimeout: const Duration(minutes: 10),
    )));
