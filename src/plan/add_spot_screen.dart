// 
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'plan_provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:google_polyline_algorithm/google_polyline_algorithm.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'dart:math' as math;

class AddSpotScreen extends StatefulWidget {
  final String planId;
  final String day;
  const AddSpotScreen({super.key, required this.planId, required this.day});

  @override
  State<AddSpotScreen> createState() => _AddSpotScreenState();
}

class _AddSpotScreenState extends State<AddSpotScreen> {
  GoogleMapController? _mapController;
  final TextEditingController _searchCtrl = TextEditingController();
  final PageController _pageController = PageController(viewportFraction: 0.88);

  // 🛑 請在這裡填入你的 Google API Key
  final String _googleApiKey = 'A'; 

  bool _isSearching = false;
  List<dynamic> _results = [];
  Map<String, dynamic>? _selectedLocation;
  
  List<dynamic> _existingSpots = [];
  List<Map<String, dynamic>> _insertionOptions = [];
  int _selectedInsertIndex = 0;
  List<LatLng> _initialRoutePoints = [];
  List<LatLng> _newRoutePoints = [];
  String _travelTimeText = "計算中...";

  int _stayHour = 1; 
  int _stayMinute = 0;
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  bool _isFirstSpot = false;

  Map<String, BitmapDescriptor> _customIcons = {};

  @override
  void initState() {
    super.initState();
    _initCustomMarkers().then((_) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadAllData());
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _initCustomMarkers() async {
    for (int i = 1; i <= 10; i++) {
      _customIcons['old_$i'] = await _createCircularMarker('$i', const Color(0xFF6CA6CC));
    }
    _customIcons['new'] = await _createCircularMarker('新', const Color(0xFFFFB6B9));
    setState(() {});
  }

  Future<BitmapDescriptor> _createCircularMarker(String text, Color bgColor) async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    final Paint paint = Paint()..color = bgColor;
    const double size = 80.0;
    
    canvas.drawCircle(const Offset(size / 2, size / 2), size / 2, paint);
    canvas.drawCircle(const Offset(size / 2, size / 2), size / 2, Paint()..color=Colors.white..style=PaintingStyle.stroke..strokeWidth=4);

    final TextPainter painter = TextPainter(textDirection: TextDirection.ltr);
    painter.text = TextSpan(text: text, style: const TextStyle(fontSize: 35, color: Colors.white, fontWeight: FontWeight.bold));
    painter.layout();
    painter.paint(canvas, Offset((size - painter.width) / 2, (size - painter.height) / 2));

    final ui.Image img = await pictureRecorder.endRecording().toImage(size.toInt(), size.toInt());
    final ByteData? data = await img.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.fromBytes(data!.buffer.asUint8List());
  }

  Future<void> _loadAllData() async {
    final itinerary = Provider.of<PlanProvider>(context, listen: false).getItinerary(widget.planId);
    final dayData = itinerary.firstWhere((d) => d['day'].toString().toUpperCase().replaceAll(' ', '') == widget.day.toUpperCase().replaceAll(' ', ''), orElse: () => <String, dynamic>{'day': widget.day, 'items': []});
    
    List<dynamic> spots = List.from(dayData['items'] ?? []);
    setState(() => _existingSpots = spots);

    if (_existingSpots.length > 1) {
      List<LatLng> pts = [];
      for (int i = 0; i < _existingSpots.length - 1; i++) {
        final url = 'https://maps.googleapis.com/maps/api/directions/json?origin=${_existingSpots[i]['coordinate']['lat']},${_existingSpots[i]['coordinate']['lng']}&destination=${_existingSpots[i+1]['coordinate']['lat']},${_existingSpots[i+1]['coordinate']['lng']}&key=$_googleApiKey&language=zh-TW';
        try {
          final res = await http.get(Uri.parse(url));
          final data = json.decode(res.body);
          if (data['status'] == 'OK') {
            pts.addAll(decodePolyline(data['routes'][0]['overview_polyline']['points']).map((c) => LatLng(c.first.toDouble(), c.last.toDouble())).toList());
          }
        } catch (e) {}
      }
      setState(() => _initialRoutePoints = pts);
    }
  }

