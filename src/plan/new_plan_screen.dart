import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'plan_provider.dart';

class NewPlanScreen extends StatefulWidget {
  final Map<String, dynamic>? plan; // 用來接收傳進來的舊計畫資料 (有傳代表編輯，無傳代表新增)

  const NewPlanScreen({super.key, this.plan});

  @override
  State<NewPlanScreen> createState() => _NewPlanScreenState();
}

class _NewPlanScreenState extends State<NewPlanScreen> {
  final TextEditingController _titleCtrl = TextEditingController();
  String? _selectedImagePath;

  late DateTime _startDate;
  late DateTime _endDate;
  void _handleConfirmDialog() {
    print('確認按鈕被按下了');
  }
  @override
  void initState() {
    super.initState();
    
    // 判斷：如果有傳資料進來，就把資料填入欄位
    if (widget.plan != null) {
      _titleCtrl.text = widget.plan!['title'] ?? '';
      _selectedImagePath = widget.plan!['img'];
      
      // 解析日期字串還原成 DateTime 格式
      try {
        List<String> dates = widget.plan!['date'].split('~');
        List<String> startParts = dates[0].split('/');
        List<String> endParts = dates[1].split('/');
        _startDate = DateTime(int.parse(startParts[0]), int.parse(startParts[1]), int.parse(startParts[2]));
        _endDate = DateTime(int.parse(endParts[0]), int.parse(endParts[1]), int.parse(endParts[2]));
      } catch (e) {
        _startDate = DateTime.now();
        _endDate = _startDate.add(const Duration(days: 1));
      }
    } else {
      // 如果是全新的一份，給預設值
      _startDate = DateTime.now();
      _endDate = _startDate.add(const Duration(days: 1));
    }
  }

  String _formatDate(DateTime d) => "${d.year}/${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}";

  Future<void> _pickDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFF6CA6CC), onPrimary: Colors.white, onSurface: Colors.black),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (_startDate.isAfter(_endDate)) _endDate = _startDate;
        } else {
          if (picked.isBefore(_startDate)) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('結束日期不能早於開始喔！')));
          } else {
            _endDate = picked;
          }
        }
      });
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _selectedImagePath = image.path);
    }
  }

  void _handleConfirm() {
    if (_titleCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('請輸入行程名稱！')));
      return;
    }

    String fullDate = "${_formatDate(_startDate)}~${_formatDate(_endDate)}";
    final provider = Provider.of<PlanProvider>(context, listen: false);

    // 判斷：如果是編輯模式，就呼叫 updatePlanInfo 更新；否則新增
    if (widget.plan != null) {
      provider.updatePlanInfo(widget.plan!['id'], _titleCtrl.text, fullDate, _selectedImagePath);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已儲存設定！')));
    } else {
      provider.addPlan({
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'title': _titleCtrl.text,
        'date': fullDate,
        'members': 1,
        'img': _selectedImagePath,
      });
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEditMode = widget.plan != null;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const IconButton(icon: Icon(Icons.close, color: Colors.transparent), onPressed: null),
        title: Text(isEditMode ? '行程設定' : '新增新計畫', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.close, color: Colors.black87), onPressed: () => Navigator.pop(context))
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: double.infinity, height: 180,
                decoration: BoxDecoration(color: const Color(0xFFCAE2F2), borderRadius: BorderRadius.circular(20)),
                alignment: Alignment.center,
                child: _selectedImagePath != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.file(File(_selectedImagePath!), width: double.infinity, height: double.infinity, fit: BoxFit.cover, errorBuilder: (_,__,___) => const Icon(Icons.check_circle, size: 60, color: Colors.white)),
                      )
                    : const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.image, size: 50, color: Colors.black26),
                          SizedBox(height: 10),
                          Text('更換背景', style: TextStyle(color: Colors.black54, fontWeight: FontWeight.bold)),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 25),

            Row(children: const [
              Text('行程名稱 ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Text('*', style: TextStyle(color: Colors.red, fontSize: 16, fontWeight: FontWeight.bold))
            ]),
            const SizedBox(height: 10),
            TextField(
              controller: _titleCtrl,
              decoration: InputDecoration(
                hintText: '輸入名稱',
                filled: true,
                fillColor: const Color(0xFFEAEAEA),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 25),

            const Text('行程日期', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _pickDate(true),
                    child: Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(color: const Color(0xFFEAEAEA), borderRadius: BorderRadius.circular(12)),
                      child: Center(child: Text(_formatDate(_startDate), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                    ),
                  ),
                ),
                const Padding(padding: EdgeInsets.symmetric(horizontal: 10), child: Text('~', style: TextStyle(fontSize: 20, color: Colors.grey))),
                Expanded(
                  child: InkWell(
                    onTap: () => _pickDate(false),
                    child: Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(color: const Color(0xFFEAEAEA), borderRadius: BorderRadius.circular(12)),
                      child: Center(child: Text(_formatDate(_endDate), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 35),

            // 邀請按鈕 (無目的地選擇)
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(color: const Color(0xFFEAEAEA), borderRadius: BorderRadius.circular(12)),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.mail_outline, color: Colors.black54),
                  SizedBox(width: 8),
                  Text('邀請 Piggo 帳戶', style: TextStyle(color: Colors.black54, fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
            ),
            const SizedBox(height: 50),

            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[800],
                  padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                onPressed: _handleConfirmDialog,
                child: Text(isEditMode ? '儲存設定' : '確定行程', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            )
          ],
        ),
      ),
    );
  }

  void _ConfirmDialog() {
    _handleConfirm();
  }
}