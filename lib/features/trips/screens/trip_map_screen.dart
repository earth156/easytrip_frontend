import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';

class TripMapScreen extends StatefulWidget {
  final List<dynamic> itinerary;

  const TripMapScreen({super.key, required this.itinerary});

  @override
  State<TripMapScreen> createState() => _TripMapScreenState();
}

class _TripMapScreenState extends State<TripMapScreen>
    with TickerProviderStateMixin {
  late final MapController _mapController;

  // --- State สำหรับ Location Tracking ---
  StreamSubscription<Position>? _locationSubscription;
  LatLng? _highlightedPoint;
  LatLng? _lastNotifiedPoint;
  // เพิ่ม List สำหรับติดตาม Animation Controllers ที่กำลังทำงาน
  final List<AnimationController> _animationControllers = [];
  final double _proximityThreshold = 100; // ระยะห่าง (เมตร) ที่จะแจ้งเตือน

  // --- State สำหรับข้อมูลแผนที่ ---
  List<Map<String, dynamic>> _placesData = [];
  LatLngBounds? _bounds;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _processItinerary();
    _initLocationServices();
  }

  /// กรองข้อมูลและเตรียม Points กับ Markers สำหรับแผนที่
  void _processItinerary() {
    final processedPlaces = <Map<String, dynamic>>[];
    final pointsForBounds = <LatLng>[];
    int markerIndex = 1;

    // วนลูปในทุกๆ วัน และทุกๆ กิจกรรม
    for (var day in widget.itinerary) {
      final activities = day['activities'] as List<dynamic>? ?? [];
      for (var activity in activities) {
        // ดึงค่า lat, lon และตรวจสอบว่าเป็น null หรือไม่
        final lat = activity['lat'];
        final lon = activity['lon'];

        if (lat != null && lon != null) {
          final point = LatLng(lat, lon);
          pointsForBounds.add(point);
          final placeName = activity['placeName'] as String? ?? 'Unknown Place';

          processedPlaces.add({
            'point': point,
            'name': placeName,
            'index': markerIndex,
          });
          markerIndex++;
        }
      }
    }

    setState(() {
      _placesData = processedPlaces;
      // คำนวณขอบเขตของแผนที่เพื่อให้แสดง Marker ทั้งหมด
      if (pointsForBounds.isNotEmpty) {
        _bounds = LatLngBounds.fromPoints(pointsForBounds);
      }
    });
  }

  /// --- จัดการ Service และ Permission ของ Location ---
  Future<void> _initLocationServices() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled don't continue
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
        'Location permissions are permanently denied, we cannot request permissions.',
      );
    }

    // เมื่อ Permission ผ่านแล้ว ให้เริ่มติดตามตำแหน่ง
    _locationSubscription = Geolocator.getPositionStream().listen((
      Position position,
    ) {
      _checkProximity(position);
    });
  }

  /// --- ตรวจสอบระยะห่างระหว่างผู้ใช้กับหมุด ---
  void _checkProximity(Position currentPosition) {
    final userLocation = LatLng(
      currentPosition.latitude,
      currentPosition.longitude,
    );
    LatLng? closestPoint;
    double minDistance = double.infinity;

    for (var place in _placesData) {
      final placeLocation = place['point'] as LatLng;
      final distance = Geolocator.distanceBetween(
        userLocation.latitude,
        userLocation.longitude,
        placeLocation.latitude,
        placeLocation.longitude,
      );

      if (distance < minDistance) {
        minDistance = distance;
        closestPoint = placeLocation;
      }
    }

    // ตรวจสอบว่าจุดที่ใกล้ที่สุดอยู่ในระยะที่กำหนดหรือไม่
    if (minDistance <= _proximityThreshold) {
      if (_highlightedPoint != closestPoint) {
        setState(() {
          _highlightedPoint = closestPoint;
        });

        // แจ้งเตือนเมื่อเข้าใกล้จุดใหม่ และยังไม่เคยแจ้งเตือนจุดนี้มาก่อน
        if (_lastNotifiedPoint != closestPoint) {
          final placeName = _placesData.firstWhere(
            (p) => p['point'] == closestPoint,
          )['name'];
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('คุณกำลังเข้าใกล้: $placeName'),
              backgroundColor: Colors.green,
            ),
          );
          _lastNotifiedPoint = closestPoint;
        }
      }
    } else {
      // ถ้าออกนอกระยะ ให้ยกเลิกการไฮไลท์
      if (_highlightedPoint != null) {
        setState(() {
          _highlightedPoint = null;
          _lastNotifiedPoint = null; // Reset notified point
        });
      }
    }
  }

  /// --- เลื่อนแผนที่ไปตำแหน่งปัจจุบันของผู้ใช้ ---
  Future<void> _centerOnUser() async {
    try {
      final position = await Geolocator.getCurrentPosition();
      _animatedMapMove(LatLng(position.latitude, position.longitude), 17.5);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ไม่สามารถดึงตำแหน่งปัจจุบันได้: $e')),
        );
      }
    }
  }

  /// --- เปิด Google Maps เพื่อนำทาง ---
  Future<void> _launchGoogleMaps(double lat, double lon) async {
    // สร้าง Uri สำหรับ Google Maps Navigation
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$lat,$lon',
    );
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ไม่สามารถเปิด Google Maps ได้')),
        );
      }
    }
  }

  /// --- สร้าง Animation สำหรับการเลื่อนแผนที่อย่างนุ่มนวล ---
  void _animatedMapMove(LatLng destLocation, double destZoom) {
    // สร้าง Tweens สำหรับการเปลี่ยนค่า lat, long, และ zoom
    final latTween = Tween<double>(
      begin: _mapController.camera.center.latitude,
      end: destLocation.latitude,
    );
    final lngTween = Tween<double>(
      begin: _mapController.camera.center.longitude,
      end: destLocation.longitude,
    );
    final zoomTween = Tween<double>(
      begin: _mapController.camera.zoom,
      end: destZoom,
    );

    // สร้าง AnimationController
    final controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    // เพิ่ม Controller ที่สร้างใหม่เข้าไปใน List เพื่อติดตาม
    _animationControllers.add(controller);

    final animation = CurvedAnimation(
      parent: controller,
      curve: Curves.fastOutSlowIn,
    );

    // เมื่อค่า animation เปลี่ยน ให้ขยับแผนที่ (Listener นี้จะถูก dispose ไปพร้อมกับ controller)
    controller.addListener(() {
      _mapController.move(
        LatLng(latTween.evaluate(animation), lngTween.evaluate(animation)),
        zoomTween.evaluate(animation),
      );
    });

    // เมื่อ animation จบ ให้ dispose controller เพื่อคืน memory
    animation.addStatusListener((status) {
      if (status == AnimationStatus.completed ||
          status == AnimationStatus.dismissed) {
        controller.dispose();
        // เมื่อ dispose แล้ว ให้นำออกจาก List ด้วย
        _animationControllers.remove(controller);
      }
    });

    controller.forward();
  }

  @override
  void dispose() {
    // วนลูปเพื่อ dispose AnimationController ทุกตัวที่อาจจะยังค้างอยู่
    for (final controller in _animationControllers) {
      controller.dispose();
    }
    _locationSubscription?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('แผนที่และเส้นทาง')),
      // --- จัดการ UI ตามเงื่อนไข ---
      body: _placesData.isEmpty
          // 1. กรณีไม่มีข้อมูลพิกัดเลย
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.map_outlined, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'ไม่มีข้อมูลพิกัดสำหรับทริปนี้',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            )
          // 2. กรณีมีข้อมูลพิกัด (1 จุดขึ้นไป)
          : FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: const LatLng(
                  13.736717,
                  100.523186,
                ), // Default to Bangkok
                initialZoom: 5,
                onMapReady: () {
                  // เมื่อแผนที่พร้อมใช้งาน ให้ปรับมุมกล้อง
                  if (_placesData.length > 1 && _bounds != null) {
                    // กรณีมีหลายจุด: ซูมให้เห็นทุกจุด
                    _mapController.fitCamera(
                      CameraFit.bounds(
                        bounds: _bounds!,
                        padding: const EdgeInsets.all(80.0),
                      ),
                    );
                  } else if (_placesData.length == 1) {
                    // กรณีมีจุดเดียว: เลื่อนไปที่จุดนั้น
                    _mapController.move(
                      _placesData.first['point'] as LatLng,
                      17.5,
                    );
                  }
                },
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://tiles.stadiamaps.com/tiles/outdoors/{z}/{x}/{y}{r}.png?api_key={apiKey}',
                  additionalOptions: {
                    // นำ API Key ที่คัดลอกมาวางตรงนี้ครับ
                    'apiKey': 'f2f873e4-56f1-4420-8ba3-86cfd547ce96',
                  },
                  userAgentPackageName: 'easytrip_frontend',
                ),

                // --- Layer สำหรับแสดงตำแหน่งปัจจุบันของผู้ใช้ ---
                CurrentLocationLayer(
                  style: LocationMarkerStyle(
                    marker: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.person_pin,
                        color: Colors.blue.shade600,
                        size: 22,
                      ),
                    ),
                    markerSize: const Size(30, 30),
                  ),
                ),

                // วาดเส้นทางเมื่อมีตั้งแต่ 2 จุดขึ้นไปเท่านั้น
                if (_placesData.length > 1)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: _placesData
                            .map((p) => p['point'] as LatLng)
                            .toList(),
                        strokeWidth: 4.0,
                        gradientColors: [
                          Colors.blue.shade900,
                          Colors.lightBlueAccent,
                        ],
                      ),
                    ],
                  ),
                MarkerLayer(markers: _buildAllMarkers()),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _centerOnUser,
        tooltip: 'ตำแหน่งของฉัน',
        child: const Icon(Icons.my_location),
      ),
    );
  }

  /// --- สร้าง Markers ทั้งหมดจาก _placesData ---
  List<Marker> _buildAllMarkers() {
    final markers = <Marker>[];
    for (var place in _placesData) {
      final point = place['point'] as LatLng;
      final name = place['name'] as String;
      final index = place['index'] as int;

      // ตรวจสอบว่าหมุดนี้เป็นหมุดที่ถูกไฮไลท์หรือไม่
      final isHighlighted = _highlightedPoint == point;

      // 1. ไอคอนพร้อมตัวเลขและ Gesture Detector สำหรับซูม
      markers.add(
        Marker(
          point: point,
          width: 45,
          height: 45,
          alignment: Alignment.bottomCenter,
          child: GestureDetector(
            onTap: () {
              _animatedMapMove(point, 17.5);
            },
            // ทำให้ไอคอนเรียบง่ายขึ้นโดยการเอาตัวเลขออก
            child: Icon(
              Icons.location_on,
              // เปลี่ยนสีถ้าถูกไฮไลท์
              color: isHighlighted ? Colors.green : Colors.red,
              size: 45,
            ),
          ),
        ),
      );

      // 2. ชื่อสถานที่ ที่จะแสดงใต้ไอคอน
      markers.add(
        Marker(
          point: point,
          width: 150, // กำหนดความกว้างเพื่อให้ Marker แสดงผล
          height: 30, // กำหนดความสูงเพื่อให้ Marker แสดงผล
          alignment: Alignment.topCenter,
          child: GestureDetector(
            onTap: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  // ใช้ Dialog ที่ปรับปรุงใหม่ตามหลัก Material 3
                  return _NavigationConfirmationDialog(
                    title: '$index. $name',
                    onConfirm: () =>
                        _launchGoogleMaps(point.latitude, point.longitude),
                  );
                },
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.85),
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 4),
                ],
              ),
              child: Text(
                // รวมเลขลำดับเข้ากับชื่อสถานที่
                '$index. $name',
                style: const TextStyle(fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ),
        ),
      );
    }
    return markers;
  }
}

/// A modern, Material 3-style dialog for navigation confirmation.
class _NavigationConfirmationDialog extends StatelessWidget {
  final String title;
  final VoidCallback onConfirm;

  const _NavigationConfirmationDialog({
    required this.title,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28.0)),
      titlePadding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 0),
      contentPadding: const EdgeInsets.fromLTRB(24.0, 20.0, 24.0, 24.0),
      actionsPadding: const EdgeInsets.fromLTRB(24.0, 0, 24.0, 24.0),
      title: Row(
        children: [
          Icon(Icons.location_on_outlined, color: theme.colorScheme.secondary),
          const SizedBox(width: 16),
          Expanded(child: Text(title, style: theme.textTheme.headlineSmall)),
        ],
      ),
      content: Text(
        'คุณต้องการนำทางไปยังสถานที่นี้หรือไม่?',
        style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
      ),
      actions: <Widget>[
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop(); // Close dialog first
            onConfirm();
          },
          child: const Text('นำทาง'),
        ),
        TextButton(
          child: const Text('ยกเลิก'),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}
