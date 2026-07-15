import 'package:flutter/material.dart';

/// หน้าจอสำหรับแสดงผลลัพธ์แผนการเดินทางที่ AI สร้างให้
class TripPlanScreen extends StatefulWidget {
  final Map<String, dynamic> tripPlan;

  const TripPlanScreen({super.key, required this.tripPlan});

  @override
  State<TripPlanScreen> createState() => _TripPlanScreenState();
}

class _TripPlanScreenState extends State<TripPlanScreen> {
  @override
  Widget build(BuildContext context) {
    // ดึงข้อมูล itinerary ออกมาอย่างปลอดภัย
    final List<dynamic> itinerary = widget.tripPlan['itinerary'] ?? [];

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.grey.shade50,
        title: Text(widget.tripPlan['title'] ?? 'แผนการเดินทางของคุณ'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: itinerary.length + 1, // +1 สำหรับการ์ดสรุปข้อมูล
        itemBuilder: (context, index) {
          if (index == 0) {
            return _buildSummaryCard(context);
          }
          final dayPlan = itinerary[index - 1] as Map<String, dynamic>;
          return _buildDayCard(context, dayPlan);
        },
      ),
    );
  }

  // --- Widget สำหรับสร้างการ์ดสรุปข้อมูล ---
  Widget _buildSummaryCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor.withOpacity(0.8),
            Theme.of(context).primaryColor,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).primaryColor.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildSummaryItem(
              context,
              Icons.calendar_month_rounded,
              '${widget.tripPlan['days_count'] ?? 'N/A'} วัน',
              'ระยะเวลา',
            ),
            _buildSummaryItem(
              context,
              Icons.wallet_rounded,
              '~${widget.tripPlan['estimated_total_cost']?.toStringAsFixed(0) ?? 'N/A'} ฿',
              'งบประมาณ',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(
    BuildContext context,
    IconData icon,
    String value,
    String label,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 32, color: Colors.white),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.8)),
        ),
      ],
    );
  }

  // --- Widget สำหรับสร้างการ์ดของแต่ละวัน ---
  Widget _buildDayCard(BuildContext context, Map<String, dynamic> dayPlan) {
    final List<dynamic> activities = dayPlan['activities'] ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 12.0, bottom: 16.0),
          child: Text(
            'Day ${dayPlan['day']}  ·  ${dayPlan['date']}',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColorDark,
            ),
          ),
        ),
        for (int i = 0; i < activities.length; i++)
          _buildTimelineActivityItem(
            context,
            activities[i] as Map<String, dynamic>,
            isLast: i == activities.length - 1,
          ),
      ],
    );
  }

  // --- Widget สำหรับสร้างกิจกรรมในรูปแบบ Timeline ---
  Widget _buildTimelineActivityItem(
    BuildContext context,
    Map<String, dynamic> activity, {
    required bool isLast,
  }) {
    final String description = activity['description'] ?? '';
    final bool hasDescription = description.isNotEmpty;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- Timeline Node (Dot and Line) ---
          SizedBox(
            width: 30,
            child: Column(
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(context).primaryColor.withOpacity(0.3),
                    border: Border.all(
                      color: Theme.of(context).primaryColor,
                      width: 3,
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    width: 2,
                    color: isLast ? Colors.transparent : Colors.grey.shade300,
                  ),
                ),
              ],
            ),
          ),
          // --- Activity Card ---
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 8.0, bottom: 24.0),
              child: Card(
                margin: EdgeInsets.zero,
                elevation: 3,
                shadowColor: Colors.black.withOpacity(0.08),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.0),
                ),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () {},
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          activity['timeSlot'] ?? 'N/A',
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          activity['placeName'] ?? 'N/A',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                height: 1.3,
                              ),
                        ),
                        // --- ส่วนที่แก้ไข: แสดงเหตุผลที่แนะนำ ---
                        if (hasDescription)
                          Padding(
                            padding: const EdgeInsets.only(top: 12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Divider(),
                                const SizedBox(height: 8),
                                Text(
                                  'เหตุผลที่แนะนำ',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey.shade800,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  description,
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
