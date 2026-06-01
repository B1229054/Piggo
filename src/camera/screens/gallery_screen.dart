import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import '../services/api_service.dart';
import '../models/trip_photo.dart';
import 'photo_detail_screen.dart';

class GalleryScreen extends StatefulWidget {
  final PageController pageController;
  final bool isTraveling;
  // 從首頁傳入正在進行的行程 ID (若沒有則為 null)
  final int? currentOngoingTripId;

  const GalleryScreen({
    super.key,
    required this.pageController,
    required this.isTraveling,
    this.currentOngoingTripId,
  });

  @override
  State<GalleryScreen> createState() => GalleryScreenState();
}

class GalleryScreenState extends State<GalleryScreen> {
  final ImagePicker _picker = ImagePicker();

  // 存放從資料庫抓回來的真實照片
  List<TripPhoto> _photos = [];
  bool _isLoading = true;

  final Map<String, int?> _personalAlbum = {'我的相簿 (私人)': null};
  Map<String, int> _ongoingTrips = {}; // 正在進行的旅行
  Map<String, int> _completedTrips = {}; // 已完成或未來的行程

  late String currentAlbum = '我的相簿 (私人)';
  int? currentTripId; // 記錄目前選中的行程 ID

  @override
  void initState() {
    super.initState();
    // 進入畫面時，先去抓真實的行程清單！
    _loadUserTrips();
  }

  // 向後端抓取行程，並依照時間智慧分類
  Future<void> _loadUserTrips() async {
    setState(() => _isLoading = true);
    try {
      final trips = await ApiService.getUserTrips(1); // 假設目前 User ID 為 1
      final now = DateTime.now();

      Map<String, int> newOngoing = {};
      Map<String, int> newCompleted = {};

      for (var trip in trips) {
        // 依照你資料庫的定義，使用 'title'
        String tripTitle = trip['title'] ?? '未命名行程';
        int id = trip['id'];

        // 解析時間
        DateTime startDate = DateTime.parse(trip['start_date']);
        // 結束日加上寬限時間，確保包含當天
        DateTime endDate = DateTime.parse(
          trip['end_date'],
        ).add(const Duration(hours: 23, minutes: 59));

        // 判斷是否正在旅行中
        if (now.isAfter(startDate) && now.isBefore(endDate)) {
          newOngoing[tripTitle] = id;
        } else {
          newCompleted[tripTitle] = id;
        }
      }

      setState(() {
        _ongoingTrips = newOngoing;
        _completedTrips = newCompleted;

        // 智慧跳轉：若有進行中的旅行就選它，否則選我的相簿
        if (_ongoingTrips.isNotEmpty) {
          currentAlbum = _ongoingTrips.keys.first;
          currentTripId = _ongoingTrips.values.first;
        } else {
          currentAlbum = '我的相簿 (私人)';
          currentTripId = null;
        }
      });

      await fetchPhotos();
    } catch (e) {
      debugPrint('載入行程相簿失敗: $e');
      setState(() => _isLoading = false);
    }
  }

  // 根據選取的模式（情境一或情境三）抓取照片
  Future<void> fetchPhotos() async {
    setState(() => _isLoading = true);

    try {
      // 若是私人相簿則用 all_mine，否則用 trip_view (含公開+自己私有)
      String mode = (currentAlbum == '我的相簿 (私人)') ? 'all_mine' : 'trip_view';

      List<TripPhoto> fetchedPhotos = await ApiService.fetchPhotos(
        mode: mode,
        userId: 1,
        tripId: currentTripId,
      );

      setState(() {
        _photos = fetchedPhotos;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('抓取照片失敗: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImageFromPhone() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('照片上傳中...')));
        Uint8List imageBytes = await image.readAsBytes();

        bool isSuccess = await ApiService.uploadPhoto(
          '',
          '阿明',
          imageBytes,
          image.name,
          isShared: false, // 預設不公開
        );

        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          if (isSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('✅ 已存入私人相簿'),
                backgroundColor: Colors.green,
              ),
            );
            fetchPhotos();
          }
        }
      }
    } catch (e) {
      debugPrint('選取出錯: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 198, 208, 240),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 246, 248, 255),
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(
            Icons.add_photo_alternate_outlined,
            color: Color(0xFFA2AED8),
            size: 28,
          ),
          onPressed: _pickImageFromPhone,
        ),
        title: PopupMenuButton<String>(
          onSelected: (String newValue) {
            if (currentAlbum != newValue) {
              setState(() {
                currentAlbum = newValue;
                if (_personalAlbum.containsKey(newValue)) {
                  currentTripId = _personalAlbum[newValue];
                } else if (_ongoingTrips.containsKey(newValue)) {
                  currentTripId = _ongoingTrips[newValue];
                } else if (_completedTrips.containsKey(newValue)) {
                  currentTripId = _completedTrips[newValue];
                }
              });
              fetchPhotos();
            }
          },
          itemBuilder: (BuildContext context) {
            List<PopupMenuEntry<String>> menuItems = [];
            menuItems.add(
              const PopupMenuItem(value: '我的相簿 (私人)', child: Text('我的相簿 (私人)')),
            );

            if (_ongoingTrips.isNotEmpty) {
              menuItems.add(const PopupMenuDivider());
              menuItems.add(
                const PopupMenuItem(
                  enabled: false,
                  child: Text(
                    '正在進行的旅行',
                    style: TextStyle(color: Colors.grey, fontSize: 8),
                  ),
                ),
              );
              for (var name in _ongoingTrips.keys) {
                menuItems.add(PopupMenuItem(value: name, child: Text(name)));
              }
            }

            if (_completedTrips.isNotEmpty) {
              menuItems.add(const PopupMenuDivider());
              menuItems.add(
                const PopupMenuItem(
                  enabled: false,
                  child: Text(
                    '其他行程紀錄',
                    style: TextStyle(color: Colors.grey, fontSize: 8),
                  ),
                ),
              );
              for (var name in _completedTrips.keys) {
                menuItems.add(PopupMenuItem(value: name, child: Text(name)));
              }
            }
            return menuItems;
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                currentAlbum,
                style: const TextStyle(
                  color: Color(0xFFA2AED8),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Icon(
                Icons.keyboard_arrow_down,
                color: Color(0xFFA2AED8),
                size: 24,
              ),
            ],
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios, color: Color(0xFFA2AED8)),
            onPressed: () => widget.pageController.animateToPage(
              1,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _photos.isEmpty
          ? RefreshIndicator(
              onRefresh: fetchPhotos,
              child: ListView(
                children: const [
                  SizedBox(height: 200),
                  Center(child: Text('這裡還沒有照片喔！')),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: fetchPhotos,
              child: GridView.builder(
                padding: const EdgeInsets.all(8),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: _photos.length,
                itemBuilder: (context, index) {
                  final photo = _photos[index];
                  return GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PhotoDetailScreen(
                          photos: _photos,
                          initialIndex: index,
                        ),
                      ),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        image: DecorationImage(
                          image: NetworkImage(photo.imageUrl),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
