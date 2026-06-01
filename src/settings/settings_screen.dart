import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> menuItems = [
      {'title': '管理帳號', 'icon': Icons.person_outline, 'route': '/account'},
      {'title': '隱私設定', 'icon': Icons.lock_outline, 'route': '/privacy'},
      {'title': '語言設定', 'icon': Icons.language_outlined, 'route': '/language'},
      {'title': '分享QRcode', 'icon': Icons.qr_code_scanner, 'route': '/qrcode'},
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF2F9FF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('設定', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                Expanded(
                  child: ListView.separated(
                    itemCount: menuItems.length,
                    separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFEEEEEE)),
                    itemBuilder: (context, index) {
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(vertical: 8),
                        leading: Icon(menuItems[index]['icon'], color: const Color(0xFF8BA0B2), size: 28),
                        title: Text(menuItems[index]['title'], style: const TextStyle(fontSize: 16, color: Color(0xFF666666))),
                        trailing: const Icon(Icons.chevron_right, color: Color(0xFFCCCCCC)),
                        onTap: () => Navigator.pushNamed(context, menuItems[index]['route']),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 100),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _showLogoutDialog(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF007AFF),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('登出', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            right: 20,
            bottom: 30,
            child: FloatingActionButton(
              onPressed: () {},
              backgroundColor: const Color(0xFF6CA6CC),
              child: Image.asset('assets/piggy/pig_login0.png', width: 30),
            ),
          )
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('登出'),
        content: const Text('確定要登出 Piggo 嗎？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          TextButton(
            onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false),
            child: const Text('確定登出', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}