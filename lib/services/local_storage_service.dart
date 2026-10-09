// Сервис для работы с локальным хранилищем SharedPreferences
// Временное решение до появления реального API
// При появлении API: заменить все вызовы этого сервиса на вызовы ApiService

import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/device_model.dart';
import '../models/frequency_model.dart';

class LocalStorageService {
  static const String _devicesKeyPrefix = 'devices_'; // + userId
  static const String _frequenciesKey = 'frequencies_'; // + deviceId
  static const String _authTokenKey = 'auth_token';
  static const String _isAuthenticatedKey = 'is_authenticated';
  static const String _savedEmailKey = 'saved_email';
  static const String _userEmailKey = 'user_email';
  static const String _userIdKey = 'user_id';

  SharedPreferences? _prefs;

  // Инициализация
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // ============ РАБОТА С УСТРОЙСТВАМИ (С ПРИВЯЗКОЙ К ПОЛЬЗОВАТЕЛЮ) ============

  String _getDevicesKey(int userId) => '${_devicesKeyPrefix}$userId';

  // Получить все устройства текущего пользователя
  Future<List<Device>> getDevices() async {
    if (_prefs == null) await init();

    final userId = await getCurrentUserId();
    if (userId == null) return [];

    final String? devicesJson = _prefs!.getString(_getDevicesKey(userId));
    if (devicesJson == null) return [];

    final List<dynamic> decoded = json.decode(devicesJson);
    return decoded.map((json) => Device.fromJson(json)).toList();
  }

  // Сохранить все устройства пользователя
  Future<void> saveDevices(List<Device> devices) async {
    if (_prefs == null) await init();

    final userId = await getCurrentUserId();
    if (userId == null) return;

    final List<Map<String, dynamic>> devicesMap = devices.map((d) => d.toJson()).toList();
    await _prefs!.setString(_getDevicesKey(userId), json.encode(devicesMap));
  }

  // Добавить устройство
  Future<Device> addDevice(Device device) async {
    final devices = await getDevices();
    final newDevice = device.copyWith(
      id: DateTime.now().millisecondsSinceEpoch,
    );
    devices.add(newDevice);
    await saveDevices(devices);
    return newDevice;
  }

  // Обновить устройство
  Future<void> updateDevice(Device updatedDevice) async {
    final devices = await getDevices();
    final index = devices.indexWhere((d) => d.id == updatedDevice.id);
    if (index != -1) {
      devices[index] = updatedDevice;
      await saveDevices(devices);
    }
  }

  // Удалить устройство
  Future<void> deleteDevice(int deviceId) async {
    final devices = await getDevices();
    devices.removeWhere((d) => d.id == deviceId);
    await saveDevices(devices);
    // Удаляем и частоты этого устройства
    await deleteAllFrequenciesForDevice(deviceId);
  }

  // Получить частоту по ID
  Future<Frequency?> getFrequency(int frequencyId) async {
    if (_prefs == null) await init();

    final devices = await getDevices();
    for (final device in devices) {
      final frequencies = await getFrequenciesForDevice(device.id!);
      for (final freq in frequencies) {
        if (freq.id == frequencyId) {
          return freq;
        }
      }
    }
    return null;
  }

  // ============ РАБОТА С ЧАСТОТАМИ ============

  String _getFrequenciesKey(int deviceId) => '${_frequenciesKey}$deviceId';

  // Получить все частоты для устройства
  Future<List<Frequency>> getFrequenciesForDevice(int deviceId) async {
    if (_prefs == null) await init();

    final String? freqsJson = _prefs!.getString(_getFrequenciesKey(deviceId));
    if (freqsJson == null) return [];

    final List<dynamic> decoded = json.decode(freqsJson);
    return decoded.map((json) => Frequency.fromJson(json)).toList();
  }

  // Сохранить все частоты для устройства
  Future<void> saveFrequenciesForDevice(int deviceId, List<Frequency> frequencies) async {
    if (_prefs == null) await init();

    final List<Map<String, dynamic>> freqsMap = frequencies.map((f) => f.toJson()).toList();
    await _prefs!.setString(_getFrequenciesKey(deviceId), json.encode(freqsMap));
  }

  // Добавить частоту
  Future<Frequency> addFrequency(int deviceId, Frequency frequency) async {
    final frequencies = await getFrequenciesForDevice(deviceId);
    final newFrequency = frequency.copyWith(
      id: DateTime.now().millisecondsSinceEpoch,
      deviceId: deviceId,
    );
    frequencies.add(newFrequency);
    await saveFrequenciesForDevice(deviceId, frequencies);
    return newFrequency;
  }

  // Обновить частоту
  Future<void> updateFrequency(int deviceId, Frequency updatedFrequency) async {
    final frequencies = await getFrequenciesForDevice(deviceId);
    final index = frequencies.indexWhere((f) => f.id == updatedFrequency.id);
    if (index != -1) {
      frequencies[index] = updatedFrequency;
      await saveFrequenciesForDevice(deviceId, frequencies);
    }
  }

  // Удалить частоту
  Future<void> deleteFrequency(int deviceId, int frequencyId) async {
    final frequencies = await getFrequenciesForDevice(deviceId);
    frequencies.removeWhere((f) => f.id == frequencyId);
    await saveFrequenciesForDevice(deviceId, frequencies);
  }

