// 
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'plan_provider.dart';
import 'luggage_screen.dart';
import 'chat_room_screen.dart'; 
import 'add_spot_screen.dart'; 
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart'; 

class ItineraryScreen extends StatefulWidget {
  final String planId;
  final String title;
  const ItineraryScreen({super.key, required this.planId, required this.title});
  
  @override
  State<ItineraryScreen> createState() => _ItineraryScreenState();
}

class _ItineraryScreenState extends State<ItineraryScreen> {
  Set<String> _expandedDays = {'DAY 1'};
  bool _isFirstLoadCalculated = false; 
  
  // 🔒 全局安全鎖狀態
  bool _isLocked = false; 

  final Map<String, TimeOfDay> _dayStartTimes = {
    'DAY 1': const TimeOfDay(hour: 9, minute: 0),
    'DAY 2': const TimeOfDay(hour: 9, minute: 0),
    'DAY 3': const TimeOfDay(hour: 9, minute: 0),
  };

  // 🛑 記得在這裡填入你的 Google API Key！
  final String _googleApiKey = ''; 

  void _pickDayStartTime(BuildContext context, String dayName) {
    if (_isLocked) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('🔒 行程已鎖定，請先點擊右上角解鎖！'), duration: Duration(seconds: 1), behavior: SnackBarBehavior.floating));
      return;
    }

    final initialTime = _dayStartTimes[dayName] ?? const TimeOfDay(hour: 9, minute: 0);
    showTimePicker(
      context: context,
      initialTime: initialTime,
      helpText: '設定 $dayName 出發時間',
    ).then((picked) {
      if (picked != null) {
        setState(() {
          _dayStartTimes[dayName] = picked;
        });
      }
    });
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  TimeOfDay _addMinutesToTime(TimeOfDay time, int minutesToadd) {
    int totalMinutes = time.hour * 60 + time.minute + minutesToadd;
    int newHour = (totalMinutes ~/ 60) % 24;
    int newMinute = totalMinutes % 60;
    return TimeOfDay(hour: newHour, minute: newMinute);
  }

  int _parseTravelMinutes(String? travelTimeText) {
    if (travelTimeText == null || travelTimeText.isEmpty || travelTimeText == "計算中...") return 15;
    int minutes = 0;
    if (travelTimeText.contains('小時')) {
      final hourMatch = RegExp(r'(\d+)\s*小時').firstMatch(travelTimeText);
      if (hourMatch != null) minutes += int.parse(hourMatch.group(1)!) * 60;
    }
    final minMatch = RegExp(r'(\d+)\s*分鐘').firstMatch(travelTimeText);
    if (minMatch != null) {
      minutes += int.parse(minMatch.group(1)!);
    } else {
      final pureNumMatch = RegExp(r'(\d+)').firstMatch(travelTimeText);
      if (pureNumMatch != null && !travelTimeText.contains('小時')) {
        minutes += int.parse(pureNumMatch.group(1)!);
      }
    }
    return minutes == 0 ? 15 : minutes;
  }

  void _autoCalculateMissingTimes(List<dynamic> itineraryList) {
    for (var dayData in itineraryList) {
      List items = dayData['items'] ?? [];
      for (int i = 0; i < items.length - 1; i++) {
        if (items[i]['travelTime'] == null || items[i]['travelTime'] == "15 分鐘") {
          _recalculateTravelTime(items[i], items[i + 1], items[i]['transportMode'] ?? 'driving');
        }
      }
    }
  }

  void _showTransportPicker(BuildContext context, Map<String, dynamic> spot, Map<String, dynamic>? nextSpot, String dayKey) {
    if (_isLocked) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('🔒 行程已鎖定，請先點擊右上角解鎖！'), duration: Duration(seconds: 1), behavior: SnackBarBehavior.floating));
      return;
    }
    if (nextSpot == null) return; 

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            const Padding(padding: EdgeInsets.all(15), child: Center(child: Text('選擇交通方式', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)))),
            ListTile(
              leading: const Icon(Icons.directions_car, color: Colors.blue), title: const Text('開車'),
              onTap: () { Navigator.pop(ctx); _recalculateTravelTime(spot, nextSpot, 'driving'); },
            ),
            ListTile(
              leading: const Icon(Icons.directions_transit, color: Colors.green), title: const Text('大眾運輸'),
              onTap: () { Navigator.pop(ctx); _recalculateTravelTime(spot, nextSpot, 'transit'); },
            ),
            ListTile(
              leading: const Icon(Icons.directions_walk, color: Colors.orange), title: const Text('走路'),
              onTap: () { Navigator.pop(ctx); _recalculateTravelTime(spot, nextSpot, 'walking'); },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _recalculateTravelTime(Map<String, dynamic> spot, Map<String, dynamic> nextSpot, String mode) async {
    if (!mounted) return;
    setState(() => spot['travelTime'] = "計算中...");

    final s = spot['coordinate'];     
    final e = nextSpot['coordinate']; 
    final url = 'https://maps.googleapis.com/maps/api/directions/json?origin=${s['lat']},${s['lng']}&destination=${e['lat']},${e['lng']}&mode=$mode&key=$_googleApiKey&language=zh-TW';
    
    try {
      final res = await http.get(Uri.parse(url));
      final data = json.decode(res.body);
      if (data['status'] == 'OK' && mounted) {
        setState(() {
          spot['transportMode'] = mode;
          spot['travelTime'] = data['routes'][0]['legs'][0]['duration']['text'];
        });
      } else if (mounted) {
        setState(() => spot['travelTime'] = "無法計算");
      }
    } catch (e) {
      if (mounted) setState(() => spot['travelTime'] = "網路錯誤");
    }
  }

  void _showDurationScrollPicker(BuildContext context, String dayKey, Map<String, dynamic> spot) {
    int currentTotalMinutes = spot['durationValue'] ?? 60;
    int h = currentTotalMinutes ~/ 60;
    int m = currentTotalMinutes % 60;

    showDialog(
      context: context, 
      builder: (ctx) {
        return AlertDialog(
          title: Text('修改「${spot['title']}」時間', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)), 
          content: SizedBox(
            height: 150, 
            child: Row(
              children: [
                Expanded(
                  child: ListWheelScrollView.useDelegate(
                    itemExtent: 40, 
                    physics: const FixedExtentScrollPhysics(),
                    controller: FixedExtentScrollController(initialItem: h), 
                    onSelectedItemChanged: (i) => h = i, 
                    childDelegate: ListWheelChildBuilderDelegate(childCount: 24, builder: (ctx, i) => Center(child: Text('$i', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold))))
                  )
                ), 
                const Text('時', style: TextStyle(fontWeight: FontWeight.bold)),
                Expanded(
                  child: ListWheelScrollView.useDelegate(
                    itemExtent: 40, 
                    physics: const FixedExtentScrollPhysics(),
                    controller: FixedExtentScrollController(initialItem: m ~/ 5), 
                    onSelectedItemChanged: (i) => m = i * 5, 
                    childDelegate: ListWheelChildBuilderDelegate(childCount: 12, builder: (ctx, i) => Center(child: Text('${i*5}'.padLeft(2,'0'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold))))
                  )
                ), 
                const Text('分', style: TextStyle(fontWeight: FontWeight.bold)),
              ]
            )
          ), 
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消', style: TextStyle(color: Colors.grey))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6CA6CC), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))), 
              onPressed: () { 
                setState(() { spot['durationValue'] = (h * 60) + m; }); 
                Navigator.pop(ctx); 
              }, 
              child: const Text('完成設定', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
            )
          ]
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PlanProvider>(context);
    final List<dynamic> itineraryList = provider.getItinerary(widget.planId);
    
    final currentPlan = provider.plans.firstWhere((p) => p['id'] == widget.planId, orElse: () => {'title': widget.title});
    final displayTitle = currentPlan['title'];

    if (!_isFirstLoadCalculated && itineraryList.isNotEmpty) {
      _isFirstLoadCalculated = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _autoCalculateMissingTimes(itineraryList));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87, size: 20), onPressed: () => Navigator.pop(context)),
        title: Text(displayTitle, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, letterSpacing: 2)),
        centerTitle: true,
        actions: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                constraints: const BoxConstraints(),
                icon: Icon(
                  _isLocked ? Icons.lock : Icons.lock_open_rounded, 
                  color: _isLocked ? Colors.redAccent : const Color(0xFF20C997), 
                  size: 22
                ),
                onPressed: () {
                  setState(() => _isLocked = !_isLocked);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(_isLocked ? '🔒 行程已鎖定，點擊地標即可查看景點！' : '🔓 行程已解鎖，開放編輯！'), 
                    duration: const Duration(seconds: 1), 
                    behavior: SnackBarBehavior.floating
                  ));
                },
              ),
              IconButton(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.people_alt_outlined, color: Colors.black54, size: 24),
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ChatRoomScreen(planId: widget.planId)))
              ),
              IconButton(
                padding: const EdgeInsets.only(left: 6, right: 16),
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.luggage_outlined, color: Colors.black54, size: 24),
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => LuggageScreen(planId: widget.planId)))
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 10), 
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              itemCount: itineraryList.length,
              itemBuilder: (context, index) {
                final dayData = itineraryList[index];
                final String dayName = dayData['day'];
                final List items = dayData['items'] ?? [];
                final bool isExpanded = _expandedDays.contains(dayName);

                TimeOfDay runningTime = _dayStartTimes[dayName] ?? const TimeOfDay(hour: 9, minute: 0);
                List<String> computedTimes = [];

                for (int i = 0; i < items.length; i++) {
                  computedTimes.add(_formatTimeOfDay(runningTime));
                  int stayMinutes = items[i]['durationValue'] ?? 60;
                  runningTime = _addMinutesToTime(runningTime, stayMinutes);
                  if (i < items.length - 1) {
                    int travelMinutes = _parseTravelMinutes(items[i]['travelTime']);
                    runningTime = _addMinutesToTime(runningTime, travelMinutes);
                  }
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () => setState(() => isExpanded ? _expandedDays.remove(dayName) : _expandedDays.add(dayName)),
                            child: Row(children: [
                              Icon(isExpanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_right, color: Colors.black54),
                              const SizedBox(width: 5),
                              Text(dayName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                            ]),
                          ),
                          const SizedBox(width: 15),
                          GestureDetector(
                            onTap: () => _pickDayStartTime(context, dayName),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(12)),
                              child: Row(children: [
                                Icon(_isLocked ? Icons.lock_outline : Icons.play_circle_outline, size: 14, color: _isLocked ? Colors.grey : const Color(0xFF6CA6CC)),
                                const SizedBox(width: 4),
                                Text(
                                  '${_formatTimeOfDay(_dayStartTimes[dayName] ?? const TimeOfDay(hour: 9, minute: 0))} 出發',
                                  style: TextStyle(fontSize: 12, color: _isLocked ? Colors.grey : const Color(0xFF6CA6CC), fontWeight: FontWeight.bold)
                                ),
                              ]),
                            ),
                          ),
                        ],
                      ),
                    ),

                    if (isExpanded)
                      ReorderableListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        buildDefaultDragHandles: false, 
                        itemCount: items.length,
                        onReorder: (oldIdx, newIdx) {
                          if (_isLocked) return; 
                          setState(() {
                            if (newIdx > oldIdx) newIdx -= 1;
                            final item = items.removeAt(oldIdx);
                            items.insert(newIdx, item);
                          });
                          
                          if (newIdx < items.length - 1) {
                            _recalculateTravelTime(items[newIdx], items[newIdx + 1], items[newIdx]['transportMode'] ?? 'driving');
                          }
                          if (newIdx > 0) {
                            _recalculateTravelTime(items[newIdx - 1], items[newIdx], items[newIdx - 1]['transportMode'] ?? 'driving');
                          }
                          if (oldIdx > 0 && oldIdx - 1 < items.length) {
                            _recalculateTravelTime(items[oldIdx - 1], items[oldIdx], items[oldIdx - 1]['transportMode'] ?? 'driving');
                          }
                        },
                        itemBuilder: (context, idx) {
                          final spot = items[idx];
                          final nextSpot = idx < items.length - 1 ? items[idx + 1] : null; 
                          bool isLast = idx == items.length - 1;
                          bool isActiveSpot = _isLocked && idx == 0; 
                          
                          final uniqueKey = ValueKey(spot.hashCode.toString() + spot['title']);
                          String displayTime = computedTimes.isNotEmpty && idx < computedTimes.length ? computedTimes[idx] : '09:00';

                          return _buildSpotTimelineRow(context, spot, nextSpot, isLast, isActiveSpot, dayName, displayTime, idx, key: uniqueKey);
                        },
                      ),
                      
                    if (isExpanded && !_isLocked)
                       Padding(
                         padding: const EdgeInsets.only(left: 70, top: 10, bottom: 30),
                         child: GestureDetector(
                           onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => AddSpotScreen(planId: widget.planId, day: dayName))),
                           child: Container(
                             width: 30, height: 30,
                             decoration: const BoxDecoration(color: Color(0xFF6CA6CC), shape: BoxShape.circle),
                             child: const Icon(Icons.add, color: Colors.white, size: 20),
                           ),
                         )
                       )
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpotTimelineRow(BuildContext context, Map<String, dynamic> spot, Map<String, dynamic>? nextSpot, bool isLast, bool isActiveSpot, String dayKey, String displayTime, int spotIndex, {required Key key}) {
    return IntrinsicHeight(
      key: key,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 70,
            child: Column(
              children: [
                const SizedBox(height: 15),
                Text(displayTime, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF6CA6CC))),
                const SizedBox(height: 10),
                if (!isLast) Expanded(child: Container(width: 2, color: const Color(0xFFFFB6B9))),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 25),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F2FA),
                      borderRadius: BorderRadius.circular(15),
                      border: isActiveSpot ? Border.all(color: Colors.orange, width: 2) : Border.all(color: Colors.transparent),
                    ),
                    child: _buildCardContent(context, spot, dayKey, spotIndex),
                  ),
                  if (!isLast)
                    Padding(
                      padding: const EdgeInsets.only(left: 10, top: 4),
                      child: GestureDetector(
                        onTap: () => _showTransportPicker(context, spot, nextSpot, dayKey),
                        child: Row(
                          children: [
                            Icon(
                              spot['transportMode'] == 'walking' ? Icons.directions_walk :
                              spot['transportMode'] == 'transit' ? Icons.directions_transit :
                              Icons.directions_car, 
                              size: 16, color: Colors.grey
                            ),
                            const SizedBox(width: 5),
                            const Text('交通方式：', style: TextStyle(fontSize: 11, color: Colors.grey)),
                            Icon(
                              spot['transportMode'] == 'walking' ? Icons.directions_walk :
                              spot['transportMode'] == 'transit' ? Icons.directions_transit :
                              Icons.directions_car, 
                              size: 16, color: _isLocked ? Colors.grey : Colors.redAccent
                            ),
                            const SizedBox(width: 5),
                            Text(
                              '${spot['travelTime'] ?? '15 分鐘'}', 
                              style: TextStyle(fontSize: 11, color: _isLocked ? Colors.grey : Colors.redAccent, fontWeight: FontWeight.bold)
                            ),
                          ],
                        ),
                      ),
                    )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardContent(BuildContext context, Map<String, dynamic> spot, String dayKey, int spotIndex) {
    if (!_isLocked) {
      return Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(spot['title'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('停留 ${spot['durationValue'] ?? 60} 分鐘', style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => _showDurationScrollPicker(context, dayKey, spot),
            child: const Icon(Icons.access_time, color: Color(0xFF6CA6CC), size: 22), 
          ),
          const SizedBox(width: 15),
          GestureDetector(
            onTap: () => Provider.of<PlanProvider>(context, listen: false).deleteItineraryItem(widget.planId, dayKey, spot['id']),
            child: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 22),
          ),
          const SizedBox(width: 15),
          ReorderableDragStartListener(
            index: spotIndex, 
            child: const Icon(Icons.drag_handle, color: Colors.black26, size: 22),
          ),
        ],
      );
    } else {
      return Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(spot['title'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('停留 ${spot['durationValue'] ?? 60} 分鐘', style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ),
          // 🔥 2. 修改此處的點擊事件：改為搜尋該景點並定位，不強制啟動導航
          GestureDetector(
            onTap: () async {
              final title = spot['title'];
              
              // 🌟 核心魔法：使用 Google Maps Search 協定，只做地標定位不開導航
              final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(title)}');
              
              if (await canLaunchUrl(url)) {
                await launchUrl(url, mode: LaunchMode.externalApplication); 
              } else {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('無法開啟 Google Maps'), 
                  behavior: SnackBarBehavior.floating
                ));
              }
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF2F9FF),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.near_me, color: Color(0xFF6CA6CC), size: 22),
            ),
          ),
        ],
      );
    }
  }
}