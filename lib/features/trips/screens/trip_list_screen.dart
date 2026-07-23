import 'package:cached_network_image/cached_network_image.dart';
import 'package:easytrip_frontend/features/trips/controller/trip_controller.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../models/trip_model.dart';
import '../../../core/utils/custom_dialogs.dart';
import 'trip_detail_screen.dart';

// ─── Color palette ─────────────────────────────────────────────────────────────
const _kPrimary = Color(0xFF00897B);
const _kAccent = Color(0xFFFF7043);
const _kBg = Color(0xFFF5F7FA);
const _kCardBg = Colors.white;
const _kTextPrimary = Color(0xFF1A2340);
const _kTextSecondary = Color(0xFF6B7A99);

class TripListScreen extends StatefulWidget {
  const TripListScreen({super.key});

  @override
  State<TripListScreen> createState() => _TripListScreenState();
}

class _TripListScreenState extends State<TripListScreen>
    with SingleTickerProviderStateMixin {
  final TripController _tripController = TripController();
  late Future<List<Trip>> _tripsFuture;
  late AnimationController _fabController;

  @override
  void initState() {
    super.initState();
    _fabController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..forward();
    _loadTrips();
  }

  @override
  void dispose() {
    _fabController.dispose();
    super.dispose();
  }

  void _loadTrips() {
    setState(() {
      _tripsFuture = _tripController.getMyTrips();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          _buildSliverHeader(innerBoxIsScrolled),
        ],
        body: FutureBuilder<List<Trip>>(
          future: _tripsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _LoadingSkeletonList();
            }
            if (snapshot.hasError) {
              return _buildErrorState(snapshot.error.toString());
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return _buildEmptyState();
            }
            return _buildTripListView(snapshot.data!);
          },
        ),
      ),
    );
  }

  // ─── Sliver App Bar ─────────────────────────────────────────────────────────
  Widget _buildSliverHeader(bool innerBoxIsScrolled) {
    return SliverAppBar(
      expandedHeight: 130,
      floating: true,
      snap: true,
      pinned: false,
      backgroundColor: _kPrimary,
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.pin,
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF00897B), Color(0xFF26A69A)],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'ทริปของฉัน ✈️',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      // Refresh button
                      GestureDetector(
                        onTap: _loadTrips,
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.refresh_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'แผนการเดินทางทั้งหมดของคุณ',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Empty State ─────────────────────────────────────────────────────────────
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: _kPrimary.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.card_travel_rounded,
                size: 56,
                color: _kPrimary,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'ยังไม่มีแผนการเดินทาง',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _kTextPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'เริ่มสร้างทริปแรกของคุณ\nแล้วปล่อยให้ AI ช่วยวางแผน!',
              textAlign: TextAlign.center,
              style: TextStyle(color: _kTextSecondary, fontSize: 15, height: 1.6),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/create-trip'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _kPrimary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              icon: const Icon(Icons.add_rounded),
              label: const Text(
                'สร้างทริปแรก',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Error State ─────────────────────────────────────────────────────────────
  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: _kAccent.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.wifi_off_rounded, size: 48, color: _kAccent),
            ),
            const SizedBox(height: 20),
            const Text(
              'โหลดข้อมูลไม่สำเร็จ',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _kTextPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(color: _kTextSecondary, fontSize: 13),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: _loadTrips,
              style: ElevatedButton.styleFrom(
                backgroundColor: _kPrimary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('ลองอีกครั้ง', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  // ─── List View ────────────────────────────────────────────────────────────────
  Widget _buildTripListView(List<Trip> trips) {
    return RefreshIndicator(
      onRefresh: () async => _loadTrips(),
      color: _kPrimary,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        itemCount: trips.length,
        itemBuilder: (context, index) {
          final trip = trips[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Dismissible(
              key: Key(trip.id),
              direction: DismissDirection.endToStart,
              confirmDismiss: (_) async {
                final bool? confirmed = await CustomDialogs.showConfirmDeleteDialog(
                  context: context,
                  title: 'ยืนยันการลบทริป?',
                  message: "ข้อมูลทริป '${trip.title}' จะถูกลบอย่างถาวร",
                );
                if (confirmed ?? false) {
                  try {
                    await _tripController.deleteTrip(trip.id);
                    return true;
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('ลบทริปล้มเหลว: $e'),
                          backgroundColor: _kAccent,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      );
                    }
                    return false;
                  }
                }
                return false;
              },
              onDismissed: (_) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('ลบ "${trip.title}" แล้ว'),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                );
                _loadTrips();
              },
              // ── Delete background ──────────────────────────────────────────
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                decoration: BoxDecoration(
                  color: const Color(0xFFE53935),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.delete_rounded, color: Colors.white, size: 28),
                    SizedBox(height: 4),
                    Text(
                      'ลบ',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ],
                ),
              ),
              child: _TripCard(
                trip: trip,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => TripDetailScreen(tripId: trip.id)),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─── Trip Card ────────────────────────────────────────────────────────────────
class _TripCard extends StatelessWidget {
  final Trip trip;
  final VoidCallback onTap;

  const _TripCard({required this.trip, required this.onTap});

  static const _defaultImage =
      'https://images.unsplash.com/photo-1501785888041-af3ef285b470?q=80&w=1170&auto=format&fit=crop';

  Color get _statusColor {
    switch (trip.status) {
      case 'completed':
        return const Color(0xFF26A69A);
      case 'processing':
        return const Color(0xFF5C6BC0);
      case 'failed':
        return _kAccent;
      default:
        return const Color(0xFF26A69A);
    }
  }

  String get _statusLabel {
    switch (trip.status) {
      case 'completed':
        return 'พร้อมใช้งาน';
      case 'processing':
        return 'กำลังสร้าง...';
      case 'failed':
        return 'สร้างไม่สำเร็จ';
      default:
        return 'พร้อมใช้งาน';
    }
  }

  IconData get _statusIcon {
    switch (trip.status) {
      case 'processing':
        return Icons.hourglass_bottom_rounded;
      case 'failed':
        return Icons.error_outline_rounded;
      default:
        return Icons.check_circle_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = (trip.imageUrl != null && trip.imageUrl!.isNotEmpty)
        ? trip.imageUrl!
        : _defaultImage;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: _kCardBg,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.07),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Image Section ──────────────────────────────────────────────
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: Stack(
                children: [
                  CachedNetworkImage(
                    imageUrl: imageUrl,
                    height: 160,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Shimmer.fromColors(
                      baseColor: Colors.grey.shade200,
                      highlightColor: Colors.grey.shade50,
                      child: Container(height: 160, color: Colors.white),
                    ),
                    errorWidget: (_, __, ___) => Image.network(
                      _defaultImage,
                      height: 160,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  // Gradient overlay
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Colors.black.withOpacity(0.4)],
                          stops: const [0.5, 1.0],
                        ),
                      ),
                    ),
                  ),
                  // Status badge
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: _statusColor,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(color: _statusColor.withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 2)),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_statusIcon, color: Colors.white, size: 12),
                          const SizedBox(width: 4),
                          Text(
                            _statusLabel,
                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Swipe hint
                  Positioned(
                    bottom: 10,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.35),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.swipe_left_rounded, color: Colors.white54, size: 12),
                          SizedBox(width: 4),
                          Text(
                            'ปัดเพื่อลบ',
                            style: TextStyle(color: Colors.white54, fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Info Section ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    trip.title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: _kTextPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _InfoChip(
                        icon: Icons.calendar_today_rounded,
                        label: '${trip.daysCount} วัน',
                        color: _kPrimary,
                      ),
                      const SizedBox(width: 8),
                      _InfoChip(
                        icon: Icons.account_balance_wallet_rounded,
                        label: '฿${trip.budget?.toStringAsFixed(0) ?? 'N/A'}',
                        color: _kAccent,
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 14,
                        color: _kTextSecondary,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Info Chip ─────────────────────────────────────────────────────────────────
class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

// ─── Loading Skeleton ─────────────────────────────────────────────────────────
class _LoadingSkeletonList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      itemCount: 4,
      itemBuilder: (_, __) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Shimmer.fromColors(
          baseColor: Colors.grey.shade200,
          highlightColor: Colors.grey.shade50,
          child: Container(
            height: 240,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
      ),
    );
  }
}
