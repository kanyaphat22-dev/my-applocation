import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPanel extends StatelessWidget {
  final VoidCallback onClose;
  const SettingsPanel({super.key, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ✅ แถวบน: ปุ่มปิด + ข้อความ "ตั้งค่า" อยู่ตรงกลาง
          Stack(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.black87, size: 28),
                  onPressed: onClose,
                  tooltip: "ปิด",
                ),
              ),
              const Center(
                child: Text(
                  "การตั้งค่า",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ✅ รายการเมนูการตั้งค่า
          const ListTile(
            leading: Icon(Icons.notifications_active, color: Colors.teal),
            title: Text("การแจ้งเตือน"),
            trailing: Icon(Icons.arrow_forward_ios, size: 16),
          ),
          const Divider(),
          const ListTile(
            leading: Icon(Icons.privacy_tip, color: Colors.teal),
            title: Text("นโยบายความเป็นส่วนตัว"),
            trailing: Icon(Icons.arrow_forward_ios, size: 16),
          ),
          const Divider(),
          const ListTile(
            leading: Icon(Icons.info_outline, color: Colors.teal),
            title: Text("เกี่ยวกับแอป"),
            trailing: Icon(Icons.arrow_forward_ios, size: 16),
          ),
          const Divider(),

          // ✅ ปุ่มออกจากระบบพร้อม Popup ยืนยัน
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: const Text("ออกจากระบบ"),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () async {
              final confirm = await showDialog<bool>(
                context: context,
                barrierDismissible: false, // ต้องกดปุ่มเท่านั้นถึงจะปิด
                builder: (context) {
                  final screenWidth = MediaQuery.of(context).size.width;

                  return Center(
                    child: Material(
                      color: Colors.transparent,
                      child: Container(
                        width: screenWidth * 0.85, // ✅ ขยายให้ใหญ่ขึ้น 85% ของจอ
                        padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              "ยืนยันการออกจากระบบ",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              "คุณต้องการออกจากระบบหรือไม่?",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 17,
                                color: Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 30),

                            // 🔹 ปุ่มยกเลิก / ตกลง — อยู่ตรงกลางและขนาดเท่ากัน
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // ปุ่มยกเลิก
                                OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(
                                        color: Colors.teal, width: 1.8),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    minimumSize: const Size(110, 45),
                                  ),
                                  onPressed: () => Navigator.pop(context, false),
                                  child: const Text(
                                    "ยกเลิก",
                                    style: TextStyle(
                                      color: Colors.teal,
                                      fontSize: 17,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 20),

                                // ปุ่มตกลง
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.teal,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    minimumSize: const Size(110, 45),
                                  ),
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text(
                                    "ตกลง",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 17,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );

              if (confirm == true) {
                final prefs = await SharedPreferences.getInstance();
                await prefs.clear();

                if (context.mounted) {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/welcome',
                    (route) => false,
                  );
                }
              }
            },
          ),

          const SizedBox(height: 60),
        ],
      ),
    );
  }
}
