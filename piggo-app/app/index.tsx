import { FontAwesome } from '@expo/vector-icons';
import { ResponseType, useAuthRequest } from 'expo-auth-session';
import * as Facebook from 'expo-auth-session/providers/facebook';
import * as Google from 'expo-auth-session/providers/google';
import { useRouter } from 'expo-router';
import * as WebBrowser from 'expo-web-browser';
import React, { useEffect, useState } from 'react';
import { Image, Platform, ScrollView, StyleSheet, Text, TouchableOpacity, View } from 'react-native';

WebBrowser.maybeCompleteAuthSession();

// ★ LINE 的設定檔
const lineDiscovery = {
  authorizationEndpoint: 'https://access.line.me/oauth2/v2.1/authorize',
  tokenEndpoint: 'https://api.line.me/oauth2/v2.1/token',
};

export default function LoginScreen() {
  const router = useRouter(); 
  const [isHappyPig, setIsHappyPig] = useState(true);

  const testBackend = async () => {
    try {
      
      const response = await fetch('http://172.20.10.2:3000/api/test-db');
      const data = await response.json();
      
      console.log("🔥🔥🔥 後端連線成功！資料：", data);
      
    } catch (error) {
      console.error("❌ 後端連線失敗：", error);
      
    }
  };

  useEffect(() => {
    testBackend();
  }, []);

  // ★ Redirect URI
  const redirectUri = Platform.select({
    web: typeof window !== 'undefined' ? window.location.origin : 'http://localhost:8081',
    default: "https://auth.expo.io/@piggo1224/piggo"
  });

  // ==========================================
  // 🟢 Google 設定
  // ==========================================
  const [googleRequest, googleResponse, googlePromptAsync] = Google.useAuthRequest({
    webClientId: 'YOUR_WEB_CLIENT_ID', 
    iosClientId: 'YOUR_IOS_CLIENT_ID',
    androidClientId: 'YOUR_ANDROID_CLIENT_ID',
    redirectUri: redirectUri,
  });

  useEffect(() => {
    if (googleResponse?.type === 'success') {
      router.replace('/quiz');
    }
  }, [googleResponse]);

  // ==========================================
  // 🔵 Facebook 設定
  // ==========================================
  const [fbRequest, fbResponse, fbPromptAsync] = Facebook.useAuthRequest({
    clientId: '744315255356436', 
    redirectUri: redirectUri,
    responseType: ResponseType.Token,
  });

  useEffect(() => {
    if (fbResponse?.type === 'success') {
      router.replace('/quiz');
    }
  }, [fbResponse]);

  // ==========================================
  // 🟢 LINE 設定
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
      router.replace('/quiz');
    }
  }, [lineResponse]);

  return (
    <ScrollView contentContainerStyle={styles.container}>
      {/* 1. 標題區 */}
      <View style={styles.headerContainer}>
        <Text style={styles.title}>Login Piggo</Text>
        <Text style={styles.subTitle}>使用以下應用程式登入/註冊並繼續</Text>
      </View>

      {/* 2. 按鈕區 */}
      <View style={styles.socialRow}>
        
        {/* LINE (綠) */}
        <TouchableOpacity 
          style={[styles.socialButton, { backgroundColor: '#06C755' }]} 
          activeOpacity={0.6}
          onPress={() => linePromptAsync()}
        >
          <FontAwesome name="comment" size={32} color="#fff" />
        </TouchableOpacity>

        {/* Facebook (藍) */}
        <TouchableOpacity 
            style={[styles.socialButton, { backgroundColor: '#4267B2' }]} 
            activeOpacity={0.6}
            onPress={() => fbPromptAsync()}
        >
          <FontAwesome name="facebook-f" size={32} color="#fff" />
        </TouchableOpacity>

        {/* Google (白) */}
        <TouchableOpacity 
            style={[styles.socialButton, { backgroundColor: '#fff' }]} 
            activeOpacity={0.6}
            onPress={() => googlePromptAsync()}
        >
          <FontAwesome name="google" size={32} color="#EA4335" />
        </TouchableOpacity>
      
      </View>

      <TouchableOpacity 
        style={styles.guestButton} 
        onPress={() => router.replace('/quiz')}
      >
        <Text style={styles.guestButtonText}>👤 訪客登入 (直接開始)</Text>
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
  headerContainer: { alignItems: 'center', marginBottom: 50 },
  title: { fontSize: 28, fontWeight: 'bold', color: '#4E84A7', marginBottom: 10 },
  subTitle: { fontSize: 14, color: '#757575' },
  socialRow: { flexDirection: 'row', justifyContent: 'center', gap: 25, marginBottom: 20 },
  socialButton: { 
    width: 70, height: 70, borderRadius: 18, alignItems: 'center', justifyContent: 'center', 
    shadowColor: '#000', shadowOffset: { width: 0, height: 4 }, shadowOpacity: 0.25, shadowRadius: 5, elevation: 8, 
  },
  
  // 訪客按鈕樣式
  guestButton: {
    backgroundColor: '#6CA6CC', paddingVertical: 12, paddingHorizontal: 40, borderRadius: 25, marginBottom: 30,
    elevation: 3, shadowColor: '#000', shadowOffset: { width: 0, height: 2 }, shadowOpacity: 0.2, shadowRadius: 3,
  },
  guestButtonText: { color: 'white', fontSize: 18, fontWeight: 'bold' },

  imageContainer: { marginBottom: 50, alignItems: 'center' },
  pigImage: { width: 200, height: 200 },
  footer: { position: 'absolute', bottom: 30 },
  footerText: { color: '#8BA0B2', fontSize: 12 }
});