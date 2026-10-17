// ЭКРАН РЕГИСТРАЦИИ 2
// Информационный экран: пользователю предлагают подтвердить email
// Кнопка-заглушка "Я подтвердил email" (в реальном приложении — deep link)

import 'package:flutter/material.dart';
import 'registration_success_screen.dart';

class RegistrationConfirmScreen extends StatelessWidget {
  final String email;

  const RegistrationConfirmScreen({
    Key? key,
    required this.email,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Регистрация',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        // Стрелка назад → Экран 1
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.mark_email_read_outlined,
              size: 80,
              color: Colors.deepPurple,
            ),
            const SizedBox(height: 24),

            // Заголовок
            const Text(
              'Откройте поступившее на почту письмо',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Текст более мелким шрифтом
            Text(
              'Подтвердите электронный ящик',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            // Email пользователя
            Text(
              email,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.deepPurple,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 48),

            // Кнопка-заглушка (в реальном приложении будет deep link)
            OutlinedButton.icon(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RegistrationSuccessScreen(email: email),
                  ),
                );
              },
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Я подтвердил email (заглушка)'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
              ),
            ),

            const SizedBox(height: 16),

            // Комментарий для разработчика
            Text(
              'В реальном приложении: после нажатия ссылки в письме\n'
                  'приложение откроется на экране подтверждения',
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/* КОД ДЛЯ РЕАЛЬНОГО API (deep link)
 *
 * Пользователь получает письмо со ссылкой вида:
 * radiomonitor://verify-email?email=user@example.com&token=abc123
 *
 * После нажатия приложение открывается, извлекает email и token,
 * отправляет запрос на сервер для подтверждения,
 * затем показывает экран RegistrationSuccessScreen
 *
 * В main.dart добавить обработку deep link:
 *
 * class MyApp extends StatelessWidget {
 *   @override
 *   Widget build(BuildContext context) {
 *     return GetMaterialApp.router(
 *       routerDelegate: router.routerDelegate,
 *       routeInformationParser: router.routeInformationParser,
 *       title: 'Radio Monitor',
 *     );
 *   }
 * }
 */