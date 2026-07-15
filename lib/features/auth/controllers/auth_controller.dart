import '../services/auth_service.dart';
import '../models/auth_result.dart';
import '../../../core/services/session_service.dart';

/// AuthController ทำหน้าที่เป็นตัวกลางระหว่าง UI (Screen) และ Business Logic (Service)
/// เพื่อจัดการกับ Use Case ที่เกี่ยวกับการยืนยันตัวตน เช่น การสมัครสมาชิก, การเข้าสู่ระบบ
class AuthController {
  // สร้าง instance ของ AuthService เพื่อเรียกใช้งาน
  final AuthService _authService = AuthService();
  final SessionService _sessionService = SessionService();

  /// ฟังก์ชันสำหรับจัดการการสมัครสมาชิก
  /// รับข้อมูลจากหน้า UI และส่งต่อไปยัง AuthService
  Future<AuthResult> register({
    required String name,
    required String email,
    required String password,
  }) async {
    // ในที่นี้ Controller ทำหน้าที่ส่งผ่านข้อมูลไปยัง Service โดยตรง
    // ในอนาคตหากมี Logic ที่ซับซ้อนขึ้น เช่น การตรวจสอบข้อมูลเพิ่มเติมก่อนส่ง
    // ก็สามารถทำได้ที่นี่
    final result = await _authService.register(
      name: name,
      email: email,
      password: password,
    );
    return result;
  }

  /// ฟังก์ชันสำหรับจัดการการเข้าสู่ระบบ
  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    final result = await _authService.login(email: email, password: password);

    // If login is successful, save the session data
    if (result is LoginSuccess) {
      await _sessionService.saveToken(result.token);
      await _sessionService.saveUserInfo(
        name: result.user.name,
        email: result.user.email,
      );
    }
    return result;
  }
}