  // 🔥 終極二合一智慧選點：點擊馬路時，先去找這個號碼是不是知名景點，才傳回來！
  void _handleMapTap(LatLng latlng) async {
    setState(() { 
      _isSearching = false; 
      _selectedLocation = {'title': '地標精確偵測中...', 'coordinate': {'lat': latlng.latitude, 'lng': latlng.longitude}}; 
    });
    
    // 1. 先用 Geocoding 抓取該點底下的所有圖資
    final geocodeUrl = 'https://maps.googleapis.com/maps/api/geocode/json?latlng=${latlng.latitude},${latlng.longitude}&key=$_googleApiKey&language=zh-TW';
    
    try {
      final res = await http.get(Uri.parse(geocodeUrl));
      final data = json.decode(res.body);
      
      if (data['status'] == 'OK' && (data['results'] as List).isNotEmpty) {
        final results = data['results'] as List;
        String? targetPlaceId;

        // 預設的備用乾淨地址（防門牌）
        String fullAddress = results[0]['formatted_address'] ?? '自選地點';
        String fallbackAddress = fullAddress.replaceAll(RegExp(r'^\d+'), '').replaceAll('台灣', '').trim();

        // 2. 檢查地號清單中，有沒有包含「店家/景點/地標」的身分證 (Place ID)
        for (var result in results) {
          List types = result['types'] ?? [];
          if (types.contains('point_of_interest') || types.contains('establishment') || types.contains('tourist_attraction')) {
            targetPlaceId = result['place_id'];
            break;
          }
        }

        // 3. 關鍵魔法：如果有找到景點身分證，立刻用 Places Details API 去把真正的「地標店家名」抓回來！
        if (targetPlaceId != null) {
          final detailsUrl = 'https://maps.googleapis.com/maps/api/place/details/json?place_id=$targetPlaceId&key=$_googleApiKey&language=zh-TW';
          final detailsRes = await http.get(Uri.parse(detailsUrl));
          final detailsData = json.decode(detailsRes.body);
          
          if (detailsData['status'] == 'OK' && detailsData['result'] != null) {
            String realName = detailsData['result']['name'] ?? fallbackAddress;
            setState(() { _selectedLocation!['title'] = realName; });
            _generateOptions();
            return; // 成功解析出景點名，直接收工
          }
        }

        // 4. 第二備案：如果地標太新，改用 Nearby Search 抓方圓 50 公尺內最知名的地方
        final nearbyUrl = 'https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=${latlng.latitude},${latlng.longitude}&radius=50&language=zh-TW&key=$_googleApiKey';
        final nearbyRes = await http.get(Uri.parse(nearbyUrl));
        final nearbyData = json.decode(nearbyRes.body);
        
        if (nearbyData['status'] == 'OK' && (nearbyData['results'] as List).isNotEmpty) {
          String nearbyName = nearbyData['results'][0]['name'] ?? fallbackAddress;
          setState(() { _selectedLocation!['title'] = nearbyName; });
        } else {
          setState(() { _selectedLocation!['title'] = fallbackAddress; });
        }
      } else {
        setState(() { _selectedLocation!['title'] = '自選地點'; });
      }
    } catch (e) {
      setState(() { _selectedLocation!['title'] = '自選地點'; });
    }
    _generateOptions();
  }

  Future<void> _handleSearch(String t) async {
    if (t.isEmpty) { setState(() { _results = []; _isSearching = false; }); return; }
    final url = 'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$t&key=$_googleApiKey&language=zh-TW&components=country:tw';
    try {
      final res = await http.get(Uri.parse(url));
      final data = json.decode(res.body);
      if (data['status'] == 'OK') {
        setState(() { _isSearching = true; _results = data['predictions']; });
      } else {
        setState(() { _isSearching = true; _results = [{'description': '⚠️ API 錯誤: ${data['status']}'}]; });
      }
    } catch (e) {
      setState(() { _isSearching = true; _results = [{'description': '網路錯誤: $e'}]; });
    }
  }

