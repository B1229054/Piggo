import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 外層用StatefulWidget來控制一進畫面的自動滑動
class PostDetailScreen extends StatefulWidget {
  final List<dynamic> posts;
  final int initialIndex;

  const PostDetailScreen({super.key, required this.posts, required this.initialIndex});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  late List<GlobalKey> _keys;

  @override
  void initState() {
    super.initState();
    // 幫每一篇貼文準備一個「定位鑰匙」
    _keys = List.generate(widget.posts.length, (index) => GlobalKey());
    
    // 等待畫面剛畫好的瞬間，自動順滑地滾動到點擊的那篇貼文
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_keys[widget.initialIndex].currentContext != null) {
        Scrollable.ensureVisible(
          _keys[widget.initialIndex].currentContext!,
          alignment: 0.0, 
          duration: const Duration(milliseconds: 300), // 順滑滾動的動畫時間
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      // 最外層有一個固定的AppBar，不會跟著貼文滑動
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('貼文', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      // 使用ListView取代PageView，達成順順滑動的效果
      body: ListView(
        children: widget.posts.asMap().entries.map((entry) {
          return Container(
            key: _keys[entry.key], // 綁定鑰匙用來定位
            child: Column(
              children: [
                PostItemWidget(post: entry.value),
                // 貼文跟貼文之間的分隔線 (淡淡的灰色區塊)
                Divider(height: 20, thickness: 8, color: Colors.grey[100]), 
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// 內層：單篇貼文的詳細內容與狀態管理
class PostItemWidget extends StatefulWidget {
  final Map<String, dynamic> post; 
  const PostItemWidget({super.key, required this.post});

  @override
  State<PostItemWidget> createState() => _PostItemWidgetState();
}

class _PostItemWidgetState extends State<PostItemWidget> {
  bool _isLiked = false;
  bool _isSaved = false;
  final List<String> _comments = []; 
  final TextEditingController _commentController = TextEditingController();
  int _currentPage = 0; 

  void _toggleLike() => setState(() => _isLiked = !_isLiked);
  void _toggleSave() => setState(() => _isSaved = !_isSaved);

  Future<void> _confirmDelete() async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('刪除貼文', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('確定要刪除這篇貼文嗎？刪除後將無法恢復。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消', style: TextStyle(color: Colors.grey))),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx); 
              final prefs = await SharedPreferences.getInstance();
              final String? postsJson = prefs.getString('my-posts');
              if (postsJson != null) {
                List<dynamic> posts = jsonDecode(postsJson);
                posts.removeWhere((p) => p['id'] == widget.post['id']);
                await prefs.setString('my-posts', jsonEncode(posts));
              }
              if (!mounted) return; 
              Navigator.pop(context, true); 
            },
            child: const Text('刪除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditDialog() async {
    TextEditingController editController = TextEditingController(text: widget.post['description']);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('修改說明文字'),
        content: TextField(
          controller: editController,
          maxLines: 3,
          decoration: const InputDecoration(border: OutlineInputBorder(), hintText: '輸入新的說明文字...'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消', style: TextStyle(color: Colors.grey))),
          TextButton(
            onPressed: () async {
              final newDescription = editController.text;
              Navigator.pop(ctx);
              final prefs = await SharedPreferences.getInstance();
              final String? postsJson = prefs.getString('my-posts');
              if (postsJson != null) {
                List<dynamic> posts = jsonDecode(postsJson);
                int index = posts.indexWhere((p) => p['id'] == widget.post['id']);
                if (index != -1) {
                  posts[index]['description'] = newDescription;
                  await prefs.setString('my-posts', jsonEncode(posts));
                  if (!mounted) return;
                  setState(() {
                    widget.post['description'] = newDescription; 
                  });
                }
              }
            },
            child: const Text('儲存', style: TextStyle(color: Color(0xFF007AFF))),
          ),
        ],
      ),
    );
  }

  void _showCommentSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, 
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.6,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 20, right: 20, top: 15,
              ),
              child: Column(
                children: [
                  Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
                  const SizedBox(height: 15),
                  const Text('留言', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const Divider(),
                  Expanded(
                    child: _comments.isEmpty
                        ? const Center(child: Text('目前還沒有留言喔！', style: TextStyle(color: Colors.grey)))
                        : ListView.builder(
                            itemCount: _comments.length,
                            itemBuilder: (context, index) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const CircleAvatar(
                                      radius: 16,
                                      backgroundImage: AssetImage('assets/piggy/pig_login0.png'),
                                      backgroundColor: Color(0xFFF2F9FF),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text('Piggy', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                          const SizedBox(height: 2),
                                          Text(_comments[index], style: const TextStyle(fontSize: 14)),
                                        ],
                                      ),
                                    )
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _commentController,
                            decoration: InputDecoration(
                              hintText: '新增留言...',
                              filled: true,
                              fillColor: Colors.grey[100],
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        IconButton(
                          icon: const Icon(Icons.send, color: Color(0xFF007AFF)),
                          onPressed: () {
                            if (_commentController.text.isNotEmpty) {
                              setModalState(() => _comments.add(_commentController.text));
                              _commentController.clear();
                            }
                          },
                        )
                      ],
                    ),
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final location = widget.post['location'] ?? '未知地點';
    final List<dynamic> hashtags = widget.post['hashtags'] ?? [];
    final description = widget.post['description'] ?? '';
    final List<dynamic> imageUrls = widget.post['imageUrls'] ?? 
        (widget.post['imageUrl'] != null ? [widget.post['imageUrl']] : []);

    // 內層不再使用Scaffold，直接回傳Column組合內容
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 地點列 + 移到最右邊的三個點點選單
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
          child: Row(
            children: [
              Icon(Icons.location_on, color: Colors.grey[700], size: 20),
              const SizedBox(width: 5),
              // 使用Expanded把地點文字撐開，把點點選單放到畫面最右邊
              Expanded(
                child: Text(location, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_horiz, color: Colors.black),
                onSelected: (value) {
                  if (value == 'edit') _showEditDialog();
                  if (value == 'delete') _confirmDelete();
                },
                itemBuilder: (BuildContext context) => [
                  const PopupMenuItem(value: 'edit', child: Text('修改說明文字')),
                  const PopupMenuItem(value: 'delete', child: Text('刪除貼文', style: TextStyle(color: Colors.red))),
                ],
              ),
            ],
          ),
        ),
        
        // Hashtags
        if (hashtags.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 15, right: 15, bottom: 10),
            child: Text(hashtags.join('  '), style: const TextStyle(color: Colors.black87, fontSize: 13)),
          ),
        
        // 圖片區塊
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            AspectRatio(
              aspectRatio: 1.0, 
              child: PageView.builder(
                itemCount: imageUrls.length,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemBuilder: (context, index) {
                  String imgPath = imageUrls[index];
                  
                  // 判斷圖片路徑的來源，決定使用哪種方式載入
                  if (imgPath.startsWith('http')) {
                    // 1. 如果是http開頭，載入網路圖片 (未來接上資料庫時)
                    return Image.network(imgPath, fit: BoxFit.cover);
                  } else if (imgPath.startsWith('assets/')) {
                    // 2. 如果是assets開頭，載入APP內建圖片
                    return Image.asset(imgPath, fit: BoxFit.cover);
                  } else {
                    // 3. 其他狀況，載入本機手機裡的檔案 (剛發佈的貼文)
                    return Image.file(File(imgPath), fit: BoxFit.cover);
                  }
                },
              ),
            ),
            if (imageUrls.length > 1)
              Container(
                margin: const EdgeInsets.all(10),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('${_currentPage + 1} / ${imageUrls.length}', 
                  style: const TextStyle(color: Colors.white, fontSize: 12)),
              ),
          ],
        ),

        // 4. 互動按鈕列
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
          child: Row(
            children: [
              IconButton(
                icon: Icon(_isLiked ? Icons.favorite : Icons.favorite_border, 
                           color: _isLiked ? Colors.red : Colors.black, size: 28),
                onPressed: _toggleLike,
              ),
              IconButton(
                icon: const Icon(Icons.chat_bubble_outline, color: Colors.black, size: 26),
                onPressed: _showCommentSheet,
              ),
              IconButton(
                icon: Icon(_isSaved ? Icons.bookmark : Icons.bookmark_border, 
                           color: _isSaved ? Colors.black : Colors.black, size: 28),
                onPressed: _toggleSave,
              ),
              
              const Spacer(),
              
              if (imageUrls.length > 1)
                Row(
                  children: List.generate(imageUrls.length, (index) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: _currentPage == index ? 6 : 5,
                    height: _currentPage == index ? 6 : 5,
                    decoration: BoxDecoration(
                      color: _currentPage == index ? Colors.black : Colors.grey[400],
                      shape: BoxShape.circle,
                    ),
                  )),
                ),
                
              const Spacer(),
              const SizedBox(width: 140), 
            ],
          ),
        ),

        // 5. 內文
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CircleAvatar(
                radius: 16,
                backgroundImage: AssetImage('assets/piggy/pig_login0.png'),
                backgroundColor: Color(0xFFF2F9FF),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(color: Colors.black, fontSize: 15, height: 1.4),
                    children: [
                      const TextSpan(text: 'Piggy  ', style: TextStyle(fontWeight: FontWeight.bold)),
                      TextSpan(text: description),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 15),
      ],
    );
  }
}
