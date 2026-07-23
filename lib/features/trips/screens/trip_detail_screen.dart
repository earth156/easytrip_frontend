import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import '../services/trip_repository.dart';
import 'trip_map_screen.dart';

// ─── Color palette & constants ────────────────────────────────────────────────
const _kPrimary = Color(0xFF00897B); // teal 600
const _kPrimaryLight = Color(0xFFB2DFDB); // teal 100
const _kAccent = Color(0xFFFF7043); // deep orange 400
const _kBg = Color(0xFFF5F7FA);
const _kCardBg = Colors.white;
const _kTextPrimary = Color(0xFF1A2340);
const _kTextSecondary = Color(0xFF6B7A99);
const _kHeaderHeight = 300.0;

class TripDetailScreen extends StatelessWidget {
  final String tripId;

  const TripDetailScreen({super.key, required this.tripId});

  @override
  Widget build(BuildContext context) {
    final TripRepository tripRepository = TripRepository();

    return FutureBuilder<Map<String, dynamic>>(
      future: tripRepository.getTripDetails(tripId),
      builder: (context, snapshot) {
        // ── 1. Loading ─────────────────────────────────────────────────────
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _LoadingView();
        }

        // ── 2. Error ───────────────────────────────────────────────────────
        if (snapshot.hasError) {
          return _ErrorView(message: '${snapshot.error}');
        }

        // ── 3. No Data ─────────────────────────────────────────────────────
        if (!snapshot.hasData || snapshot.data == null) {
          return const _EmptyView();
        }

        // ── 4. Success ─────────────────────────────────────────────────────
        final tripData = snapshot.data!;
        final String title = tripData['title'] ?? 'รายละเอียดทริป';
        final List<dynamic> itinerary = tripData['itinerary'] ?? [];
        final String status = tripData['status'] ?? 'unknown';
        final String? imageUrl = tripData['image_url'];

        // ── 4a. Processing / Failed ────────────────────────────────────────
        if (status == 'processing' || status == 'failed') {
          return _StatusView(status: status, tripData: tripData, title: title);
        }

        // ── 4b. Ready ──────────────────────────────────────────────────────
        return _TripDetailView(
          title: title,
          imageUrl: imageUrl,
          itinerary: itinerary,
          tripData: tripData,
        );
      },
    );
  }
}

// ─── Loading View ─────────────────────────────────────────────────────────────
class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: Shimmer.fromColors(
        baseColor: Colors.grey.shade200,
        highlightColor: Colors.grey.shade50,
        child: Column(
          children: [
            Container(height: _kHeaderHeight, color: Colors.white),
            const SizedBox(height: 16),
            ...List.generate(
              3,
              (_) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Container(
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Error View ───────────────────────────────────────────────────────────────
class _ErrorView extends StatelessWidget {
  final String message;
  const _ErrorView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(children: [const _BackButton()]),
            ),
            const Spacer(),
            const Icon(Icons.wifi_off_rounded, size: 72, color: _kAccent),
            const SizedBox(height: 16),
            const Text(
              'เกิดข้อผิดพลาด',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: _kTextPrimary),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(message, textAlign: TextAlign.center, style: const TextStyle(color: _kTextSecondary)),
            ),
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_rounded),
                label: const Text('กลับไปหน้าก่อน'),
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}

// ─── Empty View ───────────────────────────────────────────────────────────────
class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(children: [const _BackButton()]),
            ),
            const Spacer(),
            const Icon(Icons.luggage_outlined, size: 72, color: _kTextSecondary),
            const SizedBox(height: 16),
            const Text(
              'ไม่พบข้อมูลทริป',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _kTextPrimary),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}

// ─── Status (Processing / Failed) View ───────────────────────────────────────
class _StatusView extends StatelessWidget {
  final String status;
  final Map<String, dynamic> tripData;
  final String title;

  const _StatusView({required this.status, required this.tripData, required this.title});

