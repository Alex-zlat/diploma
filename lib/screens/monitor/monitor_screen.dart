// ============================================================
// ФАЙЛ 1: monitor_screen.dart
// ============================================================

// ЭКРАН «МОНИТОР»
//
// Отображает карточки радиостанций по устройствам
// Поддерживает:
// - Пагинацию (макс 4 радиостанции на экране)
// - Воспроизведение аудиопотока (динамик/перечеркнутый динамик)
// - Переход к графикам (иконка в теле карточки)
// - Переход в карточку частоты при клике
// - Индикаторы Up/Down с цветовой индикацией (зеленый/красный эллипс)
// - Параметры: Захват несущей, FM-сигнал, Громкость

import 'package:flutter/material.dart';
import '../../services/local_storage_service.dart';
import '../../models/device_model.dart';
import '../../models/frequency_model.dart';
import '../../models/device_with_frequencies.dart';
import '../../services/audio_player_service.dart';
import '../charts/charts_screen.dart';
import '../devices/frequency_detail_screen.dart';
import '../../services/chart_data_service.dart';


class MonitorScreen extends StatefulWidget {
  final int initialPage;

  const MonitorScreen({Key? key, this.initialPage = 0}) : super(key: key);

  @override
  State<MonitorScreen> createState() => _MonitorScreenState();
}

class _MonitorScreenState extends State<MonitorScreen> {
  final LocalStorageService _storage = LocalStorageService();
  final AudioPlayerService _audioService = AudioPlayerService();

  List<DeviceWithFrequencies> _devicesWithFrequencies = [];
  bool _isLoading = true;

  // Пагинация
  int _currentPage = 0;
  int get _totalRadioStations => _allStations.length;
  int get _totalPages => (_totalRadioStations / _itemsPerPage).ceil();
  final int _itemsPerPage = 4;  // 4 карточки на страницу

  List<_StationWithDevice> _allStations = [];

  int? _playingDeviceId;
  bool _isAudioPlaying = false;

  @override
  void initState() {
    super.initState();
    _loadData().then((_) {
      if (widget.initialPage > 0 && widget.initialPage < _totalPages) {
        setState(() {
          _currentPage = widget.initialPage;
        });
      }
    });
  }

  //@override
  //void didChangeDependencies() {
    //super.didChangeDependencies();
    // Перезагружаем данные при возврате на экран
    //_loadData();
  //}

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final devices = await _storage.getDevices();
    final List<DeviceWithFrequencies> tempList = [];

    for (final device in devices) {
      final frequencies = (await _storage.getFrequenciesForDevice(device.id!))
          .map(ChartDataService.fillMockCurrentValues)
          .toList();

      tempList.add(DeviceWithFrequencies(
        device: device,
        frequencies: frequencies,
      ));
    }

