// ЭКРАН 7: Частота: [название радиостанции]
// Отображает информацию о частоте
// Кнопка "Изменить" → экран 8

import 'package:flutter/material.dart';
import '../../models/device_model.dart';
import '../../models/frequency_model.dart';
import '../../widgets/common_widgets.dart';
import 'edit_frequency_screen.dart';
import '../../services/local_storage_service.dart';
import '../monitor/monitor_screen.dart';
import 'devices_screen.dart';

class FrequencyDetailScreen extends StatelessWidget {
  final Device device;
  final Frequency frequency;
  final int returnPage;
  final String returnScreen;

  const FrequencyDetailScreen({
    Key? key,
    required this.device,
    required this.frequency,
    this.returnPage = 0,
    this.returnScreen = 'monitor',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Частота: ${frequency.name}',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context); // ← Просто делаем шаг назад по стеку навигации
          },
        ),
        actions: const [LogoutCircleButton()],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Таблица с информацией
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _infoRow('Устройство', device.city),
                    const Divider(),
                    _infoRow('Частота', '${frequency.frequency} МГц'),
                    const Divider(),
                    _infoRow('Название', frequency.name),
                    const Divider(),
                    _infoRow('Пороги', '${frequency.thresholdRSSI}/${frequency.thresholdVolume}/${frequency.thresholdLR}%'),
                    const Divider(),
                    _infoRow('E-mail для уведомлений', frequency.email),
                    if (frequency.streamUrl != null && frequency.streamUrl!.isNotEmpty) ...[
                      const Divider(),
                      _infoRow('Ссылка для прослушивания', frequency.streamUrl!),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Кнопка "Изменить"
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EditFrequencyScreen(
                        deviceId: device.id!,
                        frequency: frequency,
                        returnPage: returnPage,      // ← Передаем страницу, на которой были
                        returnScreen: returnScreen,  // ← Передаем 'monitor' или 'devices'
                      ),
                    ),
                  );
                  if (result == true) {
                    final updatedFreq = await _getUpdatedFrequency(frequency.id!);
                    if (updatedFreq != null) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => FrequencyDetailScreen(
                            device: device,
                            frequency: updatedFreq,
                            returnPage: returnPage,       // ← ДОБАВИТЬ
                            returnScreen: returnScreen,   // ← ДОБАВИТЬ
                          ),
                        ),
                      );
                    }
                  }
                },
                child: const Text('Изменить'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: AppBottomNavigationBar(
        currentIndex: returnScreen == 'devices' ? 1 : 0,  // ← правильная подсветка
        onTap: (index) {
          if (index == 0) {
            // ← переход на Монитор (всегда страница 1)
            Navigator.pushReplacementNamed(context, '/monitor');
          } else if (index == 1) {
            // ← переход на Устройства (всегда страница 1)
            Navigator.pushReplacementNamed(context, '/devices');
          } else if (index == 2) {
            Navigator.pushNamed(context, '/profile');
          }
        },
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  // НОВЫЙ МЕТОД
  Future<Frequency?> _getUpdatedFrequency(int id) async {
    final storage = LocalStorageService();
    return await storage.getFrequency(id);
  }

}