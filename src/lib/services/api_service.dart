import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../models/user.dart'; // 你的 User Model
import '../models/trip_photo.dart';

class ApiService {
  static const String baseUrl = 'http://172.20.10.3:3000/api';

  // ==========================================
  // 1. 取得使用者資料 API
  // ==========================================
  static Future<User?> getUserProfile(int userId) async {
    try {
      final url = Uri.parse('$baseUrl/users/$userId');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        return User.fromJson(jsonResponse);
      } else {
        debugPrint('取得失敗，狀態碼：${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('網路發生錯誤：$e');
      return null;
    }
  }

  // ==========================================
  // 2. 上傳照片 API
  // ==========================================
  static Future<bool> uploadPhoto(
    String albumName,
    String userName,
    Uint8List imageBytes,
    String filename, {
    double? lat,
    double? lng,
    DateTime? takenAt,
    bool isShared = true,
  }) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/upload'));

      // 告訴後端這是哪種照片 (對應你的 if/else 邏輯)
      request.fields['uploadType'] = 'trip_photo';

      // 告訴後端這是誰傳的、傳到哪個行程 (這裡先寫死假資料，未來可以從 App 狀態管理拿)
      request.fields['userId'] = '1';
      request.fields['tripId'] = '1';
      request.fields['locationName'] = albumName;
      request.fields['is_shared'] = isShared ? '1' : '0'; // 確保傳遞給資料庫的格式正確
      request.fields['lat'] = lat?.toString() ?? '';
      request.fields['lng'] = lng?.toString() ?? '';
      request.fields['taken_at'] =
          takenAt?.toIso8601String() ?? DateTime.now().toIso8601String();

      request.files.add(
        http.MultipartFile.fromBytes('photo', imageBytes, filename: filename),
      );

      debugPrint('準備發送上傳請求給 S3 總機...');
      var response = await request.send();

      // 把後端回傳的 JSON 印出來看
      if (response.statusCode == 200) {
        var responseData = await response.stream.bytesToString();
        debugPrint('✅ 上傳成功！後端回傳: $responseData');
        return true;
      } else {
        debugPrint('❌ 上傳失敗，狀態碼: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      debugPrint('⚠️ API 連線錯誤: $e');
      return false;
    }
  }

  // ==========================================
  // 3. 取得行程清單 API
  // ==========================================
  static Future<List<Map<String, dynamic>>> getUserTrips(int userId) async {
    try {
      final url = Uri.parse('$baseUrl/upload/trips/user/$userId');
      debugPrint('[行程清單] 準備發送請求到: $url');

      final response = await http.get(url);
      debugPrint('[行程清單] 後端狀態碼: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return List<Map<String, dynamic>>.from(data['data']);
        }
      }
    } catch (e) {
      debugPrint('🚨 [行程清單] 發生致命錯誤: $e');
    }
    return []; // 如果上面任何一步失敗，就會回傳空陣列
  }

  // ==========================================
  // 4. 取得相簿照片 API
  // ==========================================
  static Future<List<TripPhoto>> fetchPhotos({
    required String mode,
    required int userId,
    int? tripId,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/upload/photos').replace(
        queryParameters: {
          'mode': mode,
          'userId': userId.toString(),
          'tripId': tripId?.toString() ?? '',
        },
      );

      debugPrint('[抓取照片] 發送請求: $url');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['success'] == true) {
          return (data['data'] as List)
              .map((p) => TripPhoto.fromJson(p))
              .toList();
        } else {
          throw Exception(data['message']);
        }
      } else {
        throw Exception('伺服器錯誤: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('🚨 [抓取照片] 失敗: $e');
      rethrow;
    }
  }
}
