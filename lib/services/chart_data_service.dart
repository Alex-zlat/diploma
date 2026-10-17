// Сервис для получения данных графиков с сервера

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/device_model.dart';
import '../models/frequency_model.dart';

// Типы графиков для частот
enum StationChartType { volume, rssi, tuned }

// Точка данных для графика
class ChartDataPoint {
  final DateTime time;  // время замера
  final double value;   // значение параметра
  final int frequencyId; // ID частоты (для группировки)
  final String frequencyName; // название частоты/радиостанции
  final double frequencyValue; // номинал частоты (для отображения)

  ChartDataPoint({
    required this.time,
    required this.value,
    required this.frequencyId,
    required this.frequencyName,
    required this.frequencyValue,
  });

  Map<String, dynamic> toJson() => {
    'time': time.toIso8601String(),
    'value': value,
    'frequencyId': frequencyId,
    'frequencyName': frequencyName,
    'frequencyValue': frequencyValue,
  };

  factory ChartDataPoint.fromJson(Map<String, dynamic> json) {
    return ChartDataPoint(
      time: DateTime.parse(json['time']),
      value: (json['value'] as num).toDouble(),
      frequencyId: json['frequencyId'],
      frequencyName: json['frequencyName'],
      frequencyValue: (json['frequencyValue'] as num).toDouble(),
    );
  }
}

// Данные для графика устройства (Online время)
class DeviceOnlineData {
  final DateTime time;
  final bool isOnline;

  DeviceOnlineData({required this.time, required this.isOnline});

  factory DeviceOnlineData.fromJson(Map<String, dynamic> json) {
    return DeviceOnlineData(
      time: DateTime.parse(json['time']),
      isOnline: json['isOnline'] == 1 || json['isOnline'] == true,
    );
  }
}

class ChartDataService {
  static const String baseUrl = 'https://radiostate.zlat.ru/Chart';

  // РЕАЛЬНЫЕ ЗАПРОСЫ К СЕРВЕРУ

  // Получить данные об Online времени устройства
  // URL: /Chart/DeviceOnlineTime/{deviceId}
  Future<List<DeviceOnlineData>> getDeviceOnlineTime(int deviceId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/DeviceOnlineTime/$deviceId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) => DeviceOnlineData.fromJson(item)).toList();
      } else {
        return [];
      }
    } catch (e) {
      print('Ошибка загрузки DeviceOnlineTime: $e');
      return [];
    }
  }

  // Получить данные для графика частот (Volume, RSSI, Tuned)
  // URL: /Chart/DeviceStationsTime/{deviceId}?stationChartType={type}
  Future<List<ChartDataPoint>> getStationChartData(
      int deviceId,
      StationChartType type,
      List<Frequency> frequencies,
      ) async {
    try {
      final typeParam = type.toString().split('.').last;
      final response = await http.get(
        Uri.parse('$baseUrl/DeviceStationsTime/$deviceId?stationChartType=$typeParam'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) {
          // Находим частоту по ID для получения названия
          final freq = frequencies.firstWhere(
                (f) => f.id == item['frequencyId'],
            orElse: () => Frequency(
              deviceId: deviceId,
              frequency: item['frequencyValue']?.toDouble() ?? 0,
              name: item['frequencyName'] ?? 'Неизвестно',
              email: '',
            ),
          );

          return ChartDataPoint(
            time: DateTime.parse(item['time']),
            value: (item['value'] as num).toDouble(),
            frequencyId: item['frequencyId'],
            frequencyName: freq.name,
            frequencyValue: freq.frequency,
          );
        }).toList();
      } else {
        return [];
      }
    } catch (e) {
      print('Ошибка загрузки StationChartData ($type): $e');
      return [];
    }
  }

  // ЗАГЛУШКА ДЛЯ ДЕМОНСТРАЦИИ (пока нет API)
  // В реальном приложении этот метод удалю

  static List<ChartDataPoint> getMockStationData(
      List<Frequency> frequencies,
      StationChartType type,
      ) {
    final stopwatch = Stopwatch()..start();
    final List<ChartDataPoint> mockData = [];
    final now = DateTime.now();

    // Генерируем 24 точки для каждой частоты (по часам)
    for (int hour = 0; hour < 24; hour++) {
      final time = DateTime(now.year, now.month, now.day, hour);

      for (final freq in frequencies) {
        double value;
        switch (type) {
          case StationChartType.volume:
            value = (50 + (freq.frequency % 50) + (hour * 2) % 30).toDouble();
            if (value > 100) value = 100;
            break;
          case StationChartType.rssi:
            value = (30 + (freq.frequency % 40) + (hour % 20)).toDouble();
            if (value > 80) value = 80;
            break;
          case StationChartType.tuned:
            value = (hour >= 6 && hour <= 23) ? 1.0 : 0.0;
            break;
        }

        mockData.add(ChartDataPoint(
          time: time,
          value: value,
          frequencyId: freq.id!,
          frequencyName: freq.name,
          frequencyValue: freq.frequency,
        ));
      }
    }

    stopwatch.stop();
    print('Mock generation (station): ${stopwatch.elapsedMicroseconds} мкс');

    return mockData;
  }

  static List<DeviceOnlineData> getMockDeviceOnlineData() {

    final stopwatch = Stopwatch()..start();

    final now = DateTime.now();
    final List<DeviceOnlineData> mockData = [];

    for (int hour = 0; hour < 24; hour++) {
      final time = DateTime(now.year, now.month, now.day, hour);
      // Устройство онлайн с 8 до 23 часов
      final isOnline = hour >= 8 && hour <= 23;
      mockData.add(DeviceOnlineData(time: time, isOnline: isOnline));
    }

    stopwatch.stop();
    print('Mock generation (online): ${stopwatch.elapsedMicroseconds} мкс');

    return mockData;
  }

  // Заполнение текущих значений для карточки мониторинга (mock)
  static Frequency fillMockCurrentValues(Frequency freq) {
    return freq.copyWith(
      currentRSSI: (30 + (freq.frequency % 40)).toInt(),
      currentVolume: (50 + (freq.frequency % 50)).toInt(),
      currentCapture: 1,
      isUp: true,
    );
  }

}