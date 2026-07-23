import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/utils/custom_dialogs.dart';
import '../controller/trip_controller.dart';
import 'home_screen.dart';

// ─── Color palette ─────────────────────────────────────────────────────────────
const _kPrimary = Color(0xFF00897B);
const _kPrimaryLight = Color(0xFFB2DFDB);
const _kAccent = Color(0xFFFF7043);
const _kBg = Color(0xFFF5F7FA);
const _kTextPrimary = Color(0xFF1A2340);
const _kTextSecondary = Color(0xFF6B7A99);
const _kCardBg = Colors.white;

/// หน้าจอสำหรับแสดงผลลัพธ์แผนการเดินทางที่ AI สร้างให้
class TripPlanScreen extends StatefulWidget {
  final Map<String, dynamic> tripPlan;

  const TripPlanScreen({super.key, required this.tripPlan});

  @override
  State<TripPlanScreen> createState() => _TripPlanScreenState();
}

class _TripPlanScreenState extends State<TripPlanScreen> {
  final TripController _tripController = TripController();
  bool _isDeleting = false;

  @override
  Widget build(BuildContext context) {
    final List<dynamic> itinerary = widget.tripPlan['itinerary'] ?? [];
    final String tripTitle =
        widget.tripPlan['title'] ?? widget.tripPlan['tripTitle'] ?? 'แผนการเดินทางของคุณ';

    return Scaffold(
      backgroundColor: _kBg,
      body: CustomScrollView(
        slivers: [
          // ── Hero App Bar ─────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: _kPrimary,
            leading: Padding(
              padding: const EdgeInsets.all(8),
              child: _CircleBackButton(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.parallax,
              titlePadding: const EdgeInsets.only(left: 16, right: 72, bottom: 16),
              title: Text(
                tripTitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  shadows: [Shadow(blurRadius: 8, color: Colors.black54, offset: Offset(0, 2))],
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Gradient background
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF00695C), Color(0xFF00897B), Color(0xFF26A69A)],
                      ),
                    ),
                  ),
                  // Decorative circles
                  Positioned(
                    top: -30,
                    right: -30,
                    child: Container(
                      width: 160,
                      height: 160,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.06),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 20,
                    left: -20,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.06),
                      ),
                    ),
                  ),
                  // AI badge
                  Positioned(
                    top: 70,
                    right: 20,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withOpacity(0.3)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.auto_awesome_rounded, color: Colors.amber, size: 14),
                          SizedBox(width: 5),
                          Text(
                            'สร้างโดย AI',
                            style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Stats Banner ─────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _StatsBanner(tripPlan: widget.tripPlan, itinerary: itinerary),
          ),

          // ── Section Title ─────────────────────────────────────────────────
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 4),
              child: Row(
                children: [
                  Icon(Icons.route_rounded, color: _kPrimary, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'แผนการเดินทาง',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: _kTextPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Day Items ─────────────────────────────────────────────────────
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => _DaySection(
                dayPlan: itinerary[index] as Map<String, dynamic>,
                isLast: index == itinerary.length - 1,
              ),
              childCount: itinerary.length,
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),

      // ── Bottom Action Bar ─────────────────────────────────────────────────
      bottomNavigationBar: _BottomActionBar(
        isDeleting: _isDeleting,
        onDiscard: _handleDiscardAndCreateNew,
        onConfirm: () {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const HomeScreen()),
            (route) => false,
          );
        },
      ),
    );
  }

  void _handleDiscardAndCreateNew() async {
    final confirmed = await CustomDialogs.showConfirmDialog(
      context: context,
      title: 'สร้างแผนใหม่?',
      message: 'แผนการเดินทางปัจจุบันจะถูกลบ และคุณจะกลับไปที่หน้าสร้างทริป',
      confirmText: 'สร้างใหม่',
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isDeleting = true);
    await _tripController.discardAndCreateNew(context, widget.tripPlan['id']);
    if (mounted) setState(() => _isDeleting = false);
  }
}

// ─── Stats Banner ─────────────────────────────────────────────────────────────
class _StatsBanner extends StatelessWidget {
  final Map<String, dynamic> tripPlan;
  final List<dynamic> itinerary;

  const _StatsBanner({required this.tripPlan, required this.itinerary});

  @override
  Widget build(BuildContext context) {
    int totalActivities = 0;
    for (final day in itinerary) {
      totalActivities += ((day as Map<String, dynamic>)['activities'] as List? ?? []).length;
    }

    final rawCost = tripPlan['estimated_total_cost'];
    final costStr = rawCost != null
        ? NumberFormat('#,##0', 'en_US').format(rawCost is double ? rawCost.toInt() : rawCost)
        : 'N/A';
    final daysCount = tripPlan['days_count'] ?? itinerary.length;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 16, offset: const Offset(0, 6)),
        ],
      ),
      child: Row(
        children: [
          _StatCell(icon: Icons.calendar_month_rounded, value: '$daysCount', label: 'วัน', color: _kPrimary),
          _VertDivider(),
          _StatCell(icon: Icons.place_rounded, value: '$totalActivities', label: 'กิจกรรม', color: const Color(0xFF5C6BC0)),
          _VertDivider(),
          _StatCell(icon: Icons.account_balance_wallet_rounded, value: '฿$costStr', label: 'ค่าใช้จ่าย', color: _kAccent),
        ],
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatCell({required this.icon, required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 15)),
          Text(label, style: const TextStyle(color: _kTextSecondary, fontSize: 11)),
        ],
      ),
    );
  }
}

class _VertDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 48, color: Colors.grey.shade200);
}