  @override
  Widget build(BuildContext context) {
    final bool isProcessing = status == 'processing';
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const _BackButton(),
        title: Text(title, style: const TextStyle(color: _kTextPrimary, fontWeight: FontWeight.bold)),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: (isProcessing ? _kPrimary : _kAccent).withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isProcessing ? Icons.hourglass_bottom_rounded : Icons.error_outline_rounded,
                  size: 52,
                  color: isProcessing ? _kPrimary : _kAccent,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                isProcessing ? 'กำลังสร้างแผนทริป...' : 'การสร้างทริปล้มเหลว',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: _kTextPrimary),
              ),
              const SizedBox(height: 12),
              Text(
                isProcessing
                    ? 'AI กำลังวิเคราะห์และวางแผนเส้นทางที่ดีที่สุดสำหรับคุณ กรุณารอสักครู่'
                    : 'ขออภัย เกิดข้อผิดพลาด: ${tripData['error_message'] ?? 'ไม่ทราบสาเหตุ'}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: _kTextSecondary, fontSize: 15),
              ),
              if (isProcessing) ...[
                const SizedBox(height: 32),
                const LinearProgressIndicator(color: _kPrimary, backgroundColor: _kPrimaryLight),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Main Trip Detail View ────────────────────────────────────────────────────
class _TripDetailView extends StatelessWidget {
  final String title;
  final String? imageUrl;
  final List<dynamic> itinerary;
  final Map<String, dynamic> tripData;

  const _TripDetailView({
    required this.title,
    required this.imageUrl,
    required this.itinerary,
    required this.tripData,
  });

  @override
  Widget build(BuildContext context) {
    int totalActivities = 0;
    int totalCost = 0;
    for (final day in itinerary) {
      final activities = (day as Map<String, dynamic>)['activities'] ?? [];
      totalActivities += (activities as List).length;
      for (final act in activities) {
        totalCost += ((act as Map<String, dynamic>)['estimatedCost'] ?? 0) as int;
      }
    }

    return Scaffold(
      backgroundColor: _kBg,
      body: CustomScrollView(
        slivers: [
          // ── Hero App Bar ─────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: _kHeaderHeight,
            pinned: true,
            backgroundColor: _kPrimary,
            leading: const Padding(
              padding: EdgeInsets.all(8),
              child: _BackButton(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.parallax,
              titlePadding: const EdgeInsets.only(left: 16, right: 72, bottom: 16),
              title: Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  shadows: [Shadow(blurRadius: 8, color: Colors.black54, offset: Offset(0, 2))],
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: imageUrl ??
                        'https://images.unsplash.com/photo-1476514525535-07fb3b4ae5f1?q=80&w=1170&auto=format&fit=crop',
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Shimmer.fromColors(
                      baseColor: Colors.grey.shade300,
                      highlightColor: Colors.grey.shade100,
                      child: Container(color: Colors.white),
                    ),
                    errorWidget: (_, __, ___) => Container(
                      color: _kPrimaryLight,
                      child: const Icon(Icons.image_not_supported_outlined, color: _kPrimary, size: 48),
                    ),
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                        stops: const [0.4, 1.0],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Stats Bar ────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _StatsBar(days: itinerary.length, activities: totalActivities, totalCost: totalCost),
          ),

          // ── Section title ─────────────────────────────────────────────────
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 4),
              child: Text(
                'แผนการเดินทาง',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _kTextPrimary),
              ),
            ),
          ),

          // ── Day Cards ────────────────────────────────────────────────────
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final dayData = itinerary[index] as Map<String, dynamic>;
                final activities = dayData['activities'] ?? [];
                return _DayCard(
                  dayData: dayData,
                  activities: activities as List,
                  isLast: index == itinerary.length - 1,
                );
              },
              childCount: itinerary.length,
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 96)),
        ],
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => TripMapScreen(itinerary: itinerary)),
        ),
        backgroundColor: _kAccent,
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.map_rounded),
        label: const Text('ดูแผนที่', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}

// ─── Stats Bar ────────────────────────────────────────────────────────────────
class _StatsBar extends StatelessWidget {
  final int days;
  final int activities;
  final int totalCost;

  const _StatsBar({required this.days, required this.activities, required this.totalCost});

