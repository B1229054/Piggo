import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

class LocationSearchScreen extends StatefulWidget {
  const LocationSearchScreen({super.key});

  @override
  State<LocationSearchScreen> createState() => _LocationSearchScreenState();
}

class _LocationSearchScreenState extends State<LocationSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  
  // Google Maps API Key
  final String _apiKey = ""; 
  
  List<Map<String, String>> _locations = [];
  bool _isLoading = true;
  Position? _currentPosition;
  Timer? _debounce; // 用來防止打字太快一直狂發API請求

  @override
  void initState() {
    super.initState();
    _initLocationAndFetchNearby();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  // 取得目前定位，並呼叫附近地點API
  Future<void> _initLocationAndFetchNearby() async {
    setState(() => _isLoading = true);
    
    // 檢查並要求定位權限
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) return;

    // 取得經緯度
    _currentPosition = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
    
    // 抓取附近地點
    await _fetchNearbyPlaces(_currentPosition!);
  }

  // 2. 呼叫Google Places Nearby Search API (抓附近地點)
  Future<void> _fetchNearbyPlaces(Position pos) async {
    final url = 'https://maps.googleapis.com/maps/api/place/nearbysearch/json?'
        'location=${pos.latitude},${pos.longitude}&radius=1500&language=zh-TW&key=$_apiKey';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          setState(() {
            _locations = (data['results'] as List).map((place) {
              return {
                "name": place['name'] as String,
                "address": place['vicinity'] as String? ?? '附近地點',
              };
            }).toList();
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint("抓取附近地點失敗: $e");
      setState(() => _isLoading = false);
    }
  }

  // 3. 呼叫 Google Places Autocomplete API (搜尋關鍵字地點)
  Future<void> _fetchAutocomplete(String query) async {
    if (query.isEmpty) {
      if (_currentPosition != null) _fetchNearbyPlaces(_currentPosition!);
      return;
    }

    setState(() => _isLoading = true);

    // 如果有定位，可以讓搜尋結果偏向目前位置附近
    String locationParam = _currentPosition != null 
        ? '&location=${_currentPosition!.latitude},${_currentPosition!.longitude}&radius=50000' 
        : '';

    final url = 'https://maps.googleapis.com/maps/api/place/autocomplete/json?'
        'input=$query$locationParam&language=zh-TW&key=$_apiKey';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          setState(() {
            _locations = (data['predictions'] as List).map((place) {
              return {
                "name": place['structured_formatting']['main_text'] as String,
                "address": place['structured_formatting']['secondary_text'] as String? ?? '',
              };
            }).toList();
            _isLoading = false;
          });
        } else {
          setState(() => _isLoading = false);
        }
      }
    } catch (e) {
      debugPrint("搜尋地點失敗: $e");
      setState(() => _isLoading = false);
    }
  }

  // 搜尋框輸入變更時觸發 (用Debounce防抖，避免打一個字發一次API浪費錢)
  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _fetchAutocomplete(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const SizedBox(), 
        title: const Text('地點', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消', style: TextStyle(color: Color(0xFF007AFF), fontSize: 16)),
          )
        ],
      ),
      body: Column(
        children: [
          // 搜尋框
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFF2F2F2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged, 
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: '搜尋或輸入自訂地點...',
                  prefixIcon: Icon(Icons.search, color: Colors.grey),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ),
          
          // 列表內容
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF007AFF))) // 讀取中轉圈圈
              : ListView.builder(
                  itemCount: _searchController.text.isNotEmpty 
                      ? _locations.length + 1 
                      : _locations.length,
                  itemBuilder: (context, index) {
                    
                    // 永遠把「手動輸入」放在搜尋結果的第一筆
                    if (_searchController.text.isNotEmpty && index == 0) {
                      return ListTile(
                        leading: const Icon(Icons.add_location_alt, color: Color(0xFF007AFF)),
                        title: Text(
                          '使用自訂地點："${_searchController.text}"', 
                          style: const TextStyle(color: Color(0xFF007AFF), fontWeight: FontWeight.bold),
                        ),
                        onTap: () {
                          Navigator.pop(context, _searchController.text);
                        },
                      );
                    }

                    final dataIndex = _searchController.text.isNotEmpty ? index - 1 : index;
                    final loc = _locations[dataIndex];
                    
                    return ListTile(
                      leading: const Icon(Icons.location_on_outlined, color: Colors.grey),
                      title: Text(loc["name"]!, style: const TextStyle(fontWeight: FontWeight.w500)),
                      subtitle: loc["address"]!.isNotEmpty 
                          ? Text(loc["address"]!, style: const TextStyle(color: Colors.grey, fontSize: 12)) 
                          : null,
                      onTap: () {
                        // 點選 API 回傳的地點
                        Navigator.pop(context, loc["name"]);
                      },
                    );
                  },
                ),
          ),
        ],
      ),
    );
  }
}
