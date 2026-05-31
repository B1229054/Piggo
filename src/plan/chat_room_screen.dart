import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'plan_provider.dart';
import 'dart:io'; 
import 'package:image_picker/image_picker.dart';

class ChatRoomScreen extends StatefulWidget {
  final String planId;
  final String roomName;

  const ChatRoomScreen({
    super.key,
    required this.planId,
    this.roomName = "旅遊群組",
  });

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final TextEditingController _inputCtrl = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // 傳送訊息邏輯
  void _handleSend() {
    if (_inputCtrl.text.trim().isEmpty) return;

    final provider = Provider.of<PlanProvider>(context, listen: false);
    
    // 呼叫 Provider 裡的方法 (我們等一下要在 Provider 補上這個 method)
    provider.sendMessage(widget.planId, _inputCtrl.text.trim());
    _inputCtrl.clear();

    // 延遲一點點時間，等畫面渲染新訊息後，捲動到底部
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
  // 🔥 點擊左下角 + 號彈出的擴充選單
  void _showActionMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20))
        ),
        child: SafeArea(
          child: Wrap(
            children: [
              // 選項 1：發起投票
              ListTile(
                leading: const CircleAvatar(backgroundColor: Color(0xFFE8F2FA), child: Icon(Icons.how_to_vote, color: Color(0xFF6CA6CC))),
                title: const Text('發起投票', style: TextStyle(fontWeight: FontWeight.bold)),
                onTap: () {
                  Navigator.pop(context); // 先關閉底下這塊選單
                  // TODO: 之後在這裡換成跳轉到投票頁面的程式碼
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('發起投票功能即將推出！')));
                },
              ),
              // 選項 2：拍照
              ListTile(
                leading: const CircleAvatar(backgroundColor: Color(0xFFFFF9E6), child: Icon(Icons.camera_alt, color: Colors.orange)),
                title: const Text('拍照', style: TextStyle(fontWeight: FontWeight.bold)),
                onTap: () async {
                  Navigator.pop(context); // 關閉選單
                  final ImagePicker picker = ImagePicker();
                  final XFile? photo = await picker.pickImage(source: ImageSource.camera);
                  if (photo != null) {
                    // 呼叫你在 Provider 寫好的 sendImage！
                    Provider.of<PlanProvider>(context, listen: false).sendImage(widget.planId, photo.path);
                  }
                },
              ),
              // 選項 3：傳送照片
              ListTile(
                leading: const CircleAvatar(backgroundColor: Color(0xFFF2F9FF), child: Icon(Icons.photo_library, color: Colors.blue)),
                title: const Text('傳送照片', style: TextStyle(fontWeight: FontWeight.bold)),
                onTap: () async {
                  Navigator.pop(context); // 關閉選單
                  final ImagePicker picker = ImagePicker();
                  final XFile? image = await picker.pickImage(source: ImageSource.gallery);
                  if (image != null) {
                    // 呼叫你在 Provider 寫好的 sendImage！
                    Provider.of<PlanProvider>(context, listen: false).sendImage(widget.planId, image.path);
                  }
                },
              ),
            ],
          ),
        ),
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    // 每次畫面重繪時，自動監聽這個 planId 專屬的訊息列表
    final messages = context.watch<PlanProvider>().getMessages(widget.planId);

    return Scaffold(
      backgroundColor: const Color(0xFFEAF6FF), // 背景淺藍色
      appBar: AppBar(
        backgroundColor: const Color(0xFFEAF6FF),
        elevation: 1, // 稍微有一點陰影當作分隔線
        shadowColor: Colors.black26,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: Colors.black87, size: 30),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('${widget.roomName} (${messages.length + 1})', style: const TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu, color: Colors.black87),
            onPressed: () {
               // 右上角選單功能保留
            },
          )
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 🌟 訊息對話框列表
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(15),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final msg = messages[index];
                  final bool isMe = msg['sender'] == 'me';

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Row(
                      mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 別人的大頭貼
                        if (!isMe)
                          Container(
                            width: 40, height: 40,
                            margin: const EdgeInsets.only(right: 10),
                            decoration: BoxDecoration(color: Colors.grey[300], shape: BoxShape.circle),
                            child: const Center(child: Text('🐷', style: TextStyle(fontSize: 20))),
                          ),
                        
                        // 訊息氣泡與名稱
                        Flexible(
                          child: Column(
                            crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                            children: [
                              if (!isMe)
                                Padding(
                                  padding: const EdgeInsets.only(left: 4, bottom: 4),
                                  child: Text(msg['name'] ?? '朋友', style: const TextStyle(fontSize: 12, color: Colors.black54)),
                                ),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isMe ? const Color(0xFF6CA6CC) : Colors.white,
                                  borderRadius: BorderRadius.only(
                                    topLeft: const Radius.circular(15),
                                    topRight: const Radius.circular(15),
                                    bottomLeft: Radius.circular(isMe ? 15 : 4),
                                    bottomRight: Radius.circular(isMe ? 4 : 15),
                                  ),
                                ),
                                child: Text(
                                  msg['text'] ?? '',
                                  style: TextStyle(fontSize: 16, color: isMe ? Colors.white : Colors.black87),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(msg['time'] ?? '剛剛', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // 🌟 底部輸入框
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              color: Colors.white,
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.add, color: Colors.black54, size: 28),
                    onPressed: _showActionMenu,
                  ),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(25)),
                      child: TextField(
                        controller: _inputCtrl,
                        decoration: const InputDecoration(
                          hintText: "輸入訊息...",
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                        ),
                        onSubmitted: (_) => _handleSend(), // 按下鍵盤 Enter 也可以送出
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _handleSend,
                    child: Container(
                      width: 40, height: 40,
                      decoration: const BoxDecoration(color: Color(0xFF6CA6CC), shape: BoxShape.circle),
                      child: const Icon(Icons.send, color: Colors.white, size: 20),
                    ),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}