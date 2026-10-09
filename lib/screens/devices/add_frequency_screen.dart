// ЭКРАН 9: Частота: добавление
// Добавление новой частоты для устройства

import 'package:flutter/material.dart';
import '../../services/local_storage_service.dart';
import '../../models/frequency_model.dart';
import '../../widgets/common_widgets.dart';

class AddFrequencyScreen extends StatefulWidget {
  final int deviceId;

  const AddFrequencyScreen({Key? key, required this.deviceId}) : super(key: key);

  @override
  State<AddFrequencyScreen> createState() => _AddFrequencyScreenState();
}

class _AddFrequencyScreenState extends State<AddFrequencyScreen> {
  final LocalStorageService _storage = LocalStorageService();

  final _frequencyController = TextEditingController();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _streamUrlController = TextEditingController();

  int _thresholdRSSI = 0;
  int _thresholdVolume = 0;
  int _thresholdLR = 0;

  final _formKey = GlobalKey<FormState>();

  Future<void> _createFrequency() async {
    if (_formKey.currentState!.validate()) {
      final newFrequency = Frequency(
        deviceId: widget.deviceId,
        frequency: double.parse(_frequencyController.text),
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        thresholdRSSI: _thresholdRSSI,
        thresholdVolume: _thresholdVolume,
        thresholdLR: _thresholdLR,
        streamUrl: _streamUrlController.text.trim().isEmpty
            ? null
            : _streamUrlController.text.trim(),  // ← НОВОЕ
      );

      await _storage.addFrequency(widget.deviceId, newFrequency);
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Tooltip(
          message: 'Частота: добавление',
          child: const Text(
            'Частота: добавление',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
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
              const Text('Описание', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),

              TextFormField(
                controller: _frequencyController,
                decoration: const InputDecoration(labelText: 'Частота', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
                validator: Frequency.validateFrequency,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Название', border: OutlineInputBorder()),
                validator: Frequency.validateName,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'E-mail для уведомлений', border: OutlineInputBorder()),
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

              const Text('Пороги', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),

              TextFormField(
                decoration: const InputDecoration(labelText: 'Порог RSSI (dBm)', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
                onChanged: (v) => _thresholdRSSI = int.tryParse(v) ?? 0,
              ),
              const SizedBox(height: 12),

              TextFormField(
                decoration: const InputDecoration(labelText: 'Порог Volume (усл.ед.)', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
                onChanged: (v) => _thresholdVolume = int.tryParse(v) ?? 0,
              ),
              const SizedBox(height: 12),

              TextFormField(
                decoration: const InputDecoration(labelText: 'Порог разницы L/R (%)', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
                onChanged: (v) => _thresholdLR = int.tryParse(v) ?? 0,
              ),

              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _createFrequency,
                      child: const Text('Создать'),
                      style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        _frequencyController.clear();
                        _nameController.clear();
                        _emailController.clear();
                        _streamUrlController.clear();
                        Navigator.pop(context);
                      },
                      child: const Text('Отмена'),
                      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),

      bottomNavigationBar: AppBottomNavigationBar(
        currentIndex: 1,
        onTap: (index) {
          if (index == 0) Navigator.pushReplacementNamed(context, '/monitor');
          if (index == 2) Navigator.pushNamed(context, '/profile');
        },
      ),
    );
  }
}