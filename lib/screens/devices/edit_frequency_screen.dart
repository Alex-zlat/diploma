// ЭКРАН 8: Частота: изменение
// Редактирование описания и пороговых значений частоты

import 'package:flutter/material.dart';
import '../../services/local_storage_service.dart';
import '../../models/frequency_model.dart';
import '../../widgets/common_widgets.dart';
import '../monitor/monitor_screen.dart';
import 'devices_screen.dart';
import '../../models/device_model.dart';
import 'device_frequencies_screen.dart';

class EditFrequencyScreen extends StatefulWidget {
  final int deviceId;
  final Frequency frequency;
  final int returnPage;
  final String returnScreen;
  final Device? device;
  final int frequencyPage;

  const EditFrequencyScreen({
    Key? key,
    required this.deviceId,
    required this.frequency,
    this.returnPage = 0,
    this.returnScreen = 'monitor',
    this.device,
    this.frequencyPage = 0,
  }) : super(key: key);

  @override
  State<EditFrequencyScreen> createState() => _EditFrequencyScreenState();
}

class _EditFrequencyScreenState extends State<EditFrequencyScreen> {
  final LocalStorageService _storage = LocalStorageService();

  late TextEditingController _frequencyController;
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _streamUrlController;

  late int _thresholdRSSI;
  late int _thresholdVolume;
  late int _thresholdLR;
  late bool _trackCapture;

  final _formKey = GlobalKey<FormState>();

  // Флаг для отслеживания изменений
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _frequencyController = TextEditingController(text: widget.frequency.frequency.toString());
    _nameController = TextEditingController(text: widget.frequency.name);
    _emailController = TextEditingController(text: widget.frequency.email);
    _streamUrlController = TextEditingController(text: widget.frequency.streamUrl ?? '');
    _thresholdRSSI = widget.frequency.thresholdRSSI;
    _thresholdVolume = widget.frequency.thresholdVolume;
    _thresholdLR = widget.frequency.thresholdLR;
    _trackCapture = widget.frequency.trackCapture;

