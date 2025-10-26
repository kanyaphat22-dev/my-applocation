// ignore_for_file: prefer_const_constructors, use_build_context_synchronously, avoid_print

import 'dart:typed_data';
import 'dart:convert';
import 'dart:ui' as ui;
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mqtt_client/mqtt_client.dart';
import '../mqtt/mqtt_service.dart';
import 'settings_screen.dart';
import 'top_name_bar.dart';

class DashboardScreen extends StatefulWidget {
  final LatLng initialLatLng;
  const DashboardScreen({super.key, required this.initialLatLng});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with WidgetsBindingObserver {
  GoogleMapController? _mapController;
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();

  LatLng? _currentLatLng;
  Set<Marker> _markers = {};
  Set<Circle> _circles = {};
  StreamSubscription<Position>? _positionStream;

  String userName = "ไม่ทราบชื่อ";
  Uint8List? profileImageBytes;
  String _currentAddress = "กำลังค้นหาที่อยู่...";
  Color avatarColor = Colors.teal;
  String? _apiKey = "AIzaSyCtw23gfoitqOgAkS7TUiJ2UYWtD5eYRes";

  double _defaultZoom = 17;
  double _currentZoom = 17;
  double _panelExtent = 0.2;
  double _savedPanelExtent = 0.2;
  bool _isAutoFollow = false;
  bool _isAnimatingPanel = false;
  bool _isProfilePanelVisible = false;

  String? _statusLabel;
  DateTime? _idleStart;
  Timer? _idleTimer;
  DateTime? _lastSentTime;

  static const double markerSize = 200;
  static const double dotSize = 30;
  BitmapDescriptor? _cachedMarkerIcon;
  String? _cachedStatusLabel;

  final MQTTService mqttService = MQTTService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await mqttService.connect("kanyaphat"); // 🔹 user id จริงของคุณ
      _listenToLocation();

      if (_sheetController.isAttached) {
        _sheetController.jumpTo(0.2);
        _panelExtent = 0.2;
      }

      await Future.delayed(Duration(milliseconds: 400));
      if (_sheetController.isAttached) {
        await _sheetController.animateTo(
          0.25,
          duration: Duration(milliseconds: 500),
          curve: Curves.easeOutCubic,
        );
        await Future.delayed(Duration(milliseconds: 100));
        await _sheetController.animateTo(
          0.2,
          duration: Duration(milliseconds: 500),
          curve: Curves.easeInOutCubic,
        );
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _sheetController.dispose();
    _positionStream?.cancel();
    _idleTimer?.cancel();
    mqttService.disconnect();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (_sheetController.isAttached) {
        _sheetController.animateTo(
          _savedPanelExtent,
          duration: Duration(milliseconds: 500),
          curve: Curves.easeOutCubic,
        );
      }
    } else if (state == AppLifecycleState.paused) {
      _savedPanelExtent = _panelExtent;
    }
  }

