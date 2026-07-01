import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user_role.dart';
import 'api_client.dart';

/// A staff account as seen by the dispatcher management screen.
class StaffUser {
  const StaffUser({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    required this.isActive,
    this.assignedBus,
    this.assignedRoute,
  });

  final String id;
  final String email;
  final String fullName;
  final UserRole role;
  final bool isActive;
  final String? assignedBus;
  final String? assignedRoute;

  static StaffUser fromJson(Map<String, dynamic> json) {
    final roleName = json['role'] as String?;
    return StaffUser(
      id: json['id'] as String,
      email: (json['email'] as String?) ?? '',
      fullName: (json['full_name'] as String?) ?? '',
      role: UserRole.values.firstWhere(
        (value) => value.name == roleName,
        orElse: () => UserRole.driver,
      ),
      isActive: (json['is_active'] as bool?) ?? true,
      assignedBus: json['assigned_bus'] as String?,
      assignedRoute: json['assigned_route'] as String?,
    );
  }
}

class UserRepository {
  UserRepository(this._api);

  final ApiClient _api;

  Future<List<StaffUser>> fetchUsers() async {
    final res = await _api.dio.get<List<dynamic>>('/users');
    return (res.data ?? const [])
        .map((item) => StaffUser.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> createUser({
    required String email,
    required String password,
    required String fullName,
    required UserRole role,
    String? assignedBus,
    String? assignedRoute,
  }) async {
    await _api.dio.post<Map<String, dynamic>>(
      '/users',
      data: {
        'email': email.trim(),
        'password': password,
        'full_name': fullName.trim(),
        'role': role.name,
        'assigned_bus': assignedBus?.trim().isEmpty ?? true
            ? null
            : assignedBus!.trim(),
        'assigned_route': assignedRoute?.trim().isEmpty ?? true
            ? null
            : assignedRoute!.trim(),
      },
    );
  }

  Future<void> setActive(String userId, {required bool isActive}) async {
    await _api.dio.patch<Map<String, dynamic>>(
      '/users/$userId',
      data: {'is_active': isActive},
    );
  }

  Future<void> deleteUser(String userId) async {
    await _api.dio.delete<void>('/users/$userId');
  }
}

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository(ref.watch(apiClientProvider));
});

final staffProvider = FutureProvider<List<StaffUser>>((ref) async {
  return ref.watch(userRepositoryProvider).fetchUsers();
});
