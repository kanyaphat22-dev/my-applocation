import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dashboard_screen.dart';

class PasswordScreen extends StatefulWidget {
  const PasswordScreen({super.key});

  @override
  State<PasswordScreen> createState() => _PasswordScreenState();
}

class _PasswordScreenState extends State<PasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  String password = '';
  bool _isLoading = false;
  String _errorMessage = '';

  /// ✅ ฟังก์ชันจำลองล็อกอิน (ไม่ผ่าน API)
  Future<void> _fakeLogin(String phone) async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // ✅ เก็บข้อมูลจำลองใน SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', 'dummy_token_123');
      await prefs.setString('fullname', 'ผู้ใช้ทดสอบ');
      await prefs.setString('phone', phone);

      // ✅ หา location ปัจจุบัน
      LatLng currentLatLng = const LatLng(13.736717, 100.523186);
      try {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        currentLatLng = LatLng(position.latitude, position.longitude);
      } catch (e) {
        debugPrint("❌ หา location ไม่ได้: $e");
      }

      if (!mounted) return;

      // ✅ เข้าหน้า Dashboard
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => DashboardScreen(initialLatLng: currentLatLng),
        ),
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'เกิดข้อผิดพลาดภายในแอป';
      });
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final phone = ModalRoute.of(context)!.settings.arguments as String?;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.teal,
        child: SafeArea(
          child: Column(
            children: [
              // 🔹 ปุ่มย้อนกลับ
              Align(
                alignment: Alignment.topLeft,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),

              const SizedBox(height: 16),

              const Text(
                "เริ่มต้นใช้งานด้วย",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "เบอร์: $phone",
                style: const TextStyle(fontSize: 20, color: Colors.white70),
              ),

              const SizedBox(height: 50),

              // 🔹 ช่องกรอกรหัสผ่าน
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Form(
                  key: _formKey,
                  child: TextFormField(
                    obscureText: true,
                    autofocus: true,
                    style: const TextStyle(color: Colors.white, fontSize: 20),
                    decoration: const InputDecoration(
                      hintText: "กรอกรหัสผ่าน",
                      hintStyle: TextStyle(color: Colors.white70, fontSize: 18),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white70),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white),
                      ),
                    ),
                    validator: (val) {
                      if (val == null || val.isEmpty) {
                        return "กรุณากรอกรหัสผ่าน";
                      }
                      return null;
                    },
                    onSaved: (val) => password = val ?? '',
                  ),
                ),
              ),

              const SizedBox(height: 20),

              if (_errorMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    _errorMessage,
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                ),

              const Spacer(),

              // 🔹 ปุ่มเข้าสู่ระบบ
              Padding(
                padding: const EdgeInsets.all(24),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _isLoading
                        ? null
                        : () {
                            if (_formKey.currentState!.validate()) {
                              _formKey.currentState!.save();
                              _fakeLogin(phone!); // 🔹 ใช้ login จำลองแทน
                            }
                          },
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.teal)
                        : const Text(
                            "เข้าสู่ระบบ",
                            style: TextStyle(
                              fontSize: 22,
                              color: Colors.teal,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