  /// ✅ ฟังตำแหน่ง — ส่ง MQTT เฉพาะเมื่อขยับเกิน 20 ม. หรืออยู่นิ่งน้อยกว่า 10 นาที
  Future<void> _listenToLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) {
      await openAppSettings();
      return;
    }

    Position current = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.bestForNavigation,
    );
    _currentLatLng = LatLng(current.latitude, current.longitude);
    LatLng lastStableLatLng = _currentLatLng!;
    bool isMoving = false;
    _lastSentTime = DateTime.now();

    await _updateMarkerAndCircle(_currentLatLng!);
    _updateAddress(_currentLatLng!);

    _positionStream?.cancel();
    _positionStream = Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 5,
      ),
    ).listen((pos) async {
      final newLatLng = LatLng(pos.latitude, pos.longitude);
      final speed = pos.speed;

      double distanceFromStable = Geolocator.distanceBetween(
        lastStableLatLng.latitude,
        lastStableLatLng.longitude,
        newLatLng.latitude,
        newLatLng.longitude,
      );

      final now = DateTime.now();
      final idleDuration =
          _idleStart == null ? Duration.zero : now.difference(_idleStart!);

      // 🔹 ถ้าอยู่นิ่งเกิน 10 นาที และไม่ขยับเกิน 20 ม. -> ไม่อัปเดต
      if (idleDuration.inMinutes >= 10 && distanceFromStable < 20) {
        print("⏸ อยู่นิ่งในรัศมี 20 ม. เกิน 10 นาที — ไม่อัปเดต MQTT");
        return;
      }

      if (distanceFromStable >= 20) {
        final builder = MqttClientPayloadBuilder();
        builder.addString(jsonEncode({
          'user_id': userName,
          'lat': pos.latitude,
          'lon': pos.longitude,
          'acc': pos.accuracy,
          'time': now.toIso8601String(),
        }));

        mqttService.client.publishMessage(
          mqttService.topic,
          MqttQos.atLeastOnce,
          builder.payload!,
        );

        print('📡 ส่ง MQTT: ${pos.latitude}, ${pos.longitude}');
        lastStableLatLng = newLatLng;
        _lastSentTime = now;
      }

      if (speed > 1.0) {
        if (!isMoving) {
          isMoving = true;
          print("🚗 เริ่มเคลื่อนไหว — โหมดเรียลไทม์");
        }
        _idleStart = null;
        _idleTimer?.cancel();
        _idleTimer = null;
        _currentLatLng = newLatLng;
        await _updateMarkerAndCircle(newLatLng);
        _updateAddress(newLatLng);
      } else {
        if (_idleStart == null) _idleStart = DateTime.now();
        final diff = DateTime.now().difference(_idleStart!);
        if (diff.inSeconds > 30 && isMoving) {
          isMoving = false;
          lastStableLatLng = newLatLng;
          print("🛑 หยุดนิ่ง — ออกจากโหมดเรียลไทม์");
        }
        if (!isMoving) {
          final newLabel = _formatIdle(diff);
          if (newLabel != _statusLabel) {
            _statusLabel = newLabel;
            await _updateMarkerAndCircle(newLatLng);
          }
        }
      }

      _updateAddress(newLatLng);
      if (_isAutoFollow && _mapController != null) {
        _mapController!.animateCamera(CameraUpdate.newLatLng(newLatLng));
      }
    });
  }

  String _formatIdle(Duration d) {
    if (d.inDays > 0) return "พักอยู่ที่นี่ ${d.inDays} วัน ${d.inHours % 24} ชม.";
    if (d.inHours > 0) return "พักอยู่ที่นี่ ${d.inHours} ชม. ${d.inMinutes % 60} นาที";
    return "พักอยู่ที่นี่ ${d.inMinutes} นาที";
  }

  Future<void> _updateAddress(LatLng latLng) async {
    if (_apiKey == null) return;
    final url = Uri.parse(
      "https://maps.googleapis.com/maps/api/geocode/json?latlng=${latLng.latitude},${latLng.longitude}&key=$_apiKey&language=th",
    );
    try {
      final res = await http.get(url);
      final data = jsonDecode(res.body);
      if (data["status"] == "OK") {
        setState(() => _currentAddress = data["results"][0]["formatted_address"]);
      }
    } catch (_) {}
  }

  Future<BitmapDescriptor> _createCustomMarker({
    Uint8List? imageBytes,
    String? name,
    String? statusLabel,
  }) async {
    const double size = markerSize;
    const double dot = dotSize;
    const double labelTopMargin = 24;
    const double labelGapBelow = 14;
    const double hPad = 32;
    const double vPad = 20;
    final double maxLabelWidth = size * 2.0;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final paint = Paint()..isAntiAlias = true;
    double boxW = 0, boxH = 0;
    TextPainter? labelTP;

    if (statusLabel != null) {
      double fontSize = 32;
      final len = statusLabel.length;
      if (len > 15) fontSize = 28;
      if (len > 25) fontSize = 24;

      labelTP = TextPainter(
        text: TextSpan(
          text: statusLabel,
          style: TextStyle(
            color: Colors.white,
            fontSize: fontSize,
            fontWeight: FontWeight.w700,
            height: 1.2,
          ),
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
        maxLines: 2,
      )..layout(maxWidth: maxLabelWidth);

      boxW = labelTP.width + (hPad * 2);
      boxH = labelTP.height + (vPad * 2);
    }

    final double extraTop =
        (statusLabel != null) ? (labelTopMargin + boxH + labelGapBelow) : 0;
    final double totalH = extraTop + size + dot;
    final center = Offset(size / 2, extraTop + size / 2);

    paint.color = Colors.white;
    canvas.drawCircle(center, size / 2, paint);

    if (imageBytes != null) {
      final codec = await ui.instantiateImageCodec(
        imageBytes,
        targetWidth: (size - 20).toInt(),
        targetHeight: (size - 20).toInt(),
      );
      final frame = await codec.getNextFrame();
      final img = frame.image;

      final clipPath = Path()
        ..addOval(Rect.fromCircle(center: center, radius: (size / 2) - 10));
      canvas.save();
      canvas.clipPath(clipPath);
      paintImage(
        canvas: canvas,
        rect: Rect.fromCircle(center: center, radius: (size / 2) - 10),
        image: img,
        fit: BoxFit.cover,
      );
      canvas.restore();
    } else {
      paint.color = avatarColor;
      canvas.drawCircle(center, (size / 2) - 12, paint);
      final tp = TextPainter(
        text: TextSpan(
          text: (name?.isNotEmpty ?? false) ? name![0] : "?",
          style: TextStyle(
              color: Colors.white, fontSize: 64, fontWeight: FontWeight.bold),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(center.dx - tp.width / 2, center.dy - tp.height / 2));
    }

    paint.color = Colors.white;
    canvas.drawCircle(
      Offset(size / 2, extraTop + size + (dot / 2) - 2),
      dot / 2,
      paint,
    );

    if (statusLabel != null && labelTP != null) {
      final Color bg = Colors.teal.withOpacity(0.92);
      final rect = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(size / 2, labelTopMargin + boxH / 2),
          width: boxW,
          height: boxH,
        ),
        Radius.circular(999),
      );
      final shadowPaint = Paint()
        ..color = Colors.black.withOpacity(0.25)
        ..maskFilter = ui.MaskFilter.blur(ui.BlurStyle.normal, 6);
      canvas.drawRRect(rect, shadowPaint);
      paint.color = bg;
      canvas.drawRRect(rect, paint);
      labelTP.paint(
        canvas,
        Offset(rect.outerRect.center.dx - labelTP.width / 2,
            rect.outerRect.center.dy - labelTP.height / 2),
      );
    }

    final img = await recorder.endRecording().toImage(size.toInt(), totalH.toInt());
    final data = await img.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.fromBytes(data!.buffer.asUint8List());
  }

  Future<void> _updateMarkerAndCircle(LatLng latLng) async {
    if (_cachedMarkerIcon == null || _cachedStatusLabel != _statusLabel) {
      _cachedMarkerIcon = await _createCustomMarker(
        imageBytes: profileImageBytes,
        name: userName,
        statusLabel: _statusLabel,
      );
      _cachedStatusLabel = _statusLabel;
    }

    final icon = _cachedMarkerIcon!;
    double labelHeight = _statusLabel != null ? 70 : 0;
    final double totalHeight = markerSize + dotSize + labelHeight;
    final double anchorY = (totalHeight - (dotSize / 2)) / totalHeight;

    setState(() {
      _markers
        ..clear()
        ..add(Marker(
          markerId: MarkerId("me"),
          position: latLng,
          icon: icon,
          anchor: Offset(0.5, anchorY),
        ));

      _circles.clear();
      if (_currentZoom > 17.5) {
        _circles.add(Circle(
          circleId: CircleId("accuracy"),
          center: latLng,
          radius: 30,
          fillColor: Colors.teal.withOpacity(0.08),
          strokeColor: Colors.teal.withOpacity(0.4),
          strokeWidth: 1,
        ));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_currentLatLng == null) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final h = MediaQuery.of(context).size.height;
    final fabTop = h * (1 - _panelExtent) - 70;
    double _locationOpacity = _isProfilePanelVisible ? 0.0 : 1.0;

    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: (controller) async {
              _mapController = controller;
              try {
                String style = await DefaultAssetBundle.of(context)
                    .loadString('assets/map_styles/forest_light.json');
                _mapController!.setMapStyle(style);
              } catch (e) {
                print("⚠️ ไม่พบไฟล์ forest_light.json: $e");
              }
              await _updateMarkerAndCircle(_currentLatLng!);
            },
            onCameraMoveStarted: () async {
              if (_isAnimatingPanel) return;
              if (_sheetController.isAttached && _panelExtent > 0.2) {
                _isAnimatingPanel = true;
                await _sheetController.animateTo(
                  0.2,
                  duration: Duration(milliseconds: 550),
                  curve: Curves.easeInOutCubic,
                );
                setState(() => _panelExtent = 0.2);
                _isAnimatingPanel = false;
              }
            },
            onCameraMove: (pos) async {
              _currentZoom = pos.zoom;
              if (_currentLatLng != null) {
                await _updateMarkerAndCircle(_currentLatLng!);
              }
            },
            initialCameraPosition:
                CameraPosition(target: _currentLatLng!, zoom: _currentZoom),
            markers: _markers,
            circles: _circles,
            myLocationEnabled: false,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
          ),

          TopNameBar(
            userName: userName,
            avatarColor: avatarColor,
            onPanelVisibilityChanged: (visible) {
              setState(() => _isProfilePanelVisible = visible);
            },
          ),

          // ปุ่มตั้งค่า
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            right: 16,
            child: Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 6,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: IconButton(
                padding: EdgeInsets.zero,
                icon: Icon(Icons.settings, color: Colors.teal, size: 24),
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) {
                      final controller = DraggableScrollableController();
                      Future.delayed(Duration(milliseconds: 150), () {
                        controller.animateTo(
                          0.95,
                          duration: Duration(milliseconds: 600),
                          curve: Curves.easeOutCubic,
                        );
                      });
                      return DraggableScrollableSheet(
                        controller: controller,
                        initialChildSize: 0.6,
                        minChildSize: 0.4,
                        maxChildSize: 0.95,
                        expand: false,
                        builder: (context, scrollController) {
                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius:
                                  BorderRadius.vertical(top: Radius.circular(24)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 10,
                                  offset: Offset(0, -3),
                                ),
                              ],
                            ),
                            child: SingleChildScrollView(
                              controller: scrollController,
                              child: SettingsPanel(
                                onClose: () => Navigator.pop(context),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ),

          // ปุ่มตำแหน่ง
          Positioned(
            top: fabTop,
            right: 16,
            child: AnimatedOpacity(
              duration: Duration(milliseconds: 250),
              opacity: _locationOpacity,
              child: IgnorePointer(
                ignoring: _isProfilePanelVisible || _locationOpacity == 0,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 6,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: Icon(Icons.my_location,
                        color: Colors.teal, size: 24),
                    onPressed: () {
                      if (_currentLatLng != null) {
                        _isAutoFollow = true;
                        _mapController?.animateCamera(
                          CameraUpdate.newLatLngZoom(
                              _currentLatLng!, _defaultZoom),
                        );
                        Future.delayed(
                          Duration(seconds: 3),
                          () => _isAutoFollow = false,
                        );
                      }
                    },
                  ),
                ),
              ),
            ),
          ),

          // Panel ด้านล่าง
          AnimatedOpacity(
            duration: Duration(milliseconds: 300),
            opacity: _isProfilePanelVisible ? 0 : 1,
            child: IgnorePointer(
              ignoring: _isProfilePanelVisible,
              child: NotificationListener<DraggableScrollableNotification>(
                onNotification: (n) {
                  setState(() {
                    _panelExtent = n.extent;
                    _savedPanelExtent = n.extent;
                  });
                  return true;
                },
                child: DraggableScrollableSheet(
                  controller: _sheetController,
                  initialChildSize: 0.2,
                  minChildSize: 0.2,
                  maxChildSize: 0.6,
                  builder: (context, scrollController) => Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(20)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 8,
                          offset: Offset(0, -3),
                        ),
                      ],
                    ),
                    child: ListView(
                      controller: scrollController,
                      padding: EdgeInsets.all(16),
                      children: [
                        Center(
                          child: Container(
                            width: 40,
                            height: 5,
                            margin: EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.grey[400],
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 30,
                              backgroundColor: avatarColor,
                              child: Text(
                                userName[0],
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    userName,
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 6),
                                  Text(
                                    _currentAddress,
                                    style: TextStyle(fontSize: 16),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
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
