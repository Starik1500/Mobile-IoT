import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive/hive.dart';
import '../domain/auth_interface.dart';

class ApiRepository {
  final Dio _dio = Dio();

  String get _baseUrl => dotenv.env['API_URL'] ?? '';

  Future<User?> syncUserData(String email) async {
    try {
      final requestUrl = '$_baseUrl/users';
      final response = await _dio.get(requestUrl, queryParameters: {'email': email});

      if (response.statusCode == 200 && (response.data as List).isNotEmpty) {
        final apiData = response.data[0];
        List<String> parsedMeters = apiData['meters'] != null ? List<String>.from(apiData['meters']) : [];

        final serverUser = User(
          name: apiData['name'] ?? 'Користувач',
          email: apiData['email'],
          address: apiData['address'] ?? 'Адреса не вказана',
          password: apiData['password'] ?? '',
          meters: parsedMeters,
          avatarPath: apiData['avatarPath'],
        );

        final usersBox = Hive.box('usersBox');
        await usersBox.put(serverUser.email, {
          'name': serverUser.name, 'email': serverUser.email, 'address': serverUser.address,
          'password': serverUser.password, 'meters': serverUser.meters, 'avatarPath': serverUser.avatarPath,
        });

        return serverUser;
      }
      return null;
    } catch (e) {
      debugPrint('Помилка API (офлайн режим): $e');
    }

    debugPrint('Віддаємо локальні дані з Hive для: $email');
    final usersBox = Hive.box('usersBox');
    final userData = usersBox.get(email);

    if (userData != null) {
      return User(
        name: userData['name'], email: userData['email'], address: userData['address'],
        password: userData['password'], meters: List<String>.from(userData['meters'] ?? []), avatarPath: userData['avatarPath'],
      );
    }
    return null;
  }

  Future<bool> registerUser(User user) async {
    final response = await _dio.post('$_baseUrl/users', data: {
      'name': user.name, 'email': user.email, 'address': user.address,
      'password': user.password, 'meters': user.meters,
    });
    return response.statusCode == 201;
  }

  Future<void> updateUser(User user) async {
    try {
      await _dio.put('$_baseUrl/users', data: {
        'name': user.name, 'email': user.email, 'address': user.address,
        'avatarPath': user.avatarPath, 'meters': user.meters,
      });
    } catch (e) {
      debugPrint('Сервер недоступний, оновлення профілю йде в чергу...');
      throw Exception('Офлайн');
    }
  }

  Future<void> saveReading(String email, String meter, Map<String, dynamic> record) async {
    try {
      final data = {
        'email': email, 'meter': meter, 'date': record['date'], 'value': record['value'], 'source': record['source']
      };
      if (record.containsKey('image')) {
        data['image'] = record['image'];
      }

      await _dio.post('$_baseUrl/readings', data: data);
    } catch (e) {
      throw Exception('Офлайн');
    }
  }

  Future<List<Map<String, String>>> getReadings(String email, String meter) async {
    try {
      final response = await _dio.get('$_baseUrl/readings', queryParameters: {'email': email, 'meter': meter});
      if (response.statusCode == 200) {
        return List<Map<String, String>>.from((response.data as List).map((item) {
          final map = {
            'date': item['date'].toString(),
            'value': item['value'].toString(),
            'source': item['source'].toString()
          };
          if (item['image'] != null) {
            map['image'] = item['image'].toString();
          }
          return map;
        }));
      }
    } catch (e) {
      debugPrint('Офлайн: тягнемо історію з Hive');
    }
    return [];
  }
}

final apiRepository = ApiRepository();