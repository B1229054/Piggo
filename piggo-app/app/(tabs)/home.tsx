// app/(tabs)/home.tsx
import React from 'react';
import { View, Text, StyleSheet } from 'react-native';

export default function HomeScreen() {
  return (
    <View style={styles.container}>
      {/* 這裡故意留白，模擬同學還沒做好的樣子 */}
      <Text style={styles.text}>首頁 (同學負責的部分)</Text>
      <Text style={styles.subText}>請點選下方的「計畫」按鈕 👇</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, justifyContent: 'center', alignItems: 'center', backgroundColor: '#F2F9FF' },
  text: { fontSize: 24, fontWeight: 'bold', color: '#ccc' },
  subText: { fontSize: 16, color: '#999', marginTop: 10 }
});