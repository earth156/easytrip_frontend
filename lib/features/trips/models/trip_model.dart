/// Model สำหรับข้อมูลสรุปของทริปแต่ละรายการที่แสดงในหน้า Home
class Trip {
  final String id;
  final String title;
  final String destination;
  final int daysCount;
  final DateTime createdAt;
  final double? budget;
  final String? imageUrl;
  final String? status; // เช่น 'completed', 'processing', 'failed'

  Trip({
    required this.id,
    required this.title,
    required this.destination,
    required this.daysCount,
    required this.createdAt,
    this.budget,
    this.imageUrl,
    this.status,
  });

  /// Factory constructor สำหรับสร้าง instance ของ Trip จาก JSON (Map)
  factory Trip.fromJson(Map<String, dynamic> json) {
    final budgetValue = json['budget'];
    return Trip(
      id: json['id'] as String,
      title: json['title'] as String? ?? 'ไม่มีชื่อทริป',
      destination: json['destination'] as String? ?? 'ไม่มีจุดหมาย',
      daysCount: json['days_count'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      budget: budgetValue is num ? budgetValue.toDouble() : null,
      imageUrl: json['image_url'] as String?,
      status: json['status'] as String?,
    );
  }
}
