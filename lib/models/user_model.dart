import 'user_role.dart';

class UserModel {
  const UserModel({
    required this.id,
    required this.fullName,
    required this.role,
    this.assignedBus,
    this.assignedRoute,
  });

  final String id;
  final String fullName;
  final UserRole role;

  final String? assignedBus;

  final String? assignedRoute;

  String get firstName => fullName.split(' ').first;
  String get lastName => fullName.split(' ').skip(1).join(' ');
}
