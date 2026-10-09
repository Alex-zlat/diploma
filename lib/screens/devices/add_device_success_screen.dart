// ЭКРАН 3.1: Устройство успешно добавлено
// ЭКРАН 3.2: Устройство успешно обновлено
// Отображается после успешного создания или обновления устройства

import 'package:flutter/material.dart';
import '../../widgets/common_widgets.dart';
import 'add_device_screen.dart';
import 'devices_screen.dart';

class AddDeviceSuccessScreen extends StatelessWidget {
  final bool isEdit;

  const AddDeviceSuccessScreen({Key? key, this.isEdit = false}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final title = isEdit ? 'Устройства: изменение' : 'Устройства: добавление';
    final successMessage = isEdit ? 'Устройство успешно обновлено' : 'Устройство успешно добавлено';
    final buttonText = isEdit ? 'Назад к редактированию' : 'Назад к добавлению';

    return Scaffold(
      appBar: AppBar(
        title: Tooltip(
          message: title,
          child: Text(
            title,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const DevicesScreen()),
                  (route) => false,
            );
          },
        ),
        actions: const [LogoutCircleButton()],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 80),
            const SizedBox(height: 24),
            Text(
              successMessage,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                if (isEdit) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const DevicesScreen()),
                        (route) => false,
                  );
                } else {
                  // Переход к списку устройств:
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const DevicesScreen()),
                        (route) => false,
                  );
                }
              },
              child: Text(buttonText),
            ),
          ],
        ),
      ),
      bottomNavigationBar: AppBottomNavigationBar(
        currentIndex: 1,
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacementNamed(context, '/monitor');
          } else if (index == 1) {
            // Переход на список устройств:
            Navigator.pushReplacementNamed(context, '/devices');
          } else if (index == 2) {
            Navigator.pushNamed(context, '/profile');
          }
        },
      ),
    );
  }
}