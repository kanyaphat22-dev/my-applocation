import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final FocusNode _phoneFocusNode = FocusNode();

  String phone = '';
  final ValueNotifier<bool> isValid = ValueNotifier(false);

  @override
  void initState() {
    super.initState();
    // ✅ หลังจาก build เสร็จ ให้ focus ช่องเบอร์โทร
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_phoneFocusNode);
    });
  }

  @override
  void dispose() {
    _phoneFocusNode.dispose();
    isValid.dispose();
    super.dispose();
  }

  void _onPhoneChanged(String value) {
    phone = value;
    isValid.value = phone.length == 10;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.teal,
        child: SafeArea(
          child: Column(
            children: [
              // ปุ่มย้อนกลับบนซ้าย
              Align(
                alignment: Alignment.topLeft,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ),

              // ข้อความบนสุด
              const Padding(
                padding: EdgeInsets.only(top: 16),
                child: Column(
                  children: [
                    Text(
                      "เริ่มต้นใช้งาน",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      "หมายเลขของคุณคืออะไร",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 50),

              // ช่องกรอกเบอร์มือถือ
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Form(
                  key: _formKey,
                  child: Row(
                    children: [
                      Row(
                        children: [
                          Image.asset(
                            "assets/thai_flag.png",
                            width: 60,
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            "+66",
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          focusNode: _phoneFocusNode,
                          keyboardType: TextInputType.phone,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                          ),
                          decoration: const InputDecoration(
                            hintText: "กรอกหมายเลขโทรศัพท์",
                            hintStyle: TextStyle(
                              color: Colors.white70,
                              fontSize: 18,
                            ),
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.white70),
                            ),
                            focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.white),
                            ),
                          ),
                          onChanged: _onPhoneChanged,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const Spacer(),

              // ปุ่มดำเนินการต่อ
              Padding(
                padding: const EdgeInsets.all(24),
                child: SizedBox(
                  width: double.infinity,
                  child: ValueListenableBuilder<bool>(
                    valueListenable: isValid,
                    builder: (context, valid, _) {
                      return ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: valid
                              ? Colors.white
                              : Colors.white.withOpacity(0.4),
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: valid
                            ? () {
                                Navigator.pushNamed(
                                  context,
                                  '/password',
                                  arguments: phone,
                                );
                              }
                            : null,
                        child: Text(
                          "ดำเนินการต่อ",
                          style: TextStyle(
                            fontSize: 22,
                            color: valid ? Colors.teal : Colors.grey[300],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    },
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
