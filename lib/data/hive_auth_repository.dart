import 'package:hive_flutter/hive_flutter.dart';
import '../domain/auth_interface.dart';
import 'api_repository.dart';
import 'package:flutter/material.dart';

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
    final usersBox = Hive.box('usersbox');

    await apiRepository.registerUser(user);

    final userDataMap = {
      'name': user.name,
      'email': user.email,
      'address': user.address,
      'password': user.password,
      'meters': user.meters,
      'avatarPath': user.avatarPath,
    };
    await usersBox.put(user.email, userDataMap);
  }

  @override
  Future<User> login(String email, String password) async {
    final usersBox = Hive.box('usersbox');
    final userData = usersBox.get(email);

    if (userData != null && userData['password'] == password) {
      final sessionBox = Hive.box('sessionBox');
      await sessionBox.put('currentUserEmail', email);
      debugPrint('Локальну сесію встановлено для: $email');
      syncUnsavedData();

      return User(
        name: userData['name'],
        email: userData['email'],
        address: userData['address'],
        password: userData['password'],
        meters: List<String>.from(userData['meters'] ?? []),
        avatarPath: userData['avatarPath'],
      );
    }

    throw Exception('Невірний email або пароль');
  }

  @override
  Future<void> updateUser(User user) async {
    final usersBox = Hive.box(_usersBoxName);

    await apiRepository.updateUser(user);

    final userDataMap = {
      'name': user.name,
      'email': user.email,
      'address': user.address,
      'password': user.password,
      'meters': user.meters,
      'avatarPath': user.avatarPath,
    };
    await usersBox.put(user.email, userDataMap);
  }

  @override
  Future<void> logout() async {
    final sessionBox = Hive.box(_sessionBoxName);
    await sessionBox.clear();
  }
  Future<void> saveSession(String email, {String? token}) async {
    final sessionBox = Hive.box(_sessionBoxName);
    await sessionBox.put('currentUserEmail', email);
    if (token != null) {
      await sessionBox.put('authToken', token);
    }
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
  Future<void> addMeterHistory(String email, String meterKey, Map<String, dynamic> record) async {
    final boxName = 'history_$email';
    final historyBox = await Hive.openBox<List>(boxName);
    final history = List<Map>.from(historyBox.get(meterKey, defaultValue: []) ?? []);

    try {
      await apiRepository.saveReading(email, meterKey, record);
    } catch (e) {
      final syncBox = await Hive.openBox<List>('unsynced_box');

      final unsynced = List<Map>.from(syncBox.get('readings', defaultValue: []) ?? []);
      unsynced.add({'email': email, 'meterKey': meterKey, 'record': record});
      await syncBox.put('readings', unsynced);
      debugPrint('Відправку відкладено. Збережено в чергу синхронізації.');
    }

    final stringRecord = record.map((key, value) => MapEntry(key.toString(), value.toString()));
    history.insert(0, stringRecord);
    await historyBox.put(meterKey, history);
  }

  Future<void> syncUnsavedData() async {
    final syncBox = await Hive.openBox<List>('unsynced_box');
    final unsynced = List<Map>.from(syncBox.get('readings', defaultValue: []) ?? []);

    if (unsynced.isEmpty) return;

    debugPrint('Знайдено ${unsynced.length} несинхронізованих показників. Спроба відправки...');

    List<Map> remainUnsynced = [];
    for (var item in unsynced) {
      try {
        await apiRepository.saveReading(
            item['email'].toString(),
            item['meterKey'].toString(),
            Map<String, dynamic>.from(item['record'])
        );
      } catch (e) {
        remainUnsynced.add(item);
      }
    }

    await syncBox.put('readings', remainUnsynced);
    if (remainUnsynced.isEmpty) {
      debugPrint('Всі відкладені показники успішно відправлено на сервер!');
    }
  }

  @override
  Future<List<Map<String, String>>> getMeterHistory(String email, String meterKey) async {
    await syncUnsavedData();

    final boxName = 'history_$email';
    final historyBox = await Hive.openBox<List>(boxName);

    final serverData = await apiRepository.getReadings(email, meterKey);

    if (serverData.isNotEmpty) {
      await historyBox.put(meterKey, serverData);
      return serverData;
    }

    final localHistory = List<Map>.from(historyBox.get(meterKey, defaultValue: []) ?? []);
    return localHistory.map((e) => {
      'date': e['date'].toString(),
      'value': e['value'].toString(),
      'source': e['source'].toString(),
    }).toList();
  }

}

final authRepository = HiveAuthRepository();