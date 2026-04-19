import { Feather } from '@expo/vector-icons';
import { useRouter } from 'expo-router';
import React from 'react';
import { Dimensions, SafeAreaView, StyleSheet, Text, TouchableOpacity, View } from 'react-native';
import QRCode from 'react-native-qrcode-svg';

const { width } = Dimensions.get('window');

export default function QRCodeScreen() {
  const router = useRouter();
  const myProfileLink = "piggo://user/piggy_01"; 

  return (
    <SafeAreaView style={styles.container}>
      {/* Header */}
      <View style={styles.header}>
        <TouchableOpacity onPress={() => router.back()} style={styles.backButton}>
          <Feather name="arrow-left" size={26} color="#333" />
        </TouchableOpacity>
        <Text style={styles.headerTitle}>分享QRcode</Text>
        <View style={{ width: 26 }} />
      </View>

      <View style={styles.content}>
        {/* QR Code 區塊 (置中) */}
        <View style={styles.qrContainer}>
          <QRCode
            value={myProfileLink} 
            size={200}           
            color="black"
            backgroundColor="white"
          />
        </View>

        {/* 底部按鈕區 */}
        <View style={styles.buttonRow}>
          <TouchableOpacity style={styles.actionButton}>
             <MaterialCommunityIcons name="qrcode" size={20} color="white" style={{marginRight: 8}} />
             <Text style={styles.buttonText}>QRcode</Text>
          </TouchableOpacity>

          <TouchableOpacity style={styles.actionButton}>
             <MaterialCommunityIcons name="share-variant" size={20} color="white" style={{marginRight: 8}} />
             <Text style={styles.buttonText}>個人檔案</Text>
          </TouchableOpacity>
        </View>
      </View>
    </SafeAreaView>
  );
}

import { MaterialCommunityIcons } from '@expo/vector-icons';

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#F2F9FF' },
  header: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', paddingHorizontal: 20, paddingVertical: 15 },
  headerTitle: { fontSize: 18, fontWeight: 'bold', color: '#333' },
  backButton: { padding: 5 },
  
  content: { flex: 1, justifyContent: 'center', alignItems: 'center' },

  qrContainer: {
    padding: 20,
    backgroundColor: 'white', 
    borderRadius: 10,
    marginBottom: 100, 
    shadowColor: "#000",
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 5,
    elevation: 3,
  },

  buttonRow: {
    flexDirection: 'row',
    gap: 20,
    position: 'absolute',
    bottom: 100, 
  },
  actionButton: {
    flexDirection: 'row',
    backgroundColor: '#007AFF',
    paddingVertical: 12,
    paddingHorizontal: 25,
    borderRadius: 8,
    alignItems: 'center',
  },
  buttonText: { color: 'white', fontSize: 16, fontWeight: 'bold' },
});
