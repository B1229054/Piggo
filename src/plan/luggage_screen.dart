import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

// 定義資料模型
class PersonalItem {
  String id;
  String name;
  bool checked;
  PersonalItem({required this.id, required this.name, required this.checked});
  
  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'checked': checked};
  factory PersonalItem.fromJson(Map<String, dynamic> json) => 
    PersonalItem(id: json['id'], name: json['name'], checked: json['checked']);
}

class SharedItem {
  String id;
  String name;
  String? assignee;
  bool isSuggested;
  String? reason;

  SharedItem({required this.id, required this.name, this.assignee, required this.isSuggested, this.reason});

  Map<String, dynamic> toJson() => {
    'id': id, 'name': name, 'assignee': assignee, 'isSuggested': isSuggested, 'reason': reason
  };
  factory SharedItem.fromJson(Map<String, dynamic> json) => SharedItem(
    id: json['id'], name: json['name'], assignee: json['assignee'], 
    isSuggested: json['isSuggested'] ?? false, reason: json['reason']
  );
}

class LuggageScreen extends StatefulWidget {
  final String planId;
  const LuggageScreen({super.key, required this.planId});

  @override
  State<LuggageScreen> createState() => _LuggageScreenState();
}

class _LuggageScreenState extends State<LuggageScreen> {
  String _activeTab = 'personal';
  final TextEditingController _newItemCtrl = TextEditingController();
  
  List<PersonalItem> _personalItems = [];
  List<SharedItem> _sharedItems = [];

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPersonal = prefs.getString('personalItems_${widget.planId}');
    final savedShared = prefs.getString('sharedItems_${widget.planId}');

