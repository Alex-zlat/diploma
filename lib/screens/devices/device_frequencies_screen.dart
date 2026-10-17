// ЭКРАН 6: Устройство: [название устройства]
// Список радиочастот для конкретного устройства (карточки)
// Позволяет добавлять, редактировать, удалять частоты
// Кнопка "Записать частоты" (логика сохранения)

import 'package:flutter/material.dart';
import '../../services/local_storage_service.dart';
import '../../models/device_model.dart';
import '../../models/frequency_model.dart';
import '../../widgets/common_widgets.dart';
import 'add_frequency_screen.dart';
import 'edit_frequency_screen.dart';
import 'frequency_detail_screen.dart';
import '../charts/charts_screen.dart';
import 'devices_screen.dart';

class DeviceFrequenciesScreen extends StatefulWidget {
  final Device device;
  final int returnPage;      // страница устройств для возврата
  final int initialPage;     // страница частот для возврата

  const DeviceFrequenciesScreen({
    Key? key,
    required this.device,
    this.returnPage = 0,
    this.initialPage = 0,
  }) : super(key: key);

  @override
  State<DeviceFrequenciesScreen> createState() => _DeviceFrequenciesScreenState();
}

class _DeviceFrequenciesScreenState extends State<DeviceFrequenciesScreen> {
  final LocalStorageService _storage = LocalStorageService();
  List<Frequency> _frequencies = [];
  bool _isLoading = true;

  // Пагинация
  int _currentPage = 0;
  int get _totalFrequencies => _frequencies.length;
  int get _totalPages => (_totalFrequencies / _itemsPerPage).ceil();
  final int _itemsPerPage = 3;  // 3 карточки на страницу

  List<Frequency> get _currentPageFrequencies {
    final start = _currentPage * _itemsPerPage;
    final end = (start + _itemsPerPage) > _frequencies.length
        ? _frequencies.length
        : start + _itemsPerPage;
    return _frequencies.sublist(start, end);
  }

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialPage;  // initialPage
    _loadFrequencies();
  }

  Future<void> _loadFrequencies() async {
    setState(() => _isLoading = true);

    // 1. Загружаем актуальный список частот
    _frequencies = await _storage.getFrequenciesForDevice(widget.device.id!);

    // 2. Обновляем состояние UI и корректируем страницу при необходимости
    setState(() {
      // Страховка: если текущая страница вышла за границы (например, удалили частоту)
      if (_currentPage >= _totalPages && _totalPages > 0) {
        _currentPage = _totalPages - 1;
      }
      _isLoading = false;
    });
  }

  Future<Frequency?> _getFreshFrequency(int frequencyId) async {
    final frequencies = await _storage.getFrequenciesForDevice(widget.device.id!);
    for (final freq in frequencies) {
      if (freq.id == frequencyId) {
        return freq;
      }
    }
    return null;
  }

  Future<void> _writeFrequenciesToDevice() async {
    if (_frequencies.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Нет частот для записи. Сначала добавьте хотя бы одну частоту.'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Частоты записаны в устройство "${widget.device.city}"'),
        backgroundColor: Colors.green,
      ),
    );
  }

  String _formatThresholds(Frequency freq) {
    return '${freq.thresholdRSSI}/${freq.thresholdVolume}/${freq.thresholdLR}%';
  }

  String _getShortTitle() {
    final city = widget.device.city;
    if (city.length > 20) {
      return '${city.substring(0, 20)}...';
    }
    return city;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Устройство: ${_getShortTitle()}',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // ← возврат на Устройства с той же страницей
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => DevicesScreen(
                  initialPage: widget.returnPage,
                ),
              ),
            );
          },
        ),
        actions: const [LogoutCircleButton()],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          // Кнопка "Добавить частоту"
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Частоты',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                ElevatedButton.icon(
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AddFrequencyScreen(deviceId: widget.device.id!),
                      ),
                    );
                    if (result == true) _loadFrequencies();
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Добавить'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ],
            ),
          ),
          // Список карточек частот
          Expanded(
            child: _frequencies.isEmpty
                ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.radio, size: 48, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Нет добавленных частот'),
                  SizedBox(height: 8),
                  Text(
                    'Нажмите "Добавить" чтобы создать частоту',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _currentPageFrequencies.length,
              itemBuilder: (context, index) {
                final freq = _currentPageFrequencies[index];
                return _buildFrequencyCard(freq);
              },
            ),
          ),
          // Пагинация
          if (_totalPages > 1) _buildPagination(),
          // Кнопка "Записать частоты"
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              onPressed: _writeFrequenciesToDevice,
              icon: const Icon(Icons.save, color: Colors.white),
              label: const Text(
                'Записать частоты',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: AppBottomNavigationBar(
        currentIndex: 1,
        onTap: (index) {
          if (index == 0) {
            // ← переход на Монитор (страница 1)
            Navigator.pushReplacementNamed(context, '/monitor');
          } else if (index == 2) {
            Navigator.pushNamed(context, '/profile');
          }
        },
      ),
    );
  }

  // КАРТОЧКА ЧАСТОТЫ (с визуальной кликабельностью)
  Widget _buildFrequencyCard(Frequency freq) {
    return InkWell(
      onTap: () async {
        final freshFreq = await _getFreshFrequency(freq.id!);
        if (freshFreq == null) return;

        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => FrequencyDetailScreen(
              device: widget.device,
              frequency: freshFreq,
              returnPage: _currentPage,
              returnScreen: 'devices',
            ),
          ),
        );
        if (result == true) {
          _loadFrequencies();
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
              // Верхняя строка: частота + название + статус Up/Down
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Text(
                          '${freq.frequency.toStringAsFixed(1)}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            freq.name,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: freq.isUp ? Colors.green : Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      freq.isUp ? 'Up' : 'Down',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Пороги
              Row(
                children: [
                  const Icon(Icons.tune, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    'Пороги: ${_formatThresholds(freq)}',
                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              // E-mail
              Row(
                children: [
                  const Icon(Icons.email_outlined, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      freq.email,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // ИКОНКА ГРАФИКОВ В КАРТОЧКЕ ЧАСТОТЫ
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChartsScreen(
                        device: widget.device,
                        frequency: freq,
                      ),
                    ),
                  );
                },
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
              const SizedBox(height: 10),
              // Кнопки действий
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EditFrequencyScreen(
                            deviceId: widget.device.id!,
                            frequency: freq,
                            device: widget.device,
                            returnPage: widget.returnPage,   // страница списка устройств (исправить!)
                            returnScreen: 'devices',
                            frequencyPage: _currentPage,     // страница списка частот
                          ),
                        ),
                      );
                      if (result == true) _loadFrequencies();
                    },
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Изменить'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                  ),
                  const SizedBox(width: 4),
                  TextButton.icon(
                    onPressed: () {
                      showDeleteFrequencyDialog(
                        context,
                        frequencyId: freq.id!,
                        frequencyName: freq.name,
                        onDelete: () async {
                          await _storage.deleteFrequency(widget.device.id!, freq.id!);
                          _loadFrequencies();
                        },
                      );
                    },
                    icon: const Icon(Icons.delete_outline, size: 16),
                    label: const Text('Удалить'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Пагинация (всегда 1-3 страницы в зоне видимости)
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
}