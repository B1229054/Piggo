import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:io';
import 'plan_provider.dart';

class GroupChatScreen extends StatefulWidget {
  final String planId;
  const GroupChatScreen({super.key, required this.planId});

  @override
  State<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> {
  final TextEditingController _inputCtrl = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _handleSend() {
    if (_inputCtrl.text.trim().isEmpty) return;
    Provider.of<PlanProvider>(context, listen: false).sendMessage(widget.planId, _inputCtrl.text.trim());
    _inputCtrl.clear();
    _scrollToBottom();
  }

  Future<void> _handlePickImage(bool fromCamera) async {
    Navigator.pop(context); // 關閉 + 號選單
    final picker = ImagePicker();
    final image = await picker.pickImage(source: fromCamera ? ImageSource.camera : ImageSource.gallery, imageQuality: 70);
    if (image != null) {
      Provider.of<PlanProvider>(context, listen: false).sendImage(widget.planId, image.path);
      _scrollToBottom();
    }
  }

  void _showPlusMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(30),
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildMenuIcon(Icons.bar_chart, '發起投票', const Color(0xFFFF9F43), () {
              Navigator.pop(ctx);
              _openVoteCreator();
            }),
            _buildMenuIcon(Icons.camera_alt, '拍照', const Color(0xFF54A0FF), () => _handlePickImage(true)),
            _buildMenuIcon(Icons.image, '相簿', const Color(0xFF1DD1A1), () => _handlePickImage(false)),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuIcon(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60, height: 60,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // 開啟投票建立視窗
  void _openVoteCreator() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _VoteCreatorSheet(planId: widget.planId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PlanProvider>();
    final messages = provider.getMessages(widget.planId);
    
    // 尋找計畫名稱 (找不到就用預設)
    final planInfo = provider.plans.firstWhere((p) => p['id'] == widget.planId, orElse: () => {'title': '旅遊群組', 'members': 1});

    return Scaffold(
      backgroundColor: const Color(0xFFF2F9FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1, shadowColor: Colors.black12,
        leading: IconButton(icon: const Icon(Icons.chevron_left, color: Colors.black), onPressed: () => Navigator.pop(context)),
        title: Text('${planInfo['title']}(${planInfo['members']})', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(15),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final msg = messages[index];
                  final isMe = msg['sender'] == 'me';

                  if (msg['type'] == 'vote') {
                    return _buildVoteCard(msg);
                  }

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 15),
                    child: Row(
                      mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (!isMe) const CircleAvatar(backgroundColor: Colors.grey, child: Text('🐷')),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Column(
                            crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                            children: [
                              if (!isMe) Text(msg['name'], style: const TextStyle(fontSize: 12, color: Colors.grey)),
                              if (msg['type'] == 'image')
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(15),
                                  child: Image.file(File(msg['image']), width: 200, height: 150, fit: BoxFit.cover, errorBuilder: (_,__,___) => const Icon(Icons.broken_image, size: 100)),
                                )
                              else
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: isMe ? const Color(0xFF6CA6CC) : Colors.white,
                                    borderRadius: BorderRadius.only(topLeft: const Radius.circular(15), topRight: const Radius.circular(15), bottomLeft: Radius.circular(isMe ? 15 : 2), bottomRight: Radius.circular(isMe ? 2 : 15)),
                                  ),
                                  child: Text(msg['text'], style: TextStyle(color: isMe ? Colors.white : Colors.black87, fontSize: 16)),
                                ),
                              Text(msg['time'], style: const TextStyle(fontSize: 10, color: Colors.grey)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (isMe) const CircleAvatar(backgroundColor: Colors.grey, child: Text('🐷')),
                      ],
                    ),
                  );
                },
              ),
            ),
            
