/// Model สำหรับข้อมูลทริปที่แสดงในหน้า "ทริปของฉัน"
class Trip {
  final String id;
  final String title;
  final String destination;
  final int daysCount;
  final double? budget;
  final DateTime createdAt;

  Trip({
    required this.id,
    required this.title,
    required this.destination,
    required this.daysCount,
    this.budget,
    required this.createdAt,
  });

  factory Trip.fromJson(Map<String, dynamic> json) {
    return Trip(
      id: json['id'] as String,
      title: json['title'] as String,
      destination: json['destination'] as String,
      daysCount: json['days_count'] as int,
      budget: (json['budget'] as num?)?.toDouble(),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
