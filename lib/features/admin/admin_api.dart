import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_error.dart';

List<String> _strings(dynamic v) =>
    ((v as List?) ?? const []).map((e) => e.toString()).toList();

class Batch {
  const Batch({
    required this.id,
    required this.name,
    this.description,
    required this.active,
  });
  final String id;
  final String name;
  final String? description;
  final bool active;

  factory Batch.fromJson(Map<String, dynamic> j) => Batch(
        id: j['batchId'] as String,
        name: (j['name'] ?? '') as String,
        description: j['description'] as String?,
        active: (j['active'] ?? true) as bool,
      );
}

class Student {
  const Student({
    required this.userId,
    required this.username,
    required this.name,
    required this.batchIds,
    required this.status,
  });
  final String userId;
  final String username;
  final String name;
  final List<String> batchIds;
  final String status;

  bool get active => status != 'disabled';

  factory Student.fromJson(Map<String, dynamic> j) => Student(
        userId: j['userId'] as String,
        username: (j['username'] ?? '') as String,
        name: (j['name'] ?? '') as String,
        batchIds: _strings(j['batchIds']),
        status: (j['status'] ?? 'active') as String,
      );
}

class Member {
  const Member({required this.userId, required this.name});
  final String userId;
  final String name;

  factory Member.fromJson(Map<String, dynamic> j) => Member(
        userId: j['userId'] as String,
        name: (j['name'] ?? '') as String,
      );
}

class Credentials {
  const Credentials({required this.username, required this.tempPassword});
  final String username;
  final String tempPassword;

  factory Credentials.fromJson(Map<String, dynamic> j) => Credentials(
        username: j['username'] as String,
        tempPassword: j['tempPassword'] as String,
      );
}

class AdminApi {
  AdminApi(this._dio);
  final Dio _dio;

  Future<T> _run<T>(Future<T> Function() f) async {
    try {
      return await f();
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  Map<String, dynamic> _map(dynamic d) => Map<String, dynamic>.from(d as Map);

  List<Map<String, dynamic>> _items(dynamic d) =>
      ((_map(d)['items'] as List?) ?? const []).map(_map).toList();

  // ---- Batches ----
  Future<List<Batch>> batches() => _run(() async {
        final r = await _dio.get('/batches');
        return _items(r.data).map(Batch.fromJson).toList();
      });

  Future<void> createBatch({required String name, String? description}) =>
      _run<void>(() async {
        await _dio.post('/admin/batches', data: {
          'name': name,
          if (description != null && description.isNotEmpty)
            'description': description,
        });
      });

  Future<void> updateBatch(String id,
          {String? name, String? description, bool? active}) =>
      _run<void>(() async {
        await _dio.patch('/admin/batches/$id', data: {
          if (name != null) 'name': name,
          if (description != null) 'description': description,
          if (active != null) 'active': active,
        });
      });

  Future<void> deleteBatch(String id) => _run<void>(() async {
        await _dio.delete('/admin/batches/$id');
      });

  Future<List<Member>> members(String batchId) => _run(() async {
        final r = await _dio.get('/batches/$batchId/members');
        final list = (_map(r.data)['members'] as List?) ?? const [];
        return list.map((e) => Member.fromJson(_map(e))).toList();
      });

  // ---- Students ----
  Future<List<Student>> students({String? batchId}) => _run(() async {
        final r = await _dio.get('/admin/students',
            queryParameters: {if (batchId != null) 'batchId': batchId});
        return _items(r.data).map(Student.fromJson).toList();
      });

  Future<Credentials> createStudent({
    required String name,
    required List<String> batchIds,
    String? usernameHint,
  }) =>
      _run(() async {
        final r = await _dio.post('/admin/students', data: {
          'name': name,
          'batchIds': batchIds,
          if (usernameHint != null && usernameHint.isNotEmpty)
            'usernameHint': usernameHint,
        });
        return Credentials.fromJson(_map(r.data));
      });

  Future<void> updateStudent(String id,
          {String? name, List<String>? batchIds, String? status}) =>
      _run<void>(() async {
        await _dio.patch('/admin/students/$id', data: {
          if (name != null) 'name': name,
          if (batchIds != null) 'batchIds': batchIds,
          if (status != null) 'status': status,
        });
      });

  Future<Credentials> resetPassword(String id) => _run(() async {
        final r = await _dio.post('/admin/students/$id/reset-password');
        return Credentials.fromJson(_map(r.data));
      });

  Future<void> deleteStudent(String id) => _run<void>(() async {
        await _dio.delete('/admin/students/$id');
      });
}

final adminApiProvider =
    Provider<AdminApi>((ref) => AdminApi(ref.watch(mainDioProvider)));

final batchesProvider = FutureProvider.autoDispose<List<Batch>>(
    (ref) => ref.watch(adminApiProvider).batches());

final studentFilterProvider = StateProvider.autoDispose<String?>((_) => null);

final studentsProvider = FutureProvider.autoDispose<List<Student>>((ref) {
  final filter = ref.watch(studentFilterProvider);
  return ref.watch(adminApiProvider).students(batchId: filter);
});

final membersProvider = FutureProvider.autoDispose.family<List<Member>, String>(
    (ref, batchId) => ref.watch(adminApiProvider).members(batchId));
