import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../controller/trip_controller.dart';
import '../models/trip_creation_data.dart';

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
  bool _isInitiating = false; // State สำหรับจัดการสถานะ Loading ของปุ่ม
  final List<String> _travelStyles = [
    'สายชิล',
    'สายลุย',
    'สายกิน',
    'สายประวัติศาสตร์',
    'สายธรรมชาติ',
    'สายปาร์ตี้',
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
    // ตรวจสอบว่าข้อมูลในฟอร์มผ่านเงื่อนไข (validator) ทั้งหมดหรือไม่
    if (_formKey.currentState!.validate()) {
      setState(() => _isInitiating = true);
      try {
        // 1. รวบรวมข้อมูลจากฟอร์มลงใน Model
        final tripData = TripCreationData(
          country: _countryController.text,
          province: _provinceController.text,
          startDate: _selectedStartDate!,
          endDate: _selectedEndDate!,
          travelers: int.parse(_travelersController.text),
          budget: double.parse(_budgetController.text),
          travelStyle: _selectedTravelStyle!,
        );

        // 2. เรียก API เพื่อเริ่มสร้างทริปและรับ tripId กลับมา
        final tripId = await _tripController.initiateTrip(tripData);

        if (mounted) {
          // 3. นำทางไปยังหน้า GeneratingTripScreen พร้อมกับส่ง tripId ไป
          Navigator.of(
            context,
          ).pushNamed('/generating-trip', arguments: tripId);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('เกิดข้อผิดพลาด: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        // ไม่ว่าจะสำเร็จหรือล้มเหลว ให้ปิดสถานะ loading
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
      if (days > 0) {
        durationText += '$days วัน';
      }
      if (hours > 0) {
        if (durationText.isNotEmpty) {
          durationText += ' ';
        }
        durationText += '$hours ชั่วโมง';
      }

      // Handle cases less than an hour, or same day
      if (durationText.isEmpty) {
        if (difference.inMinutes > 0) {
          durationText = 'ไม่ถึง 1 ชั่วโมง';
        } else {
          // This case should not happen if end date is after start date
          setState(() => _tripDuration = null);
          return;
        }
      }

      setState(() {
        _tripDuration = durationText;
      });
    } else {
      // If dates are invalid or not set, clear the duration
      setState(() => _tripDuration = null);
    }
  }

  // --- ฟังก์ชันสำหรับแสดง Date & Time Picker ---
  Future<void> _selectDateTime(
    BuildContext context, {
    required bool isStartDate,
  }) async {
    final now = DateTime.now();
    // กำหนดค่าเริ่มต้นของปฏิทิน
    final initialDate = isStartDate
        ? (_selectedStartDate ?? now)
        : (_selectedEndDate ?? _selectedStartDate ?? now);

    // กำหนดวันแรกที่เลือกได้ (สำหรับวันสิ้นสุด จะต้องไม่ก่อนวันเริ่มต้น)
    final firstDate = isStartDate ? now : _selectedStartDate ?? now;

    // 1. แสดงปฏิทิน (DatePicker)
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: now.add(const Duration(days: 365 * 2)),
    );

    if (pickedDate != null && mounted) {
      // 2. แสดงนาฬิกา (TimePicker)
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(initialDate),
      );

      if (pickedTime != null) {
        final finalDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );

        // --- [เพิ่มเข้ามา] ตรวจสอบว่าวัน-เวลาเริ่มต้นที่เลือกอยู่ในอดีตหรือไม่ ---
        if (isStartDate &&
            finalDateTime.isBefore(now.subtract(const Duration(minutes: 1)))) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('ไม่สามารถเลือกวัน-เวลาเริ่มต้นในอดีตได้'),
                backgroundColor: Colors.orange,
              ),
            );
          }
          return; // ไม่ตั้งค่าวันที่และจบการทำงาน
        }
        // --- สิ้นสุดส่วนที่เพิ่มเข้ามา ---

        // จัดรูปแบบการแสดงผล (เพื่อความสวยงาม ควรใช้ package 'intl' ในอนาคต)
        final formattedDateTime =
            '${finalDateTime.day.toString().padLeft(2, '0')}/${finalDateTime.month.toString().padLeft(2, '0')}/${finalDateTime.year} - ${finalDateTime.hour.toString().padLeft(2, '0')}:${finalDateTime.minute.toString().padLeft(2, '0')}';

        setState(() {
          if (isStartDate) {
            _selectedStartDate = finalDateTime;
            _startDateController.text = formattedDateTime;
            // ถ้ำวันสิ้นสุดที่เคยเลือกไว้ ดันมาก่อนวันเริ่มต้นใหม่ ให้ล้างค่าทิ้ง
            if (_selectedEndDate != null &&
                _selectedEndDate!.isBefore(_selectedStartDate!)) {
              _selectedEndDate = null;
              _endDateController.text = '';
            }
          } else {
            _selectedEndDate = finalDateTime;
            _endDateController.text = formattedDateTime;
          }
          // คำนวณระยะเวลาทุกครั้งที่มีการเปลี่ยนวันที่
          _calculateDuration();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('สร้างแพลนเที่ยวกับ AI'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSectionHeader(
                  'จุดหมายปลายทาง',
                  'คุณอยากจะไปเที่ยวที่ไหน?',
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _countryController,
                  decoration: _buildInputDecoration(
                    labelText: 'ประเทศ',
                    prefixIcon: Icons.public,
                  ),
                  validator: (value) => (value == null || value.isEmpty)
                      ? 'กรุณากรอกประเทศ'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _provinceController,
                  decoration: _buildInputDecoration(
                    labelText: 'จังหวัด/เมือง',
                    prefixIcon: Icons.location_city,
                  ),
                  validator: (value) => (value == null || value.isEmpty)
                      ? 'กรุณากรอกจังหวัดหรือเมือง'
                      : null,
                ),
                const SizedBox(height: 32),
                _buildSectionHeader(
                  'รายละเอียดทริป',
                  'บอกเราเกี่ยวกับทริปของคุณ',
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _startDateController,
                  decoration: _buildInputDecoration(
                    labelText: 'วัน-เวลาที่เริ่มเดินทาง',
                    prefixIcon: Icons.calendar_today_outlined,
                  ),
                  readOnly: true, // ทำให้พิมพ์ไม่ได้ ต้องกดเลือกเท่านั้น
                  onTap: () => _selectDateTime(context, isStartDate: true),
                  validator: (value) => (value == null || value.isEmpty)
                      ? 'กรุณาเลือกวัน-เวลาเริ่มต้น'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _endDateController,
                  decoration: _buildInputDecoration(
                    labelText: 'วัน-เวลาที่เดินทางกลับ',
                    prefixIcon: Icons.event_available_outlined,
                  ),
                  readOnly: true,
                  onTap: () => _selectDateTime(context, isStartDate: false),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'กรุณาเลือกวัน-เวลากลับ';
                    }
                    if (_selectedStartDate != null &&
                        _selectedEndDate != null &&
                        !_selectedEndDate!.isAfter(_selectedStartDate!)) {
                      return 'วัน-เวลากลับต้องอยู่หลังวัน-เวลาเริ่มต้น';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Visibility(
                  visible: _tripDuration != null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.timer_outlined,
                          color: Theme.of(context).primaryColor,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'ระยะเวลาทริป: ',
                          style: TextStyle(fontSize: 16),
                        ),
                        Text(
                          _tripDuration ?? '',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColorDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _travelersController,
                        decoration: _buildInputDecoration(
                          labelText: 'จำนวนผู้เดินทาง',
                          prefixIcon: Icons.people_outline,
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        validator: (value) => (value == null || value.isEmpty)
                            ? 'กรุณากรอกจำนวนผู้เดินทาง'
                            : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _budgetController,
                        decoration: _buildInputDecoration(
                          labelText: 'งบประมาณ/คน',
                          prefixIcon: Icons.account_balance_wallet_outlined,
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d+\.?\d{0,2}'),
                          ),
                        ],
                        validator: (value) => (value == null || value.isEmpty)
                            ? 'กรุณากรอกงบประมาณ'
                            : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedTravelStyle,
                  decoration: _buildInputDecoration(
                    labelText: 'รูปแบบการท่องเที่ยว',
                    prefixIcon: Icons.explore_outlined,
                  ),
                  items: _travelStyles.map((String style) {
                    return DropdownMenuItem<String>(
                      value: style,
                      child: Text(style),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      _selectedTravelStyle = newValue;
                    });
                  },
                  validator: (value) =>
                      (value == null) ? 'กรุณาเลือกรูปแบบการท่องเที่ยว' : null,
                ),
                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: _isInitiating ? null : _submitForm,
                  style:
                      ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ).copyWith(
                        backgroundColor:
                            MaterialStateProperty.resolveWith<Color?>((
                              Set<MaterialState> states,
                            ) {
                              if (states.contains(MaterialState.disabled))
                                return Colors.grey;
                              return null; // Use the component's default.
                            }),
                      ),
                  child: _isInitiating
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('สร้างทริปเลย'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper Widget สำหรับสร้าง Header ของแต่ละ Section
  Widget _buildSectionHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  // Helper Widget สำหรับสร้าง InputDecoration เพื่อลดการเขียนโค้ดซ้ำ
  InputDecoration _buildInputDecoration({
    required String labelText,
    IconData? prefixIcon,
  }) {
    return InputDecoration(
      labelText: labelText,
      prefixIcon: prefixIcon != null
          ? Icon(prefixIcon, color: Colors.grey[600])
          : null,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
      ),
    );
  }
}
