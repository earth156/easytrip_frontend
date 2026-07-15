import 'package:easytrip_frontend/features/profile/screens/profile_screen.dart';
import 'package:flutter/material.dart';
import '../../../core/services/session_service.dart';
import 'trip_list_screen.dart'; // Import หน้าจอ TripListScreen

// HomeScreen จะเป็น StatefulWidget เพราะต้องจัดการ "สถานะ" ของ Tab ที่ถูกเลือก
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // สร้าง State เพื่อเก็บค่า index ของ Tab ที่ถูกเลือกในปัจจุบัน
  int _selectedIndex = 0;
  String _userName = 'นักเดินทาง'; // Default name
  final SessionService _sessionService = SessionService();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() async {
    final name = await _sessionService.getUserName();
    if (name != null && name.isNotEmpty) {
      setState(() {
        _userName = name;
      });
    }
  }

  // ฟังก์ชันที่จะถูกเรียกเมื่อผู้ใช้กดเปลี่ยน Tab
  void _onItemTapped(int index) {
    // ใช้ setState เพื่อบอกให้ Flutter วาดหน้าจอใหม่ตาม index ที่เปลี่ยนไป
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // สร้าง List ของ Widget ที่จะแสดงในแต่ละ Tab
    // การทำแบบนี้ทำให้เราสลับหน้าจอได้ง่ายๆ โดยไม่ต้องใช้ Navigator
    final List<Widget> widgetOptions = <Widget>[
      _buildHomeTab(context), // Tab 0: หน้าหลัก (Home)
      const TripListScreen(), // Tab 1: ทริปของฉัน (My Trips)
      const ProfileScreen(), // Tab 2: โปรไฟล์ (Profile)
    ];

    return Scaffold(
      // body จะแสดง Widget ตาม Tab ที่ถูกเลือก
      body: widgetOptions.elementAt(_selectedIndex),
      // Bottom Navigation Bar ที่จะแสดงอยู่ด้านล่างสุดของจอ
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home_filled),
            label: 'หน้าหลัก',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt_outlined),
            label: 'ทริปของฉัน',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'โปรไฟล์',
          ),
        ],
        currentIndex: _selectedIndex, // บอกว่า Tab ไหนกำลังถูกใช้งานอยู่
        onTap: _onItemTapped, // บอกว่าเมื่อกดแล้วให้เรียกฟังก์ชันไหน
        type:
            BottomNavigationBarType.fixed, // ทำให้ Label ของทุกปุ่มแสดงตลอดเวลา
        selectedItemColor: Theme.of(
          context,
        ).primaryColor, // สีของ Tab ที่ถูกเลือก
        unselectedItemColor: Colors.grey[600], // สีของ Tab ที่ไม่ได้เลือก
      ),
    );
  }

  // --- Widget สำหรับสร้างเนื้อหาของ "Tab หน้าหลัก" ---
  Widget _buildHomeTab(BuildContext context) {
    // SafeArea ช่วยป้องกันไม่ให้ UI ของเราไปซ้อนทับกับ Status Bar (แถบแสดงเวลา, แบตเตอรี่)
    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section 1: Header - ส่วนทักทายและรูปโปรไฟล์
              _buildHeader(),
              const SizedBox(height: 24),

              // Section 2: Hero AI Card - การ์ดโปรโมทฟีเจอร์ AI
              _buildHeroAiCard(context),
              const SizedBox(height: 32),

              // Section 3: Quick Prompts - ไอเดียทริปยอดฮิต
              _buildQuickPrompts(),
              const SizedBox(height: 32),

              // Section 4: Recent Trips - ทริปล่าสุด
              _buildRecentTrips(),
            ],
          ),
        ),
      ),
    );
  }

  // --- Section 1: Header ---
  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'สวัสดี,',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            Text(
              _userName,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        // รูปโปรไฟล์ (ใช้รูปจากเน็ตเวิร์คเป็นตัวอย่าง)
        const CircleAvatar(
          radius: 28,
          backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=3'),
        ),
      ],
    );
  }

  // --- Section 2: Hero AI Card ---
  Widget _buildHeroAiCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [Colors.teal.shade300, Colors.teal.shade500],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.teal.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ให้ AI ช่วยวางแผนทริปในฝันของคุณ ✨',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              Navigator.pushNamed(context, '/create-trip');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.teal.shade700,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: const Text(
              'เริ่มสร้างทริปเลย',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  // --- Section 3: Quick Prompts ---
  Widget _buildQuickPrompts() {
    final prompts = [
      'เที่ยวทะเล 2 วัน 1 คืน',
      'สายคาเฟ่',
      'งบประหยัด',
      'เดินป่า',
      'ไหว้พระ 9 วัด',
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ไอเดียทริปยอดฮิต',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 40,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: prompts.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Chip(
                  label: Text(prompts[index]),
                  backgroundColor: Colors.grey.shade200,
                  side: BorderSide.none,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // --- Section 4: Recent Trips ---
  Widget _buildRecentTrips() {
    final recentTrips = [
      {
        'name': 'ทริปเชียงใหม่หน้าหนาว',
        'image':
            'https://images.unsplash.com/photo-1583342531553-7304a072a34b?q=80&w=1074&auto=format&fit=crop',
      },
      {
        'name': 'ตะลุยคาเฟ่กรุงเทพ',
        'image':
            'https://images.unsplash.com/photo-1559925393-a4036f101154?q=80&w=1170&auto=format&fit=crop',
      },
      {
        'name': 'พักผ่อนที่ภูเก็ต',
        'image':
            'https://images.unsplash.com/photo-1589394815804-243b94871c8c?q=80&w=1170&auto=format&fit=crop',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ทริปล่าสุดของคุณ',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: recentTrips.length,
            itemBuilder: (context, index) {
              return Container(
                width: 150,
                margin: const EdgeInsets.only(right: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          recentTrips[index]['image']!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      recentTrips[index]['name']!,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
