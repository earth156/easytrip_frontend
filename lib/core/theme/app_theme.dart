import 'package:flutter/material.dart';

class AppTheme {
  // ทำให้เป็น private constructor เพื่อป้องกันการสร้าง instance จากภายนอก
  AppTheme._();

  // สร้าง static getter สำหรับ light theme เพื่อให้เรียกใช้งานได้ง่ายๆ
  // เช่น AppTheme.lightTheme
  static ThemeData get lightTheme {
    return ThemeData(
      primarySwatch: Colors.teal,
      scaffoldBackgroundColor: Colors.white,
      fontFamily: 'Kanit',

      // --- Theme ของปุ่มทั้งหมดในแอป ---
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.teal,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      // เราสามารถเพิ่ม theme ของ widget อื่นๆ ที่นี่ได้อีกในอนาคต
      // เช่น appBarTheme, inputDecorationTheme, textTheme เป็นต้น
    );
  }
}
