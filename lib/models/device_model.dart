// Модель данных "Устройство"

class Device {
  final int? id;                    // уникальный ID (от сервера или временный)
  final String city;                // Город (обязательное, макс 255 символов)
  final String email;               // E-mail для уведомлений (обязательное)
  final String? token;              // Токен устройства (только для чтения, генерируется)
  final String? streamUrl;          // Ссылка для прослушивания (опционально)

  // Таймауты в минутах (стартовое значение по умолчанию = 1 минута)
  final int listenTimeout;          // Таймаут прослушивания (от 0 минут)
  final int upDownTimeout;          // Таймаут для оповещения Up/Down (от 0 минут)
  final int onlineOfflineTimeout;   // Таймаут для оповещения Online/Offline (от 0 минут)

  // Флаги
  final bool isUsed;                // "Использовать" = отображать на странице мониторинга
  final bool notifyOnSite;          // "Оповещать на сайте" = push + звук

  // Статус (приходит с сервера в реальном времени)
  final bool isOnline;              // Online/Offline устройство

  Device({
    this.id,
    required this.city,
    required this.email,
    this.token,
    this.streamUrl,
    this.listenTimeout = 1,         // По умолчанию 1 минута
    this.upDownTimeout = 1,         // По умолчанию 1 минута
    this.onlineOfflineTimeout = 1,  // По умолчанию 1 минута
    this.isUsed = true,             // По умолчанию true (использовать)
    this.notifyOnSite = false,      // По умолчанию false (требует разрешений)
    this.isOnline = false,
  });

  // Копирование с изменениями (для редактирования)
  Device copyWith({
    int? id,
    String? city,
    String? email,
    String? token,
    String? streamUrl,
    int? listenTimeout,
    int? upDownTimeout,
    int? onlineOfflineTimeout,
    bool? isUsed,
    bool? notifyOnSite,
    bool? isOnline,
  }) {
    return Device(
      id: id ?? this.id,
      city: city ?? this.city,
      email: email ?? this.email,
      token: token ?? this.token,
      streamUrl: streamUrl ?? this.streamUrl,
      listenTimeout: listenTimeout ?? this.listenTimeout,
      upDownTimeout: upDownTimeout ?? this.upDownTimeout,
      onlineOfflineTimeout: onlineOfflineTimeout ?? this.onlineOfflineTimeout,
      isUsed: isUsed ?? this.isUsed,
      notifyOnSite: notifyOnSite ?? this.notifyOnSite,
      isOnline: isOnline ?? this.isOnline,
    );
  }

  // Преобразование в JSON (для отправки на сервер или сохранения)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'city': city,
      'email': email,
      'token': token,
      'streamUrl': streamUrl,
      'listenTimeout': listenTimeout,
      'upDownTimeout': upDownTimeout,
      'onlineOfflineTimeout': onlineOfflineTimeout,
      'isUsed': isUsed,
      'notifyOnSite': notifyOnSite,
      'isOnline': isOnline,
    };
  }

  // Создание из JSON (с сервера)
  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
      id: json['id'],
      city: json['city'] ?? '',
      email: json['email'] ?? '',
      token: json['token'],
      streamUrl: json['streamUrl'],
      listenTimeout: json['listenTimeout'] ?? 1,
      upDownTimeout: json['upDownTimeout'] ?? 1,
      onlineOfflineTimeout: json['onlineOfflineTimeout'] ?? 1,
      isUsed: json['isUsed'] ?? true,
      notifyOnSite: json['notifyOnSite'] ?? false,
      isOnline: json['isOnline'] ?? false,
    );
  }

  // Валидация полей
  static String? validateCity(String? value) {
    if (value == null || value.isEmpty) {
      return 'Укажите населенный пункт';
    }
    if (value.length > 255) {
      return 'Не более 255 символов';
    }
    return null;
  }

  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Укажите адрес почты';
    }
    if (value.length > 255) {
      return 'Не более 255 символов';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Введите корректный email';
    }
    return null;
  }
}