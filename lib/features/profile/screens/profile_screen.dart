import 'package:easytrip_frontend/core/utils/custom_dialogs.dart';
import 'package:flutter/material.dart';
import '../../../core/services/session_service.dart';

// หน้าจอโปรไฟล์ผู้ใช้
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Widget build(BuildContext context) {
    // กำหนดค่าคงที่สำหรับความสูงและรัศมี เพื่อให้แก้ไขง่าย
    const double coverHeight = 200;
    const double avatarRadius = 60;

    return Scaffold(
      backgroundColor:
          Colors.grey[100], // สีพื้นหลังอ่อนๆ เพื่อให้การ์ดเมนูเด่นขึ้น
      body: SingleChildScrollView(
        child: Column(
          children: [
            // --- 1. ส่วนปกและรูปโปรไฟล์ ---
            Stack(
              clipBehavior: Clip.none, // อนุญาตให้ Avatar ล้นออกมานอก Stack ได้
              alignment: Alignment.center,
              children: [
                // ภาพปก (Cover Photo)
                _buildCoverImage(coverHeight),
                // รูปโปรไฟล์ (Avatar)
                _buildAvatar(coverHeight, avatarRadius),
              ],
            ),

            // เว้นระยะห่างเท่ากับครึ่งหนึ่งของ Avatar เพื่อให้เนื้อหาอยู่ใต้ Avatar
            const SizedBox(height: avatarRadius),

            // --- 2. ส่วนข้อมูลผู้ใช้ ---
            _buildUserInfo(),
            const SizedBox(height: 16),

            // --- 3. ส่วนสถิติการเดินทาง ---
            _buildTravelStats(),
            const SizedBox(height: 24),

            // --- 4. ส่วนเมนูการตั้งค่า ---
            _buildSettingsMenu(context),
          ],
        ),
      ),
    );
  }

  // Widget สำหรับสร้างภาพปก
  Widget _buildCoverImage(double height) {
    return Container(
      height: height,
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: NetworkImage(
            'https://images.unsplash.com/photo-1501785888041-af3ef285b470?q=80&w=1170&auto=format&fit=crop',
          ),
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  // Widget สำหรับสร้างรูปโปรไฟล์
  Widget _buildAvatar(double coverHeight, double radius) {
    return Positioned(
      top:
          coverHeight -
          radius, // จัดตำแหน่งให้ Avatar อยู่กึ่งกลางระหว่างปกกับเนื้อหา
      child: CircleAvatar(
        radius: radius,
        backgroundColor: Colors.white, // ขอบขาว
        child: CircleAvatar(
          radius: radius - 5, // ขนาดรูปโปรไฟล์ด้านใน
          backgroundImage: const NetworkImage(
            'https://i.pravatar.cc/150?img=3',
          ),
        ),
      ),
    );
  }

  // Widget สำหรับสร้างข้อมูลผู้ใช้
  Widget _buildUserInfo() {
    return const Column(
      children: [
        Text(
          'จิรวัฒน์ แสวงคำ',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 4),
        Text(
          'jirawat.s@example.com',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      ],
    );
  }

  // Widget สำหรับสร้างสถิติการเดินทาง
  Widget _buildTravelStats() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildStatItem('ทริปทั้งหมด', '5'),
        _buildStatItem('สถานที่โปรด', '12'),
      ],
    );
  }

  // Widget ย่อยสำหรับแสดงสถิติแต่ละอัน
  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
      ],
    );
  }

  // Widget สำหรับสร้างเมนูการตั้งค่าทั้งหมด
  Widget _buildSettingsMenu(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          // กลุ่มบัญชี
          _buildSettingsGroup(
            children: [
              ProfileMenuTile(
                icon: Icons.edit_outlined,
                title: 'แก้ไขโปรไฟล์',
                onTap: () {},
              ),
              const Divider(height: 1),
              ProfileMenuTile(
                icon: Icons.lock_outline,
                title: 'เปลี่ยนรหัสผ่าน',
                onTap: () {},
              ),
            ],
          ),
          const SizedBox(height: 16),
          // กลุ่มตั้งค่า
          _buildSettingsGroup(
            children: [
              ProfileMenuTile(
                icon: Icons.language_outlined,
                title: 'ภาษา',
                onTap: () {},
              ),
              const Divider(height: 1),
              ProfileMenuTile(
                icon: Icons.notifications_none_outlined,
                title: 'การแจ้งเตือน',
                onTap: () {},
              ),
            ],
          ),
          const SizedBox(height: 16),
          // กลุ่มช่วยเหลือ
          _buildSettingsGroup(
            children: [
              ProfileMenuTile(
                icon: Icons.help_outline,
                title: 'ศูนย์ช่วยเหลือ',
                onTap: () {},
              ),
              const Divider(height: 1),
              ProfileMenuTile(
                icon: Icons.info_outline,
                title: 'เกี่ยวกับแอป EasyTrip',
                onTap: () {},
              ),
            ],
          ),
          const SizedBox(height: 24),
          // ปุ่มออกจากระบบ
          _buildLogoutButton(context),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // Widget สำหรับสร้างกลุ่มของเมนู (การ์ดสีขาว)
  Widget _buildSettingsGroup({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(children: children),
    );
  }

  // Widget สำหรับสร้างปุ่มออกจากระบบ
  Widget _buildLogoutButton(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: const Icon(Icons.logout, color: Colors.red),
        title: const Text(
          'ออกจากระบบ',
          style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
        ),
        onTap: () async {
          // เรียกใช้ Custom Dialog เพื่อยืนยันการออกจากระบบ
          final bool? didRequestLogout = await CustomDialogs.showConfirmDialog(
            context: context,
            title: 'ยืนยันการออกจากระบบ',
            message: 'คุณต้องการออกจากระบบใช่หรือไม่?',
            confirmText: 'ยืนยัน',
          );
          // ถ้าผู้ใช้กดยืนยัน (true) ให้ทำการออกจากระบบ
          if (didRequestLogout == true) {
            // 1. เรียกใช้ SessionService เพื่อล้างข้อมูลทั้งหมด
            await SessionService().clearSession();

            // 2. นำทางผู้ใช้กลับไปหน้า Login
            // ตรวจสอบว่า widget ยังอยู่ใน tree ก่อนเรียก Navigator
            if (!mounted) return;
            Navigator.of(
              context,
            ).pushNamedAndRemoveUntil('/login', (route) => false);
          }
        },
      ),
    );
  }
}

/// Widget ที่ใช้ซ้ำสำหรับสร้างรายการเมนูในหน้าโปรไฟล์
class ProfileMenuTile extends StatelessWidget {
  const ProfileMenuTile({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey[600]),
      title: Text(title),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: Colors.grey,
      ),
      onTap: onTap,
    );
  }
}
