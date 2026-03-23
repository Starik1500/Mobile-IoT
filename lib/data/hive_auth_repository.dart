import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../domain/auth_interface.dart';
import 'api_repository.dart';

class HiveAuthRepository implements IAuthRepository {
  static const String _usersBoxName = 'usersBox';
  static const String _sessionBoxName = 'sessionBox';
  static const String _historyBoxName = 'historyBox';

  bool _isSyncingReadings = false;
  bool _isSyncingProfiles = false;

  Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(_usersBoxName);
    await Hive.openBox(_sessionBoxName);
    await Hive.openBox(_historyBoxName);
  }

  @override
  Future<void> register(User user) async {
    final usersBox = Hive.box(_usersBoxName);

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
    final usersBox = Hive.box(_usersBoxName);
    final userData = usersBox.get(email);

    if (userData != null && userData['password'] == password) {
      final sessionBox = Hive.box(_sessionBoxName);
      await sessionBox.put('currentUserEmail', email);
      debugPrint('Локальну сесію встановлено для: $email');

      syncUnsavedProfiles();
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
    final userDataMap = {
      'name': user.name,
      'email': user.email,
      'address': user.address,
      'password': user.password,
      'meters': user.meters,
      'avatarPath': user.avatarPath,
    };

    try {
      await apiRepository.updateUser(user);
    } catch (e) {
      final syncBox = await Hive.openBox<List>('unsynced_box');
      final unsynced = List<Map>.from(syncBox.get('profiles', defaultValue: []) ?? []);

      unsynced.removeWhere((e) => e['email'] == user.email);
      unsynced.add(userDataMap);

      await syncBox.put('profiles', unsynced);
      debugPrint('Офлайн: оновлення профілю відкладено в чергу.');
    }

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
        syncUnsavedProfiles();
        syncUnsavedData();
        return User.fromMap(Map<String, dynamic>.from(userData));
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

  Future<void> syncUnsavedProfiles() async {
    if (_isSyncingProfiles) return;
    _isSyncingProfiles = true;

    try {
      final syncBox = await Hive.openBox<List>('unsynced_box');

      while (true) {
        final unsynced = List<Map>.from(syncBox.get('profiles', defaultValue: []) ?? []);
        if (unsynced.isEmpty) break;

        final item = unsynced.first;

        try {
          final userToSync = User(
            name: item['name'], email: item['email'], address: item['address'],
            password: item['password'], meters: List<String>.from(item['meters'] ?? []), avatarPath: item['avatarPath'],
          );
          await apiRepository.updateUser(userToSync);

          final latestUnsynced = List<Map>.from(syncBox.get('profiles', defaultValue: []) ?? []);
          latestUnsynced.removeWhere((e) => e['email'] == item['email']);
          await syncBox.put('profiles', latestUnsynced);
        } catch (e) {
          break;
        }
      }
    } finally {
      _isSyncingProfiles = false;
    }
  }

  Future<void> syncUnsavedData() async {
    if (_isSyncingReadings) return;
    _isSyncingReadings = true;

    try {
      final syncBox = await Hive.openBox<List>('unsynced_box');

      while (true) {
        final unsynced = List<Map>.from(syncBox.get('readings', defaultValue: []) ?? []);
        if (unsynced.isEmpty) break;

        final item = unsynced.first;

        try {
          await apiRepository.saveReading(
              item['email'].toString(),
              item['meterKey'].toString(),
              Map<String, dynamic>.from(item['record'])
          );

          final latestUnsynced = List<Map>.from(syncBox.get('readings', defaultValue: []) ?? []);
          latestUnsynced.removeWhere((e) => e.toString() == item.toString());
          await syncBox.put('readings', latestUnsynced);

        } catch (e) {
          break;
        }
      }
    } finally {
      _isSyncingReadings = false;
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