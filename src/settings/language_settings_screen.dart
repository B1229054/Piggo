import 'package:flutter/material.dart';

class LanguageSettingsScreen extends StatefulWidget {
  const LanguageSettingsScreen({super.key});

  @override
  State<LanguageSettingsScreen> createState() => _LanguageSettingsScreenState();
}

class _LanguageSettingsScreenState extends State<LanguageSettingsScreen> {
  final TextEditingController _searchController = TextEditingController();
  
  // 模擬原本的 LANGUAGES 資料
  final List<Map<String, String>> _languages = [
    {'id': 'en', 'name': 'English', 'sub': '英文'},
    {'id': 'zh-tw', 'name': '中文(繁體)', 'sub': '繁體中文'},
  ];

  List<Map<String, String>> _filteredLanguages = [];

  @override
  void initState() {
    super.initState();
    _filteredLanguages = _languages;
  }

  void _filterLanguages(String query) {
    setState(() {
      _filteredLanguages = _languages
          .where((lang) =>
              lang['name']!.toLowerCase().contains(query.toLowerCase()) ||
              lang['sub']!.contains(query))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F9FF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('語言設定', 
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            // 搜尋框 (對應原本的 searchContainer)
            Container(
              margin: const EdgeInsets.only(top: 10),
              height: 45,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: const Color(0xFF007AFF)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: _filterLanguages,
                decoration: InputDecoration(
                  hintText: '搜尋語言',
                  prefixIcon: const Icon(Icons.search, color: Color(0xFF007AFF)),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close, color: Colors.grey),
                          onPressed: () {
                            _searchController.clear();
                            _filterLanguages('');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // 語言列表 (對應原本的 FlatList)
            Expanded(
              child: ListView.builder(
                itemCount: _filteredLanguages.length,
                itemBuilder: (context, index) {
                  final item = _filteredLanguages[index];
                  return Column(
                    children: [
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(vertical: 8),
                        title: Text(item['name']!,
                            style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black)),
                        subtitle: Text(item['sub']!,
                            style: const TextStyle(
                                fontSize: 14, color: Colors.grey)),
                        onTap: () {
                          // 處理切換語言邏輯
                        },
                      ),
                      // 模擬原本無底線或自定義底線的效果
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}