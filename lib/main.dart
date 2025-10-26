import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/splash_screen.dart';
import 'screens/welcome_screen.dart';
import 'screens/login_screen.dart';
import 'screens/password_screen.dart';
import 'screens/register_screen.dart';
import 'screens/set_name_screen.dart';
import 'screens/dashboard_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  bool _wasInBackground = false;
  LatLng? _savedLatLng;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadLastLocation();
  }

  Future<void> _loadLastLocation() async {
    final prefs = await SharedPreferences.getInstance();
    final lat = prefs.getDouble('last_lat');
    final lng = prefs.getDouble('last_lng');
    if (lat != null && lng != null) {
      _savedLatLng = LatLng(lat, lng);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.resumed && _wasInBackground) {
      if (_savedLatLng != null && mounted) {
        // ✅ ใช้ PageRouteBuilder เพื่อให้มีแอนิเมชันเลื่อนขึ้น
        Navigator.pushAndRemoveUntil(
          context,
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 400),
            pageBuilder: (_, __, ___) =>
                DashboardScreen(initialLatLng: _savedLatLng!),
            transitionsBuilder: (_, animation, __, child) {
              final tween = Tween<Offset>(
                begin: const Offset(0, 0.2), // เริ่มจากล่างนิด ๆ
                end: Offset.zero,
              ).chain(CurveTween(curve: Curves.easeOutCubic));
              return SlideTransition(position: animation.drive(tween), child: child);
            },
          ),
          (route) => false,
        );
      }
      _wasInBackground = false;
    } else if (state == AppLifecycleState.paused) {
      _wasInBackground = true;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'FamilyGPS',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        scaffoldBackgroundColor: Colors.white,
        textSelectionTheme: const TextSelectionThemeData(
          cursorColor: Colors.white,
          selectionColor: Colors.tealAccent,
          selectionHandleColor: Colors.tealAccent,
        ),
      ),
      initialRoute: '/splash',

      routes: {
        '/splash': (context) => const SplashScreen(),
        '/welcome': (context) => const WelcomeScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/setname': (context) => const SetNameScreen(),
      },

      onGenerateRoute: (settings) {
        // หน้า Password
        if (settings.name == '/password') {
          final phone = settings.arguments as String;
          return MaterialPageRoute(
            builder: (_) => const PasswordScreen(),
            settings: RouteSettings(arguments: phone),
          );
        }

        // ✅ หน้า Dashboard — เพิ่มแอนิเมชันเลื่อนขึ้นเช่นกัน
        if (settings.name == '/dashboard') {
          final args = settings.arguments as Map<String, dynamic>;
          final latLng = args["latlng"] ?? const LatLng(0, 0);

          return PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 400),
            pageBuilder: (_, __, ___) => DashboardScreen(initialLatLng: latLng),
            transitionsBuilder: (_, animation, __, child) {
              final tween = Tween<Offset>(
                begin: const Offset(0, 0.2),
                end: Offset.zero,
              ).chain(CurveTween(curve: Curves.easeOutCubic));
              return SlideTransition(position: animation.drive(tween), child: child);
            },
          );
        }

        return null;
      },
    );
  }
}
