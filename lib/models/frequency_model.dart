// Модель данных "Частота" (радиостанция)

class Frequency {
  final int? id;                    // Уникальный ID
  final int deviceId;               // ID устройства, к которому относится
  final double frequency;           // Номинал частоты (например, 89.3)
  final String name;                // Название радиостанции
  final String email;               // E-mail для уведомлений по этой частоте
  final String? streamUrl;

  // Пороговые значения (для мониторинга)
  final int thresholdRSSI;          // Порог RSSI (условные единицы)
  final int thresholdVolume;        // Порог Volume (условные единицы 0-255)
  final int thresholdLR;            // Порог разницы L/R (%)
  final bool trackCapture;          // Флажок "Порог Tuned/Stereo" (отслеживать несущую)

  // Текущие значения (приходят с сервера в реальном времени)
  final bool isUp;                  // Up = частота в эфире, Down = нет
  final int? currentRSSI;           // Текущее RSSI
  final int? currentVolume;         // Текущий Volume
  final int? currentCapture;        // Текущий захват несущей (1 или 0)


  Frequency({
    this.id,
    required this.deviceId,
    required this.frequency,
    required this.name,
    required this.email,
    this.thresholdRSSI = 0,
    this.thresholdVolume = 0,
    this.thresholdLR = 0,
    this.trackCapture = false,
    this.isUp = false,
    this.currentRSSI,
    this.currentVolume,
    this.currentCapture,
    this.streamUrl,
  });

  Frequency copyWith({
    int? id,
    int? deviceId,
    double? frequency,
    String? name,
    String? email,
    int? thresholdRSSI,
    int? thresholdVolume,
    int? thresholdLR,
    bool? trackCapture,
    bool? isUp,
    int? currentRSSI,
    int? currentVolume,
    int? currentCapture,
    String? streamUrl,
  }) {
    return Frequency(
      id: id ?? this.id,
      deviceId: deviceId ?? this.deviceId,
      frequency: frequency ?? this.frequency,
      name: name ?? this.name,
      email: email ?? this.email,
      thresholdRSSI: thresholdRSSI ?? this.thresholdRSSI,
      thresholdVolume: thresholdVolume ?? this.thresholdVolume,
      thresholdLR: thresholdLR ?? this.thresholdLR,
      trackCapture: trackCapture ?? this.trackCapture,
      isUp: isUp ?? this.isUp,
      currentRSSI: currentRSSI ?? this.currentRSSI,
      currentVolume: currentVolume ?? this.currentVolume,
      currentCapture: currentCapture ?? this.currentCapture,
      streamUrl: streamUrl,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'deviceId': deviceId,
      'frequency': frequency,
      'name': name,
      'email': email,
      'thresholdRSSI': thresholdRSSI,
      'thresholdVolume': thresholdVolume,
      'thresholdLR': thresholdLR,
      'trackCapture': trackCapture,
      'isUp': isUp,
      'currentRSSI': currentRSSI,
      'currentVolume': currentVolume,
      'currentCapture': currentCapture,
      'streamUrl': streamUrl,
    };
  }

  factory Frequency.fromJson(Map<String, dynamic> json) {
    return Frequency(
      id: json['id'],
      deviceId: json['deviceId'] ?? 0,
      frequency: (json['frequency'] ?? 0).toDouble(),
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      thresholdRSSI: json['thresholdRSSI'] ?? 0,
      thresholdVolume: json['thresholdVolume'] ?? 0,
      thresholdLR: json['thresholdLR'] ?? 0,
      trackCapture: json['trackCapture'] ?? false,
      isUp: json['isUp'] ?? false,
      currentRSSI: json['currentRSSI'],
      currentVolume: json['currentVolume'],
      currentCapture: json['currentCapture'],
      streamUrl: json['streamUrl'],
    );
  }

  // Валидация
  static String? validateFrequency(String? value) {
    if (value == null || value.isEmpty) {
      return 'Укажите частоту';
    }
    final freq = double.tryParse(value);
    if (freq == null || freq < 80 || freq > 108) {
      return 'Введите корректную FM-частоту (80-108 МГц)';
    }
    return null;
  }

  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Укажите название радиостанции';
    }
    if (value.length > 255) {
      return 'Не более 255 символов';
    }
    return null;
  }
}