  @override
  Widget build(BuildContext context) {
    final costFormatted = NumberFormat('#,##0', 'en_US').format(totalCost);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 16, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          _StatItem(icon: Icons.calendar_month_rounded, value: '$days', label: 'วัน', color: _kPrimary),
          _StatDivider(),
          _StatItem(icon: Icons.place_rounded, value: '$activities', label: 'กิจกรรม', color: const Color(0xFF5C6BC0)),
          _StatDivider(),
          _StatItem(icon: Icons.account_balance_wallet_rounded, value: '฿$costFormatted', label: 'ค่าใช้จ่าย', color: _kAccent),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatItem({required this.icon, required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16)),
          Text(label, style: const TextStyle(color: _kTextSecondary, fontSize: 12)),
        ],
      ),
    );
  }
}

class _StatDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(height: 40, width: 1, color: Colors.grey.shade200);
  }
}

// ─── Day Card ─────────────────────────────────────────────────────────────────
class _DayCard extends StatelessWidget {
  final Map<String, dynamic> dayData;
  final List activities;
  final bool isLast;

  const _DayCard({required this.dayData, required this.activities, required this.isLast});

  @override
  Widget build(BuildContext context) {
    final int dayNumber = dayData['day'] ?? 0;
    final String date = dayData['date'] ?? '';

    String displayDate = date;
    try {
      final parsed = DateFormat('yyyy-MM-dd').parse(date);
      displayDate = DateFormat('EEE, d MMM', 'th').format(parsed);
    } catch (_) {}

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 8, 16, isLast ? 8 : 4),
      child: Container(
        decoration: BoxDecoration(
          color: _kCardBg,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Day Header ─────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: const BoxDecoration(
                color: _kPrimary,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'DAY $dayNumber',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(displayDate, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${activities.length} กิจกรรม',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),

            // ── Activities ─────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                children: activities.asMap().entries.map((entry) {
                  return _ActivityItem(
                    activity: entry.value as Map<String, dynamic>,
                    isLast: entry.key == activities.length - 1,
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Activity Item (Timeline style) ──────────────────────────────────────────
class _ActivityItem extends StatelessWidget {
  final Map<String, dynamic> activity;
  final bool isLast;

  const _ActivityItem({required this.activity, required this.isLast});

  IconData _iconForActivity(String? name) {
    if (name == null) return Icons.place_rounded;
    final lower = name.toLowerCase();
    if (lower.contains('ร้าน') || lower.contains('อาหาร') || lower.contains('กิน') || lower.contains('คาเฟ่')) {
      return Icons.restaurant_rounded;
    }
    if (lower.contains('โรงแรม') || lower.contains('ที่พัก') || lower.contains('resort')) {
      return Icons.hotel_rounded;
    }
    if (lower.contains('ทะเล') || lower.contains('หาด') || lower.contains('beach')) {
      return Icons.beach_access_rounded;
    }
    if (lower.contains('วัด') || lower.contains('temple')) {
      return Icons.account_balance_rounded;
    }
    if (lower.contains('ห้าง') || lower.contains('shopping')) {
      return Icons.shopping_bag_rounded;
    }
    return Icons.place_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final cost = NumberFormat('#,##0', 'en_US').format(activity['estimatedCost'] ?? 0);
    final timeSlot = activity['timeSlot'] ?? '';
    final placeName = activity['placeName'] ?? 'ไม่มีชื่อสถานที่';
    final description = activity['description'] ?? 'ไม่มีคำอธิบาย';

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Timeline dot + line ──────────────────────────────────────────
          SizedBox(
            width: 32,
            child: Column(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(color: _kPrimary.withOpacity(0.1), shape: BoxShape.circle),
                  child: Icon(_iconForActivity(placeName), size: 16, color: _kPrimary),
                ),
                if (!isLast)
                  Expanded(
                    child: Center(
                      child: Container(width: 2, color: _kPrimaryLight),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // ── Content ──────────────────────────────────────────────────────
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (timeSlot.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: _kPrimaryLight, borderRadius: BorderRadius.circular(6)),
                      child: Text(
                        timeSlot,
                        style: const TextStyle(color: _kPrimary, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          placeName,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: _kTextPrimary),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '฿$cost',
                        style: const TextStyle(color: _kAccent, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(color: _kTextSecondary, fontSize: 13, height: 1.5),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Back Button ──────────────────────────────────────────────────────────────
class _BackButton extends StatelessWidget {
  const _BackButton();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.maybePop(context),
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: _kTextPrimary),
      ),
    );
  }
}
