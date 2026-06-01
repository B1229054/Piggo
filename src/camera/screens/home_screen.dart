import 'package:flutter/material.dart';
import 'camera_screen.dart';
import 'gallery_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PageController _pageController = PageController(initialPage: 1);
  bool isTraveling = true;
  int? ongoingTripId = 1;

  // 建立專線：GlobalKey
  final GlobalKey<GalleryScreenState> _galleryKey = GlobalKey();

  // 通報函數：當相機說上傳成功時，大總管就撥專線叫相簿更新
  void _handleUploadSuccess() {
    _galleryKey.currentState?.fetchPhotos();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        children: [
          GalleryScreen(
            key: _galleryKey, // 把專線接上
            pageController: _pageController,
            isTraveling: isTraveling,
            currentOngoingTripId: ongoingTripId,
          ),
          CameraScreen(
            pageController: _pageController,
            isTraveling: isTraveling,
            ongoingTripId: ongoingTripId,
            onUploadSuccess: _handleUploadSuccess, // 把通報函數交給相機
          ),
        ],
      ),
    );
  }
}
