// ЭКРАН ВОССТАНОВЛЕНИЯ ПАРОЛЯ 2
// Информационный экран: пользователю предлагают проверить почту

import 'package:flutter/material.dart';
import 'recovery_new_password_screen.dart';

class RecoveryCheckEmailScreen extends StatelessWidget {
  final String email;

  const RecoveryCheckEmailScreen({
    Key? key,
    required this.email,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Сброс пароля',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        // Стрелка назад возвращает на экран 1
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

            // Основная надпись
            const Text(
              'Сброс пароля',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Пояснение более мелким шрифтом
            Text(
              'Пожалуйста, проверьте ваш e-mail для сброса пароля',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
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

            // Временная кнопка-заглушка (в реальном приложении будет deep link)
            // В ТЗ: пользователь сам идет в почту, кликает по ссылке и открывается экран 3
            OutlinedButton.icon(
              onPressed: () {
                // В реальном приложении: ссылка из письма открывает приложение на экране 3
                // Сейчас делаем переход вручную для демонстрации
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RecoveryNewPasswordScreen(email: email),
                  ),
                );
              },
              icon: const Icon(Icons.open_in_browser),
              label: const Text('Я перешел в почту (заглушка)'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),

            const SizedBox(height: 16),

            // Комментарий для самого себя (разработчика)
            Text(
              'В реальном приложении: после нажатия ссылки в письме\n'
                  'приложение откроется на экране ввода нового пароля',
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/* === КОД ДЛЯ РЕАЛЬНОГО API (deep link) ===
 *
 * В файле android/app/src/main/AndroidManifest.xml:
 *
 * <intent-filter>
 *   <action android:name="android.intent.action.VIEW" />
 *   <category android:name="android.intent.category.DEFAULT" />
 *   <category android:name="android.intent.category.BROWSABLE" />
 *   <data android:scheme="radiomonitor" android:host="reset-password" />
 * </intent-filter>
 *
 * В iOS: Info.plist с URL Scheme
 *
 * В письме ссылка: radiomonitor://reset-password?email=user@example.com&token=abc123
 *
 * В main.dart обработка deep link:
 *
 * GetMaterialApp.router(
 *   routerDelegate: router.routerDelegate,
 *   routeInformationParser: router.routeInformationParser,
 * )
 *
 * При переходе по ссылке извлекаем email и token,
 * показываем экран RecoveryNewPasswordScreen
 */