// ЭКРАН 5: Устройство: добавление по токену
// Добавление устройства другого пользователя по токену (гостевой доступ)

import 'package:flutter/material.dart';
import '../../services/local_storage_service.dart';
import '../../models/device_model.dart';
import '../../widgets/common_widgets.dart';
import 'add_device_success_screen.dart';

class AddDeviceByTokenScreen extends StatefulWidget {
  const AddDeviceByTokenScreen({Key? key}) : super(key: key);

  @override
  State<AddDeviceByTokenScreen> createState() => _AddDeviceByTokenScreenState();
}

class _AddDeviceByTokenScreenState extends State<AddDeviceByTokenScreen> {
  final LocalStorageService _storage = LocalStorageService();
  final TextEditingController _tokenController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  Future<void> _addByToken() async {
    if (_formKey.currentState!.validate()) {
      // В реальности: отправляем токен на сервер, получаем данные устройства
      // Пока создаем демо-устройство по токену
      final demoDevice = Device(
        city: 'Устройство по токену (гостевой доступ)',
        email: 'guest@example.com',
        token: _tokenController.text,
        isUsed: true,
        notifyOnSite: false,
        isOnline: false,
      );

      await _storage.addDevice(demoDevice);

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
          message: 'Устройство: добавление по токену',
          child: const Text(
            'Устройство: по токену',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
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
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Введите токен', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _tokenController,
                decoration: const InputDecoration(
                  hintText: 'Укажите токен',
                  border: OutlineInputBorder(),
                ),
                maxLength: 255,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Введите токен';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _addByToken,
                      child: const Text('Добавить'),
                      style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
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
          if (index == 0) {
            Navigator.pushReplacementNamed(context, '/monitor');
          } else if (index == 1) {
            Navigator.pushReplacementNamed(context, '/devices');
          } else if (index == 2) {
            Navigator.pushNamed(context, '/profile');
          }
        },
      ),
    );
  }
}