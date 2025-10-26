import 'package:flutter/material.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final FocusNode _phoneFocusNode = FocusNode();

  String phone = '';
  String password = '';
  String confirmPassword = '';

  final ValueNotifier<bool> isValid = ValueNotifier(false);
  final ValueNotifier<bool> showPasswordError = ValueNotifier(false);

  bool _obscurePass = true;
  bool _obscureConfirm = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_phoneFocusNode);
    });
  }

  @override
  void dispose() {
    _phoneFocusNode.dispose();
    isValid.dispose();
    showPasswordError.dispose();
    super.dispose();
  }

  void _validateForm() {
    final phoneOk = phone.length == 10;
    final passOk = password.isNotEmpty && confirmPassword.isNotEmpty;
    final match = password == confirmPassword;

    isValid.value = phoneOk && passOk && match;
    showPasswordError.value = passOk && !match;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.teal,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 150),
            child: Column(
              children: [
                // 🔙 ปุ่มย้อนกลับ
                Align(
                  alignment: Alignment.topLeft,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),

                // 📝 หัวข้อ
                const Padding(
                  padding: EdgeInsets.only(top: 16),
                  child: Column(
                    children: [
                      Text(
                        "ลงชื่อเข้าใช้",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        "ด้วยเบอร์มือถือและรหัสผ่าน",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // ☎️ เบอร์โทร
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      Image.asset("assets/thai_flag.png", width: 50),
                      const SizedBox(width: 6),
                      const Text(
                        "+66",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          focusNode: _phoneFocusNode,
                          keyboardType: TextInputType.phone,
                          style: const TextStyle(color: Colors.white, fontSize: 20),
                          decoration: const InputDecoration(
                            hintText: "กรอกหมายเลขโทรศัพท์",
                            hintStyle: TextStyle(color: Colors.white70, fontSize: 18),
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.white70),
                            ),
                            focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.white),
                            ),
                          ),
                          onChanged: (val) {
                            phone = val;
                            _validateForm();
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // 🔐 รหัสผ่าน
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: TextFormField(
                    obscureText: _obscurePass,
                    style: const TextStyle(color: Colors.white, fontSize: 20),
                    decoration: InputDecoration(
                      hintText: "ตั้งรหัสผ่าน",
                      hintStyle: const TextStyle(color: Colors.white70, fontSize: 18),
                      enabledBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white70),
                      ),
                      focusedBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePass ? Icons.visibility_off : Icons.visibility,
                          color: Colors.white70,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePass = !_obscurePass;
                          });
                        },
                      ),
                    ),
                    onChanged: (val) {
                      password = val;
                      _validateForm();
                    },
                  ),
                ),

                const SizedBox(height: 24),

                // 🔁 ยืนยันรหัสผ่าน
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        obscureText: _obscureConfirm,
                        style: const TextStyle(color: Colors.white, fontSize: 20),
                        decoration: InputDecoration(
                          hintText: "ยืนยันรหัสผ่าน",
                          hintStyle: const TextStyle(color: Colors.white70, fontSize: 18),
                          enabledBorder: const UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.white70),
                          ),
                          focusedBorder: const UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.white),
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirm
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: Colors.white70,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureConfirm = !_obscureConfirm;
                              });
                            },
                          ),
                        ),
                        onChanged: (val) {
                          confirmPassword = val;
                          _validateForm();
                        },
                      ),
                      ValueListenableBuilder<bool>(
                        valueListenable: showPasswordError,
                        builder: (context, showError, _) {
                          return showError
                              ? const Padding(
                                  padding: EdgeInsets.only(top: 6),
                                  child: Text(
                                    "รหัสผ่านไม่ตรงกัน",
                                    style: TextStyle(color: Colors.redAccent),
                                  ),
                                )
                              : const SizedBox.shrink();
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),

      // ✅ ปุ่มล่าง
      bottomNavigationBar: Container(
        color: Colors.teal,
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          top: 12,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              child: ValueListenableBuilder<bool>(
                valueListenable: isValid,
                builder: (context, valid, _) {
                  return ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          valid ? Colors.white : Colors.white.withOpacity(0.4),
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    // ✅ ส่งข้อมูลไปหน้า SetNameScreen
                    onPressed: valid
                        ? () {
                            Navigator.pushReplacementNamed(
                              context,
                              '/setname',
                              arguments: {
                                "phone": phone,
                                "password": password,
                              },
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
            TextButton(
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/login');
              },
              child: const Text(
                "มีบัญชีแล้ว? เข้าสู่ระบบ",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
