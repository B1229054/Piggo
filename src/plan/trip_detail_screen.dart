import 'package:flutter/material.dart';

class TripDetailScreen extends StatefulWidget {
  const TripDetailScreen({super.key});

  @override
  State<TripDetailScreen> createState() => _TripDetailScreenState();
}

class _TripDetailScreenState extends State<TripDetailScreen> {
  // 1. 小豬跟行李的邏輯
  final int totalItems = 20;
  int packedItems = 8;

  // 2. 這是彈出來的視窗 (Modal)
  void _showLuggageModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // 允許我們自訂高度
      backgroundColor: Colors.transparent, // 讓外層透明，才能顯示裡面的圓角
      builder: (BuildContext context) {
        // 🔥 加入 StatefulBuilder，讓 Modal 裡面的狀態可以獨立更新
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            
            // 計算進度
            double progressRatio = packedItems / totalItems;
            String pigImagePath = progressRatio >= 0.5 
                ? 'assets/piggy/pig_login1.png' 
                : 'assets/piggy/pig_login0.png';

            return Container(
              height: MediaQuery.of(context).size.height * 0.75, // 視窗佔據螢幕下方 75%
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  
                  // 右上角的關閉按鈕
                  Align(
                    alignment: Alignment.topRight,
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context), // 點擊關閉視窗
                      child: const Padding(
                        padding: EdgeInsets.all(10.0),
                        child: Text('✖', style: TextStyle(fontSize: 24, color: Color(0xFF333333))),
                      ),
                    ),
                  ),

                  // 小豬圖片
                  Image.asset(
                    pigImagePath,
                    width: 180,
                    height: 180,
                    fit: BoxFit.contain,
                  ),

                  // 進度文字
                  const Text('行李打包進度', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 5),
                  Text(
                    '已準備 $packedItems / $totalItems 項 (${(progressRatio * 100).round()}%)',
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 20),

                  // 模擬打勾的測試按鈕
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3498db),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      minimumSize: const Size(250, 50), // 類似 RN 的 width: '80%'
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () {
                      // 🔥 用 setModalState 來更新視窗內的數字
                      setModalState(() {
                        if (packedItems < totalItems) {
                          packedItems++;
                        }
                      });
                      // 也同步更新底層畫面的狀態
                      setState(() {}); 
                    },
                    child: const Text(
                      '模擬收好一件行李 (+1)', 
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)
                    ),
                  ),

                ],
              ),
            );
          }
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5), // 底層畫面背景色
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ＝＝＝ 這裡是你原本的底層畫面 ＝＝＝
              const Text('台南三天兩夜', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              const Text(
                '這裡放你原本的行程表、地圖、景點資訊...', 
                style: TextStyle(fontSize: 16, color: Color(0xFF666666))
              ),
              const SizedBox(height: 30),

              // 觸發彈出視窗的按鈕
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF9800),
                  padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 30),
                  elevation: 3,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                ),
                onPressed: _showLuggageModal, // 點擊呼叫彈出視窗的函式
                child: const Text(
                  '🎒 點我檢查行李清單', 
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)
                ),
              ),
              // ＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝
            ],
          ),
        ),
      ),
    );
  }
}