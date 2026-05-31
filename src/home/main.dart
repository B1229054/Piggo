import 'package:flutter/material.dart';
import 'home_screen.dart'; // 引入主畫面

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Piggo App',
      theme: ThemeData(
        primaryColor: const Color(0xFF6292B4),
        scaffoldBackgroundColor: Colors.white,
      ),
      debugShowCheckedModeBanner: false, // 關閉右上角的Debug標籤
      home: const HomeScreen(), // 將首頁指向HomeScreen
    );
  }
}
