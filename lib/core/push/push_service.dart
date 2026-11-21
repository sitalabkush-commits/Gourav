import 'dart:async';
import 'package:dio/dio.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../network/api_client.dart';

/// Best effort: if Firebase is not configured yet, everything here fails silently.
class PushService {
  PushService(this._dio);
  final Dio _dio;
  String? _token;
  bool _listening = false;

  Future<void> register() async {
    try {
      await Firebase.initializeApp();
      final fm = FirebaseMessaging.instance;
      await fm.requestPermission(); // Android 13+ POST_NOTIFICATIONS
      _token = await fm.getToken();
      await _send(_token);
      if (!_listening) {
        _listening = true;
        fm.onTokenRefresh.listen((t) {
          _token = t;
          unawaited(_send(t));
        });
      }
    } catch (_) {}
  }

  Future<void> _send(String? t) async {
    if (t == null) return;
    try {
      await _dio.post('/me/device', data: {'token': t, 'platform': 'android'});
    } catch (_) {}
  }

  Future<void> unregister() async {
    final t = _token;
    if (t == null) return;
    try {
      await _dio
          .post('/me/device/unregister', data: {'token': t})
          .timeout(const Duration(seconds: 3));
    } catch (_) {}
  }
}

final pushServiceProvider = Provider<PushService>((ref) => PushService(ref.read(mainDioProvider)));
