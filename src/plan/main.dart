import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// 引入你的 Provider 與首頁檔案
import 'plan_provider.dart';
import 'main_navigation.dart'; // 假設你的首頁叫做 MainNavigation，如果檔名不同請自行修改

void main() {
  // 把 MultiProvider 包在最外層，這樣整個 App 都能共用 PlanProvider 的資料
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PlanProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Piggo Travel',
      debugShowCheckedModeBanner: false, // 隱藏右上角的 DEBUG 標籤
      
      // ==========================================
      // 🎨 全域主題設定：統治整個 App 的藍色風格
      // ==========================================
      theme: ThemeData(
        // 1. App 背景底色 (質感淺灰白，讓白色的卡片可以凸顯出來)
        scaffoldBackgroundColor: const Color(0xFFF8F9FA), 
        
        // 2. 主色調 (Piggo 專屬天空藍)
        primaryColor: const Color(0xFF6CA6CC),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6CA6CC),
          primary: const Color(0xFF6CA6CC),
        ),

        // 3. 統一 AppBar (頂部標題列) 的風格：透明背景、黑字、無陰影
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          iconTheme: IconThemeData(color: Colors.black87),
          titleTextStyle: TextStyle(
            color: Colors.black87, 
            fontSize: 18, 
            fontWeight: FontWeight.bold,
          ),
        ),

        // 4. 統一所有 ElevatedButton (主要確認按鈕) 的風格：藍底白字、大圓角
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6CA6CC),
            foregroundColor: Colors.white, // 文字顏色
            elevation: 0, // 取消預設的厚重陰影感，讓畫面更現代
            padding: const EdgeInsets.symmetric(vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16), // 統一圓角大小
            ),
            textStyle: const TextStyle(
              fontSize: 16, 
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        // 5. 統一 TextField (輸入框與搜尋框) 的風格：白底、無邊框、圓角
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
        ),
      ),
      
      // 設定 App 啟動後的第一個畫面
      home: const MainNavigation(), 
    );
  }
}