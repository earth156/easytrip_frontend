import 'package:easytrip_frontend/features/trips/controller/trip_controller.dart';
import 'package:flutter/material.dart';

class TripDetailScreen extends StatefulWidget {
  final String tripId;
  const TripDetailScreen({super.key, required this.tripId});

  @override
  State<TripDetailScreen> createState() => _TripDetailScreenState();
}

class _TripDetailScreenState extends State<TripDetailScreen> {
  final TripController _tripController = TripController();
  late Future<Map<String, dynamic>> _tripDetailsFuture;

  @override
  void initState() {
    super.initState();
    _tripDetailsFuture = _tripController.getTripDetails(widget.tripId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<Map<String, dynamic>>(
        future: _tripDetailsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('เกิดข้อผิดพลาด: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('ไม่พบข้อมูลทริป'));
          }

          // --- FIX: ทำให้แอปทนทานต่อการที่ API ส่งข้อมูลกลับมาเป็น List ---
          // จัดการกรณีที่ API อาจส่งข้อมูลกลับมาเป็น List แทนที่จะเป็น Object เดียว
          final dynamic rawData = snapshot.data!;
          Map<String, dynamic> tripData;

          if (rawData is List) {
            // ถ้า API ส่งกลับมาเป็น List, ให้ใช้ข้อมูลตัวแรกสุด
            // และแสดงคำเตือนใน console เพื่อให้ทราบว่า backend มีปัญหา
            debugPrint(
              "Warning: getTripDetails returned a List, expected a Map. Using the first element.",
            );
            if (rawData.isEmpty) {
              return const Center(
                child: Text('ไม่พบข้อมูลทริป (ได้ข้อมูลเป็น List ว่าง)'),
              );
            }
            tripData = rawData.first as Map<String, dynamic>;
          } else {
            // กรณีที่ API ทำงานถูกต้อง
            tripData = rawData as Map<String, dynamic>;
          }

          return _buildTripDetailContent(context, tripData);
        },
      ),
    );
  }

  Widget _buildTripDetailContent(
    BuildContext context,
    Map<String, dynamic> tripData,
  ) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context, tripData),
          SliverToBoxAdapter(child: _buildSummaryCard(context, tripData)),
          ..._buildItinerarySlivers(context, tripData),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          /* TODO: Implement map view */
        },
        label: const Text('ดูเส้นทางบนแผนที่'),
        icon: const Icon(Icons.map_outlined),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildSliverAppBar(
    BuildContext context,
    Map<String, dynamic> tripData,
  ) {
    return SliverAppBar(
      expandedHeight: 250.0, // ความสูงของ AppBar เมื่อขยายเต็มที่
      pinned: true, // ปักหมุด AppBar ไว้ด้านบนเมื่อ scroll ขึ้น
      stretch: true, // ให้สามารถยืดได้เมื่อ scroll ลงเกิน
      backgroundColor: Theme.of(
        context,
      ).primaryColor, // สีพื้นหลังเมื่อ AppBar หดลง
      flexibleSpace: FlexibleSpaceBar(
        // Title จะแสดงขึ้นมาเมื่อ AppBar หดลงเท่านั้น
        title: Text(
          tripData['title'] ?? 'รายละเอียดทริป',
          style: const TextStyle(fontSize: 16, color: Colors.white),
        ),
        centerTitle: true,
        titlePadding: const EdgeInsets.only(bottom: 16),
        // background คือ Widget ที่จะแสดงเป็นพื้นหลัง (รูปภาพ)
        // TODO: ใช้ cover_image_url จาก tripData เมื่อมีในฐานข้อมูล
        background: Image.network(
          'https://images.unsplash.com/photo-1507525428034-b723a996f3ea?q=80&w=1170',
          fit: BoxFit.cover,
          color: Colors.black.withOpacity(0.3),
          colorBlendMode: BlendMode.darken,
        ),
      ),
    );
  }

  Widget _buildSummaryCard(
    BuildContext context,
    Map<String, dynamic> tripData,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tripData['title'] ?? 'N/A',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryItem(
                Icons.calendar_today_outlined,
                '${tripData['days_count'] ?? 'N/A'} วัน',
              ),
              _buildSummaryItem(
                Icons.account_balance_wallet_outlined,
                '~฿${(tripData['budget'] as num?)?.toStringAsFixed(0) ?? 'N/A'}',
              ),
              _buildSummaryItem(Icons.mood, tripData['travel_style'] ?? 'N/A'),
            ],
          ),
        ],
      ),
    );
  }

  // Widget ย่อยสำหรับแสดงข้อมูลใน Summary Card
  Widget _buildSummaryItem(IconData icon, String text) {
    return Column(
      children: [
        Icon(icon, color: Theme.of(context).primaryColor, size: 28),
        const SizedBox(height: 4),
        Text(text, style: const TextStyle(fontSize: 14)),
      ],
    );
  }

  // --- ฟังก์ชันสำหรับสร้าง List ของ Slivers สำหรับ Itinerary ---
  List<Widget> _buildItinerarySlivers(
    BuildContext context,
    Map<String, dynamic> tripData,
  ) {
    final List<Widget> slivers = [];
    // ดึงข้อมูล itinerary จาก JSON ที่ AI สร้าง
    // --- FIX: แก้ไขการดึงข้อมูล itinerary ให้ถูกต้อง ---
    final List itinerary = (tripData['itinerary'] as List<dynamic>?) ?? [];

    for (var dayData in itinerary) {
      // เพิ่ม Header ของวัน (เช่น "วันที่ 1")
      slivers.add(
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Day ${dayData['day']} | ${dayData['date']}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      );

      // เพิ่ม SliverList ที่มีรายการสถานที่ของวันนั้นๆ
      slivers.add(
        SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
            final activity =
                dayData['activities'][index] as Map<String, dynamic>;
            return ActivityCardWidget(
              time: activity['timeSlot'] as String?,
              name: activity['placeName'] as String?,
              description: activity['aiRecommendationReason'] as String?,
              activityType: activity['activityType'] as String?,
              imageUrl: activity['imageUrl'] as String?,
            );
          }, childCount: dayData['activities'].length),
        ),
      );
    }
    return slivers;
  }
}

