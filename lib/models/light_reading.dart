class LightReading {
  final double luxValue;
  final DateTime timestamp;

  LightReading({required this.luxValue, required this.timestamp});

  Map<String, dynamic> toJson() {
    return {
      'luxValue': luxValue,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }

  factory LightReading.fromJson(Map<String, dynamic> json) {
    return LightReading(
      luxValue: json['luxValue'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp']),
    );
  }
}
