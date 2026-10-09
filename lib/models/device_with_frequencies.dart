// Вспомогательная модель для экрана Монитор
// Объединяет устройство и список его радиостанций

import 'device_model.dart';
import 'frequency_model.dart';

class DeviceWithFrequencies {
  final Device device;
  final List<Frequency> frequencies;

  // Текущий индекс для воспроизведения по кругу
  int _currentPlayingIndex = -1;
  bool _isPlaying = false;

  DeviceWithFrequencies({
    required this.device,
    required this.frequencies,
  });

  // Геттеры для состояния воспроизведения
  bool get isPlaying => _isPlaying;
  int get currentPlayingIndex => _currentPlayingIndex;

  // Начать воспроизведение с указанной частоты
  void startPlaying(int index) {
    _isPlaying = true;
    _currentPlayingIndex = index;
  }

  // Остановить воспроизведение
  void stopPlaying() {
    _isPlaying = false;
    _currentPlayingIndex = -1;
  }

  // Получить следующую частоту для воспроизведения (по кругу)
  Frequency? getNextFrequency() {
    if (frequencies.isEmpty) return null;
    _currentPlayingIndex = (_currentPlayingIndex + 1) % frequencies.length;
    return frequencies[_currentPlayingIndex];
  }

  // Копирование с новыми частотами (для обновления)
  DeviceWithFrequencies copyWith({
    Device? device,
    List<Frequency>? frequencies,
  }) {
    final newInstance = DeviceWithFrequencies(
      device: device ?? this.device,
      frequencies: frequencies ?? this.frequencies,
    );
    newInstance._isPlaying = _isPlaying;
    newInstance._currentPlayingIndex = _currentPlayingIndex;
    return newInstance;
  }
}