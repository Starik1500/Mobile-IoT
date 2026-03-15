import 'package:hive_flutter/hive_flutter.dart';
import '../domain/auth_interface.dart';

class HiveAuthRepository implements IAuthRepository {
  static const String _usersBoxName = 'usersBox';
  static const String _sessionBoxName = 'sessionBox';
  static const String _historyBoxName = 'historyBox';

  Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(_usersBoxName);
    await Hive.openBox(_sessionBoxName);
    await Hive.openBox(_historyBoxName);
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

  @override
  Future<void> addMeterHistory(String email, String meterType, Map<String, String> record) async {
    final box = Hive.box(_historyBoxName);
    final key = '${email}_$meterType';

    List<dynamic> currentHistory = box.get(key, defaultValue: []);

    currentHistory.insert(0, record);

    await box.put(key, currentHistory);
  }

  @override
  Future<List<Map<String, String>>> getMeterHistory(String email, String meterType) async {
    final box = Hive.box(_historyBoxName);
    final key = '${email}_$meterType';

    final data = box.get(key, defaultValue: []);
    return data.map<Map<String, String>>((item) => Map<String, String>.from(item)).toList();
  }

}

final authRepository = HiveAuthRepository();