  // Удалить все частоты устройства
  Future<void> deleteAllFrequenciesForDevice(int deviceId) async {
    if (_prefs == null) await init();
    await _prefs!.remove(_getFrequenciesKey(deviceId));
  }

  // ============ РАБОТА С СЕССИЕЙ ПОЛЬЗОВАТЕЛЯ ============

  // Сохранить сессию пользователя (С userId)
  Future<void> saveUserSession(String email, String token, {bool rememberMe = true, int? userId}) async {
    if (_prefs == null) await init();

    if (rememberMe) {
      await _prefs!.setString(_savedEmailKey, email);
      await _prefs!.setString(_authTokenKey, token);
    } else {
      await _prefs!.remove(_savedEmailKey);
      await _prefs!.remove(_authTokenKey);
    }
    await _prefs!.setBool(_isAuthenticatedKey, true);
    await _prefs!.setString(_userEmailKey, email);
    if (userId != null) {
      await _prefs!.setInt(_userIdKey, userId);
    }
  }

  // Проверить, авторизован ли пользователь
  Future<bool> isAuthenticated() async {
    if (_prefs == null) await init();

    final isAuth = _prefs!.getBool(_isAuthenticatedKey) ?? false;
    final token = _prefs!.getString(_authTokenKey);
    return isAuth && token != null;
  }

  // Получить токен авторизации
  Future<String?> getAuthToken() async {
    if (_prefs == null) await init();
    return _prefs!.getString(_authTokenKey);
  }

  // Получить сохраненный email
  Future<String?> getSavedEmail() async {
    if (_prefs == null) await init();
    return _prefs!.getString(_savedEmailKey);
  }

  // Получить email текущего пользователя
  Future<String?> getUserEmail() async {
    if (_prefs == null) await init();
    return _prefs!.getString(_userEmailKey);
  }

  // Получить ID текущего пользователя
  Future<int?> getCurrentUserId() async {
    if (_prefs == null) await init();
    return _prefs!.getInt(_userIdKey);
  }

  // Очистить сессию пользователя (выход)
  Future<void> clearUserSession() async {
    if (_prefs == null) await init();

    await _prefs!.remove(_authTokenKey);
    await _prefs!.setBool(_isAuthenticatedKey, false);
    await _prefs!.remove(_savedEmailKey);
    await _prefs!.remove(_userEmailKey);
    await _prefs!.remove(_userIdKey);
  }

// ============ ДЛЯ ЗАМЕНЫ НА API (КОГДА ПОЯВИТСЯ) ============
/*
  // Вместо LocalStorageService создадим ApiService:

  class ApiService {
    final String baseUrl = 'https://radiostate.zlat.ru/api/';
    final Dio _dio = Dio();

    // Перехватчик для добавления токена
    ApiService() {
      _dio.interceptors.add(InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await LocalStorageService().getAuthToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
      ));
    }

    Future<List<Device>> getDevices() async {
      final response = await _dio.get('${baseUrl}devices');
      return (response.data as List).map((j) => Device.fromJson(j)).toList();
    }

    Future<Device> addDevice(Device device) async {
      final response = await _dio.post('${baseUrl}devices', data: device.toJson());
      return Device.fromJson(response.data);
    }

    Future<void> updateDevice(Device device) async {
      await _dio.put('${baseUrl}devices/${device.id}', data: device.toJson());
    }

    Future<void> deleteDevice(int deviceId) async {
      await _dio.delete('${baseUrl}devices/$deviceId');
    }

    Future<List<Frequency>> getFrequenciesForDevice(int deviceId) async {
      final response = await _dio.get('${baseUrl}devices/$deviceId/frequencies');
      return (response.data as List).map((j) => Frequency.fromJson(j)).toList();
    }

    Future<Frequency> addFrequency(int deviceId, Frequency frequency) async {
      final response = await _dio.post('${baseUrl}devices/$deviceId/frequencies', data: frequency.toJson());
      return Frequency.fromJson(response.data);
    }

    Future<void> updateFrequency(int deviceId, Frequency frequency) async {
      await _dio.put('${baseUrl}devices/$deviceId/frequencies/${frequency.id}', data: frequency.toJson());
    }

    Future<void> deleteFrequency(int deviceId, int frequencyId) async {
      await _dio.delete('${baseUrl}devices/$deviceId/frequencies/$frequencyId');
    }

    // Авторизация
    Future<Map<String, dynamic>> login(String email, String password) async {
      final response = await _dio.post('${baseUrl}auth/login', data: {
        'email': email,
        'password': password,
      });
      return response.data;
    }

    Future<void> logout() async {
      await _dio.post('${baseUrl}auth/logout');
    }

    Future<void> register(String email, String password) async {
      await _dio.post('${baseUrl}auth/register', data: {
        'email': email,
        'password': password,
      });
    }

    Future<void> resetPassword(String email) async {
      await _dio.post('${baseUrl}auth/reset-password', data: {'email': email});
    }
  }

  // Заменим так:
  // 1. Убрать sharedPrefsService из всех файлов
  // 2. Добавить apiService через dependency injection
  // 3. Заменить вызовы: getDevices() -> apiService.getDevices()
  // 4. При login: сохранять токен через LocalStorageService().saveUserSession()
  */
}