    setState(() {
      _devicesWithFrequencies = tempList;
      _buildAllStationsList();
      // _currentPage = 0;  ← УДАЛИТЬ ЭТУ СТРОКУ
      // Проверяем, что текущая страница не выходит за границы
      if (_currentPage >= _totalPages && _totalPages > 0) {
        _currentPage = _totalPages - 1;
      }
      _isLoading = false;
    });
  }

  Future<Frequency?> _getFreshFrequency(int frequencyId) async {
    final devices = await _storage.getDevices();
    for (final device in devices) {
      final frequencies = await _storage.getFrequenciesForDevice(device.id!);
      for (final freq in frequencies) {
        if (freq.id == frequencyId) {
          return freq;
        }
      }
    }
    return null;
  }

  void _buildAllStationsList() {
    _allStations.clear();
    for (final dwf in _devicesWithFrequencies) {
      for (final freq in dwf.frequencies) {
        _allStations.add(_StationWithDevice(
          device: dwf.device,
          frequency: freq,
          deviceWithFrequencies: dwf,
        ));
      }
    }
  }

  List<_StationWithDevice> get _currentPageStations {
    final start = _currentPage * _itemsPerPage;
    final end = (start + _itemsPerPage) > _allStations.length
        ? _allStations.length
        : start + _itemsPerPage;
    return _allStations.sublist(start, end);
  }

  bool _calculateUpDownStatus(Frequency frequency) {
    if (frequency.currentRSSI == null || frequency.currentVolume == null) {
      return false;
    }
    final rssiOk = frequency.currentRSSI! >= frequency.thresholdRSSI;
    final volumeOk = frequency.currentVolume! >= frequency.thresholdVolume;
    final captureOk = !frequency.trackCapture || frequency.currentCapture == 1;
    return rssiOk && volumeOk && captureOk;
  }

  String _formatParameters(Frequency frequency) {
    final capture = frequency.currentCapture ?? 0;
    final rssi = frequency.currentRSSI ?? '—';
    final volume = frequency.currentVolume ?? '—';
    return '$capture/$rssi/$volume';
  }

  Future<void> _toggleCircularPlayback(DeviceWithFrequencies dwf) async {
    final deviceId = dwf.device.id!;

    // БЕРЕМ URL ИЗ ТЕКУЩЕЙ ЧАСТОТЫ
    final currentFreq = dwf.frequencies[dwf.currentPlayingIndex];
    final streamUrl = currentFreq.streamUrl;

    if (streamUrl == null || streamUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Для этой радиостанции не указана ссылка для прослушивания'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    if (dwf.frequencies.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Нет радиостанций для воспроизведения'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    if (_playingDeviceId == deviceId && _isAudioPlaying) {
      await _audioService.stop();
      setState(() {
        _isAudioPlaying = false;
        _playingDeviceId = null;
        dwf.stopPlaying();
      });
      return;
    }

    if (_playingDeviceId != null) {
      await _audioService.stop();
      final otherDwf = _devicesWithFrequencies.firstWhere(
            (d) => d.device.id == _playingDeviceId,
        orElse: () => dwf,
      );
      otherDwf.stopPlaying();
    }

    setState(() {
      _playingDeviceId = deviceId;
      _isAudioPlaying = true;
      dwf.startPlaying(-1);
    });

    await _playNextInDevice(dwf);
  }

  Future<void> _playNextInDevice(DeviceWithFrequencies dwf) async {
    if (!_isAudioPlaying || _playingDeviceId != dwf.device.id) return;

    final nextFreq = dwf.getNextFrequency();
    if (nextFreq == null) return;

    setState(() {});

    final success = await _audioService.play(dwf.device.streamUrl!);

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ошибка воспроизведения аудиопотока'),
          duration: Duration(seconds: 2),
        ),
      );
      setState(() {
        _isAudioPlaying = false;
        _playingDeviceId = null;
        dwf.stopPlaying();
      });
      return;
    }

    Future.delayed(const Duration(seconds: 10), () {
      if (_playingDeviceId == dwf.device.id && _isAudioPlaying) {
        _playNextInDevice(dwf);
      }
    });
  }

  void _goToCharts(Device device, Frequency frequency) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChartsScreen(
          device: device,
          frequency: frequency,
        ),
      ),
    );
  }

  void _goToFrequencyDetail(Device device, Frequency frequency) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FrequencyDetailScreen(
          device: device,
          frequency: frequency,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          'Монитор',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        // УБРАТЬ leading (стрелка "Назад")
        actions: [
          PopupMenuButton<String>(
            icon: const CircleAvatar(
              radius: 16,
              backgroundColor: Colors.grey,
              child: Icon(Icons.person, size: 16),
            ),
            onSelected: (value) {
              if (value == 'logout') {
                _logout();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'logout',
                child: Text('Выйти'),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _allStations.isEmpty
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.radio, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Нет добавленных радиостанций'),
            SizedBox(height: 8),
            Text(
              'Добавьте устройство и частоты\nв разделе "Устройства"',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      )
          : Column(
        children: [
          // Список карточек радиостанций
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _currentPageStations.length,
              itemBuilder: (context, index) {
                final station = _currentPageStations[index];
                return _buildStationCard(station);
              },
            ),
          ),
          // Пагинация
          if (_totalPages > 1) _buildPagination(),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  // КАРТОЧКА РАДИОСТАНЦИИ
  Widget _buildStationCard(_StationWithDevice station) {
    final freq = station.frequency;
    final isUp = _calculateUpDownStatus(freq);
    final device = station.device;
    final isPlaying = _playingDeviceId == device.id && _isAudioPlaying;

    return InkWell(
      onTap: () async {
        // ПОЛУЧАЕМ СВЕЖИЕ ДАННЫЕ ИЗ ХРАНИЛИЩА
        final freshFreq = await _getFreshFrequency(freq.id!);
        if (freshFreq == null) return;

        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FrequencyDetailScreen(
              device: device,
              frequency: freshFreq,
              returnPage: _currentPage,
              returnScreen: 'monitor',  // ← откуда пришли
            ),
          ),
        );
        if (result == true) {
          _loadData();
        }
      },
      borderRadius: BorderRadius.circular(12),
      splashColor: Colors.deepPurple.withOpacity(0.1),
      highlightColor: Colors.deepPurple.withOpacity(0.05),
      child: Card(
        margin: const EdgeInsets.only(bottom: 10),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // СЕРАЯ СТРОКА (только город и динамик)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      device.city,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        isPlaying ? Icons.volume_up : Icons.volume_off,
                        color: isPlaying ? Colors.green : Colors.grey,
                        size: 20,
                      ),
                      onPressed: () => _toggleCircularPlayback(station.deviceWithFrequencies),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: isPlaying ? 'Остановить прослушивание' : 'Начать прослушивание по кругу',
                    ),
                  ],
                ),
              ),
              // Частота + название + статус Up/Down
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Text(
                          '${freq.frequency.toStringAsFixed(1)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            freq.name,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isUp ? Colors.green : Colors.red,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      isUp ? 'Up' : 'Down',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Параметры (пороги)
              Row(
                children: [
                  const Icon(Icons.tune, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    _formatParameters(freq),
                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // ИКОНКА ГРАФИКОВ В ТЕЛЕ КАРТОЧКИ
              InkWell(
                onTap: () => _goToCharts(device, freq),
                child: const Row(
                  children: [
                    Icon(
                      Icons.analytics,
                      size: 16,
                      color: Colors.blue,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Графики',
                      style: TextStyle(
                        color: Colors.blue,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ПАГИНАЦИЯ (всегда 1-3 страницы в зоне видимости)
  Widget _buildPagination() {
    List<int> visiblePages = [];

// Если страниц 3 или больше, всегда показываем 3 номера
    if (_totalPages >= 3) {
      int startPage = _currentPage - 1;
      if (startPage < 0) startPage = 0;
      if (startPage > _totalPages - 3) startPage = _totalPages - 3;

      for (int i = 0; i < 3; i++) {
        visiblePages.add(startPage + i);
      }
    } else {
      // Если страниц меньше 3, показываем все
      for (int i = 0; i < _totalPages; i++) {
        visiblePages.add(i);
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _currentPage > 0
                ? () {
              setState(() {
                _currentPage--;
              });
            }
                : null,
          ),
          ...visiblePages.map((page) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: InkWell(
              onTap: () {
                setState(() {
                  _currentPage = page;
                });
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _currentPage == page ? Colors.deepPurple : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${page + 1}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: _currentPage == page ? FontWeight.bold : FontWeight.normal,
                    color: _currentPage == page ? Colors.white : Colors.black,
                  ),
                ),
              ),
            ),
          )),
          IconButton(
            icon: const Icon(Icons.arrow_forward),
            onPressed: _currentPage < _totalPages - 1
                ? () {
              setState(() {
                _currentPage++;
              });
            }
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      currentIndex: 0,
      onTap: (index) {
        if (index == 1) {
          Navigator.pushReplacementNamed(context, '/devices');
        } else if (index == 2) {
          // ПЕРЕХОД НА ПРОФИЛЬ
          Navigator.pushReplacementNamed(context, '/profile');
        }
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.monitor), label: 'Монитор'),
        BottomNavigationBarItem(icon: Icon(Icons.devices), label: 'Устройства'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Профиль'),
      ],
    );
  }

  void _logout() async {
    await _audioService.stop();
    AudioPlayerService().dispose();
    await LocalStorageService().clearUserSession();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/verification', (route) => false);
  }
}

// Вспомогательный класс
class _StationWithDevice {
  final Device device;
  final Frequency frequency;
  final DeviceWithFrequencies deviceWithFrequencies;

  _StationWithDevice({
    required this.device,
    required this.frequency,
    required this.deviceWithFrequencies,
  });
}