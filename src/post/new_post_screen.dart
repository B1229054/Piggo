import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart'; // 引入裁切套件
import 'package:shared_preferences/shared_preferences.dart';
import 'location_search_screen.dart'; 

class NewPostScreen extends StatefulWidget {
  const NewPostScreen({super.key});

  @override
  State<NewPostScreen> createState() => _NewPostScreenState();
}

class _NewPostScreenState extends State<NewPostScreen> {
  final List<String> _images = [];
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _hashtagController = TextEditingController();
  final List<String> _hashtags = [];
  String? _selectedLocation;

  @override
  void initState() {
    super.initState();
    // 進入畫面時自動打開相簿
    WidgetsBinding.instance.addPostFrameCallback((_) => _pickImages());
  }

  // 裁切圖片的功能
  Future<void> _cropImage(int index) async {
    CroppedFile? croppedFile = await ImageCropper().cropImage(
      sourcePath: _images[index],
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: '編輯照片',
          toolbarColor: const Color(0xFF007AFF),
          toolbarWidgetColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.square,
          lockAspectRatio: false,
          hideBottomControls: false, // 顯示旋轉、比例縮放的控制列
          aspectRatioPresets: [
            CropAspectRatioPreset.square,
            CropAspectRatioPreset.ratio3x2,
            CropAspectRatioPreset.original,
            CropAspectRatioPreset.ratio4x3,
            CropAspectRatioPreset.ratio16x9
          ],
        ),
        IOSUiSettings(
          title: '編輯照片',
          aspectRatioPresets: [
            CropAspectRatioPreset.square,
            CropAspectRatioPreset.ratio3x2,
            CropAspectRatioPreset.original,
            CropAspectRatioPreset.ratio4x3,
            CropAspectRatioPreset.ratio16x9
          ],
        ),
      ],
    );

    // 如果完成裁切，就把舊圖片替換成裁切後的新圖片
    if (croppedFile != null) {
      setState(() {
        _images[index] = croppedFile.path;
      });
    }
  }

  // 選擇圖片
  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final List<XFile> pickedFiles = await picker.pickMultiImage(imageQuality: 80);

    if (pickedFiles.isNotEmpty) {
      setState(() {
        _images.addAll(pickedFiles.map((file) => file.path));
      });
    } else if (_images.isEmpty) {
      if (mounted) Navigator.pop(context);
    }
  }

  // 處理Hashtag
  void _onHashtagChanged(String text) {
    if (text.endsWith(' ')) {
      String cleanText = text.trim();
      if (cleanText.isNotEmpty) {
        if (!cleanText.startsWith('#')) cleanText = '#$cleanText';
        if (!_hashtags.contains(cleanText)) {
          setState(() {
            _hashtags.add(cleanText);
          });
        }
      }
      _hashtagController.clear();
    }
  }

  // 處理發布
  Future<void> _handlePublish() async {
    if (_images.isEmpty) {
      _showAlert('提示', '請至少保留一張照片');
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final String? postsJson = prefs.getString('my-posts');
    List<dynamic> posts = postsJson != null ? jsonDecode(postsJson) : [];

    final newPost = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(), 
      'imageUrls': _images, 
      'hashtags': _hashtags,
      'location': _selectedLocation,
      'description': _descController.text,
    };

    posts.insert(0, newPost);
    await prefs.setString('my-posts', jsonEncode(posts));
    
    if (mounted) Navigator.pop(context);
  }

  void _showAlert(String title, String content) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('確定'))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F9FF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF007AFF)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('新貼文', style: TextStyle(color: Color(0xFF007AFF), fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: Column(
          children: [
            SizedBox(
              height: 160,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                scrollDirection: Axis.horizontal,
                itemCount: _images.length + (_images.length < 10 ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _images.length) return _buildAddImageBtn();
                  return _buildImageItem(index);
                },
              ),
            ),
            Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(15),
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4)],
              ),
              child: TextField(
                controller: _descController,
                maxLines: null,
                decoration: const InputDecoration(hintText: "新增說明文字...", border: InputBorder.none),
              ),
            ),
            _buildSectionHeader(Icons.location_on, '地點'),
            _buildLocationSelector(),
            const SizedBox(height: 25),
            _buildSectionHeader(Icons.tag, '相關旅遊標籤'),
            _buildHashtagContainer(),
            const SizedBox(height: 40),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _handlePublish,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF007AFF),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('發布', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildImageItem(int index) {
    return Stack(
      children: [
        Container(
          margin: const EdgeInsets.only(right: 10),
          width: 150, height: 150,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            image: DecorationImage(image: FileImage(File(_images[index])), fit: BoxFit.cover),
          ),
        ),
        // 刪除按鈕 (右上角)
        Positioned(
          right: 15, top: 8,
          child: GestureDetector(
            onTap: () => setState(() => _images.removeAt(index)),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
              child: const Icon(Icons.close, color: Colors.white, size: 14),
            ),
          ),
        ),
        // 編輯/裁切按鈕 (左上角)
        Positioned(
          left: 5, top: 8,
          child: GestureDetector(
            onTap: () => _cropImage(index),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.85), 
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 3)],
              ),
              child: const Icon(Icons.crop_rotate, color: Color(0xFF007AFF), size: 18),
            ),
          ),
        )
      ],
    );
  }

  Widget _buildAddImageBtn() {
    return GestureDetector(
      onTap: _pickImages,
      child: Container(
        width: 150, height: 150,
        decoration: BoxDecoration(
          color: const Color(0xFFE0E0E0),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey, style: BorderStyle.solid),
        ),
        child: const Icon(Icons.add, size: 32, color: Colors.grey),
      ),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 10),
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          const Text(' *', style: TextStyle(color: Colors.red)),
        ],
      ),
    );
  }

  Widget _buildLocationSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: InkWell(
        onTap: () async {
          final selected = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const LocationSearchScreen()),
          );
          if (selected != null) setState(() => _selectedLocation = selected);
        },
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(color: const Color(0xFFE8F1FA), borderRadius: BorderRadius.circular(8)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_selectedLocation ?? '新增地點...', style: TextStyle(color: _selectedLocation == null ? Colors.grey : Colors.black)),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHashtagContainer() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: const Color(0xFFE8F1FA), borderRadius: BorderRadius.circular(8)),
      child: Wrap(
        spacing: 8,
        children: [
          ..._hashtags.map((tag) => Chip(
            label: Text(tag, style: const TextStyle(color: Color(0xFF007AFF))),
            backgroundColor: const Color(0xFFCCE0F5),
            onDeleted: () => setState(() => _hashtags.remove(tag)),
            deleteIconColor: const Color(0xFF007AFF),
          )),
          TextField(
            controller: _hashtagController,
            onChanged: _onHashtagChanged,
            decoration: const InputDecoration(hintText: "輸入後按空白鍵產生標籤", border: InputBorder.none, isDense: true),
          ),
        ],
      ),
    );
  }
}
