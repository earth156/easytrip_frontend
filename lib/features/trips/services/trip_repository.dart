import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/constants/api.dart';
import '../../../core/services/session_service.dart';
import '../models/trip_creation_data.dart';
import '../models/trip_model.dart';

/// Repository สำหรับจัดการการเรียก API ที่เกี่ยวกับ Trip
class TripRepository {
  final String _baseUrl = ApiConfig.baseUrl;
  final SessionService _sessionService = SessionService();

  /// ส่งคำขอเพื่อเริ่มสร้างทริป และรับ tripId กลับมาทันที
  Future<String> initiateTripGeneration(TripCreationData data) async {
    final token = await _sessionService.getToken();
    if (token == null) {
      throw Exception('กรุณาเข้าสู่ระบบก่อนสร้างทริป');
    }

    final response = await http.post(
      // Endpoint ที่เราคาดหวังจาก Backend
      Uri.parse('$_baseUrl/api/trips/generate'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data.toJson()),
    );

    // Backend จะตอบกลับ 202 Accepted พร้อม tripId
    if (response.statusCode == 202) {
      final responseBody = jsonDecode(utf8.decode(response.bodyBytes));
      final tripId = responseBody['tripId'];
      if (tripId == null) throw Exception('ไม่ได้รับ tripId จากเซิร์ฟเวอร์');
      return tripId;
    } else {
      // หากเกิดข้อผิดพลาด
      // พยายามถอดรหัส JSON จาก body ของ response
      // ถ้า body ไม่ใช่ JSON (เช่น เป็น HTML error page) จะได้ไม่เกิด FormatException
      try {
        final errorBody = jsonDecode(utf8.decode(response.bodyBytes));
        // ถ้าถอดรหัสสำเร็จ ให้ใช้ message จาก server
        throw Exception(
          errorBody['message'] ??
              'เกิดข้อผิดพลาดจากเซิร์ฟเวอร์ (Code: ${response.statusCode})',
        );
      } catch (e) {
        // ถ้าถอดรหัสไม่สำเร็จ (body ไม่ใช่ JSON) ให้โยน Exception พร้อมกับ status code และ body ดิบๆ
        // เพื่อให้ง่ายต่อการ debug
        throw Exception(
          'เกิดข้อผิดพลาดในการสื่อสารกับเซิร์ฟเวอร์ (Code: ${response.statusCode}). Body: ${response.body}',
        );
      }
    }
  }

  /// ดึงข้อมูลทริปทั้งหมดที่ผู้ใช้เคยบันทึกไว้
  Future<List<Trip>> getMyTrips() async {
    final token = await _sessionService.getToken();
    if (token == null) {
      throw Exception('กรุณาเข้าสู่ระบบเพื่อดูทริปของคุณ');
    }

    final response = await http.get(
      Uri.parse('$_baseUrl/api/trips'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      final List<dynamic> tripData = body['data'];
      return tripData.map((json) => Trip.fromJson(json)).toList();
    } else {
      try {
        final errorBody = jsonDecode(utf8.decode(response.bodyBytes));
        throw Exception(
          errorBody['message'] ??
              'เกิดข้อผิดพลาดในการดึงข้อมูลทริป (Code: ${response.statusCode})',
        );
      } catch (e) {
        throw Exception(
          'เกิดข้อผิดพลาดในการสื่อสารกับเซิร์ฟเวอร์ (Code: ${response.statusCode}). Body: ${response.body}',
        );
      }
    }
  }

  /// ดึงข้อมูลทริปแบบเจาะจง 1 รายการจาก ID
  Future<Map<String, dynamic>> getTripDetails(String tripId) async {
    final token = await _sessionService.getToken();
    if (token == null) {
      throw Exception('กรุณาเข้าสู่ระบบเพื่อดูรายละเอียดทริป');
    }

    final response = await http.get(
      Uri.parse('$_baseUrl/api/trips/$tripId'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      // The backend nests the trip object inside a 'data' key.
      // We need to extract it before returning for consistency.
      return body['data'] as Map<String, dynamic>;
    } else {
      try {
        final errorBody = jsonDecode(utf8.decode(response.bodyBytes));
        throw Exception(
          errorBody['message'] ??
              'เกิดข้อผิดพลาดในการดึงข้อมูลทริป (Code: ${response.statusCode})',
        );
      } catch (e) {
        throw Exception(
          'เกิดข้อผิดพลาดในการสื่อสารกับเซิร์ฟเวอร์ (Code: ${response.statusCode}). Body: ${response.body}',
        );
      }
    }
  }

  /// ลบทริปจาก ID
  Future<void> deleteTrip(String tripId) async {
    final token = await _sessionService.getToken();
    if (token == null) {
      throw Exception('กรุณาเข้าสู่ระบบเพื่อลบทริป');
    }

    final response = await http.delete(
      Uri.parse('$_baseUrl/api/trips/$tripId'),
      headers: {'Authorization': 'Bearer $token'},
    );

    // A successful DELETE can return 200 OK or 204 No Content
    if (response.statusCode == 200 || response.statusCode == 204) {
      return;
    } else {
      try {
        final errorBody = jsonDecode(utf8.decode(response.bodyBytes));
        throw Exception(
          errorBody['message'] ??
              'เกิดข้อผิดพลาดในการลบทริป (Code: ${response.statusCode})',
        );
      } catch (e) {
        throw Exception(
          'เกิดข้อผิดพลาดในการสื่อสารกับเซิร์ฟเวอร์ (Code: ${response.statusCode}). Body: ${response.body}',
        );
      }
    }
  }
}
