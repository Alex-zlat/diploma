import 'dart:convert';
import 'dart:html' as html;

class StorageService {
  static const String _usersKey = 'db_users';

  static void saveUsers(List<String> users) {
    html.window.localStorage[_usersKey] = jsonEncode(users);
    print('💾 Сохранено ${users.length} пользователей');
  }

  static List<String> getUsers() {
    final data = html.window.localStorage[_usersKey];
    print('📖 Чтение из localStorage: "$data"');

    if (data == null || data.isEmpty) {
      return [];
    }

    try {
      final decoded = jsonDecode(data);
      if (decoded is List) {
        return decoded.map((e) => e.toString()).toList();
      }
      return [];
    } catch (e) {
      print('❌ Ошибка чтения пользователей: $e');

      // Поддержка старого формата (если там еще старые данные)
      if (data.contains('|')) {
        return [data];
      }
      return [];
    }
  }

  static void clearUsers() {
    html.window.localStorage.remove(_usersKey);
    print('🗑️ Пользователи удалены');
  }
}