import 'package:flutter/material.dart';

class TopNameBar extends StatefulWidget {
  final String userName;
  final Color avatarColor;
  final ValueChanged<bool>? onPanelVisibilityChanged;

  const TopNameBar({
    super.key,
    required this.userName,
    this.avatarColor = Colors.teal,
    this.onPanelVisibilityChanged,
  });

  @override
  State<TopNameBar> createState() => _TopNameBarState();
}

class _TopNameBarState extends State<TopNameBar> {
  bool _isProfilePanelVisible = false;

  void _togglePanel() {
    setState(() => _isProfilePanelVisible = !_isProfilePanelVisible);
    widget.onPanelVisibilityChanged?.call(_isProfilePanelVisible);
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final double nameWidth = w * 0.55;

    return Stack(
      children: [
        // ✅ พื้นหลังขาวเต็มจอ
        AnimatedPositioned(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOutCubic,
          top: _isProfilePanelVisible ? 0 : -MediaQuery.of(context).size.height,
          left: 0,
          right: 0,
          height: MediaQuery.of(context).size.height,
          child: Container(
            color: Colors.white,
            child: SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 80), // ⬅️ จาก 100 ลดเหลือ 40 ให้ใกล้ปุ่มชื่อมากขึ้น

                  // ✅ กล่อง teal โปร่ง + แถบซ้าย
                  Stack(
                    children: [
                      Container(
                        width: double.infinity,
                        height: 90,
                        decoration: BoxDecoration(
                          color: Colors.teal.withOpacity(0.25),
                          border: const Border(
                            left: BorderSide(
                              color: Colors.teal,
                              width: 6,
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(
                            left: 26, right: 20, top: 14, bottom: 14),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: widget.avatarColor,
                              child: Text(
                                widget.userName.isNotEmpty
                                    ? widget.userName[0]
                                    : "?",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                widget.userName,
                                style: const TextStyle(
                                  color: Colors.teal,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const Icon(
                              Icons.check_rounded,
                              color: Colors.teal,
                              size: 30,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),

        // ✅ ปุ่มชื่อ (อยู่บนสุด)
        Positioned(
          top: MediaQuery.of(context).padding.top + 12,
          left: (w - nameWidth) / 2,
          child: GestureDetector(
            onTap: _togglePanel,
            child: Container(
              width: nameWidth,
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: widget.avatarColor,
                        child: Text(
                          widget.userName.isNotEmpty
                              ? widget.userName[0]
                              : "?",
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        widget.userName,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                  Icon(
                    _isProfilePanelVisible
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: Colors.teal,
                    size: 26,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
