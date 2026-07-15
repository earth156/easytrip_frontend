import 'dart:convert';
import 'dart:io';
import 'package:easytrip_frontend/core/constants/api.dart';
import 'package:http/http.dart' as http;

import '../models/auth_result.dart';
import '../models/user_model.dart';

class AuthService {
  // ใช้ Platform.isAndroid เพื่อตรวจสอบว่าเป็น Android หรือไม่
  // ถ้าเป็น Android Emulator ให้ใช้ 10.0.2.2 เพื่อเชื่อมต่อกับ localhost ของเครื่องคอมพิวเตอร์
  // ถ้าเป็น iOS Simulator หรือ Web สามารถใช้ localhost ได้โดยตรง
  final String _baseUrl =
      '${ApiConfig.baseUrl}/api/auth'; // Simplified Base URL

  Future<AuthResult> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/register'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'name': name,
          'email': email,
          'password': password,
        }),
      );

      final responseBody = jsonDecode(response.body);

      // ตรวจสอบจาก status code ที่ backend ส่งมา (201, 409, 500 etc.)
      if (response.statusCode == 201) {
        return AuthSuccess(
          message: responseBody['message'] ?? 'ลงทะเบียนสำเร็จ!',
        );
      } else {
        return AuthFailure(
          message: responseBody['message'] ?? 'เกิดข้อผิดพลาดที่ไม่รู้จัก',
        );
      }
    } catch (e) {
      // กรณี Network Error หรือเชื่อมต่อ Server ไม่ได้
      print('AuthService Error: $e');
      return AuthFailure(message: 'ไม่สามารถเชื่อมต่อกับเซิร์ฟเวอร์ได้');
    }
  }

  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    final url = Uri.parse('$_baseUrl/login');
    final headers = <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    };
    final body = jsonEncode(<String, String>{
      'email': email,
      'password': password,
    });

    try {
      print('--- [AuthService] Sending Login Request ---');
      print('URL: $url');
      final response = await http.post(url, headers: headers, body: body);

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Check if the token exists and is a string before proceeding.
        if (responseBody['data'] != null &&
            responseBody['data']['accessToken'] is String &&
            responseBody['data']['user'] is Map) {
          // Login successful, backend returns a token.
          final user = User.fromJson(
            responseBody['data']['user'] as Map<String, dynamic>,
          );

          return LoginSuccess(
            message: responseBody['message'] ?? 'เข้าสู่ระบบสำเร็จ!',
            token: responseBody['data']['accessToken'],
            user: user,
          );
        } else {
          // Handle cases where the server response is malformed (e.g., missing token).
          return AuthFailure(
            message: 'การตอบกลับจากเซิร์ฟเวอร์ไม่ถูกต้อง (ไม่พบ Token)',
          );
        }
      } else {
        // Login failed (e.g., invalid credentials, user not found).
        return AuthFailure(
          message: responseBody['message'] ?? 'อีเมลหรือรหัสผ่านไม่ถูกต้อง',
        );
      }
    } on http.ClientException catch (e) {
      // Handle network-related errors (e.g., connection refused)
      print('--- [AuthService] ClientException Error ---');
      print('Error: ${e.message}');
      return AuthFailure(
        message: 'ไม่สามารถเชื่อมต่อกับเซิร์ฟเวอร์ได้ กรุณาตรวจสอบ IP และ Port',
      );
    } catch (e) {
      // Handle other unexpected errors
      print('--- [AuthService] Unexpected Login Error ---');
      print('Error: ${e.toString()}');
      return AuthFailure(
        message: 'เกิดข้อผิดพลาดที่ไม่คาดคิด: ${e.toString()}',
      );
    }
  }
}
