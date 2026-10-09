// ЭКРАН 4: Устройства: изменение
// Форма для редактирования существующего устройства
// Открывается из экрана 1 по ссылке "Изменить"

import 'package:flutter/material.dart';
import '../../services/local_storage_service.dart';
import '../../models/device_model.dart';
import '../../widgets/common_widgets.dart';
import 'add_device_success_screen.dart';

class EditDeviceScreen extends StatefulWidget {
  final Device? device; // если null, то создаем новый (но этот экран для редактирования)

  const EditDeviceScreen({Key? key, required this.device}) : super(key: key);

  @override
  State<EditDeviceScreen> createState() => _EditDeviceScreenState();
}

class _EditDeviceScreenState extends State<EditDeviceScreen> {
  final LocalStorageService _storage = LocalStorageService();

  late TextEditingController _cityController;
  late TextEditingController _emailController;

  late int _listenTimeout;
  late int _upDownTimeout;
  late int _onlineOfflineTimeout;

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    // Заполняем текущими значениями устройства
    _cityController = TextEditingController(text: widget.device!.city);
    _emailController = TextEditingController(text: widget.device!.email);
    _listenTimeout = widget.device!.listenTimeout;
    _upDownTimeout = widget.device!.upDownTimeout;
    _onlineOfflineTimeout = widget.device!.onlineOfflineTimeout;
  }

  Future<void> _saveChanges() async {
    if (_formKey.currentState!.validate()) {
      final updatedDevice = widget.device!.copyWith(
        city: _cityController.text.trim(),
        email: _emailController.text.trim(),
        listenTimeout: _listenTimeout,
        upDownTimeout: _upDownTimeout,
        onlineOfflineTimeout: _onlineOfflineTimeout,
      );

      await _storage.updateDevice(updatedDevice);

      // Переход на экран 3.2 (успешно обновлено)
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const AddDeviceSuccessScreen(isEdit: true),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Tooltip(
          message: 'Устройства: изменение',
          child: const Text(
            'Устройства: изменение',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // Возврат к списку устройств
            Navigator.pushReplacementNamed(context, '/devices');
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
              // Город
              const Text('Город', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              TextFormField(
                controller: _cityController,
                decoration: const InputDecoration(border: OutlineInputBorder()),
                maxLength: 255,
                validator: Device.validateCity,
              ),

              const SizedBox(height: 16),

              // E-mail
              const Text('E-mail для уведомлений', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(border: OutlineInputBorder()),
                maxLength: 255,
                validator: Device.validateEmail,
              ),

              const SizedBox(height: 24),
              const Text('Параметры оповещения', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),

              TimeoutInputWithArrows(
                title: 'Таймаут прослушивания, минуты',
                hint: 'Укажите время прослушивания',
                value: _listenTimeout,
                onChanged: (v) => setState(() => _listenTimeout = v),
              ),

              TimeoutInputWithArrows(
                title: 'Таймаут для оповещения Up/Down, минуты',
                hint: 'Укажите время реагирования',
                value: _upDownTimeout,
                onChanged: (v) => setState(() => _upDownTimeout = v),
              ),

              TimeoutInputWithArrows(
                title: 'Таймаут для оповещения Online/Offline, минуты',
                hint: 'Укажите время реагирования',
                value: _onlineOfflineTimeout,
                onChanged: (v) => setState(() => _onlineOfflineTimeout = v),
              ),

              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _saveChanges,
                      child: const Text('Сохранить'),
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
          if (index == 0) Navigator.pushReplacementNamed(context, '/monitor');
          if (index == 2) Navigator.pushNamed(context, '/profile');
        },
      ),
    );
  }
}