import 'user_role.dart';

class UserModel {
  const UserModel({
    required this.id,
    required this.fullName,
    required this.role,
    this.email,
    this.assignedBus,
    this.assignedRoute,
  });

  final String id;
  final String fullName;
  final UserRole role;
  final String? email;
  final String? assignedBus;
  final String? assignedRoute;

  String get firstName => fullName.split(' ').first;
  String get lastName => fullName.split(' ').skip(1).join(' ');

  UserModel copyWith({
    String? fullName,
    UserRole? role,
    String? email,
    String? assignedBus,
    String? assignedRoute,
  }) {
    return UserModel(
      id: id,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      email: email ?? this.email,
      assignedBus: assignedBus ?? this.assignedBus,
      assignedRoute: assignedRoute ?? this.assignedRoute,
    );
  }
}
