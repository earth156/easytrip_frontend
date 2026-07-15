import 'package:flutter/material.dart';
import 'dart:ui'; // Import สำหรับใช้ ImageFilter (เอฟเฟกต์เบลอ)
import 'package:easytrip_frontend/core/utils/custom_dialogs.dart';

import '../controllers/auth_controller.dart';
import '../models/auth_result.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // GlobalKey สำหรับใช้ควบคุมและตรวจสอบ Form ของเรา
  final AuthController _authController = AuthController();
  bool _isLoading = false;
  // State สำหรับเก็บข้อความ Error จากฝั่ง Server
  String? _serverError;

  final _formKey = GlobalKey<FormState>();

  // TextEditingController สำหรับดึงค่าจากช่องกรอกข้อความ
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // อย่าลืม dispose controller เมื่อ Widget นี้ถูกทำลาย เพื่อคืน memory
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() async {
    // ตรวจสอบว่าข้อมูลในฟอร์มผ่านเงื่อนไข (validator) ทั้งหมดหรือไม่
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final result = await _authController.login(
        email: _emailController.text,
        password: _passwordController.text,
      );

      setState(() {
        _serverError = null; // ล้างค่า server error เก่าทุกครั้งที่กด login
      });

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      switch (result) {
        case LoginSuccess(user: final user):
          // The controller has already saved the token and user info.
          print('Login successful for ${user.name}');
          // หลังจากล็อกอินสำเร็จ ให้เปลี่ยนไปหน้า Home
          // ใช้ pushReplacementNamed เพื่อไม่ให้ผู้ใช้กด back กลับมาหน้า login ได้อีก
          Navigator.pushReplacementNamed(context, '/home');
          break;

        case AuthFailure(message: final msg):
          // เมื่อ Login ไม่สำเร็จ ให้เก็บข้อความ Error ไว้ใน State
          // แล้วเรียก formKey.currentState!.validate() อีกครั้งเพื่อให้ UI อัปเดต
          setState(() {
            _serverError = msg;
          });
          _formKey.currentState!.validate();
          break;

        // Default case to handle other AuthResult types if any
        default:
          // จัดการเคสที่ไม่คาดคิด
          setState(() {
            _serverError = 'เกิดข้อผิดพลาดที่ไม่คาดคิด';
          });
          _formKey.currentState!.validate();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Scaffold คือโครงสร้างพื้นฐานของหน้าจอ
    return Scaffold(
      // ใช้ Stack เพื่อซ้อน Widget ต่างๆ ทับกัน
      // ชั้นล่างสุด -> รูปพื้นหลัง
      // ชั้นกลาง -> Overlay สีดำโปร่งแสง
      // ชั้นบนสุด -> กล่อง Login และฟอร์ม
      body: Stack(
        children: [
          // --- 1. พื้นหลัง (Background Image) ---
          // เปลี่ยนมาใช้ Image.asset เพื่อดึงรูปจากในโปรเจกต์
          // ให้นำไฟล์ภาพพื้นหลัง (เช่น background.jpg) ไปไว้ในโฟลเดอร์ assets/images/
          Image.asset(
            'assets/images/background.jpg', // แก้เป็นชื่อไฟล์ภาพพื้นหลังของคุณ
            height: double.infinity,
            width: double.infinity,
            fit: BoxFit.cover, // ทำให้รูปเต็มจอโดยไม่เสียสัดส่วน
          ),

          // --- 2. Overlay สีดำโปร่งแสง ---
          // Container สีดำที่มี Opacity เพื่อดรอปความสว่างของภาพพื้นหลัง
          Container(
            height: double.infinity,
            width: double.infinity,
            color: Colors.black.withOpacity(0.4),
          ),

          // --- 3. กล่อง Login และฟอร์ม ---
          // จัดให้อยู่กลางจอ และสามารถ scroll ได้
          Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // --- 4. กล่องกระจก (Glassmorphism) ---
                  // ใช้ ClipRRect เพื่อทำให้ขอบของกล่องมน
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BackdropFilter(
                      // ใช้ ImageFilter.blur เพื่อทำเอฟเฟกต์เบลอฉากหลัง
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        // กำหนดขนาดและความโปร่งแสงของกล่อง
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
                                'EasyTrip',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const Text(
                                'พร้อมจะออกเดินทางหรือยัง?',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white70,
                                ),
                              ),
                              const SizedBox(height: 30),

                              // ช่องกรอกอีเมล
                              TextFormField(
                                controller: _emailController,
                                decoration: _buildInputDecoration(
                                  'อีเมล',
                                  Icons.email_outlined,
                                ),
                                style: const TextStyle(color: Colors.white),
                                keyboardType: TextInputType.emailAddress,
                                // เพิ่ม onChanged เพื่อล้าง server error เมื่อผู้ใช้เริ่มพิมพ์แก้ไข
                                onChanged: (value) {
                                  if (_serverError != null) {
                                    setState(() {
                                      _serverError = null;
                                    });
                                  }
                                },
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
                                  // ถ้ามี serverError ให้แสดงผลที่ช่องอีเมลด้วย
                                  // เพื่อให้ผู้ใช้รู้ว่าข้อมูลที่กรอกอาจไม่ถูกต้อง
                                  return _serverError;
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
                                // เพิ่ม onChanged เพื่อล้าง server error เมื่อผู้ใช้เริ่มพิมพ์แก้ไข
                                onChanged: (value) {
                                  if (_serverError != null) {
                                    setState(() {
                                      _serverError = null;
                                    });
                                  }
                                },
                                validator: (value) =>
                                    (value == null || value.isEmpty)
                                    ? 'กรุณากรอกรหัสผ่าน'
                                    // ถ้ามี serverError ให้แสดงผลที่ช่องรหัสผ่าน
                                    // เพื่อให้ผู้ใช้รู้ว่าข้อมูลที่กรอกอาจไม่ถูกต้อง
                                    : _serverError,
                              ),
                              const SizedBox(height: 24),

                              // ปุ่มเข้าสู่ระบบ
                              ElevatedButton(
                                onPressed: _login,
                                child: _isLoading
                                    ? const SizedBox(
                                        height: 24,
                                        width: 24,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 3,
                                        ),
                                      )
                                    : const Text('เข้าสู่ระบบ'),
                              ),
                              const SizedBox(height: 16),

                              // เส้นคั่น "หรือ"
                              Row(
                                children: [
                                  const Expanded(
                                    child: Divider(color: Colors.white54),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8.0,
                                    ),
                                    child: Text(
                                      'หรือ',
                                      style: TextStyle(color: Colors.white70),
                                    ),
                                  ),
                                  const Expanded(
                                    child: Divider(color: Colors.white54),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // ปุ่มเข้าสู่ระบบด้วย Google
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: Colors.black87,
                                ),
                                onPressed: () {
                                  // TODO: Implement Google Login
                                  print('Google Login Tapped');
                                },
                                icon: Image.asset(
                                  'assets/images/google_logo.png', // เปลี่ยนมาใช้รูปจากในโปรเจกต์
                                  height: 20, // กำหนดความสูงของไอคอน
                                ),
                                label: const Text('เข้าสู่ระบบด้วย Google'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // ลิงก์ไปหน้าสมัครสมาชิก
                  Padding(
                    padding: const EdgeInsets.only(top: 20.0),
                    child: TextButton(
                      onPressed: () =>
                          Navigator.pushNamed(context, '/register'),
                      child: const Text(
                        'ยังไม่มีบัญชีใช่ไหม? สมัครสมาชิก',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
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
