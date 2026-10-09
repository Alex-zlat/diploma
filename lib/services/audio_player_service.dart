// Сервис для воспроизведения аудиопотоков
// Использует пакет audioplayers

import 'package:audioplayers/audioplayers.dart';

class AudioPlayerService {
  static final AudioPlayerService _instance = AudioPlayerService._internal();
  factory AudioPlayerService() => _instance;
  AudioPlayerService._internal();

  final AudioPlayer _player = AudioPlayer();
  String? _currentUrl;

  // Воспроизвести URL
  Future<bool> play(String url) async {
    try {
      // Останавливаем текущее воспроизведение
      await stop();

      _currentUrl = url;
      final result = await _player.play(UrlSource(url));
      return true;
    } catch (e) {
      print('Ошибка воспроизведения: $e');
      return false;
    }
  }

  // Остановить воспроизведение
  Future<void> stop() async {
    await _player.stop();
    _currentUrl = null;
  }

  // Пауза
  Future<void> pause() async {
    await _player.pause();
  }

  // Возобновить
  Future<void> resume() async {
    if (_currentUrl != null) {
      await _player.resume();
    }
  }

  // Проверить, воспроизводится ли сейчас
  bool get isPlaying => _player.state == PlayerState.playing;

  // Получить текущий URL
  String? get currentUrl => _currentUrl;

  // Освободить ресурсы
  void dispose() {
    _player.dispose();
  }
}