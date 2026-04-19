// app/group-chat.tsx
import { Ionicons } from '@expo/vector-icons';
import { useRouter, useLocalSearchParams } from 'expo-router';
import React, { useState } from 'react';
import { Image, StyleSheet, Text, TextInput, TouchableOpacity, ScrollView, View, FlatList, KeyboardAvoidingView, Platform, Alert, Modal, Dimensions, Switch, ActivityIndicator } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import * as ImagePicker from 'expo-image-picker';
import DateTimePicker from '@react-native-community/datetimepicker';
import MapView, { Marker } from 'react-native-maps'; 
import { usePlans } from '../components/PlanContext';

const { width } = Dimensions.get('window');

export default function GroupChatScreen() {
  const router = useRouter();
  const params: any = useLocalSearchParams();
  const planId = params.planId;
  
  const { getPlanById, getMessages, sendMessage, sendImage, addVote, addItineraryItem, castVote, searchGooglePlaces, getPlaceDetails, getItinerary, reverseGeocodeGoogle } = usePlans() as any;
  const currentPlan = getPlanById(planId);
  const planTitle = currentPlan ? `${currentPlan.title}(${currentPlan.members})` : '群組';

  const [inputText, setInputText] = useState('');
  const messages = getMessages(planId);

  // 投票設定狀態
  const [isVoteModalVisible, setIsVoteModalVisible] = useState(false);
  const [voteCategory, setVoteCategory] = useState('general'); 
  const [voteQuestion, setVoteQuestion] = useState('');
  const [voteOptions, setVoteOptions] = useState<any[]>([{ text: '', coordinate: null }, { text: '', coordinate: null }]);
  
  const [isMultiSelect, setIsMultiSelect] = useState(false); 
  const [isAnonymous, setIsAnonymous] = useState(false);
  const [deadline, setDeadline] = useState('無限制'); 
  const [showDatePicker, setShowDatePicker] = useState(false);
  const [customDate, setCustomDate] = useState(new Date());
  
  const defaultDeadlines = ['無限制', '1小時後', '今天半夜'];

  const [plusMenuVisible, setPlusMenuVisible] = useState(false);

  // 地圖選點狀態
  const [mapPickerVisible, setMapPickerVisible] = useState(false); 
  const [editingOptionIndex, setEditingOptionIndex] = useState<number | null>(null); 
  const [tempCoordinate, setTempCoordinate] = useState<any>(null); 
  const [tempName, setTempName] = useState<string>(''); 

  // 搜尋狀態
  const [searchQuery, setSearchQuery] = useState('');
  const [searchResults, setSearchResults] = useState<any[]>([]);
  const [isSearching, setIsSearching] = useState(false);

  const onDateChange = (event: any, selectedDate?: Date) => {
      if (Platform.OS === 'android') setShowDatePicker(false);
      if (selectedDate) {
          setCustomDate(selectedDate);
          const mm = selectedDate.getMonth() + 1;
          const dd = selectedDate.getDate();
          const hh = String(selectedDate.getHours()).padStart(2, '0');
          const min = String(selectedDate.getMinutes()).padStart(2, '0');
          setDeadline(`${mm}/${dd} ${hh}:${min}`);
      }
  };

  const handleCategoryChange = (category: string) => {
      setVoteCategory(category);
      if (category === 'spot') {
          setVoteQuestion('基於目前的行程，大家下個景點想去哪？');
          
          const itinerary = getItinerary(planId);
          const existingSpots = itinerary.flatMap((day: any) => day.items.map((item: any) => item.title));

          const allTainanSpots = [
              { text: '奇美博物館', coordinate: { lat: 22.934, lng: 120.226 } },
              { text: '安平古堡', coordinate: { lat: 23.001, lng: 120.160 } },
              { text: '神農街', coordinate: { lat: 22.997, lng: 120.197 } },
              { text: '林家白糖粿', coordinate: { lat: 22.993, lng: 120.197 } },
              { text: '十鼓仁糖文創園區', coordinate: { lat: 22.939, lng: 120.231 } },
              { text: '漁光島', coordinate: { lat: 22.981, lng: 120.157 } },
              { text: '藍晒圖文創園區', coordinate: { lat: 22.987, lng: 120.197 } },
              { text: '花園夜市', coordinate: { lat: 23.011, lng: 120.199 } }
          ];

          const recommended = allTainanSpots.filter(s => !existingSpots.includes(s.text)).slice(0, 4);

          if (recommended.length === 0) {
              setVoteOptions([{ text: '', coordinate: null }, { text: '', coordinate: null }]);
          } else {
              setVoteOptions(recommended);
          }
      } else {
          setVoteQuestion('');
          setVoteOptions([{ text: '', coordinate: null }, { text: '', coordinate: null }]);
      }
  };

  const handleSend = () => {
      if (!inputText.trim()) return;
      sendMessage(planId, inputText);
      setInputText('');
  };

  const handlePickImage = async (useCamera: boolean) => {
      const permission = useCamera ? await ImagePicker.requestCameraPermissionsAsync() : await ImagePicker.requestMediaLibraryPermissionsAsync();
      if (permission.status !== 'granted') return Alert.alert('權限不足', '請允許存取權限');
      let result = useCamera ? await ImagePicker.launchCameraAsync({ quality: 0.7 }) : await ImagePicker.launchImageLibraryAsync({ quality: 0.7 });
      if (!result.canceled) {
          sendImage(planId, result.assets[0].uri);
          setPlusMenuVisible(false);
      }
  };

  const handleCreateVote = () => {
      const validOptions = voteOptions.filter(o => o.text.trim());
      if (!voteQuestion.trim() || validOptions.length < 2) return Alert.alert('提示', '請輸入問題與至少兩個選項');

      addVote(planId, {
          question: voteQuestion,
          options: validOptions.map(opt => ({ text: opt.text, coordinate: opt.coordinate, count: 0 })), 
          status: 'open',
          isMultiSelect: isMultiSelect,
          isAnonymous: isAnonymous,
          deadline: deadline
      });

      setIsVoteModalVisible(false);
      setPlusMenuVisible(false);
      setVoteQuestion('');
      setVoteOptions([{ text: '', coordinate: null }, { text: '', coordinate: null }]);
      setIsMultiSelect(false);
      setIsAnonymous(false);
      setDeadline('無限制');
  };

  const finalizeVote = async (voteData: any) => {
    const winner = [...voteData.options].sort((a, b) => b.count - a.count)[0];
    
    Alert.alert("投票結束", `最高票是「${winner.text}」，要直接加入行程嗎？`, [
        { text: "取消", style: "cancel" },
        { 
          text: "確定加入", 
          onPress: async () => {
            const itinerary = getItinerary(planId);
            const targetDay = itinerary.length > 0 ? itinerary[0].day : 'DAY1';

            let realCoordinate = winner.coordinate; 
            if (!realCoordinate) realCoordinate = { lat: 22.9971, lng: 120.2126 }; 

            addItineraryItem(planId, targetDay, {
                title: winner.text,
                desc: '由群組投票決定',
                type: 'activity',
                durationValue: 60,
                time: '12:00',
                coordinate: realCoordinate, 
            }, -1); 
            
            router.push({ pathname: '/(tabs)/itinerary', params: { id: planId, title: currentPlan.title } } as any);
          }
        }
    ]);
  };

  const openMapPicker = (index: number) => {
      setEditingOptionIndex(index);
      setTempCoordinate(voteOptions[index].coordinate);
      setTempName(voteOptions[index].text || '');
      setSearchQuery('');
      setSearchResults([]);
      setMapPickerVisible(true);
  };

  const executeMapSearch = async (text: string) => {
      setSearchQuery(text);
      if (text.length > 0) {
          setIsSearching(true);
          const results = await searchGooglePlaces(`${currentPlan?.title || ''} ${text}`);
          setSearchResults(results);
          setIsSearching(false);
      } else {
          setSearchResults([]);
      }
  };

  const handleSelectPlaceFromSearch = async (place: any) => {
      setIsSearching(true);
      const details = await getPlaceDetails(place.place_id);
      setIsSearching(false);

      if (details) {
          setTempCoordinate(details.coordinate);
          setTempName(details.name);            
          setSearchResults([]);                 
          setSearchQuery('');                   
      }
  };

  const handleMapPress = async (e: any) => {
      const { latitude, longitude } = e.nativeEvent.coordinate;
      setTempCoordinate({ lat: latitude, lng: longitude });
      setTempName('尋找地名中...');
      
      const res = await reverseGeocodeGoogle(latitude, longitude);
      if (res) {
          setTempName(res.title);
      } else {
          setTempName('自訂地點');
      }
  };

  const confirmMapSelection = () => {
      if (editingOptionIndex === null) return;
      if (!tempCoordinate || !tempName) {
          Alert.alert('提示', '請先在地圖上選擇一個地點');
          return;
      }
      
      const newOpts = [...voteOptions];
      newOpts[editingOptionIndex] = { text: tempName, coordinate: tempCoordinate };
      setVoteOptions(newOpts);
      setMapPickerVisible(false);
  };

  const getInitialRegion = () => {
      if (tempCoordinate) {
          return { latitude: tempCoordinate.lat, longitude: tempCoordinate.lng, latitudeDelta: 0.02, longitudeDelta: 0.02 };
      }
      const validCoords = voteOptions.filter(o => o.coordinate).map(o => o.coordinate);
      if (validCoords.length === 0) return { latitude: 22.9971, longitude: 120.2126, latitudeDelta: 0.1, longitudeDelta: 0.1 };
      
      const avgLat = validCoords.reduce((sum, c) => sum + c.lat, 0) / validCoords.length;
      const avgLng = validCoords.reduce((sum, c) => sum + c.lng, 0) / validCoords.length;
      return { latitude: avgLat, longitude: avgLng, latitudeDelta: 0.05, longitudeDelta: 0.05 };
  };

  return (
    <SafeAreaView style={styles.container} edges={['top']}>
      <View style={styles.header}>
         <TouchableOpacity onPress={() => router.back()} style={{padding: 10}}>
             <Ionicons name="chevron-back" size={28} color="#333" />
         </TouchableOpacity>
         <Text style={styles.headerTitle}>{planTitle}</Text>
         <View style={{width: 48}} /> 
      </View>

      <FlatList
          data={messages}
          keyExtractor={item => item.id}
          style={styles.chatList}
          contentContainerStyle={{padding: 15, paddingBottom: 30}}
          renderItem={({ item }) => {
              const isMe = item.sender === 'me';
              
              if (item.type === 'vote') {
                  return (
                      <View style={styles.voteMsgContainer}>
                          <View style={styles.voteCard}>
                              <View style={styles.voteCardHeader}>
                                  <Ionicons name="stats-chart" size={18} color="#6CA6CC" />
                                  <Text style={styles.voteCardTitle}> 行程投票發起</Text>
                              </View>
                              <Text style={styles.voteQuestion}>{item.text}</Text>
                              
                              <View style={styles.voteTagsContainer}>
                                  {item.voteData?.isMultiSelect && <Text style={styles.voteTag}>☑️ 可複選</Text>}
                                  {item.voteData?.isAnonymous && <Text style={styles.voteTag}>👤 匿名</Text>}
                                  <Text style={[styles.voteTag, item.voteData?.deadline !== '無限制' && {color: '#FF8888', backgroundColor: '#FFF0F0'}]}>
                                      ⏰ {item.voteData?.deadline === '無限制' ? '暫無截止日' : `截止：${item.voteData?.deadline}`}
                                  </Text>
                              </View>

                              {item.voteData?.options.map((opt: any, idx: number) => {
                                  const isVotedByMe = opt.voters && opt.voters.includes('me');
                                  return (
                                      <TouchableOpacity 
                                          key={idx} 
                                          style={[styles.voteOptionBtnChat, isVotedByMe && { backgroundColor: '#EAF4FA', borderColor: '#6CA6CC', borderWidth: 2 }]}
                                          onPress={() => castVote(planId, item.id, idx, 'me')}
                                      >
                                          <View style={[styles.optionDot, isVotedByMe && { backgroundColor: '#FF9F43', transform: [{scale: 1.5}] }]} />
                                          <View style={{flex: 1}}>
                                              <Text style={[styles.voteOptionTextChat, isVotedByMe && { fontWeight: 'bold', color: '#6CA6CC' }]}>{opt.text}</Text>
                                          </View>
                                          <Text style={styles.voteCount}>{opt.count} 票</Text>
                                      </TouchableOpacity>
                                  );
                              })}
                              <TouchableOpacity style={styles.finalizeBtn} onPress={() => finalizeVote(item.voteData)}>
                                  <Text style={styles.finalizeBtnText}>結束投票並加入行程</Text>
                              </TouchableOpacity>
                          </View>
                      </View>
                  );
              }

              return (
                  <View style={[styles.msgRow, isMe ? styles.msgRowMe : styles.msgRowOther]}>
                      {!isMe && <Image source={item.avatar} style={styles.avatar} />}
                      {item.type === 'image' ? (
                          <View style={[styles.imageBubble, isMe ? styles.imageBubbleMe : styles.imageBubbleOther]}>
                              <Image source={{ uri: item.image }} style={styles.msgImage} resizeMode="cover" />
                          </View>
                      ) : (
                          <View style={[styles.bubble, isMe ? styles.bubbleMe : styles.bubbleOther]}>
                              <Text style={[styles.msgText, isMe && {color: 'white'}]}>{item.text}</Text>
                          </View>
                      )}
                      {isMe && <Image source={item.avatar} style={styles.avatarMe} />}
                  </View>
              );
          }}
      />

      <KeyboardAvoidingView behavior={Platform.OS === 'ios' ? 'padding' : undefined}>
          <View style={styles.inputBar}>
              <TouchableOpacity style={styles.iconBtn} onPress={() => setPlusMenuVisible(true)}>
                  <Ionicons name="add-circle-outline" size={34} color="#6CA6CC" />
              </TouchableOpacity>
              <TextInput style={styles.input} value={inputText} onChangeText={setInputText} placeholder="輸入訊息..." multiline />
              <TouchableOpacity style={styles.sendBtn} onPress={handleSend}>
                  <Ionicons name="paper-plane" size={20} color="white" />
              </TouchableOpacity>
          </View>
      </KeyboardAvoidingView>

      <Modal visible={plusMenuVisible} transparent animationType="fade">
          <TouchableOpacity style={styles.menuOverlay} activeOpacity={1} onPress={() => setPlusMenuVisible(false)}>
              <View style={styles.menuContainer}>
                  <View style={styles.menuGrid}>
                      <TouchableOpacity style={styles.menuGridItem} onPress={() => { setIsVoteModalVisible(true); setPlusMenuVisible(false); }}>
                          <View style={[styles.menuIconCircle, { backgroundColor: '#FF9F43' }]}><Ionicons name="stats-chart" size={24} color="white" /></View>
                          <Text style={styles.menuGridText}>發起投票</Text>
                      </TouchableOpacity>
                      <TouchableOpacity style={styles.menuGridItem} onPress={() => handlePickImage(true)}>
                          <View style={[styles.menuIconCircle, { backgroundColor: '#54A0FF' }]}><Ionicons name="camera" size={24} color="white" /></View>
                          <Text style={styles.menuGridText}>拍照</Text>
                      </TouchableOpacity>
                      <TouchableOpacity style={styles.menuGridItem} onPress={() => handlePickImage(false)}>
                          <View style={[styles.menuIconCircle, { backgroundColor: '#1DD1A1' }]}><Ionicons name="image" size={24} color="white" /></View>
                          <Text style={styles.menuGridText}>相簿</Text>
                      </TouchableOpacity>
                  </View>
              </View>
          </TouchableOpacity>
      </Modal>

      {/* 投票建立 Modal */}
      <Modal visible={isVoteModalVisible} transparent={true} animationType="slide" onRequestClose={() => setIsVoteModalVisible(false)}>
          <View style={styles.voteModalOverlay}>
              <View style={[styles.voteModalContent, mapPickerVisible && { height: '95%', paddingBottom: 0 }]}>
                  {!mapPickerVisible && <View style={styles.dragHandle} />}
                  
                  {mapPickerVisible ? (
                      // 地圖選點模式
                      <View style={{ flex: 1, backgroundColor: '#fff', borderRadius: 20, overflow: 'hidden' }}>
                          <View style={styles.mapHeader}>
                              <TouchableOpacity onPress={() => setMapPickerVisible(false)} style={{padding: 5}}><Ionicons name="chevron-down" size={28} color="#333" /></TouchableOpacity>
                              <Text style={styles.mapHeaderTitle}>更改選項 {editingOptionIndex !== null ? editingOptionIndex + 1 : ''}</Text>
                              <View style={{width: 38}} />
                          </View>

                          <View style={styles.mapSearchContainer}>
                              <Ionicons name="search" size={20} color="#999" />
                              <TextInput 
                                  style={styles.searchInput} 
                                  placeholder="輸入地名或直接點擊地圖..."
                                  value={searchQuery}
                                  onChangeText={executeMapSearch}
                              />
                              {searchQuery.length > 0 && (
                                  <TouchableOpacity onPress={() => executeMapSearch('')}><Ionicons name="close-circle" size={20} color="#CCC" /></TouchableOpacity>
                              )}
                          </View>

                          {searchResults.length > 0 && (
                              <View style={styles.searchResultsOverlay}>
                                  <FlatList 
                                      data={searchResults}
                                      keyExtractor={(item) => item.place_id}
                                      keyboardShouldPersistTaps="handled"
                                      renderItem={({item}) => (
                                          <TouchableOpacity style={styles.mapSearchResultItem} onPress={() => handleSelectPlaceFromSearch(item)}>
                                              <Ionicons name="location-sharp" size={20} color="#FF6B6B" style={{marginRight: 10}} />
                                              <View style={{flex: 1}}>
                                                  <Text style={{fontWeight: 'bold', color: '#333'}}>{item.structured_formatting.main_text}</Text>
                                                  <Text style={{fontSize: 12, color: '#888'}}>{item.structured_formatting.secondary_text}</Text>
                                              </View>
                                          </TouchableOpacity>
                                      )}
                                  />
                              </View>
                          )}

                          <MapView 
                              style={{ flex: 1 }}
                              initialRegion={getInitialRegion()}
                              onPress={handleMapPress}
                          >
                              {voteOptions.map((opt, idx) => {
                                  if (idx === editingOptionIndex || !opt.coordinate) return null;
                                  return (
                                      <Marker key={idx} coordinate={{ latitude: opt.coordinate.lat, longitude: opt.coordinate.lng }}>
                                          <View style={{ alignItems: 'center', opacity: 0.7 }}>
                                              <View style={[styles.customMarkerBubble, {backgroundColor: '#999'}]}>
                                                  <Text style={styles.customMarkerText}>{idx + 1}</Text>
                                              </View>
                                              <View style={[styles.customMarkerTriangle, {borderTopColor: '#999'}]} />
                                              <Text style={styles.customMarkerLabel} numberOfLines={1}>{opt.text}</Text>
                                          </View>
                                      </Marker>
                                  );
                              })}

                              {tempCoordinate && (
                                  <Marker coordinate={{ latitude: tempCoordinate.lat, longitude: tempCoordinate.lng }}>
                                      <View style={{ alignItems: 'center' }}>
                                          <View style={[styles.customMarkerBubble, {backgroundColor: '#54A0FF', width: 34, height: 34, borderRadius: 17}]}>
                                              <Ionicons name="star" size={16} color="#FFF" />
                                          </View>
                                          <View style={[styles.customMarkerTriangle, {borderTopColor: '#54A0FF', borderTopWidth: 10}]} />
                                      </View>
                                  </Marker>
                              )}
                          </MapView>

                          <View style={styles.mapBottomPanel}>
                              <View style={{flex: 1, marginRight: 15}}>
                                  <Text style={{fontSize: 12, color: '#888', marginBottom: 4}}>目前選擇的地點：</Text>
                                  <Text style={{fontSize: 16, fontWeight: 'bold', color: '#333'}} numberOfLines={1}>
                                      {tempName || '請點擊地圖或搜尋'}
                                  </Text>
                              </View>
                              <TouchableOpacity style={[styles.mapConfirmBtn, !tempCoordinate && {backgroundColor: '#CCC'}]} onPress={confirmMapSelection} disabled={!tempCoordinate}>
                                  <Text style={{color: '#FFF', fontWeight: 'bold'}}>確定替換</Text>
                              </TouchableOpacity>
                          </View>
                      </View>
                  ) : (
                      <>
                          <View style={styles.voteModalHeader}>
                              <TouchableOpacity onPress={() => setIsVoteModalVisible(false)} style={{ padding: 5 }}><Text style={styles.cancelText}>取消</Text></TouchableOpacity>
                              <Text style={styles.voteModalTitle}>發起新投票</Text>
                              <TouchableOpacity onPress={handleCreateVote} style={styles.publishBtn}><Text style={styles.publishBtnText}>發布</Text></TouchableOpacity>
                          </View>

                          <ScrollView contentContainerStyle={{ paddingHorizontal: 25, paddingBottom: 50 }} showsVerticalScrollIndicator={false}>
                              <View style={styles.voteTypeSelector}>
                                  <TouchableOpacity style={[styles.voteTypeBtn, voteCategory === 'general' && styles.voteTypeBtnActive]} onPress={() => handleCategoryChange('general')}>
                                      <Text style={[styles.voteTypeText, voteCategory === 'general' && styles.voteTypeTextActive]}>一般投票</Text>
                                  </TouchableOpacity>
                                  <TouchableOpacity style={[styles.voteTypeBtn, voteCategory === 'spot' && styles.voteTypeBtnActive]} onPress={() => handleCategoryChange('spot')}>
                                      <Text style={[styles.voteTypeText, voteCategory === 'spot' && styles.voteTypeTextActive]}>📍 景點投票</Text>
                                  </TouchableOpacity>
                              </View>

                              <Text style={styles.sectionLabel}>{voteCategory === 'spot' ? '景點提問 💬' : '大家來表決 💬'}</Text>
                              <View style={styles.questionContainer}>
                                  <TextInput style={styles.questionInput} placeholder="想問大家什麼呢？" placeholderTextColor="#aaa" value={voteQuestion} onChangeText={setVoteQuestion} multiline />
                              </View>

                              <Text style={styles.sectionLabel}>{voteCategory === 'spot' ? '候選景點清單 📋' : '選項 📋'}</Text>
                              
                              {voteOptions.map((opt, idx) => (
                                  <View key={idx} style={styles.optionRowWrapper}>
                                      <View style={styles.optionNumberCircle}>
                                          <Text style={styles.optionNumberText}>{idx + 1}</Text>
                                      </View>
                                      
                                      {voteCategory === 'general' ? (
                                          <TextInput 
                                              style={styles.optionInputUI}
                                              placeholder={`輸入選項...`}
                                              placeholderTextColor="#bbb"
                                              value={opt.text}
                                              onChangeText={(t) => {
                                                  const newOpts = [...voteOptions];
                                                  newOpts[idx].text = t;
                                                  setVoteOptions(newOpts);
                                              }}
                                          />
                                      ) : (
                                          <View style={[styles.optionInputUI, { justifyContent: 'center' }]}>
                                              <Text style={{ color: opt.text ? '#333' : '#bbb', fontSize: 16, fontWeight: opt.text ? 'bold' : 'normal' }} numberOfLines={1}>
                                                  {opt.text ? opt.text : `尚未選擇地點`}
                                              </Text>
                                          </View>
                                      )}
                                      
                                      {voteCategory === 'spot' && (
                                          <TouchableOpacity onPress={() => openMapPicker(idx)} style={{padding: 10}}>
                                              <Ionicons name="map" size={24} color={opt.coordinate ? "#54A0FF" : "#FF9F43"} />
                                          </TouchableOpacity>
                                      )}

                                      {voteOptions.length > 2 && (
                                          <TouchableOpacity style={styles.deleteOptionBtn} onPress={() => setVoteOptions(voteOptions.filter((_, i) => i !== idx))}>
                                              <Ionicons name="close-circle" size={22} color="#FF8888" />
                                          </TouchableOpacity>
                                      )}
                                  </View>
                              ))}

                              <TouchableOpacity style={styles.addMoreOptionBtn} onPress={() => setVoteOptions([...voteOptions, { text: '', coordinate: null }])}>
                                  <Ionicons name="add-circle-outline" size={20} color="#6CA6CC" />
                                  <Text style={styles.addMoreOptionText}>新增選項</Text>
                              </TouchableOpacity>

                              <Text style={styles.sectionLabel}>截止時間 ⏰</Text>
                              <View style={styles.deadlineSelector}>
                                  {defaultDeadlines.map(t => (
                                      <TouchableOpacity key={t} style={[styles.deadlineBtn, deadline === t && styles.deadlineBtnActive]} onPress={() => setDeadline(t)}>
                                          <Text style={[styles.deadlineText, deadline === t && styles.deadlineTextActive]}>{t}</Text>
                                      </TouchableOpacity>
                                  ))}
                                  <TouchableOpacity style={[styles.deadlineBtn, !defaultDeadlines.includes(deadline) && styles.deadlineBtnActive]} onPress={() => setShowDatePicker(true)}>
                                      <Text style={[styles.deadlineText, !defaultDeadlines.includes(deadline) && styles.deadlineTextActive]}>{!defaultDeadlines.includes(deadline) ? deadline : '自訂...'}</Text>
                                  </TouchableOpacity>
                              </View>

                              <Text style={styles.sectionLabel}>進階設定 ⚙️</Text>
                              <View style={styles.settingRow}>
                                  <Text style={styles.settingText}>一人多票 (可複選)</Text>
                                  <Switch value={isMultiSelect} onValueChange={setIsMultiSelect} trackColor={{ true: '#6CA6CC', false: '#ddd' }} />
                              </View>
                              <View style={styles.settingRow}>
                                  <Text style={styles.settingText}>匿名投票</Text>
                                  <Switch value={isAnonymous} onValueChange={setIsAnonymous} trackColor={{ true: '#6CA6CC', false: '#ddd' }} />
                              </View>
                          </ScrollView>

                          {showDatePicker && Platform.OS === 'ios' && (
                             <View style={styles.iosAbsoluteOverlay}>
                                 <View style={styles.datePickerContainer}>
                                     <Text style={styles.datePickerTitle}>自訂截止時間</Text>
                                     <DateTimePicker value={customDate} mode="datetime" display="spinner" onChange={onDateChange} textColor="#000" />
                                     <TouchableOpacity style={styles.confirmBtn} onPress={() => setShowDatePicker(false)}><Text style={styles.confirmBtnText}>完成</Text></TouchableOpacity>
                                 </View>
                             </View>
                          )}
                          {showDatePicker && Platform.OS === 'android' && <DateTimePicker value={customDate} mode="date" display="default" onChange={onDateChange} />}
                      </>
                  )}
              </View>
          </View>
      </Modal>

    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#F2F9FF' },
  header: { flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', borderBottomWidth: 1, borderBottomColor: '#eee', backgroundColor: '#fff', height: 60 },
  headerTitle: { fontSize: 18, fontWeight: 'bold' },
  chatList: { flex: 1 },
  msgRow: { flexDirection: 'row', alignItems: 'flex-end', marginBottom: 15, paddingHorizontal: 15 },
  msgRowMe: { justifyContent: 'flex-end' },
  msgRowOther: { justifyContent: 'flex-start' },
  avatar: { width: 35, height: 35, borderRadius: 17.5, marginRight: 8, backgroundColor: '#ccc' },
  avatarMe: { width: 35, height: 35, borderRadius: 17.5, marginLeft: 8, backgroundColor: '#ccc' },
  bubble: { maxWidth: '75%', padding: 12, borderRadius: 18, backgroundColor: '#fff', elevation: 1, shadowColor: '#000', shadowOffset: {width: 0, height: 1}, shadowOpacity: 0.1, shadowRadius: 1 },
  bubbleMe: { backgroundColor: '#6CA6CC', borderBottomRightRadius: 2 },
  bubbleOther: { borderBottomLeftRadius: 2 },
  msgText: { fontSize: 15, color: '#333' },
  imageBubble: { borderRadius: 15, overflow: 'hidden', elevation: 2 },
  imageBubbleMe: { borderBottomRightRadius: 2 },
  imageBubbleOther: { borderBottomLeftRadius: 2 },
  msgImage: { width: 200, height: 150 },
  
  inputBar: { flexDirection: 'row', alignItems: 'center', paddingHorizontal: 15, paddingVertical: 12, paddingBottom: Platform.OS === 'ios' ? 25 : 12, backgroundColor: '#fff', borderTopWidth: 1, borderTopColor: '#eee' },
  input: { flex: 1, backgroundColor: '#f0f0f0', borderRadius: 22, paddingHorizontal: 18, paddingVertical: 10, marginHorizontal: 10, fontSize: 16, maxHeight: 100 },
  iconBtn: { padding: 5 },
  sendBtn: { width: 44, height: 44, borderRadius: 22, backgroundColor: '#6CA6CC', justifyContent: 'center', alignItems: 'center' },
  
  voteMsgContainer: { width: '100%', alignItems: 'center', marginVertical: 15 },
  voteCard: { width: width * 0.85, backgroundColor: '#fff', borderRadius: 20, padding: 20, elevation: 5, shadowColor: '#000', shadowOpacity: 0.1, shadowRadius: 10 },
  voteCardHeader: { flexDirection: 'row', alignItems: 'center', marginBottom: 10 },
  voteCardTitle: { fontWeight: 'bold', color: '#6CA6CC', fontSize: 12 },
  voteQuestion: { fontSize: 18, fontWeight: 'bold', marginBottom: 15, color: '#333' },
  voteOptionBtnChat: { flexDirection: 'row', alignItems: 'center', padding: 15, backgroundColor: '#f8f9fa', borderRadius: 12, marginBottom: 10, borderWidth: 1, borderColor: '#eee' },
  voteOptionTextChat: { fontSize: 16, color: '#333' },
  voteCount: { color: '#6CA6CC', fontWeight: 'bold', marginLeft: 10 },
  finalizeBtn: { marginTop: 10, backgroundColor: '#6CA6CC', padding: 15, borderRadius: 12, alignItems: 'center' },
  finalizeBtnText: { color: '#fff', fontWeight: 'bold', fontSize: 16 },

  menuOverlay: { flex: 1, backgroundColor: 'rgba(0,0,0,0.4)', justifyContent: 'flex-end' },
  menuContainer: { backgroundColor: '#fff', borderTopLeftRadius: 25, borderTopRightRadius: 25, padding: 30, paddingBottom: 50 },
  menuGrid: { flexDirection: 'row', justifyContent: 'space-around' },
  menuGridItem: { alignItems: 'center' },
  menuIconCircle: { width: 60, height: 60, borderRadius: 30, justifyContent: 'center', alignItems: 'center', marginBottom: 10 },
  menuGridText: { fontSize: 14, color: '#666', fontWeight: '500' },

  voteModalOverlay: { flex: 1, backgroundColor: 'rgba(0,0,0,0.5)', justifyContent: 'flex-end' },
  voteModalContent: { backgroundColor: '#F8FBFF', borderTopLeftRadius: 30, borderTopRightRadius: 30, height: '90%', shadowColor: '#000', shadowOffset: { width: 0, height: -2 }, shadowOpacity: 0.1, shadowRadius: 10, elevation: 5, overflow: 'hidden' },
  dragHandle: { width: 50, height: 6, backgroundColor: '#DDDDDD', borderRadius: 3, alignSelf: 'center', marginTop: 15, marginBottom: 10 },
  voteModalHeader: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', paddingHorizontal: 20, paddingBottom: 20, borderBottomWidth: 1, borderBottomColor: '#EEF2F6' },
  cancelText: { fontSize: 16, color: '#888', fontWeight: '500' },
  voteModalTitle: { fontSize: 18, fontWeight: 'bold', color: '#333' },
  publishBtn: { backgroundColor: '#6CA6CC', paddingVertical: 8, paddingHorizontal: 18, borderRadius: 20 },
  publishBtnText: { color: 'white', fontWeight: 'bold', fontSize: 15 },
  
  voteTypeSelector: { flexDirection: 'row', backgroundColor: '#E8F1F8', borderRadius: 12, padding: 4, marginBottom: 20 },
  voteTypeBtn: { flex: 1, paddingVertical: 10, alignItems: 'center', borderRadius: 8 },
  voteTypeBtnActive: { backgroundColor: '#fff', shadowColor: '#000', shadowOffset: {width: 0, height: 1}, shadowOpacity: 0.1, shadowRadius: 2, elevation: 2 },
  voteTypeText: { fontSize: 15, color: '#888', fontWeight: 'bold' },
  voteTypeTextActive: { color: '#6CA6CC' },
  
  sectionLabel: { fontSize: 16, fontWeight: 'bold', color: '#555', marginTop: 10, marginBottom: 15 },
  questionContainer: { backgroundColor: '#fff', borderRadius: 15, padding: 15, borderWidth: 1, borderColor: '#E8F1F8', shadowColor: '#6CA6CC', shadowOffset: {width: 0, height: 2}, shadowOpacity: 0.05, shadowRadius: 5, elevation: 2 },
  questionInput: { fontSize: 18, color: '#333', fontWeight: 'bold', minHeight: 60, textAlignVertical: 'top' },
  
  optionDot: { width: 8, height: 8, borderRadius: 4, backgroundColor: '#6CA6CC', marginRight: 10 },
  optionRowWrapper: { flexDirection: 'row', alignItems: 'center', backgroundColor: '#fff', borderRadius: 12, paddingHorizontal: 10, marginBottom: 12, borderWidth: 1, borderColor: '#E8F1F8', elevation: 1 },
  optionNumberCircle: { width: 24, height: 24, borderRadius: 12, backgroundColor: '#6CA6CC', justifyContent: 'center', alignItems: 'center', marginRight: 10 },
  optionNumberText: { color: '#FFF', fontWeight: 'bold', fontSize: 12 },
  optionInputUI: { flex: 1, paddingVertical: 15, fontSize: 16, color: '#333' },
  deleteOptionBtn: { paddingLeft: 10, paddingRight: 5 },
  
  addMoreOptionBtn: { flexDirection: 'row', alignItems: 'center', justifyContent: 'center', backgroundColor: '#EAF4FA', paddingVertical: 15, borderRadius: 12, marginTop: 5, marginBottom: 20, borderStyle: 'dashed', borderWidth: 1, borderColor: '#A5CDE6' },
  addMoreOptionText: { color: '#6CA6CC', fontSize: 16, fontWeight: 'bold', marginLeft: 8 },

  deadlineSelector: { flexDirection: 'row', flexWrap: 'wrap', gap: 10, marginBottom: 20 },
  deadlineBtn: { backgroundColor: '#E8F1F8', paddingVertical: 10, paddingHorizontal: 15, borderRadius: 20 },
  deadlineBtnActive: { backgroundColor: '#6CA6CC' },
  deadlineText: { color: '#6CA6CC', fontSize: 14, fontWeight: 'bold' },
  deadlineTextActive: { color: '#fff' },

  settingRow: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', backgroundColor: '#fff', padding: 15, borderRadius: 12, marginBottom: 10, borderWidth: 1, borderColor: '#E8F1F8' },
  settingText: { fontSize: 16, color: '#333', fontWeight: '500' },
  voteTagsContainer: { flexDirection: 'row', flexWrap: 'wrap', marginBottom: 15, gap: 8 },
  voteTag: { backgroundColor: '#E8F1F8', color: '#6CA6CC', paddingHorizontal: 10, paddingVertical: 4, borderRadius: 12, fontSize: 12, fontWeight: 'bold', overflow: 'hidden' },

  iosAbsoluteOverlay: { position: 'absolute', top: 0, left: 0, right: 0, bottom: 0, backgroundColor: 'rgba(0,0,0,0.6)', justifyContent: 'center', alignItems: 'center', zIndex: 1000 },
  datePickerContainer: { width: '85%', backgroundColor: 'white', borderRadius: 20, padding: 20, alignItems: 'center', elevation: 5 },
  datePickerTitle: { fontSize: 18, fontWeight: 'bold', marginBottom: 15, color: '#333' },
  confirmBtn: { marginTop: 15, backgroundColor: '#6CA6CC', paddingVertical: 12, paddingHorizontal: 40, borderRadius: 20 },
  confirmBtnText: { color: 'white', fontSize: 16, fontWeight: 'bold' },

  mapHeader: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', paddingHorizontal: 20, paddingTop: 15, paddingBottom: 15, backgroundColor: '#FFF', zIndex: 10, elevation: 4 },
  mapHeaderTitle: { fontSize: 18, fontWeight: 'bold', color: '#333' },
  mapSearchContainer: { position: 'absolute', top: 75, left: 20, right: 20, flexDirection: 'row', alignItems: 'center', backgroundColor: '#FFF', borderRadius: 25, paddingHorizontal: 15, paddingVertical: 12, zIndex: 10, elevation: 5, shadowColor: '#000', shadowOffset: {width: 0, height: 2}, shadowOpacity: 0.2, shadowRadius: 4 },
  searchInput: { flex: 1, marginLeft: 10, fontSize: 16, color: '#333' },
  searchResultsOverlay: { position: 'absolute', top: 135, left: 20, right: 20, backgroundColor: '#FFF', borderRadius: 15, maxHeight: 200, zIndex: 10, elevation: 5, padding: 10 },
  mapSearchResultItem: { flexDirection: 'row', alignItems: 'center', paddingVertical: 12, borderBottomWidth: 1, borderBottomColor: '#F0F0F0' },
  mapBottomPanel: { position: 'absolute', bottom: 20, left: 20, right: 20, backgroundColor: '#FFF', borderRadius: 20, padding: 20, flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', elevation: 5, shadowColor: '#000', shadowOffset: {width: 0, height: 2}, shadowOpacity: 0.2, shadowRadius: 4 },
  mapConfirmBtn: { backgroundColor: '#54A0FF', paddingVertical: 12, paddingHorizontal: 20, borderRadius: 12 },

  customMarkerBubble: { backgroundColor: '#FF6B6B', width: 28, height: 28, borderRadius: 14, justifyContent: 'center', alignItems: 'center', elevation: 4, shadowColor: '#000', shadowOffset: { width: 0, height: 2 }, shadowOpacity: 0.3, shadowRadius: 2 },
  customMarkerText: { color: '#FFF', fontWeight: 'bold', fontSize: 14 },
  customMarkerTriangle: { width: 0, height: 0, borderLeftWidth: 6, borderRightWidth: 6, borderTopWidth: 8, borderLeftColor: 'transparent', borderRightColor: 'transparent', borderTopColor: '#FF6B6B', marginTop: -1 },
  customMarkerLabel: { backgroundColor: 'rgba(255,255,255,0.95)', paddingHorizontal: 6, paddingVertical: 3, borderRadius: 6, fontSize: 12, fontWeight: 'bold', color: '#333', marginTop: 2, borderWidth: 1, borderColor: '#DDD', maxWidth: 120, textAlign: 'center' }
});