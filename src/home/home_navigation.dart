import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'package:piggo/home/profile.dart';
import 'package:piggo/home/community_screen.dart';
import 'home_screen.dart';

class HomeNavigation extends StatefulWidget {
  const HomeNavigation({super.key});

  @override
  State<HomeNavigation> createState() => _HomeNavigationState();
}

class _HomeNavigationState extends State<HomeNavigation> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const HomeScreen(),
    const CommunityScreen(),
    const Center(child: Text('核心計畫頁 (開發中)')),
    const Center(child: Text('計畫表 (開發中)')),
    const ProfileScreen(), 
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        height: 90, 
        decoration: const BoxDecoration(
          color: Color(0xFFF2F9FF),
          border: Border(top: BorderSide.none),
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: const Color(0xFF6CA6CC),
          unselectedItemColor: Colors.grey,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          items: [
            const BottomNavigationBarItem(icon: FaIcon(FontAwesomeIcons.house, size: 20), label: '首頁'),
            const BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), label: '交流'),
            // 中間的大圓鈕
            BottomNavigationBarItem(
              icon: Container(
                width: 50, height: 50,
                decoration: const BoxDecoration(color: Color(0xFF6CA6CC), shape: BoxShape.circle),
                child: const Icon(Icons.add, color: Colors.white),
              ),
              label: '',
            ),
            const BottomNavigationBarItem(icon: Icon(Icons.menu_book), label: '計畫'),
            const BottomNavigationBarItem(icon: FaIcon(FontAwesomeIcons.user, size: 20), label: '我的'),
          ],
        ),
      ),
    );
  }
}
