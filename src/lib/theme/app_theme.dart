import 'package:flutter/material.dart';

class PiggoTheme {
  static const primaryBlue = Color(0xFF6592B5); // 主色：用於「開始導航」、「集合!」等按鈕
  static const lightBackground = Color(0xFFDDEAF3); // 淺景：用於登入頁、底部導覽列背景
  static const surfaceWhite = Colors.white; // 區塊背景：用於輸入框、卡片

  static const textDark = Color(0xFF333333); // 主要文字顏色

  // 統一的文字樣式
  static const headingStyle = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: textDark,
  );

  static const bodyStyle = TextStyle(fontSize: 16, color: textDark);
}
