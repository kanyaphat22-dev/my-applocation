import 'dart:typed_data';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class SetNameScreen extends StatefulWidget {
  const SetNameScreen({super.key});

  @override
  State<SetNameScreen> createState() => _SetNameScreenState();
}

class _SetNameScreenState extends State<SetNameScreen> {
  String firstName = '';
  String lastName = '';
  bool isValid = false;
  Uint8List? profileImageBytes;

  final ImagePicker _picker = ImagePicker();
  late final Color avatarBgColor;

  @override
  void initState() {
    super.initState();
    avatarBgColor = _getRandomAvatarColor();
  }

  Color _getRandomAvatarColor() {
    final rand = Random();
    MaterialColor color;
    do {
      color = Colors.primaries[rand.nextInt(Colors.primaries.length)];
    } while (color == Colors.teal);
    return color.shade400;
  }

  void _validate() {
    setState(() {
      isValid = firstName.trim().isNotEmpty && lastName.trim().isNotEmpty;
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    PermissionStatus status;

    if (source == ImageSource.gallery) {
      status = await Permission.photos.request();
      if (!status.isGranted) {
        status = await Permission.storage.request();
      }
    } else {
      status = await Permission.camera.request();
    }

    if (!status.isGranted) return;

    final XFile? picked = await _picker.pickImage(
      source: source,
      imageQuality: 60,
      maxWidth: 800,
    );

    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() {
        profileImageBytes = bytes;
      });
    }
  }

  void _showImagePicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.gallery);
                },
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.photo_library, size: 40, color: Colors.teal),
                    SizedBox(height: 8),
                    Text("แกลเลอรี่"),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.camera);
                },
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.photo_camera, size: 40, color: Colors.teal),
                    SizedBox(height: 8),
                    Text("กล้อง"),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<LatLng> _getCurrentLatLng() async {
    var status = await Permission.location.request();
    if (!status.isGranted) return const LatLng(13.7563, 100.5018);

    try {
      Position pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      return LatLng(pos.latitude, pos.longitude);
    } catch (e) {
      debugPrint("❌ หา location ไม่ได้: $e");
      return const LatLng(13.7563, 100.5018);
    }
  }

  @override
  Widget build(BuildContext context) {
    String initials =
        firstName.isNotEmpty ? firstName.trim()[0].toUpperCase() : "?";

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.teal,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 100,
          ),
          child: Column(
            children: [
              Align(
                alignment: Alignment.topLeft,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pushReplacementNamed(
                    context,
                    '/register',
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "ตั้งค่าโปรไฟล์ของคุณ",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 30),

              // 🔹 Avatar
              Stack(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: profileImageBytes == null
                        ? avatarBgColor
                        : Colors.transparent,
                    backgroundImage: profileImageBytes != null
                        ? MemoryImage(profileImageBytes!)
                        : null,
                    child: profileImageBytes == null
                        ? Text(
                            initials,
                            style: const TextStyle(
                              fontSize: 40,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _showImagePicker,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          size: 24,
                          color: Colors.teal,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 40),

              // 🔹 ชื่อ
              TextFormField(
                style: const TextStyle(color: Colors.white, fontSize: 20),
                decoration: const InputDecoration(
                  hintText: "ชื่อ",
                  hintStyle: TextStyle(color: Colors.white70, fontSize: 18),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white70),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                ),
                onChanged: (val) {
                  firstName = val;
                  _validate();
                },
              ),

              const SizedBox(height: 24),

              // 🔹 นามสกุล
              TextFormField(
                style: const TextStyle(color: Colors.white, fontSize: 20),
                decoration: const InputDecoration(
                  hintText: "นามสกุล",
                  hintStyle: TextStyle(color: Colors.white70, fontSize: 18),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white70),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                ),
                onChanged: (val) {
                  lastName = val;
                  _validate();
                },
              ),
            ],
          ),
        ),
      ),

      // ✅ ปุ่มดำเนินการต่อ (ไม่ผ่าน API)
      bottomNavigationBar: Container(
        color: Colors.teal,
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          top: 12,
        ),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: isValid ? Colors.white : Colors.grey,
            padding: const EdgeInsets.symmetric(vertical: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: isValid
              ? () async {
                  String fullName = "$firstName $lastName";
                  LatLng currentLatLng = await _getCurrentLatLng();

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content:
                          Text("เข้าสู่ระบบสำเร็จ (โหมดทดสอบไม่เชื่อม API)"),
                    ),
                  );

                  if (!context.mounted) return;
                  Navigator.pushReplacementNamed(
                    context,
                    '/dashboard',
                    arguments: {
                      "name": fullName,
                      "imageBytes": profileImageBytes,
                      "latlng": currentLatLng,
                      "color": avatarBgColor.value,
                    },
                  );
                }
              : null,
          child: Text(
            "ดำเนินการต่อ",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: isValid ? Colors.teal : Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
