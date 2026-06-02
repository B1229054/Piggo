import 'package:flutter/material.dart';
import 'package:piggo/post/post_detail_screen.dart'; // 確保路徑正確以調用 PostItemWidget

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F9FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFE3F0FA),
        elevation: 0,
        // 左側按鈕
        leading: IconButton(
          icon: const Icon(Icons.add, color: Colors.black),
          onPressed: () {},
        ),
        // 中間搜尋列
        title: Container(
          height: 38,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const TextField(
            decoration: InputDecoration(
              hintText: '搜尋...',
              prefixIcon: Icon(Icons.search, color: Colors.grey, size: 20),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 10),
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.black),
            onPressed: () {},
          ),
        ],
        // 分頁切換
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.black,
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF6CA6CC),
          indicatorWeight: 3,
          tabs: const [
            Tab(text: '推 薦'),
            Tab(text: '交 流'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          RecommendationTab(),
          ExchangeTab(),
        ],
      ),
      // AI小豬懸浮按鈕
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: const Color(0xFF6CA6CC),
        shape: const CircleBorder(),
        child: const Icon(Icons.smart_toy, color: Colors.white),
      ),
    );
  }
}

// ==================== 推薦版 (使用 PostItemWidget) ====================
class RecommendationTab extends StatelessWidget {
  const RecommendationTab({super.key});

  @override
  Widget build(BuildContext context) {
    // 模擬從資料庫抓取的推薦貼文資料
    final List<Map<String, dynamic>> recommendedPosts = [
      {
        'id': 'rec_1',
        'location': '台南 , 國華街',
        'hashtags': ['#台南美食', '#甜點', '#小吃', '#食記'],
        'description': '每次來台南必吃的美食們～ ...行程細項',
        'imageUrls': [
          'assets/images/food1.png',
          'assets/images/food2.png'
        ],
      },
      {
        'id': 'rec_2',
        'location': '日本東京都',
        'hashtags': ['#東京', '#東京鐵塔'],
        'description': '兩天一夜',
        'imageUrls': [
          'https://images.unsplash.com/photo-1540959733332-eab4deabeeaf?q=80&w=600&auto=format&fit=crop'
        ],
      },
    ];

    return ListView(
      children: [
        // 推薦貼文列表
        const SizedBox(height: 10),
        ...recommendedPosts.map((data) => Column(
          children: [
            PostItemWidget(post: data),
            Divider(height: 24, thickness: 8, color: Colors.grey.withValues(alpha: 0.1)),
          ],
        )),
        const SizedBox(height: 60), // 底部留白避免被導航列遮擋
      ],
    );
  }
}

// ==================== 交流版 主列表 ====================
class ExchangeTab extends StatelessWidget {
  const ExchangeTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        ExchangePostItem(
          author: 'pigggy',
          title: '白糖粿沒開',
          time: '10 min',
          content: '國華街的林家白糖粿為甚麼沒有開呀？？剛剛查明明就寫營業中，好想吃白糖粿喔！',
          flags: 20,
          commentsCount: 2,
          aiSummary: '國華街的知名白糖粿「林家茂子白糖粿蕃薯椪」(原國華街口)，已於2024年底搬遷至台南市尊王路上繼續營業。',
          replies: [
            {'author': 'bee', 'time': '1 min', 'content': '因為搬家了！！！'},
            {'author': 'haha', 'time': '4 min', 'content': '最喜歡吃他們家的白糖粿，以前還有賣芋頭餅也很...'},
          ],
        ),
        const ExchangePostItem(
          author: 'ryan',
          title: '國華街推薦',
          time: '20 min',
          content: '誰可以告訴我台南國華街附近有什麼好吃好玩的地方',
          flags: 36,
          commentsCount: 7,
        ),
        const SizedBox(height: 60),
      ],
    );
  }
}

// ==================== 交流版 單篇貼文元件(列表用)====================
class ExchangePostItem extends StatefulWidget {
  final String author;
  final String title;
  final String time;
  final String content;
  final int flags;
  final int commentsCount;
  final String? aiSummary;
  final List<Map<String, String>>? replies; // 接收留言資料

  const ExchangePostItem({
    super.key,
    required this.author,
    required this.title,
    required this.time,
    required this.content,
    required this.flags,
    required this.commentsCount,
    this.aiSummary,
    this.replies,
  });

  @override
  State<ExchangePostItem> createState() => _ExchangePostItemState();
}

class _ExchangePostItemState extends State<ExchangePostItem> {
  bool _isLiked = false;
  bool _isSaved = false;
  late int _currentLikes;

  @override
  void initState() {
    super.initState();
    _currentLikes = widget.flags;
  }

  void _toggleLike() => setState(() {
    _isLiked = !_isLiked;
    _isLiked ? _currentLikes++ : _currentLikes--;
  });

