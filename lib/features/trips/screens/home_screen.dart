import 'package:cached_network_image/cached_network_image.dart';
import 'package:easytrip_frontend/features/trips/controller/trip_controller.dart';
import 'package:easytrip_frontend/features/trips/models/trip_model.dart';
import 'package:easytrip_frontend/features/trips/screens/trip_detail_screen.dart';
import 'package:easytrip_frontend/features/profile/screens/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/services/session_service.dart';
import 'trip_list_screen.dart';

// ─── Color palette ─────────────────────────────────────────────────────────────
const _kPrimary = Color(0xFF00897B);
const _kPrimaryLight = Color(0xFFB2DFDB);
const _kAccent = Color(0xFFFF7043);
const _kBg = Color(0xFFF5F7FA);
const _kTextPrimary = Color(0xFF1A2340);
const _kTextSecondary = Color(0xFF6B7A99);

// HomeScreen จะเป็น StatefulWidget เพราะต้องจัดการ "สถานะ" ของ Tab ที่ถูกเลือก
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  String _userName = 'นักเดินทาง';
  final TripController _tripController = TripController();
  final SessionService _sessionService = SessionService();
  late Future<List<Trip>> _recentTripsFuture;

  @override
  void initState() {
    super.initState();
    _loadRecentTrips();
    _loadUserData();
  }

  void _loadUserData() async {
    final name = await _sessionService.getUserName();
    if (name != null && name.isNotEmpty && mounted) {
      setState(() => _userName = name);
    }
  }

  void _loadRecentTrips() {
    setState(() {
      _recentTripsFuture = _tripController.getMyTrips();
    });
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> widgetOptions = [
      _HomeTab(
        userName: _userName,
        recentTripsFuture: _recentTripsFuture,
        onRefresh: _loadRecentTrips,
      ),
      const TripListScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      backgroundColor: _kBg,
      body: widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: _ModernNavBar(
        selectedIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}

// ─── Modern Bottom Nav Bar ────────────────────────────────────────────────────
class _ModernNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const _ModernNavBar({required this.selectedIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    const items = [
      _NavItem(icon: Icons.home_rounded, label: 'หน้าหลัก'),
      _NavItem(icon: Icons.flight_rounded, label: 'ทริปของฉัน'),
      _NavItem(icon: Icons.person_rounded, label: 'โปรไฟล์'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: items.asMap().entries.map((entry) {
              final i = entry.key;
              final item = entry.value;
              final isSelected = i == selectedIndex;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onTap(i),
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            color: isSelected ? _kPrimary.withOpacity(0.12) : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            item.icon,
                            size: 24,
                            color: isSelected ? _kPrimary : _kTextSecondary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.label,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? _kPrimary : _kTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}

// ─── Home Tab ─────────────────────────────────────────────────────────────────
class _HomeTab extends StatelessWidget {
  final String userName;
  final Future<List<Trip>> recentTripsFuture;
  final VoidCallback onRefresh;

  const _HomeTab({
    required this.userName,
    required this.recentTripsFuture,
    required this.onRefresh,
  });

  // ── Quick prompts data ───────────────────────────────────────────────────────
  static const _prompts = [
    _PromptItem('ทะเล 2 วัน 1 คืน', Icons.beach_access_rounded, Color(0xFF0288D1)),
    _PromptItem('สายคาเฟ่', Icons.local_cafe_rounded, Color(0xFF795548)),
    _PromptItem('งบประหยัด', Icons.savings_rounded, Color(0xFF2E7D32)),
    _PromptItem('เดินป่า', Icons.forest_rounded, Color(0xFF388E3C)),
    _PromptItem('ไหว้พระ 9 วัด', Icons.account_balance_rounded, Color(0xFFF57F17)),
    _PromptItem('ช้อปปิ้ง', Icons.shopping_bag_rounded, Color(0xFFAB47BC)),
  ];

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        // ── Hero header ───────────────────────────────────────────────────
        SliverToBoxAdapter(child: _buildHeroHeader(context)),

        // ── AI Banner ─────────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
            child: _buildAiBanner(context),
          ),
        ),

        // ── Quick Prompts ─────────────────────────────────────────────────
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, 28, 16, 12),
            child: Text(
              'ไอเดียทริปยอดฮิต 🔥',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _kTextPrimary,
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 48,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _prompts.length,
              itemBuilder: (_, i) => _PromptChip(item: _prompts[i]),
            ),
          ),
        ),

        // ── Recent Trips header ───────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 28, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'ทริปล่าสุดของคุณ',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: _kTextPrimary,
                  ),
                ),
                GestureDetector(
                  onTap: onRefresh,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: _kPrimary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.refresh_rounded, size: 18, color: _kPrimary),
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── Recent Trips list ─────────────────────────────────────────────
        SliverToBoxAdapter(
          child: FutureBuilder<List<Trip>>(
            future: recentTripsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return _RecentTripsLoading();
              }
              if (snapshot.hasError) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _ErrorCard(message: '${snapshot.error}'),
                );
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return _EmptyTripsCard(
                  onTap: () => Navigator.pushNamed(context, '/create-trip'),
                );
              }
              final trips = snapshot.data!.take(5).toList();
              return SizedBox(
                height: 210,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: trips.length,
                  itemBuilder: (context, i) => _RecentTripCard(
                    trip: trips[i],
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TripDetailScreen(tripId: trips[i].id),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 32)),
      ],
    );
  }

  // ── Hero Header ─────────────────────────────────────────────────────────────
  Widget _buildHeroHeader(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF00695C), Color(0xFF00897B), Color(0xFF26A69A)],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          child: Column(
            children: [
              // Avatar row
              Row(
                children: [
                  const CircleAvatar(
                    radius: 26,
                    backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=3'),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'สวัสดี! 👋',
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                        Text(
                          userName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.flight_takeoff_rounded, color: Colors.white, size: 14),
                        SizedBox(width: 4),
                        Text(
                          'EasyTrip',
                          style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Search-like CTA bar
              GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/create-trip'),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.search_rounded, color: _kTextSecondary),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'อยากไปเที่ยวที่ไหน?',
                          style: TextStyle(color: _kTextSecondary, fontSize: 15),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _kPrimary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'AI ✨',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── AI Banner ────────────────────────────────────────────────────────────────
  Widget _buildAiBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFF1A237E), Color(0xFF283593), Color(0xFF3949AB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A237E).withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    '✨ AI Trip Planner',
                    style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'วางแผนทริปอัตโนมัติ\nด้วย AI ฉลาดๆ',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 14),
                GestureDetector(
                  onTap: () => Navigator.pushNamed(context, '/create-trip'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'เริ่มสร้างทริปเลย →',
                      style: TextStyle(
                        color: Color(0xFF1A237E),
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Decorative icon cluster
          Column(
            children: [
              _GlassIcon(icon: Icons.flight_rounded, color: Colors.white),
              const SizedBox(height: 8),
              _GlassIcon(icon: Icons.map_rounded, color: Colors.amber),
              const SizedBox(height: 8),
              _GlassIcon(icon: Icons.camera_alt_rounded, color: Colors.pinkAccent),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Glass Icon ───────────────────────────────────────────────────────────────
class _GlassIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  const _GlassIcon({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }
}

// ─── Prompt Chip ──────────────────────────────────────────────────────────────
class _PromptItem {
  final String label;
  final IconData icon;
  final Color color;
  const _PromptItem(this.label, this.icon, this.color);
}

class _PromptChip extends StatelessWidget {
  final _PromptItem item;
  const _PromptChip({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 10),
      child: GestureDetector(
        onTap: () => Navigator.pushNamed(context, '/create-trip'),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: item.color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: item.color.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(item.icon, size: 15, color: item.color),
              const SizedBox(width: 6),
              Text(
                item.label,
                style: TextStyle(
                  color: item.color,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Recent Trip Card ─────────────────────────────────────────────────────────
class _RecentTripCard extends StatelessWidget {
  final Trip trip;
  final VoidCallback onTap;
  static const _defaultImage =
      'https://images.unsplash.com/photo-1501785888041-af3ef285b470?q=80&w=1170&auto=format&fit=crop';

  const _RecentTripCard({required this.trip, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final imageUrl = (trip.imageUrl != null && trip.imageUrl!.isNotEmpty)
        ? trip.imageUrl!
        : _defaultImage;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Stack(
            fit: StackFit.expand,
            children: [
              CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                placeholder: (_, __) => Shimmer.fromColors(
                  baseColor: Colors.grey.shade200,
                  highlightColor: Colors.grey.shade50,
                  child: Container(color: Colors.white),
                ),
                errorWidget: (_, __, ___) => Container(
                  color: _kPrimaryLight,
                  child: const Icon(Icons.image_not_supported_outlined, color: _kPrimary),
                ),
              ),
              // Gradient overlay
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withOpacity(0.72)],
                    stops: const [0.45, 1.0],
                  ),
                ),
              ),
              // Info
              Positioned(
                bottom: 12,
                left: 12,
                right: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      trip.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${trip.daysCount} วัน',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Empty Trips Card ─────────────────────────────────────────────────────────
class _EmptyTripsCard extends StatelessWidget {
  final VoidCallback onTap;
  const _EmptyTripsCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _kPrimaryLight, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: _kPrimary.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.add_rounded, color: _kPrimary, size: 28),
              ),
              const SizedBox(height: 12),
              const Text(
                'ยังไม่มีทริปเลย',
                style: TextStyle(fontWeight: FontWeight.bold, color: _kTextPrimary, fontSize: 15),
              ),
              const SizedBox(height: 4),
              const Text(
                'แตะที่นี่เพื่อสร้างทริปแรกของคุณ!',
                style: TextStyle(color: _kTextSecondary, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Error Card ───────────────────────────────────────────────────────────────
class _ErrorCard extends StatelessWidget {
  final String message;
  const _ErrorCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kAccent.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: _kAccent),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'โหลดไม่สำเร็จ: $message',
              style: const TextStyle(color: _kAccent, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Recent Trips Loading ─────────────────────────────────────────────────────
class _RecentTripsLoading extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 210,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 3,
        itemBuilder: (_, __) => Padding(
          padding: const EdgeInsets.only(right: 14),
          child: Shimmer.fromColors(
            baseColor: Colors.grey.shade200,
            highlightColor: Colors.grey.shade50,
            child: Container(
              width: 160,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
