class ProximityReading {
  final double distance;
  final DateTime timestamp;

  ProximityReading({required this.distance, required this.timestamp});

  Map<String, dynamic> toJson() {
    return {
      'distance': distance,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }

  factory ProximityReading.fromJson(Map<String, dynamic> json) {
    return ProximityReading(
      distance: json['distance'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp']),
    );
  }
}
