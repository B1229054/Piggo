import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'main_navigation.dart'; // 暫時先跳轉到導覽列 (之後你有 quiz.dart 再換過去)

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isHappyPig = true;

  @override
  void initState() {
    super.initState();
    _testBackend();
  }

  // 🔥 測試後端連線
  Future<void> _testBackend() async {
    try {
      // 注意：如果你是在 Android 模擬器上測試本機後端，通常 IP 要改成 10.0.2.2
      final url = Uri.parse('http://172.20.10.2:3000/api/test-db');
      final response = await http.get(url).timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        print("🔥🔥🔥 後端連線成功！資料：${response.body}");
      } else {
        print("⚠️ 後端連線狀態碼異常：${response.statusCode}");
      }
    } catch (error) {
      print("❌ 後端連線失敗：$error");
    }
  }

  // 模擬登入成功後跳轉 (對應你原本的 router.replace('/quiz'))
  void _handleLoginSuccess() {
    // 因為我們還沒有 quiz 頁面，先跳轉到你的導覽列主畫面
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const MainNavigation()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F9FF), // 背景淺藍色
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              // 確保內容不夠長時也能置中，並且把 Footer 推到最下面
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Spacer(), // 把內容往下推一點

                        // 1. 標題區
                        const Text('Login Piggo', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF4E84A7))),
                        const SizedBox(height: 10),
                        const Text('使用以下應用程式登入/註冊並繼續', style: TextStyle(fontSize: 14, color: Color(0xFF757575))),
                        const SizedBox(height: 40),

                        // 2. 社群按鈕區
                        // 2. 社群按鈕區
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // LINE (綠)
                            _buildSocialBtn(
                              color: const Color(0xFF06C755),
                              iconWidget: const FaIcon(FontAwesomeIcons.solidComment, color: Colors.white, size: 32),
                              onTap: _handleLoginSuccess,
                            ),
                            const SizedBox(width: 25),
                            // Facebook (藍)
                            _buildSocialBtn(
                              color: const Color(0xFF4267B2),
                              iconWidget: const FaIcon(FontAwesomeIcons.facebookF, color: Colors.white, size: 32),
                              onTap: _handleLoginSuccess,
                            ),
                            const SizedBox(width: 25),
                            // Google (白)
                            _buildSocialBtn(
                              color: Colors.white,
                              iconWidget: const FaIcon(FontAwesomeIcons.google, color: Color(0xFFEA4335), size: 32),
                              onTap: _handleLoginSuccess,
                            ),
                          ],
                        ),
                        const SizedBox(height: 30),

                        // 3. 訪客按鈕
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6CA6CC),
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 40),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                            elevation: 3,
                          ),
                          onPressed: _handleLoginSuccess,
                          child: const Text('👤 訪客登入 (直接開始)', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(height: 50),

                        // 4. 小豬切換圖片
                        GestureDetector(
                          onTap: () => setState(() => _isHappyPig = !_isHappyPig),
                          child: Image.asset(
                            _isHappyPig ? 'assets/piggy/pig_login0.jpg' : 'assets/piggy/pig_login1.jpg',
                            width: 200, height: 200, fit: BoxFit.contain,
                            // 預防圖片路徑錯誤的防呆設計
                            errorBuilder: (ctx, err, stack) => Container(
                              width: 200, height: 200,
                              decoration: BoxDecoration(color: Colors.grey[300], shape: BoxShape.circle),
                              child: Icon(Icons.pets, size: 80, color: _isHappyPig ? Colors.pink[200] : Colors.grey),
                            ),
                          ),
                        ),

                        const Spacer(), // 把 Footer 擠到最下面

                        // 5. 底部條款
                        const Padding(
                          padding: EdgeInsets.only(bottom: 10),
                          child: Text('登入即代表同意使用者條款', style: TextStyle(color: Color(0xFF8BA0B2), fontSize: 12)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // 封裝社群按鈕的樣式
  Widget _buildSocialBtn({required Color color, required Widget iconWidget, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 70, height: 70,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [BoxShadow(color: Colors.black26, offset: Offset(0, 4), blurRadius: 5)],
        ),
        child: Center(child: iconWidget), // 直接放入傳進來的圖示
      ),
    );
  }
}