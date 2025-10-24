class CheckInEntry {
  const CheckInEntry({
    required this.id,
    required this.timestamp,
  });

  final String id;
  final DateTime timestamp;

  factory CheckInEntry.fromJson(Map<String, dynamic> json) {
    return CheckInEntry(
      id: json['id'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'timestamp': timestamp.toIso8601String(),
      };
}
