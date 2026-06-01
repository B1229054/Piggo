import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../services/api_service.dart';
import 'package:image/image.dart' as img;

class CameraScreen extends StatefulWidget {
  final PageController pageController;
  final bool isTraveling;
  final int? ongoingTripId;
  final VoidCallback? onUploadSuccess;

  const CameraScreen({
    super.key,
    required this.pageController,
    required this.isTraveling,
    this.ongoingTripId,
    this.onUploadSuccess,
  });

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  String currentLocationName = '定位中...';
  double _currentLat = 0.0;
  double _currentLng = 0.0;
  CameraController? _cameraController;
  List<CameraDescription>? cameras;
  XFile? capturedImage;

  int _selectedCameraIndex = 0;
  FlashMode _flashMode = FlashMode.off;
  double _currentZoomLevel = 1.0;
  double _minZoomLevel = 1.0;
  double _maxZoomLevel = 1.0;
  double _baseZoomLevel = 1.0;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    await _initCamera();
    await _getCurrentLocation();
  }

  Future<void> _initCamera() async {
    try {
      cameras = await availableCameras();
      if (cameras != null && cameras!.isNotEmpty) {
        _cameraController = CameraController(
          cameras![_selectedCameraIndex],
          ResolutionPreset.veryHigh,
          enableAudio: false,
          imageFormatGroup: ImageFormatGroup.jpeg,
        );
        await _cameraController!.initialize();
        _maxZoomLevel = await _cameraController!.getMaxZoomLevel();
        _minZoomLevel = await _cameraController!.getMinZoomLevel();
        await _cameraController!.setFlashMode(_flashMode);
        if (mounted) setState(() {});
      }
    } catch (e) {
      debugPrint('相機初始化失敗: $e');
    }
  }

  Future<void> _toggleCamera() async {
    if (cameras == null || cameras!.length < 2) return;
    setState(() {
      _selectedCameraIndex = (_selectedCameraIndex + 1) % cameras!.length;
      capturedImage = null;
    });
    await _initCamera();
  }

  Future<void> _toggleFlash() async {
    if (_cameraController == null) return;
    FlashMode newMode;
    if (_flashMode == FlashMode.off) {
      newMode = FlashMode.auto;
    } else if (_flashMode == FlashMode.auto) {
      newMode = FlashMode.always;
    } else {
      newMode = FlashMode.off;
    }
    await _cameraController!.setFlashMode(newMode);
    setState(() => _flashMode = newMode);
  }

  Future<void> _getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );

        // 存經緯度
        _currentLat = position.latitude;
        _currentLng = position.longitude;

        await setLocaleIdentifier('zh_TW');

        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );

        if (placemarks.isNotEmpty) {
          Placemark place = placemarks[0];
          debugPrint('原始地址封包: $place');

          // 啟動華為繁體翻譯蒟蒻
          String city = place.subAdministrativeArea ?? place.locality ?? '';
          String district = place.locality ?? place.subLocality ?? '';

          String finalLocation = '$city $district'
              .replaceAll('桃园', '桃園')
              .replaceAll('龟山', '龜山')
              .replaceAll('区', '區')
              .replaceAll('台湾省', '')
              .trim();

          setState(() => currentLocationName = finalLocation);
        }
      }
    } catch (e) {
      debugPrint('⚠️ 定位錯誤原因: 無法取得真實地址');
    }
  }

  Future<void> _takePhoto() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized)
      return;
    try {
      final XFile photo = await _cameraController!.takePicture();
      setState(() => capturedImage = photo);

      if (widget.isTraveling) {
        _showShareDialog();
      } else {
        _resetCamera();
      }
    } catch (e) {
      debugPrint('拍照失敗: $e');
    }
  }

  void _resetCamera() {
    setState(() => capturedImage = null);
    _cameraController?.resumePreview();
  }

  // 1. 新增：獨立出來的「裁切與上傳」專屬處理中心
  Future<void> _processAndUploadPhoto({required bool isShared}) async {
    if (capturedImage == null) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        // 根據公開/私密顯示不同的提示字
        content: Text(isShared ? '正在分享照片給成員...' : '正在儲存為私人照片...'),
        duration: const Duration(seconds: 2),
      ),
    );

    try {
      // 1. 讀取原始照片位元組
      Uint8List originalBytes = await capturedImage!.readAsBytes();

      // 2. 進行 3:4 裁切處理
      img.Image? decodedImage = img.decodeImage(originalBytes);
      Uint8List finalBytes;

      if (decodedImage != null) {
        int targetWidth = decodedImage.width;
        int targetHeight = (targetWidth * 4) ~/ 3;

        if (targetHeight > decodedImage.height) {
          targetHeight = decodedImage.height;
          targetWidth = (targetHeight * 3) ~/ 4;
        }

        img.Image croppedImage = img.copyCrop(
          decodedImage,
          x: (decodedImage.width - targetWidth) ~/ 2,
          y: (decodedImage.height - targetHeight) ~/ 2,
          width: targetWidth,
          height: targetHeight,
        );
        finalBytes = Uint8List.fromList(img.encodeJpg(croppedImage));
      } else {
        finalBytes = originalBytes;
      }

      // 3. 呼叫 API 上傳
      bool isSuccess = await ApiService.uploadPhoto(
        currentLocationName == '定位中...' ? '' : currentLocationName,
        '阿明',
        finalBytes,
        capturedImage!.name,
        isShared: isShared, // 把按鈕傳來的 true 或 false 交給總機！
        lat: _currentLat,
        lng: _currentLng,
        takenAt: DateTime.now(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        if (isSuccess) {
          widget.onUploadSuccess?.call();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              // 根據結果顯示不同顏色的成功提示
              content: Text(isShared ? '分享成功！已加入行程相簿' : '儲存成功！已存為私人照片'),
              backgroundColor: isShared
                  ? const Color.fromARGB(255, 133, 200, 136)
                  : const Color.fromARGB(255, 130, 200, 186),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('上傳失敗，請檢查網路'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('連線失敗'), backgroundColor: Colors.red),
        );
      }
    }

    // 處理完畢後，重置相機準備拍下一張
    _resetCamera();
  }

  // 2. 修改後的：超乾淨對話框
  void _showShareDialog() {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (dialogContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '要分享給成員嗎？',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(dialogContext); // 關閉對話框
                        _processAndUploadPhoto(
                          isShared: false,
                        ); // 呼叫上傳，設定為私密 (false)！
                      },
                      child: const Text(
                        '不公開 (僅自己可見)',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFA2AED8), // 配上你的專屬紫色
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () {
                        Navigator.pop(dialogContext); // 關閉對話框
                        _processAndUploadPhoto(
                          isShared: true,
                        ); // 呼叫上傳，設定為公開 (true)！
                      },
                      child: const Text('分享給成員'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  IconData _getFlashIcon() {
    switch (_flashMode) {
      case FlashMode.auto:
        return Icons.flash_auto;
      case FlashMode.always:
        return Icons.flash_on;
      case FlashMode.off:
      default:
        return Icons.flash_off;
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            // 頂部：地點按鈕
            Padding(
              padding: const EdgeInsets.only(top: 12.0, bottom: 8.0),
              child: Center(
                child: GestureDetector(
                  onTap: () {
                    debugPrint('點擊了地點標籤');
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFA2AED8),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min, // 讓寬度跟著內容縮放
                      children: [
                        const Icon(
                          Icons.location_on,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          currentLocationName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // 觀景窗：強制 3:4 比例，放大並向上靠攏
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Center(
                  child: AspectRatio(
                    aspectRatio: 3 / 4,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Container(
                            color: Colors.black,
                            child: capturedImage != null
                                ? (kIsWeb
                                      ? Image.network(
                                          capturedImage!.path,
                                          fit: BoxFit.cover,
                                        )
                                      : Image.file(
                                          File(capturedImage!.path),
                                          fit: BoxFit.cover,
                                        ))
                                : (_cameraController != null &&
                                      _cameraController!.value.isInitialized)
                                ? Builder(
                                    builder: (context) {
                                      // 防呆：強制將感光元件比例校正為「直立」
                                      double cameraAspect =
                                          _cameraController!.value.aspectRatio;
                                      if (cameraAspect > 1.0) {
                                        cameraAspect = 1.0 / cameraAspect;
                                      }

                                      return GestureDetector(
                                        // 防誤觸盾牌：攔截橫向滑動
                                        onHorizontalDragStart: (_) {},

                                        onScaleStart: (details) =>
                                            _baseZoomLevel = _currentZoomLevel,
                                        onScaleUpdate: (details) async {
                                          if (_cameraController == null) return;
                                          double newZoom =
                                              (_baseZoomLevel * details.scale)
                                                  .clamp(
                                                    _minZoomLevel,
                                                    _maxZoomLevel,
                                                  );
                                          if (newZoom != _currentZoomLevel) {
                                            setState(
                                              () => _currentZoomLevel = newZoom,
                                            );
                                            await _cameraController!
                                                .setZoomLevel(
                                                  _currentZoomLevel,
                                                );
                                          }
                                        },
                                        child: ClipRect(
                                          child: FittedBox(
                                            fit: BoxFit.cover,
                                            child: SizedBox(
                                              // 套用校正過後的直立比例
                                              width: cameraAspect,
                                              height: 1.0,
                                              child: CameraPreview(
                                                _cameraController!,
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  )
                                : const Center(
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                    ),
                                  ),
                          ),

                          if (capturedImage == null)
                            Positioned(
                              top: 16,
                              left: 16,
                              child: GestureDetector(
                                onTap: _toggleFlash,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.black38,
                                  ),
                                  child: Icon(
                                    _getFlashIcon(),
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),

                          if (capturedImage == null)
                            Positioned(
                              top: 16,
                              right: 16,
                              child: GestureDetector(
                                onTap: () async {
                                  if (_cameraController != null) {
                                    await _cameraController!.setZoomLevel(
                                      _minZoomLevel,
                                    );
                                    setState(
                                      () => _currentZoomLevel = _minZoomLevel,
                                    );
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black38,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    '${_currentZoomLevel.toStringAsFixed(1)}X',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // 底部群組：相簿、快門、翻轉
            Padding(
              padding: const EdgeInsets.only(
                top: 16.0,
                bottom: 32.0,
                left: 32.0,
                right: 32.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.photo_library_outlined,
                      color: Colors.black54,
                      size: 32,
                    ),
                    onPressed: () {
                      widget.pageController.animateToPage(
                        0,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                  ),

                  GestureDetector(
                    onTap: _takePhoto,
                    child: Container(
                      height: 72,
                      width: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFA2AED8),
                          width: 4,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Container(
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFFA2AED8),
                          ),
                        ),
                      ),
                    ),
                  ),

                  IconButton(
                    icon: const Icon(
                      Icons.cameraswitch_outlined,
                      color: Colors.black54,
                      size: 32,
                    ),
                    onPressed: _toggleCamera,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
