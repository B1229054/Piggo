import 'package:flutter/material.dart';
import 'plan_list_screen.dart';
import 'new_plan_screen.dart'; 

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  // 目前選中的分頁 index
  int _currentIndex = 2; // 預設停在「計畫」頁 (對應原本的導覽列位置)

  // 定義分頁列表
  final List<Widget> _pages = [
    const Center(child: Text('首頁開發中...')), // Index 0: 首頁
    const Center(child: Text('交流區開發中...')), // Index 1: 交流
    const PlanListScreen(),                 // Index 2: 計畫 (我們寫好的那一頁)
    const Center(child: Text('帳號設定開發中...')), // Index 3: 帳號
  ];
  void _handleConfirmDialog() {
    print('確認按鈕被按下了');
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 🌟 IndexedStack 可以保持每個分頁的狀態，切換時不會重跑 initState
      body: IndexedStack(
        index: _currentIndex == 4 ? 2 : (_currentIndex > 2 ? _currentIndex - 1 : _currentIndex),
        // 修正：因為中間有個「+」，所以我們要處理 index 的位移
        children: const [
          Center(child: Text('首頁')),
          Center(child: Text('交流')),
          PlanListScreen(),
          Center(child: Text('帳號')),
        ],
      ),

      // 🌟 中間那個藍色的「＋」按鈕
      floatingActionButton: Container(
        height: 65, width: 65,
        padding: const EdgeInsets.all(4),
        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle), // 白色外圈
        child: FloatingActionButton(
          elevation: 0,
          backgroundColor: const Color(0xFF89C4E6), // PIGGO 藍色
          shape: const CircleBorder(),
          onPressed: () {
             Navigator.push(context, MaterialPageRoute(builder: (_) => const NewPlanScreen(), fullscreenDialog: true));
          },
          child: const Icon(Icons.add, color: Colors.white, size: 30),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked, // 讓按鈕停在中間

      // 🌟 底部導覽列
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(), // 讓中間凹一個洞給「+」按鈕
        notchMargin: 8.0,
        color: Colors.white,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildTabItem(index: 0, icon: Icons.home, label: '首頁'),
              _buildTabItem(index: 1, icon: Icons.chat_bubble_outline, label: '交流'),
              
              const SizedBox(width: 40), 
              
              _buildTabItem(index: 2, icon: Icons.calendar_today, label: '計畫'),
              _buildTabItem(index: 3, icon: Icons.person_outline, label: '帳號'),
            ],
          ),
        ),
      ),
    );
  }

  // 自訂 Tab 按鈕小組件
  Widget _buildTabItem({required int index, required IconData icon, required String label}) {
    bool isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: isSelected ? const Color(0xFF6CA6CC) : Colors.grey, size: 24),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isSelected ? const Color(0xFF6CA6CC) : Colors.grey,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}