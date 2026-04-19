// app/add-spot.tsx
import { Ionicons } from '@expo/vector-icons';
import { useLocalSearchParams, useRouter } from 'expo-router';
import React, { useEffect, useRef, useState } from 'react';
import { ActivityIndicator, Dimensions, FlatList, Keyboard, Modal, ScrollView as NativeScrollView, StyleSheet, Text, TextInput, TouchableOpacity, View } from 'react-native';
import MapView, { Marker, Polyline, PROVIDER_GOOGLE } from 'react-native-maps';
import { SafeAreaView } from 'react-native-safe-area-context';
import { usePlans } from '../components/PlanContext';

const { width } = Dimensions.get('window');
const CARD_WIDTH = width * 0.85; 
const SPACING = (width - CARD_WIDTH) / 2;

const ITEM_HEIGHT = 50; 
const PICKER_PADDING = 50; 
const PICKER_HEIGHT = 150; 

export default function AddSpotScreen() {
  const router = useRouter();
  const params: any = useLocalSearchParams();
  const { planId, day } = params;
  
  const { addItineraryItem, searchGooglePlaces, getPlaceDetails, getItinerary, reverseGeocodeGoogle } = usePlans();
  const mapRef = useRef<MapView>(null);

  const itinerary = getItinerary(planId) || [];
  const dayData = itinerary.find((d: any) => d?.day === day);
  const existingActivities = dayData ? dayData.items.filter((i: any) => i && i.type === 'activity') : [];

  const [query, setQuery] = useState('');
  const [results, setResults] = useState<any[]>([]);
  const [isSearching, setIsSearching] = useState(false);
  const [loading, setLoading] = useState(false);
  const [selectedLocation, setSelectedLocation] = useState<any>(null); 
  
  const [region, setRegion] = useState(() => {
      if (existingActivities.length > 0) {
          const lastSpot = existingActivities[existingActivities.length - 1];
          const lat = lastSpot?.coordinate?.lat || lastSpot?.coordinate?.latitude;
          const lng = lastSpot?.coordinate?.lng || lastSpot?.coordinate?.longitude;
          if (lat && lng) {
              return { latitude: lat, longitude: lng, latitudeDelta: 0.02, longitudeDelta: 0.02 };
          }
      }
      return { latitude: 25.0330, longitude: 121.5654, latitudeDelta: 0.05, longitudeDelta: 0.05 };
  });

  const [insertionOptions, setInsertionOptions] = useState<any[]>([]);
  const [selectedInsertIndex, setSelectedInsertIndex] = useState(-1);

  const [showTimeModal, setShowTimeModal] = useState(false);
  const [stayHour, setStayHour] = useState(0); 
  const [stayMinute, setStayMinute] = useState(30); 
  
  const hoursList = Array.from({ length: 24 }, (_, i) => i);
  const minutesList = Array.from({ length: 12 }, (_, i) => i * 5);
  const hourScrollRef = useRef<NativeScrollView>(null);
  const minuteScrollRef = useRef<NativeScrollView>(null);

  const isPoiClicked = useRef(false);

  useEffect(() => {
      if (showTimeModal) {
          setTimeout(() => {
              hourScrollRef.current?.scrollTo({ y: stayHour * ITEM_HEIGHT, animated: false });
              minuteScrollRef.current?.scrollTo({ y: (stayMinute / 5) * ITEM_HEIGHT, animated: false });
          }, 50);
      }
  }, [showTimeModal]);

  useEffect(() => {
      if (selectedLocation) {
          const options = [];
          existingActivities.forEach((item: any, index: number) => {
              if (item) options.push({ type: 'insert_after', targetIndex: index, prevItem: item, label: `插在 ${item?.title || '此景點'} 之後` });
          });
          const lastItem = existingActivities.length > 0 ? existingActivities[existingActivities.length - 1] : null;
          options.push({ type: 'append', targetIndex: existingActivities.length - 1, prevItem: lastItem, label: '排在最後' });
          setInsertionOptions(options);
          setSelectedInsertIndex(options.length - 1);
      }
  }, [selectedLocation, existingActivities]);

  const handleSearch = async (text: string) => {
      setQuery(text);
      if (text.length > 0) {
          setIsSearching(true);
          const predictions = await searchGooglePlaces(text);
          setResults(predictions || []);
      } else {
          setResults([]); setIsSearching(false);
      }
  };

  const handleSelectFromList = async (placeId: string, mainText: string) => {
      Keyboard.dismiss(); setQuery(mainText); setResults([]); setIsSearching(false);
      setLoading(true);
      const details = await getPlaceDetails(placeId);
      if (details?.coordinate) {
          const lat = details.coordinate.lat || details.coordinate.latitude;
          const lng = details.coordinate.lng || details.coordinate.longitude;
          setRegion({ latitude: lat, longitude: lng, latitudeDelta: 0.01, longitudeDelta: 0.01 });
          mapRef.current?.animateToRegion({ latitude: lat, longitude: lng, latitudeDelta: 0.01, longitudeDelta: 0.01 }, 1000);
          setSelectedLocation({ title: details.name, address: details.address, coordinate: { lat, lng } });
      }
      setLoading(false);
  };

  const handlePoiClick = async (e: any) => {
      isPoiClicked.current = true;
      setTimeout(() => { isPoiClicked.current = false; }, 800); 
      setIsSearching(false); setResults([]); Keyboard.dismiss();

      const { placeId, name, coordinate } = e.nativeEvent;
      if (!coordinate) return;

      setSelectedLocation({ title: name || "讀取中...", address: "連線中...", coordinate: { lat: coordinate.latitude, lng: coordinate.longitude } });

      if (placeId) {
          const details = await getPlaceDetails(placeId);
          if (details) {
              const lat = details.coordinate?.lat || details.coordinate?.latitude || coordinate.latitude;
              const lng = details.coordinate?.lng || details.coordinate?.longitude || coordinate.longitude;
              setSelectedLocation({ title: details.name || name, address: details.address, coordinate: { lat, lng } });
          }
      }
  };

  const handleMapPress = async (e: any) => {
      if (isSearching || query.length > 0) {
          Keyboard.dismiss(); setIsSearching(false); setResults([]); return; 
      }

      const { coordinate, name } = e.nativeEvent;
      if (!coordinate) return;

      setTimeout(async () => {
          if (isPoiClicked.current) return; 
          setLoading(true);
          
          const geoResult = await reverseGeocodeGoogle(coordinate.latitude, coordinate.longitude);
          
          let finalTitle = "自選地圖位置";
          if (geoResult?.isPlace && geoResult?.title) {
              finalTitle = geoResult.title;
          } else if (name && name.length > 0) {
              finalTitle = name;
          }

          setSelectedLocation({
              title: finalTitle,
              address: geoResult?.address || `座標: ${coordinate.latitude.toFixed(4)}, ${coordinate.longitude.toFixed(4)}`,
              coordinate: { lat: coordinate.latitude, lng: coordinate.longitude }
          });
          setLoading(false);
      }, 150); 
  };

  const handleConfirmAdd = () => {
      if (!selectedLocation) return;
      const safeIndex = (selectedInsertIndex >= 0 && selectedInsertIndex < insertionOptions.length) ? selectedInsertIndex : insertionOptions.length - 1;
      const option = insertionOptions[safeIndex];
      if (!option) return;

      let d = ''; if(stayHour>0) d+=`${stayHour}小時 `; if(stayMinute>0) d+=`${stayMinute}分鐘`; if(d==='') d='30分鐘';
      const totalMins = stayHour * 60 + stayMinute;

      const newItem = {
          title: selectedLocation?.title || '新景點',
          desc: `停留${d}`,
          durationValue: totalMins === 0 ? 30 : totalMins,
          type: 'activity',
          coordinate: {
              lat: selectedLocation.coordinate?.lat || selectedLocation.coordinate?.latitude,
              lng: selectedLocation.coordinate?.lng || selectedLocation.coordinate?.longitude
          },
          time: '09:00',
      };
      
      const finalIndex = option.type === 'append' ? -1 : option.targetIndex;
      addItineraryItem(planId, day, newItem, finalIndex);
      router.back();
  };

  const renderCard = ({ item, index }: any) => {
      const isActive = index === selectedInsertIndex;
      const prevItem = item?.prevItem;
      const prevTitle = prevItem?.title || null;
      const prevIdx = prevItem ? existingActivities.findIndex((i: any) => i?.id === prevItem.id) : -1;
      const nextIdx = prevTitle ? prevIdx + 2 : 1;

      return (
          <TouchableOpacity style={[styles.card, isActive && styles.activeCard]} onPress={() => setSelectedInsertIndex(index)} activeOpacity={0.9}>
              <View style={styles.cardHeader}>
                  <Text style={styles.cardTitle}>{item?.label}</Text>
                  <TouchableOpacity style={styles.timeBtn} onPress={() => setShowTimeModal(true)}>
                      <Text style={{fontSize:12, color:'#333', fontWeight:'bold', marginRight:4}}>
                          {stayHour}時 {stayMinute}分
                      </Text>
                      <Ionicons name="create-outline" size={16} color="#333" />
                  </TouchableOpacity>
              </View>
              <View style={styles.cardBody}>
                  {prevTitle && (
                      <>
                          <View style={styles.nodeRow}>
                              <View style={styles.nodeNumber}><Text style={styles.nodeText}>{prevIdx + 1}</Text></View>
                              <Text style={styles.nodeName} numberOfLines={1}>{prevTitle}</Text>
                          </View>
                          <View style={styles.nodeLine} />
                      </>
                  )}
                  <View style={styles.nodeRow}>
                      <View style={[styles.nodeNumber, { backgroundColor: '#FF8888', borderWidth:0 }]}><Ionicons name="add" size={14} color="white" /></View>
                      <View style={{flex: 1}}>
                          <Text style={[styles.nodeName, { fontWeight: 'bold' }]} numberOfLines={1}>{selectedLocation?.title || '新景點'}</Text>
                          <Text style={{fontSize:10, color:'#FF8888'}}>(將成為第 {nextIdx} 站)</Text>
                      </View>
                  </View>
              </View>
          </TouchableOpacity>
      );
  };

  return (
    <View style={styles.container}>
      {}
      <MapView 
          ref={mapRef} 
          style={styles.map} 
          region={region} 
          provider={PROVIDER_GOOGLE} 
          onPress={handleMapPress} 
          onPoiClick={handlePoiClick}
      >
          {existingActivities.map((spot: any, i: number) => {
              const lat = spot?.coordinate?.lat || spot?.coordinate?.latitude;
              const lng = spot?.coordinate?.lng || spot?.coordinate?.longitude;
              if (!lat || !lng) return null;

              return (
                  <Marker key={spot.id} coordinate={{ latitude: lat, longitude: lng }} title={`${i + 1}. ${spot?.title || '景點'}`}>
                      <View style={styles.markerBubble}><Text style={styles.markerText}>{i + 1}</Text></View>
                  </Marker>
              );
          })}
          <Polyline 
              coordinates={existingActivities
                  .filter((s:any) => s?.coordinate?.lat || s?.coordinate?.latitude)
                  .map((s:any) => ({
                      latitude: s.coordinate.lat || s.coordinate.latitude, 
                      longitude: s.coordinate.lng || s.coordinate.longitude
                  }))
              } 
              strokeColor="#6CA6CC" strokeWidth={3} 
          />
          
          {selectedLocation && selectedLocation.coordinate && (
              <Marker 
                  coordinate={{ 
                      latitude: selectedLocation.coordinate.lat || selectedLocation.coordinate.latitude, 
                      longitude: selectedLocation.coordinate.lng || selectedLocation.coordinate.longitude 
                  }}
                  title={selectedLocation?.title || '新景點'}
                  description={selectedLocation?.address || ''}
                  pinColor="red" 
              />
          )}
      </MapView>

      {loading && (
          <View style={styles.loadingOverlay}>
              <ActivityIndicator size="large" color="#6CA6CC" />
          </View>
      )}

      <SafeAreaView style={styles.topContainer} pointerEvents="box-none">
          <View style={styles.header}>
              <TouchableOpacity onPress={() => router.back()} style={styles.backBtn}><Ionicons name="chevron-back" size={24} color="#333" /></TouchableOpacity>
              <View style={styles.searchBox}>
                  <Ionicons name="search" size={20} color="#666" style={{marginRight: 8}} />
                  <TextInput style={styles.searchInput} placeholder="搜尋地點 或 點擊地標" value={query} onChangeText={handleSearch} onFocus={() => setIsSearching(true)} />
                  {query.length > 0 && (<TouchableOpacity onPress={() => { setQuery(''); setResults([]); setIsSearching(false); }}><Ionicons name="close-circle" size={20} color="#ccc" /></TouchableOpacity>)}
              </View>
          </View>
          {isSearching && results.length > 0 && (
              <View style={styles.resultsList}>
                  <FlatList data={results} keyExtractor={(item) => item.place_id} keyboardShouldPersistTaps="handled" renderItem={({ item }) => (
                      <TouchableOpacity style={styles.resultItem} onPress={() => handleSelectFromList(item.place_id, item.structured_formatting.main_text)}>
                          <Ionicons name="location" size={20} color="#666" style={{marginRight:10}} />
                          <Text style={styles.placeName}>{item.structured_formatting.main_text}</Text>
                      </TouchableOpacity>
                  )} />
              </View>
          )}
      </SafeAreaView>

      {selectedLocation && !isSearching && (
          <View style={styles.bottomArea} pointerEvents="box-none">
              <View style={styles.carouselContainer} pointerEvents="box-none">
                  <FlatList
                      data={insertionOptions} horizontal showsHorizontalScrollIndicator={false}
                      snapToInterval={CARD_WIDTH + 20} decelerationRate="fast"
                      contentContainerStyle={{ paddingHorizontal: SPACING }}
                      keyExtractor={(_, i) => i.toString()} renderItem={renderCard}
                      onMomentumScrollEnd={(ev) => {
                          const index = Math.round(ev.nativeEvent.contentOffset.x / (CARD_WIDTH + 20));
                          setSelectedInsertIndex(index);
                      }}
                  />
              </View>
              <TouchableOpacity style={styles.globalConfirmBtn} onPress={handleConfirmAdd}>
                  <Text style={styles.globalConfirmText}>確定新增此景點</Text>
              </TouchableOpacity>
          </View>
      )}

      <Modal visible={showTimeModal} transparent animationType="fade">
         <View style={styles.modalOverlay}>
             <View style={styles.confirmBox}>
                 <Text style={styles.modalTitle}>設定停留時間</Text>
                 <View style={styles.timePickerContainer}>
                     <View style={styles.selectionLine} pointerEvents="none"/>
                     <View style={styles.pickerColumn}>
                         <Text style={styles.pickerLabel}>時</Text>
                         <NativeScrollView ref={hourScrollRef} style={styles.pickerScroll} snapToInterval={ITEM_HEIGHT} decelerationRate="fast" showsVerticalScrollIndicator={false} contentContainerStyle={{ paddingVertical: PICKER_PADDING }} onMomentumScrollEnd={(e) => setStayHour(hoursList[Math.round(e.nativeEvent.contentOffset.y / ITEM_HEIGHT)] || 0)}>
                            {hoursList.map((h) => <View key={h} style={styles.pickerItem}><Text style={[styles.pickerText, stayHour === h && styles.pickerTextSelected]}>{h}</Text></View>)}
                         </NativeScrollView>
                     </View>
                     <View style={styles.pickerDivider}><Text style={{fontSize: 20, color:'#ddd'}}>:</Text></View>
                     <View style={styles.pickerColumn}>
                         <Text style={styles.pickerLabel}>分</Text>
                         <NativeScrollView ref={minuteScrollRef} style={styles.pickerScroll} snapToInterval={ITEM_HEIGHT} decelerationRate="fast" showsVerticalScrollIndicator={false} contentContainerStyle={{ paddingVertical: PICKER_PADDING }} onMomentumScrollEnd={(e) => setStayMinute(minutesList[Math.round(e.nativeEvent.contentOffset.y / ITEM_HEIGHT)] || 0)}>
                            {minutesList.map((m) => <View key={m} style={styles.pickerItem}><Text style={[styles.pickerText, stayMinute === m && styles.pickerTextSelected]}>{String(m).padStart(2,'0')}</Text></View>)}
                         </NativeScrollView>
                     </View>
                 </View>
                 <TouchableOpacity style={styles.timeConfirmBtn} onPress={()=>setShowTimeModal(false)}><Text style={{color:'white', fontWeight:'bold', fontSize: 16}}>完成設定</Text></TouchableOpacity>
             </View>
         </View>
      </Modal>
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#fff' },
  map: { ...StyleSheet.absoluteFillObject }, 
  loadingOverlay: { position: 'absolute', top: '50%', left: '50%', marginLeft: -25, marginTop: -25, backgroundColor: 'rgba(255,255,255,0.8)', padding: 10, borderRadius: 25, zIndex: 100 },
  topContainer: { position: 'absolute', top: 0, left: 0, right: 0, paddingHorizontal: 15, paddingTop: 10, zIndex: 10 },
  header: { flexDirection: 'row', alignItems: 'center' },
  backBtn: { width: 40, height: 40, borderRadius: 20, backgroundColor: 'white', justifyContent: 'center', alignItems: 'center', elevation: 5, shadowColor: '#000', shadowOffset: {width:0, height:2}, shadowOpacity:0.1, shadowRadius:4, marginRight: 10 },
  searchBox: { flex: 1, flexDirection: 'row', alignItems: 'center', backgroundColor: 'white', height: 46, borderRadius: 23, paddingHorizontal: 15, elevation: 5, shadowColor: '#000', shadowOffset: {width:0, height:2}, shadowOpacity:0.1, shadowRadius:4 },
  searchInput: { flex: 1, fontSize: 16, color: '#333' },
  resultsList: { position: 'absolute', top: 70, left: 15, right: 15, backgroundColor: 'white', borderRadius: 10, elevation: 10, maxHeight: 300, zIndex: 999 },
  resultItem: { flexDirection: 'row', alignItems: 'center', padding: 15, borderBottomWidth: 1, borderBottomColor: '#eee' },
  placeName: { fontSize: 16, color: '#333' },
  bottomArea: { position: 'absolute', bottom: 20, left: 0, right: 0, alignItems: 'center', zIndex: 20 },
  carouselContainer: { height: 160, width: '100%', marginBottom: 15 },
  card: { width: CARD_WIDTH, backgroundColor: 'white', borderRadius: 20, marginHorizontal: 10, padding: 15, elevation: 5, height: '100%', borderWidth: 1, borderColor: '#eee' },
  activeCard: { borderColor: '#6CA6CC', borderWidth: 2 },
  cardHeader: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', marginBottom: 10 },
  cardTitle: { fontSize: 16, fontWeight: 'bold', color: '#333' },
  timeBtn: { flexDirection:'row', alignItems:'center', backgroundColor:'#f0f0f0', paddingVertical:6, paddingHorizontal:10, borderRadius:15 },
  cardBody: { flex: 1, justifyContent: 'center', paddingLeft: 10 },
  nodeRow: { flexDirection: 'row', alignItems: 'center' },
  nodeNumber: { width: 24, height: 24, borderRadius: 12, backgroundColor: '#6CA6CC', justifyContent: 'center', alignItems: 'center', marginRight: 10 },
  nodeText: { color: 'white', fontWeight: 'bold', fontSize: 12 },
  nodeName: { fontSize: 16, color: '#333' },
  nodeLine: { width: 2, height: 25, backgroundColor: '#ccc', marginLeft: 11, marginVertical: 2 },
  globalConfirmBtn: { backgroundColor: '#6CA6CC', width: '85%', padding: 15, borderRadius: 30, alignItems: 'center', elevation: 5, shadowColor: '#000', shadowOffset: {width:0, height:2}, shadowOpacity:0.2, shadowRadius:4 },
  globalConfirmText: { color: 'white', fontWeight: 'bold', fontSize: 18 },

  markerBubble: { width: 24, height: 24, borderRadius: 12, backgroundColor: '#6CA6CC', justifyContent: 'center', alignItems: 'center', borderWidth: 2, borderColor: 'white' },
  markerText: { color: 'white', fontWeight: 'bold', fontSize: 10 },

  modalOverlay: { flex: 1, backgroundColor: 'rgba(0,0,0,0.5)', justifyContent: 'center', alignItems: 'center' },
  confirmBox: { width: '85%', backgroundColor: 'white', borderRadius: 20, padding: 25, alignItems: 'center', elevation: 10 },
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
  timeConfirmBtn: { width: '100%', backgroundColor: '#6CA6CC', padding: 15, borderRadius: 12, alignItems: 'center', justifyContent: 'center' }
});