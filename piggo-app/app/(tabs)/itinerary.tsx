// app/(tabs)/itinerary.tsx
import { FontAwesome, Ionicons, MaterialIcons } from '@expo/vector-icons';
import DateTimePicker from '@react-native-community/datetimepicker';
import * as ImagePicker from 'expo-image-picker';
import { useLocalSearchParams, useRouter } from 'expo-router';
import React, { useEffect, useRef, useState } from 'react';
import { ActivityIndicator, Alert, Image, Modal, ScrollView as NativeScrollView, Platform, StyleSheet, Text, TextInput, TouchableOpacity, View } from 'react-native';
import { NestableDraggableFlatList, NestableScrollContainer, ScaleDecorator } from 'react-native-draggable-flatlist';
import { usePlans } from '../../components/PlanContext';

const ITEM_HEIGHT = 50; 
const PICKER_PADDING = 50; 
const PICKER_HEIGHT = 150;

export default function ItineraryScreen() {
  const router = useRouter();
  const params: any = useLocalSearchParams();
  const { getItinerary, deleteItineraryItem, reorderItineraryItem, updateItineraryItem, getTransportOptions, updateTransportMode, updatePlanInfo, getPlanById, updateStartTime } = usePlans();

  const planId = params.id;
  const currentPlan = getPlanById(planId);
  const planTitle = currentPlan?.title || params.title || '行程詳情';
  const planDate = currentPlan?.date || '日期未定';
  const planImage = currentPlan?.img || require('../../assets/piggy/pig_login0.png');

  const daysData = getItinerary(planId) || [];
  const [expandedDay, setExpandedDay] = useState('ALL');

  const [settingsVisible, setSettingsVisible] = useState(false);
  const [transportModalVisible, setTransportModalVisible] = useState(false);
  const [planSettingsVisible, setPlanSettingsVisible] = useState(false);
  const [timePickerVisible, setTimePickerVisible] = useState(false);
  
  const [targetDay, setTargetDay] = useState('');
  const [editingItem, setEditingItem] = useState<any>(null);
  const [editingTransport, setEditingTransport] = useState<any>(null);
  const [transportOptions, setTransportOptions] = useState<any[]>([]);
  const [loadingTransport, setLoadingTransport] = useState(false);
  const [editTitle, setEditTitle] = useState(planTitle);
  const [editImage, setEditImage] = useState<any>(null);
  
  const [startDateObj, setStartDateObj] = useState(new Date());
  const [endDateObj, setEndDateObj] = useState(new Date());
  const [showDatePicker, setShowDatePicker] = useState(false);
  const [datePickerMode, setDatePickerMode] = useState<'start' | 'end'>('start');

  const [selectedHour, setSelectedHour] = useState(0);
  const [selectedMinute, setSelectedMinute] = useState(0);
  
  const hoursList = Array.from({ length: 24 }, (_, i) => i);
  const minutesList = Array.from({ length: 12 }, (_, i) => i * 5);
  const hourScrollRef = useRef<NativeScrollView>(null);
  const minuteScrollRef = useRef<NativeScrollView>(null);

  useEffect(() => {
      if (settingsVisible || timePickerVisible) {
          setTimeout(() => {
              hourScrollRef.current?.scrollTo({ y: selectedHour * ITEM_HEIGHT, animated: false });
              minuteScrollRef.current?.scrollTo({ y: (selectedMinute / 5) * ITEM_HEIGHT, animated: false });
          }, 50);
      }
  }, [settingsVisible, timePickerVisible]);

  const isWeb = Platform.OS === 'web';

  const parseDateStr = (str: string) => {
      if(!str) return new Date();
      const parts = str.replace(/-/g, '/').split('/').map(Number);
      if(parts.length === 3) return new Date(parts[0], parts[1]-1, parts[2]);
      return new Date();
  };
  const formatDate = (date: Date) => `${date.getFullYear()}/${(date.getMonth()+1).toString().padStart(2,'0')}/${date.getDate().toString().padStart(2,'0')}`;

  const onDateChange = (event: any, selectedDate?: Date) => {
      if (Platform.OS === 'android') setShowDatePicker(false);
      if (selectedDate) {
          if (datePickerMode === 'start') {
              setStartDateObj(selectedDate);
              if (selectedDate > endDateObj) setEndDateObj(selectedDate);
          } else {
              if (selectedDate < startDateObj) { Alert.alert('錯誤', '結束日期不能早於開始'); setEndDateObj(startDateObj); } 
              else { setEndDateObj(selectedDate); }
          }
      }
  };

  const pickImage = async () => {
    const { status } = await ImagePicker.requestMediaLibraryPermissionsAsync();
    if (status !== 'granted') { Alert.alert('權限不足', '請允許存取相簿'); return; }
    let result = await ImagePicker.launchImageLibraryAsync({ mediaTypes: ImagePicker.MediaTypeOptions.Images, allowsEditing: true, aspect: [16, 9], quality: 1 });
    if (!result.canceled) { setEditImage(result.assets[0].uri); }
  };

  const openPlanSettings = () => {
      setEditTitle(planTitle);
      const parts = planDate.split('~');
      setStartDateObj(parseDateStr(parts[0]));
      setEndDateObj(parseDateStr(parts[1]));
      setEditImage(null); 
      setPlanSettingsVisible(true);
  };

  const handleSavePlanSettings = () => {
      const fullDate = `${formatDate(startDateObj)}~${formatDate(endDateObj)}`;
      updatePlanInfo(planId, editTitle, fullDate, editImage);
      setPlanSettingsVisible(false);
  };

  const openTimePicker = (item: any, index: number, dayKey: string) => {
    if (index !== 0) { Alert.alert("提示", "中間的行程時間是根據停留與交通自動計算的。"); return; }
    let timeStr = item?.time || '09:00';
    let cleanTime = timeStr.replace(/[^0-9:]/g, ''); 
    let [h, m] = cleanTime.split(':').map(Number);
    if (timeStr.includes('下午') && h < 12) h += 12;
    setSelectedHour(h || 9);
    setSelectedMinute(m || 0);
    setEditingItem(item);
    setTargetDay(dayKey);
    setTimePickerVisible(true);
  };

  const handleSaveTime = () => {
      let period = selectedHour < 12 ? '上午' : '下午';
      let displayH = selectedHour > 12 ? selectedHour - 12 : selectedHour;
      if (displayH === 0) displayH = 12;
      let newTimeStr = `${period}${String(displayH).padStart(2, '0')}:${String(selectedMinute).padStart(2, '0')}`;
      updateStartTime(planId, targetDay, newTimeStr);
      setTimePickerVisible(false);
  };

  const openItemSettings = (item: any, dayKey: string) => { 
      setEditingItem(item); 
      setTargetDay(dayKey);
      let h = 0; let m = 0; 
      if (item?.durationValue !== undefined && item?.durationValue !== null) {
          h = Math.floor(item.durationValue / 60);
          m = item.durationValue % 60;
      } else {
          m = 30; // 預設
      }
      setSelectedHour(h); setSelectedMinute(m); 
      setSettingsVisible(true); 
  };
  
  const handleSaveSettings = () => { 
      if(!editingItem) return; 
      let d=''; if(selectedHour>0) d+=`${selectedHour}小時 `; if(selectedMinute>0) d+=`${selectedMinute}分鐘`; if(d==='') d='0分鐘';
      const totalMins = selectedHour * 60 + selectedMinute;
      updateItineraryItem(planId, targetDay, editingItem?.id, { desc: `停留${d}`, durationValue: totalMins }); 
      setSettingsVisible(false); 
  };

  const handleDeleteDirectly = (item: any, dayKey: string) => {
      Alert.alert('刪除景點', `確定要刪除「${item?.title || '此景點'}」嗎？`, [
          { text: '取消', style: 'cancel' },
          { text: '刪除', style: 'destructive', onPress: () => deleteItineraryItem(planId, dayKey, item?.id) }
      ]);
  };

  const openTransportMenu = async (item: any, dayKey: string) => { 
      setEditingTransport(item); 
      setTargetDay(dayKey); 
      setTransportModalVisible(true); setLoadingTransport(true); setTransportOptions([]); 
      const opts = await getTransportOptions(planId, dayKey, item?.id); 
      setTransportOptions(opts); setLoadingTransport(false); 
  };
  
  const handleSelectTransport = (opt: any) => { 
      if(opt?.disabled) return; 
      updateTransportMode(planId, targetDay, editingTransport?.id, opt); 
      setTransportModalVisible(false); 
  };

  const renderRowContent = (item: any, index: number, dayKey: string, drag?: () => void, isActive: boolean = false) => {
      // 🔥 交通圖示美化修復區塊
      if (item?.type === 'transport') {
          let iconName = "car"; 
          if (item?.mode === 'walk') iconName = "walk";
          if (item?.mode === 'transit') iconName = "train";
          if (item?.mode === 'bicycle') iconName = "bicycle";

          return (
              <TouchableOpacity style={styles.transportRow} onPress={() => openTransportMenu(item, dayKey)} disabled={isActive}> 
                  <View style={styles.timeColumn} />
                  <View style={[styles.cardColumn, { flexDirection: 'row', alignItems: 'center' }]}>
                      <View style={{ backgroundColor: '#E0EEF8', padding: 6, borderRadius: 15, marginRight: 8 }}>
                          <Ionicons name={iconName as any} size={16} color="#6CA6CC" />
                      </View>
                      <Text style={styles.transportText}>{item?.text || '點擊設定交通方式'}</Text>
                  </View>
              </TouchableOpacity>
          );
      } 
      
      // 景點卡片區塊
      return (
          <TouchableOpacity activeOpacity={1} onLongPress={drag} disabled={isActive} style={[styles.activityRow, { opacity: isActive ? 0.5 : 1 }]}>
              <TouchableOpacity style={styles.timeColumn} onPress={() => openTimePicker(item, index, dayKey)}>
                  <Text style={styles.timeText}>{item?.time}</Text>
                  {index === 0 && <Ionicons name="create-outline" size={12} color="#999" style={{marginTop:2}} />}
              </TouchableOpacity>
              <View style={styles.cardColumn}>
                  <View style={[styles.card, isActive && {backgroundColor: '#FFEB99'}]}>
                      <View style={{flex: 1}}>
                          <Text style={styles.cardTitle}>{item?.title || '未命名景點'}</Text>
                          <Text style={styles.cardDesc}>{item?.desc}</Text>
                      </View>
                      <View style={styles.actionIcons}>
                          <TouchableOpacity onPress={() => openItemSettings(item, dayKey)} style={{marginRight: 10, padding: 5}}>
                              <Ionicons name="time-outline" size={22} color="#666" /> 
                          </TouchableOpacity>
                          <TouchableOpacity onPress={() => handleDeleteDirectly(item, dayKey)} style={{marginRight: 10, padding: 5}}>
                              <Ionicons name="trash-outline" size={22} color="#FF5555" /> 
                          </TouchableOpacity>
                          {!isWeb && <TouchableOpacity onLongPress={drag} style={{padding: 5}}><MaterialIcons name="drag-handle" size={24} color="#999" /></TouchableOpacity>}
                      </View>
                  </View>
              </View>
          </TouchableOpacity>
      );
  };

  const MainContainer = isWeb ? NativeScrollView : NestableScrollContainer;

  return (
    <View style={styles.container}>
      <View style={styles.header}>
        <TouchableOpacity onPress={() => router.replace('/(tabs)/plan')} style={styles.iconBtn}><Ionicons name="chevron-back" size={28} color="#333" /></TouchableOpacity>
        <Text style={styles.headerTitle}>{planTitle}</Text>
        <View style={styles.headerRight}>
            <TouchableOpacity style={styles.iconBtn} onPress={() => router.push({ pathname: '/group-chat', params: { planId } } as any)}><FontAwesome name="users" size={20} color="#333" /></TouchableOpacity>
            <TouchableOpacity style={styles.iconBtn} onPress={openPlanSettings}><Ionicons name="settings-outline" size={24} color="#333" /></TouchableOpacity>
            <TouchableOpacity style={styles.iconBtn} onPress={() => router.push(`/luggage?planId=${planId}` as any)}>
               <Ionicons name="briefcase-outline" size={22} color="#333" />
            </TouchableOpacity>
        </View>
      </View>

      <View style={styles.tabContainer}>
        <NativeScrollView horizontal showsHorizontalScrollIndicator={false} contentContainerStyle={styles.tabScroll}>
            <TouchableOpacity style={[styles.tabItem, expandedDay === 'ALL' && styles.activeTabItem]} onPress={() => setExpandedDay('ALL')}><Text style={[styles.tabText, expandedDay === 'ALL' && styles.activeTabText]}>總覽</Text></TouchableOpacity>
            {daysData.map((dayItem: any) => (<TouchableOpacity key={dayItem?.day} style={[styles.tabItem, expandedDay === dayItem?.day && styles.activeTabItem]} onPress={() => setExpandedDay(dayItem.day)}><Text style={[styles.tabText, expandedDay === dayItem?.day && styles.activeTabText]}>{dayItem?.day}</Text></TouchableOpacity>))}
        </NativeScrollView>
      </View>

      <MainContainer contentContainerStyle={{paddingBottom: 100}}>
        {daysData.map((dayItem: any) => {
            const shouldShow = expandedDay === 'ALL' || expandedDay === dayItem?.day;
            return (
                <View key={dayItem?.day}>
                    {(shouldShow) && (
                        <TouchableOpacity style={styles.dayHeader} onPress={() => setExpandedDay(dayItem?.day === expandedDay ? 'ALL' : dayItem?.day)}>
                            <Ionicons name={expandedDay === dayItem?.day ? "chevron-down" : "chevron-forward"} size={20} color="#000" />
                            <View style={{marginLeft: 10}}>
                                <Text style={styles.dayTitle}>{dayItem?.day}</Text>
                                <Text style={styles.dateText}>{dayItem?.date}</Text>
                            </View>
                        </TouchableOpacity>
                    )}
                    {shouldShow && (
                        <View style={styles.timelineContainer}>
                            <View style={styles.verticalLine} />
                            {isWeb ? (
                                <View>{dayItem?.items?.map((item: any, index: number) => <View key={item?.id || index}>{renderRowContent(item, index, dayItem.day)}</View>)}</View>
                            ) : (
                                <NestableDraggableFlatList 
                                    data={dayItem?.items || []} 
                                    renderItem={({item, getIndex, drag, isActive}) => <ScaleDecorator>{renderRowContent(item, getIndex() || 0, dayItem?.day, drag, isActive)}</ScaleDecorator>} 
                                    keyExtractor={(item: any) => item?.id || Math.random().toString()} 
                                    onDragEnd={({ data }) => reorderItineraryItem(planId, dayItem?.day, data)} 
                                />
                            )}
                            <View style={styles.addBtnContainer}>
                                <TouchableOpacity style={styles.circleAddBtn} onPress={() => router.push({ pathname: '/add-spot', params: { planId: planId, day: dayItem?.day } } as any)}><FontAwesome name="plus" size={16} color="white" /></TouchableOpacity>
                            </View>
                        </View>
                    )}
                </View>
            );
        })}
      </MainContainer>

      {/* 計畫設定 Modal */}
      <Modal visible={planSettingsVisible} animationType="slide" onRequestClose={() => setPlanSettingsVisible(false)}>
          <View style={styles.fullScreenModal}>
             <View style={styles.modalHeader}><View style={{flex:1}}/><Text style={styles.modalHeaderTitle}>行程設定</Text><TouchableOpacity style={{flex:1, alignItems:'flex-end', paddingRight:20}} onPress={() => setPlanSettingsVisible(false)}><Ionicons name="ellipsis-horizontal" size={24} color="#666" /></TouchableOpacity></View>
             <NativeScrollView contentContainerStyle={{padding: 25}}>
                 <TouchableOpacity style={styles.coverImageContainer} onPress={pickImage}>
                     <Image source={editImage ? { uri: editImage } : planImage} style={editImage ? styles.coverImageSelected : styles.coverImage} resizeMode={editImage ? "cover" : "contain"} /><Text style={styles.changeCoverText}>更換背景</Text>
                 </TouchableOpacity>
                 <View style={styles.formGroup}><Text style={styles.label}>行程名稱 <Text style={{color:'red'}}>*</Text></Text><TextInput style={styles.inputField} value={editTitle} onChangeText={setEditTitle}/></View>
                 <View style={styles.formGroup}>
                     <Text style={styles.label}>行程日期</Text>
                     <View style={styles.dateRow}>
                        <TouchableOpacity style={styles.dateBtn} onPress={() => {setDatePickerMode('start'); setShowDatePicker(true);}}><Text style={styles.pickerDateText}>{formatDate(startDateObj)}</Text></TouchableOpacity>
                        <Text style={{marginHorizontal:10, fontSize:20, color:'#666'}}>~</Text>
                        <TouchableOpacity style={styles.dateBtn} onPress={() => {setDatePickerMode('end'); setShowDatePicker(true);}}><Text style={styles.pickerDateText}>{formatDate(endDateObj)}</Text></TouchableOpacity>
                     </View>
                 </View>
                 <View style={{alignItems:'center', marginTop: 40}}><TouchableOpacity style={styles.savePlanBtn} onPress={handleSavePlanSettings}><Text style={{color:'white', fontSize:18, fontWeight:'bold'}}>儲存設定</Text></TouchableOpacity></View>
             </NativeScrollView>
             {showDatePicker && Platform.OS === 'ios' && (
                <View style={styles.iosAbsoluteOverlay}>
                    <View style={styles.datePickerContainer}>
                        <Text style={styles.datePickerTitle}>{datePickerMode === 'start' ? '選擇開始日期' : '選擇結束日期'}</Text>
                        <DateTimePicker value={datePickerMode === 'start' ? startDateObj : endDateObj} mode="date" display="inline" onChange={onDateChange} style={styles.datePicker} textColor="#000" themeVariant="light" />
                        <TouchableOpacity style={styles.confirmBtn} onPress={() => setShowDatePicker(false)}><Text style={styles.confirmBtnText}>完成</Text></TouchableOpacity>
                    </View>
                </View>
             )}
          </View>
      </Modal>

      {/* 停留時間 Modal */}
      <Modal visible={settingsVisible} transparent={true} animationType="fade" onRequestClose={() => setSettingsVisible(false)}>
         <View style={styles.modalOverlay}>
             <View style={styles.confirmBox}>
                 <TouchableOpacity style={styles.closeBtn} onPress={()=>setSettingsVisible(false)}>
                     <Ionicons name="close" size={24} color="#ccc"/>
                 </TouchableOpacity>
                 <Text style={styles.modalTitle}>設定停留時間</Text>
                 <View style={styles.timePickerContainer}>
                     <View style={styles.selectionLine} pointerEvents="none"/>
                     <View style={styles.pickerColumn}>
                         <Text style={styles.pickerLabel}>時</Text>
                         <NativeScrollView ref={hourScrollRef} style={styles.pickerScroll} snapToInterval={ITEM_HEIGHT} decelerationRate="fast" showsVerticalScrollIndicator={false} contentContainerStyle={{ paddingVertical: PICKER_PADDING }} onMomentumScrollEnd={(e) => setSelectedHour(hoursList[Math.round(e.nativeEvent.contentOffset.y / ITEM_HEIGHT)] || 0)}>
                            {hoursList.map((h) => <View key={h} style={styles.pickerItem}><Text style={[styles.pickerText, selectedHour === h && styles.pickerTextSelected]}>{h}</Text></View>)}
                         </NativeScrollView>
                     </View>
                     <View style={styles.pickerDivider}><Text style={{fontSize: 20, color:'#ddd'}}>:</Text></View>
                     <View style={styles.pickerColumn}>
                         <Text style={styles.pickerLabel}>分</Text>
                         <NativeScrollView ref={minuteScrollRef} style={styles.pickerScroll} snapToInterval={ITEM_HEIGHT} decelerationRate="fast" showsVerticalScrollIndicator={false} contentContainerStyle={{ paddingVertical: PICKER_PADDING }} onMomentumScrollEnd={(e) => setSelectedMinute(minutesList[Math.round(e.nativeEvent.contentOffset.y / ITEM_HEIGHT)] || 0)}>
                            {minutesList.map((m) => <View key={m} style={styles.pickerItem}><Text style={[styles.pickerText, selectedMinute === m && styles.pickerTextSelected]}>{String(m).padStart(2,'0')}</Text></View>)}
                         </NativeScrollView>
                     </View>
                 </View>
                 <TouchableOpacity style={styles.timeConfirmBtn} onPress={handleSaveSettings}>
                     <Text style={{color:'white', fontWeight:'bold', fontSize: 16}}>儲存設定</Text>
                 </TouchableOpacity>
             </View>
         </View>
      </Modal>

      {/* 出發時間 Modal */}
      <Modal visible={timePickerVisible} transparent={true} animationType="fade" onRequestClose={() => setTimePickerVisible(false)}>
         <View style={styles.modalOverlay}>
             <View style={styles.confirmBox}>
                 <TouchableOpacity style={styles.closeBtn} onPress={() => setTimePickerVisible(false)}>
                     <Ionicons name="close" size={24} color="#ccc" />
                 </TouchableOpacity>
                 <Text style={styles.modalTitle}>設定出發時間</Text>
                 <View style={styles.timePickerContainer}>
                     <View style={styles.selectionLine} pointerEvents="none"/>
                     <View style={styles.pickerColumn}>
                         <Text style={styles.pickerLabel}>時</Text>
                         <NativeScrollView ref={hourScrollRef} style={styles.pickerScroll} snapToInterval={ITEM_HEIGHT} decelerationRate="fast" showsVerticalScrollIndicator={false} contentContainerStyle={{ paddingVertical: PICKER_PADDING }} onMomentumScrollEnd={(e) => setSelectedHour(hoursList[Math.round(e.nativeEvent.contentOffset.y / ITEM_HEIGHT)] || 0)}>
                            {hoursList.map((h) => <View key={h} style={styles.pickerItem}><Text style={[styles.pickerText, selectedHour === h && styles.pickerTextSelected]}>{h}</Text></View>)}
                         </NativeScrollView>
                     </View>
                     <View style={styles.pickerDivider}><Text style={{fontSize: 20, color:'#ddd'}}>:</Text></View>
                     <View style={styles.pickerColumn}>
                         <Text style={styles.pickerLabel}>分</Text>
                         <NativeScrollView ref={minuteScrollRef} style={styles.pickerScroll} snapToInterval={ITEM_HEIGHT} decelerationRate="fast" showsVerticalScrollIndicator={false} contentContainerStyle={{ paddingVertical: PICKER_PADDING }} onMomentumScrollEnd={(e) => setSelectedMinute(minutesList[Math.round(e.nativeEvent.contentOffset.y / ITEM_HEIGHT)] || 0)}>
                            {minutesList.map((m) => <View key={m} style={styles.pickerItem}><Text style={[styles.pickerText, selectedMinute === m && styles.pickerTextSelected]}>{String(m).padStart(2,'0')}</Text></View>)}
                         </NativeScrollView>
                     </View>
                 </View>
                 <TouchableOpacity style={styles.timeConfirmBtn} onPress={handleSaveTime}>
                     <Text style={{color:'white', fontWeight:'bold', fontSize: 16}}>確定</Text>
                 </TouchableOpacity>
             </View>
         </View>
      </Modal>

      {/* 交通選單 */}
      <Modal visible={transportModalVisible} transparent={true} animationType="slide" onRequestClose={() => setTransportModalVisible(false)}><View style={styles.modalOverlay}><View style={styles.transportBox}><Text style={styles.modalTitle}>交通</Text>{loadingTransport?<ActivityIndicator/>:transportOptions.map((opt:any)=><TouchableOpacity key={opt.mode} style={styles.transportOption} onPress={()=>handleSelectTransport(opt)}><Text>{opt.icon} {opt.label} {opt.text}</Text></TouchableOpacity>)}<TouchableOpacity style={styles.cancelBtn} onPress={()=>setTransportModalVisible(false)}><Text>取消</Text></TouchableOpacity></View></View></Modal>
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#F2F9FF', paddingTop: 50 },
  header: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', paddingHorizontal: 15, marginBottom: 10 },
  headerTitle: { fontSize: 20, fontWeight: 'bold' },
  headerRight: { flexDirection: 'row', gap: 15 },
  iconBtn: { padding: 5 },
  tabContainer: { paddingLeft: 10, marginBottom: 10 },
  tabScroll: { paddingRight: 20 },
  tabItem: { paddingVertical: 6, paddingHorizontal: 15, marginRight: 5, borderRadius: 20, backgroundColor: 'transparent' },
  activeTabItem: { backgroundColor: '#CAE2F2' },
  tabText: { fontSize: 14, fontWeight: 'bold', color: '#999' },
  activeTabText: { color: '#000' },
  dayHeader: { flexDirection: 'row', alignItems: 'center', marginVertical: 15, paddingHorizontal: 20 },
  dayTitle: { fontSize: 18, fontWeight: 'bold' },
  dateText: { fontSize: 12, color: '#666' },
  timelineContainer: { position: 'relative', paddingLeft: 20, paddingRight: 20 },
  verticalLine: { position: 'absolute', left: 90, top: 0, bottom: 0, width: 2, backgroundColor: '#FF8888', zIndex: -1 },
  activityRow: { flexDirection: 'row', marginBottom: 15, alignItems: 'center' },
  timeColumn: { width: 70, paddingRight: 10, alignItems: 'flex-start' },
  timeText: { fontSize: 12, color: '#333' },
  cardColumn: { flex: 1 },
  card: { backgroundColor: '#CAE2F2', borderRadius: 12, padding: 15, flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between' },
  cardTitle: { fontSize: 16, fontWeight: 'bold', color: '#000' },
  cardDesc: { fontSize: 12, color: '#333', marginTop: 4 },
  actionIcons: { flexDirection: 'row', alignItems: 'center' },
  transportRow: { flexDirection: 'row', marginBottom: 15, alignItems: 'center', height: 40 },
  transportText: { fontSize: 13, color: '#333', fontWeight: 'bold' },
  addBtnContainer: { alignItems: 'center', marginTop: 10, marginBottom: 20 },
  circleAddBtn: { width: 30, height: 30, borderRadius: 15, backgroundColor: '#6CA6CC', justifyContent: 'center', alignItems: 'center' },
  
  modalOverlay: { position: 'absolute', top: 0, left: 0, right: 0, bottom: 0, backgroundColor: 'rgba(0,0,0,0.5)', justifyContent: 'center', alignItems: 'center' },
  iosAbsoluteOverlay: { position: 'absolute', top: 0, left: 0, right: 0, bottom: 0, backgroundColor: 'rgba(0,0,0,0.5)', justifyContent: 'center', alignItems: 'center', zIndex: 1000 },
  datePickerContainer: { width: '90%', backgroundColor: 'white', borderRadius: 20, padding: 20, alignItems: 'center', elevation: 5 },
  datePickerTitle: { fontSize: 18, fontWeight: 'bold', marginBottom: 15, color: '#333' },
  datePicker: { width: '100%', height: 320 }, 
  confirmBtn: { marginTop: 15, backgroundColor: '#6CA6CC', paddingVertical: 10, paddingHorizontal: 30, borderRadius: 20 },
  confirmBtnText: { color: 'white', fontSize: 16, fontWeight: 'bold' },
  
  confirmBox: { width: '85%', backgroundColor: 'white', borderRadius: 20, padding: 25, alignItems: 'center', elevation: 10, position: 'relative' },
  closeBtn: { position: 'absolute', top: 15, right: 15, zIndex: 10, padding: 5 },
  modalTitle: { fontSize: 18, fontWeight: 'bold', marginBottom: 20 },
  
  timePickerContainer: { flexDirection: 'row', width: '100%', height: PICKER_HEIGHT, backgroundColor: '#F9F9F9', borderRadius: 15, marginBottom: 20, position: 'relative', overflow: 'hidden' },
  selectionLine: { position: 'absolute', top: PICKER_PADDING, left: 0, right: 0, height: ITEM_HEIGHT, backgroundColor: '#EAF6FF', borderColor: '#6CA6CC', borderTopWidth: 1, borderBottomWidth: 1, zIndex: 0 },
  pickerColumn: { flex: 1, alignItems: 'center', height: '100%', zIndex: 1 },
  pickerScroll: { width: '100%' },
  pickerLabel: { fontSize: 12, color: '#999', position: 'absolute', top: 5, zIndex: 2 },
  pickerItem: { height: ITEM_HEIGHT, justifyContent: 'center', alignItems: 'center', width: '100%' },
  pickerText: { fontSize: 18, color: '#ccc' },
  pickerTextSelected: { fontSize: 22, fontWeight: 'bold', color: '#6CA6CC' },
  pickerDivider: { justifyContent: 'center', paddingBottom: 10, zIndex: 1 },
  
  timeConfirmBtn: { width: '100%', backgroundColor: '#6CA6CC', padding: 15, borderRadius: 12, alignItems: 'center', justifyContent: 'center' },
  
  transportBox: { width: '90%', backgroundColor: 'white', borderRadius: 20, padding: 20, paddingBottom: 30, alignItems: 'center', elevation: 10 },
  transportOption: { flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', width: '100%', paddingVertical: 15, borderBottomWidth: 1, borderBottomColor: '#eee' },
  cancelBtn: { marginTop: 20, padding: 10 },
  fullScreenModal: { flex: 1, backgroundColor: '#fff', marginTop: 40, position: 'relative' },
  modalHeader: { flexDirection: 'row', alignItems: 'center', justifyContent: 'center', padding: 15, marginBottom: 10 },
  modalHeaderTitle: { fontSize: 20, fontWeight: 'bold', color:'#333' },
  coverImageContainer: { width: '100%', height: 180, backgroundColor: '#CAE2F2', borderRadius: 20, justifyContent: 'center', alignItems: 'center', marginBottom: 30, overflow:'hidden' },
  coverImage: { width: 100, height: 100, opacity: 0.6 },
  coverImageSelected: { width: '100%', height: '100%' },
  changeCoverText: { marginTop: 10, color: '#555', fontWeight: 'bold', fontSize: 14, position: 'absolute', bottom: 10 },
  formGroup: { marginBottom: 25 },
  label: { fontSize: 16, fontWeight: 'bold', marginBottom: 10, color: '#222' },
  inputField: { backgroundColor: '#EAEAEA', padding: 15, borderRadius: 12, fontSize: 16, color: '#333' },
  dateRow: { flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between' },
  dateBtn: { flex: 1, backgroundColor: '#EAEAEA', padding: 15, borderRadius: 12, alignItems: 'center' },
  pickerDateText: { fontSize: 16, color: '#333', fontWeight: 'bold' },
  savePlanBtn: { backgroundColor: '#666', paddingVertical: 15, paddingHorizontal: 80, borderRadius: 30, alignItems: 'center', elevation: 3 }
});