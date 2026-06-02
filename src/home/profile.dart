import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
// 👉 確保有正確引入貼文詳細頁
import 'package:piggo/post/post_detail_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _username = 'Piggy';
  String? _avatarPath;
  List<dynamic> _myPosts = [];
  int _tabIndex = 0; // 0 代表貼文, 1 代表收藏

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final String? postsJson = prefs.getString('my-posts');
    setState(() {
      _username = prefs.getString('user-name') ?? 'Piggy';
      _avatarPath = prefs.getString('user-avatar');
      if (postsJson != null) {
        _myPosts = jsonDecode(postsJson);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(_username, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 20)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_box_outlined, color: Colors.black),
            onPressed: () async {
              await Navigator.pushNamed(context, '/new_post');
              _loadUserData();
            },
          ),
          IconButton(
            icon: const Icon(Icons.more_horiz, color: Colors.black),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadUserData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              _buildHeader(),
              _buildTabBar(),
              _tabIndex == 0 ? _buildGrid() : _buildSavedGrid(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: const Color(0xFFF2F9FF),
            backgroundImage: _avatarPath != null 
              ? FileImage(File(_avatarPath!)) 
              : const AssetImage('assets/piggy/pig_login0.png') as ImageProvider,
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatItem(_myPosts.length.toString(), '貼文'),
                _buildStatItem('250', '粉絲'),
                _buildStatItem('150', '追蹤'),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildStatItem(String count, String label) {
    return Column(
      children: [
        Text(count, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.black87, fontSize: 14)),
      ],
    );
  }

  Widget _buildTabBar() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: IconButton(
                icon: Icon(Icons.grid_view, color: _tabIndex == 0 ? const Color(0xFF6CA6CC) : Colors.grey),
                onPressed: () => setState(() => _tabIndex = 0),
              ),
            ),
            Expanded(
              child: IconButton(
                icon: Icon(Icons.bookmark_border, color: _tabIndex == 1 ? const Color(0xFF6CA6CC) : Colors.grey),
                onPressed: () => setState(() => _tabIndex = 1),
              ),
            ),
          ],
        ),
        Stack(
          children: [
            const Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 200),
              left: _tabIndex == 0 ? 0 : MediaQuery.of(context).size.width / 2,
              child: Container(
                width: MediaQuery.of(context).size.width / 2,
                height: 1,
                color: const Color(0xFF6CA6CC),
              ),
            )
          ],
        )
      ],
    );
  }

  Widget _buildGrid() {
    if (_myPosts.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(top: 50),
        child: Text('還沒有發布任何貼文哦！', style: TextStyle(color: Colors.grey)),
      );
    }
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _myPosts.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, crossAxisSpacing: 2, mainAxisSpacing: 2,
      ),
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () async {
            // 👉 點擊時傳送所有貼文與初始位置
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PostDetailScreen(posts: _myPosts, initialIndex: index),
              ),
            );
            _loadUserData(); // 若刪除貼文，返回時會自動刷新畫面
          },
          child: Image.file(
            File(_myPosts[index]['imageUrls'] != null 
                ? _myPosts[index]['imageUrls'][0] 
                : _myPosts[index]['imageUrl']),
            fit: BoxFit.cover,
          ),
        );
      },
    );
  }

  Widget _buildSavedGrid() {
    return const Padding(
      padding: EdgeInsets.only(top: 50),
      child: Text('尚未收藏任何貼文', style: TextStyle(color: Colors.grey)),
    );
  }
}