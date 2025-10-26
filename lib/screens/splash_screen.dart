import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dashboard_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  /// ✅ ตรวจสอบ token เพื่อตัดสินใจว่าจะไปหน้าไหน
  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    // ✅ หน่วงเวลา 2 วิ เพื่อให้โลโก้โชว์ก่อน
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    if (token != null && token.isNotEmpty) {
      // ✅ หา location ปัจจุบันก่อนเข้า Dashboard
      LatLng currentLatLng = const LatLng(13.736717, 100.523186); // fallback = กทม.
      try {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        currentLatLng = LatLng(position.latitude, position.longitude);
      } catch (e) {
        debugPrint("❌ หา location ไม่ได้: $e");
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => DashboardScreen(initialLatLng: currentLatLng),
        ),
      );
    } else {
      // ❌ ไม่มี token → ไปหน้า welcome
      Navigator.pushReplacementNamed(context, '/welcome');
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final logoSize =
        (screenWidth * 0.4 > 250 ? 250 : screenWidth * 0.4).toDouble();

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFFFFFFF), // ขาวด้านบน
              Color.fromARGB(255, 35, 149, 121), // เขียวเข้มด้านล่าง
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 80),
            child: Image.asset(
              "assets/logo.png",
              width: logoSize,
            ),
          ),
        ),
      ),
    );
  }
}
