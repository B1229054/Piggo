import { Feather } from '@expo/vector-icons';
import { useRouter } from 'expo-router';
import React, { useState } from 'react';
import { SafeAreaView, StyleSheet, Switch, Text, TouchableOpacity, View } from 'react-native';

export default function PrivacySettingsScreen() {
  const router = useRouter();
  const [isPrivate, setIsPrivate] = useState(true); 

  return (
    <SafeAreaView style={styles.container}>
      {/* Header */}
      <View style={styles.header}>
        <TouchableOpacity onPress={() => router.back()} style={styles.backButton}>
          <Feather name="arrow-left" size={26} color="#333" />
        </TouchableOpacity>
        <Text style={styles.headerTitle}>隱私設定</Text>
        <View style={{ width: 26 }} />
      </View>

      {/* 設定選項 */}
      <View style={styles.row}>
        <Text style={styles.label}>不公開帳號</Text>
        <Switch
          trackColor={{ false: "#767577", true: "#2D3452" }} 
          thumbColor={isPrivate ? "#FFF" : "#f4f3f4"}
          ios_backgroundColor="#3e3e3e"
          onValueChange={setIsPrivate}
          value={isPrivate}
          style={{ transform: [{ scaleX: 1.2 }, { scaleY: 1.2 }] }}
        />
      </View>

    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#F2F9FF' },
  header: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', paddingHorizontal: 20, paddingVertical: 15 },
  headerTitle: { fontSize: 18, fontWeight: 'bold', color: '#333' },
  backButton: { padding: 5 },
  
  row: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingHorizontal: 40,
    marginTop: 60, 
  },
  label: { fontSize: 20, color: '#2D3452', fontWeight: '500' },
});
