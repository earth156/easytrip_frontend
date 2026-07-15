import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
// Import หน้าจอต่างๆ ที่เราจะใช้ในการทำ Routing
// *** หมายเหตุ: ไฟล์เหล่านี้ตอนนี้ยังเป็นไฟล์เปล่า เราต้องไปสร้าง UI ข้างในทีหลัง ***
import 'features/auth/screens/login_screen.dart';
import 'features/trips/models/trip_creation_data.dart';
import 'features/auth/screens/register_screen.dart';
import 'features/trips/screens/home_screen.dart';
import 'features/trips/screens/create_trip_screen.dart';
import 'features/trips/screens/generating_trip_screen.dart';
import 'features/trips/screens/trip_plan_screen.dart';
import 'features/splash/screens/splash_screen.dart'; // 1. Import SplashScreen

void main() {
  // ทำให้แน่ใจว่า Flutter Engine พร้อมทำงานก่อนเริ่มแอป
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

// MyApp คือ Widget หลักของแอปเรา เปรียบเสมือนรากของต้นไม้
// ที่จะคอยครอบ Widget อื่นๆ ทั้งหมดไว้
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // build() เป็นเมธอดที่จะถูกเรียกเพื่อวาด UI ของ Widget นี้
  @override
  Widget build(BuildContext context) {
    // MaterialApp เป็น Widget ที่มีเครื่องมือสำหรับสร้างแอปแบบ Material Design
    // ช่วยจัดการเรื่อง Theme, Routing (การเปลี่ยนหน้า) และอื่นๆ
    return MaterialApp(
      // ชื่อของแอปที่จะแสดงผล เช่น ตอนสลับแอปในมือถือ
      title: 'EasyTrip',

      // ปิดแถบ "DEBUG" ที่มุมขวาบนของจอ
      debugShowCheckedModeBanner: false,

      // กำหนดหน้าตาโดยรวมของแอป (Theme) เช่น สีหลัก, ฟอนต์
      // ในโปรเจคจริง เราจะแยกโค้ดส่วนนี้ไปไว้ที่ 'core/theme/app_theme.dart' เพื่อความเป็นระเบียบ
      theme: AppTheme.lightTheme,

      // initialRoute คือการบอกว่าเมื่อเปิดแอปขึ้นมาครั้งแรก จะให้ไปที่หน้าไหน
      // 2. กำหนดให้ไปที่หน้า Splash Screen ก่อนเสมอ
      initialRoute: '/splash',

      // routes คือการ 'ลงทะเบียน' หน้าต่างๆ ของแอป
      // ทำให้เราสามารถเรียกเปลี่ยนหน้าได้ง่ายๆ ด้วยการเรียกชื่อ (Named Route)
      // เช่น Navigator.pushNamed(context, '/register');
      routes: {
        // 3. เพิ่ม Route สำหรับ Splash Screen
        '/splash': (context) => const SplashScreen(),
        // ถ้าแอปเรียก path '/login' ให้แสดงผล Widget LoginScreen
        '/login': (context) => const LoginScreen(),
        // ถ้าแอปเรียก path '/register' ให้แสดงผล Widget RegisterScreen
        '/register': (context) => const RegisterScreen(),
        '/create-trip': (context) => const CreateTripScreen(),
        // Route สำหรับหน้า "กำลังสร้างทริป" ซึ่งจะรับ tripId มาเป็น arguments
        '/generating-trip': (context) => GeneratingTripScreen(
          tripId: ModalRoute.of(context)!.settings.arguments as String,
        ),
        // Route สำหรับหน้าแสดงผลลัพธ์แผนการเดินทาง
        '/trip-plan': (context) => TripPlanScreen(
          tripPlan:
              ModalRoute.of(context)!.settings.arguments
                  as Map<String, dynamic>,
        ),
        // ถ้าแอปเรียก path '/home' ให้แสดงผล Widget HomeScreen (หน้าหลักหลัง login)
        '/home': (context) => const HomeScreen(),
      },
    );
  }
}
