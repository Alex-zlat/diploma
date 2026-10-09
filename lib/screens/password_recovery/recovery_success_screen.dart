// ЭКРАН ВОССТАНОВЛЕНИЯ ПАРОЛЯ 4
// Заголовок "Пароль обновлен"
// Сообщение об успехе
// Иконка для перехода на экран верификации

import 'package:flutter/material.dart';

class RecoverySuccessScreen extends StatelessWidget {
  const RecoverySuccessScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Пароль обновлен',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        // Стрелка назад → на экран верификации (согласно твоему ответу)
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // Возврат на экран верификации
            Navigator.pushNamedAndRemoveUntil(context, '/verification', (route) => false);
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.check_circle_outline,
              size: 100,
              color: Colors.green,
            ),
            const SizedBox(height: 24),

            // Заголовок второго уровня
            const Text(
              'Процесс выполнен успешно',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Текст более мелким шрифтом
            Text(
              'Ваш пароль был обновлен. Войдите в приложение',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 48),

            // Иконка для перехода на экран верификации
            InkWell(
              onTap: () {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/verification',
                      (route) => false,
                );
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.login,
                  size: 40,
                  color: Colors.deepPurple,
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Войти',
              style: TextStyle(color: Colors.deepPurple),
            ),
          ],
        ),
      ),
    );
  }
}