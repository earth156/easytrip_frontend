/// Model สำหรับรวบรวมข้อมูลจากฟอร์มสร้างทริปเพื่อส่งไปยัง Backend
class TripCreationData {
  final String country;
  final String province;
  final DateTime startDate;
  final DateTime endDate;
  final int travelers;
  final double budget;
  final String travelStyle;

  TripCreationData({
    required this.country,
    required this.province,
    required this.startDate,
    required this.endDate,
    required this.travelers,
    required this.budget,
    required this.travelStyle,
  });

  /// แปลง Object เป็น JSON เพื่อส่งไปใน body ของ HTTP request
  Map<String, dynamic> toJson() => {
    'country': country,
    'province': province,
    'startDate': startDate.toIso8601String(),
    'endDate': endDate.toIso8601String(),
    'travelers': travelers,
    'budget': budget,
    'travelStyle': travelStyle,
  };
}
