import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../controller/trip_controller.dart';
import '../models/trip_creation_data.dart';

// ─── Color palette ─────────────────────────────────────────────────────────────
const _kPrimary = Color(0xFF00897B);
const _kPrimaryLight = Color(0xFFB2DFDB);
const _kAccent = Color(0xFFFF7043);
const _kBg = Color(0xFFF5F7FA);
const _kTextPrimary = Color(0xFF1A2340);
const _kTextSecondary = Color(0xFF6B7A99);

/// หน้าจอสำหรับให้ผู้ใช้กรอกข้อมูลเพื่อสร้างทริปใหม่
class CreateTripScreen extends StatefulWidget {
  const CreateTripScreen({super.key});

  @override
  State<CreateTripScreen> createState() => _CreateTripScreenState();
}

class _CreateTripScreenState extends State<CreateTripScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tripController = TripController();

  // Controllers สำหรับดึงค่าจากช่องกรอกข้อความ
  final _countryController = TextEditingController();
  final _provinceController = TextEditingController();
  final _startDateController = TextEditingController();
  final _endDateController = TextEditingController();
  final _budgetController = TextEditingController();
  final _travelersController = TextEditingController();

  // State สำหรับเก็บค่าวันที่และ Dropdown
  DateTime? _selectedStartDate;
  DateTime? _selectedEndDate;
  String? _tripDuration;
  String? _selectedTravelStyle;
  bool _isInitiating = false;

  // รูปแบบการท่องเที่ยว พร้อม icon
  final List<_TravelStyleOption> _travelStyles = const [
    _TravelStyleOption('สายชิล', Icons.beach_access_rounded, Color(0xFF26A69A)),
    _TravelStyleOption('สายลุย', Icons.hiking_rounded, Color(0xFF5C6BC0)),
    _TravelStyleOption('สายกิน', Icons.restaurant_rounded, Color(0xFFEF5350)),
    _TravelStyleOption('สายประวัติศาสตร์', Icons.account_balance_rounded, Color(0xFF8D6E63)),
    _TravelStyleOption('สายธรรมชาติ', Icons.forest_rounded, Color(0xFF66BB6A)),
    _TravelStyleOption('สายปาร์ตี้', Icons.celebration_rounded, Color(0xFFAB47BC)),
  ];

  @override
  void dispose() {
    _countryController.dispose();
    _provinceController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    _budgetController.dispose();
    _travelersController.dispose();
    super.dispose();
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isInitiating = true);
      try {
        final tripData = TripCreationData(
          country: _countryController.text,
          province: _provinceController.text,
          startDate: _selectedStartDate!,
          endDate: _selectedEndDate!,
          travelers: int.parse(_travelersController.text),
          budget: double.parse(_budgetController.text),
          travelStyle: _selectedTravelStyle!,
        );

        final tripId = await _tripController.initiateTrip(tripData);

        if (mounted) {
          Navigator.of(context).pushNamed('/generating-trip', arguments: tripId);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('เกิดข้อผิดพลาด: ${e.toString()}'),
              backgroundColor: _kAccent,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isInitiating = false);
      }
    }
  }

  void _calculateDuration() {
    if (_selectedStartDate != null &&
        _selectedEndDate != null &&
        _selectedEndDate!.isAfter(_selectedStartDate!)) {
      final difference = _selectedEndDate!.difference(_selectedStartDate!);
      final days = difference.inDays;
      final hours = difference.inHours.remainder(24);

      String durationText = '';
      if (days > 0) durationText += '$days วัน';
      if (hours > 0) {
        if (durationText.isNotEmpty) durationText += ' ';
        durationText += '$hours ชั่วโมง';
      }
      if (durationText.isEmpty) {
        durationText = difference.inMinutes > 0 ? 'ไม่ถึง 1 ชั่วโมง' : '';
      }

      setState(() => _tripDuration = durationText.isEmpty ? null : durationText);
    } else {
      setState(() => _tripDuration = null);
    }
  }

  Future<void> _selectDateTime(BuildContext context, {required bool isStartDate}) async {
    final now = DateTime.now();
    final initialDate = isStartDate
        ? (_selectedStartDate ?? now)
        : (_selectedEndDate ?? _selectedStartDate ?? now);
    final firstDate = isStartDate ? now : _selectedStartDate ?? now;

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: now.add(const Duration(days: 365 * 2)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: _kPrimary,
            onPrimary: Colors.white,
            surface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );

    if (pickedDate != null && mounted) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(initialDate),
        builder: (context, child) => Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: _kPrimary),
          ),
          child: child!,
        ),
      );

      if (pickedTime != null) {
        final finalDateTime = DateTime(
          pickedDate.year, pickedDate.month, pickedDate.day,
          pickedTime.hour, pickedTime.minute,
        );

        if (isStartDate && finalDateTime.isBefore(now.subtract(const Duration(minutes: 1)))) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('ไม่สามารถเลือกวัน-เวลาเริ่มต้นในอดีตได้'),
                backgroundColor: _kAccent,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            );
          }
          return;
        }

        final formatted =
            '${finalDateTime.day.toString().padLeft(2, '0')}/${finalDateTime.month.toString().padLeft(2, '0')}/${finalDateTime.year}  ${finalDateTime.hour.toString().padLeft(2, '0')}:${finalDateTime.minute.toString().padLeft(2, '0')}';

        setState(() {
          if (isStartDate) {
            _selectedStartDate = finalDateTime;
            _startDateController.text = formatted;
            if (_selectedEndDate != null && _selectedEndDate!.isBefore(_selectedStartDate!)) {
              _selectedEndDate = null;
              _endDateController.text = '';
            }
          } else {
            _selectedEndDate = finalDateTime;
            _endDateController.text = formatted;
          }
          _calculateDuration();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Section 1: Destination ───────────────────────────
                    _SectionCard(
                      icon: Icons.flight_takeoff_rounded,
                      title: 'จุดหมายปลายทาง',
                      subtitle: 'คุณอยากจะไปเที่ยวที่ไหน?',
                      color: _kPrimary,
                      children: [
                        _StyledField(
                          controller: _countryController,
                          label: 'ประเทศ',
                          hint: 'เช่น ไทย, ญี่ปุ่น, เกาหลี',
                          icon: Icons.public_rounded,
                          validator: (v) => (v == null || v.isEmpty) ? 'กรุณากรอกประเทศ' : null,
                        ),
                        const SizedBox(height: 14),
                        _StyledField(
                          controller: _provinceController,
                          label: 'จังหวัด/เมือง',
                          hint: 'เช่น กรุงเทพฯ, เชียงใหม่, โตเกียว',
                          icon: Icons.location_city_rounded,
                          validator: (v) => (v == null || v.isEmpty) ? 'กรุณากรอกจังหวัดหรือเมือง' : null,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // ── Section 2: Date ──────────────────────────────────
                    _SectionCard(
                      icon: Icons.calendar_month_rounded,
                      title: 'ช่วงเวลาเดินทาง',
                      subtitle: 'วางแผนว่าจะไปเมื่อไหร่?',
                      color: const Color(0xFF5C6BC0),
                      children: [
                        _StyledField(
                          controller: _startDateController,
                          label: 'วัน-เวลาที่เริ่มเดินทาง',
                          hint: 'แตะเพื่อเลือกวันที่',
                          icon: Icons.calendar_today_rounded,
                          readOnly: true,
                          onTap: () => _selectDateTime(context, isStartDate: true),
                          validator: (v) => (v == null || v.isEmpty) ? 'กรุณาเลือกวัน-เวลาเริ่มต้น' : null,
                        ),
                        const SizedBox(height: 14),
                        _StyledField(
                          controller: _endDateController,
                          label: 'วัน-เวลาที่เดินทางกลับ',
                          hint: 'แตะเพื่อเลือกวันที่',
                          icon: Icons.event_available_rounded,
                          readOnly: true,
                          onTap: () => _selectDateTime(context, isStartDate: false),
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'กรุณาเลือกวัน-เวลากลับ';
                            if (_selectedStartDate != null &&
                                _selectedEndDate != null &&
                                !_selectedEndDate!.isAfter(_selectedStartDate!)) {
                              return 'วัน-เวลากลับต้องอยู่หลังวัน-เวลาเริ่มต้น';
                            }
                            return null;
                          },
                        ),
                        // Duration badge
                        if (_tripDuration != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF00897B), Color(0xFF26A69A)],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.timer_rounded, color: Colors.white, size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  'ระยะเวลาทริป: $_tripDuration',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 16),

                    // ── Section 3: Trip details ──────────────────────────
                    _SectionCard(
                      icon: Icons.people_rounded,
                      title: 'รายละเอียดทริป',
                      subtitle: 'บอกเราเพิ่มเติมเกี่ยวกับทริปนี้',
                      color: _kAccent,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _StyledField(
                                controller: _travelersController,
                                label: 'จำนวนผู้เดินทาง',
                                hint: 'เช่น 2',
                                icon: Icons.people_outline_rounded,
                                keyboardType: TextInputType.number,
                                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                validator: (v) => (v == null || v.isEmpty) ? 'กรุณากรอก' : null,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _StyledField(
                                controller: _budgetController,
                                label: 'งบ/คน (฿)',
                                hint: 'เช่น 15000',
                                icon: Icons.account_balance_wallet_rounded,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
                                validator: (v) => (v == null || v.isEmpty) ? 'กรุณากรอก' : null,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // ── Section 4: Travel style ──────────────────────────
                    _SectionCard(
                      icon: Icons.explore_rounded,
                      title: 'สไตล์การท่องเที่ยว',
                      subtitle: 'คุณชอบท่องเที่ยวแบบไหน?',
                      color: const Color(0xFFAB47BC),
                      children: [
                        _TravelStyleSelector(
                          options: _travelStyles,
                          selected: _selectedTravelStyle,
                          onSelected: (style) => setState(() => _selectedTravelStyle = style),
                        ),
                        if (_formKey.currentState != null && _selectedTravelStyle == null)
                          const Padding(
                            padding: EdgeInsets.only(top: 8, left: 4),
                            child: Text(
                              'กรุณาเลือกสไตล์การท่องเที่ยว',
                              style: TextStyle(color: Colors.red, fontSize: 12),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // ── Submit Button ────────────────────────────────────
                    _SubmitButton(
                      isLoading: _isInitiating,
                      onPressed: _submitForm,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF00897B), Color(0xFF26A69A)],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.maybePop(context),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'สร้างทริปกับ AI ✨',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'กรอกข้อมูล แล้วให้ AI วางแผนให้คุณ',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
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

// ─── Section Card ─────────────────────────────────────────────────────────────
class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final List<Widget> children;

  const _SectionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _kTextPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 12, color: _kTextSecondary),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}

// ─── Styled Field ─────────────────────────────────────────────────────────────
class _StyledField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final bool readOnly;
  final VoidCallback? onTap;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;

  const _StyledField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.readOnly = false,
    this.onTap,
    this.validator,
    this.keyboardType,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      onTap: onTap,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      style: const TextStyle(color: _kTextPrimary, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(color: _kTextSecondary, fontSize: 13),
        hintStyle: TextStyle(color: _kTextSecondary.withOpacity(0.5), fontSize: 13),
        prefixIcon: Icon(icon, color: _kPrimary, size: 20),
        suffixIcon: readOnly ? const Icon(Icons.chevron_right_rounded, color: _kTextSecondary) : null,
        filled: true,
        fillColor: const Color(0xFFF8FAFB),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE8EDF2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE8EDF2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _kPrimary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _kAccent),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _kAccent, width: 2),
        ),
      ),
    );
  }
}

// ─── Travel Style Selector ────────────────────────────────────────────────────
class _TravelStyleOption {
  final String label;
  final IconData icon;
  final Color color;

  const _TravelStyleOption(this.label, this.icon, this.color);
}

class _TravelStyleSelector extends StatelessWidget {
  final List<_TravelStyleOption> options;
  final String? selected;
  final ValueChanged<String> onSelected;

  const _TravelStyleSelector({
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: options.map((opt) {
        final isSelected = selected == opt.label;
        return GestureDetector(
          onTap: () => onSelected(opt.label),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? opt.color : opt.color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? opt.color : opt.color.withOpacity(0.3),
                width: isSelected ? 2 : 1,
              ),
              boxShadow: isSelected
                  ? [BoxShadow(color: opt.color.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))]
                  : [],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(opt.icon, size: 16, color: isSelected ? Colors.white : opt.color),
                const SizedBox(width: 6),
                Text(
                  opt.label,
                  style: TextStyle(
                    color: isSelected ? Colors.white : opt.color,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ─── Submit Button ────────────────────────────────────────────────────────────
class _SubmitButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onPressed;

  const _SubmitButton({required this.isLoading, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 56,
        decoration: BoxDecoration(
          gradient: isLoading
              ? null
              : const LinearGradient(
                  colors: [Color(0xFF00897B), Color(0xFF26A69A)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
          color: isLoading ? const Color(0xFFB2DFDB) : null,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isLoading
              ? []
              : [
                  BoxShadow(
                    color: const Color(0xFF00897B).withOpacity(0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                )
              : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'ให้ AI สร้างทริปเลย!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
