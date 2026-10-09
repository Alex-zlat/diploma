// ЭКРАН 2: Устройства: добавление
// Форма для добавления нового устройства

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/local_storage_service.dart';
import '../../models/device_model.dart';
import '../../widgets/common_widgets.dart';
import 'add_device_success_screen.dart';

class AddDeviceScreen extends StatefulWidget {
  const AddDeviceScreen({Key? key}) : super(key: key);

  @override
  State<AddDeviceScreen> createState() => _AddDeviceScreenState();
}

class _AddDeviceScreenState extends State<AddDeviceScreen> {
  final LocalStorageService _storage = LocalStorageService();

  // Контроллеры полей
  final _cityController = TextEditingController();
  final _emailController = TextEditingController();
  final _streamUrlController = TextEditingController();

  // Таймауты (стартовые значения = 1 минута, согласно ТЗ)
  int _listenTimeout = 1;
  int _upDownTimeout = 1;
  int _onlineOfflineTimeout = 1;

  // Флаги
  bool _isUsed = true;        // "Использовать" = отображать на мониторе
  bool _notifyOnSite = false; // "Оповещать на сайте" = push + звук

  // Генерируем демо-токен (в реальности приходит с сервера)
  final String _generatedToken = "a7f3e9c1-5b8d-4f2a-9e6c-7d1b3a5e8f2c";

  final _formKey = GlobalKey<FormState>();

  void _clearForm() {
    _cityController.clear();
    _emailController.clear();
    _streamUrlController.clear();
    setState(() {
      _listenTimeout = 1;
      _upDownTimeout = 1;
      _onlineOfflineTimeout = 1;
      _isUsed = true;
      _notifyOnSite = false;
    });
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      final newDevice = Device(
        city: _cityController.text.trim(),
        email: _emailController.text.trim(),
        token: _generatedToken,
        streamUrl: _streamUrlController.text.trim().isEmpty ? null : _streamUrlController.text.trim(),
        listenTimeout: _listenTimeout,
        upDownTimeout: _upDownTimeout,
        onlineOfflineTimeout: _onlineOfflineTimeout,
        isUsed: _isUsed,
        notifyOnSite: _notifyOnSite,
        isOnline: false, // изначально офлайн
      );

      await _storage.addDevice(newDevice);

      // Переход на экран 3.1 (успешно добавлено)
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const AddDeviceSuccessScreen(isEdit: false),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Tooltip(
          message: 'Устройства: добавление',
          child: const Text(
            'Устройства: добавление',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        // Стрелка назад: обнуляет данные (согласно ТЗ)
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            _clearForm();
            // Возврат к списку устройств
            Navigator.pushReplacementNamed(context, '/devices');
          },
          tooltip: 'Назад (данные будут обнулены)',
        ),
        actions: const [
          LogoutCircleButton(),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 2.1 Город
              const Text('Город', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              TextFormField(
                controller: _cityController,
                decoration: const InputDecoration(
                  hintText: 'Укажите населенный пункт',
                  border: OutlineInputBorder(),
                ),
                maxLength: 255,
                validator: Device.validateCity,
              ),

              const SizedBox(height: 16),

              // 2.3 Токен (неактивное поле с копированием)
              const Text('Токен', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: TextEditingController(text: _generatedToken),
                      enabled: false,
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.grey[200],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.copy),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: _generatedToken));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Токен скопирован в буфер обмена')),
                      );
                    },
                    tooltip: 'Копировать токен',
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // 2.5 Ссылка для прослушивания
              const Text('Ссылка для прослушивания', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              TextFormField(
                controller: _streamUrlController,
                decoration: const InputDecoration(
                  hintText: 'Укажите ссылку на поток online',
                  border: OutlineInputBorder(),
                ),
                maxLength: 255,
              ),

              const SizedBox(height: 16),

              // 2.7 E-mail
              const Text('E-mail для уведомлений', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  hintText: 'Укажите адрес',
                  border: OutlineInputBorder(),
                ),
                maxLength: 255,
                validator: Device.validateEmail,
              ),

              const SizedBox(height: 24),
              const Text('Параметры оповещения', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),

              // 2.9 Таймаут прослушивания
              TimeoutInputWithArrows(
                title: 'Таймаут прослушивания, минуты',
                hint: 'Укажите время прослушивания',
                value: _listenTimeout,
                onChanged: (v) => setState(() => _listenTimeout = v),
              ),

              // 2.11 Таймаут Up/Down
              TimeoutInputWithArrows(
                title: 'Таймаут для оповещения Up/Down, минуты',
                hint: 'Укажите время реагирования',
                value: _upDownTimeout,
                onChanged: (v) => setState(() => _upDownTimeout = v),
              ),

              // 2.13 Таймаут Online/Offline
              TimeoutInputWithArrows(
                title: 'Таймаут для оповещения Online/Offline, минуты',
                hint: 'Укажите время реагирования',
                value: _onlineOfflineTimeout,
                onChanged: (v) => setState(() => _onlineOfflineTimeout = v),
              ),

              const SizedBox(height: 16),

              // 3. Флаги
              Row(
                children: [
                  Checkbox(
                    value: _isUsed,
                    onChanged: (value) => setState(() => _isUsed = value!),
                  ),
                  const Expanded(
                    child: Text('Использовать (отображать станции устройства на странице мониторинга)'),
                  ),
                ],
              ),
              Row(
                children: [
                  Checkbox(
                    value: _notifyOnSite,
                    onChanged: (value) => setState(() => _notifyOnSite = value!),
                  ),
                  const Expanded(
                    child: Text('Оповещать на сайте (показывать push-уведомления и проигрывать звук)'),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Кнопки Создать и Отмена
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _submitForm,
                      child: const Text('Создать'),
                      style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        _clearForm();
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