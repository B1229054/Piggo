// app/(tabs)/new-plan.tsx
import { Ionicons } from '@expo/vector-icons';
import DateTimePicker from '@react-native-community/datetimepicker';
import * as ImagePicker from 'expo-image-picker';
import { useRouter } from 'expo-router';
import React, { useState } from 'react';
import { Alert, Image, Modal, Platform, ScrollView, StyleSheet, Text, TextInput, TouchableOpacity, View } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';

// 引用上一層的 Context
import { usePlans } from '../../components/PlanContext';

export default function NewPlanScreen() {
  const router = useRouter();
  const { addPlan } = usePlans();

  const [newTitle, setNewTitle] = useState('');
  const [newImage, setNewImage] = useState<any>(null);

  // --- 日期相關狀態 ---
  const today = new Date();
  const tomorrow = new Date(today);
  tomorrow.setDate(tomorrow.getDate() + 1);

  const [startDateObj, setStartDateObj] = useState(today);
  const [endDateObj, setEndDateObj] = useState(tomorrow);
  
  // 控制 Picker 顯示 (是否彈出)
  const [showPicker, setShowPicker] = useState(false);
  const [pickerMode, setPickerMode] = useState<'start' | 'end'>('start');

  const formatDate = (date: Date) => {
      return `${date.getFullYear()}/${(date.getMonth() + 1).toString().padStart(2, '0')}/${date.getDate().toString().padStart(2, '0')}`;
  };

  const onDateChange = (event: any, selectedDate?: Date) => {
      // Android: 選完會自動關閉
      if (Platform.OS === 'android') {
          setShowPicker(false);
      }
      
      if (selectedDate) {
          if (pickerMode === 'start') {
              setStartDateObj(selectedDate);
              // 如果開始時間晚於結束時間，自動推移結束時間
              if (selectedDate > endDateObj) setEndDateObj(selectedDate);
          } else {
              if (selectedDate < startDateObj) {
                  Alert.alert('日期錯誤', '結束日期不能早於開始日期');
                  setEndDateObj(startDateObj);
              } else {
                  setEndDateObj(selectedDate);
              }
          }
      }
  };

  const showDatepicker = (mode: 'start' | 'end') => {
      setPickerMode(mode);
      setShowPicker(true);
  };

  const pickImage = async () => {
    const { status } = await ImagePicker.requestMediaLibraryPermissionsAsync();
    if (status !== 'granted') { Alert.alert('權限不足', '請允許存取相簿'); return; }
    let result = await ImagePicker.launchImageLibraryAsync({ mediaTypes: ImagePicker.MediaTypeOptions.Images, allowsEditing: true, aspect: [16, 9], quality: 1 });
    if (!result.canceled) { setNewImage(result.assets[0].uri); }
  };

  const handleConfirm = () => {
    if (!newTitle) { Alert.alert("提示", "請輸入行程名稱"); return; }
    const fullDate = `${formatDate(startDateObj)}~${formatDate(endDateObj)}`;
    const newPlan = { id: Date.now().toString(), title: newTitle, date: fullDate, members: 1 };
    addPlan(newPlan, newImage);
    router.back();
  };

  return (
    <SafeAreaView style={styles.container} edges={['top']}>
      <View style={styles.header}>
         <TouchableOpacity onPress={() => router.back()} style={{padding: 10}}>
             <Ionicons name="close" size={28} color="transparent" /> 
         </TouchableOpacity>
         <Text style={styles.headerTitle}>新增新計畫</Text>
         <TouchableOpacity onPress={() => router.back()} style={{padding: 10}}>
             <Ionicons name="close" size={28} color="#333" />
         </TouchableOpacity>
      </View>

      <ScrollView contentContainerStyle={{padding: 25}}>
         <TouchableOpacity style={styles.coverImageContainer} onPress={pickImage}>
             <Image source={newImage ? { uri: newImage } : require('../../assets/piggy/pig_login0.png')} style={newImage ? styles.coverImageSelected : styles.coverImage} resizeMode={newImage ? "cover" : "contain"} />
             <Text style={styles.changeCoverText}>更換背景</Text>
         </TouchableOpacity>

         <View style={styles.formGroup}><Text style={styles.label}>行程名稱 <Text style={{color:'red'}}>*</Text></Text><TextInput style={styles.inputField} value={newTitle} onChangeText={setNewTitle} placeholder="輸入名稱" /></View>

         {/* 🔥 改成按鈕觸發 Modal */}
         <View style={styles.formGroup}>
             <Text style={styles.label}>行程日期</Text>
             <View style={styles.dateRow}>
                <TouchableOpacity style={styles.dateBtn} onPress={() => showDatepicker('start')}>
                    <Text style={styles.dateText}>{formatDate(startDateObj)}</Text>
                </TouchableOpacity>
                
                <Text style={{marginHorizontal:10, fontSize:20, color:'#666'}}>~</Text>
                
                <TouchableOpacity style={styles.dateBtn} onPress={() => showDatepicker('end')}>
                    <Text style={styles.dateText}>{formatDate(endDateObj)}</Text>
                </TouchableOpacity>
             </View>
         </View>

         <View style={styles.formGroup}><Text style={styles.label}>目的地</Text><TouchableOpacity style={styles.addDestBtn}><Ionicons name="add-circle" size={22} color="#6CA6CC" /><Text style={{color:'#333', fontWeight:'bold', marginLeft:8, fontSize:16}}>新增目的地</Text></TouchableOpacity></View>
         <TouchableOpacity style={styles.inviteBtn}><Ionicons name="mail-outline" size={22} color="#555" /><Text style={{fontWeight:'bold', marginLeft:10, color:'#555', fontSize:16}}>邀請 Piggo 帳戶</Text></TouchableOpacity>

         <View style={{alignItems:'center', marginTop: 40}}>
            <TouchableOpacity style={styles.savePlanBtn} onPress={handleConfirm}>
                <Text style={{color:'white', fontSize:18, fontWeight:'bold'}}>確定行程</Text>
            </TouchableOpacity>
         </View>

         {/* 🔥🔥🔥 Android 原生日期選擇器 (它自己就是 Modal，不用包) */}
         {showPicker && Platform.OS === 'android' && (
             <DateTimePicker
                 value={pickerMode === 'start' ? startDateObj : endDateObj}
                 mode="date"
                 display="default"
                 onChange={onDateChange}
             />
         )}

      </ScrollView>

      {}
      {Platform.OS === 'ios' && (
        <Modal visible={showPicker} transparent animationType="fade">
            <View style={styles.modalOverlay}>
                <View style={styles.datePickerContainer}>
                    <Text style={styles.datePickerTitle}>
                        {pickerMode === 'start' ? '選擇開始日期' : '選擇結束日期'}
                    </Text>
                    
                    {/* 月曆本體 */}
                    <DateTimePicker
                        value={pickerMode === 'start' ? startDateObj : endDateObj}
                        mode="date"
                        display="inline" // 🔥 重點：這會變成漂亮的月曆
                        onChange={onDateChange}
                        style={styles.datePicker}
                        textColor="#000"
                        themeVariant="light" 
                    />
                    
                    {/* 完成按鈕 */}
                    <TouchableOpacity style={styles.confirmBtn} onPress={() => setShowPicker(false)}>
                        <Text style={styles.confirmBtnText}>完成</Text>
                    </TouchableOpacity>
                </View>
            </View>
        </Modal>
      )}

    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#fff' },
  header: { flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', paddingHorizontal: 10, marginBottom: 10 },
  headerTitle: { fontSize: 20, fontWeight: 'bold', color:'#333' },
  coverImageContainer: { width: '100%', height: 180, backgroundColor: '#CAE2F2', borderRadius: 20, justifyContent: 'center', alignItems: 'center', marginBottom: 30, overflow:'hidden' },
  coverImage: { width: 100, height: 100, opacity: 0.6 },
  coverImageSelected: { width: '100%', height: '100%' },
  changeCoverText: { marginTop: 10, color: '#555', fontWeight: 'bold', fontSize: 14, position: 'absolute', bottom: 10 },
  formGroup: { marginBottom: 25 },
  label: { fontSize: 16, fontWeight: 'bold', marginBottom: 10, color: '#222' },
  inputField: { backgroundColor: '#EAEAEA', padding: 15, borderRadius: 12, fontSize: 16, color: '#333' },
  
  // 按鈕樣式
  dateRow: { flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between' },
  dateBtn: { flex: 1, backgroundColor: '#EAEAEA', padding: 15, borderRadius: 12, alignItems: 'center' },
  dateText: { fontSize: 16, color: '#333', fontWeight: 'bold' },
  addDestBtn: { backgroundColor: '#EAEAEA', padding: 15, borderRadius: 12, alignItems: 'center', flexDirection: 'row', justifyContent: 'center' },
  inviteBtn: { backgroundColor: '#EAEAEA', padding: 15, borderRadius: 12, alignItems: 'center', flexDirection: 'row', justifyContent: 'center', marginBottom: 20 },
  savePlanBtn: { backgroundColor: '#666', paddingVertical: 15, paddingHorizontal: 80, borderRadius: 30, alignItems: 'center', elevation: 3 },

  
  modalOverlay: { flex: 1, backgroundColor: 'rgba(0,0,0,0.5)', justifyContent: 'center', alignItems: 'center' },
  datePickerContainer: { width: '90%', backgroundColor: 'white', borderRadius: 20, padding: 20, alignItems: 'center', elevation: 5 },
  datePickerTitle: { fontSize: 18, fontWeight: 'bold', marginBottom: 15, color: '#333' },
  datePicker: { width: '100%', height: 320 }, 
  confirmBtn: { marginTop: 15, backgroundColor: '#6CA6CC', paddingVertical: 10, paddingHorizontal: 30, borderRadius: 20 },
  confirmBtnText: { color: 'white', fontSize: 16, fontWeight: 'bold' }
});