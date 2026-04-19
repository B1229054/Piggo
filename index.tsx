import { FontAwesome } from '@expo/vector-icons';
import AsyncStorage from '@react-native-async-storage/async-storage'; // ★ 引入 AsyncStorage
import { ResponseType, useAuthRequest } from 'expo-auth-session';
import * as Facebook from 'expo-auth-session/providers/facebook';
import * as Google from 'expo-auth-session/providers/google';
import { useRouter } from 'expo-router';
import * as WebBrowser from 'expo-web-browser';
import React, { useEffect, useState } from 'react';
import { Alert, Image, Platform, ScrollView, StyleSheet, Text, TouchableOpacity, View } from 'react-native';

WebBrowser.maybeCompleteAuthSession();

// LINE的設定檔
const lineDiscovery = {
  authorizationEndpoint: 'https://access.line.me/oauth2/v2.1/authorize',
  tokenEndpoint: 'https://api.line.me/oauth2/v2.1/token',
};

export default function LoginScreen() {
  const router = useRouter(); 
  const [isHappyPig, setIsHappyPig] = useState(true);

  // Redirect URI
  const redirectUri = Platform.select({
    web: typeof window !== 'undefined' ? window.location.origin : 'http://localhost:8081',
    default: "https://auth.expo.io/@piggo1224/piggo" // 這裡之後如果換帳號發布，記得改回自己的 expo 帳號
  });

  // ==========================================
  // Google 登入
  // ==========================================
  const [googleRequest, googleResponse, googlePromptAsync] = Google.useAuthRequest({
    webClientId: '915340601206-ru7s7bu9p7vbldjrft6bm6c4kv4kk4ef.apps.googleusercontent.com',
    iosClientId: '915340601206-ru7s7bu9p7vbldjrft6bm6c4kv4kk4ef.apps.googleusercontent.com',
    androidClientId: '915340601206-ru7s7bu9p7vbldjrft6bm6c4kv4kk4ef.apps.googleusercontent.com',
    redirectUri: redirectUri,
  });

  useEffect(() => {
    if (googleResponse?.type === 'success') {
      const { authentication } = googleResponse;
      if (authentication?.accessToken) {
        // ★ 登入成功拿到 Token 後，去跟 Google 要使用者資料
        fetchGoogleUserInfo(authentication.accessToken);
      }
    } else if (googleResponse?.type === 'error') {
      Alert.alert("Google 登入失敗", "請再試一次");
    }
  }, [googleResponse]);

  // ★ 拿 Token 去換取使用者的基本資料，並存入記憶體
  const fetchGoogleUserInfo = async (token: string) => {
    try {
      const res = await fetch('https://www.googleapis.com/userinfo/v2/me', {
        headers: { Authorization: `Bearer ${token}` },
      });
      const user = await res.json();
      console.log('Google 使用者資料:', user);

      // 把抓到的名字和頭貼存進 AsyncStorage，讓 Profile 頁面可以讀取！
      await AsyncStorage.setItem('user-name', user.name);
      if (user.picture) {
        await AsyncStorage.setItem('user-avatar', user.picture);
      }

      Alert.alert('登入成功', `歡迎回來，${user.name}！`);
      router.replace('/quiz'); // 跳轉到測驗頁
    } catch (error) {
      console.error('獲取 Google 資料失敗:', error);
      Alert.alert('錯誤', '無法獲取使用者資料');
    }
  };

  // ==========================================
  // Facebook 登入
  // ==========================================
  const [fbRequest, fbResponse, fbPromptAsync] = Facebook.useAuthRequest({
    clientId: '744315255356436', 
    redirectUri: redirectUri,
    responseType: ResponseType.Token,
  });

  useEffect(() => {
    if (fbResponse?.type === 'success') {
      console.log("FB 登入成功，跳轉中...");
      router.replace('/quiz');
    }
  }, [fbResponse]);

  // ==========================================
  // LINE 登入
  // ==========================================
  const [lineRequest, lineResponse, linePromptAsync] = useAuthRequest(
    {
      clientId: '2008788101',
      scopes: ['openid', 'profile', 'email'],
      redirectUri: redirectUri,
      responseType: ResponseType.Code, 
    },
    lineDiscovery
  );

  useEffect(() => {
    if (lineResponse?.type === 'success') {
      console.log("LINE 登入成功，跳轉中...");
      router.replace('/quiz');
    } else if (lineResponse?.type === 'error') {
      Alert.alert("LINE 登入失敗", lineResponse.error?.message);
    }
  }, [lineResponse]);

  // ==========================================
  // 訪客登入
  // ==========================================
  const handleGuestLogin = () => {
    console.log("訪客模式啟動 (無提示)");
    router.replace('/quiz');
  };

  return (
    <ScrollView contentContainerStyle={styles.container}>
      <View style={styles.headerContainer}>
        <Text style={styles.title}>Login Piggo</Text>
        <Text style={styles.subTitle}>使用以下應用程式登入/註冊並繼續</Text>
      </View>

      <View style={styles.socialRow}>
        <TouchableOpacity 
          style={[styles.socialButton, { backgroundColor: '#06C755' }]} 
          disabled={!lineRequest} 
          activeOpacity={0.6}
          onPress={() => linePromptAsync()}
        >
          <FontAwesome name="comment" size={32} color="#fff" />
        </TouchableOpacity>

        <TouchableOpacity 
            style={[styles.socialButton, { backgroundColor: '#4267B2' }]} 
            activeOpacity={0.6}
            onPress={() => fbPromptAsync()}
        >
          <FontAwesome name="facebook-f" size={32} color="#fff" />
        </TouchableOpacity>

        {/* ★ Google 登入按鈕 */}
        <TouchableOpacity 
            style={[styles.socialButton, { backgroundColor: '#fff' }]} 
            activeOpacity={0.6}
            disabled={!googleRequest} // 確保請求準備好才能按
            onPress={() => googlePromptAsync()}
        >
          <FontAwesome name="google" size={32} color="#EA4335" />
        </TouchableOpacity>
      </View>

      <TouchableOpacity onPress={handleGuestLogin} style={styles.guestButton} activeOpacity={0.6}>
        <Text style={styles.guestButtonText}>先逛逛 (訪客模式) &gt;</Text>
      </TouchableOpacity>

      <View style={styles.imageContainer}>
         <TouchableOpacity 
            onPress={() => setIsHappyPig(!isHappyPig)}
            activeOpacity={0.8}
         >
             <Image 
                source={isHappyPig ? require('../assets/piggy/pig_login0.png') : require('../assets/piggy/pig_login1.png')} 
                style={styles.pigImage} 
                resizeMode="contain" 
             />
         </TouchableOpacity>
      </View>

      <View style={styles.footer}>
        <Text style={styles.footerText}>登入即代表同意使用者條款</Text>
      </View>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  container: { flexGrow: 1, backgroundColor: '#F2F9FF', alignItems: 'center', justifyContent: 'center', padding: 30 },
  headerContainer: { alignItems: 'center', marginBottom: 40 }, 
  title: { fontSize: 28, fontWeight: 'bold', color: '#4E84A7', marginBottom: 10 },
  subTitle: { fontSize: 14, color: '#757575' },
  socialRow: { flexDirection: 'row', justifyContent: 'center', gap: 25, marginBottom: 25 }, 
  socialButton: { 
    width: 70, height: 70, borderRadius: 18, alignItems: 'center', justifyContent: 'center', 
    shadowColor: '#000', shadowOffset: { width: 0, height: 4 }, shadowOpacity: 0.25, shadowRadius: 5, elevation: 8, 
  },
  guestButton: { marginBottom: 30, paddingVertical: 10, paddingHorizontal: 20, borderRadius: 20, borderWidth: 1, borderColor: '#8BA0B2' },
  guestButtonText: { color: '#6CA6CC', fontSize: 16, fontWeight: '600' },
  imageContainer: { marginBottom: 50, alignItems: 'center' },
  pigImage: { width: 200, height: 200 },
  footer: { position: 'absolute', bottom: 30 },
  footerText: { color: '#8BA0B2', fontSize: 12 }
});