/// --- Widget ที่แยกออกมาสำหรับแสดงการ์ดของแต่ละกิจกรรม ---
class ActivityCardWidget extends StatefulWidget {
  const ActivityCardWidget({
    super.key,
    this.time,
    this.name,
    this.description,
    this.activityType,
    this.imageUrl,
  });

  final String? time;
  final String? name;
  final String? description;
  final String? activityType;
  final String? imageUrl;

  @override
  State<ActivityCardWidget> createState() => _ActivityCardWidgetState();
}

class _ActivityCardWidgetState extends State<ActivityCardWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  IconData _getIconForActivityType(String type) {
    if (type.contains('อาหาร') || type.contains('food')) {
      return Icons.restaurant_menu_outlined;
    } else if (type.contains('ท่องเที่ยว') || type.contains('landmark')) {
      return Icons.camera_alt_outlined;
    } else if (type.contains('ชอปปิ้ง') || type.contains('shopping')) {
      return Icons.shopping_bag_outlined;
    } else if (type.contains('คาเฟ่') || type.contains('cafe')) {
      return Icons.local_cafe_outlined;
    } else if (type.contains('ธรรมชาติ') || type.contains('nature')) {
      return Icons.eco_outlined;
    } else if (type.contains('ที่พัก') || type.contains('hotel')) {
      return Icons.hotel_outlined;
    }
    return Icons.attractions_outlined;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ส่วนของเวลา
          Text(
            widget.time ?? 'N/A',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black54,
            ),
          ),
          const SizedBox(width: 16),

          // เส้น Timeline แนวตั้ง (ทำแบบง่ายๆ)
          Column(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
              Container(
                width: 2,
                height: 80, // ความสูงของเส้นเชื่อม (ปรับได้)
                color: Colors.grey.shade300,
              ),
            ],
          ),
          const SizedBox(width: 16),

          // ส่วนของการ์ดเนื้อหา
          Expanded(
            child: Card(
              margin: const EdgeInsets.all(0),
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(
                        context,
                      ).primaryColor.withOpacity(0.1),
                      child: Icon(
                        _getIconForActivityType(widget.activityType ?? ''),
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    title: Text(
                      widget.name ?? 'N/A',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      widget.description ?? '',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
