import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:gal/gal.dart';
import '../models/trip_photo.dart';

class PhotoDetailScreen extends StatelessWidget {
  final List<TripPhoto> photos;
  final int initialIndex;

  const PhotoDetailScreen({
    super.key,
    required this.photos,
    required this.initialIndex,
  });

  // 1. 智慧時間轉換器 (處理今天、昨天、前天)
  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    // 抹除時間，只比對「日期」
    final today = DateTime(now.year, now.month, now.day);
    final targetDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    final difference = today.difference(targetDate).inDays;

    // 格式化時間為 HH:mm (例如 14:05)
    String timeStr =
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';

    if (difference == 0) {
      return timeStr; // 今天只顯示時間
    } else if (difference == 1) {
      return '昨天 $timeStr';
    } else if (difference == 2) {
      return '前天 $timeStr';
    } else {
      return '${dateTime.month}/${dateTime.day} $timeStr'; // 更久以前才顯示日期
    }
  }

  // 2. 儲存照片到手機相簿
  Future<void> _savePhoto(BuildContext context, String imageUrl) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('下載中，請稍候...'),
          duration: Duration(seconds: 1),
        ),
      );

      // A. 下載圖片變成位元組 (Bytes)
      var response = await http.get(Uri.parse(imageUrl));
      final bytes = response.bodyBytes;

      // B. 檢查相簿權限 (Gal 套件內建超方便的權限管理)
      bool hasAccess = await Gal.hasAccess();
      if (!hasAccess) {
        await Gal.requestAccess();
      }

      // C. 存進手機相簿
      await Gal.putImageBytes(
        bytes,
        name: "piggo_${DateTime.now().millisecondsSinceEpoch}",
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('已成功儲存至手機相簿！'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('下載發生錯誤或權限被拒絕'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 137, 140, 172),
      body: SafeArea(
        child: PageView.builder(
          scrollDirection: Axis.vertical,
          controller: PageController(initialPage: initialIndex),
          itemCount: photos.length,
          itemBuilder: (context, index) {
            final photo = photos[index];

            // 防呆：確認是否有地點名稱 (排除空字串或預設的未知地點)
            bool hasLocation =
                photo.locationName.trim().isNotEmpty &&
                photo.locationName != '未知地點' &&
                photo.locationName != 'null';

            // 使用這個更乾淨、優雅的顏色：紫色代碼 Color(0xFFA2AED8)
            const appPurple = Color(0xFFA2AED8);

            return Column(
              children: [
                // --- 頂部列 ---
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // 左側關閉按鈕
                      Align(
                        alignment: Alignment.centerLeft,
                        child: IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                    ],
                  ),
                ),

                // --- 1. 新位置：地點資訊區 (置中在照片外的上面，底為紫色) ---
                if (hasLocation)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 20.0,
                    ), // 增加上下間距
                    child: Align(
                      alignment: Alignment.center, // 水平置中
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8, // 內間距
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white, // 白底
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.location_on,
                              color: appPurple,
                              size: 14,
                            ),
                            const SizedBox(width: 8), // 增加與文字間距
                            Text(
                              photo.locationName,
                              style: const TextStyle(
                                color: appPurple,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                // --- 2. 照片顯示區 (3:4，靠中偏上) ---
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    // 垂直方向稍向上推 (0.0 是水平置中, -0.4 是垂直偏上)
                    child: Align(
                      alignment: const Alignment(0.0, -1.2),
                      child: AspectRatio(
                        aspectRatio: 3 / 4, // 強制 3:4 比例
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(32),
                          child: Image.network(
                            photo.imageUrl,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // --- 底部資訊與互動區 ---
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        backgroundImage: NetworkImage(
                          'https://picsum.photos/100', // 發文者大頭貼
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            photo.userName, // 照片發布者
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          // 智慧時間格式
                          Text(
                            _formatDateTime(photo.takenAt),
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      // 儲存照片按鈕
                      IconButton(
                        icon: const Icon(
                          Icons.download_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                        onPressed: () => _savePhoto(context, photo.imageUrl),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
