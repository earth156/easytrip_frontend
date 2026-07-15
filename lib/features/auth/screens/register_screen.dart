import 'dart:ui';

import 'package:flutter/material.dart';
import '../controllers/auth_controller.dart'; // 1. เปลี่ยนไปนำเข้า AuthController
import '../../../core/utils/custom_dialogs.dart';
import '../models/auth_result.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // 2. สร้าง instance ของ AuthController และ state สำหรับ loading
  final AuthController _authController = AuthController();
  bool _isLoading = false;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // 3. ปรับปรุงฟังก์ชัน _register ให้เรียกใช้ API
  void _register() async {
    // ตรวจสอบว่าข้อมูลในฟอร์มผ่านเงื่อนไข (validator) ทั้งหมดหรือไม่
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true; // เริ่มแสดง loading
      });

      final result = await _authController.register(
        name: _nameController.text,
        email: _emailController.text,
        password: _passwordController.text,
      );

      // ตรวจสอบว่า widget ยังอยู่ใน tree ก่อนจะใช้งาน context
      if (!mounted) return;

      setState(() {
        _isLoading = false; // หยุดแสดง loading
      });

      // ใช้ switch กับ sealed class ทำให้โค้ดสะอาดและจัดการทุกเคสได้ครบถ้วน
      switch (result) {
        case AuthSuccess(message: final msg):
          // 1. แสดง Dialog ว่าสมัครสำเร็จ
          await CustomDialogs.showSuccessDialog(
            context: context,
            title: 'สมัครสมาชิกสำเร็จ!',
            message:
                'บัญชีของคุณถูกสร้างเรียบร้อยแล้ว เราจะนำคุณเข้าสู่ระบบทันที',
          );

          if (!mounted) return;

          // 2. ทำการ Login อัตโนมัติ
          setState(() => _isLoading = true);

          final loginResult = await _authController.login(
            email: _emailController.text,
            password: _passwordController.text,
          );

          if (!mounted) return;

          setState(() => _isLoading = false);

          // 3. จัดการผลลัพธ์จากการ Login
          switch (loginResult) {
            case LoginSuccess(user: final user):
              // Controller has saved the session.
              print('Auto-login successful for ${user.name}');
              Navigator.of(
                context,
              ).pushNamedAndRemoveUntil('/home', (route) => false);
              break;
            case AuthFailure(message: final loginMsg):
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('เข้าสู่ระบบอัตโนมัติล้มเหลว: $loginMsg'),
                  backgroundColor: Colors.red,
                ),
              );
              Navigator.of(context).pop(); // กลับไปหน้า Login
              break;
            default:
              // Should not happen
              Navigator.of(context).pop();
          }
          break;

        case AuthFailure(message: final msg):
          // สมัครไม่สำเร็จ
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(msg), backgroundColor: Colors.red),
          );
          break;
        // แม้ว่าการสมัครสมาชิกจะไม่ควรคืนค่า LoginSuccess, แต่เพื่อให้ switch statement สมบูรณ์ (exhaustive)
        // เราควรจะจัดการกับเคสนี้ด้วย ในที่นี้จะแสดงเป็นข้อผิดพลาดทั่วไป
        case LoginSuccess():
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('เกิดข้อผิดพลาดที่ไม่คาดคิดระหว่างการสมัคร'),
              backgroundColor: Colors.red,
            ),
          );
          break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // ทำให้ Scaffold โปร่งใส และขยาย body ไปด้านหลัง AppBar
    // เพื่อให้ภาพพื้นหลังแสดงผลเต็มจอรวมถึงบริเวณ status bar
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      // AppBar แบบโปร่งใส ไม่มีเงา
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      // ใช้ Stack เพื่อซ้อน Widget ต่างๆ ทับกัน
      body: Stack(
        children: [
          // --- 1. พื้นหลัง (Background Image) ---
          // ใช้ Image.asset เพื่อดึงรูปจากในโปรเจกต์
          Image.asset(
            'assets/images/background_register.jpg', // ใช้ภาพพื้นหลังเดียวกับหน้า Login
            height: double.infinity,
            width: double.infinity,
            fit: BoxFit.cover,
          ),

          // --- 2. Overlay สีดำโปร่งแสง ---
          Container(
            height: double.infinity,
            width: double.infinity,
            color: Colors.black.withOpacity(0.4),
          ),

          // --- 3. กล่อง Register และฟอร์ม ---
          // จัดให้อยู่กลางจอ และสามารถ scroll ได้
          Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // --- 4. กล่องกระจก (Glassmorphism) ---
                  // ใช้ดีไซน์เดียวกับหน้า Login เพื่อความสอดคล้อง
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                      child: Container(
                        width: MediaQuery.of(context).size.width * 0.9,
                        padding: const EdgeInsets.all(24.0),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                            width: 1.5,
                          ),
                        ),
                        // --- 5. เนื้อหาภายในกล่อง ---
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // ข้อความต้อนรับ
                              const Text(
                                'สร้างบัญชีใหม่',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const Text(
                                'เตรียมตัวออกเดินทางไปกับ EasyTrip',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white70,
                                ),
                              ),
                              const SizedBox(height: 30),

                              // ช่องกรอกชื่อ-นามสกุล
                              TextFormField(
                                controller: _nameController,
                                decoration: _buildInputDecoration(
                                  'ชื่อ-นามสกุล',
                                  Icons.person_outline,
                                ),
                                style: const TextStyle(color: Colors.white),
                                validator: (value) =>
                                    (value == null || value.isEmpty)
                                    ? 'กรุณากรอกชื่อ'
                                    : null,
                              ),
                              const SizedBox(height: 16),

                              // ช่องกรอกอีเมล
                              TextFormField(
                                controller: _emailController,
                                decoration: _buildInputDecoration(
                                  'อีเมล',
                                  Icons.email_outlined,
                                ),
                                style: const TextStyle(color: Colors.white),
                                keyboardType: TextInputType.emailAddress,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'กรุณากรอกอีเมล';
                                  }
                                  // ใช้ Regular Expression ตรวจสอบรูปแบบอีเมล
                                  final emailRegex = RegExp(
                                    r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+",
                                  );
                                  if (!emailRegex.hasMatch(value)) {
                                    return 'รูปแบบอีเมลไม่ถูกต้อง';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),

                              // ช่องกรอกรหัสผ่าน
                              TextFormField(
                                controller: _passwordController,
                                decoration: _buildInputDecoration(
                                  'รหัสผ่าน',
                                  Icons.lock_outline,
                                ),
                                obscureText: true,
                                style: const TextStyle(color: Colors.white),
                                validator: (value) {
                                  if (value == null || value.isEmpty)
                                    return 'กรุณากรอกรหัสผ่าน';
                                  if (value.length < 6)
                                    return 'รหัสผ่านต้องมีอย่างน้อย 6 ตัวอักษร';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),

                              // ช่องยืนยันรหัสผ่าน
                              TextFormField(
                                controller: _confirmPasswordController,
                                decoration: _buildInputDecoration(
                                  'ยืนยันรหัสผ่าน',
                                  Icons.lock_outline,
                                ),
                                obscureText: true,
                                style: const TextStyle(color: Colors.white),
                                validator: (value) {
                                  if (value != _passwordController.text)
                                    return 'รหัสผ่านไม่ตรงกัน';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 24),

                              // ปุ่มสมัครสมาชิก
                              ElevatedButton(
                                onPressed: _register,
                                child: _isLoading
                                    ? const SizedBox(
                                        height: 24,
                                        width: 24, // กำหนดขนาด
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 3,
                                        ),
                                      )
                                    : const Text('สมัครสมาชิก'),
                              ),
                              const SizedBox(height: 20),

                              // ปุ่มสำหรับกลับไปหน้า Login
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text(
                                  'มีบัญชีอยู่แล้วใช่ไหม? เข้าสู่ระบบ',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
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
          ),
        ],
      ),
    );
  }

  // ฟังก์ชันสำหรับสร้าง Decoration ของ TextFormField เพื่อลดการเขียนโค้ดซ้ำซ้อน
  InputDecoration _buildInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white),
      prefixIcon: Icon(icon, color: Colors.white70),
      filled: true,
      fillColor: Colors.white.withOpacity(0.1),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }
}
