// app/(tabs)/chat-room.tsx
import { Ionicons } from '@expo/vector-icons';
import { useRouter, useLocalSearchParams } from 'expo-router';
import React, { useState, useRef, useEffect } from 'react'; // 引入 useEffect
import { ScrollView, StyleSheet, Text, TextInput, TouchableOpacity, View } from 'react-native';
import { usePlans } from '../../components/PlanContext'; // 👈 引入倉庫

export default function ChatRoomScreen() {
  const router = useRouter();
  const params: any = useLocalSearchParams(); 
  const scrollViewRef = useRef<ScrollView>(null); 
  
  // 1. 從倉庫取得工具
  const { getMessages, sendMessage } = usePlans();
  
  // 2. 取得現在是哪個計畫 ID
  const planId = params.id; 
  const roomName = params.title || "旅遊群組";

  // 3. 讀取該 ID 的訊息 (這是即時的，倉庫更新這裡也會更新)
  const messages = getMessages(planId);

  const [inputText, setInputText] = useState('');

  // 4. 發送訊息時，呼叫倉庫的 function
  const handleSend = () => {
    if (inputText.trim() === '') return;
    
    sendMessage(planId, inputText); // 👈 告訴倉庫要傳給誰
    setInputText('');

    // 自動捲動到底部
    setTimeout(() => {
        scrollViewRef.current?.scrollToEnd({ animated: true });
    }, 100);
  };

  return (
    <View style={styles.container}>
      <View style={styles.header}>
        <TouchableOpacity onPress={() => router.back()} style={styles.backButton}>
             <Ionicons name="chevron-back" size={28} color="#333" />
        </TouchableOpacity>
        <Text style={styles.headerTitle}>{roomName} ({messages.length + 1})</Text>
        <TouchableOpacity>
             <Ionicons name="menu" size={24} color="#333" />
        </TouchableOpacity>
      </View>

      <ScrollView 
        ref={scrollViewRef}
        contentContainerStyle={styles.chatContent}
        onContentSizeChange={() => scrollViewRef.current?.scrollToEnd({ animated: true })}
      >
        {messages.map((msg: any) => (
            <View key={msg.id} style={[styles.messageRow, msg.sender === 'me' ? { justifyContent: 'flex-end' } : null]}>
                {msg.sender === 'other' && (
                    <View style={styles.avatar}><Text>🐷</Text></View>
                )}
                <View style={msg.sender === 'me' ? { alignItems: 'flex-end' } : { alignItems: 'flex-start' }}>
                    {msg.sender === 'other' && <Text style={styles.senderName}>{msg.name}</Text>}
                    <View style={msg.sender === 'me' ? styles.bubbleRight : styles.bubbleLeft}>
                        <Text style={[styles.messageText, msg.sender === 'me' ? {color: 'white'} : {color: '#333'}]}>
                            {msg.text}
                        </Text>
                    </View>
                    <Text style={styles.timeText}>{msg.time}</Text>
                </View>
            </View>
        ))}
      </ScrollView>

      <View style={styles.inputArea}>
         <TouchableOpacity style={styles.plusBtn}><Ionicons name="add" size={24} color="#666" /></TouchableOpacity>
         <TextInput 
            style={styles.input} 
            placeholder="輸入訊息..." 
            value={inputText}
            onChangeText={setInputText} 
            onSubmitEditing={handleSend} 
         />
         <TouchableOpacity style={styles.sendBtn} onPress={handleSend}>
            <Ionicons name="paper-plane" size={20} color="white" />
         </TouchableOpacity>
      </View>
    </View>
  );
}
// (Styles 維持不變，這裡為了版面簡潔省略，請保留原本的 styles)
const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#EAF6FF', paddingTop: 50 },
  header: { flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', paddingHorizontal: 15, paddingBottom: 15, borderBottomWidth: 1, borderBottomColor: '#ddd', backgroundColor: '#EAF6FF' },
  headerTitle: { fontSize: 18, fontWeight: 'bold' },
  backButton: { padding: 5 },
  chatContent: { padding: 15 },
  messageRow: { flexDirection: 'row', marginBottom: 20 },
  avatar: { width: 40, height: 40, borderRadius: 20, backgroundColor: '#ddd', justifyContent: 'center', alignItems: 'center', marginRight: 10 },
  senderName: { fontSize: 12, color: '#666', marginBottom: 4, marginLeft: 4 },
  bubbleLeft: { backgroundColor: 'white', padding: 12, borderRadius: 15, borderTopLeftRadius: 4, maxWidth: '80%' },
  bubbleRight: { backgroundColor: '#6CA6CC', padding: 12, borderRadius: 15, borderTopRightRadius: 4, maxWidth: '80%' },
  messageText: { fontSize: 16 },
  timeText: { fontSize: 10, color: '#999', marginTop: 4, textAlign: 'right' },
  inputArea: { flexDirection: 'row', padding: 10, backgroundColor: 'white', alignItems: 'center' },
  input: { flex: 1, backgroundColor: '#f0f0f0', borderRadius: 20, paddingHorizontal: 15, paddingVertical: 8, marginHorizontal: 10 },
  plusBtn: { padding: 5 },
  sendBtn: { width: 35, height: 35, borderRadius: 17.5, backgroundColor: '#6CA6CC', justifyContent: 'center', alignItems: 'center' }
});