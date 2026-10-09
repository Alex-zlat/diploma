// ============================================================
// ФАЙЛ 2: devices_screen.dart
// ============================================================

// ЭКРАН 1: Список устройств
// Отображает карточки всех устройств пользователя
// Позволяет добавить, редактировать, удалить устройство
// При клике на город → экран 6 (частоты устройства)

import 'package:flutter/material.dart';
import '../../services/local_storage_service.dart';
import '../../models/device_model.dart';
import '../../widgets/common_widgets.dart';
import 'add_device_screen.dart';
import 'add_device_by_token_screen.dart';
import 'device_frequencies_screen.dart';
import 'edit_device_screen.dart';
import '../monitor/monitor_screen.dart';

class DevicesScreen extends StatefulWidget {
  final int initialPage;  // ← для возврата на ту же страницу

  const DevicesScreen({Key? key, this.initialPage = 0}) : super(key: key);

  @override
  State<DevicesScreen> createState() => _DevicesScreenState();
}

class _DevicesScreenState extends State<DevicesScreen> {
  final LocalStorageService _storage = LocalStorageService();
  List<Device> _devices = [];
  bool _isLoading = true;

  // ✅ ПАГИНАЦИЯ (убедитесь, что эта строка есть!)
  int _currentPage = 0;

  int get _totalDevices => _devices.length;
  int get _totalPages => (_totalDevices / _itemsPerPage).ceil();
  final int _itemsPerPage = 3; // 3 карточки на страницу

  List<Device> get _currentPageDevices {
    final start = _currentPage * _itemsPerPage;
    final end = (start + _itemsPerPage) > _devices.length
        ? _devices.length
        : start + _itemsPerPage;
    return _devices.sublist(start, end);
  }

  @override
  void initState() {
    super.initState();
    // ✅ Устанавливаем страницу СРАЗУ при инициализации
    _currentPage = widget.initialPage;
    _loadDevices();
  }

  Future<void> _loadDevices() async {
    setState(() => _isLoading = true);

    // 1. Загружаем актуальный список
    _devices = await _storage.getDevices();

    // 2. Обновляем состояние UI и корректируем страницу при необходимости
    setState(() {
      // Страховка: если текущая страница вышла за границы (например, удалили устройство)
      if (_currentPage >= _totalPages && _totalPages > 0) {
        _currentPage = _totalPages - 1;
      }
      _isLoading = false;
    });
  }

  void _showAddDeviceOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.add_circle_outline),
              title: const Text('Добавить'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddDeviceScreen()),
                ).then((_) => _loadDevices());
              },
            ),
            ListTile(
              leading: const Icon(Icons.qr_code_scanner),
              title: const Text('Добавить по токену'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddDeviceByTokenScreen()),
                ).then((_) => _loadDevices());
              },
            ),
          ],
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
          'Список устройств',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        // УБРАТЬ leading (стрелка "Назад")
        actions: const [
          LogoutCircleButton(),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _devices.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.devices_other, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('Нет добавленных устройств'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _showAddDeviceOptions,
              child: const Text('Добавить устройство'),
            ),
          ],
        ),
      )
          : Column(
        children: [
          // Кнопка «Добавить устройство»
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              onPressed: _showAddDeviceOptions,
              icon: const Icon(Icons.add),
              label: const Text('Добавить устройство'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ),
          // Список карточек устройств
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _currentPageDevices.length,
              itemBuilder: (context, index) {
                final device = _currentPageDevices[index];
                return _buildDeviceCard(device);
              },
            ),
          ),
          // Пагинация
          if (_totalPages > 1) _buildPagination(),
        ],
      ),
      bottomNavigationBar: AppBottomNavigationBar(
        currentIndex: 1,
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => MonitorScreen(
                  initialPage: 0,   // ← изменили с _currentPage на 0
                ),
              ),
            );
          } else if (index == 2) {  // ← ЭТО ОСТАВИТЬ БЕЗ ИЗМЕНЕНИЙ
            Navigator.pushNamed(context, '/profile');
          }
        },
      ),
    );
  }

  Widget _buildDeviceCard(Device device) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Верхняя строка: Город + статус Online
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      // ← передаём текущую страницу для возврата
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DeviceFrequenciesScreen(
                            device: device,
                            returnPage: _currentPage,  // ← запоминаем страницу
                          ),
                        ),
                      );
                      if (result == true) {
                        _loadDevices();
                      }
                    },
                    child: Text(
                      device.city,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: device.isOnline ? Colors.green : Colors.red,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      device.isOnline ? 'Online' : 'Offline',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: device.isOnline ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),

            // E-mail
            Row(
              children: [
                const Icon(Icons.email_outlined, size: 16, color: Colors.grey),
                const SizedBox(width: 6),
                Text(
                  device.email,
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Таймауты
            Row(
              children: [
                const Icon(Icons.timer_outlined, size: 16, color: Colors.grey),
                const SizedBox(width: 6),
                Text(
                  'Таймауты: ${device.listenTimeout}/${device.upDownTimeout}/${device.onlineOfflineTimeout}',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Флаг "Использовать"
            Row(
              children: [
                Icon(
                  device.isUsed ? Icons.check_box : Icons.check_box_outline_blank,
                  size: 16,
                  color: device.isUsed ? Colors.green : Colors.grey,
                ),
                const SizedBox(width: 6),
                Text(
                  device.isUsed ? 'Используется' : 'Не используется',
                  style: TextStyle(
                    fontSize: 14,
                    color: device.isUsed ? Colors.green : Colors.grey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Разделитель
            const Divider(height: 1),

            // Кнопки действий
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EditDeviceScreen(device: device),
                      ),
                    );
                    if (result == true) _loadDevices();
                  },
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('Изменить'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.blue,
                  ),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () {
                    showDeleteDeviceDialog(
                      context,
                      deviceId: device.id!,
                      deviceCity: device.city,
                      onDelete: () async {
                        await _storage.deleteDevice(device.id!);
                        _loadDevices();
                      },
                    );
                  },
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('Удалить'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                  ),
                ),
              ],
            ),
          ],
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
}