            // 底部輸入列
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              color: Colors.white,
              child: Row(
                children: [
                  IconButton(icon: const Icon(Icons.add_circle_outline, size: 30, color: Color(0xFF6CA6CC)), onPressed: _showPlusMenu),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(20)),
                      child: TextField(
                        controller: _inputCtrl,
                        decoration: const InputDecoration(hintText: '輸入訊息...', border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 15, vertical: 10)),
                        onSubmitted: (_) => _handleSend(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _handleSend,
                    child: Container(width: 40, height: 40, decoration: const BoxDecoration(color: Color(0xFF6CA6CC), shape: BoxShape.circle), child: const Icon(Icons.send, color: Colors.white, size: 20)),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  // 渲染投票卡片
  Widget _buildVoteCard(Map<String, dynamic> msg) {
    final voteData = msg['voteData'];
    final options = voteData['options'] as List;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bar_chart, color: Color(0xFF6CA6CC), size: 18),
              const Text(' 行程投票發起', style: TextStyle(color: Color(0xFF6CA6CC), fontWeight: FontWeight.bold, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 10),
          Text(voteData['question'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: [
              if (voteData['isMultiSelect']) _buildTag('☑️ 可複選'),
              if (voteData['isAnonymous']) _buildTag('👤 匿名'),
              _buildTag(voteData['deadline'] == '無限制' ? '⏰ 暫無截止日' : '⏰ 截止: ${voteData['deadline']}', isAlert: voteData['deadline'] != '無限制'),
            ],
          ),
          const SizedBox(height: 15),
          ...List.generate(options.length, (idx) {
            final opt = options[idx];
            final isVotedByMe = (opt['voters'] as List).contains('me');
            return GestureDetector(
              onTap: () => Provider.of<PlanProvider>(context, listen: false).castVote(widget.planId, msg['id'], idx, 'me'),
              child: Container(
                margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(color: isVotedByMe ? const Color(0xFFEAF4FA) : Colors.grey[50], borderRadius: BorderRadius.circular(12), border: Border.all(color: isVotedByMe ? const Color(0xFF6CA6CC) : Colors.grey[300]!)),
                child: Row(
                  children: [
                    Container(width: 10, height: 10, decoration: BoxDecoration(color: isVotedByMe ? Colors.orange : const Color(0xFF6CA6CC), shape: BoxShape.circle)),
                    const SizedBox(width: 10),
                    Expanded(child: Text(opt['text'], style: TextStyle(fontWeight: isVotedByMe ? FontWeight.bold : FontWeight.normal, color: isVotedByMe ? const Color(0xFF6CA6CC) : Colors.black87))),
                    Text('${opt['count']} 票', style: const TextStyle(color: Color(0xFF6CA6CC), fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTag(String text, {bool isAlert = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: isAlert ? const Color(0xFFFFF0F0) : const Color(0xFFE8F1F8), borderRadius: BorderRadius.circular(12)),
      child: Text(text, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isAlert ? Colors.red : const Color(0xFF6CA6CC))),
    );
  }
}

// ==========================================
// 建立投票專用的 BottomSheet
// ==========================================
class _VoteCreatorSheet extends StatefulWidget {
  final String planId;
  const _VoteCreatorSheet({required this.planId});

  @override
  State<_VoteCreatorSheet> createState() => _VoteCreatorSheetState();
}

class _VoteCreatorSheetState extends State<_VoteCreatorSheet> {
  String _category = 'general';
  final TextEditingController _questionCtrl = TextEditingController();
  List<Map<String, dynamic>> _options = [{'text': '', 'coord': null}, {'text': '', 'coord': null}];
  
  bool _isMultiSelect = false;
  bool _isAnonymous = false;
  String _deadline = '無限制';

  void _publish() {
    List<Map<String, dynamic>> validOptions = _options.where((o) => o['text'].toString().trim().isNotEmpty).toList();
    if (_questionCtrl.text.trim().isEmpty || validOptions.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('請輸入問題與至少兩個選項！')));
      return;
    }

    Provider.of<PlanProvider>(context, listen: false).addVote(widget.planId, {
      'question': _questionCtrl.text.trim(),
      'options': validOptions,
      'isMultiSelect': _isMultiSelect,
      'isAnonymous': _isAnonymous,
      'deadline': _deadline,
    });
    Navigator.pop(context); // 關閉表單
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(color: Color(0xFFF8FBFF), borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      child: Column(
        children: [
          Container(width: 50, height: 5, margin: const EdgeInsets.symmetric(vertical: 10), decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(5))),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(onTap: () => Navigator.pop(context), child: const Text('取消', style: TextStyle(color: Colors.grey, fontSize: 16))),
                const Text('發起新投票', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6CA6CC), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                  onPressed: _publish,
                  child: const Text('發布', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                )
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // 類型切換
                Container(
                  decoration: BoxDecoration(color: const Color(0xFFE8F1F8), borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    children: [
                      Expanded(child: _buildTypeBtn('一般投票', 'general')),
                      Expanded(child: _buildTypeBtn('📍 景點投票', 'spot')),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const Text('大家來表決 💬', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 10),
                TextField(
                  controller: _questionCtrl,
                  maxLines: 2,
                  decoration: InputDecoration(hintText: '想問大家什麼呢？', filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none)),
                ),
                const SizedBox(height: 20),
                const Text('選項 📋', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 10),
                ...List.generate(_options.length, (index) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE8F1F8))),
                    child: Row(
                      children: [
                        CircleAvatar(radius: 12, backgroundColor: const Color(0xFF6CA6CC), child: Text('${index + 1}', style: const TextStyle(color: Colors.white, fontSize: 12))),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            onChanged: (val) => _options[index]['text'] = val,
                            decoration: const InputDecoration(hintText: '輸入選項...', border: InputBorder.none),
                          ),
                        ),
                        if (_category == 'spot') const Icon(Icons.map, color: Color(0xFF54A0FF)),
                      ],
                    ),
                  );
                }),
                TextButton.icon(
                  onPressed: () => setState(() => _options.add({'text': '', 'coord': null})),
                  icon: const Icon(Icons.add_circle_outline, color: Color(0xFF6CA6CC)),
                  label: const Text('新增選項', style: TextStyle(color: Color(0xFF6CA6CC))),
                ),
                const SizedBox(height: 20),
                const Text('進階設定 ⚙️', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                SwitchListTile(title: const Text('一人多票 (可複選)'), value: _isMultiSelect, activeColor: const Color(0xFF6CA6CC), onChanged: (v) => setState(() => _isMultiSelect = v)),
                SwitchListTile(title: const Text('匿名投票'), value: _isAnonymous, activeColor: const Color(0xFF6CA6CC), onChanged: (v) => setState(() => _isAnonymous = v)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildTypeBtn(String label, String type) {
    bool isActive = _category == type;
    return GestureDetector(
      onTap: () {
        setState(() {
          _category = type;
          if (type == 'spot') {
            _questionCtrl.text = '基於目前的行程，大家下個景點想去哪？';
            _options = [{'text': '奇美博物館', 'coord': null}, {'text': '安平古堡', 'coord': null}];
          } else {
            _questionCtrl.clear();
            _options = [{'text': '', 'coord': null}, {'text': '', 'coord': null}];
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(color: isActive ? Colors.white : Colors.transparent, borderRadius: BorderRadius.circular(8), boxShadow: isActive ? [const BoxShadow(color: Colors.black12, blurRadius: 2)] : []),
        alignment: Alignment.center,
        child: Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: isActive ? const Color(0xFF6CA6CC) : Colors.grey)),
      ),
    );
  }
}