  void _toggleSave() => setState(() => _isSaved = !_isSaved);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      // 貼文時，跳轉到詳細頁面
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ExchangePostDetailScreen(
              author: widget.author,
              title: widget.title,
              time: widget.time,
              content: widget.content,
              flags: _currentLikes,
              commentsCount: widget.commentsCount,
              aiSummary: widget.aiSummary,
              replies: widget.replies,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 頂部資訊
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    CircleAvatar(radius: 14, backgroundColor: Colors.grey[200], child: const Icon(Icons.person, size: 16, color: Colors.grey)),
                    const SizedBox(width: 8),
                    Text(widget.author, style: const TextStyle(fontWeight: FontWeight.bold)),
                    const Text('  >  ', style: TextStyle(color: Colors.grey)),
                    Text(widget.title, style: const TextStyle(fontWeight: FontWeight.w500)),
                  ],
                ),
                Text(widget.time, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 12),
            
            // 內文
            Text(widget.content, style: const TextStyle(fontSize: 15, height: 1.4)),
            const SizedBox(height: 12),
              
            // 底部互動區 
            Row(
              children: [
                GestureDetector(
                  onTap: _toggleLike,
                  child: Icon(_isLiked ? Icons.favorite : Icons.favorite_border, size: 22, color: _isLiked ? Colors.red : Colors.black87),
                ),
                const SizedBox(width: 4),
                Text('$_currentLikes', style: const TextStyle(color: Colors.black87, fontSize: 14)),
                const SizedBox(width: 16),
                
                const Icon(Icons.chat_bubble_outline, size: 20, color: Colors.black87),
                const SizedBox(width: 4),
                Text('${widget.commentsCount}', style: const TextStyle(color: Colors.black87, fontSize: 14)),
                const SizedBox(width: 16),
                
                GestureDetector(
                  onTap: _toggleSave,
                  child: Icon(_isSaved ? Icons.bookmark : Icons.bookmark_border, size: 22, color: Colors.black87),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== 交流版 詳細留言頁面 (新頁面) ====================
class ExchangePostDetailScreen extends StatelessWidget {
  final String author;
  final String title;
  final String time;
  final String content;
  final int flags;
  final int commentsCount;
  final String? aiSummary;
  final List<Map<String, String>>? replies;

  const ExchangePostDetailScreen({
    super.key,
    required this.author,
    required this.title,
    required this.time,
    required this.content,
    required this.flags,
    required this.commentsCount,
    this.aiSummary,
    this.replies,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F9FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFE3F0FA),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 1. 貼文主體
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(radius: 14, backgroundColor: Colors.grey[200], child: const Icon(Icons.person, size: 16, color: Colors.grey)),
                          const SizedBox(width: 8),
                          Text(author, style: const TextStyle(fontWeight: FontWeight.bold)),
                          const Text('  >  ', style: TextStyle(color: Colors.grey)),
                          Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
                        ],
                      ),
                      Text(time, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(content, style: const TextStyle(fontSize: 15, height: 1.4)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.favorite_border, size: 22, color: Colors.black87),
                      const SizedBox(width: 4),
                      Text('$flags', style: const TextStyle(color: Colors.black87, fontSize: 14)),
                      const SizedBox(width: 16),
                      const Icon(Icons.chat_bubble_outline, size: 20, color: Colors.black87),
                      const SizedBox(width: 4),
                      Text('$commentsCount', style: const TextStyle(color: Colors.black87, fontSize: 14)),
                      const SizedBox(width: 16),
                      const Icon(Icons.bookmark_border, size: 22, color: Colors.black87),
                    ],
                  ),
                ],
              ),
            ),
            
            // 貼文跟留言區之間的分隔底色
            const Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)),

            // 2. 排序與AI摘要區塊
            Container(
              color: const Color(0xFFF8F9FA),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 排序下拉選單模擬
                  Row(
                    children: [
                      const Icon(Icons.workspace_premium, color: Colors.amber, size: 20),
                      const SizedBox(width: 4),
                      const Icon(Icons.keyboard_arrow_down, color: Colors.grey, size: 18),
                      const SizedBox(width: 8),
                      Text('最優解/由近到遠/由遠到近', style: TextStyle(color: Colors.grey[700], fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // AI摘要
                  if (aiSummary != null)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEBF1F5), 
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              CircleAvatar(
                                radius: 14, backgroundColor: Color(0xFF6CA6CC),
                                child: Icon(Icons.smart_toy, color: Colors.white, size: 14),
                              ),
                              SizedBox(width: 10),
                              Text('AI 摘要', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(aiSummary!, style: const TextStyle(fontSize: 14, height: 1.5, color: Colors.black87)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            
            // 3. 網友留言列表
            if (replies != null)
              Container(
                color: const Color(0xFFF8F9FA),
                padding: const EdgeInsets.only(bottom: 40),
                child: Column(
                  children: replies!.map((reply) => _buildReplyItem(reply)).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // 單則留言的UI
  Widget _buildReplyItem(Map<String, String> reply) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFEEEEEE))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18, backgroundColor: Colors.white,
            child: Icon(Icons.pets, color: Colors.grey[800], size: 20), // 模擬頭貼
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(reply['author']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    Text(reply['time']!, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 6),
                Text(reply['content']!, style: const TextStyle(fontSize: 14, height: 1.4, color: Colors.black87)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