    setState(() {
      if (savedPersonal != null) {
        final List decoded = json.decode(savedPersonal);
        _personalItems = decoded.map((e) => PersonalItem.fromJson(e)).toList();
      }
      if (savedShared != null) {
        final List decoded = json.decode(savedShared);
        _sharedItems = decoded.map((e) => SharedItem.fromJson(e)).toList();
      }
    });
  }

  Future<void> _savePersonal() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('personalItems_${widget.planId}', json.encode(_personalItems.map((e) => e.toJson()).toList()));
  }

  Future<void> _saveShared() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('sharedItems_${widget.planId}', json.encode(_sharedItems.map((e) => e.toJson()).toList()));
  }

  // 🔥 幫你寫好的「一鍵灌入測試資料」功能
  void _injectTestData() {
    setState(() {
      _personalItems = [
        PersonalItem(id: 'p1', name: '換洗衣物 (3套)', checked: false),
        PersonalItem(id: 'p2', name: '睡衣', checked: false),
        PersonalItem(id: 'p3', name: '牙刷 / 牙膏', checked: true),
        PersonalItem(id: 'p4', name: '手機快充線', checked: false),
        PersonalItem(id: 'p5', name: '防蚊液 (台南夏天必備)', checked: true),
        PersonalItem(id: 'p6', name: '薄外套 (防冷氣)', checked: false),
      ];

      _sharedItems = [
        SharedItem(id: 's1', name: '延長線 (民宿插座少)', assignee: null, isSuggested: true),
        SharedItem(id: 's2', name: '安耐曬防曬乳', assignee: null, isSuggested: true),
        SharedItem(id: 's3', name: '大風量吹風機', assignee: '小明', isSuggested: false),
        SharedItem(id: 's4', name: '醫藥盒 (腸胃藥/OK繃)', assignee: null, isSuggested: true),
        SharedItem(id: 's5', name: '桌遊 (UNO/撲克牌)', assignee: '阿華', isSuggested: false),
      ];
    });
    _savePersonal();
    _saveShared();
    
    // 跳出提示框
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('🎁 已成功載入台南測試資料！'), duration: Duration(seconds: 2), backgroundColor: Color(0xFF6CA6CC)),
    );
  }

  // 操作函數
  void _togglePersonalItem(String id) {
    setState(() {
      for (var item in _personalItems) {
        if (item.id == id) item.checked = !item.checked;
      }
    });
    _savePersonal();
  }

  void _claimItem(String id) {
    setState(() {
      for (var item in _sharedItems) {
        if (item.id == id) item.assignee = '我';
      }
    });
    _saveShared();
  }

  void _unclaimItem(String id) {
    setState(() {
      for (var item in _sharedItems) {
        if (item.id == id) item.assignee = null;
      }
    });
    _saveShared();
  }

  void _handleAddItem() {
    final name = _newItemCtrl.text.trim();
    if (name.isEmpty) return;
    
    final newId = DateTime.now().millisecondsSinceEpoch.toString();
    setState(() {
      if (_activeTab == 'personal') {
        _personalItems.add(PersonalItem(id: newId, name: name, checked: false));
        _savePersonal();
      } else {
        _sharedItems.add(SharedItem(id: newId, name: name, assignee: null, isSuggested: false));
        _saveShared();
      }
    });
    _newItemCtrl.clear();
    FocusScope.of(context).unfocus(); // 收起鍵盤
  }

  // 🌟 超強統整 Modal (BottomSheet)
  void _showSummaryModal() {
    int personalDone = _personalItems.where((i) => i.checked).length;
    int sharedDone = _sharedItems.where((i) => i.assignee != null).length;
    int totalCount = _personalItems.length + _sharedItems.length;
    int totalDoneCount = personalDone + sharedDone;
    double progressRatio = totalCount > 0 ? totalDoneCount / totalCount : 0;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.85,
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30))
          ),
          child: Column(
            children: [
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  icon: const Icon(Icons.cancel, size: 32, color: Colors.grey),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Image.asset(
                        progressRatio >= 0.5 ? 'assets/piggy/pig_login1.png' : 'assets/piggy/pig_login0.png',
                        width: 140, height: 140,
                      ),
                      const SizedBox(height: 10),
                      const Text('準備進度總覽', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 15),
                      // Progress Bar
                      Container(
                        width: MediaQuery.of(context).size.width * 0.8,
                        height: 10,
                        decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(5)),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: progressRatio,
                          child: Container(decoration: BoxDecoration(color: const Color(0xFF6CA6CC), borderRadius: BorderRadius.circular(5))),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text('$totalDoneCount / $totalCount 項已就緒', style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                      
                      // 🔴 還沒準備
                      const SizedBox(height: 25),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('🔴 還沒準備 (${totalCount - totalDoneCount})', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                            const SizedBox(height: 10),
                            ..._personalItems.where((i) => !i.checked).map((i) => Padding(padding: const EdgeInsets.only(bottom: 5, left: 10), child: Text('• ${i.name}', style: const TextStyle(color: Colors.grey, fontSize: 15)))),
                            ..._sharedItems.where((i) => i.assignee == null).map((i) => Padding(padding: const EdgeInsets.only(bottom: 5, left: 10), child: Text('• ${i.name}', style: const TextStyle(color: Colors.grey, fontSize: 15)))),
                          ],
                        ),
                      ),

                      // 🟢 已經帶了
                      const SizedBox(height: 25),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('🟢 已經帶了 ($totalDoneCount)', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                            const SizedBox(height: 10),
                            ..._personalItems.where((i) => i.checked).map((i) => Padding(padding: const EdgeInsets.only(bottom: 5, left: 10), child: Text('• ${i.name}', style: const TextStyle(color: Colors.grey, fontSize: 15)))),
                            ..._sharedItems.where((i) => i.assignee != null).map((i) => Padding(padding: const EdgeInsets.only(bottom: 5, left: 10), child: Text('• ${i.name} (${i.assignee})', style: const TextStyle(color: Colors.grey, fontSize: 15)))),
                          ],
                        ),
                      ),
                      const SizedBox(height: 50),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    List<dynamic> currentList = _activeTab == 'personal' ? _personalItems : _sharedItems;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F9FF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            width: 40, height: 40,
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 2)]),
            child: const Icon(Icons.arrow_back_ios_new, size: 20, color: Colors.black87),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('行李準備', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
        centerTitle: true,
        actions: [
          // 🔥 測試專用：載入資料按鈕 (橘色禮物盒)
          IconButton(
            icon: Container(
              width: 40, height: 40,
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 2)]),
              child: const Icon(Icons.card_giftcard, size: 20, color: Color(0xFFFF9800)),
            ),
            onPressed: _injectTestData,
          ),
          // 總覽清單按鈕
          IconButton(
            icon: Container(
              width: 40, height: 40,
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 2)]),
              child: const Icon(Icons.list_alt, size: 20, color: Color(0xFF6CA6CC)),
            ),
            onPressed: _showSummaryModal,
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: Column(
        children: [
          // Tabs
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(color: const Color(0xFFE0EEF8), borderRadius: BorderRadius.circular(25)),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _activeTab = 'personal'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _activeTab == 'personal' ? const Color(0xFF6CA6CC) : Colors.transparent,
                        borderRadius: BorderRadius.circular(20)
                      ),
                      child: Center(child: Text('我的行李', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: _activeTab == 'personal' ? Colors.white : Colors.grey[600]))),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _activeTab = 'shared'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _activeTab == 'shared' ? const Color(0xFF6CA6CC) : Colors.transparent,
                        borderRadius: BorderRadius.circular(20)
                      ),
                      child: Center(child: Text('群組共享', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: _activeTab == 'shared' ? Colors.white : Colors.grey[600]))),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // List 渲染
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              itemCount: currentList.length,
              itemBuilder: (ctx, i) {
                final item = currentList[i];
                
                // 情況 A: 個人行李
                if (_activeTab == 'personal') {
                  final pItem = item as PersonalItem;
                  return GestureDetector(
                    onTap: () => _togglePersonalItem(pItem.id),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 2)]),
                      child: Row(
                        children: [
                          Icon(pItem.checked ? Icons.check_circle : Icons.radio_button_unchecked, size: 28, color: pItem.checked ? const Color(0xFF6CA6CC) : Colors.grey[400]),
                          const SizedBox(width: 15),
                          Expanded(child: Text(pItem.name, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: pItem.checked ? Colors.grey : Colors.black87, decoration: pItem.checked ? TextDecoration.lineThrough : null))),
                        ],
                      ),
                    ),
                  );
                }
                
                // 情況 B: 群組共享
                final sItem = item as SharedItem;
                final isClaimedByMe = sItem.assignee == '我';
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: sItem.isSuggested && sItem.assignee == null ? const Color(0xFFFFF9E6) : Colors.white, 
                    borderRadius: BorderRadius.circular(15), 
                    border: sItem.isSuggested && sItem.assignee == null ? Border.all(color: const Color(0xFFFFE499)) : null,
                    boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 2)]
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (sItem.isSuggested && sItem.assignee == null) 
                              const Text('💡 智能建議', style: TextStyle(fontSize: 11, color: Color(0xFFFFB800), fontWeight: FontWeight.bold)),
                            const SizedBox(height: 2),
                            Text(sItem.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                            const SizedBox(height: 4),
                            Text(sItem.assignee != null ? '負責人：${sItem.assignee}' : '尚未有人認領', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: sItem.assignee != null ? const Color(0xFF6CA6CC) : const Color(0xFFFF8888))),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () => isClaimedByMe ? _unclaimItem(sItem.id) : _claimItem(sItem.id),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                          decoration: BoxDecoration(color: isClaimedByMe ? Colors.grey[200] : const Color(0xFF6CA6CC), borderRadius: BorderRadius.circular(20)),
                          child: Text(isClaimedByMe ? '取消' : '我來帶', style: TextStyle(color: isClaimedByMe ? Colors.grey[600] : Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      )
                    ],
                  ),
                );
              },
            ),
          ),

          // 新增物品的輸入框
          Container(
            padding: const EdgeInsets.fromLTRB(15, 10, 15, 25), 
            decoration: const BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5, offset: Offset(0, -2))]),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    decoration: BoxDecoration(color: const Color(0xFFF2F9FF), borderRadius: BorderRadius.circular(25)),
                    child: TextField(
                      controller: _newItemCtrl,
                      decoration: const InputDecoration(hintText: '新增物品...', border: InputBorder.none),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: _handleAddItem,
                  child: Container(
                    width: 50, height: 50,
                    decoration: const BoxDecoration(color: Color(0xFF6CA6CC), shape: BoxShape.circle),
                    child: const Icon(Icons.add, color: Colors.white, size: 28),
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}