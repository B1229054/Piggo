// app/(tabs)/_layout.tsx
import { Tabs } from 'expo-router';
import { FontAwesome, Ionicons } from '@expo/vector-icons';
import { View } from 'react-native';

export default function TabLayout() {
  return (
    <Tabs screenOptions={{ headerShown: false, tabBarActiveTintColor: '#6CA6CC' }}>
      <Tabs.Screen 
        name="home" 
        options={{
          title: '首頁',
          tabBarIcon: ({ color }) => <FontAwesome name="home" size={24} color={color} />,
        }} 
      />
      
      {/* 交流 */}
      <Tabs.Screen name="chat" options={{ title: '交流', href: null, tabBarIcon: ({ color }) => <Ionicons name="chatbubbles" size={24} color={color} /> }} />

      {/* 中間新增按鈕 */}
      <Tabs.Screen 
        name="add" 
        options={{
          title: '',
          tabBarIcon: () => (
            <View style={{ width: 50, height: 50, backgroundColor: '#89C4E6', borderRadius: 25, justifyContent: 'center', alignItems: 'center', marginBottom: 20, borderWidth: 4, borderColor: 'white' }}>
                <FontAwesome name="plus" size={24} color="white" />
            </View>
          ),
        }} 
        listeners={() => ({ tabPress: (e) => e.preventDefault() })}
      />

      {/* 計畫 (這顆按下去就會跑到 plan.tsx) */}
      <Tabs.Screen 
        name="plan" 
        options={{
          title: '計畫',
          tabBarIcon: ({ color }) => <FontAwesome name="calendar" size={24} color={color} />,
        }} 
      />

      {/* 帳號 */}
      <Tabs.Screen name="account" options={{ title: '帳號', href: null, tabBarIcon: ({ color }) => <FontAwesome name="user" size={24} color={color} /> }} />
      <Tabs.Screen 
        name="new-plan" 
        options={{
          href: null, // 關鍵！這樣就不會出現在下方按鈕列
          title: '新增計畫',
        }} 

      />
      <Tabs.Screen name="chat-room" options={{ href: null, title: '聊天室' }} />
      <Tabs.Screen name="invite" options={{ href: null, title: '邀請' }} />
      <Tabs.Screen name="itinerary" options={{ href: null, title: '行程詳情' }} />
    </Tabs>
  );
}
