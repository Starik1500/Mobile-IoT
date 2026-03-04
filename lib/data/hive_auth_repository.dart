import 'package:hive_flutter/hive_flutter.dart';
import '../domain/auth_interface.dart';

class HiveAuthRepository implements IAuthRepository {
  static const String _usersBoxName = 'usersBox';
  static const String _sessionBoxName = 'sessionBox';

  Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(_usersBoxName);
    await Hive.openBox(_sessionBoxName);
  }

  @override
  Future<void> register(User user) async {
    final box = Hive.box(_usersBoxName);

    if (box.containsKey(user.email)) {
      throw Exception('Користувач з таким email вже існує!');
    }

    await box.put(user.email, user.toMap());
  }

  @override
  Future<User> login(String email, String password) async {
    final box = Hive.box(_usersBoxName);

    if (!box.containsKey(email)) {
      throw Exception('Користувача не знайдено!');
    }

    final userData = box.get(email);
    final user = User.fromMap(userData);

    if (user.password != password) {
      throw Exception('Неправильний пароль!');
    }

    final sessionBox = Hive.box(_sessionBoxName);
    await sessionBox.put('currentUserEmail', user.email);

    return user;
  }

  @override
  Future<void> updateUser(User user) async {
    final box = Hive.box(_usersBoxName);
    await box.put(user.email, user.toMap());
  }

  @override
  Future<void> logout() async {
    final sessionBox = Hive.box(_sessionBoxName);
    await sessionBox.delete('currentUserEmail');
  }

  @override
  Future<User?> getCurrentUser() async {
    final sessionBox = Hive.box(_sessionBoxName);
    final currentUserEmail = sessionBox.get('currentUserEmail');

    if (currentUserEmail != null) {
      final usersBox = Hive.box(_usersBoxName);
      final userData = usersBox.get(currentUserEmail);
      if (userData != null) {
        return User.fromMap(userData);
      }
    }
    return null;
  }
}

final authRepository = HiveAuthRepository();