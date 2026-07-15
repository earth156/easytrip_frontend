import 'package:flutter/material.dart';

/// คลาสสำหรับรวบรวม Custom Dialog ที่ใช้บ่อยในแอป
/// ทำให้สามารถเรียกใช้ได้ง่ายและมีดีไซน์ที่สอดคล้องกัน
class CustomDialogs {
  // ทำให้เป็น private constructor เพื่อป้องกันการสร้าง instance จากภายนอก
  CustomDialogs._();

  /// --- ตัวอย่างการเรียกใช้งาน ---
  /// await CustomDialogs.showSuccessDialog(
  ///   context: context,
  ///   title: 'สำเร็จ!',
  ///   message: 'การดำเนินการของคุณเสร็จสิ้นแล้ว',
  /// );
  static Future<void> showSuccessDialog({
    required BuildContext context,
    required String title,
    required String message,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // ผู้ใช้ต้องกดปุ่มเพื่อปิดเท่านั้น
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 20),
              Icon(
                Icons.check_circle,
                color: Theme.of(context).primaryColor, // ใช้สีหลักของแอป
                size: 60,
              ),
              const SizedBox(height: 20),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('ไปกันเลย'),
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  /// --- ตัวอย่างการเรียกใช้งาน ---
  /// await CustomDialogs.showErrorDialog(
  ///   context: context,
  ///   title: 'เกิดข้อผิดพลาด',
  ///   message: 'ไม่สามารถดำเนินการได้ กรุณาลองใหม่อีกครั้ง',
  /// );
  static Future<void> showErrorDialog({
    required BuildContext context,
    required String title,
    required String message,
  }) {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 20),
              const Icon(Icons.error, color: Colors.red, size: 60),
              const SizedBox(height: 20),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('ลองอีกครั้ง'),
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  /// --- ตัวอย่างการเรียกใช้งาน ---
  /// final bool? didRequestDelete = await CustomDialogs.showConfirmDeleteDialog(
  ///   context: context,
  ///   title: 'ยืนยันการลบ',
  ///   message: 'คุณแน่ใจหรือไม่ว่าต้องการลบรายการนี้?',
  /// );
  /// if (didRequestDelete == true) {
  ///   // ... ทำการลบข้อมูล ...
  /// }
  static Future<bool?> showConfirmDeleteDialog({
    required BuildContext context,
    required String title,
    required String message,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 20),
              const Icon(
                Icons.warning_rounded,
                color: Colors.redAccent,
                size: 60,
              ),
              const SizedBox(height: 20),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false), // คืนค่า false
              child: Text("ยกเลิก", style: TextStyle(color: Colors.grey[700])),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true), // คืนค่า true
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                // Override minimumSize จาก theme กลาง เพื่อไม่ให้ปุ่มกว้างเต็มจอ
                // โดยกำหนดให้ไม่มีความกว้างขั้นต่ำ และมีความสูง 40
                minimumSize: const Size(0, 40),
                // เพิ่ม padding ด้านข้างเพื่อให้ปุ่มไม่เล็กเกินไป
                padding: const EdgeInsets.symmetric(horizontal: 24),
              ),
              child: const Text("ลบทิ้ง"),
            ),
          ],
          // เปลี่ยนการจัดวางปุ่มไปทางขวา ซึ่งเป็นมาตรฐานของ Dialog
          actionsAlignment: MainAxisAlignment.end,
          actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
        );
      },
    );
  }

  /// --- ตัวอย่างการเรียกใช้งาน ---
  /// final bool? confirmed = await CustomDialogs.showConfirmDialog(
  ///   context: context,
  ///   title: 'ยืนยัน',
  ///   message: 'คุณต้องการดำเนินการต่อใช่หรือไม่?',
  /// );
  /// if (confirmed == true) {
  ///   // ... ดำเนินการต่อ ...
  /// }
  static Future<bool?> showConfirmDialog({
    required BuildContext context,
    required String title,
    required String message,
    String confirmText = 'ยืนยัน',
  }) {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 20),
              Icon(
                Icons.help_outline,
                color: Theme.of(context).primaryColor,
                size: 60,
              ),
              const SizedBox(height: 20),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false), // คืนค่า false
              child: Text("ยกเลิก", style: TextStyle(color: Colors.grey[700])),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true), // คืนค่า true
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(0, 40),
                padding: const EdgeInsets.symmetric(horizontal: 24),
              ),
              child: Text(confirmText),
            ),
          ],
          actionsAlignment: MainAxisAlignment.end,
          actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
        );
      },
    );
  }
}
