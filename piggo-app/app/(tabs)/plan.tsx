// app/(tabs)/plan.tsx
import { Ionicons, MaterialCommunityIcons } from '@expo/vector-icons';
import { useRouter } from 'expo-router';
import React, { useState } from 'react';
import { Image, ScrollView, StyleSheet, Text, TouchableOpacity, View, Modal, TextInput, Alert, Platform } from 'react-native';
import * as ImagePicker from 'expo-image-picker';
import DateTimePicker from '@react-native-community/datetimepicker';
import { usePlans } from '../../components/PlanContext';

export default function PlanScreen() {
  const router = useRouter();
  const { plans, updatePlanInfo, deletePlan } = usePlans();

  const [settingsModalVisible, setSettingsModalVisible] = useState(false);
  const [menuVisible, setMenuVisible] = useState(false);
  const [targetPlan, setTargetPlan] = useState<any>(null);

  const [editTitle, setEditTitle] = useState('');
  const [editImage, setEditImage] = useState<any>(null);
  const [previewImage, setPreviewImage] = useState<any>(null);

  // 日期狀態
  const [startDateObj, setStartDateObj] = useState(new Date());
  const [endDateObj, setEndDateObj] = useState(new Date());
  const [showDatePicker, setShowDatePicker] = useState(false);
  const [datePickerMode, setDatePickerMode] = useState<'start' | 'end'>('start');

  const parseDateStr = (str: string) => {
      if(!str) return new Date();
      const parts = str.replace(/-/g, '/').split('/').map(Number);
      if(parts.length === 3) return new Date(parts[0], parts[1]-1, parts[2]);
      return new Date();
  };
  const formatDate = (date: Date) => `${date.getFullYear()}/${(date.getMonth()+1).toString().padStart(2,'0')}/${date.getDate().toString().padStart(2,'0')}`;

  const handleOpenMenu = (plan: any) => { setTargetPlan(plan); setMenuVisible(true); };
  const handleShare = () => { setMenuVisible(false); Alert.alert("分享", "已分享行程至推薦版！(模擬)"); };
  const handleDelete = () => {
      setMenuVisible(false);
      Alert.alert("刪除行程", `確定要刪除「${targetPlan?.title}」嗎？`, [
          { text: "取消", style: "cancel" },
          { text: "刪除", style: "destructive", onPress: () => { if (targetPlan) deletePlan(targetPlan.id); } }
      ]);
  };

  const handleOpenSettings = () => {
      setMenuVisible(false);
      if (!targetPlan) return;
      setEditTitle(targetPlan.title);
      const parts = (targetPlan.date || '').split('~');
      setStartDateObj(parseDateStr(parts[0]));
      setEndDateObj(parseDateStr(parts[1]));
      setPreviewImage(targetPlan.img); 
      setEditImage(null); 
      setSettingsModalVisible(true);
  };

  const handleSaveSettings = () => {
      if (targetPlan) {
          const fullDate = `${formatDate(startDateObj)}~${formatDate(endDateObj)}`;
          updatePlanInfo(targetPlan.id, editTitle, fullDate, editImage);
          setSettingsModalVisible(false);
          Alert.alert("成功", "計畫已更新！");
      }
  };

  const showDatepicker = (mode: 'start' | 'end') => {
      setDatePickerMode(mode);
      setShowDatePicker(true);
  };

  const onDateChange = (event: any, selectedDate?: Date) => {
      if (Platform.OS === 'android') setShowDatePicker(false);
      if (selectedDate) {
          if (datePickerMode === 'start') {
              setStartDateObj(selectedDate);
              if (selectedDate > endDateObj) setEndDateObj(selectedDate);
          } else {
              if (selectedDate < startDateObj) {
                  Alert.alert('錯誤', '結束日期不能早於開始');
                  setEndDateObj(startDateObj);
              } else {
                  setEndDateObj(selectedDate);
              }
          }
      }
  };

  const pickImage = async () => {
    const { status } = await ImagePicker.requestMediaLibraryPermissionsAsync();
    if (status !== 'granted') { Alert.alert('權限不足', '請允許存取相簿'); return; }
    let result = await ImagePicker.launchImageLibraryAsync({ mediaTypes: ImagePicker.MediaTypeOptions.Images, allowsEditing: true, aspect: [16, 9], quality: 1 });
    if (!result.canceled) { setEditImage(result.assets[0].uri); setPreviewImage({ uri: result.assets[0].uri }); }
  };

  return (
    <View style={styles.container}>
      <View style={styles.headerContainer}>
          <Text style={styles.headerTitle}>計畫</Text>
          <Image source={require('../../assets/piggy/pig_login0.png')} style={styles.headerIcon} resizeMode="contain" />
      </View>

      <View style={styles.actionRow}>
          <View>
              <Text style={styles.sectionTitle}>我的計畫</Text>
              <View style={styles.sortRow}>
                  <MaterialCommunityIcons name="arrow-up-down" size={16} color="#333" />
                  <Text style={styles.sortText}> 上次編輯的時間</Text>
              </View>
          </View>
          <TouchableOpacity style={styles.addPlanBtn} onPress={() => router.push('/new-plan')}>
              <Ionicons name="add" size={20} color="white" />
              <Text style={styles.addPlanText}>新增新計畫</Text>
          </TouchableOpacity>
      </View>

      <ScrollView contentContainerStyle={styles.scrollContent}>
        {(plans || []).map((plan: any) => (
          <TouchableOpacity 
            key={plan.id} 
            style={styles.cardContainer} 
            onPress={() => router.push({ pathname: '/(tabs)/itinerary', params: { id: plan.id, title: plan.title } })}
            activeOpacity={0.9}
          >
            <View style={styles.cardImageArea}>
                <Image source={plan.img || require('../../assets/piggy/pig_login0.png')} style={styles.cardImage} resizeMode="cover" />
                <View style={styles.cardStickers}>
                    {Array.from({ length: Math.min(plan.members || 1, 5) }).map((_, i) => (
                        <Image key={i} source={require('../../assets/piggy/pig_login0.png')} style={[styles.sticker, { zIndex: 10 - i }]} />
                    ))}
                    {(plan.members > 5) && <View style={[styles.sticker, { backgroundColor: '#ddd', alignItems:'center', justifyContent:'center' }]}><Text style={{fontSize:10}}>+{plan.members - 5}</Text></View>}
                </View>
            </View>

            <View style={styles.cardInfoArea}>
                <View style={styles.textGroup}>
                    <Text style={styles.planTitle}>{plan.title}</Text>
                    <Text style={styles.planDate}>{plan.date}</Text>
                </View>
                <View style={styles.iconGroup}>
                    <TouchableOpacity style={styles.iconBtn} onPress={() => router.push({ pathname: '/group-chat', params: { planId: plan.id } })}>
                        <Ionicons name="chatbubble-outline" size={20} color="#333" />
                    </TouchableOpacity>
                    <TouchableOpacity style={styles.iconBtn} onPress={() => Alert.alert("成員", "這裡可以管理成員")}>
                        <Ionicons name="person-add-outline" size={20} color="#333" />
                    </TouchableOpacity>
                    <TouchableOpacity style={styles.iconBtn} onPress={() => handleOpenMenu(plan)}>
                        <Ionicons name="ellipsis-horizontal" size={20} color="#333" />
                    </TouchableOpacity>
                </View>
            </View>
          </TouchableOpacity>
        ))}
      </ScrollView>

      <View style={styles.bottomDecor}>
          <View style={styles.speechBubble}><Text style={styles.speechText}>提供日期、地點，讓我為您安排整個行程嗎？</Text></View>
          <TouchableOpacity style={styles.floatingPigBtn}><Image source={require('../../assets/piggy/pig_login0.png')} style={styles.pigIcon} resizeMode="contain" /></TouchableOpacity>
      </View>

      {/* Modal 1: 底部選單 */}
      <Modal visible={menuVisible} transparent={true} animationType="fade" onRequestClose={() => setMenuVisible(false)}>
          <TouchableOpacity style={styles.menuOverlay} activeOpacity={1} onPress={() => setMenuVisible(false)}>
              <View style={styles.menuContainer} onStartShouldSetResponder={() => true}>
                  <View style={styles.menuHandle} />
                  <TouchableOpacity style={styles.menuItem} onPress={handleShare}>
                      <Ionicons name="share-social-outline" size={24} color="#333" />
                      <Text style={styles.menuText}>分享行程至推薦版</Text>
                  </TouchableOpacity>
                  <TouchableOpacity style={styles.menuItem} onPress={handleDelete}>
                      <Ionicons name="trash-outline" size={24} color="#FF5555" />
                      <Text style={[styles.menuText, { color: '#FF5555' }]}>刪除行程</Text>
                  </TouchableOpacity>
                  <TouchableOpacity style={[styles.menuItem, { borderBottomWidth: 0 }]} onPress={handleOpenSettings}>
                      <Ionicons name="settings-outline" size={24} color="#333" />
                      <Text style={styles.menuText}>行程設定</Text>
                  </TouchableOpacity>
              </View>
          </TouchableOpacity>
      </Modal>

      {/* Modal 2: 設定視窗 (日期選擇器已整合在內) */}
      <Modal visible={settingsModalVisible} animationType="slide" onRequestClose={() => setSettingsModalVisible(false)}>
          <View style={styles.fullScreenModal}>
             <View style={styles.modalHeader}>
                 <View style={{flex:1}} />
                 <Text style={styles.modalHeaderTitle}>行程設定</Text>
                 <TouchableOpacity style={{flex:1, alignItems:'flex-end', paddingRight:20}} onPress={() => setSettingsModalVisible(false)}>
                     <Ionicons name="close" size={28} color="#666" />
                 </TouchableOpacity>
             </View>

             <ScrollView contentContainerStyle={{padding: 25}}>
                 <TouchableOpacity style={styles.coverImageContainer} onPress={pickImage}>
                     <Image source={previewImage || require('../../assets/piggy/pig_login0.png')} style={editImage ? styles.coverImageSelected : styles.coverImage} resizeMode={editImage ? "cover" : "contain"} />
                     <Text style={styles.changeCoverText}>更換背景</Text>
                 </TouchableOpacity>

                 <View style={styles.formGroup}><Text style={styles.label}>行程名稱 <Text style={{color:'red'}}>*</Text></Text><TextInput style={styles.inputField} value={editTitle} onChangeText={setEditTitle}/></View>
                 
                 <View style={styles.formGroup}>
                     <Text style={styles.label}>行程日期</Text>
                     <View style={styles.dateRow}>
                        <TouchableOpacity style={styles.dateBtn} onPress={() => showDatepicker('start')}><Text style={styles.pickerDateText}>{formatDate(startDateObj)}</Text></TouchableOpacity>
                        <Text style={{marginHorizontal:10, fontSize:20, color:'#666'}}>~</Text>
                        <TouchableOpacity style={styles.dateBtn} onPress={() => showDatepicker('end')}><Text style={styles.pickerDateText}>{formatDate(endDateObj)}</Text></TouchableOpacity>
                     </View>
                 </View>

                 <View style={styles.formGroup}><Text style={styles.label}>目的地</Text><TouchableOpacity style={styles.addDestBtn}><Ionicons name="add-circle" size={22} color="#6CA6CC" /><Text style={{color:'#333', fontWeight:'bold', marginLeft:8, fontSize:16}}>新增目的地</Text></TouchableOpacity></View>
                 <TouchableOpacity style={styles.inviteBtn} onPress={() => Alert.alert("邀請", "連結已複製！")}>
                     <Ionicons name="mail-outline" size={22} color="#555" />
                     <Text style={{fontWeight:'bold', marginLeft:10, color:'#555', fontSize:16}}>邀請 Piggo 帳戶</Text>
                 </TouchableOpacity>
                 <View style={{alignItems:'center', marginTop: 40}}>
                    <TouchableOpacity style={styles.savePlanBtn} onPress={handleSaveSettings}>
                        <Text style={{color:'white', fontSize:18, fontWeight:'bold'}}>儲存設定</Text>
                    </TouchableOpacity>
                 </View>

                 {/* Android Picker */}
                 {showDatePicker && Platform.OS === 'android' && (<DateTimePicker value={datePickerMode === 'start' ? startDateObj : endDateObj} mode="date" display="default" onChange={onDateChange} />)}
             </ScrollView>

             {/* 🔥🔥🔥 iOS 偽彈窗 (直接放在 Modal 裡面，使用絕對定位覆蓋) */}
             {showDatePicker && Platform.OS === 'ios' && (
                <View style={styles.iosAbsoluteOverlay}>
                    <View style={styles.datePickerContainer}>
                        <Text style={styles.datePickerTitle}>
                            {datePickerMode === 'start' ? '選擇開始日期' : '選擇結束日期'}
                        </Text>
                        <DateTimePicker
                            value={datePickerMode === 'start' ? startDateObj : endDateObj}
                            mode="date"
                            display="inline" 
                            onChange={onDateChange}
                            style={styles.datePicker}
                            textColor="#000"
                            themeVariant="light"
                        />
                        <TouchableOpacity style={styles.confirmBtn} onPress={() => setShowDatePicker(false)}>
                            <Text style={styles.confirmBtnText}>完成</Text>
                        </TouchableOpacity>
                    </View>
                </View>
             )}
          </View>
      </Modal>
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#DDF0FF', paddingTop: 50 },
  headerContainer: { alignItems: 'center', marginBottom: 20, position: 'relative' },
  headerTitle: { fontSize: 22, fontWeight: 'bold', color: '#000' },
  headerIcon: { width: 30, height: 30, position: 'absolute', right: 20, top: 0 },
  actionRow: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', paddingHorizontal: 20, marginBottom: 15 },
  sectionTitle: { fontSize: 24, fontWeight: 'bold', color: '#000' },
  sortRow: { flexDirection: 'row', alignItems: 'center', marginTop: 5 },
  sortText: { fontSize: 14, fontWeight: 'bold', color: '#333' },
  addPlanBtn: { flexDirection: 'row', backgroundColor: '#555', paddingVertical: 10, paddingHorizontal: 20, borderRadius: 25, alignItems: 'center' },
  addPlanText: { color: 'white', fontWeight: 'bold', marginLeft: 5 },
  scrollContent: { paddingHorizontal: 20, paddingBottom: 120 },
  
  cardContainer: { borderRadius: 20, overflow: 'hidden', marginBottom: 20, elevation: 5, backgroundColor: 'transparent' },
  cardImageArea: { height: 140, width: '100%', backgroundColor: '#CBE8FF', position: 'relative' },
  cardImage: { width: '100%', height: '100%', resizeMode: 'cover', opacity: 0.9 },
  cardStickers: { position: 'absolute', bottom: 10, left: 15, flexDirection: 'row' },
  sticker: { width: 25, height: 25, marginRight: -8, borderRadius: 12.5, backgroundColor: '#fff' },
  cardInfoArea: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', backgroundColor: '#6CA6CC', padding: 15, height: 70 },
  textGroup: { flex: 1 },
  planTitle: { fontSize: 20, fontWeight: 'bold', color: '#000' },
  planDate: { fontSize: 12, color: '#333', marginTop: 2 },
  iconGroup: { flexDirection: 'row', gap: 10 },
  iconBtn: { width: 36, height: 36, borderRadius: 18, backgroundColor: 'rgba(255,255,255,0.6)', justifyContent: 'center', alignItems: 'center' },
  bottomDecor: { position: 'absolute', bottom: 90, right: 20, flexDirection: 'row', alignItems: 'flex-end' },
  speechBubble: { backgroundColor: 'white', padding: 12, borderRadius: 15, marginRight: 10, marginBottom: 15, borderBottomRightRadius: 0, elevation: 3, maxWidth: 200 },
  speechText: { fontSize: 12, fontWeight: 'bold', color: '#333' },
  floatingPigBtn: { width: 60, height: 60, borderRadius: 30, backgroundColor: '#5A8EAD', justifyContent: 'center', alignItems: 'center', elevation: 5 },
  pigIcon: { width: 35, height: 35, tintColor: 'white' },
  
  menuOverlay: { flex: 1, backgroundColor: 'rgba(0,0,0,0.5)', justifyContent: 'flex-end' },
  menuContainer: { width: '100%', backgroundColor: 'white', borderTopLeftRadius: 20, borderTopRightRadius: 20, paddingHorizontal: 20, paddingTop: 10, paddingBottom: 40 },
  menuHandle: { width: 40, height: 5, backgroundColor: '#ddd', borderRadius: 3, alignSelf: 'center', marginVertical: 10 },
  menuItem: { flexDirection: 'row', alignItems: 'center', paddingVertical: 18, borderBottomWidth: 1, borderBottomColor: '#f0f0f0' },
  menuText: { fontSize: 18, marginLeft: 15, color: '#333', fontWeight: '500' },

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
  addDestBtn: { backgroundColor: '#EAEAEA', padding: 15, borderRadius: 12, alignItems: 'center', flexDirection: 'row', justifyContent: 'center' },
  inviteBtn: { backgroundColor: '#EAEAEA', padding: 15, borderRadius: 12, alignItems: 'center', flexDirection: 'row', justifyContent: 'center', marginBottom: 20 },
  savePlanBtn: { backgroundColor: '#666', paddingVertical: 15, paddingHorizontal: 80, borderRadius: 30, alignItems: 'center', elevation: 3 },
  
  // 🔥🔥🔥 iOS 偽彈窗樣式 (Absolute Overlay)
  iosAbsoluteOverlay: { position: 'absolute', top: 0, left: 0, right: 0, bottom: 0, backgroundColor: 'rgba(0,0,0,0.5)', justifyContent: 'center', alignItems: 'center', zIndex: 1000 },
  datePickerContainer: { width: '90%', backgroundColor: 'white', borderRadius: 20, padding: 20, alignItems: 'center', elevation: 5 },
  datePickerTitle: { fontSize: 18, fontWeight: 'bold', marginBottom: 15, color: '#333' },
  datePicker: { width: '100%', height: 320 }, 
  confirmBtn: { marginTop: 15, backgroundColor: '#6CA6CC', paddingVertical: 10, paddingHorizontal: 30, borderRadius: 20 },
  confirmBtnText: { color: 'white', fontSize: 16, fontWeight: 'bold' }
});