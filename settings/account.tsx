import { Feather, MaterialCommunityIcons } from '@expo/vector-icons';
import AsyncStorage from '@react-native-async-storage/async-storage';
import * as ImagePicker from 'expo-image-picker';
import { useRouter } from 'expo-router';
import React, { useEffect, useState } from 'react';
import { Dimensions, Image, SafeAreaView, StyleSheet, Text, TextInput, TouchableOpacity, View } from 'react-native';

const { width } = Dimensions.get('window');

export default function AccountSettingsScreen() {
  const router = useRouter();
  const [name, setName] = useState('Piggy'); // 預設名字
  const [avatarUri, setAvatarUri] = useState<string | null>(null);

  useEffect(() => {
    const loadData = async () => {
      const savedAvatar = await AsyncStorage.getItem('user-avatar');
      if (savedAvatar) setAvatarUri(savedAvatar);

      const savedName = await AsyncStorage.getItem('user-name');
      if (savedName) setName(savedName);
    };
    loadData();
  }, []);

  const pickImage = async () => {
    let result = await ImagePicker.launchImageLibraryAsync({
      mediaTypes: ImagePicker.MediaTypeOptions.Images,
      allowsEditing: true,
      aspect: [1, 1], 
      quality: 0.8,
    });

    if (!result.canceled) {
      const newUri = result.assets[0].uri;
      setAvatarUri(newUri);
      await AsyncStorage.setItem('user-avatar', newUri);
    }
  };

  const handleSaveAndGoBack = async () => {
    await AsyncStorage.setItem('user-name', name); 
    router.back(); 
  };

  return (
    <SafeAreaView style={styles.container}>
      <View style={styles.header}>
        <TouchableOpacity onPress={handleSaveAndGoBack} style={styles.backButton}>
          <Feather name="arrow-left" size={26} color="#333" />
        </TouchableOpacity>
        <Text style={styles.headerTitle}>管理帳號</Text>
        <View style={{ width: 26 }} />
      </View>

      <View style={styles.content}>
        <View style={styles.avatarContainer}>
          <TouchableOpacity style={styles.avatarWrapper} onPress={pickImage} activeOpacity={0.8}>
            <Image 
              source={avatarUri ? { uri: avatarUri } : require('../../assets/piggy/pig_login0.png')} 
              style={styles.avatar}
              resizeMode="cover"
            />
            <View style={styles.editIconBadge}>
              <MaterialCommunityIcons name="pencil-outline" size={16} color="white" />
            </View>
          </TouchableOpacity>
        </View>

        <View style={styles.inputSection}>
          <Text style={styles.label}>帳號名稱</Text>
          <View style={styles.inputContainer}>
            <TextInput 
              style={styles.input}
              value={name}
              onChangeText={setName} 
            />
          </View>
        </View>

        <View style={styles.footer}>
          <TouchableOpacity style={styles.doneButton} onPress={handleSaveAndGoBack}>
            <Text style={styles.doneButtonText}>完成</Text>
          </TouchableOpacity>
        </View>
      </View>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#F2F9FF' },
  header: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', paddingHorizontal: 20, paddingVertical: 15 },
  headerTitle: { fontSize: 18, fontWeight: 'bold', color: '#333' },
  backButton: { padding: 5 },
  content: { flex: 1, alignItems: 'center', paddingHorizontal: 30 },
  avatarContainer: { marginTop: 60, marginBottom: 40 },
  avatarWrapper: { position: 'relative' },
  avatar: { width: 100, height: 100, borderRadius: 50, borderWidth: 2, borderColor: '#333', backgroundColor: '#FFF' },
  editIconBadge: { position: 'absolute', right: 0, bottom: 0, backgroundColor: '#2D3452', width: 28, height: 28, borderRadius: 14, justifyContent: 'center', alignItems: 'center', borderWidth: 2, borderColor: '#FFF' },
  inputSection: { width: '100%' },
  label: { fontSize: 16, fontWeight: 'bold', color: '#2D3452', marginBottom: 5, marginLeft: 5 },
  inputContainer: { backgroundColor: '#BCC6D0', borderRadius: 10, paddingVertical: 12, paddingHorizontal: 15 },
  input: { fontSize: 16, color: '#2D3452' },
  footer: { flex: 1, justifyContent: 'flex-end', marginBottom: 40, width: '100%' },
  doneButton: { backgroundColor: '#007AFF', paddingVertical: 15, borderRadius: 10, alignItems: 'center' },
  doneButtonText: { color: 'white', fontSize: 16, fontWeight: 'bold' },
});
