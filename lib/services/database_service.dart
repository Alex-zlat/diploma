import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'storage_service.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  // Пользователи

  Future<bool> userExists(String email) async {
    final users = StorageService.getUsers();
    return users.any((user) => user.split('|')[0] == email.toLowerCase().trim());
  }

  Future<bool> createUser(String email, String password) async {
    try {
      var users = StorageService.getUsers();
      if (users.any((user) => user.split('|')[0] == email.toLowerCase().trim())) {
        return false;
      }
      users.add('${email.toLowerCase().trim()}|$password');
      StorageService.saveUsers(users);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>?> getUser(String email, String password) async {
    final users = StorageService.getUsers();
    for (var user in users) {
      final parts = user.split('|');
      if (parts.length == 2 &&
          parts[0] == email.toLowerCase().trim() &&
          parts[1] == password) {
        return {
          'id': users.indexOf(user) + 1,
          'email': parts[0],
        };
      }
    }
    return null;
  }

  Future<int?> getUserId(String email) async {
    final users = StorageService.getUsers();
    for (int i = 0; i < users.length; i++) {
      if (users[i].split('|')[0] == email.toLowerCase().trim()) {
        return i + 1;
      }
    }
    return null;
  }

  // Устройства (с привязкой к пользователю)

  Future<List<Map<String, dynamic>>> getDevicesForUser(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'devices_$userId';
    final data = prefs.getString(key);
    if (data == null) return [];
    try {
      return List<Map<String, dynamic>>.from(jsonDecode(data) as List);
    } catch (e) {
      return [];
    }
  }

  Future<int> addDevice(int userId, Map<String, dynamic> deviceData) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'devices_$userId';
    final devices = await getDevicesForUser(userId);
    final newId = DateTime.now().millisecondsSinceEpoch;
    deviceData['id'] = newId;
    devices.add(deviceData);
    await prefs.setString(key, jsonEncode(devices));
    return newId;
  }

  Future<bool> updateDevice(int deviceId, Map<String, dynamic> deviceData) async {
    // TODO: реализовать обновление устройства
    return true;
  }

  Future<bool> deleteDevice(int deviceId) async {
    // TODO: реализовать удаление устройства
    return true;
  }

  Future<Map<String, dynamic>?> getDevice(int deviceId) async {
    // TODO: реализовать получение устройства по ID
    return null;
  }

  // Частоты (заглушки)

  Future<List<Map<String, dynamic>>> getFrequenciesForDevice(int deviceId) async {
    return [];
  }

  Future<int> addFrequency(int deviceId, Map<String, dynamic> frequencyData) async {
    return DateTime.now().millisecondsSinceEpoch;
  }

  Future<bool> updateFrequency(int frequencyId, Map<String, dynamic> frequencyData) async {
    return true;
  }

  Future<bool> deleteFrequency(int frequencyId) async {
    return true;
  }

  Future<Map<String, dynamic>?> getFrequency(int frequencyId) async {
    return null;
  }

  Future<bool> deleteAllFrequenciesForDevice(int deviceId) async {
    return true;
  }

  Future<void> clearAllData() async {
    StorageService.clearUsers();
  }
}