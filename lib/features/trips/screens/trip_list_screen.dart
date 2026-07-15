import 'package:easytrip_frontend/features/trips/controller/trip_controller.dart';
import 'package:flutter/material.dart';
import '../models/trip_model.dart';
import '../../../core/utils/custom_dialogs.dart';
import 'trip_detail_screen.dart';

class TripListScreen extends StatefulWidget {
  const TripListScreen({super.key});

  @override
  State<TripListScreen> createState() => _TripListScreenState();
}

class _TripListScreenState extends State<TripListScreen> {
  final TripController _tripController = TripController();
  late Future<List<Trip>> _tripsFuture;

  @override
  void initState() {
    super.initState();
    _loadTrips();
  }

  void _loadTrips() {
    setState(() {
      _tripsFuture = _tripController.getMyTrips();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ทริปของฉัน'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTrips,
            tooltip: 'โหลดข้อมูลใหม่',
          ),
        ],
      ),
      body: FutureBuilder<List<Trip>>(
        future: _tripsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _buildErrorState(snapshot.error.toString());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyState();
          }

          final trips = snapshot.data!;
          return _buildTripListView(trips);
        },
      ),
    );
  }

  // --- Widget สำหรับแสดงผลเมื่อไม่มีข้อมูลทริป (Empty State) ---
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ไอคอนกระเป๋าเดินทาง
            Icon(Icons.card_travel, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            // ข้อความ
            const Text(
              'ยังไม่มีแพลนการเดินทางเลย',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            // ปุ่มสำหรับสร้างทริป
            ElevatedButton(
              onPressed: () {
                // TODO: ในอนาคตจะเชื่อมต่อไปยังหน้าสร้างทริป
                print('Navigate to create trip screen');
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
              ),
              child: const Text('สร้างทริปแรกของคุณ'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 80, color: Colors.red.shade300),
            const SizedBox(height: 16),
            const Text(
              'เกิดข้อผิดพลาด',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadTrips,
              child: const Text('ลองอีกครั้ง'),
            ),
          ],
        ),
      ),
    );
  }

  // --- Widget สำหรับแสดงรายการทริป (List View) ---
  Widget _buildTripListView(List<Trip> trips) {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0), // เพิ่ม padding รอบๆ ListView
      itemCount: trips.length,
      itemBuilder: (context, index) {
        final trip = trips[index];

        // --- ส่วนของการปัดเพื่อลบ (Swipe to Delete) ---
        return Dismissible(
          key: Key(trip.id),

          // --- ส่วนของการยืนยันก่อนลบ ---
          // confirmDismiss จะถูกเรียก "ก่อน" onDismissed
          // เราจะเรียกใช้ Custom Dialog ที่สร้างไว้ใน Utility
          confirmDismiss: (direction) async {
            final bool? didRequestDelete =
                await CustomDialogs.showConfirmDeleteDialog(
                  context: context,
                  title: "ยืนยันการลบทริป?",
                  message: "ข้อมูลทริป '${trip.title}' จะถูกลบอย่างถาวร",
                );

            if (didRequestDelete ?? false) {
              try {
                await _tripController.deleteTrip(trip.id);
                return true; // API call was successful, allow dismiss.
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('ลบทริปล้มเหลว: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
                return false; // API call failed, do not dismiss.
              }
            }
            return false; // User cancelled the dialog.
          },

          // onDismissed: จะถูกเรียกเมื่อผู้ใช้ปัดจนสุด
          onDismissed: (direction) {
            // แสดง SnackBar เพื่อแจ้งผู้ใช้ว่าลบสำเร็จ
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('${trip.title} ถูกลบแล้ว')));
            // It's good practice to refresh the list from the source of truth
            // after a deletion to handle any potential inconsistencies.
            _loadTrips();
          },

          // direction: กำหนดทิศทางการปัด (ในที่นี้คือปัดจากขวาไปซ้าย)
          direction: DismissDirection.endToStart,

          // background: คือ Widget ที่จะแสดงเป็นพื้นหลัง "ขณะที่กำลังปัด"
          background: Container(
            color: Colors.red,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            margin: const EdgeInsets.only(bottom: 12),
            child: const Icon(Icons.delete, color: Colors.white),
          ),

          // child: คือ Widget หลักที่จะแสดงผลปกติ (การ์ดทริป)
          child: _buildTripCard(trip),
        );
      },
    );
  }

  // --- Widget สำหรับสร้างการ์ดทริปแต่ละอัน ---
  Widget _buildTripCard(Trip trip) {
    return GestureDetector(
      onTap: () {
        // นำทางไปยังหน้า TripDetailScreen เมื่อกดที่การ์ด
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TripDetailScreen(tripId: trip.id),
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 12), // ระยะห่างด้านล่างของการ์ด
        clipBehavior: Clip.antiAlias, // ทำให้รูปภาพไม่ล้นขอบมนของการ์ด
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ส่วนของรูปภาพ
            // TODO: เพิ่ม cover_image_url ในการดึงข้อมูลและแสดงผลที่นี่
            Image.network(
              'https://images.unsplash.com/photo-1507525428034-b723a996f3ea?q=80&w=1170', // Placeholder
              height: 150,
              width: double.infinity,
              fit: BoxFit.cover,
              // เพิ่ม loadingBuilder เพื่อแสดงสถานะขณะโหลดรูป
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  height: 150,
                  color: Colors.grey[200],
                  child: const Center(child: CircularProgressIndicator()),
                );
              },
              // เพิ่ม errorBuilder เพื่อแสดงผลกรณีโหลดรูปไม่สำเร็จ
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 150,
                  color: Colors.grey[200],
                  child: const Icon(
                    Icons.broken_image,
                    color: Colors.grey,
                    size: 40,
                  ),
                );
              },
            ),
            // ส่วนของรายละเอียด
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    trip.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${trip.daysCount} วัน',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      Text(
                        '~฿${trip.budget?.toStringAsFixed(0) ?? 'N/A'}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
