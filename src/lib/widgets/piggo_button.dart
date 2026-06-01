import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class PiggoButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final Color? backgroundColor; 
  final Color? textColor;       

  const PiggoButton({
    super.key, 
    required this.text, 
    required this.onPressed,
    this.backgroundColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    // 取得這顆按鈕當下的背景色，用來做相近色的陰影
    final btnColor = backgroundColor ?? PiggoTheme.primaryBlue;

    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: btnColor, 
        foregroundColor: textColor ?? Colors.white, 
        
        // 🌟 關鍵修改：把陰影加回來了！
        elevation: 6, // 數字越大，按鈕看起來浮得越高、陰影範圍越廣
        
        // 🎨 高級感小秘訣：讓陰影帶有一點點按鈕本身的顏色，並降低透明度
        shadowColor: btnColor.withOpacity(0.4), 
        
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30), 
        ),
      ),
      onPressed: onPressed,
      child: Text(
        text,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }
}