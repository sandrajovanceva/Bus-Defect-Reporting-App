import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user_model.dart';
import '../models/user_role.dart';

const _mockUsers = <String, UserModel>{
  'D-4827': UserModel(
    id: 'D-4827',
    fullName: 'Стефан Илиевски',
    role: UserRole.driver,
    assignedBus: 'Автобус #42',
    assignedRoute: 'Линија 15',
  ),
  'D-1193': UserModel(
    id: 'D-1193',
    fullName: 'Марко Петровски',
    role: UserRole.driver,
    assignedBus: 'Автобус #07',
    assignedRoute: 'Линија 3',
  ),
  'DISP-001': UserModel(
    id: 'DISP-001',
    fullName: 'Сандра Јованчева',
    role: UserRole.dispatcher,
  ),
  'DISP-002': UserModel(
    id: 'DISP-002',
    fullName: 'Ивана Николовска',
    role: UserRole.dispatcher,
  ),
};

class AuthNotifier extends Notifier<UserModel?> {
  @override
  UserModel? build() => null;

  Future<String?> login(String userId, String password) async {
    await Future<void>.delayed(const Duration(milliseconds: 700));

    if (password.length < 4) {
      return 'Невалидна лозинка';
    }

    final user = _mockUsers[userId.trim().toUpperCase()];
    if (user == null) {
      return 'Корисникот не е пронајден. Проверете го ID-то.';
    }

    state = user;
    return null;
  }

  void logout() => state = null;
}

final authProvider = NotifierProvider<AuthNotifier, UserModel?>(
  AuthNotifier.new,
);
