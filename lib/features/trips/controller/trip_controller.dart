import 'package:easytrip_frontend/features/trips/services/trip_repository.dart';
import '../models/trip_creation_data.dart';
import 'package:flutter/material.dart';
import '../models/trip_model.dart';

/// Controller สำหรับจัดการ Logic ที่เกี่ยวกับ Trip
class TripController {
  final TripRepository _repository = TripRepository();

  Future<String> initiateTrip(TripCreationData data) async {
    try {
      // เรียกใช้ repository เพื่อเริ่มสร้างทริปและรับ tripId กลับมา
      final tripId = await _repository.initiateTripGeneration(data);
      return tripId;
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Trip>> getMyTrips() async {
    try {
      final trips = await _repository.getMyTrips();
      return trips;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getTripDetails(String tripId) async {
    try {
      return await _repository.getTripDetails(tripId);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteTrip(String tripId) async {
    try {
      await _repository.deleteTrip(tripId);
    } catch (e) {
      rethrow;
    }
  }

  /// จัดการ Logic การลบทริป (ที่ยังไม่สมบูรณ์) และนำทางกลับไปหน้าสร้างทริป
  Future<void> discardAndCreateNew(BuildContext context, String? tripId) async {
    if (tripId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('ไม่พบ ID ของทริป')));
      return;
    }

    try {
      await _repository.deleteTrip(tripId);
      if (context.mounted) {
        // กลับไปที่หน้าสร้างทริปโดยล้าง Stack ที่อยู่ข้างบนออก
        Navigator.popUntil(context, ModalRoute.withName('/create-trip'));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ล้มเหลวในการลบแผน: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
