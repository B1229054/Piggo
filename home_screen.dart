import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:dio/dio.dart';
import 'dart:async';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:geocoding/geocoding.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

/// Piggo 首頁
/// 整合：AI助理、天氣、群組記帳分帳、即時定位地圖、交通、附近推薦、翻譯與匯率等功能
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final Dio dio = Dio();
  // 1. 狀態變數定義

  // UI 與模式切換
  bool isTravelMode = true; // 控制 App 目前是「旅行中」還是「非旅行中」模式

  // OpenAI 助理
  String openAiKey = ""; //  API Key：OpenAI GPT
  List<Map<String, String>> chatMessages = [
    {'role': 'assistant', 'content': '你好！我是你的專屬 AI 助理，有任何問題都可以提問喔！'}
  ]; // 儲存聊天室的對話紀錄
  final TextEditingController chatController = TextEditingController(); 
  bool isAiTyping = false; // AI 思考的狀態顯示
  Timer? alertTimer; // 定時檢查天氣與行程

  // --- 語音與翻譯 ---
  final stt.SpeechToText _speech = stt.SpeechToText(); // 語音轉文字
  bool _isListening = false; // 判斷是否在錄音
  String transInput = ''; 
  String transResult = ''; 
  bool isTranslating = false; // 判斷是否在呼叫翻譯 API
  File? capturedImage; // 儲存透過相機拍下的照片
  final ImagePicker _picker = ImagePicker(); // 相機與相簿選擇
  final String googleApiKey = ""; 

  // 支援的翻譯語言
  String sourceLang = 'zh-TW';
  String targetLang = 'en';
  final Map<String, String> supportedLangs = {
    'zh-TW': '繁體中文', 'zh-CN': '簡體中文', 'en': '英文',
    'ja': '日文', 'ko': '韓文', 'th': '泰文',
    'es': '西班牙文', 'fr': '法文'
  };

  // --- 匯率 ---
  String baseCurrency = 'TWD';   // 基準貨幣
  String targetCurrency = 'JPY'; // 目標貨幣
  final TextEditingController twdController = TextEditingController(); // 匯率輸入框
  double foreignAmount = 0.0; // 換算後的金額
  
  // 匯率暫存表
  Map<String, double> exchangeRates = {
    'TWD': 1.0, 'JPY': 4.75, 'KRW': 42.5, 'USD': 0.031, 'THB': 1.15, 'EUR': 0.029
  };
  
  // 支援的貨幣&對應的國旗
  final List<Map<String, String>> supportedCurrencies = [
    {'code': 'TWD', 'flag': '🇹🇼', 'name': '新臺幣'}, 
    {'code': 'JPY', 'flag': '🇯🇵', 'name': '日圓'},
    {'code': 'KRW', 'flag': '🇰🇷', 'name': '韓元'},
    {'code': 'THB', 'flag': '🇹🇭', 'name': '泰銖'},
    {'code': 'USD', 'flag': '🇺🇸', 'name': '美金'},
    {'code': 'EUR', 'flag': '🇪🇺', 'name': '歐元'},
  ];

  // 國家代碼與貨幣的對照表
  final Map<String, String> countryToCurrency = {
    'JP': 'JPY', 'KR': 'KRW', 'TH': 'THB', 'US': 'USD',
    'FR': 'EUR', 'DE': 'EUR', 'IT': 'EUR', 'ES': 'EUR'
  };

  // --- 地圖與 Socket 群組定位 ---
  GoogleMapController? mapController;
  LatLng mapRegion = const LatLng(25.0330, 121.5654); // 預設地圖中心點
  io.Socket? socket; 
  Timer? locationTimer; // 定時上傳自身位置
  bool isSharingLocation = true; // 是否開啟位置分享
  Set<Marker> mapMarkers = {}; // 地圖上的標記點集合
  Map<String, dynamic> othersLocations = {}; // 儲存其他群組成員的即時位置
  
  String userAvatar = 'https://ui-avatars.com/api/?name=Me&background=FFB6C1&color=fff&rounded=true&size=150'; 
  
  LatLng? groupMeetingPoint; // 群組的集合點
  String? meetingPointInitiator; // 發起集合點的人

  // --- 記帳 ---
  final TextEditingController titleController = TextEditingController(); // 記帳品項
  final TextEditingController amountController = TextEditingController(); // 記帳金額
  String selectedPayer = '我'; // 紀錄「誰先代墊」
  List<Map<String, dynamic>> participants = []; // 參與分攤的成員名單與各自金額
  List<dynamic> expenses = []; // 歷史消費紀錄
  int? editingExpenseId; 
  
  double myShare = 0.0; // 目前總花費
  double myBalance = 0.0; // 結餘
  double myBudget = 8000.0; // 個人旅行總預算
  Map<String, double> memberBalances = {}; // 群組內結餘

  DateTime selectedExpenseDate = DateTime.now(); 
  String splitMethod = 'avg'; // 分帳模式

  // --- 行程 ---
  Map<String, dynamic> activeTrip = {
    'id': 1, 'name': '🇹🇼 台南古都爆食三日遊', 'status': 'active',
    'members': [], 'todaySchedule': []
  }; // 假資料
  Map<String, dynamic>? nextStop; // 下一個行程

  // --- 天氣 ---
  bool isSearchingWeather = false;
  final TextEditingController weatherSearchController = TextEditingController();
  Map<String, dynamic> weatherData = {
    'temp': '--', 'desc': '載入中', 'locationName': '定位中...',
    'high': '--', 'low': '--', 'humidity': '--', 'wind': '--', 'pop': '--',
    'icon': FontAwesomeIcons.cloud,
    'hourly': []
  }; 

  // --- 交通 ---
  final Map<String, Map<String, String>> transportLinks = {
    'Uber': {'scheme': 'uber://', 'webUrl': 'https://m.uber.com/ul/'},
    'Ubike': {'scheme': 'youbike2://', 'webUrl': 'https://www.youbike.com.tw/'},
    '公車': {'scheme': 'https://www.taiwanbus.tw/', 'webUrl': 'https://www.taiwanbus.tw/'},
    'iRent': {'scheme': 'irent://', 'webUrl': 'https://www.irentcar.com.tw/'},
    'goShare': {'scheme': 'goshare://', 'webUrl': 'https://www.ridegoshare.com/'},
  }; 

  List<Map<String, dynamic>> nearbyPlaces = []; //附近景點
  bool isLoadingPlaces = true;
  final PageController _pageController = PageController(viewportFraction: 0.9); 
  
  // 假資料
  final List<Map<String, dynamic>> mockPlaces = [
    {'name': '奇美博物館', 'rating': '4.9', 'image': 'https://images.unsplash.com/photo-1504674900247-0877df9cc836?q=80&w=1000', 'lat': 22.935, 'lon': 120.226},
    {'name': '神農街', 'rating': '4.7', 'image': 'https://images.unsplash.com/photo-1504674900247-0877df9cc836?q=80&w=1000', 'lat': 22.997, 'lon': 120.197},
  ];

  // 2. 生命週期

  @override
  void initState() {
    super.initState();
    // 初始化群組成員假座標資料
    othersLocations = {
      'haha': {'userId': 'haha', 'userName': 'haha', 'avatar_url': 'https://i.pravatar.cc/150?u=haha', 'latitude': mapRegion.latitude + 0.0005, 'longitude': mapRegion.longitude + 0.0005},
      'bee': {'userId': 'bee', 'userName': 'bee', 'avatar_url': 'https://i.pravatar.cc/150?u=bee', 'latitude': mapRegion.latitude - 0.0004, 'longitude': mapRegion.longitude - 0.0002},
      'ryan': {'userId': 'ryan', 'userName': 'ryan', 'avatar_url': 'https://i.pravatar.cc/150?u=ryan', 'latitude': mapRegion.latitude + 0.0002, 'longitude': mapRegion.longitude - 0.0006},
    };
    groupMeetingPoint = LatLng(mapRegion.latitude + 0.001, mapRegion.longitude + 0.001);
    meetingPointInitiator = 'haha';

    fetchTripSchedule(); // 抓取行程
    fetchTripMembers();  // 抓取成員
    refreshExpenses();   // 抓取帳務
    
    handleCurrentLocation().then((_) {
      Future.delayed(const Duration(seconds: 1), () {
        _checkSmartAlerts();
      });
    });
    
    setupSocketIo(); 
    fetchExchangeRates(); 

    //每 15 分鐘自動檢查一次天氣和行程狀態
    alertTimer = Timer.periodic(const Duration(minutes: 15), (timer) {
      _checkSmartAlerts();
    });
  }

  @override
  void dispose() {
    socket?.disconnect();
    locationTimer?.cancel();
    alertTimer?.cancel();
    super.dispose();
  }

  //  3. AI 功能
  
  /// 根據當前天氣、時間，主動發送提醒給使用者
  void _checkSmartAlerts() {
    if (!mounted) return;
    
    List<String> alerts = [];
    String weatherDesc = weatherData['desc']?.toString() ?? "";
    int currentTemp = int.tryParse(weatherData['temp']?.toString() ?? "25") ?? 25;

    // 1. 天氣 (下雨、高溫、低溫)
    if (weatherDesc.contains("雨") || (weatherData['pop'] != '--' && int.parse(weatherData['pop']) > 60)) {
      alerts.add("今天可能有降雨，出門記得帶把傘，或者穿防水外套喔！☔️");
    } else if (currentTemp >= 30) {
      alerts.add("下午氣溫高達 ${currentTemp}°C，記得多補充水分，避免中暑！☀️");
    } else if (currentTemp <= 18) {
      alerts.add("天氣有點冷，建議隨身帶件薄外套，別感冒囉！🧥");
    }

    // 2. 行程與營業時間
    if (nextStop != null) {
      final parts = nextStop!['time'].toString().split(':');
      final stopTimeMins = int.parse(parts[0]) * 60 + int.parse(parts[1]);
      final now = DateTime.now();
      final nowMins = now.hour * 60 + now.minute;
      final diff = stopTimeMins - nowMins;

      // 若距離出發時間<=30 分鐘，主動提醒準備出發
      if (diff > 0 && diff <= 30) {
        alerts.add("提醒你，下一站【${nextStop!['title']}】預計 $diff 分鐘後出發，差不多該準備囉！🚗");
      }

      if (diff < 0) { 
        alerts.add("行程似乎有點延後了，下個景點可能快關門了，需要我幫你找替代行程或調整順序嗎？🤔");
      }
    }

    // 3. 觸發提醒並更新至聊天室
    for (var msg in alerts) {
      // 避免重複發送相同的提醒
      if (!chatMessages.any((m) => m['content'] == "💡 貼心提醒：\n$msg")) {
        setState(() {
          chatMessages.add({'role': 'assistant', 'content': '💡 貼心提醒：\n$msg'});
        });
        // 在畫面上方彈出提醒
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(msg, style: const TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: const Color(0xFF6292B4),
          duration: const Duration(seconds: 5),
          action: SnackBarAction(label: '查看', textColor: Colors.white, onPressed: showAiChatModal),
        ));
      }
    }
  }

  /// 發送對話至 OpenAI API
  Future<void> sendMessageToOpenAI(String message, StateSetter setModalState) async {
    if (message.trim().isEmpty) return;

    // 將 App 目前狀態打包成 System Prompt
    String contextInfo = """
    【目前狀態資訊】
    - 當地天氣: ${weatherData['desc'] ?? '未知'}，氣溫 ${weatherData['temp'] ?? '--'}°C
    - 今日完整行程: ${(activeTrip['todaySchedule'] as List).map((s) => s['time'] + ' ' + s['title']).join(', ')}
    - 下一個行程: ${nextStop != null ? nextStop!['title'] + ' (預計 ' + nextStop!['time'] + ' 出發)' : '當日行程已全部結束'}
    - 個人總花費: NT\$${formatAmount(myShare)} / 個人預算: NT\$${formatAmount(myBudget)}
    - 地圖集合點狀態: ${groupMeetingPoint != null ? '已設定集合點' : '尚未設定'}
    """;

    try {
      setModalState(() {
        chatMessages.add({'role': 'user', 'content': message});
        isAiTyping = true;
      });
      chatController.clear();

      // 呼叫 OpenAI API
      final response = await dio.post(
        'https://api.openai.com/v1/chat/completions',
        options: Options(
          headers: {
            'Authorization': 'Bearer $openAiKey',
            'Content-Type': 'application/json',
          },
        ),
        data: {
          "model": "gpt-3.5-turbo",
          "messages": [
            {
              "role": "system", 
              "content": """
                你是一個貼心、幽默的旅遊助理 Piggo。
                請根據以下動態資訊回答：
                $contextInfo
                
                【重要守則】:
                1. 若使用者問「行程」，請務必將所有列出的行程按時間順序完整列出，不要遺漏。
                2. 如果行程包含多個景點（例如花園夜市、海安路），請一併告訴使用者。
                3. 如果預算快超支請溫馨提醒，如果天氣不好請主動關心。
                4. 如果行程延後，請主動分析下個景點營業時間，並詢問是否需要推薦其他景點。
                5. 語氣要像好朋友一樣輕鬆，句尾加 Emoji。
              """
            },
            // 帶入歷史訊息
            ...chatMessages.map((m) => {"role": m['role'], "content": m['content']})
          ]
        },
      );

      // 接收並顯示AI的回覆
      if (response.data['choices'] != null && response.data['choices'].isNotEmpty) {
        final aiReply = response.data['choices'][0]['message']['content'];
        try {
          setModalState(() {
            chatMessages.add({'role': 'assistant', 'content': aiReply});
            isAiTyping = false;
          });
        } catch (e) {} 
      }
    } catch (e) {
      try {
        setModalState(() {
          chatMessages.add({'role': 'assistant', 'content': '哎呀，我腦袋當機了（連線失敗），請確認你的 API Key 是否正確！\n($e)'});
          isAiTyping = false;
        });
      } catch (e) {}
    }
  }

  // 4. 地圖、定位、Socket 通訊
  
  /// 開關位置分享
  void toggleSharing(bool v) {
    setState(() => isSharingLocation = v);
    if (!v && socket != null) {
      // 告訴伺服器停止分享
      socket!.emit('stopSharingLocation', {'userId': 'user_me'});
    }
    updateMapMarkers(); 
  }

  /// 建立 Socket.io 連線
  void setupSocketIo() {
    socket = io.io('http://10.0.2.2:3000', <String, dynamic>{'transports': ['websocket'], 'autoConnect': true});
    
    // 接收其他成員的座標
    socket?.on('userMoved', (data) { 
      if (mounted) { 
        setState(() => othersLocations[data['userId']] = data); 
        updateMapMarkers(); 
      } 
    });
    
    // 接收其他成員停止分享的通知
    socket?.on('userStoppedSharing', (data) { 
      if (mounted) { 
        setState(() { othersLocations.remove(data['userId']); }); 
        updateMapMarkers(); 
      } 
    });
    
    // 接收群組建立新集合點的通知
    socket?.on('newMeetingPoint', (data) { 
      if (mounted) { 
        setState(() { 
          groupMeetingPoint = LatLng(data['lat'], data['lon']); 
          meetingPointInitiator = data['userName'] ?? '未知'; 
        }); 
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('📍 群組已更新集合地點！'))); 
        updateMapMarkers(); 
      } 
    });
    
    // 每 5 秒鐘將自己的座標打到後端
    locationTimer = Timer.periodic(const Duration(seconds: 5), (timer) { 
      if (isSharingLocation && socket != null) { 
        socket!.emit('updateLocation', {'userId': 'user_me', 'userName': '我', 'avatar_url': userAvatar, 'latitude': mapRegion.latitude, 'longitude': mapRegion.longitude}); 
      } 
    });
  }

  /// 更新 Google Maps 上的位置標記
  Future<void> updateMapMarkers() async {
    Set<Marker> newMarkers = {};
    const Size avatarSize = Size(75, 75);

    for (var entry in othersLocations.entries) {
      var data = entry.value;
      try {
        var icon = await getMarkerIcon(data['avatar_url'] ?? userAvatar, avatarSize);
        newMarkers.add(Marker(markerId: MarkerId(data['userId']), position: LatLng(data['latitude'], data['longitude']), icon: icon, infoWindow: InfoWindow(title: data['userName'])));
      } catch (e) { 
        debugPrint("產生 Marker 失敗: $e"); 
      }
    }
    
    if (isSharingLocation) {
      try {
        var myIcon = await getMarkerIcon(userAvatar, avatarSize);
        newMarkers.add(Marker(
          markerId: const MarkerId('user_me'), 
          position: mapRegion, 
          icon: myIcon, 
          infoWindow: const InfoWindow(title: '我 (目前位置)'),
          zIndex: 2.0 
        ));
      } catch (e) {
        debugPrint("產生自己的 Marker 失敗: $e");
      }
    }

    // 建立集合點
    if (groupMeetingPoint != null) {
      newMarkers.add(Marker(
        markerId: const MarkerId('meeting_point'), 
        position: groupMeetingPoint!, 
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed), 
        infoWindow: InfoWindow(title: '🌟 集合點 (${meetingPointInitiator ?? '我'} 發起) 🌟')
      ));
    }
    
    if (mounted) {
      setState(() => mapMarkers = newMarkers);
    }
  }

  /// 啟動手機導航
  Future<void> startNavigation({String? destinationName, double? lat, double? lon}) async {
    String googleUrl = ''; 
    String appleUrl = '';
    // 如果傳入經緯度，直接導航至座標
    if (lat != null && lon != null) { 
      googleUrl = 'http://googleusercontent.com/maps.google.com/maps?daddr=$lat,$lon'; 
      appleUrl = 'https://maps.apple.com/?daddr=$lat,$lon'; 
    } 
    // 如果傳入地名，交給地圖搜尋
    else if (destinationName != null) { 
      final encodedDest = Uri.encodeComponent(destinationName); 
      googleUrl = 'http://googleusercontent.com/maps.google.com/maps?daddr=$encodedDest'; 
      appleUrl = 'https://maps.apple.com/?daddr=$encodedDest'; 
    } else { 
      return; 
    }

    // 依據裝置判定對應的地圖App
    try { 
      if (Platform.isIOS) { 
        await launchUrl(Uri.parse(appleUrl), mode: LaunchMode.externalApplication); 
      } else { 
        await launchUrl(Uri.parse(googleUrl), mode: LaunchMode.externalApplication); 
      } 
    } catch (e) { 
      debugPrint("導航啟動失敗: $e"); 
    }
  }

  // 5. 資料請求API
  
  /// 獲取即時匯率
  Future<void> fetchExchangeRates() async {
    try {
      final response = await dio.get('https://open.er-api.com/v6/latest/TWD');
      if (response.data['rates'] != null) {
        setState(() { 
          exchangeRates['TWD'] = 1.0; 
          exchangeRates['JPY'] = response.data['rates']['JPY']; 
          exchangeRates['KRW'] = response.data['rates']['KRW']; 
          exchangeRates['THB'] = response.data['rates']['THB']; 
          exchangeRates['USD'] = response.data['rates']['USD']; 
          exchangeRates['EUR'] = response.data['rates']['EUR']; 
        });
      }
    } catch (e) { 
      debugPrint('匯率失敗: $e'); 
    }
  }

  /// 獲取旅行成員
  Future<void> fetchTripMembers() async {
    try {
      final response = await dio.get('http://10.0.2.2:3000/api/trips/${activeTrip['id']}/members');
      if (response.data != null) { 
        setState(() => activeTrip['members'] = response.data); 
        initParticipants(); 
      }
    } catch (e) { 
      debugPrint("抓取成員名單失敗: $e"); 
      // 若後端未啟動，提供假資料
      if (mounted) {
        setState(() {
          activeTrip['members'] = [{'user_name': 'haha'}, {'user_name': 'bee'}, {'user_name': 'ryan'}];
          initParticipants();
        });
      }
    }
  }

  /// 獲取帳務紀錄
  Future<void> refreshExpenses() async {
    try {
      final response = await dio.get('http://10.0.2.2:3000/api/trips/${activeTrip['id']}/expenses');
      if (response.data != null && mounted) {
        setState(() => expenses = response.data);
        _calculateBalances();
      }
    } catch (e) {
      debugPrint("帳務獲取失敗: $e");
      // 若後端未啟動，提供假資料
      if (mounted) {
        setState(() {
          expenses = [
            {
              'id': 1, 'title': '燒肉大餐', 'category': '吃飯', 'amount': 4000.0, 'payer_name': 'haha', 'emoji': '🥩', 'time': '18:30', 
              'participants': [{'name': '我', 'amount': 1000.0}, {'name': 'haha', 'amount': 1000.0}, {'name': 'bee', 'amount': 1000.0}, {'name': 'ryan', 'amount': 1000.0}]
            },
            {
              'id': 2, 'title': '冰淇淋', 'category': '點心', 'amount': 150.0, 'payer_name': 'bee', 'emoji': '🍦', 'time': '20:00', 
              'participants': [{'name': '我', 'amount': 37.5}, {'name': 'haha', 'amount': 37.5}, {'name': 'bee', 'amount': 37.5}, {'name': 'ryan', 'amount': 37.5}]
            },
            {
              'id': 3, 'title': '我的伴手禮', 'category': '個人', 'amount': 150.0, 'payer_name': '我', 'emoji': '🎁', 'time': '21:00', 
              'participants': [{'name': '我', 'amount': 150.0}]
            },
          ];
          _calculateBalances();
        });
      }
    }
  }

  /// 自動排程與旅行清單
  Future<void> fetchTripSchedule() async {
    try {
      final response = await dio.get('http://10.0.2.2:3000/api/trips/${activeTrip['id']}/schedule');
      if (response.data != null && mounted) { 
        setState(() { activeTrip['todaySchedule'] = response.data; _calculateNextStop(); }); 
      }
    } catch (e) { 
      if (mounted) { 
        final now = DateTime.now();
        final stop1 = now.add(const Duration(minutes: 30)); 
        final stop2 = now.add(const Duration(hours: 2));
        
        setState(() { 
          activeTrip['todaySchedule'] = [
            {'time': '${stop1.hour.toString().padLeft(2, '0')}:${stop1.minute.toString().padLeft(2, '0')}', 'title': '神農街吃美食'}, 
            {'time': '${stop2.hour.toString().padLeft(2, '0')}:${stop2.minute.toString().padLeft(2, '0')}', 'title': '花園夜市'}
          ]; 
          _calculateNextStop(); 
        }); 
      } 
    }
  }

  // 6. 業務邏輯
  
  /// 初始化參與記帳的成員
  void initParticipants() {
    final membersList = activeTrip['members'] as List? ?? [];
    final Set<String> uniqueNames = {};
    List<Map<String, dynamic>> list = [];
    
    uniqueNames.add('我');
    list.add({'name': '我', 'selected': true, 'amount': 0.0, 'controller': TextEditingController(text: '')});

    for (var m in membersList) {
      String name = m['user_name']?.toString() ?? '朋友';
      if (!uniqueNames.contains(name)) {
        uniqueNames.add(name);
        list.add({
          'name': name,
          'selected': true,
          'amount': 0.0,
          'controller': TextEditingController(text: '')
        });
      }
    }
    
    setState(() => participants = list);
  }

  /// 計算群組內所有的借貸關係與總花費
  void _calculateBalances() {
    Map<String, double> tempBalances = {};
    double tempMyShare = 0.0;
    
    tempBalances['我'] = 0.0;
    for (var p in participants) {
      tempBalances[p['name'].toString()] = 0.0;
    }

    // 遍歷所有消費紀錄，結算每個人的餘額
    for (var exp in expenses) {
      String payer = exp['payer_name']?.toString() ?? '我';
      double amount = double.tryParse(exp['amount'].toString()) ?? 0.0;

      // 先付錢的人餘額增加
      tempBalances[payer] = (tempBalances[payer] ?? 0.0) + amount;

      var parts = exp['participants'] ?? exp['splits'] ?? [];
      for (var split in parts) {
        String pName = split['name']?.toString() ?? split['user_name']?.toString() ?? '未知';
        double pAmount = double.tryParse(split['amount'].toString()) ?? 0.0;

        // 參與分攤的人餘額減少
        tempBalances[pName] = (tempBalances[pName] ?? 0.0) - pAmount;
        
        if (pName == '我') {
          tempMyShare += pAmount; // 統計使用者總共花了多少
        }
      }
    }

    setState(() {
      memberBalances = tempBalances;
      myShare = tempMyShare;      
      myBalance = tempBalances['我'] ?? 0.0; 
    });
  }

  String formatAmount(double amount) {
    return amount.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '');
  }

  /// 產生最終的分攤名單與金額
  List<Map<String, dynamic>> generateFinalSplits(double totalAmt) {
    List<Map<String, dynamic>> finalSplits = [];
    var selectedParts = participants.where((p) => p['selected'] == true).toList();

    if (splitMethod == 'avg') {
      // 平均分攤
      double splitAmt = selectedParts.isNotEmpty ? totalAmt / selectedParts.length : 0;
      for (var p in selectedParts) {
        finalSplits.add({"name": p['name'], "amount": splitAmt});
      }
    } else {
      // 精確分攤
      var emptyParts = selectedParts.where((p) => (p['amount'] == null || p['amount'] == 0.0)).toList();
      double filledSum = selectedParts.where((p) => (p['amount'] != null && p['amount'] > 0)).fold(0.0, (s, p) => s + (p['amount'] as double));
      double remainder = totalAmt - filledSum;

      for (var p in selectedParts) {
        double pAmt = p['amount'] ?? 0.0;
        if (emptyParts.length == 1 && p['name'] == emptyParts.first['name']) {
          pAmt = remainder > 0 ? remainder : 0.0;
        }
        finalSplits.add({"name": p['name'], "amount": pAmt});
      }
    }
    return finalSplits;
  }

  /// OCR：呼叫相機拍照並透過 Google Vision API 辨識文字
  Future<void> handleCamera(Function updateModal) async {
    final XFile? photo = await _picker.pickImage(source: ImageSource.camera, imageQuality: 80);
    if (photo != null) {
      try { updateModal(() { capturedImage = File(photo.path); transInput = "（🔍 正在分析...）"; }); } catch(e){}
      try {
        String base64Image = base64Encode(await capturedImage!.readAsBytes());
        final response = await dio.post('https://vision.googleapis.com/v1/images:annotate?key=$googleApiKey', data: { "requests": [ { "image": {"content": base64Image}, "features": [{"type": "TEXT_DETECTION"}] } ] });
        if (response.data['responses'] != null && response.data['responses'].isNotEmpty) {
          var annotations = response.data['responses'][0]['textAnnotations'];
          if (annotations != null && annotations.isNotEmpty) { 
            try { updateModal(() => transInput = annotations[0]['description']); } catch(e){}
            await performTranslation(updateModal);  // 辨識成功後呼叫翻譯
          } else { 
            try { updateModal(() => transInput = "照片中找不到文字喔！"); } catch(e){}
          }
        }
      } catch (e) { 
        try { updateModal(() => transInput = "辨識失敗 ($e)"); } catch(e){}
      }
    }
  }

  ///呼叫 MyMemory API 進行跨語系翻譯
  Future<void> performTranslation(Function updateModal) async {
    if (transInput.isEmpty) { return; }
    try { updateModal(() { isTranslating = true; transResult = "（翻譯中...）"; }); } catch(e){}
    try {
      final url = 'https://api.mymemory.translated.net/get?q=${Uri.encodeComponent(transInput)}&langpair=$sourceLang|$targetLang';
      final response = await dio.get(url);
      try { updateModal(() { transResult = response.data['responseData']['translatedText']; isTranslating = false; }); } catch(e){}
    } catch (e) { 
      try { updateModal(() { transResult = "翻譯失敗"; isTranslating = false; }); } catch(e){}
    }
  }

  /// 將網路圖片轉換成 Google Maps 支援的大頭針圖示
  Future<BitmapDescriptor> getMarkerIcon(String url, Size size) async {
    final response = await http.get(Uri.parse(url));
    final ui.Codec codec = await ui.instantiateImageCodec(response.bodyBytes, targetWidth: size.width.toInt(), targetHeight: size.height.toInt());
    final ui.FrameInfo fi = await codec.getNextFrame();
    final ui.Image image = fi.image; 
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder(); 
    final Canvas canvas = Canvas(pictureRecorder);
    final Paint paint = Paint()..isAntiAlias = true; 
    final double radius = size.width / 2; 
    paint.color = Colors.white; 
    
    canvas.drawCircle(Offset(radius, radius), radius, paint);
    
    // 繪製圓形裁剪的圖片
    final Path clipPath = Path()..addOval(Rect.fromLTWH(4, 4, size.width - 8, size.height - 8)); 
    canvas.clipPath(clipPath); 
    canvas.drawImage(image, const Offset(0, 0), paint);
    
    final ui.Image finalImage = await pictureRecorder.endRecording().toImage(size.width.toInt(), size.height.toInt());
    final ByteData? byteData = await finalImage.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.bytes(byteData!.buffer.asUint8List());
  }

  /// 獲取地點天氣：傳入座標，取得 Open-Meteo 天氣預報資料
  Future<void> fetchWeatherAndCity(double lat, double lon, {String? customCity}) async {
    try {
      String cityName = customCity ?? "未知地點";
      if (customCity == null) {
        try {
          List<Placemark> placemarks = await placemarkFromCoordinates(lat, lon);
          if (placemarks.isNotEmpty) {
            cityName = placemarks.first.locality ?? placemarks.first.administrativeArea ?? "未知地點";
          }
        } catch (geoError) {
          debugPrint("查無城市名稱，但不影響天氣: $geoError");
        }
      }
      final url = 'https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon&current=temperature_2m,relative_humidity_2m,wind_speed_10m,weather_code&hourly=temperature_2m,weather_code,precipitation_probability&daily=temperature_2m_max,temperature_2m_min&timezone=auto';
      final response = await dio.get(url); 
      final data = response.data;
      final currentTemp = data['current']['temperature_2m'].round().toString(); 
      final humidity = data['current']['relative_humidity_2m'].toString(); 
      final wind = data['current']['wind_speed_10m'].toString(); 
      final code = data['current']['weather_code']; 
      final high = data['daily']['temperature_2m_max'][0].round().toString(); 
      final low = data['daily']['temperature_2m_min'][0].round().toString();
      
      // 解析天氣代碼，轉換為中文描述
      String getDesc(int c) { 
        if (c <= 3) { return "多雲時晴"; } 
        if (c <= 67) { return "下雨"; } 
        return "大雨/雷雨"; 
      }
      dynamic getIcon(int c) { 
        if (c <= 3) { return FontAwesomeIcons.cloudSun; } 
        if (c <= 67) { return FontAwesomeIcons.cloudRain; } 
        return FontAwesomeIcons.cloudShowersHeavy; 
      }
      
      // 未來 24 小時預報
      List<Map<String, dynamic>> hourlyData = []; 
      int currentHourIdx = DateTime.now().hour;
      for (int i = 0; i < 24; i++) {
        int targetIdx = currentHourIdx + i; 
        if (targetIdx >= data['hourly']['temperature_2m'].length) { break; }
        hourlyData.add({'time': i == 0 ? '現在' : '${(targetIdx % 24).toString().padLeft(2, '0')}:00', 'temp': data['hourly']['temperature_2m'][targetIdx].round().toString(), 'icon': getIcon(data['hourly']['weather_code'][targetIdx]), 'pop': data['hourly']['precipitation_probability'][targetIdx].toString()});
      }
      if (mounted) { 
        setState(() { weatherData = {'temp': currentTemp, 'desc': getDesc(code), 'locationName': cityName, 'high': high, 'low': low, 'humidity': humidity, 'wind': wind, 'icon': getIcon(code), 'hourly': hourlyData, 'pop': hourlyData.isNotEmpty ? hourlyData[0]['pop'] : '--'}; }); 
      }
    } catch (e) { 
      debugPrint("天氣獲取失敗: $e"); 
    }
  }

  /// 透過城市名稱字串去查天氣
  Future<void> searchCityWeather(String cityName, Function updateModal) async {
    if (cityName.isEmpty) { return; }
    try {
      try { updateModal(() => isSearchingWeather = true); } catch(e){}
      final url = 'https://geocoding-api.open-meteo.com/v1/search?name=$cityName&count=1&language=zh';
      final response = await dio.get(url);
      if (response.data['results'] != null && response.data['results'].isNotEmpty) {
        final result = response.data['results'][0]; 
        await fetchWeatherAndCity(result['latitude'], result['longitude'], customCity: result['name']);
      }
    } catch (e) { 
      debugPrint("搜尋城市失敗: $e"); 
    } finally { 
      try { updateModal(() => isSearchingWeather = false); } catch(e){} 
      weatherSearchController.clear(); 
    }
  }

  /// 獲取附近熱門景點
  Future<void> fetchNearbyPlaces(double lat, double lon) async {
    setState(() => isLoadingPlaces = true);
    try {
      final url = 'https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=$lat,$lon&radius=2000&type=point_of_interest&language=zh-TW&key=$googleApiKey';
      final response = await dio.get(url);
      if (response.data['status'] == 'OK') {
        final results = response.data['results'] as List; List<Map<String, dynamic>> fetchedPlaces = [];
        for (var i = 0; i < results.length && i < 5; i++) {
          var place = results[i]; String? photoRef = place['photos'] != null && place['photos'].isNotEmpty ? place['photos'][0]['photo_reference'] : null;
          String imageUrl = photoRef != null ? 'https://maps.googleapis.com/maps/api/place/photo?maxwidth=800&photoreference=$photoRef&key=$googleApiKey' : 'https://images.unsplash.com/photo-1504674900247-0877df9cc836?q=80&w=1000';
          fetchedPlaces.add({'name': place['name']?.toString() ?? '', 'rating': place['rating']?.toString() ?? '--', 'image': imageUrl, 'lat': place['geometry']['location']['lat'], 'lon': place['geometry']['location']['lng']});
        }
        if (mounted) { setState(() { nearbyPlaces = fetchedPlaces; isLoadingPlaces = false; }); }
      } else { 
        if (mounted) { setState(() { nearbyPlaces = mockPlaces; isLoadingPlaces = false; }); } 
      }
    } catch (e) { 
      if (mounted) { setState(() { nearbyPlaces = mockPlaces; isLoadingPlaces = false; }); } 
    }
  }

  /// 獲取手機當前定位，並連動更新天氣與景點
  Future<void> handleCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled(); 
      if (!serviceEnabled) { return; } 
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) { 
        permission = await Geolocator.requestPermission(); 
        if (permission == LocationPermission.denied) { return; } 
      }
      if (permission == LocationPermission.deniedForever) { return; }
      
      // 成功取得座標
      Position pos = await Geolocator.getCurrentPosition(); 
      setState(() => mapRegion = LatLng(pos.latitude, pos.longitude));
      
      // 取得座標後更新天氣與景點
      await fetchWeatherAndCity(pos.latitude, pos.longitude); 
      await fetchNearbyPlaces(pos.latitude, pos.longitude);
      try {
        // 用來判斷出國自動切換匯率
        List<Placemark> placemarks = await placemarkFromCoordinates(pos.latitude, pos.longitude);
        if (placemarks.isNotEmpty) { 
          String? countryCode = placemarks.first.isoCountryCode; 
          if (countryCode != null && countryToCurrency.containsKey(countryCode)) { 
            setState(() => targetCurrency = countryToCurrency[countryCode]!); 
          } 
        }
      } catch (e) { 
        debugPrint("反查地址失敗: $e"); 
      }
    } catch (e) { 
      debugPrint("獲取定位失敗: $e"); 
    }
  }

  /// 定位我的位置
  Future<void> returnToCurrentLocation(Function updateModal) async {
    try { updateModal(() => isSearchingWeather = true); } catch(e){}
    weatherSearchController.clear(); 
    await handleCurrentLocation(); 
    try { updateModal(() => isSearchingWeather = false); } catch(e){}
  }

  /// 計算下一個行程
  void _calculateNextStop() {
    final now = DateTime.now(); 
    final timeVal = now.hour * 60 + now.minute; 
    final schedule = activeTrip['todaySchedule'] as List? ?? [];
    Map<String, dynamic>? upcoming;
    for (var item in schedule) { 
      final parts = item['time'].toString().split(':'); 
      final itemTime = int.parse(parts[0]) * 60 + int.parse(parts[1]); 
      if (itemTime > timeVal) { 
        upcoming = item; 
        break; 
      } 
    }
    if (mounted) { setState(() => nextStop = upcoming); }
  }

  /// 交通按鈕，啟動第三方 App
  Future<void> handleTransportPress(String name) async {
    final link = transportLinks[name];
    if (link != null) {
      final schemeUri = Uri.parse(link['scheme']!); 
      final webUri = Uri.parse(link['webUrl']!);
      try { 
        await launchUrl(schemeUri, mode: LaunchMode.externalApplication); 
      } catch (e) { 
        try { 
          await launchUrl(webUri, mode: LaunchMode.externalApplication); 
        } catch (webError) { 
          debugPrint("連網頁都打不開: $webError"); 
        } 
      }
    }
  }

  /// 產生匯率下拉選單
  Widget _buildCurrencyDropdown(String currentValue, ValueChanged<String?> onChanged) {
    return Container(
      height: 28, padding: const EdgeInsets.symmetric(horizontal: 8), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: currentValue,
          icon: const Icon(Icons.arrow_drop_down, size: 16, color: Color(0xFF6292B4)),
          isDense: true,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF6292B4)),
          onChanged: onChanged,
          items: supportedCurrencies.map<DropdownMenuItem<String>>((c) => DropdownMenuItem<String>(value: c['code']?.toString(), child: Text(c['code']?.toString() ?? ''))).toList()
        )
      ),
    );
  }

  // 7. 模組化彈窗

  /// 顯示 AI 聊天室
  void showAiChatModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom), // 防鍵盤遮擋
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
              child: Container(
                decoration: const BoxDecoration(color: Color(0xFFF4F6F9), borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: const BoxDecoration(color: Color(0xFF6292B4), borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.smart_toy, color: Colors.white),
                              SizedBox(width: 10),
                              Text("Piggo AI 助理", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                            ],
                          ),
                          GestureDetector(
                            onTap: () => Navigator.of(context).pop(), // 關閉彈窗
                            child: const Icon(Icons.close, color: Colors.white),
                          )
                        ],
                      )
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(15),
                        itemCount: chatMessages.length,
                        itemBuilder: (context, index) {
                          final msg = chatMessages[index];
                          final isUser = msg['role'] == 'user';
                          return Align(
                            alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(12),
                              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                              decoration: BoxDecoration(
                                color: isUser ? const Color(0xFF6292B4) : Colors.white,
                                borderRadius: BorderRadius.circular(15),
                                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))]
                              ),
                              child: Text(
                                msg['content'] ?? '',
                                style: TextStyle(color: isUser ? Colors.white : Colors.black87, fontSize: 15),
                              )
                            ),
                          );
                        }
                      )
                    ),
                    if (isAiTyping)
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text("Piggo 正在思考中... 🐷", style: TextStyle(color: Colors.grey, fontSize: 12)),
                        )
                      ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                      color: Colors.white,
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 15),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(25),
                                border: Border.all(color: Colors.grey[300]!)
                              ),
                              child: TextField(
                                controller: chatController,
                                decoration: const InputDecoration(
                                  hintText: "問我行程、當地景點或幫你翻譯...",
                                  hintStyle: TextStyle(fontSize: 14),
                                  border: InputBorder.none
                                ),
                                onSubmitted: (val) => sendMessageToOpenAI(val, setModalState),
                              )
                            )
                          ),
                          const SizedBox(width: 10),
                          GestureDetector(
                            onTap: () => sendMessageToOpenAI(chatController.text, setModalState),
                            child: const CircleAvatar(
                              backgroundColor: Color(0xFF6292B4),
                              child: Icon(Icons.send, color: Colors.white, size: 18),
                            )
                          )
                        ],
                      )
                    )
                  ],
                )
              ),
            ),
          );
        }
      )
    );
  }

  /// 設定集合點
  void showSetMeetingPointModal() {
    LatLng? tempPoint = groupMeetingPoint ?? mapRegion;
    bool hasPermission = meetingPointInitiator == null || meetingPointInitiator == '我';

    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
            child: Container(
              decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
              child: Stack(
                children: [
                  GoogleMap(
                    initialCameraPosition: CameraPosition(target: tempPoint!, zoom: 17.5), 
                    myLocationEnabled: false, 
                    onTap: (pos) {
                      if (hasPermission) {
                         try { setModalState(() => tempPoint = pos); } catch(e){}
                      } else {
                         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('請先取得發起人同意才可修改！')));
                      }
                    }, 
                    markers: tempPoint != null ? {Marker(markerId: const MarkerId('temp'), position: tempPoint!)} : {}
                  ),
                  Positioned(
                    top: 20, left: 20, right: 20, 
                    child: Container(
                      padding: const EdgeInsets.all(15), 
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.9), borderRadius: BorderRadius.circular(15)), 
                      child: Text(
                        hasPermission 
                          ? (groupMeetingPoint == null ? '在地圖上點擊來設定集合點，然後按下確認。' : '在地圖上點擊來修改集合點，然後按下確認。')
                          : '這是由 $meetingPointInitiator 發起的集合，需取得同意才可修改或取消。', 
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: hasPermission ? Colors.black : Colors.red)
                      )
                    )
                  ),
                  Positioned(
                    bottom: 30, left: 20, right: 20, 
                    child: hasPermission 
                      ? Row(
                          children: [
                            if (groupMeetingPoint != null)
                              Expanded(
                                flex: 1,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, padding: const EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))), 
                                  onPressed: () { 
                                    setState(() { groupMeetingPoint = null; meetingPointInitiator = null; }); 
                                    updateMapMarkers();
                                    Navigator.pop(context); 
                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已取消集合！'))); 
                                  }, 
                                  child: const Text('取消集合', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold))
                                ),
                              ),
                            if (groupMeetingPoint != null) const SizedBox(width: 10),
                            Expanded(
                              flex: 2,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6292B4), padding: const EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))), 
                                onPressed: () { 
                                  if (tempPoint != null) { 
                                    setState(() { groupMeetingPoint = tempPoint; meetingPointInitiator = '我'; }); 
                                    socket?.emit('setMeetingPoint', {'lat': tempPoint!.latitude, 'lon': tempPoint!.longitude, 'userName': '我'}); 
                                    updateMapMarkers();
                                    Navigator.pop(context); 
                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已設定新的集合點！'))); 
                                  } 
                                }, 
                                child: const Text('📍 確認位置', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold))
                              )
                            )
                          ],
                        )
                      : SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, padding: const EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                            onPressed: () {
                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (ctx) {
                                  Future.delayed(const Duration(seconds: 2), () {
                                    if (Navigator.canPop(ctx)) { Navigator.pop(ctx); }
                                    try {
                                      setModalState(() => hasPermission = true);
                                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('✅ $meetingPointInitiator 已同意！現在您可以修改或取消集合點了。')));
                                    } catch (e) {
                                    }
                                  });
                                  return const AlertDialog(
                                    content: Row(
                                      children: [
                                        CircularProgressIndicator(color: Colors.orange),
                                        SizedBox(width: 20),
                                        Expanded(child: Text("正在向發起人請求權限..."))
                                      ]
                                    )
                                  );
                                }
                              );
                            },
                            child: Text('向 $meetingPointInitiator 請求修改權限', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold))
                          ),
                        )
                  ),
                  Positioned(top: 20, right: 20, child: FloatingActionButton(mini: true, backgroundColor: Colors.white, onPressed: () => Navigator.pop(context), child: const Icon(Icons.close, color: Colors.black)))
                ]
              )
            ),
          ),
        )
      )
    );
  }

  /// 群組即時地圖
  void showRealtimeMapModal() {
    StateSetter? modalSetState;

    updateMapMarkers().then((_) {
      if (modalSetState != null) {
        try { modalSetState!(() {}); } catch (e) {}
      }
    });

    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          modalSetState = setModalState;

          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
              child: Container(
                decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                child: Stack(
                  children: [
                    GoogleMap(
                      initialCameraPosition: CameraPosition(target: mapRegion, zoom: 17.5), 
                      myLocationEnabled: false, 
                      markers: mapMarkers, 
                      onMapCreated: (c) => mapController = c
                    ),
                    Positioned(top: 20, right: 20, child: FloatingActionButton(mini: true, backgroundColor: Colors.white, onPressed: () => Navigator.pop(context), child: const Icon(Icons.close, color: Colors.black))),
                    if (groupMeetingPoint != null) Positioned(bottom: 30, left: 30, right: 30, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, padding: const EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))), onPressed: () => startNavigation(lat: groupMeetingPoint!.latitude, lon: groupMeetingPoint!.longitude), child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.directions, color: Colors.white), SizedBox(width: 10), Text('開始導航至集合點', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold))])))
                  ]
                )
              ),
            ),
          );
        }
      )
    );
  }

  /// 天氣資訊與搜尋
  void showWeatherDetailModal() {
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
              child: Container(
                decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF283593), Color(0xFF1976D2)]), borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 30, 20, 10),
                      child: Row(
                        children: [
                          Expanded(child: Container(height: 45, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)), child: TextField(controller: weatherSearchController, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(hintText: "搜尋城市或地區...", hintStyle: TextStyle(color: Colors.white54), prefixIcon: Icon(Icons.search, color: Colors.white70), border: InputBorder.none), onSubmitted: (val) => searchCityWeather(val, setModalState)))),
                          const SizedBox(width: 10), IconButton(onPressed: () => returnToCurrentLocation(setModalState), icon: const Icon(Icons.my_location, color: Colors.white, size: 26)), IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.cancel, color: Colors.white70, size: 30))
                        ]
                      )
                    ),
                    if (isSearchingWeather) const Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(color: Colors.white))
                    else Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            const SizedBox(height: 20), Text(weatherData['locationName']?.toString() ?? '未知', style: const TextStyle(fontSize: 32, color: Colors.white, fontWeight: FontWeight.bold)), const SizedBox(height: 5), Text('${weatherData['temp']}°', style: const TextStyle(fontSize: 80, color: Colors.white, fontWeight: FontWeight.w200)), Text(weatherData['desc']?.toString() ?? '', style: const TextStyle(fontSize: 20, color: Colors.white70)), const SizedBox(height: 5), Text('最高 ${weatherData['high']}°  最低 ${weatherData['low']}°', style: const TextStyle(fontSize: 16, color: Colors.white)), const SizedBox(height: 40),
                            Container(
                              margin: const EdgeInsets.symmetric(horizontal: 20), padding: const EdgeInsets.symmetric(vertical: 20), decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(25)),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Padding(padding: EdgeInsets.only(left: 20, bottom: 15), child: Text('⏳ 24 小時預報', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                                  SizedBox(height: 100, child: ListView.builder(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 10), itemCount: (weatherData['hourly'] as List? ?? []).length, itemBuilder: (context, i) { var hour = (weatherData['hourly'] as List? ?? [])[i]; return SizedBox(width: 65, child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Text(hour['time']?.toString() ?? '', style: const TextStyle(color: Colors.white70, fontSize: 13)), const SizedBox(height: 10), FaIcon(hour['icon'], color: Colors.white, size: 24), const SizedBox(height: 10), Text('${hour['temp']}°', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16))])); }))
                                ]
                              )
                            ),
                            const SizedBox(height: 15),
                            Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: Row(children: [Expanded(child: _buildGlassCard(FontAwesomeIcons.droplet, "濕度", "${weatherData['humidity']}%")), const SizedBox(width: 15), Expanded(child: _buildGlassCard(FontAwesomeIcons.wind, "風速", "${weatherData['wind']} km/h")), const SizedBox(width: 15), Expanded(child: _buildGlassCard(FontAwesomeIcons.umbrella, "降雨機率", "${weatherData['pop']}%"))])),
                            const SizedBox(height: 40)
                          ]
                        )
                      )
                    )
                  ]
                )
              ),
            ),
          );
        }
      )
    );
  }

  Widget _buildGlassCard(dynamic icon, String label, String val) {
    return Container(padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)), child: Column(children: [FaIcon(icon, color: Colors.white70, size: 24), const SizedBox(height: 10), Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)), const SizedBox(height: 5), Text(val, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold))]));
  }

  /// 匯率計算機
  void showCurrencyModal() {
    twdController.clear(); foreignAmount = 0.0; bool isBaseToTarget = true; 
    String getCurrencyName(String code) => supportedCurrencies.firstWhere((c) => c['code'] == code)['name'] ?? code;
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          // 動態計算匯率
          void calculate(String text) { double input = double.tryParse(text) ?? 0.0; double rate = exchangeRates[targetCurrency]! / exchangeRates[baseCurrency]!; setModalState(() { if (isBaseToTarget) { foreignAmount = input * rate; } else { foreignAmount = input / rate; } }); }
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
              child: Container(
                decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
                child: Column(
                  children: [
                    Padding(padding: const EdgeInsets.all(20), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text("💱 匯率換算", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)), IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.cancel, color: Colors.grey, size: 30))])),
                    SizedBox(height: 45, child: ListView.builder(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 15), itemCount: supportedCurrencies.length, itemBuilder: (context, i) { final currency = supportedCurrencies[i]; bool isSel = targetCurrency == currency['code']; return GestureDetector(onTap: () { setState(() => targetCurrency = currency['code'] ?? 'TWD'); setModalState(() {}); calculate(twdController.text); }, child: Container(margin: const EdgeInsets.only(right: 10), padding: const EdgeInsets.symmetric(horizontal: 15), decoration: BoxDecoration(color: isSel ? const Color(0xFF4ECDC4) : Colors.grey[100], borderRadius: BorderRadius.circular(25)), child: Center(child: Text("${currency['flag']} ${currency['name']}", style: TextStyle(color: isSel ? Colors.white : Colors.black, fontWeight: FontWeight.bold))))); })),
                    const SizedBox(height: 30),
                    Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey[200]!)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(isBaseToTarget ? "輸入 ${getCurrencyName(baseCurrency)} ($baseCurrency)" : "輸入 ${getCurrencyName(targetCurrency)} ($targetCurrency)", style: const TextStyle(color: Colors.grey, fontSize: 12)), TextField(controller: twdController, keyboardType: TextInputType.number, style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold), decoration: const InputDecoration(border: InputBorder.none, hintText: "0"), onChanged: calculate)]))),
                    GestureDetector(onTap: () { setModalState(() { isBaseToTarget = !isBaseToTarget; calculate(twdController.text); }); }, child: Padding(padding: const EdgeInsets.symmetric(vertical: 10), child: Icon(Icons.swap_vert, color: isBaseToTarget ? Colors.grey : const Color(0xFF4ECDC4), size: 35))),
                    Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: Container(width: double.infinity, padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: const Color(0xFFFFF3E0), borderRadius: BorderRadius.circular(20)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(isBaseToTarget ? "換算 $targetCurrency (約)" : "換算 $baseCurrency (約)", style: const TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.bold)), const SizedBox(height: 10), Text(foreignAmount.toStringAsFixed(2), style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.orange)), const SizedBox(height: 5), Text(isBaseToTarget ? "目前匯率：1 $baseCurrency = ${(exchangeRates[targetCurrency]! / exchangeRates[baseCurrency]!).toStringAsFixed(4)} $targetCurrency" : "目前匯率：1 $targetCurrency = ${(exchangeRates[baseCurrency]! / exchangeRates[targetCurrency]!).toStringAsFixed(4)} $baseCurrency", style: const TextStyle(color: Colors.grey, fontSize: 11))])))
                  ]
                )
              ),
            ),
          );
        }
      )
    );
  }

  /// 翻譯功能
  void showTranslationModal({bool autoListen = false}) { 
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          // 處理語音輸入功能
          void handleVoiceListen() async {
            if (!_isListening) {
              bool available = await _speech.initialize(onStatus: (status) { 
                if (status == 'done' || status == 'notListening') { 
                  try { setModalState(() => _isListening = false); } catch(e){} 
                  if (transInput.isNotEmpty) { performTranslation(setModalState); } 
                } 
              }, onError: (error) { 
                debugPrint('語音錯誤: $error'); 
                try { setModalState(() => _isListening = false); } catch(e){} 
              });
              if (available) { 
                try { setModalState(() { _isListening = true; transInput = ''; }); } catch(e){} 
                _speech.listen(onResult: (val) { 
                  try { setModalState(() { transInput = val.recognizedWords; }); } catch(e){} 
                }, localeId: sourceLang); 
              }
            } else { 
              try { setModalState(() => _isListening = false); } catch(e){} 
              _speech.stop(); 
              if (transInput.isNotEmpty) { performTranslation(setModalState); } 
            }
          }
          if (autoListen) { 
            autoListen = false; 
            WidgetsBinding.instance.addPostFrameCallback((_) { handleVoiceListen(); }); 
          }
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
              child: Container(
                decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
                child: Column(
                  children: [
                    Container(padding: const EdgeInsets.all(15), decoration: const BoxDecoration(color: Color(0xFF4285F4), borderRadius: BorderRadius.vertical(top: Radius.circular(25))), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, color: Colors.white)), Row(children: [GestureDetector(onTap: () { showDialog(context: context, builder: (c) => AlertDialog(title: const Text("選擇語言"), content: SizedBox(width: double.maxFinite, child: ListView(shrinkWrap: true, children: supportedLangs.keys.map((k) => ListTile(title: Text(supportedLangs[k]!), onTap: () { try { setModalState(() => sourceLang = k); } catch(e){} Navigator.pop(c); })).toList())))); }, child: Text(supportedLangs[sourceLang]!, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))), IconButton(icon: const Icon(Icons.swap_horiz, color: Colors.white), onPressed: () { try { setModalState(() { var t = sourceLang; sourceLang = targetLang; targetLang = t; }); } catch(e){} }), GestureDetector(onTap: () { showDialog(context: context, builder: (c) => AlertDialog(title: const Text("選擇語言"), content: SizedBox(width: double.maxFinite, child: ListView(shrinkWrap: true, children: supportedLangs.keys.map((k) => ListTile(title: Text(supportedLangs[k]!), onTap: () { try { setModalState(() => targetLang = k); } catch(e){} Navigator.pop(c); })).toList())))); }, child: Text(supportedLangs[targetLang]!, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))]), const SizedBox(width: 48)])),
                    Expanded(child: Padding(padding: const EdgeInsets.all(20), child: Column(children: [Expanded(child: Container(padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(15)), child: TextField(maxLines: null, decoration: InputDecoration(border: InputBorder.none, hintText: _isListening ? "正在聆聽中..." : "輸入文字..."), controller: TextEditingController(text: transInput), onChanged: (v) => transInput = v))), const SizedBox(height: 10), ElevatedButton(onPressed: () => performTranslation(setModalState), child: Text(isTranslating ? "翻譯中" : "翻譯")), const SizedBox(height: 10), Expanded(child: Container(width: double.infinity, padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: const Color(0xFFE3F2FD), borderRadius: BorderRadius.circular(15)), child: SingleChildScrollView(child: Text(transResult.isEmpty ? "翻譯結果" : transResult, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))))), if (capturedImage != null) Padding(padding: const EdgeInsets.only(top: 10), child: Image.file(capturedImage!, height: 80))]))),
                    Padding(padding: const EdgeInsets.only(bottom: 30), child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [GestureDetector(onTap: () async { await handleCamera(setModalState); }, child: const Column(children: [CircleAvatar(backgroundColor: Color(0xFFE3F2FD), child: Icon(Icons.camera_alt, color: Color(0xFF4285F4))), SizedBox(height: 5), Text("相機", style: TextStyle(fontSize: 12))])), GestureDetector(onTap: handleVoiceListen, child: Column(children: [CircleAvatar(backgroundColor: _isListening ? Colors.red[50] : const Color(0xFFE3F2FD), child: Icon(Icons.mic, color: _isListening ? Colors.red : const Color(0xFF4285F4))), const SizedBox(height: 5), Text(_isListening ? "結束錄音" : "語音", style: TextStyle(fontSize: 12, color: _isListening ? Colors.red : Colors.black))]))]))
                  ]
                )
              ),
            ),
          );
        }
      )
    );
  }

  // 頁面邏輯
  void showExpenseModal({bool openAdd = false}) {
    if (participants.isEmpty) { initParticipants(); }
    
    // 開啟新增記帳前，先清空表單狀態
    if (openAdd) {
      titleController.clear();
      amountController.clear();
      selectedPayer = '我';
      editingExpenseId = null;
      selectedExpenseDate = DateTime.now();
      splitMethod = 'avg';
      for(var p in participants) {
        p['selected'] = true;
        p['amount'] = 0.0;
        p['controller'].text = '';
      }
    }

    int currentPage = openAdd ? 1 : 0; // 0=總覽主畫面, 1=新增/編輯畫面, 2=群組結算畫面, 3=進階分攤設定畫面

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            
            // 畫面 0: 記帳系統主首頁
            Widget buildMainView() {
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: () async {
                            DateTime? picked = await showDatePicker(
                              context: context,
                              initialDate: selectedExpenseDate,
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2100),
                            );
                            if (picked != null) {
                              try { setModalState(() => selectedExpenseDate = picked); } catch(e){}
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                            decoration: BoxDecoration(color: const Color(0xFF7BA6BA), borderRadius: BorderRadius.circular(20)),
                            child: Text('${selectedExpenseDate.year}-${selectedExpenseDate.month.toString().padLeft(2, '0')} ▼', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        GestureDetector(
                          onTap: () { try { setModalState(() => currentPage = 2); } catch(e){} }, 
                          child: const CircleAvatar(backgroundColor: Color(0xFFD6E6F2), child: Icon(Icons.group, color: Colors.black87)),
                        )
                      ],
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.all(20), padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFB9D8EC), width: 2)),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(child: Container(padding: const EdgeInsets.symmetric(vertical: 15), decoration: BoxDecoration(color: const Color(0xFFFFC6C6), borderRadius: BorderRadius.circular(10)), child: Center(child: Text("支出 : NT\$ ${formatAmount(myShare)}", style: const TextStyle(fontWeight: FontWeight.bold))))),
                            const SizedBox(width: 10),
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  TextEditingController budgetCtrl = TextEditingController(text: myBudget.toStringAsFixed(0));
                                  showDialog(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Text("設定個人預算"),
                                      content: TextField(
                                        controller: budgetCtrl,
                                        keyboardType: TextInputType.number,
                                        decoration: const InputDecoration(prefixText: "NT\$ "),
                                      ),
                                      actions: [
                                        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("取消")),
                                        TextButton(
                                          onPressed: () {
                                            try { setModalState(() => myBudget = double.tryParse(budgetCtrl.text) ?? myBudget); } catch(e){}
                                            Navigator.pop(ctx);
                                          }, 
                                          child: const Text("確認")
                                        ),
                                      ],
                                    )
                                  );
                                },
                                child: Container(padding: const EdgeInsets.symmetric(vertical: 15), decoration: BoxDecoration(color: const Color(0xFFD4EAC8), borderRadius: BorderRadius.circular(10)), child: Center(child: Text("預算 : NT\$ ${formatAmount(myBudget)}", style: const TextStyle(fontWeight: FontWeight.bold)))),
                              )
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),
                        Text("結餘 : NT\$ ${formatAmount(myBudget - myShare)}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))
                      ],
                    ),
                  ),
                  Expanded(
                    child: Container(
                      width: double.infinity, padding: const EdgeInsets.all(20),
                      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
                      child: Stack(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text("歷史紀錄", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Expanded(
                                child: ListView.builder(
                                  itemCount: expenses.length,
                                  itemBuilder: (context, index) {
                                    final exp = expenses[index];
                                    double myExpenseShare = 0.0;
                                    var parts = exp['participants'] ?? exp['splits'] ?? [];
                                    for (var split in parts) {
                                      if (split['name'] == '我' || split['user_name'] == '我') {
                                        myExpenseShare = double.tryParse(split['amount'].toString()) ?? 0.0;
                                      }
                                    }

                                    return GestureDetector(
                                      onTap: () {
                                        // 點擊歷史紀錄進入編輯模式
                                        titleController.text = exp['title']?.toString() ?? '';
                                        amountController.text = exp['amount']?.toString() ?? '';
                                        
                                        String pName = exp['payer_name']?.toString() ?? '我';
                                        if (participants.any((p) => p['name'] == pName)) {
                                          selectedPayer = pName;
                                        } else {
                                          selectedPayer = participants.first['name'];
                                        }

                                        editingExpenseId = exp['id'];
                                        
                                        var timeParts = (exp['time']?.toString() ?? '12:00').split(':');
                                        selectedExpenseDate = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day, int.tryParse(timeParts[0])??12, int.tryParse(timeParts[1])??0);
                                        
                                        for(var p in participants) {
                                           p['selected'] = false;
                                           p['amount'] = 0.0;
                                           p['controller'].text = '';
                                        }
                                        
                                        double firstAmt = -1;
                                        bool allEqual = true;
                                        for (var ep in parts) {
                                          try {
                                            var match = participants.firstWhere((p) => p['name'] == (ep['name'] ?? ep['user_name']));
                                            match['selected'] = true;
                                            match['amount'] = double.tryParse(ep['amount'].toString()) ?? 0.0;
                                            match['controller'].text = formatAmount(match['amount']);
                                            if (firstAmt == -1) {
                                              firstAmt = match['amount'];
                                            } else if (firstAmt != match['amount']) {
                                              allEqual = false;
                                            }
                                          } catch(e) {
                                            debugPrint(e.toString());
                                          }
                                        }
                                        splitMethod = allEqual ? 'avg' : 'exact';

                                        try { setModalState(() => currentPage = 1); } catch(e){}
                                      },
                                      child: _buildExpenseItem(
                                        exp['emoji']?.toString() ?? "💰", 
                                        exp['title']?.toString() ?? "未命名", 
                                        "${exp['category']?.toString() ?? '一般'} ${exp['time']?.toString() ?? ''} ${exp['note']?.toString() ?? ''}", 
                                        "-NT\$${formatAmount(myExpenseShare)}"
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                          Positioned(
                            bottom: 20, left: 0, right: 0,
                            child: Center(
                              child: GestureDetector(
                                onTap: () {
                                  // 重置準備新增
                                  titleController.clear();
                                  amountController.clear();
                                  selectedPayer = participants.isNotEmpty ? participants.first['name'] : '我';
                                  editingExpenseId = null;
                                  selectedExpenseDate = DateTime.now();
                                  splitMethod = 'avg';
                                  for(var p in participants) { p['selected'] = true; p['amount'] = 0.0; p['controller'].text = ''; }
                                  try { setModalState(() => currentPage = 1); } catch(e){}
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                                  decoration: BoxDecoration(color: const Color(0xFFAEDDF4), borderRadius: BorderRadius.circular(30), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 5))]),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text("記 帳 ", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF335870))),
                                      Icon(Icons.add_circle, color: Color(0xFF5582A1)),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                  )
                ],
              );
            }

            // 畫面 1: 新增/編輯消費紀錄畫面
            Widget buildAddView() {
              return Container(
                decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          GestureDetector(onTap: () { try { setModalState(() => currentPage = 0); } catch(e){} }, child: const Icon(Icons.arrow_back_ios)),
                          Expanded(child: Center(child: Text(editingExpenseId == null ? "新增紀錄" : "編輯紀錄", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)))),
                          
                          if (editingExpenseId != null)
                            GestureDetector(
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text("刪除紀錄"),
                                    content: const Text("確定要刪除這筆紀錄嗎？"),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("取消", style: TextStyle(color: Colors.grey))),
                                      TextButton(
                                        onPressed: () async {
                                          Navigator.pop(ctx);
                                          try {
                                            await dio.delete('http://10.0.2.2:3000/api/trips/${activeTrip['id']}/expenses/$editingExpenseId');
                                            refreshExpenses();
                                            try { setModalState(() => currentPage = 0); } catch(e){}
                                          } catch (e) {
                                            debugPrint("刪除失敗: $e");
                                            expenses.removeWhere((item) => item['id'] == editingExpenseId);
                                            _calculateBalances();
                                            try { setModalState(() => currentPage = 0); } catch(e){}
                                          }
                                        },
                                        child: const Text("刪除", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                                      )
                                    ]
                                  )
                                );
                              },
                              child: const Icon(Icons.delete, color: Colors.redAccent, size: 26)
                            )
                          else
                            const SizedBox(width: 24)
                        ],
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () async {
                                      DateTime? d = await showDatePicker(context: context, initialDate: selectedExpenseDate, firstDate: DateTime(2000), lastDate: DateTime(2100));
                                      if (d != null) { 
                                        try { setModalState(() => selectedExpenseDate = DateTime(d.year, d.month, d.day, selectedExpenseDate.hour, selectedExpenseDate.minute)); } catch(e){} 
                                      }
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12), decoration: BoxDecoration(color: const Color(0xFFF6F6F6), borderRadius: BorderRadius.circular(10)),
                                      child: Row(children: [const Icon(Icons.calendar_today, size: 16, color: Colors.grey), const SizedBox(width: 8), Text("${selectedExpenseDate.year}-${selectedExpenseDate.month.toString().padLeft(2,'0')}-${selectedExpenseDate.day.toString().padLeft(2,'0')}")]),
                                    ),
                                  )
                                ),
                                const SizedBox(width: 15),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () async {
                                      TimeOfDay? t = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(selectedExpenseDate));
                                      if (t != null) { 
                                        try { setModalState(() => selectedExpenseDate = DateTime(selectedExpenseDate.year, selectedExpenseDate.month, selectedExpenseDate.day, t.hour, t.minute)); } catch(e){} 
                                      }
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12), decoration: BoxDecoration(color: const Color(0xFFF6F6F6), borderRadius: BorderRadius.circular(10)),
                                      child: Row(children: [const Icon(Icons.access_time, size: 16, color: Colors.grey), const SizedBox(width: 8), Text("${selectedExpenseDate.hour.toString().padLeft(2,'0')}:${selectedExpenseDate.minute.toString().padLeft(2,'0')}")]),
                                    ),
                                  )
                                ),
                              ]
                            ),
                            const SizedBox(height: 15),
                            Container(padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: const Color(0xFFF6F6F6), borderRadius: BorderRadius.circular(10)), child: TextField(controller: titleController, decoration: const InputDecoration.collapsed(hintText: "品項"))),
                            const SizedBox(height: 15),
                            Row(
                              children: [
                                Expanded(
                                  flex: 3, 
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5), 
                                    decoration: BoxDecoration(color: const Color(0xFFF6F6F6), borderRadius: BorderRadius.circular(10)), 
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<String>(
                                        value: 'TWD', 
                                        items: const [DropdownMenuItem<String>(value: 'TWD', child: Text("TWD (NT\$)"))], 
                                        onChanged: null
                                      )
                                    )
                                  )
                                ),
                                const SizedBox(width: 15),
                                Expanded(
                                  flex: 5, 
                                  child: Container(
                                    padding: const EdgeInsets.all(15), 
                                    decoration: BoxDecoration(color: const Color(0xFFFDF2F2), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.red[200]!)), 
                                    child: TextField(
                                      controller: amountController, 
                                      keyboardType: TextInputType.number, 
                                      decoration: const InputDecoration.collapsed(hintText: "總金額", hintStyle: TextStyle(color: Colors.redAccent)),
                                      onChanged: (v) { try { setModalState((){}); } catch(e){} },
                                    )
                                  )
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            const Text("誰先付錢", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
                            const SizedBox(height: 5),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 15), decoration: BoxDecoration(color: const Color(0xFFF6F6F6), borderRadius: BorderRadius.circular(10)), 
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: participants.any((p) => p['name'] == selectedPayer) ? selectedPayer : participants.first['name'], 
                                  isExpanded: true, 
                                  items: participants.map<DropdownMenuItem<String>>((p) => DropdownMenuItem<String>(value: p['name']?.toString() ?? '未知', child: Text(p['name']?.toString() ?? '未知'))).toList(), 
                                  onChanged: (v) { try { setModalState(() => selectedPayer = v ?? participants.first['name']); } catch(e){} }
                                )
                              )
                            ),
                            const SizedBox(height: 20),
                            const Text("如何分", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
                            const SizedBox(height: 5),
                            
                            GestureDetector(
                              onTap: () { try { setModalState(() => currentPage = 3); } catch(e){} },
                              child: Container(
                                padding: const EdgeInsets.all(15),
                                decoration: BoxDecoration(color: const Color(0xFFF6F6F6), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFF5582A1).withValues(alpha:0.3))),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(splitMethod == 'avg' 
                                      ? "平均分攤 (${participants.where((p)=>p['selected']).length} 人)" 
                                      : "精確分攤", 
                                      style: const TextStyle(fontSize: 16, color: Colors.black87, fontWeight: FontWeight.bold)),
                                    const Text("進階設定 ➡️", style: TextStyle(color: Color(0xFF5582A1), fontWeight: FontWeight.bold, fontSize: 12))
                                  ]
                                )
                              )
                            ),
                            
                            const SizedBox(height: 20),
                            Container(height: 100, padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: const Color(0xFFF6F6F6), borderRadius: BorderRadius.circular(10)), child: const TextField(maxLines: null, decoration: InputDecoration.collapsed(hintText: "備註"))),
                            const SizedBox(height: 30),
                            Center(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD6F0FA), padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                                onPressed: () async {
                                  double amt = double.tryParse(amountController.text) ?? 0;
                                  List<Map<String, dynamic>> finalSplits = generateFinalSplits(amt);
                                  String fTime = "${selectedExpenseDate.hour.toString().padLeft(2,'0')}:${selectedExpenseDate.minute.toString().padLeft(2,'0')}";
                                  
                                  try {
                                    if (editingExpenseId != null) {
                                      await dio.put('http://10.0.2.2:3000/api/trips/${activeTrip['id']}/expenses/$editingExpenseId', data: {"title": titleController.text, "amount": amt, "payer_name": selectedPayer, "participants": finalSplits, "time": fTime});
                                    } else {
                                      await dio.post('http://10.0.2.2:3000/api/trips/${activeTrip['id']}/expenses', data: {"title": titleController.text, "amount": amt, "payer_name": selectedPayer, "participants": finalSplits, "time": fTime});
                                    }
                                    refreshExpenses();
                                    try { setModalState(() => currentPage = 0); } catch(e){} 
                                  } catch (e) { 
                                    debugPrint("儲存失敗: $e"); 
                                    // 儲存至本地
                                    if (editingExpenseId != null) {
                                      final idx = expenses.indexWhere((e) => e['id'] == editingExpenseId);
                                      if (idx != -1) {
                                        expenses[idx]['title'] = titleController.text;
                                        expenses[idx]['amount'] = amt;
                                        expenses[idx]['payer_name'] = selectedPayer;
                                        expenses[idx]['participants'] = finalSplits;
                                        expenses[idx]['time'] = fTime;
                                      }
                                    } else {
                                      expenses.insert(0, {
                                        'id': DateTime.now().millisecondsSinceEpoch,
                                        'title': titleController.text,
                                        'amount': amt,
                                        'payer_name': selectedPayer,
                                        'emoji': '💰',
                                        'category': '一般',
                                        'time': fTime,
                                        'note': '',
                                        'participants': finalSplits
                                      });
                                    }
                                    _calculateBalances();
                                    try { setModalState(() => currentPage = 0); } catch(e){} 
                                  }
                                },
                                child: Text(editingExpenseId == null ? "新 增" : "儲 存", style: const TextStyle(color: Color(0xFF335870), fontWeight: FontWeight.bold, fontSize: 16))
                              ),
                            ),
                            const SizedBox(height: 50),
                          ],
                        ),
                      ),
                    )
                  ],
                ),
              );
            }

            // 畫面 2: 群組帳務結算
            Widget buildSettleView() {
              return Container(
                decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          GestureDetector(onTap: () { try { setModalState(() => currentPage = 0); } catch(e){} }, child: const Icon(Icons.arrow_back_ios)),
                          const Expanded(child: Center(child: Text("群組結算", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)))),
                          const SizedBox(width: 24)
                        ],
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            Container(
                              color: const Color(0xFFF2F5F6),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              child: Column(
                                children: memberBalances.entries.map<Widget>((e) {
                                  String emoji = "👤";
                                  if (e.key == '我') { emoji = "🐷"; }
                                  else if (e.key == 'haha') { emoji = "🐾"; }
                                  else if (e.key == 'bee') { emoji = "🐝"; }
                                  else if (e.key == 'ryan') { emoji = "🦁"; }
                                  return _buildSettleBar(emoji, e.key, e.value.round(), e.value >= 0);
                                }).toList(),
                              ),
                            ),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(20),
                              color: const Color(0xFFF2F5F6),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: expenses.map<Widget>((exp) {
                                  String payer = exp['payer_name']?.toString() ?? '我';
                                  double amount = double.tryParse(exp['amount'].toString()) ?? 0.0;
                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(exp['time']?.toString() ?? '今日', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black54)),
                                      const SizedBox(height: 5),
                                      Container(
                                        padding: const EdgeInsets.all(15), color: const Color(0xFFD6F0FA), 
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween, 
                                          children: [
                                            Text("${exp['title']}  ($payer 先付 NT\$${amount.toStringAsFixed(0)})", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)), 
                                          ]
                                        )
                                      ),
                                      const SizedBox(height: 15),
                                    ],
                                  );
                                }).toList(),
                              ),
                            )
                          ],
                        ),
                      ),
                    )
                  ],
                ),
              );
            }

            // 畫面 3: 分攤設定
            Widget buildSplitConfigView() {
              double totalAmt = double.tryParse(amountController.text) ?? 0.0;
              double filledSum = participants.where((p) => p['selected'] && p['amount'] != null).fold(0.0, (s, p) => s + (p['amount'] as double));
              double remainder = totalAmt - filledSum;
              int selectedCount = participants.where((p) => p['selected']).length;

              return Container(
                decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(15),
                      decoration: const BoxDecoration(color: Color(0xFF5582A1), borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
                      child: Row(
                        children: [
                          IconButton(icon: const Icon(Icons.check, color: Colors.white), onPressed: () { try { setModalState(()=>currentPage=1); } catch(e){} }),
                          const Expanded(child: Center(child: Text("分攤設定", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)))),
                          const SizedBox(width: 48)
                        ]
                      )
                    ),
                    Padding(
                      padding: const EdgeInsets.all(15),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () { try { setModalState(()=>splitMethod='avg'); } catch(e){} },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(color: splitMethod == 'avg' ? const Color(0xFFD6F0FA) : Colors.grey[200], borderRadius: const BorderRadius.horizontal(left: Radius.circular(10))),
                                child: Center(child: Text("平均分攤", style: TextStyle(fontWeight: FontWeight.bold, color: splitMethod == 'avg' ? const Color(0xFF335870) : Colors.grey)))
                              )
                            )
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () { try { setModalState(()=>splitMethod='exact'); } catch(e){} },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(color: splitMethod == 'exact' ? const Color(0xFFD6F0FA) : Colors.grey[200], borderRadius: const BorderRadius.horizontal(right: Radius.circular(10))),
                                child: Center(child: Text("精確分攤", style: TextStyle(fontWeight: FontWeight.bold, color: splitMethod == 'exact' ? const Color(0xFF335870) : Colors.grey)))
                              )
                            )
                          )
                        ]
                      )
                    ),
                    if (splitMethod == 'exact')
                       Container(
                         padding: const EdgeInsets.all(10), color: remainder < 0 ? Colors.red[50] : const Color(0xFFE8F5E9), width: double.infinity,
                         child: Column(
                           children: [
                              Text("總計 NT\$ ${formatAmount(totalAmt)}", style: const TextStyle(fontWeight: FontWeight.bold)),
                              Text("剩餘 NT\$ ${formatAmount(remainder)}", style: TextStyle(color: remainder < 0 ? Colors.red : Colors.green[800], fontWeight: FontWeight.bold, fontSize: 16))
                           ]
                         )
                       ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: participants.length,
                        itemBuilder: (ctx, i) {
                           var p = participants[i];
                           return ListTile(
                              leading: Checkbox(
                                activeColor: const Color(0xFF5582A1),
                                value: p['selected'],
                                onChanged: (v) {
                                   try {
                                     setModalState(() {
                                       p['selected'] = v;
                                       if (v == false) { p['amount'] = 0.0; p['controller'].text = ''; }
                                     });
                                   } catch(e){}
                                }
                              ),
                              title: Text(p['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                              trailing: splitMethod == 'exact' && p['selected']
                                ? SizedBox(
                                    width: 120,
                                    child: TextField(
                                      controller: p['controller'],
                                      keyboardType: TextInputType.number,
                                      textAlign: TextAlign.right,
                                      decoration: InputDecoration(prefixText: "NT\$ ", contentPadding: const EdgeInsets.symmetric(horizontal: 10), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                                      onChanged: (val) {
                                         p['amount'] = double.tryParse(val) ?? 0.0;
                                         try { setModalState((){}); } catch(e){} 
                                      }
                                    )
                                  )
                                : (splitMethod == 'avg' && p['selected']
                                    ? Text("NT\$ ${selectedCount > 0 ? formatAmount(totalAmt / selectedCount) : '0'}", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[600]))
                                    : null
                                  )
                           );
                        }
                      )
                    )
                  ]
                )
              );
            }

            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
                child: Container(
                  decoration: const BoxDecoration(color: Color(0xFFE8F1F8), borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
                  child: currentPage == 0 ? buildMainView() 
                       : currentPage == 1 ? buildAddView() 
                       : currentPage == 2 ? buildSettleView() 
                       : buildSplitConfigView(),
                ),
              ),
            );
          }
        );
      }
    );
  }

  /// 歷史記帳清單
  Widget _buildExpenseItem(String emoji, String title, String subtitle, String amount) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15), padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 5, offset: Offset(0, 2))]),
      child: Row(
        children: [
          CircleAvatar(backgroundColor: Colors.transparent, child: Text(emoji, style: const TextStyle(fontSize: 24))),
          const SizedBox(width: 15),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), const SizedBox(height: 5), Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12))])),
          Text(amount, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: amount.startsWith('-NT\$0') ? Colors.grey : Colors.black))
        ],
      ),
    );
  }

  /// 結算畫面
  Widget _buildSettleBar(String emoji, String name, int amount, bool isPositive) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      child: Row(
        children: [
          if (!isPositive) Expanded(child: Align(alignment: Alignment.centerRight, child: Text("- NT\$${amount.abs()}", style: const TextStyle(color: Color(0xFF5582A1), fontWeight: FontWeight.bold)))),
          if (!isPositive) Container(width: 60, height: 30, margin: const EdgeInsets.symmetric(horizontal: 10), decoration: BoxDecoration(color: const Color(0xFFFFC6C6), borderRadius: BorderRadius.circular(5))),
          
          CircleAvatar(backgroundColor: Colors.white, child: Text(emoji, style: const TextStyle(fontSize: 20))),
          const SizedBox(width: 10),
          SizedBox(width: 60, child: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
          
          if (isPositive) Container(width: 100, height: 30, margin: const EdgeInsets.symmetric(horizontal: 10), decoration: BoxDecoration(color: const Color(0xFFD4EAC8), borderRadius: BorderRadius.circular(5))),
          if (isPositive) Expanded(child: Align(alignment: Alignment.centerLeft, child: Text("+ NT\$$amount", style: const TextStyle(color: Color(0xFF5582A1), fontWeight: FontWeight.bold)))),
        ],
      ),
    );
  }

  // 8. 模組化 UI 區塊

  /// 首頁 UI：天氣與記帳
  Widget _buildWeatherAndExpense(BoxDecoration cardStyle) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 左半部：天氣
          Expanded(
            flex: 6,
            child: GestureDetector(
              onTap: showWeatherDetailModal,
              child: Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(color: const Color(0xFF24293D), borderRadius: BorderRadius.circular(20)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, 
                  mainAxisAlignment: MainAxisAlignment.spaceBetween, 
                  children: [
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('${weatherData['locationName']}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), FaIcon(weatherData['icon'], color: Colors.white, size: 20)]),
                    const SizedBox(height: 10),
                    Text('${weatherData['temp']}°', style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.w300)),
                    const SizedBox(height: 10),
                    Align(alignment: Alignment.centerRight, child: Text('${weatherData['desc']}\n最高${weatherData['high']}° 最低${weatherData['low']}°', textAlign: TextAlign.right, style: const TextStyle(color: Colors.white70, fontSize: 10))),
                    const SizedBox(height: 10),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: (weatherData['hourly'] as List? ?? []).take(5).map((hourData) { return Column(children: [Text(hourData['time']?.toString() ?? '', style: const TextStyle(color: Colors.white70, fontSize: 9)), const SizedBox(height: 4), FaIcon(hourData['icon'], color: Colors.white, size: 16), const SizedBox(height: 4), Text('${hourData['temp']}°', style: const TextStyle(color: Colors.white, fontSize: 11))]); }).toList())
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // 右半部：記帳
          Expanded(
            flex: 4,
            child: GestureDetector(
              onTap: () => showExpenseModal(openAdd: false), 
              child: Container(
                padding: const EdgeInsets.all(15), decoration: cardStyle,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, 
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('記帳', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), 
                    const SizedBox(height: 5), 
                    const Text('目前花費', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)), 
                    Text('\$${formatAmount(myShare)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                    const SizedBox(height: 5), 
                    const Text('群組結餘', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)), 
                    Text(myBalance >= 0 ? '+\$${formatAmount(myBalance)}' : '-\$${formatAmount(myBalance.abs())}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: myBalance >= 0 ? Colors.green[800] : Colors.red[800])),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.bottomRight,
                      child: GestureDetector(
                        onTap: () => showExpenseModal(openAdd: true), 
                        child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(20)), child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.add, size: 16, color: Colors.black87), SizedBox(width: 4), Text('記一筆', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 13))])),
                      )
                    )
                  ],
                ),
              ),
            ),
          ),
        ],
      )
    );
  }

  /// 首頁 UI：交通
  Widget _buildTransport(BoxDecoration cardStyle, BoxDecoration btnStyle) {
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(15), decoration: cardStyle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('交通', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: ['Uber', 'Ubike', '公車', 'iRent', 'go\nShare'].map((name) {
              return GestureDetector(
                onTap: () => handleTransportPress(name.replaceAll('\n', '')),
                child: Container(width: 55, height: 60, decoration: btnStyle, child: Center(child: Text(name, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)))),
              );
            }).toList(),
          )
        ],
      ),
    );
  }

  /// 首頁 UI：Google Places 附近熱門景點推薦
  Widget _buildPlacesSlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isTravelMode) ...[
          const Text('📍 附近探索', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
        ],
        SizedBox(
          height: 180,
          child: isLoadingPlaces
              ? const Center(child: CircularProgressIndicator(color: Colors.white))
              : nearbyPlaces.isEmpty
                  ? const Center(child: Text("附近暫無推薦景點", style: TextStyle(color: Colors.grey)))
                  : PageView.builder(
                      controller: _pageController, itemCount: nearbyPlaces.length,
                      itemBuilder: (context, index) {
                        final place = nearbyPlaces[index];
                        return Container(
                          margin: const EdgeInsets.only(right: 15),
                          decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), image: DecorationImage(image: NetworkImage(place['image']), fit: BoxFit.cover)),
                          child: Stack(
                            children: [
                              Positioned(top: 15, left: 15, child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.85), borderRadius: BorderRadius.circular(20)), child: Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.place, size: 16, color: Colors.redAccent), const SizedBox(width: 5), Text(place['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)), const SizedBox(width: 8), const Icon(Icons.star, size: 14, color: Colors.amber), Text(place['rating'], style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))]))),
                              Positioned(bottom: 15, right: 15, child: GestureDetector(onTap: () => startNavigation(lat: place['lat'], lon: place['lon']), child: Container(padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8), decoration: BoxDecoration(color: isTravelMode ? const Color(0xFF6292B4) : const Color(0xFFC07B57), borderRadius: BorderRadius.circular(20)), child: const Row(children: [Text('查看地圖 ', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)), Icon(Icons.directions, color: Colors.white, size: 16)])))),
                            ],
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  /// 首頁 UI：行程導航與群組位置分享
  Widget _buildNextStopAndShare(BoxDecoration cardStyle, BoxDecoration btnStyle) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), image: const DecorationImage(image: NetworkImage('https://media.wired.com/photos/59269cd37034dc5f91bec0f1/master/pass/GoogleMapTA.jpg'), fit: BoxFit.cover, opacity: 0.3), color: Colors.white),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('下一站', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), 
                  const SizedBox(height: 10),
                  Text(nextStop != null ? '目的地：${nextStop!['title']}' : '🎉 今日行程已結束', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  if (nextStop != null) Padding(padding: const EdgeInsets.only(top: 5), child: Text('預計 ${nextStop!['time']} 出發', style: const TextStyle(fontSize: 12, color: Colors.black54))),
                  const SizedBox(height: 15),
                  if (nextStop != null) Center(child: GestureDetector(onTap: () => startNavigation(destinationName: nextStop!['title']), child: Container(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10), decoration: btnStyle, child: const Text('開始導航', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))))
                ],
              ),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(15), decoration: cardStyle,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('分享位置', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), Switch(value: isSharingLocation, onChanged: toggleSharing, activeThumbColor: Colors.white, activeTrackColor: btnStyle.color)]),
                  const SizedBox(height: 15),
                  GestureDetector(onTap: showSetMeetingPointModal, child: Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 12), decoration: btnStyle, child: const Center(child: Text('集合！', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))))),
                  const SizedBox(height: 10),
                  GestureDetector(onTap: showRealtimeMapModal, child: Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 12), decoration: btnStyle, child: const Center(child: Text('查看位置', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))))),
                ],
              ),
            ),
          ),
        ],
      )
    );
  }

  /// 首頁 UI：語音翻譯與即時匯率
  Widget _buildTranslateAndCurrency(BoxDecoration cardStyle, BoxDecoration btnStyle) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => showTranslationModal(),
              child: Container(
                padding: const EdgeInsets.all(15), decoration: cardStyle,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('翻譯', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), 
                    const SizedBox(height: 15),
                    Center(child: IconButton(onPressed: () => showTranslationModal(autoListen: true), icon: const Icon(Icons.mic), iconSize: 50, color: btnStyle.color, splashColor: Colors.white30)),
                    const SizedBox(height: 10), 
                    Center(child: Text('點擊麥克風語音翻譯', style: TextStyle(color: btnStyle.color, fontSize: 10, fontWeight: FontWeight.bold))), 
                    const SizedBox(height: 15),
                    Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 10), decoration: btnStyle, child: const Center(child: Text('更多翻譯', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: GestureDetector(
              onTap: showCurrencyModal, 
              child: Container(
                padding: const EdgeInsets.all(15), decoration: cardStyle,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(children: [Text('匯率 ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), Text('(點擊計算機)', style: TextStyle(fontSize: 10))]), 
                    const SizedBox(height: 15),
                    Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8), decoration: btnStyle, child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('1', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), _buildCurrencyDropdown(baseCurrency, (val) { if (val != null) { setState(() => baseCurrency = val); } })])),
                    const SizedBox(height: 15),
                    Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8), decoration: btnStyle, child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text((exchangeRates[targetCurrency]! / exchangeRates[baseCurrency]!).toStringAsFixed(2), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), _buildCurrencyDropdown(targetCurrency, (val) { if (val != null) { setState(() => targetCurrency = val); } })])),
                  ],
                ),
              ),
            ),
          ),
        ],
      )
    );
  }

  // 9. 總頁面
  
  @override
  Widget build(BuildContext context) {
    // 依據當下模式 (旅行/非旅行) 切換色調
    final Color bgColor = isTravelMode ? const Color(0xFFF4F6F9) : const Color(0xFF7C8A66); 
    final BoxDecoration cardStyle = BoxDecoration(color: isTravelMode ? const Color(0xFFD6E6F2) : const Color(0xFFB1C096), borderRadius: BorderRadius.circular(20));
    final BoxDecoration btnStyle = BoxDecoration(color: isTravelMode ? const Color(0xFF6292B4) : const Color(0xFF556E54), borderRadius: BorderRadius.circular(12));

    return Scaffold(
      backgroundColor: bgColor, 
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 右上角切換開關
              Padding(
                padding: const EdgeInsets.only(bottom: 15),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(isTravelMode ? '🛫 旅行中' : '🏠 日常模式', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isTravelMode ? Colors.black87 : Colors.white)),
                    Switch(value: isTravelMode, onChanged: (v) => setState(() => isTravelMode = v), activeThumbColor: Colors.white, activeTrackColor: const Color(0xFF6292B4), inactiveThumbColor: Colors.white, inactiveTrackColor: const Color(0xFF556E54)),
                  ],
                ),
              ),

              // 依據模式重新排卡片順序
              if (isTravelMode) ...[
                _buildWeatherAndExpense(cardStyle), const SizedBox(height: 15),
                _buildTransport(cardStyle, btnStyle), const SizedBox(height: 15),
                _buildPlacesSlider(), const SizedBox(height: 15),
                _buildNextStopAndShare(cardStyle, btnStyle), const SizedBox(height: 15),
                _buildTranslateAndCurrency(cardStyle, btnStyle),
              ] else ...[
                _buildPlacesSlider(), const SizedBox(height: 15),
                _buildWeatherAndExpense(cardStyle), const SizedBox(height: 15),
                _buildTransport(cardStyle, btnStyle), const SizedBox(height: 15),
                _buildTranslateAndCurrency(cardStyle, btnStyle),
              ],
              
              const SizedBox(height: 80), 
            ],
          ),
        ),
      ),
      // 畫面右下角： AI 助理
      floatingActionButton: FloatingActionButton(
        onPressed: showAiChatModal, 
        backgroundColor: btnStyle.color,
        child: const Icon(Icons.smart_toy, color: Colors.white), 
      ),
    );
  }
}