// ─── Day Section ──────────────────────────────────────────────────────────────
class _DaySection extends StatelessWidget {
  final Map<String, dynamic> dayPlan;
  final bool isLast;

  const _DaySection({required this.dayPlan, required this.isLast});

  @override
  Widget build(BuildContext context) {
    final List<dynamic> activities = dayPlan['activities'] ?? [];
    final int dayNumber = dayPlan['day'] ?? 0;
    final String date = dayPlan['date'] ?? '';

    String displayDate = date;
    try {
      final parsed = DateFormat('dd/MM/yyyy').parse(date);
      displayDate = DateFormat('EEE, d MMM', 'th').format(parsed);
    } catch (_) {}

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 12, 16, isLast ? 12 : 4),
      child: Container(
        decoration: BoxDecoration(
          color: _kCardBg,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Day Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF00897B), Color(0xFF26A69A)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
                    child: Text(
                      displayDate,
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
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

            // Activities Timeline
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                children: activities.asMap().entries.map((e) {
                  return _ActivityItem(
                    activity: e.value as Map<String, dynamic>,
                    index: e.key,
                    isLast: e.key == activities.length - 1,
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

// ─── Activity Item ────────────────────────────────────────────────────────────
class _ActivityItem extends StatefulWidget {
  final Map<String, dynamic> activity;
  final int index;
  final bool isLast;

  const _ActivityItem({
    required this.activity,
    required this.index,
    required this.isLast,
  });

  @override
  State<_ActivityItem> createState() => _ActivityItemState();
}

class _ActivityItemState extends State<_ActivityItem> {
  bool _expanded = false;

  IconData _iconFor(String? name) {
    if (name == null) return Icons.place_rounded;
    final l = name.toLowerCase();
    if (l.contains('ร้าน') || l.contains('อาหาร') || l.contains('กิน') || l.contains('คาเฟ่')) {
      return Icons.restaurant_rounded;
    }
    if (l.contains('โรงแรม') || l.contains('ที่พัก')) return Icons.hotel_rounded;
    if (l.contains('ทะเล') || l.contains('หาด')) return Icons.beach_access_rounded;
    if (l.contains('วัด') || l.contains('temple')) return Icons.account_balance_rounded;
    if (l.contains('ห้าง') || l.contains('shopping')) return Icons.shopping_bag_rounded;
    if (l.contains('สวน') || l.contains('ป่า')) return Icons.park_rounded;
    return Icons.place_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final act = widget.activity;
    final String placeName = act['placeName'] ?? 'ไม่มีชื่อสถานที่';
    final String timeSlot = act['timeSlot'] ?? '';
    final String description = act['description'] ?? '';
    final num rawCost = act['estimatedCost'] ?? 0;
    final String costStr = NumberFormat('#,##0', 'en_US').format(rawCost);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Timeline ──────────────────────────────────────────────────
          SizedBox(
            width: 36,
            child: Column(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _kPrimary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(_iconFor(placeName), size: 18, color: _kPrimary),
                ),
                if (!widget.isLast)
                  Expanded(
                    child: Center(
                      child: Container(
                        width: 2,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [_kPrimaryLight, _kPrimaryLight.withOpacity(0.2)],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // ── Content Card ─────────────────────────────────────────────
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _expanded = !_expanded),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: EdgeInsets.only(bottom: widget.isLast ? 0 : 14),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _expanded ? _kPrimary.withOpacity(0.04) : const Color(0xFFF8FAFB),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _expanded ? _kPrimary.withOpacity(0.3) : Colors.grey.shade200,
                    width: _expanded ? 1.5 : 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Time + cost row
                    Row(
                      children: [
                        if (timeSlot.isNotEmpty) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: _kPrimaryLight,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              timeSlot,
                              style: const TextStyle(color: _kPrimary, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const Spacer(),
                        ],
                        Text(
                          '฿$costStr',
                          style: const TextStyle(
                            color: _kAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: 4),
                        AnimatedRotation(
                          turns: _expanded ? 0.5 : 0,
                          duration: const Duration(milliseconds: 200),
                          child: const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: _kTextSecondary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Place name
                    Text(
                      placeName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: _kTextPrimary,
                      ),
                    ),
                    // Description (expandable)
                    if (_expanded && description.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Container(
                        height: 1,
                        color: _kPrimary.withOpacity(0.1),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.info_outline_rounded, size: 14, color: _kPrimary),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              description,
                              style: const TextStyle(
                                color: _kTextSecondary,
                                fontSize: 13,
                                height: 1.6,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Circle Back Button ───────────────────────────────────────────────────────
class _CircleBackButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.maybePop(context),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: Colors.white),
      ),
    );
  }
}

// ─── Bottom Action Bar ────────────────────────────────────────────────────────
class _BottomActionBar extends StatelessWidget {
  final bool isDeleting;
  final VoidCallback onDiscard;
  final VoidCallback onConfirm;

  const _BottomActionBar({
    required this.isDeleting,
    required this.onDiscard,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 16, offset: const Offset(0, -4)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Discard button
            Expanded(
              child: GestureDetector(
                onTap: isDeleting ? null : onDiscard,
                child: Container(
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Center(
                    child: isDeleting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.refresh_rounded, size: 18, color: _kTextSecondary),
                              SizedBox(width: 6),
                              Text(
                                'สร้างแผนใหม่',
                                style: TextStyle(
                                  color: _kTextPrimary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Confirm button
            Expanded(
              flex: 2,
              child: GestureDetector(
                onTap: onConfirm,
                child: Container(
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF00897B), Color(0xFF26A69A)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: _kPrimary.withOpacity(0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'ยืนยันทริปนี้!',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
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