    // Отслеживаем изменения в полях
    _frequencyController.addListener(_onChanged);
    _nameController.addListener(_onChanged);
    _emailController.addListener(_onChanged);
    _streamUrlController.addListener(_onChanged);
  }

  // Метод вызывается при любом изменении в полях
  void _onChanged() {
    if (!_hasChanges) {
      setState(() {
        _hasChanges = true;
      });
    }
  }

  // проверка, были изменения или нет
  bool _checkForChanges() {
    if (!_hasChanges) return false;

    final currentFrequency = double.tryParse(_frequencyController.text) ?? 0;
    final currentName = _nameController.text.trim();
    final currentEmail = _emailController.text.trim();
    final currentStreamUrl = _streamUrlController.text.trim().isEmpty
        ? null
        : _streamUrlController.text.trim();

    // Сравниваем с исходными данными
    if (currentFrequency != widget.frequency.frequency) return true;
    if (currentName != widget.frequency.name) return true;
    if (currentEmail != widget.frequency.email) return true;
    if (currentStreamUrl != widget.frequency.streamUrl) return true;
    if (_thresholdRSSI != widget.frequency.thresholdRSSI) return true;
    if (_thresholdVolume != widget.frequency.thresholdVolume) return true;
    if (_thresholdLR != widget.frequency.thresholdLR) return true;
    if (_trackCapture != widget.frequency.trackCapture) return true;

    return false;
  }

  // Диалог подтверждения при выходе
  Future<bool?> _showSaveDialog() async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Сохранить изменения?'),
        content: const Text(
          'У вас есть несохраненные изменения. Хотите сохранить их перед выходом?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Да'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Нет'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('Отмена'),
          ),
        ],
      ),
    );
  }

  // Обработка выхода с проверкой изменений
  Future<bool?> _handleExit() async {
    if (_checkForChanges()) {
      final result = await _showSaveDialog();

      if (result == true) {
        await _saveChanges();
        if (!mounted) return null;
        return true;
      } else if (result == false) {
        if (!mounted) return null;
        return false;
      }
      // null — ОТМЕНА, остаемся на экране
      return null;
    }

    // Изменений нет — выходим без сохранения
    return false;
  }

  Future<void> _saveChanges() async {
    if (_formKey.currentState!.validate()) {
      final updatedFrequency = widget.frequency.copyWith(
        frequency: double.parse(_frequencyController.text),
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        thresholdRSSI: _thresholdRSSI,
        thresholdVolume: _thresholdVolume,
        thresholdLR: _thresholdLR,
        trackCapture: _trackCapture,
        streamUrl: _streamUrlController.text.trim().isEmpty
            ? null
            : _streamUrlController.text.trim(),
      );

      await _storage.updateFrequency(widget.deviceId, updatedFrequency);
      _hasChanges = false;
    }
  }


  @override
  void dispose() {
    _frequencyController.removeListener(_onChanged);
    _nameController.removeListener(_onChanged);
    _emailController.removeListener(_onChanged);
    _streamUrlController.removeListener(_onChanged);
    _frequencyController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _streamUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        final result = await _handleExit();
        return result != null; // Разрешаем выход только если не "Отмена"
      },
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text('Частота: изменение', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              final result = await _handleExit();
              if (result != null && mounted) {
                Navigator.pop(context, result); // Закрываем и передаем true/false экрану, который нас открыл
              }
            },
          ),
          actions: const [LogoutCircleButton()],
        ),
        body: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Блок "Описание"
                const Text('Описание', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),

                TextFormField(
                  controller: _frequencyController,
                  decoration: const InputDecoration(
                    labelText: 'Частота',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: Frequency.validateFrequency,
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Название',
                    border: OutlineInputBorder(),
                  ),
                  validator: Frequency.validateName,
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'E-mail для уведомлений',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Укажите адрес почты';
                    }
                    if (!value.contains('@')) {
                      return 'Введите корректный email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _streamUrlController,
                  decoration: const InputDecoration(
                    labelText: 'Ссылка для прослушивания (опционально)',
                    hintText: 'http://radio.example.com:8000/stream.mp3',
                    border: OutlineInputBorder(),
                  ),
                  maxLength: 255,
                ),

                const SizedBox(height: 24),

                // Блок "Пороги"
                const Text('Пороги', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),

                // Порог RSSI
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        initialValue: _thresholdRSSI.toString(),
                        decoration: const InputDecoration(
                          labelText: 'Порог RSSI (dBm)',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (v) {
                          _thresholdRSSI = int.tryParse(v) ?? 0;
                          _onChanged();  // ← ОТСЛЕЖИВАЕМ ИЗМЕНЕНИЯ
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Row(
                      children: [
                        Checkbox(
                          value: _trackCapture,
                          onChanged: (v) {
                            setState(() {
                              _trackCapture = v ?? false;
                              _onChanged();  // ← ОТСЛЕЖИВАЕМ ИЗМЕНЕНИЯ
                            });
                          },
                        ),
                        const Text('Порог Tuned/Stereo'),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Порог Volume
                TextFormField(
                  initialValue: _thresholdVolume.toString(),
                  decoration: const InputDecoration(
                    labelText: 'Порог Volume (усл.ед.)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (v) {
                    _thresholdVolume = int.tryParse(v) ?? 0;
                    _onChanged();  // ← ОТСЛЕЖИВАЕМ ИЗМЕНЕНИЯ
                  },
                ),
                const SizedBox(height: 12),

                // Порог разницы L/R
                TextFormField(
                  initialValue: _thresholdLR.toString(),
                  decoration: const InputDecoration(
                    labelText: 'Порог разницы L/R (%)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (v) {
                    _thresholdLR = int.tryParse(v) ?? 0;
                    _onChanged();  // ← ОТСЛЕЖИВАЕМ ИЗМЕНЕНИЯ
                  },
                ),

                const SizedBox(height: 24),

                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          await _saveChanges();
                          if (!mounted) return;
                          Navigator.pop(context, true);
                        },
                        child: const Text('Сохранить'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          final result = await _handleExit();
                          // Закрываем экран только если НЕ нажали "Отмена" в диалоге
                          if (result != null && mounted) {
                            Navigator.pop(context, result);
                          }
                        },
                        child: const Text('Отмена'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: AppBottomNavigationBar(
          currentIndex: widget.returnScreen == 'devices' ? 1 : 0,
          onTap: (index) async {
            final result = await _handleExit();
            if (result == null || !mounted) return;

            if (index == 0) { // Монитор
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => MonitorScreen(
                    initialPage: widget.returnScreen == 'monitor' ? widget.returnPage : 0,
                  ),
                ),
              );
            } else if (index == 1) {  // Устройства
              if (widget.device != null && widget.returnScreen == 'devices') {
                // Возврат в то же устройство, на ту же страницу частот
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DeviceFrequenciesScreen(
                      device: widget.device!,
                      returnPage: widget.returnPage,      // страница списка устройств
                      initialPage: widget.frequencyPage,  // страница списка частот
                    ),
                  ),
                );
              } else {
                // Переход на список устройств (первая страница)
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DevicesScreen(initialPage: 0),
                  ),
                );
              }
            } else if (index == 2) { // Профиль
              Navigator.pushReplacementNamed(context, '/profile');
            }
          },
        ),
      ),
    );
  }
}