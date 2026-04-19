import { DarkTheme, DefaultTheme, ThemeProvider } from '@react-navigation/native';
import { Stack } from 'expo-router';
import { StatusBar } from 'expo-status-bar';
import 'react-native-reanimated';
// ★ 1. 引入手勢庫
import { GestureHandlerRootView } from 'react-native-gesture-handler';

// 假設你的 hooks 資料夾路徑沒變，這行保留
import { useColorScheme } from '@/hooks/use-color-scheme';

export default function RootLayout() {
  const colorScheme = useColorScheme();

  return (
    // ★ 2. 最外層必須包這一個，測驗的卡片才能滑動
    <GestureHandlerRootView style={{ flex: 1 }}>
      
      {/* 3. 這是原本的主題設定 (深色/淺色模式)，保留它 */}
      <ThemeProvider value={colorScheme === 'dark' ? DarkTheme : DefaultTheme}>
        
        {/* 4. 路由設定 */}
        <Stack screenOptions={{ headerShown: false }}>
          {/* 因為你把檔案都搬到最外層了，這裡其實可以不用寫 Stack.Screen，
             Expo 會自動抓到 index, register, quiz。
             如果你想要針對特定頁面設定標題，可以像這樣寫 (沒寫也沒關係)：
          */}
          <Stack.Screen name="index" /> 
          <Stack.Screen name="register" />
          <Stack.Screen name="quiz" />
          
          {/* 如果你之後還要用 tabs，可以留著，不然目前可以先忽略 */}
          <Stack.Screen name="(tabs)" options={{ headerShown: false }} />
        </Stack>

        <StatusBar style="auto" />
      </ThemeProvider>
      
    </GestureHandlerRootView>
  );
}