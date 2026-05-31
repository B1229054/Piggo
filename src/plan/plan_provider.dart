import 'package:flutter/material.dart';

class PlanProvider extends ChangeNotifier {
  // ==========================================
  // 1. 資料庫 (State)
  // ==========================================
  
  // 計畫總覽 (首頁卡片)
  List<Map<String, dynamic>> plans = [
    {
      'id': '1',
      'title': '台南之旅',
      'date': '2026/11/01~2026/11/03',
      'members': 4,
      'img': null, 
    }
  ];

  // 行程表資料
  Map<String, List<Map<String, dynamic>>> itineraryData = {
    '1': [
      {
        'day': 'DAY 1',
        'items': [
          {
            'id': 'item1', 'type': 'activity', 'title': '台北車站', 'time': '10:20', 'durationValue': 120,
            'coordinate': {'lat': 25.0478, 'lng': 121.5170}
          },
          {
            'id': 'item2', 'type': 'activity', 'title': '台南車站', 'time': '14:00', 'durationValue': 30,
            'coordinate': {'lat': 22.997, 'lng': 120.212}
          },
          {
            'id': 'item3', 'type': 'activity', 'title': '林家白糖粿', 'time': '14:40', 'durationValue': 30,
            'coordinate': {'lat': 22.993, 'lng': 120.197}
          }
        ]
      }
    ]
  };

  // 聊天室與投票資料
  Map<String, List<Map<String, dynamic>>> chatData = {};


  // ==========================================
  // 2. 計畫相關方法 (Plan Methods)
  // ==========================================

  void addPlan(Map<String, dynamic> newPlan) {
    plans.insert(0, newPlan);
    notifyListeners();
  }

  void deletePlan(String planId) {
    plans.removeWhere((p) => p['id'] == planId);
    notifyListeners();
  }

  void updatePlanInfo(String planId, String title, String date, String? img) {
    int idx = plans.indexWhere((p) => p['id'] == planId);
    if (idx != -1) {
      plans[idx]['title'] = title;
      plans[idx]['date'] = date;
      if (img != null) plans[idx]['img'] = img;
      notifyListeners();
    }
  }


  // ==========================================
  // 3. 行程相關方法 (Itinerary Methods)
  // ==========================================

  List<dynamic> getItinerary(String planId) {
    return itineraryData[planId] ?? [];
  }

  void addItineraryItem(String planId, String dayKey, Map<String, dynamic> newItem, int targetIndex) {
    if (!itineraryData.containsKey(planId)) itineraryData[planId] = [];
    var planItinerary = itineraryData[planId]!;
    
    // 強力匹配：防止 DAY 1 和 DAY1 對不上的問題
    int dayIndex = planItinerary.indexWhere((d) => 
      d['day'].toString().toUpperCase().replaceAll(' ', '') == dayKey.toUpperCase().replaceAll(' ', '')
    );
    
    if (dayIndex == -1) {
      planItinerary.add({'day': dayKey, 'items': []});
      dayIndex = planItinerary.length - 1;
    }
    
    newItem['id'] = DateTime.now().millisecondsSinceEpoch.toString();
    List<Map<String, dynamic>> items = List.from(planItinerary[dayIndex]['items']);
    
    // 精準插入指定位置
    if (targetIndex >= items.length) {
      items.add(newItem);
    } else {
      items.insert(targetIndex, newItem);
    }
    
    planItinerary[dayIndex]['items'] = items;
    notifyListeners();
  }

  void deleteItineraryItem(String planId, String dayKey, String itemId) {
    if (!itineraryData.containsKey(planId)) return;
    var planItinerary = itineraryData[planId]!;
    int dayIndex = planItinerary.indexWhere((d) => d['day'] == dayKey);
    
    if (dayIndex != -1) {
      List items = List.from(planItinerary[dayIndex]['items']);
      items.removeWhere((item) => item['id'] == itemId);
      planItinerary[dayIndex]['items'] = items;
      notifyListeners();
    }
  }


  // ==========================================
  // 4. 聊天與投票相關方法 (Chat & Vote Methods)
  // ==========================================

  List<Map<String, dynamic>> getMessages(String planId) {
    return chatData[planId] ?? [];
  }

  void sendMessage(String planId, String text) {
    if (!chatData.containsKey(planId)) chatData[planId] = [];
    final now = DateTime.now();
    final timeStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    
    chatData[planId]!.add({
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'type': 'text',
      'text': text,
      'sender': 'me',
      'name': '我',
      'time': timeStr,
    });
    notifyListeners();
  }

  void sendImage(String planId, String imagePath) {
    if (!chatData.containsKey(planId)) chatData[planId] = [];
    final now = DateTime.now();
    final timeStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    
    chatData[planId]!.add({
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'type': 'image',
      'image': imagePath,
      'sender': 'me',
      'name': '我',
      'time': timeStr,
    });
    notifyListeners();
  }

  void addVote(String planId, Map<String, dynamic> voteData) {
    if (!chatData.containsKey(planId)) chatData[planId] = [];
    final now = DateTime.now();
    final timeStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    
    List<Map<String, dynamic>> initializedOptions = (voteData['options'] as List).map((opt) {
      Map<String, dynamic> newOpt = Map<String, dynamic>.from(opt);
      newOpt['count'] = 0;
      newOpt['voters'] = <String>[];
      return newOpt;
    }).toList();
    voteData['options'] = initializedOptions;

    chatData[planId]!.add({
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'type': 'vote',
      'text': voteData['question'],
      'voteData': voteData,
      'sender': 'me',
      'name': '我',
      'time': timeStr,
    });
    notifyListeners();
  }

  void castVote(String planId, String messageId, int optionIndex, String userId) {
    if (!chatData.containsKey(planId)) return;
    
    int msgIndex = chatData[planId]!.indexWhere((m) => m['id'] == messageId);
    if (msgIndex == -1 || chatData[planId]![msgIndex]['type'] != 'vote') return;

    var msg = chatData[planId]![msgIndex];
    var voteData = msg['voteData'];
    bool isMulti = voteData['isMultiSelect'] ?? false;
    List options = voteData['options'];

    var targetOption = options[optionIndex];
    List voters = List.from(targetOption['voters'] ?? []);
    bool hasVotedThis = voters.contains(userId);

    if (isMulti) {
      if (hasVotedThis) { 
        voters.remove(userId); 
      } else { 
        voters.add(userId); 
      }
      options[optionIndex]['voters'] = voters;
      options[optionIndex]['count'] = voters.length;
    } else {
      for (var opt in options) {
        List v = List.from(opt['voters'] ?? []);
        v.remove(userId);
        opt['voters'] = v;
        opt['count'] = v.length;
      }
      if (!hasVotedThis) {
        options[optionIndex]['voters'].add(userId);
        options[optionIndex]['count'] = options[optionIndex]['voters'].length;
      }
    }
    notifyListeners();
  }
}