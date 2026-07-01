import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user_model.dart';
import '../models/user_role.dart';
import 'api_client.dart';

class AuthRepository {
  AuthRepository(this._api);

  final ApiClient _api;

  /// Restores the session from a stored token, or null when signed out.
  Future<UserModel?> currentUser() async {
    final token = await _api.readToken();
    if (token == null) return null;
    try {
      final res = await _api.dio.get<Map<String, dynamic>>('/auth/me');
      return _userFromJson(res.data!);
    } on DioException {
      await _api.clearToken();
      return null;
    }
  }

  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    final res = await _api.dio.post<Map<String, dynamic>>(
      '/auth/login',
      data: {'email': email.trim(), 'password': password},
    );
    return _handleAuthResponse(res.data!);
  }

  Future<void> signOut() => _api.clearToken();

  Future<UserModel> _handleAuthResponse(Map<String, dynamic> data) async {
    await _api.setToken(data['access_token'] as String);
    return _userFromJson(data['user'] as Map<String, dynamic>);
  }

  UserModel _userFromJson(Map<String, dynamic> json) {
    final roleName = json['role'] as String?;
    final role = UserRole.values.firstWhere(
      (value) => value.name == roleName,
      orElse: () => UserRole.driver,
    );
    return UserModel(
      id: json['id'] as String,
      fullName: (json['full_name'] as String?) ?? 'Transit user',
      email: json['email'] as String?,
      role: role,
      assignedBus: json['assigned_bus'] as String?,
      assignedRoute: json['assigned_route'] as String?,
    );
  }
}

class AuthFailure implements Exception {
  const AuthFailure(this.message);
  final String message;
}

class AuthNotifier extends AsyncNotifier<UserModel?> {
  AuthRepository get _repository => ref.read(authRepositoryProvider);

  @override
  Future<UserModel?> build() async {
    return _repository.currentUser();
  }

  Future<String?> login(String email, String password) async {
    state = const AsyncLoading();
    try {
      final user = await _repository.signIn(email: email, password: password);
      state = AsyncData(user);
      return null;
    } on AuthFailure catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      return error.message;
    } on DioException catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      return _mapDioError(error);
    } on Object catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      return 'Unable to sign in. Please check your connection and try again.';
    }
  }

  Future<void> logout() async {
    await _repository.signOut();
    state = const AsyncData(null);
  }

  String _mapDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.connectionError:
      case DioExceptionType.receiveTimeout:
        return 'Cannot reach the server. Make sure the backend is running.';
      default:
        final detail = error.response?.data;
        if (detail is Map && detail['detail'] is String) {
          return detail['detail'] as String;
        }
        return 'Unable to sign in. Please try again.';
    }
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(apiClientProvider));
});

final authProvider = AsyncNotifierProvider<AuthNotifier, UserModel?>(
  AuthNotifier.new,
);
