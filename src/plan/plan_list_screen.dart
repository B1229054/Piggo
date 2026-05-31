import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'plan_provider.dart';
import 'itinerary_screen.dart';
import 'group_chat_screen.dart';
import 'new_plan_screen.dart'; // 🌟 引入新增/編輯計畫頁面

class PlanListScreen extends StatefulWidget {
  const PlanListScreen({super.key});

  @override
  State<PlanListScreen> createState() => _PlanListScreenState();
}

class _PlanListScreenState extends State<PlanListScreen> {
  String _currentSort = 'edit_desc'; // 目前的排序狀態

  // ==========================================
  // 1. 首頁的排序選單
  // ==========================================
  void _showSortMenu() {
    String tempSort = _currentSort;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: const EdgeInsets.all(25),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(5))),
                  const SizedBox(height: 20),
                  const Text('排序', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  
                  _buildSortOption('上次編輯時間', 'edit_desc', tempSort, () => setState(() => tempSort = 'edit_desc')),
                  _buildSortOption('建立時間（由近到遠）', 'create_desc', tempSort, () => setState(() => tempSort = 'create_desc')),
                  _buildSortOption('建立時間（由遠到近）', 'create_asc', tempSort, () => setState(() => tempSort = 'create_asc')),
                  
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6CA6CC), 
                        padding: const EdgeInsets.symmetric(vertical: 15), 
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))
                      ),
                      onPressed: () {
                        this.setState(() => _currentSort = tempSort);
                        Navigator.pop(ctx);
                        // TODO: 未來接後端時可以在這裡呼叫排序邏輯
                      },
                      child: const Text('確認', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  )
                ],
              ),
            );
          }
        );
      },
    );
  }

  Widget _buildSortOption(String text, String value, String currentValue, VoidCallback onTap) {
    bool isSelected = currentValue == value;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFCAE2F2) : Colors.transparent, 
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.black87, width: 1), 
        ),
        child: Center(child: Text(text, style: const TextStyle(fontSize: 16, color: Colors.black87))),
      ),
    );
  }

  // ==========================================
  // 2. 卡片右下角的動作選單 (...) 
  // ==========================================
  void _showActionMenu(Map<String, dynamic> plan) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 50, height: 6, margin: const EdgeInsets.only(top: 15, bottom: 10), decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(5))),
              
              ListTile(title: const Center(child: Text('分享行程至推薦版', style: TextStyle(fontSize: 16))), onTap: () => Navigator.pop(ctx)),
              const Divider(height: 1, color: Colors.black12),
              
              // 🌟 行程設定 (跳轉到 NewPlanScreen 並帶入資料)
              ListTile(
                title: const Center(child: Text('行程設定', style: TextStyle(fontSize: 16))),
                onTap: () {
                  Navigator.pop(ctx); // 先關掉選單
                  Navigator.push(context, MaterialPageRoute(builder: (_) => NewPlanScreen(plan: plan))); // 帶入舊資料
                },
              ),
              const Divider(height: 1, color: Colors.black12),
              
              // 🌟 複製行程 (複製一份新的到保險箱)
              ListTile(
                title: const Center(child: Text('複製行程', style: TextStyle(fontSize: 16))),
                onTap: () {
                  Navigator.pop(ctx); 
                  Map<String, dynamic> newPlan = Map<String, dynamic>.from(plan); 
                  newPlan['id'] = DateTime.now().millisecondsSinceEpoch.toString(); 
                  newPlan['title'] = '${plan['title']} (複製)'; 
                  Provider.of<PlanProvider>(context, listen: false).addPlan(newPlan); 
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已成功複製行程！')));
                },
              ),
              const Divider(height: 1, color: Colors.black12),
              
              // 🌟 刪除行程
              ListTile(
                title: const Center(child: Text('刪除行程', style: TextStyle(color: Colors.red, fontSize: 16))),
                onTap: () {
                  Navigator.pop(ctx); 
                  _showDeleteConfirm(plan['id'], plan['title']); 
                },
              ),
              
              Container(height: 8, color: Colors.grey[100]), 
              ListTile(title: const Center(child: Text('取消', style: TextStyle(fontSize: 16, color: Colors.black54))), onTap: () => Navigator.pop(ctx)),
            ],
          ),
        );
      },
    );
  }

  // 刪除確認視窗
  void _showDeleteConfirm(String planId, String planTitle) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('刪除確認', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('確定要刪除「$planTitle」嗎？\n刪除後將無法恢復。', textAlign: TextAlign.center),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
            onPressed: () {
              Provider.of<PlanProvider>(context, listen: false).deletePlan(planId); 
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已刪除行程')));
            },
            child: const Text('確定刪除', style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  // ==========================================
  // 3. 產生邀請 QR Code
  // ==========================================
  void _showQRCodeDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('邀請加入計畫', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('請朋友掃描下方 QR Code', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 20),
            Container(
              width: 150, height: 150,
              decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.black12), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.qr_code_2, size: 100, color: Colors.black87),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6CA6CC), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
              onPressed: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已複製邀請連結！')));
              },
              icon: const Icon(Icons.link, color: Colors.white, size: 18),
              label: const Text('複製連結', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 監聽 Provider 裡面的計畫資料
    final plans = context.watch<PlanProvider>().plans;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F9FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF2F9FF),
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text('我的計畫', style: TextStyle(color: Colors.black, fontSize: 24, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(icon: const Icon(Icons.sort, color: Colors.black87), onPressed: _showSortMenu),
          const SizedBox(width: 10),
        ],
      ),
      body: plans.isEmpty
          ? const Center(child: Text('目前還沒有行程，按下方＋新增吧！', style: TextStyle(color: Colors.grey, fontSize: 16)))
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: plans.length,
              itemBuilder: (context, index) {
                final plan = plans[index];
                
                return GestureDetector(
                  onTap: () {
                    // 點擊卡片跳轉到行程表 (ItineraryScreen)
                    Navigator.push(context, MaterialPageRoute(builder: (_) => ItineraryScreen(planId: plan['id'], title: plan['title'])));
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 上半部：封面圖片
                        Container(
                          height: 120,
                          width: double.infinity,
                          decoration: const BoxDecoration(
                            color: Color(0xFFCAE2F2),
                            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                          ),
                          child: const Icon(Icons.image, size: 50, color: Colors.white),
                        ),
                        // 下半部：文字資訊與按鈕
                        Padding(
                          padding: const EdgeInsets.all(15),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(plan['title'] ?? '未命名計畫', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 5),
                                    Text(plan['date'] ?? '', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                  ],
                                ),
                              ),
                              // 🌟 右下角的三顆按鈕
                              Row(
                                children: [
                                  _buildCircleBtn(Icons.chat_bubble_outline, () {
                                    Navigator.push(context, MaterialPageRoute(builder: (_) => GroupChatScreen(planId: plan['id'])));
                                  }),
                                  const SizedBox(width: 8),
                                  _buildCircleBtn(Icons.person_add_alt_1, _showQRCodeDialog),
                                  const SizedBox(width: 8),
                                  _buildCircleBtn(Icons.more_horiz, () => _showActionMenu(plan)),
                                ],
                              )
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  // 封裝右下角的灰色圓形按鈕
  Widget _buildCircleBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: Colors.grey[200], shape: BoxShape.circle),
        child: Icon(icon, size: 20, color: Colors.black54),
      ),
    );
  }
}