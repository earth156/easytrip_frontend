import 'dart:async';

import 'package:easytrip_frontend/features/trips/controller/trip_controller.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

/// หน้าจอที่แสดงระหว่างรอ AI ประมวลผลและสร้างแพลนเที่ยว
class GeneratingTripScreen extends StatefulWidget {
  final String tripId;
  const GeneratingTripScreen({super.key, required this.tripId});

  @override
  State<GeneratingTripScreen> createState() => _GeneratingTripScreenState();
}

class _GeneratingTripScreenState extends State<GeneratingTripScreen> {
  final TripController _tripController = TripController();
  Timer? _pollingTimer; // Timer สำหรับการ Polling
  Timer? _tipTimer; // Timer สำหรับการเปลี่ยน Tips
  int _currentTipIndex = 0;

  // List of tips or fun facts to display
  final List<String> _loadingTips = [
    'กำลังค้นหาสถานที่ลับเฉพาะสำหรับคุณ...',
    'จัดเรียงเส้นทางที่ดีที่สุดเพื่อประหยัดเวลาเดินทาง...',
    'ตรวจสอบสภาพอากาศและฤดูกาลท่องเที่ยว...',
    'หาดีลร้านอาหารและคาเฟ่เด็ดๆ...',
    'สร้างสรรค์กิจกรรมให้ตรงกับสไตล์ของคุณ...',
    'เกือบเสร็จแล้ว! กำลังจัดทำแผนการเดินทางฉบับสมบูรณ์...',
  ];

  @override
  void initState() {
    super.initState();
    // Start polling for trip status
    _startPolling();

    // Start a timer to cycle through the loading tips UI
    _tipTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (mounted) {
        setState(() {
          _currentTipIndex = (_currentTipIndex + 1) % _loadingTips.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel(); // ยกเลิก Timer ของ Polling
    _tipTimer?.cancel(); // ยกเลิก Timer ของ Tips
    super.dispose();
  }

  void _startPolling() {
    // Poll every 5 seconds
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      try {
        // getTripDetails now returns the unwrapped trip object directly,
        // so we can use it without accessing a 'data' key.
        final tripData = await _tripController.getTripDetails(widget.tripId);
        if (tripData == null) {
          throw Exception("Invalid response format from server.");
        }

        final status = tripData['status'];

        if (!mounted) {
          timer.cancel();
          return;
        }

        if (status == 'completed') {
          timer.cancel();
          Navigator.of(
            context,
          ).pushReplacementNamed('/trip-plan', arguments: tripData);
        } else if (status == 'failed') {
          timer.cancel();
          _showErrorDialog(
            'สร้างทริปล้มเหลว',
            tripData['error_message'] ??
                'เกิดข้อผิดพลาดไม่ทราบสาเหตุในระหว่างการสร้างทริป',
          );
        }
        // If status is 'processing' or 'pending', do nothing and wait for the next poll.
      } catch (e) {
        // Handle polling error
        timer.cancel();
        if (mounted) {
          _showErrorDialog(
            'เกิดข้อผิดพลาด',
            'ขาดการเชื่อมต่อกับเซิร์ฟเวอร์ กรุณาตรวจสอบอินเทอร์เน็ตแล้วลองใหม่อีกครั้ง',
          );
        }
      }
    });
  }

  // --- Helper function to show an error dialog ---
  Future<void> _showErrorDialog(String title, String content) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // User must tap a button to close.
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: <Widget>[
            TextButton(
              child: const Text('ตกลง'),
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Close the dialog
                Navigator.of(
                  context,
                ).pop(); // Pop back to the create trip screen
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Prevent user from going back while loading
      body: PopScope(
        canPop: false,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).primaryColorLight,
                Theme.of(context).primaryColorDark,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Lottie Animation
                  Lottie.asset(
                    'assets/animations/travel_animation.json',
                    width: 250,
                    height: 250,
                  ),
                  const SizedBox(height: 32),
                  // Main Title
                  const Text(
                    'AI กำลังจัดทริปสุดพิเศษสำหรับคุณ...',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // --- เพิ่มเข้ามา: แถบ Progress Indicator ---
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0),
                    child: LinearProgressIndicator(
                      backgroundColor: Colors.white.withOpacity(0.3),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Colors.white,
                      ),
                      minHeight: 6,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Animated text for loading tips
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 500),
                    transitionBuilder:
                        (Widget child, Animation<double> animation) {
                          return FadeTransition(
                            opacity: animation,
                            child: child,
                          );
                        },
                    child: Text(
                      _loadingTips[_currentTipIndex],
                      key: ValueKey<int>(
                        _currentTipIndex,
                      ), // Important for AnimatedSwitcher
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
