import { Feather, Ionicons } from '@expo/vector-icons';
import { useRouter } from 'expo-router';
import React, { useState } from 'react';
import { FlatList, SafeAreaView, StyleSheet, Text, TextInput, TouchableOpacity, View } from 'react-native';

const LANGUAGES = [
  { id: 'en', name: 'English', sub: '英文' },
  { id: 'zh-tw', name: '中文(繁體)', sub: '繁體中文' },
];

export default function LanguageSettingsScreen() {
  const router = useRouter();
  const [search, setSearch] = useState('');

  return (
    <SafeAreaView style={styles.container}>
      {/* Header */}
      <View style={styles.header}>
        <TouchableOpacity onPress={() => router.back()} style={styles.backButton}>
          <Feather name="arrow-left" size={26} color="#333" />
        </TouchableOpacity>
        <Text style={styles.headerTitle}>語言設定</Text>
        <View style={{ width: 26 }} />
      </View>

      <View style={styles.content}>
        {/* 搜尋框 */}
        <View style={styles.searchContainer}>
          <Ionicons name="search" size={20} color="#007AFF" style={styles.searchIcon} />
          <TextInput 
            style={styles.searchInput}
            placeholder="搜尋語言"
            value={search}
            onChangeText={setSearch}
          />
          <TouchableOpacity onPress={() => setSearch('')}>
             <Ionicons name="close" size={20} color="#999" />
          </TouchableOpacity>
        </View>

        {/* 語言列表 */}
        <FlatList
          data={LANGUAGES}
          keyExtractor={(item) => item.id}
          renderItem={({ item }) => (
            <TouchableOpacity style={styles.langItem}>
              <View>
                <Text style={styles.langName}>{item.name}</Text>
                <Text style={styles.langSub}>{item.sub}</Text>
              </View>
            </TouchableOpacity>
          )}
          contentContainerStyle={{ marginTop: 20 }}
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
  content: { flex: 1, paddingHorizontal: 20 },

  // 搜尋框
  searchContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#FFF',
    borderWidth: 1,
    borderColor: '#007AFF', 
    borderRadius: 10,
    paddingHorizontal: 10,
    height: 40,
    marginTop: 10,
  },
  searchIcon: { marginRight: 10 },
  searchInput: { flex: 1, fontSize: 16 },

  // 列表項目
  langItem: { paddingVertical: 15, borderBottomWidth: 0 }, // 根據截圖好像沒有底線，如果要有可加 borderBottomColor
  langName: { fontSize: 18, fontWeight: 'bold', color: '#000' },
  langSub: { fontSize: 14, color: '#666', marginTop: 2 },
});