  void _onSearchItemTap(dynamic p) async {
    if (p['place_id'] == null) return; 
    FocusScope.of(context).unfocus();
    final url = 'https://maps.googleapis.com/maps/api/place/details/json?place_id=${p['place_id']}&key=$_googleApiKey&language=zh-TW';
    final res = await http.get(Uri.parse(url));
    final data = json.decode(res.body);
    if (data['status'] == 'OK') {
      final loc = data['result']['geometry']['location'];
      final name = data['result']['name']; 
      setState(() {
        _isSearching = false; _results = []; _searchCtrl.text = name;
        _selectedLocation = {'title': name, 'coordinate': {'lat': loc['lat'], 'lng': loc['lng']}};
      });
      _mapController?.animateCamera(CameraUpdate.newLatLngZoom(LatLng(loc['lat'], loc['lng']), 15));
      _generateOptions();
    }
  }

  double _getDistance(double lat1, double lng1, double lat2, double lng2) {
    var p = 0.017453292519943295;
    var a = 0.5 - math.cos((lat2 - lat1) * p) / 2 + math.cos(lat1 * p) * math.cos(lat2 * p) * (1 - math.cos((lng2 - lng1) * p)) / 2;
    return 12742 * math.asin(math.sqrt(a));
  }

  void _generateOptions() {
    _insertionOptions = [];
    if (_existingSpots.isEmpty) {
      _insertionOptions.add({'label': '今天第一個景點', 'index': 0, 'prev': null});
    } else {
      _insertionOptions.add({'label': '排在最前面', 'index': 0, 'prev': null});
      for (int i = 0; i < _existingSpots.length; i++) {
        _insertionOptions.add({'label': i == _existingSpots.length - 1 ? '排在最後' : '插在中間', 'index': i + 1, 'prev': _existingSpots[i], 'prevNum': i + 1});
      }
    }

    // 🌟 最短車程智慧推薦：找出跟上一站地理直線距離最短的最佳插入排程卡片
    int bestIndex = _insertionOptions.length - 1; 
    if (_insertionOptions.length > 1 && _selectedLocation != null) {
      double minDistance = double.infinity;
      for (int i = 0; i < _insertionOptions.length; i++) {
        final opt = _insertionOptions[i];
        if (opt['prev'] != null) {
          double dist = _getDistance(
            _selectedLocation!['coordinate']['lat'], _selectedLocation!['coordinate']['lng'],
            opt['prev']['coordinate']['lat'], opt['prev']['coordinate']['lng']
          );
          if (dist < minDistance) {
            minDistance = dist;
            bestIndex = i;
          }
        }
      }
    }

    setState(() { 
      _selectedInsertIndex = bestIndex; 
      _isFirstSpot = _selectedInsertIndex == 0; 
    });
    
    // 讓底部的 PageView 直接跳到我們算出的「最順路、路程最短」的那張卡片上！
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_pageController.hasClients) {
        _pageController.jumpToPage(bestIndex);
      }
    });
    
    _updatePreviewRoute();
  }

  Future<void> _updatePreviewRoute() async {
    if (_selectedLocation == null) return;
    final opt = _insertionOptions[_selectedInsertIndex];
    if (opt['prev'] == null) { setState(() { _newRoutePoints = []; _travelTimeText = "第一站"; }); return; }
    
    final s = LatLng(opt['prev']['coordinate']['lat'], opt['prev']['coordinate']['lng']);
    final e = LatLng(_selectedLocation!['coordinate']['lat'], _selectedLocation!['coordinate']['lng']);
    final url = 'https://maps.googleapis.com/maps/api/directions/json?origin=${s.latitude},${s.longitude}&destination=${e.latitude},${e.longitude}&key=$_googleApiKey&language=zh-TW';
    final res = await http.get(Uri.parse(url));
    final data = json.decode(res.body);
    if (data['status'] == 'OK') {
      setState(() {
        _newRoutePoints = decodePolyline(data['routes'][0]['overview_polyline']['points']).map((c) => LatLng(c.first.toDouble(), c.last.toDouble())).toList();
        _travelTimeText = "車程約 ${data['routes'][0]['legs'][0]['duration']['text']}";
      });
    }
  }

  void _confirmSave() {
    if (_selectedLocation == null) return;
    String cleanTravelTime = _travelTimeText.replaceAll('車程約 ', '');

    Provider.of<PlanProvider>(context, listen: false).addItineraryItem(
      widget.planId, widget.day,
      {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'type': 'activity', 
        'title': _selectedLocation!['title'], 
        'coordinate': _selectedLocation!['coordinate'],
        'durationValue': _stayHour * 60 + _stayMinute,
        'travelTime': cleanTravelTime,
        'transportMode': 'driving',
      },
      _insertionOptions[_selectedInsertIndex]['index']
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    Set<Marker> markers = {};
    
    for (int i = 0; i < _existingSpots.length; i++) {
      if (_customIcons.containsKey('old_${i+1}')) {
        markers.add(Marker(
          markerId: MarkerId('old_$i'), 
          position: LatLng(_existingSpots[i]['coordinate']['lat'], _existingSpots[i]['coordinate']['lng']), 
          icon: _customIcons['old_${i+1}']!, 
          infoWindow: InfoWindow(title: '${i+1}. ${_existingSpots[i]['title']}')
        ));
      }
    }
    
    if (_selectedLocation != null && _customIcons.containsKey('new')) {
      markers.add(Marker(
        markerId: const MarkerId('new'), 
        position: LatLng(_selectedLocation!['coordinate']['lat'], _selectedLocation!['coordinate']['lng']), 
        icon: _customIcons['new']!,
        infoWindow: InfoWindow(title: _selectedLocation!['title'])
      ));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('加入行程', style: TextStyle(fontWeight: FontWeight.bold))),
      body: Stack(children: [
        GoogleMap(
          initialCameraPosition: const CameraPosition(target: LatLng(22.997, 120.212), zoom: 13),
          onMapCreated: (c) => _mapController = c,
          onTap: _handleMapTap,
          markers: markers,
          polylines: {
            Polyline(polylineId: const PolylineId('old'), points: _initialRoutePoints, color: const Color(0xFF6CA6CC), width: 6),
            Polyline(polylineId: const PolylineId('new'), points: _newRoutePoints, color: const Color(0xFFFFB6B9), width: 6),
          },
          zoomControlsEnabled: false,
        ),
        _buildSearchOverlay(),
        if (_selectedLocation != null && !_isSearching) _buildSwipeCards(),
      ]),
    );
  }

  Widget _buildSearchOverlay() {
    return Padding(
      padding: const EdgeInsets.all(16), 
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(25), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)]), 
            child: TextField(
              controller: _searchCtrl, 
              onChanged: _handleSearch, 
              decoration: const InputDecoration(
                hintText: '搜尋地點 或 點擊地圖', 
                prefixIcon: Icon(Icons.search), 
                border: InputBorder.none, 
                contentPadding: EdgeInsets.symmetric(vertical: 15)
              )
            )
          ),
          if (_isSearching && _results.isNotEmpty) 
            Container(
              margin: const EdgeInsets.only(top: 8), 
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)]),
              constraints: const BoxConstraints(maxHeight: 280), 
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _results.length, 
                separatorBuilder: (ctx, i) => const Divider(height: 1, color: Color(0xFFEEEEEE)), 
                itemBuilder: (ctx, i) {
                  final result = _results[i];
                  String mainText = '';
                  String subText = '';
                  if (result['structured_formatting'] != null) {
                    mainText = result['structured_formatting']['main_text'] ?? '';
                    subText = result['structured_formatting']['secondary_text'] ?? '';
                  } else {
                    List<String> parts = (result['description'] ?? '').split(',');
                    mainText = parts.isNotEmpty ? parts[0].trim() : '未知地點';
                    subText = parts.length > 1 ? parts.sublist(1).join(',').trim() : '台灣';
                  }
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: const Color(0xFFF2F9FF), borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.location_on, color: Color(0xFF6CA6CC)),
                    ),
                    title: Text(mainText, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87), maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: subText.isNotEmpty ? Padding(padding: const EdgeInsets.only(top: 4), child: Text(subText, style: const TextStyle(fontSize: 13, color: Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis)) : null,
                    trailing: const Icon(Icons.add_circle_outline, color: Color(0xFF20C997)),
                    onTap: () => _onSearchItemTap(result)
                  );
                }
              )
            )
        ]
      )
    );
  }

  Widget _buildSwipeCards() {
    return Positioned(bottom: 20, left: 0, right: 0, child: Column(children: [
      Padding(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5), child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
        GestureDetector(onTap: _isFirstSpot ? _pickStartTime : _showStayPicker, child: Container(padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)]), child: Row(children: [Icon(_isFirstSpot ? Icons.access_time : Icons.hourglass_bottom, size: 16, color: const Color(0xFF6CA6CC)), const SizedBox(width: 5), Text(_isFirstSpot ? '開始時間 ${_startTime.format(context)}' : '停留 $_stayHour 時 $_stayMinute 分', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))]))),
      ])),
      SizedBox(
        height: 180, 
        child: PageView.builder(
          controller: _pageController, 
          onPageChanged: (i) { setState(() => _selectedInsertIndex = i); _updatePreviewRoute(); }, 
          itemCount: _insertionOptions.length, 
          itemBuilder: (ctx, idx) {
            final opt = _insertionOptions[idx];
            final isSelected = idx == _selectedInsertIndex;
            return AnimatedContainer(duration: const Duration(milliseconds: 300), margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 5), padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: isSelected ? const Color(0xFF6CA6CC) : Colors.transparent, width: 2), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)]), child: Column(children: [
              Text(opt['label'], style: const TextStyle(fontWeight: FontWeight.bold)),
              const Spacer(),
              // 🔥 修正：這裡拼錯字已經改回正確的 MainAxisAlignment 了！
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                if (opt['prev'] != null) ...[ _numIcon('${opt['prevNum']}', const Color(0xFF6CA6CC)), const Icon(Icons.arrow_forward, size: 16, color: Colors.grey) ],
                const Text('+', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 20)),
                _numIcon('${opt['index'] + 1}', const Color(0xFF6CA6CC)),
                const SizedBox(width: 10),
                Expanded(child: Text(_selectedLocation!['title'], style: const TextStyle(fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
              ]),
              const Spacer(),
              ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFB6B9), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))), onPressed: _confirmSave, child: Text(isSelected && opt['prev'] != null ? '確定新增 ($_travelTimeText)' : '確定新增', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
            ]));
          }
        )
      ),
    ]));
  }

  void _showStayPicker() {
    showDialog(context: context, builder: (ctx) {
      int h = _stayHour; int m = _stayMinute;
      return AlertDialog(title: const Text('設定停留時間', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)), content: SizedBox(height: 150, child: Row(children: [
        Expanded(child: ListWheelScrollView.useDelegate(itemExtent: 40, controller: FixedExtentScrollController(initialItem: h), onSelectedItemChanged: (i)=>h=i, childDelegate: ListWheelChildBuilderDelegate(childCount: 24, builder: (ctx, i)=>Center(child: Text('$i', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)))))), const Text('時'),
        Expanded(child: ListWheelScrollView.useDelegate(itemExtent: 40, controller: FixedExtentScrollController(initialItem: m~/5), onSelectedItemChanged: (i)=>m=i*5, childDelegate: ListWheelChildBuilderDelegate(childCount: 12, builder: (ctx, i)=>Center(child: Text('${i*5}'.padLeft(2,'0'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)))))), const Text('分'),
      ])), actions: [SizedBox(width: double.infinity, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6CA6CC)), onPressed: () { setState(() { _stayHour = h; _stayMinute = m; }); Navigator.pop(ctx); }, child: const Text('完成設定', style: TextStyle(color: Colors.white))))]);
    });
  }
  void _pickStartTime() async { final t = await showTimePicker(context: context, initialTime: _startTime); if (t != null) setState(() => _startTime = t); }
  Widget _numIcon(String t, Color c) => Container(width: 28, height: 28, decoration: BoxDecoration(color: c, shape: BoxShape.circle), child: Center(child: Text(t, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold))));
}