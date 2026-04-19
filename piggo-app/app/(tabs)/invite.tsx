// app/(tabs)/invite.tsx
import { FontAwesome, Ionicons } from '@expo/vector-icons';
import { useRouter, useLocalSearchParams } from 'expo-router'; // 👈 1. 引入
import React from 'react';
import { Image, StyleSheet, Text, TouchableOpacity, View } from 'react-native';

export default function InviteScreen() {
  const router = useRouter();
  const params: any = useLocalSearchParams(); // 👈 2. 接收參數

  // 3. 取得標題
  const planTitle = params.title || "此行程";

  return (
    <View style={styles.container}>
      <View style={styles.header}>
        <View style={styles.headerBar} />
        {/* 👇 4. 顯示動態標題 */}
        <Text style={styles.headerTitle}>邀請加入「{planTitle}」</Text>
      </View>

      <View style={styles.qrContainer}>
        <FontAwesome name="qrcode" size={150} color="black" />
      </View>

      <View style={styles.linkRow}>
        <Ionicons name="link" size={20} color="#333" style={{marginRight: 10}} />
        <Text style={styles.linkText}>https://piggo.com/join/{planTitle}</Text>
        <TouchableOpacity style={styles.copyButton}>
            <Text style={styles.copyText}>複製</Text>
        </TouchableOpacity>
      </View>

      <TouchableOpacity style={styles.inviteButton}>
         <FontAwesome name="envelope-o" size={18} color="#333" style={{marginRight: 10}} />
         <Text style={styles.inviteText}>邀請Piggo帳戶</Text>
      </TouchableOpacity>
      
      <TouchableOpacity style={styles.closeArea} onPress={() => router.back()}>
          <Text style={{color: '#999'}}>點擊此處返回</Text>
      </TouchableOpacity>

      <View style={styles.fab}>
        <Image source={require('../../assets/piggy/pig_login0.png')} style={{width: 30, height: 30, tintColor: 'white'}} resizeMode="contain" />
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#F2F4F7', alignItems: 'center', paddingTop: 60 },
  header: { alignItems: 'center', marginBottom: 40, width: '100%' },
  headerBar: { width: 100, height: 15, backgroundColor: 'black', borderRadius: 10, marginBottom: 20 },
  headerTitle: { fontSize: 20, fontWeight: 'bold' },
  qrContainer: { padding: 20, backgroundColor: 'transparent', marginBottom: 40 },
  linkRow: { flexDirection: 'row', backgroundColor: '#E0E5E9', width: '85%', padding: 15, borderRadius: 10, alignItems: 'center', marginBottom: 20 },
  linkText: { flex: 1, color: '#333' },
  copyButton: { backgroundColor: 'white', paddingVertical: 4, paddingHorizontal: 10, borderRadius: 5 },
  copyText: { fontSize: 12, fontWeight: 'bold' },
  inviteButton: { flexDirection: 'row', backgroundColor: '#E0E5E9', width: '85%', padding: 15, borderRadius: 10, alignItems: 'center', justifyContent: 'flex-start' },
  inviteText: { fontWeight: 'bold', color: '#333' },
  closeArea: { marginTop: 50, padding: 20 },
  fab: { position: 'absolute', right: 20, bottom: 100, width: 50, height: 50, borderRadius: 25, backgroundColor: '#6CA6CC', justifyContent: 'center', alignItems: 'center' }
});