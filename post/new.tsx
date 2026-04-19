import { Feather } from '@expo/vector-icons';
import AsyncStorage from '@react-native-async-storage/async-storage';
import * as ImagePicker from 'expo-image-picker';
import * as Location from 'expo-location';
import { useRouter } from 'expo-router';
import React, { useEffect, useState } from 'react';

import { ActionSheetIOS, Alert, Dimensions, FlatList, Image, KeyboardAvoidingView, Modal, Platform, SafeAreaView, ScrollView, StyleSheet, Text, TextInput, TouchableOpacity, View } from 'react-native';

const { width } = Dimensions.get('window');
const GOOGLE_API_KEY = process.env.EXPO_PUBLIC_GOOGLE_API_KEY;

export default function NewPostScreen() {
  const router = useRouter();
  const [images, setImages] = useState<string[]>([]);
  const [description, setDescription] = useState('');
  
  const [selectedLocation, setSelectedLocation] = useState<string | null>(null);
  const [isLocationModalVisible, setLocationModalVisible] = useState(false);
  const [searchQuery, setSearchQuery] = useState('');
  const [searchResults, setSearchResults] = useState<any[]>([]);
  
  const [hashtags, setHashtags] = useState<string[]>([]);
  const [currentHashtag, setCurrentHashtag] = useState('');

  useEffect(() => {
    pickImages();
  }, []);

  useEffect(() => {
    if (searchQuery.trim() === '') {
      setSearchResults([]);
      return;
    }
    const delayDebounceFn = setTimeout(() => {
      searchGooglePlaces(searchQuery);
    }, 500);
    return () => clearTimeout(delayDebounceFn);
  }, [searchQuery]);

  const searchGooglePlaces = async (text: string) => {
    if (!GOOGLE_API_KEY) return;
    try {
      const response = await fetch(
        `https://maps.googleapis.com/maps/api/place/autocomplete/json?input=${encodeURIComponent(text)}&key=${GOOGLE_API_KEY}&language=zh-TW&components=country:tw`
      );
      const data = await response.json();
      if (data.status === 'OK') {
        const formattedResults = data.predictions.map((p: any) => ({
          id: p.place_id,
          name: p.structured_formatting.main_text,
          address: p.structured_formatting.secondary_text,
        }));
        setSearchResults(formattedResults);
      } else {
        setSearchResults([]);
      }
    } catch (error) {
      console.error("搜尋地點失敗:", error);
    }
  };

  const pickImages = async () => {
    let result = await ImagePicker.launchImageLibraryAsync({
      mediaTypes: ImagePicker.MediaTypeOptions.Images,
      allowsMultipleSelection: true,
      selectionLimit: 10,
      quality: 0.8,
      exif: true,
    });

    if (!result.canceled && result.assets.length > 0) {
      const newUris = result.assets.map(asset => asset.uri);
      setImages(prev => [...prev, ...newUris]);

      if (images.length === 0) {
        const firstExif = result.assets[0].exif;
        if (firstExif && firstExif.GPSLatitude && firstExif.GPSLongitude) {
          let lat = firstExif.GPSLatitude;
          let lon = firstExif.GPSLongitude;
          if (firstExif.GPSLatitudeRef === 'S') lat = -lat;
          if (firstExif.GPSLongitudeRef === 'W') lon = -lon;
          extractLocationName(lat, lon);
        }
      }
    } else if (images.length === 0) {
      router.back();
    }
  };

  const handleImageTap = (index: number) => {
    if (Platform.OS === 'ios') {
      ActionSheetIOS.showActionSheetWithOptions(
        {
          options: ['取消', '更換並裁切大小 (1:1)', '刪除這張圖片'],
          destructiveButtonIndex: 2,
          cancelButtonIndex: 0,
        },
        (buttonIndex) => {
          if (buttonIndex === 1) {
            replaceAndCropImage(index);
          } else if (buttonIndex === 2) {
            removeImage(index);
          }
        }
      );
    } else {
      Alert.alert(
        "編輯圖片",
        "請選擇你要執行的動作",
        [
          { text: "更換並裁切大小 (1:1)", onPress: () => replaceAndCropImage(index) },
          { text: "刪除這張圖片", onPress: () => removeImage(index), style: 'destructive' },
          { text: "取消", style: "cancel" }
        ]
      );
    }
  };

  const replaceAndCropImage = async (index: number) => {
    let result = await ImagePicker.launchImageLibraryAsync({
      mediaTypes: ImagePicker.MediaTypeOptions.Images,
      allowsEditing: true,
      aspect: [1, 1],
      quality: 0.8,
    });

    if (!result.canceled) {
      const newUri = result.assets[0].uri;
      const updatedImages = [...images];
      updatedImages[index] = newUri;
      setImages(updatedImages);
    }
  };

  const removeImage = (index: number) => {
    const updatedImages = images.filter((_, i) => i !== index);
    setImages(updatedImages);
  };

  const extractLocationName = async (latitude: number, longitude: number) => {
    try {
      let { status } = await Location.requestForegroundPermissionsAsync();
      if (status !== 'granted') return;
      const geocode = await Location.reverseGeocodeAsync({ latitude, longitude });
      if (geocode.length > 0) {
        const place = geocode[0];
        const locationName = place.name || place.street || place.city || place.subregion;
        if (locationName) setSelectedLocation(locationName);
      }
    } catch (error) {
      console.log('地點解析失敗:', error);
    }
  };

  const processHashtag = (textToProcess: string) => {
    let rawText = textToProcess.trim();
    if (!rawText) return;
    if (!rawText.startsWith('#')) {
      rawText = '#' + rawText;
    }
    if (!hashtags.includes(rawText)) {
      setHashtags([...hashtags, rawText]);
    }
    setCurrentHashtag('');
  };

  const handleHashtagChange = (text: string) => {
    if (text.endsWith(' ') || text.endsWith('\n')) {
      processHashtag(text);
    } else {
      setCurrentHashtag(text);
    }
  };

  const removeHashtag = (tagToRemove: string) => {
    setHashtags(hashtags.filter(tag => tag !== tagToRemove));
  };

  const handlePublish = async () => {
    if (images.length === 0) {
      Alert.alert('提示', '請至少保留一張照片');
      return;
    }
    
    const newPost = {
      id: Date.now().toString(),
      imageUrl: images[0], 
      type: 'photo',
      hashtags: hashtags, 
      location: selectedLocation
    };
    
    try {
      const existingPostsJson = await AsyncStorage.getItem('my-posts');
      const existingPosts = existingPostsJson ? JSON.parse(existingPostsJson) : [];
      const updatedPosts = [newPost, ...existingPosts];
      
      await AsyncStorage.setItem('my-posts', JSON.stringify(updatedPosts));
      router.push('/(tabs)/profile' as any);
    } catch (error) {
      console.error('儲存貼文失敗:', error);
      Alert.alert('錯誤', '發布失敗，請重試');
    }
  };

  const renderLocationItem = ({ item }: { item: any }) => (
    <TouchableOpacity 
      style={styles.locationListItem}
      onPress={() => {
        setSelectedLocation(item.name);
        setLocationModalVisible(false);
        setSearchQuery('');
      }}
    >
      <Text style={styles.locationListName}>{item.name}</Text>
      <Text style={styles.locationListSubtitle}>{item.address}</Text>
    </TouchableOpacity>
  );

  return (
    <SafeAreaView style={styles.container}>

      <KeyboardAvoidingView 
        style={{ flex: 1 }} 
        behavior={Platform.OS === 'ios' ? 'padding' : undefined}
      >
        <View style={styles.header}>
          <TouchableOpacity onPress={() => router.back()} style={styles.backButton}>
            <Feather name="arrow-left" size={24} color="#007AFF" />
          </TouchableOpacity>
          <Text style={styles.headerTitle}>新貼文</Text>
          <View style={{ width: 24 }} />
        </View>

        <ScrollView 
          style={styles.content} 
          showsVerticalScrollIndicator={false}
          keyboardShouldPersistTaps="handled"
        >
          <ScrollView horizontal showsHorizontalScrollIndicator={false} style={styles.imageScroll}>
            {images.map((uri, index) => (
              <TouchableOpacity 
                key={index} 
                activeOpacity={0.8} 
                onPress={() => handleImageTap(index)}
                style={styles.imageWrapper}
              >
                <Image source={{ uri }} style={styles.selectedImage} />
                <View style={styles.editBadge}>
                  <Feather name="edit-2" size={14} color="white" />
                </View>
              </TouchableOpacity>
            ))}
            
            {images.length < 10 && (
              <TouchableOpacity style={styles.addImageButton} onPress={pickImages}>
                <Feather name="plus" size={32} color="#999" />
              </TouchableOpacity>
            )}
          </ScrollView>

          <View style={styles.textInputContainer}>
            <TextInput
              style={styles.textInput}
              placeholder="新增說明文字..."
              placeholderTextColor="#999"
              multiline
              value={description}
              onChangeText={setDescription}
            />
          </View>

          <View style={styles.sectionContainer}>
            <View style={styles.sectionHeader}>
              <View style={styles.sectionTitleRow}>
                <Feather name="map-pin" size={20} color="#666" style={styles.sectionIcon} />
                <Text style={styles.sectionTitle}>地點 <Text style={styles.required}>*</Text></Text>
              </View>
            </View>
            
            <TouchableOpacity 
              style={styles.locationSelectorBtn}
              activeOpacity={0.7}
              onPress={() => setLocationModalVisible(true)}
            >
              <Text style={[styles.locationSelectorText, !selectedLocation && { color: '#999' }]}>
                {selectedLocation ? selectedLocation : '新增地點...'}
              </Text>
              <Feather name="chevron-right" size={20} color="#999" />
            </TouchableOpacity>
          </View>

          <View style={styles.sectionContainer}>
            <View style={styles.sectionHeader}>
              <View style={styles.sectionTitleRow}>
                <Feather name="hash" size={20} color="#666" style={styles.sectionIcon} />
                <Text style={styles.sectionTitle}>相關旅遊標籤 <Text style={styles.required}>*</Text></Text>
              </View>
            </View>
            
            <View style={styles.hashtagContainer}>
              {hashtags.map((tag, index) => (
                <View key={index} style={styles.hashtagPill}>
                  <Text style={styles.hashtagText}>{tag}</Text>
                  <TouchableOpacity onPress={() => removeHashtag(tag)} style={styles.removeTagBtn}>
                    <Feather name="x" size={14} color="#007AFF" />
                  </TouchableOpacity>
                </View>
              ))}

              <TextInput
                style={styles.hashtagInput}
                placeholder={hashtags.length === 0 ? "輸入後按空白鍵產生標籤" : "新增標籤..."}
                placeholderTextColor="#999"
                value={currentHashtag}
                onChangeText={handleHashtagChange}
                onSubmitEditing={() => processHashtag(currentHashtag)}
                blurOnSubmit={false}
              />
            </View>
          </View>
        </ScrollView>

        <View style={styles.footer}>
          <TouchableOpacity style={styles.publishButton} onPress={handlePublish}>
            <Text style={styles.publishButtonText}>發布</Text>
          </TouchableOpacity>
        </View>
      </KeyboardAvoidingView>

      <Modal
        visible={isLocationModalVisible}
        animationType="slide"
        presentationStyle="pageSheet"
        onRequestClose={() => setLocationModalVisible(false)}
      >
        <SafeAreaView style={styles.modalContainer}>
          <View style={styles.modalHeader}>
            <View style={{ width: 40 }} />
            <Text style={styles.modalTitle}>地點</Text>
            <TouchableOpacity onPress={() => setLocationModalVisible(false)} style={styles.modalCancelBtn}>
              <Text style={styles.modalCancelText}>取消</Text>
            </TouchableOpacity>
          </View>

          <View style={styles.searchBarContainer}>
            <Feather name="search" size={18} color="#8E8E93" style={styles.searchIcon} />
            <TextInput
              style={styles.searchInput}
              placeholder="搜尋"
              placeholderTextColor="#8E8E93"
              value={searchQuery}
              onChangeText={setSearchQuery}
              autoFocus={false}
            />
          </View>

          <FlatList
            data={searchResults}
            keyExtractor={(item) => item.id}
            renderItem={renderLocationItem}
            contentContainerStyle={styles.locationList}
            showsVerticalScrollIndicator={false}
            ListEmptyComponent={
              searchQuery.length > 0 ? (
                <Text style={{ textAlign: 'center', marginTop: 20, color: '#999' }}>找不到相關地點</Text>
              ) : null
            }
          />
        </SafeAreaView>
      </Modal>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#F2F9FF' },
  header: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', paddingHorizontal: 15, paddingVertical: 15, backgroundColor: '#F2F9FF' },
  backButton: { padding: 5 },
  headerTitle: { fontSize: 18, fontWeight: 'bold', color: '#007AFF' },
  content: { flex: 1 },
  
  imageScroll: { paddingHorizontal: 15, marginTop: 10, marginBottom: 20 },
  imageWrapper: { position: 'relative', marginRight: 10 },
  selectedImage: { width: 150, height: 150, borderRadius: 10, backgroundColor: '#E0E0E0' },
  editBadge: { position: 'absolute', right: 8, top: 8, backgroundColor: 'rgba(0,0,0,0.6)', padding: 6, borderRadius: 12 },
  addImageButton: { width: 150, height: 150, borderRadius: 10, backgroundColor: '#E0E0E0', justifyContent: 'center', alignItems: 'center', borderWidth: 1, borderColor: '#CCC', borderStyle: 'dashed' },
  
  textInputContainer: { backgroundColor: '#FFF', borderRadius: 12, marginHorizontal: 20, marginBottom: 25, padding: 15, minHeight: 120, shadowColor: '#000', shadowOffset: { width: 0, height: 2 }, shadowOpacity: 0.05, shadowRadius: 4, elevation: 2 },
  textInput: { flex: 1, fontSize: 16, color: '#333', textAlignVertical: 'top', lineHeight: 24 },

  sectionContainer: { paddingHorizontal: 20, marginBottom: 25 },
  sectionHeader: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', marginBottom: 10 },
  sectionTitleRow: { flexDirection: 'row', alignItems: 'center' },
  sectionIcon: { marginRight: 10 },
  sectionTitle: { fontSize: 16, color: '#333', fontWeight: '500' },
  required: { color: 'red' },
  
  locationSelectorBtn: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', backgroundColor: '#E8F1FA', borderRadius: 8, paddingHorizontal: 15, paddingVertical: 15 },
  locationSelectorText: { fontSize: 16, color: '#333' },
  
  hashtagContainer: { flexDirection: 'row', flexWrap: 'wrap', backgroundColor: '#E8F1FA', borderRadius: 8, padding: 10, minHeight: 50, alignItems: 'center' },
  hashtagPill: { flexDirection: 'row', alignItems: 'center', backgroundColor: '#CCE0F5', borderRadius: 15, paddingVertical: 6, paddingHorizontal: 12, marginRight: 8, marginBottom: 8 },
  hashtagText: { color: '#007AFF', fontSize: 14, fontWeight: '500', marginRight: 5 },
  removeTagBtn: { backgroundColor: 'rgba(0,122,255,0.1)', borderRadius: 10, padding: 2 },
  hashtagInput: { flex: 1, minWidth: 150, fontSize: 15, color: '#333', paddingVertical: 6, marginBottom: 8 },

  footer: { padding: 20, paddingBottom: 30, position: 'relative' },
  publishButton: { backgroundColor: '#007AFF', paddingVertical: 15, borderRadius: 10, alignItems: 'center' },
  publishButtonText: { color: '#FFF', fontSize: 18, fontWeight: 'bold' },
  
  modalContainer: { flex: 1, backgroundColor: '#FFF' },
  modalHeader: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', paddingHorizontal: 15, paddingVertical: 12, borderBottomWidth: 1, borderBottomColor: '#F0F0F0', marginBottom: 10 },
  modalTitle: { fontSize: 18, fontWeight: 'bold', color: '#000' },
  modalCancelBtn: { padding: 5, minWidth: 60, alignItems: 'flex-end' },
  modalCancelText: { fontSize: 16, color: '#007AFF' },
  
  searchBarContainer: { flexDirection: 'row', alignItems: 'center', backgroundColor: '#F2F2F7', borderRadius: 10, marginHorizontal: 15, paddingHorizontal: 10, height: 40, marginBottom: 10 },
  searchIcon: { marginRight: 8 },
  searchInput: { flex: 1, fontSize: 16, color: '#000' },
  locationList: { paddingHorizontal: 15, paddingBottom: 40 },
  locationListItem: { paddingVertical: 12, borderBottomWidth: StyleSheet.hairlineWidth, borderBottomColor: '#E5E5EA' },
  locationListName: { fontSize: 16, color: '#000', marginBottom: 4 },
  locationListSubtitle: { fontSize: 13, color: '#8E8E93' },
});
