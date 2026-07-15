import 'package:flutter/material.dart';
import 'dart:async';
import '../../../core/services/session_service.dart'; // Import service สำหรับเช็ค session

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkSessionAndNavigate();
  }

  Future<void> _checkSessionAndNavigate() async {
    // --- การตั้งเวลาสลับหน้า (Timer) ---
    // เราใช้ Future.delayed เพื่อหน่วงเวลาไว้ 3 วินาที
    // เหมือนเป็นการจำลองว่าแอปกำลังโหลดข้อมูลเบื้องหลังอยู่ครับ
    await Future.delayed(const Duration(seconds: 3));

    final sessionService = SessionService();
    final token = await sessionService.getToken();

    // เช็คก่อนว่า Widget ยังอยู่ในหน้าจอ (mounted) ก่อนจะเรียกใช้ context
    if (!mounted) return;

    final route = (token != null && token.isNotEmpty) ? '/home' : '/login';

    // ใช้ pushReplacementNamed เพื่อเปลี่ยนหน้าแบบถาวร ผู้ใช้จะกด Back กลับมาหน้านี้ไม่ได้
    Navigator.of(
      context,
    ).pushReplacementNamed(route); // ในโจทย์คือไป '/login' แต่โค้ดเดิมดีกว่า
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ใช้ Stack เพื่อวาง Widget ซ้อนกัน: 1.พื้นหลังไล่สี 2.โลโก้ 3.ตัวโหลด
      body: Stack(
        children: [
          // --- ส่วนพื้นหลังไล่สี (Gradient Background) ---
          Container(
            // ทำให้ Container ขยายเต็มหน้าจอ
            width: double.infinity,
            height: double.infinity,
            // BoxDecoration ใช้สำหรับตกแต่งกล่องสี่เหลี่ยม
            decoration: const BoxDecoration(
              // LinearGradient: บอกว่าจะไล่สีแบบเป็นเส้นตรงนะ
              gradient: LinearGradient(
                // colors: คือลิสต์ของสีที่เราจะใช้ไล่่กัน
                colors: [
                  Color(0xFF03E1C8), // สีที่ 1 (สีอ่อน)
                  Color(0xFF01A6DE), // สีที่ 2 (สีเข้ม)
                ],
                // begin: คือจุดเริ่มต้นของการไล่สี (มุมซ้ายบน)
                begin: Alignment.topLeft,
                // end: คือจุดสิ้นสุดของการไล่สี (มุมขวาล่าง)
                end: Alignment.bottomRight,
              ),
            ),
          ),

          // --- ส่วนโลโก้ (Center Logo) ---
          Center(
            // ใช้ Container เพื่อเพิ่มเงาและทำให้ขอบมน
            child: Container(
              width: 220,
              height:
                  220, // กำหนดความสูงให้เท่ากับความกว้างเพื่อให้เป็นสี่เหลี่ยมจัตุรัส
              decoration: BoxDecoration(
                // ทำให้ขอบโค้งมน
                borderRadius: BorderRadius.circular(30),
                // เพิ่มเงาเพื่อให้ดูนูนขึ้น
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.25), // สีของเงา
                    spreadRadius: 2, // การกระจายของเงา
                    blurRadius: 15, // ความเบลอของเงา
                    offset: const Offset(0, 8), // ตำแหน่งของเงา (x, y)
                  ),
                ],
              ),
              // ใช้ ClipRRect เพื่อตัดรูปภาพให้มีขอบมนตาม Container
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: Image.asset('assets/images/logosplash.jpg'),
              ),
            ),
          ),

          // --- ส่วนตัวโหลด (Loading Indicator) ---
          const Padding(
            padding: EdgeInsets.only(bottom: 50.0),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
