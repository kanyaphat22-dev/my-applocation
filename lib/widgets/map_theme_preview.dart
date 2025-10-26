import 'package:flutter/material.dart';

class MapThemePreview extends StatelessWidget {
  final bool isDark;
  const MapThemePreview({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 120,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF0b3d0b), const Color(0xFF1a237e)] // Forest Dark
              : [const Color(0xFFd0f0d0), const Color(0xFF64b5f6)], // Forest Light
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          // ถนน
          Positioned.fill(
            child: CustomPaint(
              painter: _RoadPainter(isDark: isDark),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoadPainter extends CustomPainter {
  final bool isDark;
  _RoadPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isDark ? const Color(0xFF424242) : Colors.white
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // วาดถนนโค้ง
    final path = Path()
      ..moveTo(0, size.height * 0.7)
      ..quadraticBezierTo(
        size.width * 0.3,
        size.height * 0.4,
        size.width,
        size.height * 0.6,
      );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
