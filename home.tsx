import { FontAwesome5, Ionicons, MaterialCommunityIcons } from '@expo/vector-icons';
import * as ExpoClipboard from 'expo-clipboard';
import * as ImagePicker from 'expo-image-picker';
import * as Location from 'expo-location';
import React, { useEffect, useState } from 'react';
import {
  ActivityIndicator,
  Alert, Dimensions,
  Image,
  ImageBackground,
  Linking, Modal,
  Platform,
  ScrollView,
  Share,
  StyleSheet,
  Switch,
  Text, TextInput, TouchableOpacity, View
} from 'react-native';
import { io } from 'socket.io-client';

let MapView: any = View;
let Marker: any = View;
let PROVIDER_GOOGLE: any = undefined;

if (Platform.OS !== 'web') {
  try {
    const Maps = require('react-native-maps');
    MapView = Maps.default;
    Marker = Maps.Marker;
    PROVIDER_GOOGLE = Maps.PROVIDER_GOOGLE;
  } catch (err) {
    console.log("Web 環境跳過地圖載入", err);
  }
}

const { width } = Dimensions.get('window');

const HOURS = Array.from({ length: 24 }, (_, i) => i.toString().padStart(2, '0'));
const MINUTES = ['00', '10', '20', '30', '40', '50'];

const GOOGLE_API_KEY = "AIzaSyAmlJOp_kRQw7tHvhd3goOMuHxt9CeNpos"; 
const WEATHER_API_KEY = "7b70b1773bfc5e58c1f1c2ef86c04082"; 

const MOCK_ACTIVE_TRIP = {
  id: 1,
  name: '🇹🇼 台南古都爆食三日遊',
  status: 'active',
  members: ['我', '小明', '阿美', '小華'],
  todaySchedule: [] 
};

const LANGUAGES = [
  { code: 'zh-TW', name: '繁體中文', country: 'TW' },
  { code: 'en', name: '英文', country: 'US' },
  { code: 'ja', name: '日文', country: 'JP' },
  { code: 'ko', name: '韓文', country: 'KR' },
  { code: 'th', name: '泰文', country: 'TH' },
  { code: 'vi', name: '越南文', country: 'VN' },
  { code: 'fr', name: '法文', country: 'FR' },
  { code: 'de', name: '德文', country: 'DE' },
];

const POPULAR_CITIES = [
  { name: '台北', query: 'Taipei' }, { name: '台中', query: 'Taichung' }, { name: '台南', query: 'Tainan' },
  { name: '高雄', query: 'Kaohsiung' }, { name: '東京', query: 'Tokyo' }, { name: '首爾', query: 'Seoul' },
  { name: '大阪', query: 'Osaka' }, { name: '曼谷', query: 'Bangkok' }, { name: '倫敦', query: 'London' },
  { name: '紐約', query: 'New York' },
];
const SUPPORTED_CURRENCIES = [
  { code: 'JP', name: '日本', currency: 'JPY', flag: '🇯🇵' }, { code: 'KR', name: '韓國', currency: 'KRW', flag: '🇰🇷' },
  { code: 'US', name: '美國', currency: 'USD', flag: '🇺🇸' }, { code: 'CN', name: '中國', currency: 'CNY', flag: '🇨🇳' },
  { code: 'HK', name: '香港', currency: 'HKD', flag: '🇭🇰' }, { code: 'TH', name: '泰國', currency: 'THB', flag: '🇹🇭' },
  { code: 'VN', name: '越南', currency: 'VND', flag: '🇻🇳' }, { code: 'EU', name: '歐盟', currency: 'EUR', flag: '🇪🇺' },
  { code: 'GB', name: '英國', currency: 'GBP', flag: '🇬🇧' }, { code: 'TW', name: '台灣', currency: 'TWD', flag: '🇹🇼' },
];
const TRANSPORT_LINKS: Record<string, { scheme: string; webUrl: string }> = {
  'Uber': { scheme: 'uber://', webUrl: 'https://m.uber.com/ul/' },
  'Ubike': { scheme: 'youbike://', webUrl: 'https://www.youbike.com.tw/region/main/' },
  '公車': { scheme: 'https://www.taiwanbus.tw/', webUrl: 'https://www.taiwanbus.tw/' },
  'iRent': { scheme: 'irent://', webUrl: 'https://www.irentcar.com.tw/' },
  'goShare': { scheme: 'goshare://', webUrl: 'https://www.ridegoshare.com/' },
};

interface CardProps {
  title: string; subTitle: string; icon?: string; size?: 'small' | 'large'; onPress?: () => void; loading?: boolean; style?: any;
}
const FunctionCard: React.FC<CardProps> = ({ title, subTitle, icon, size = 'small', onPress, loading, style }) => (
  <TouchableOpacity 
    style={[styles.card, size === 'large' ? styles.largeCard : styles.smallCard, style]} 
    onPress={onPress} 
    activeOpacity={0.7}
  >
    <View style={styles.cardHeader}>
      <Text style={styles.cardTitle}>{title}</Text>
      {icon && <FontAwesome5 name={icon as any} size={22} color="#4E84A7" />}
    </View>
    {loading ? <ActivityIndicator size="small" color="#4E84A7" style={{alignSelf:'flex-start', marginTop:5}}/> : <Text style={styles.cardSubTitle}>{subTitle}</Text>}
  </TouchableOpacity>
);

const WeatherDetailItem = ({ icon, label, value, iconLib = "FontAwesome5" }: any) => (
  <View style={styles.weatherDetailItem}>
    <View style={styles.weatherIconCircle}>
      {iconLib === "MaterialCommunityIcons" ? <MaterialCommunityIcons name={icon} size={20} color="#4E84A7" /> : <FontAwesome5 name={icon} size={20} color="#4E84A7" />}
    </View>
    <Text style={styles.weatherDetailLabel}>{label}</Text>
    <Text style={styles.weatherDetailValue}>{value || '--'}</Text>
  </View>
);

const formatTime = (unixTime: number) => {
  if (!unixTime) return '--:--';
  const date = new Date(unixTime * 1000);
  return `${date.getHours().toString().padStart(2, '0')}:${date.getMinutes().toString().padStart(2, '0')}`;
};
const getDayName = (unixTime: number) => {
  const days = ['週日', '週一', '週二', '週三', '週四', '週五', '週六'];
  return days[new Date(unixTime * 1000).getDay()];
};

export default function HomeScreen() {
  const defaultCurrency = SUPPORTED_CURRENCIES.find(c => c.code === 'TW') || SUPPORTED_CURRENCIES[0];
  const [targetInfo, setTargetInfo] = useState(defaultCurrency); 
  const [exchangeRate, setExchangeRate] = useState<number | null>(null);
const [userAvatar, setUserAvatar] = useState('https://png.pngtree.com/element_our/20200703/ourlarge/pngtree-q-version-cute-cartoon-cute-little-animals-zodiac-signs-pig-image_2298838.jpg');
  const [modalVisible, setModalVisible] = useState(false);
  const [weatherModalVisible, setWeatherModalVisible] = useState(false);
  const [isSelectingCountry, setIsSelectingCountry] = useState(false);
  
  const [twdValue, setTwdValue] = useState('');      
  const [foreignValue, setForeignValue] = useState('');
  const [isSelectingCity, setIsSelectingCity] = useState(false);
  const [citySearchText, setCitySearchText] = useState('');
  
  const [isMapMode, setIsMapMode] = useState(false); 
  const [mapRegion, setMapRegion] = useState({ latitude: 25.0330, longitude: 121.5654, latitudeDelta: 0.05, longitudeDelta: 0.05 });
  const [selectedCoord, setSelectedCoord] = useState<{lat: number, lon: number} | null>(null);
  
  const [activeTrip, setActiveTrip] = useState<any>({
    id: 1,
    name: '🇹🇼 台南古都爆食三日遊', 
    status: 'active',
    members: [],       // 預設為空陣列
    todaySchedule: []  // 預設為空陣列
  });

  const fetchTripSchedule = async () => {
    try {
      const response = await fetch('http://172.20.112.231:3000/api/schedule');
      const realSchedule = await response.json();
      setActiveTrip((prev: any) => ({ ...prev, todaySchedule: realSchedule }));
    } catch (error: any) {
      console.error('❌ 抓取行程失敗:', error.message);
    }
  };

  const fetchTripMembers = async () => {
    try {
      const response = await fetch(`http://172.20.112.231:3000/api/trips/${activeTrip.id}/members`); 
      const realMembers = await response.json();

      setActiveTrip((prev: any) => ({
        ...prev,
        members: realMembers
      }));
    } catch (error: any) {
      console.error('❌ 無法取得群組成員:', error.message);
    }
  };
  
  const [nextStop, setNextStop] = useState<any>(null); 
  const [meetingPoint, setMeetingPoint] = useState<any>(null); 

  const [isSharingLocation, setIsSharingLocation] = useState(true); 

  const [meetingModalVisible, setMeetingModalVisible] = useState(false);
  const [tempMeetingCoord, setTempMeetingCoord] = useState<any>(null); 
  const [tempPlaceName, setTempPlaceName] = useState<string>('');
  
  const [selectedHour, setSelectedHour] = useState('12');
  const [selectedMinute, setSelectedMinute] = useState('00');

  const [weatherData, setWeatherData] = useState({
    temp: '--', desc: '載入中...', icon: 'cloud-sun', locationName: '定位中...',
    feelsLike: '--', humidity: '--', windSpeed: '--', pressure: '--',
    tempMin: '--', tempMax: '--', sunrise: '--', sunset: '--', hourly: [] as any[], daily: [] as any[],
  });
  const [recommendations, setRecommendations] = useState<any[]>([]);

  const [transModalVisible, setTransModalVisible] = useState(false);
  const [transInput, setTransInput] = useState('');
  const [transResult, setTransResult] = useState('');
  const [isTranslating, setIsTranslating] = useState(false);
  const [isListening, setIsListening] = useState(false); 
  const [sourceLang, setSourceLang] = useState(LANGUAGES[0]);
  const [targetLang, setTargetLang] = useState(LANGUAGES[1]);
  const [isSelectingTransLang, setIsSelectingTransLang] = useState<'source' | 'target' | null>(null);
  const [capturedImage, setCapturedImage] = useState<string | null>(null);
  const [othersLocations, setOthersLocations] = useState<any>({}); 
  const [expenses, setExpenses] = useState<any[]>([]);
  const [newExpenseTitle, setNewExpenseTitle] = useState('');
  const [selectedPayer, setSelectedPayer] = useState('我');
const [expenseNote, setExpenseNote] = useState('');     
const [splitType, setSplitType] = useState('平均分攤');  
  const [newExpenseAmount, setNewExpenseAmount] = useState('');
  const [isExpenseModalVisible, setExpenseModalVisible] = useState(false); 
const [participants, setParticipants] = useState<any[]>([]); // 加上 <any[]>
const [splitMode, setSplitMode] = useState<'equal' | 'custom'>('equal');
  const [activeTab, setActiveTab] = useState<'add' | 'records'>('add');
  const [editingExpenseId, setEditingExpenseId] = useState<number | null>(null);
  const fetchExpenses = async () => {
  try {
    const response = await fetch(`http://172.20.112.231:3000/api/trips/${activeTrip.id}/expenses`);
    const data = await response.json(); 
        
        console.log("🔍 Google 視覺 API 真實回傳:", JSON.stringify(data, null, 2));
        if (data.error) {
          Alert.alert("Google 拒絕連線 🚫", data.error.message);
          setTransInput('');
          return;
        }

    if (Array.isArray(data)) {
      setExpenses(data);
    }
  } catch (error) {
    console.error('❌ 抓取花費失敗:', error);
  }
};

  const handleDeleteExpense = (expenseId: number) => {
    Alert.alert("刪除紀錄", "確定要刪除這筆花費嗎？", [
      { text: "取消", style: "cancel" },
      { text: "確定刪除", style: "destructive", onPress: async () => {
          await fetch(`http://172.20.112.231:3000/api/trips/${activeTrip.id}/expenses/${expenseId}`, { method: 'DELETE' });
          fetchExpenses(); 
        }
      }
    ]);
  };

  const handleEditExpense = (expense: any) => {
    setEditingExpenseId(expense.id);
    setNewExpenseTitle(expense.title);
    setNewExpenseAmount(expense.amount.toString());
    setSelectedPayer(expense.payer_name);
    
    if (activeTrip.members) {
      const restoredParticipants = activeTrip.members.map((m: any) => {
        const foundSplit = expense.splits?.find((s: any) => s.user_name === m.user_name);
        return {
          name: m.user_name,
          selected: !!foundSplit, 
          amount: foundSplit ? parseFloat(foundSplit.amount_owed) : 0
        };
      });
      setParticipants(restoredParticipants);
    }
    
    setSplitMode('equal');
    
    setActiveTab('add');
  };

  const resetExpenseForm = () => {
    setEditingExpenseId(null);
    setNewExpenseTitle('');
    setNewExpenseAmount('');
    setExpenseNote('');
    setActiveTab('add');
    if (activeTrip.members) {
      setParticipants(activeTrip.members.map((m: any) => ({ name: m.user_name, selected: true, amount: 0 })));
    }
  };


useEffect(() => {
  if (activeTrip.members) {
    setParticipants(activeTrip.members.map((m: any) => ({ name: m.user_name, selected: true, amount: 0 })));
  }
}, [activeTrip.members]);

  useEffect(() => {
    // 建立 Socket 連線
    const socket = io('http://172.20.112.231:3000');

    socket.on('userMoved', (data: any) => {
      console.log('🚶‍♂️ 收到成員移動:', data);
      setOthersLocations((prev: any) => ({
        ...prev,
        [data.userId]: data
      }));
    });

    let mockLat = mapRegion.latitude + 0.005; 
    let mockLon = mapRegion.longitude;

    const mockInterval = setInterval(() => {
      mockLat -= 0.0001;  // 往南走
      mockLon += 0.00005; // 往東走

      setOthersLocations((prev: any) => ({
        ...prev,
        'user_xiaoming': {
          userId: 'user_xiaoming',
          userName: '小明',
          avatar_url: 'https://cdn-icons-png.flaticon.com/512/147/147144.png',
          latitude: mockLat,
          longitude: mockLon
        }
      }));
    }, 2000); 
    const locationInterval = setInterval(() => {
      if (isSharingLocation && mapRegion) {
        socket.emit('updateLocation', {
          userId: 'user_me', 
          userName: '我',
          avatar_url: userAvatar, 
          latitude: mapRegion.latitude,
          longitude: mapRegion.longitude
        });
      }
    }, 5000); // 每 5 秒發送一次

    return () => {
      socket.disconnect();
      clearInterval(mockInterval);
      clearInterval(locationInterval);
    };
  }, [mapRegion, isSharingLocation, userAvatar]); 

  useEffect(() => {
    fetchTripSchedule();
    fetchTripMembers();  
    fetchExpenses();

    (async () => {
      await handleCurrentLocation();
      fetchRate(targetInfo.currency);
    })();
  }, []);


  useEffect(() => {
    const now = new Date();
    const currentHour = now.getHours();
    const currentMin = now.getMinutes();
    const currentTimeVal = currentHour * 60 + currentMin;
    

    console.log(`⏰ 目前時間: ${currentHour}:${currentMin} (數值: ${currentTimeVal})`);
    console.log(`📅 目前拿到的行程:`, activeTrip?.todaySchedule); 

    if (activeTrip && activeTrip.status === 'active') {
        
        // 這樣後面執行 .find() 時，最慘也就是找不到東西，絕對不會閃退崩潰！
        const scheduleArray = Array.isArray(activeTrip?.todaySchedule) ? activeTrip.todaySchedule : [];
        
        const upcoming = scheduleArray.find((item: any) => {
            if (!item || !item.time) return false; 
            
            const [h, m] = item.time.split(':').map(Number);
            const itemTimeVal = h * 60 + m;
            return itemTimeVal > currentTimeVal;
        });
        
        console.log(`📍 算出來的下一站是:`, upcoming ? upcoming.title : '沒有下一站');
        setNextStop(upcoming ? upcoming : null);
    }
  }, [activeTrip]);

  useEffect(() => {
    if (!transInput.trim()) { setTransResult(''); return; }
    const timer = setTimeout(() => { handleTranslate(); }, 800);
    return () => clearTimeout(timer);
  }, [transInput, sourceLang, targetLang]);

  const handleCurrentLocation = async () => {
    setIsSelectingCity(false);
    setIsMapMode(false);
    setWeatherData(prev => ({ ...prev, locationName: '定位中...', desc: '更新數據中...' }));
    try {
      let location = await Location.getCurrentPositionAsync({});
      const { latitude, longitude } = location.coords;
      setMapRegion({ latitude, longitude, latitudeDelta: 0.05, longitudeDelta: 0.05 });
      setTempMeetingCoord({ latitude, longitude });
      setTempPlaceName("我的位置");
      fetchFullWeatherData(latitude, longitude);
      fetchPlaces(latitude, longitude); 
      let address = await Location.reverseGeocodeAsync({ latitude, longitude });
      if (address && address.length > 0) {
         const currentCountryCode = address[0].isoCountryCode; 
         const foundCurrency = SUPPORTED_CURRENCIES.find(c => c.code === currentCountryCode);
         if (foundCurrency) { setTargetInfo(foundCurrency); fetchRate(foundCurrency.currency); }
         if (currentCountryCode !== 'TW') {
             const foundLang = LANGUAGES.find(l => l.country === currentCountryCode);
             if (foundLang) { setSourceLang(LANGUAGES.find(l => l.code === 'zh-TW') || LANGUAGES[0]); setTargetLang(foundLang); }
         }
      }
    } catch (error) { console.log(error); }
  };

  const fetchFullWeatherData = async (lat: number, lon: number, cityNameOverride?: string) => {
    if (!WEATHER_API_KEY) return;
    try {
      const currentUrl = `https://api.openweathermap.org/data/2.5/weather?lat=${lat}&lon=${lon}&units=metric&lang=zh_tw&appid=${WEATHER_API_KEY}`;
      const currentRes = await fetch(currentUrl);
      const currentData = await currentRes.json();
      if (currentData.cod !== 200) { Alert.alert("天氣錯誤", "無法抓取目前天氣"); return; }
      let forecastData = null;
      try {
        const forecastRes = await fetch(`https://api.openweathermap.org/data/2.5/forecast?lat=${lat}&lon=${lon}&units=metric&lang=zh_tw&appid=${WEATHER_API_KEY}`);
        const forecastJson = await forecastRes.json();
        if (forecastJson.cod === "200" || forecastJson.cod === 200) forecastData = forecastJson;
      } catch (err) {}
      processFullWeatherData(currentData, forecastData, cityNameOverride);
    } catch (error) { Alert.alert("連線失敗", "請檢查網路狀態"); }
  };
  const fetchWeatherByName = async (cityName: string) => {
    if (!cityName) return;
    try {
      const geoRes = await fetch(`https://api.openweathermap.org/data/2.5/weather?q=${cityName}&units=metric&lang=zh_tw&appid=${WEATHER_API_KEY}`);
      const geoData = await geoRes.json();
      if (geoData.cod !== 200) { Alert.alert("找不到城市", "請確認輸入名稱"); return; }
      fetchFullWeatherData(geoData.coord.lat, geoData.coord.lon, geoData.name);
      setIsSelectingCity(false);
    } catch (error) { Alert.alert("錯誤", "網路連線異常"); }
  };
  const fetchPlaces = async (lat: number, lon: number) => {
    if (!GOOGLE_API_KEY) return;
    try {
      const response = await fetch('https://places.googleapis.com/v1/places:searchNearby', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-Goog-Api-Key': GOOGLE_API_KEY,
          'X-Goog-FieldMask': 'places.id,places.displayName,places.photos,places.rating,places.formattedAddress,places.location'
        },
        body: JSON.stringify({
          includedTypes: ['tourist_attraction', 'restaurant', 'park', 'store', 'cafe'], 
          maxResultCount: 10,
          locationRestriction: { circle: { center: { latitude: lat, longitude: lon }, radius: 5000.0 } }
        })
      });
      const data = await response.json();
      if (data.places) {
        const places = data.places.map((item: any) => {
          let photoUrl = 'https://images.unsplash.com/photo-1542038784424-48ed74686c5e?q=80&w=1000';
          if (item.photos && item.photos.length > 0) {
            const photoName = item.photos[0].name;
            photoUrl = `https://places.googleapis.com/v1/${photoName}/media?maxHeightPx=800&maxWidthPx=800&key=${GOOGLE_API_KEY}`;
          }
          return {
            id: item.id, title: item.displayName?.text || '未知地點', image: photoUrl,
            rating: item.rating || 0.0, address: item.formattedAddress || '',
            lat: item.location?.latitude, lon: item.location?.longitude
          };
        });
        setRecommendations(places);
      } else { setRecommendations([]); }
    } catch (error) {}
  };
  const processFullWeatherData = (current: any, forecast: any, cityNameOverride?: string) => {
    if (!current) return;
    let hourlyList: any[] = [];
    if (forecast && forecast.list) {
        hourlyList = forecast.list.slice(0, 9).map((item: any) => ({
            dt: item.dt, temp: Math.round(item.main.temp), icon: getWeatherIcon(item.weather[0].id), time: formatTime(item.dt)
        }));
    }
    let dailyList: any[] = [];
    if (forecast && forecast.list) {
        const dailyMap: Record<string, any> = {};
        forecast.list.forEach((item: any) => {
            const dateTxt = item.dt_txt.split(' ')[0];
            if (!dailyMap[dateTxt]) { dailyMap[dateTxt] = { min: item.main.temp_min, max: item.main.temp_max, iconId: item.weather[0].id, dt: item.dt }; } 
            else {
                dailyMap[dateTxt].min = Math.min(dailyMap[dateTxt].min, item.main.temp_min);
                dailyMap[dateTxt].max = Math.max(dailyMap[dateTxt].max, item.main.temp_max);
                if (item.dt_txt.includes("12:00")) dailyMap[dateTxt].iconId = item.weather[0].id;
            }
        });
        dailyList = Object.values(dailyMap).slice(1, 6).map((d: any) => ({
            day: getDayName(d.dt), min: Math.round(d.min), max: Math.round(d.max), icon: getWeatherIcon(d.iconId)
        }));
    }
    setWeatherData({
      temp: Math.round(current.main.temp).toString(), desc: current.weather[0].description, icon: getWeatherIcon(current.weather[0].id),
      locationName: cityNameOverride || current.name, feelsLike: Math.round(current.main.feels_like).toString(),
      humidity: current.main.humidity.toString(), windSpeed: current.wind.speed.toString(), pressure: current.main.pressure.toString(),
      tempMin: Math.round(current.main.temp_min).toString(), tempMax: Math.round(current.main.temp_max).toString(),
      sunrise: current.sys ? formatTime(current.sys.sunrise) : '--:--', sunset: current.sys ? formatTime(current.sys.sunset) : '--:--',
      hourly: hourlyList, daily: dailyList
    });
  };
  const getWeatherIcon = (id: number): string => {
    if (id >= 200 && id < 300) return 'bolt'; if (id >= 300 && id < 500) return 'cloud-rain'; if (id >= 500 && id < 600) return 'umbrella';
    if (id >= 600 && id < 700) return 'snowflake'; if (id >= 700 && id < 800) return 'smog'; if (id === 800) return 'sun'; if (id > 800) return 'cloud';
    return 'cloud-sun';
  };
  const fetchRate = async (targetCurrency: string) => {
    try {
      if (targetCurrency === 'TWD') { setExchangeRate(1); if (twdValue) setForeignValue(twdValue); return; }
      const response = await fetch('https://api.exchangerate-api.com/v4/latest/TWD');
      const data = await response.json();
      setExchangeRate(data.rates[targetCurrency]);
      if (twdValue && data.rates[targetCurrency]) { const val = parseFloat(twdValue); if(!isNaN(val)) setForeignValue((val * data.rates[targetCurrency]).toFixed(2)); }
    } catch (error) { console.error(error); }
  };
  const handleTwdChange = (text: string) => { setTwdValue(text); if (!text) { setForeignValue(''); return; } if (exchangeRate) { const val = parseFloat(text); if (!isNaN(val)) setForeignValue((val * exchangeRate).toFixed(2)); } };
  const handleForeignChange = (text: string) => { setForeignValue(text); if (!text) { setTwdValue(''); return; } if (exchangeRate) { const val = parseFloat(text); if (!isNaN(val)) setTwdValue((val / exchangeRate).toFixed(1)); } };
  const handleCountrySelect = (country: typeof SUPPORTED_CURRENCIES[0]) => { setTargetInfo(country); fetchRate(country.currency); setIsSelectingCountry(false); setForeignValue(''); };
  const handleTransportPress = async (name: string) => {
    const STRATEGIES: Record<string, string[]> = { 'YouBike': ['youbike2://', 'youbike://'], 'Uber': ['uber://'], 'Ubike': ['youbike2://'] };
    const targetUrl = TRANSPORT_LINKS[name]?.webUrl;
    const schemes = STRATEGIES[name] || [TRANSPORT_LINKS[name]?.scheme];
    if (!targetUrl) return;
    for (const scheme of schemes) { if (!scheme) continue; try { await Linking.openURL(scheme); return; } catch (err) {} }
    Linking.openURL(targetUrl);
  };
  
  const handleNavigate = (lat: number, lon: number, label: string) => {
    if (!lat || !lon) { Alert.alert("錯誤", "找不到座標"); return; }
    
    const url = Platform.select({
      ios: `maps://app?daddr=${lat},${lon}&q=${encodeURIComponent(label)}`,
      android: `google.navigation:q=${lat},${lon}`,
      default: `https://www.google.com/maps/dir/?api=1&destination=${lat},${lon}`
    });

    if (url) {
      Linking.openURL(url).catch(err => { 
        // Fallback to web browser if app linking fails
        Linking.openURL(`https://www.google.com/maps/search/?api=1&query=${lat},${lon}`);
      });
    }
  };

  const handleShareLocation = async () => {
    try {
      const lat = mapRegion.latitude;
      const lon = mapRegion.longitude;
      const mapUrl = `https://www.google.com/maps/search/?api=1&query=${lat},${lon}`;
      await Share.share({ message: `我在這裡！快來找我～ 📍\n${mapUrl}` });
    } catch (error) { Alert.alert('分享失敗', '無法啟動分享功能'); }
  };
  
  const handleOpenMeetingMap = () => { 
      setMeetingModalVisible(true); 
      if (!tempMeetingCoord) { 
          handleCurrentLocation(); 
      }
  };
  
  const handleConfirmMeeting = () => {
      if (!tempMeetingCoord) return;
      const finalTime = `${selectedHour}:${selectedMinute}`; 
      setMeetingPoint({
          title: tempPlaceName || "自訂集合點", 
          time: finalTime,
          lat: tempMeetingCoord.latitude,
          lon: tempMeetingCoord.longitude
      });
      setMeetingModalVisible(false);
      Alert.alert("✅ 集合發起成功", `大家將在 ${finalTime} 於「${tempPlaceName || "地圖指定位置"}」集合！`);
  };

  const handleCancelMeeting = () => {
      Alert.alert(
          "取消集合",
          "確定要取消這次的集合嗎？",
          [
              { text: "保留", style: "cancel" },
              { text: "確認取消", style: "destructive", onPress: () => setMeetingPoint(null) }
          ]
      );
  };

  const handleMeetingCardPress = () => {
      if (meetingPoint) {
          Alert.alert(
              "🔥 集合進行中",
              `目標：${meetingPoint.title}\n時間：${meetingPoint.time}`,
              [
                  { text: "📍 導航前往", onPress: () => handleNavigate(meetingPoint.lat, meetingPoint.lon, meetingPoint.title) },
                  { text: "取消集合", style: 'destructive', onPress: handleCancelMeeting },
                  { text: "查看/修改位置", onPress: () => setMeetingModalVisible(true) }, 
                  { text: "關閉", style: 'cancel' }
              ]
          );
      } else {
          handleOpenMeetingMap();
      }
  };

  const toggleSharing = () => {
      setIsSharingLocation(previousState => !previousState);
      if (!isSharingLocation) { Alert.alert("📍 定位分享中", "群組成員現在可以在地圖上看到你的大頭貼！"); } else { Alert.alert("👻 幽靈模式", "你已隱藏位置，地圖上不會顯示你的大頭貼。"); }
  };
  const handleTranslate = async () => {
    if (!transInput.trim()) return;
    setIsTranslating(true);
    const langPair = `${sourceLang.code}|${targetLang.code}`;
    try {
      const url = `https://api.mymemory.translated.net/get?q=${encodeURIComponent(transInput)}&langpair=${langPair}`;
      const response = await fetch(url);
      const data = await response.json();
      if (data.responseData) setTransResult(data.responseData.translatedText);
      else setTransResult("翻譯失敗");
    } catch (error) { setTransResult("網路錯誤"); } 
    finally { setIsTranslating(false); }
  };
  const handleSwapLanguages = () => { const temp = sourceLang; setSourceLang(targetLang); setTargetLang(temp); };
  const handleCopyResult = async () => { if (transResult) { await ExpoClipboard.setStringAsync(transResult); Alert.alert("已複製", "翻譯結果已複製"); } };
  const handleCamera = async () => {
    const permissionResult = await ImagePicker.requestCameraPermissionsAsync();
    if (permissionResult.granted === false) { 
      Alert.alert("需要權限", "請允許使用相機"); 
      return; 
    }
    
    const result = await ImagePicker.launchCameraAsync({ 
      mediaTypes: ImagePicker.MediaTypeOptions.Images, 
      allowsEditing: false, 
      quality: 0.8,
      base64: true  
    });
    
    if (!result.canceled && result.assets[0].base64) { 
      setCapturedImage(result.assets[0].uri); 
      setTransInput("（🔍 正在使用 Google 視覺 AI 分析圖片文字...）"); 
      
      try {
        const response = await fetch(`https://vision.googleapis.com/v1/images:annotate?key=${GOOGLE_API_KEY}`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            requests: [{
              image: { content: result.assets[0].base64 },
              features: [{ type: 'TEXT_DETECTION' }] 
            }]
          })
        });
        
        const data = await response.json();
        
        console.log("🔍 Google API 回傳:", JSON.stringify(data, null, 2));
        
        if (data.error) {
          Alert.alert("API 金鑰錯誤 🚫", data.error.message);
          setTransInput('');
          return;
        }

        if (data.responses && data.responses[0] && data.responses[0].error) {
          Alert.alert("Google 權限被擋 🚫", data.responses[0].error.message);
          setTransInput('');
          return;
        }
        
        if (data.responses && data.responses[0] && data.responses[0].textAnnotations) {
          const detectedText = data.responses[0].textAnnotations[0].description;
          setTransInput(detectedText); 
        } else {
          setTransInput('');
          Alert.alert("辨識失敗", "圖片中找不到任何文字，請靠近一點再拍一次！");
        }
      } catch (error) {
        console.error("OCR 錯誤:", error);
        setTransInput('');
        Alert.alert("連線錯誤", "無法分析圖片，請檢查網路狀態或 API Key。");
      }
    } 
  };

  const handlePickAvatar = async () => {
    const permissionResult = await ImagePicker.requestMediaLibraryPermissionsAsync();
    if (permissionResult.granted === false) {
      Alert.alert("需要權限", "請允許存取相簿來更換大頭貼！");
      return;
    }

    const result = await ImagePicker.launchImageLibraryAsync({
      mediaTypes: ImagePicker.MediaTypeOptions.Images,
      allowsEditing: true,
      aspect: [1, 1], 
      quality: 0.5, 
    });

    if (!result.canceled && result.assets && result.assets.length > 0) {
      setUserAvatar(result.assets[0].uri);
    }
  };

  const handleVoice = () => { Alert.alert("語音輸入", "請點擊輸入框，並使用鍵盤上的「麥克風 🎙️」按鈕來說話喔！"); };
  
  const handleCardVoice = () => {
    if (isListening) return;
    setIsListening(true);
    setTransResult('');
    setTransInput('');
    setTimeout(() => {
        const mockTexts = ["這附近有推薦的餐廳嗎？", "請問捷運站在哪裡？", "我想去便利商店", "今天天氣如何？"];
        const randomText = mockTexts[Math.floor(Math.random() * mockTexts.length)];
        setTransInput(randomText);
        setIsListening(false);
    }, 1500);
  };

  const selectTransLang = (lang: typeof LANGUAGES[0]) => { 
    if (isSelectingTransLang === 'source') {
      setSourceLang(lang);
    } else if (isSelectingTransLang === 'target') {
      setTargetLang(lang);
    }
    setIsSelectingTransLang(null); 
  };

  const totalExpense = expenses.reduce((sum, item) => sum + (Number(item.amount) || 0), 0);

  const myPaid = expenses
    .filter(item => item.payer_name === '我')
    .reduce((sum, item) => sum + (Number(item.amount) || 0), 0);

  const myShare = expenses.reduce((sum, expense) => {
    // 如果後端有傳 splits 明細過來，就去裡面找「我」的名字
    if (expense.splits && expense.splits.length > 0) {
      const mySplit = expense.splits.find((s: any) => s.user_name === '我');
      return sum + (mySplit ? Number(mySplit.amount_owed) : 0);
    } else {
      const count = Array.isArray(activeTrip?.members) && activeTrip.members.length > 0 ? activeTrip.members.length : 4;
      return sum + (Number(expense.amount) / count);
    }
  }, 0);

  const myBalance = myPaid - myShare;

  const getSplitAmount = (index: number) => {
    if (splitMode === 'equal') {
      const selectedCount = participants.filter(p => p.selected).length;
      return selectedCount > 0 ? (Number(newExpenseAmount) / selectedCount).toFixed(0) : "0";
    } else {
      return participants[index].amount ? participants[index].amount.toString() : "0";
    }
  };

  return (
    <View style={styles.container}>
      <View style={styles.topHeader}><Text style={styles.topHeaderText}>Piggo 首頁</Text></View>
      <ScrollView contentContainerStyle={styles.content}>
        
        {/* 天氣 & 記帳 */}
        <View style={styles.row}>
          <TouchableOpacity style={[styles.card, styles.weatherCardWide]} activeOpacity={0.9} onPress={() => { setWeatherModalVisible(true); setIsSelectingCity(false); }}>
            <View style={{flexDirection:'row', justifyContent:'space-between', alignItems:'center', marginBottom: 5}}>
                <Text style={styles.weatherCardLocation} numberOfLines={1}><Ionicons name="location-sharp" size={12}/> {weatherData.locationName}</Text>
                <Text style={styles.weatherCardDesc}>{weatherData.desc}</Text>
            </View>
            <View style={{flexDirection:'row', justifyContent:'space-between', alignItems:'center'}}>
                <View>
                    <Text style={styles.weatherCardTempBig}>{weatherData.temp}°</Text>
                    <Text style={styles.weatherCardHighLow}>最高{weatherData.tempMax}° 最低{weatherData.tempMin}°</Text>
                </View>
                <FontAwesome5 name={weatherData.icon as any} size={40} color="#FBC02D" style={{opacity: 0.9}}/>
            </View>
            <View style={styles.weatherCardDivider} />
            <View style={{flexDirection: 'row', justifyContent: 'space-between', paddingTop: 5}}>
                {weatherData.hourly.length > 0 ? (
                  weatherData.hourly.slice(0, 3).map((item, index) => (
                    <View key={index} style={{alignItems:'center', width: width / 6}}>
                        <Text style={{color:'#ccc', fontSize:10}}>{item.time}</Text>
                        <FontAwesome5 name={item.icon as any} size={12} color="#fff" style={{marginVertical:2}}/>
                        <Text style={{color:'#fff', fontSize:12, fontWeight:'bold'}}>{item.temp}°</Text>
                    </View>
                  ))
                ) : (
                  <Text style={{color:'#aaa', fontSize:12}}>更新中...</Text>
                )}
            </View>
          </TouchableOpacity>
{/*  記帳卡片  */}
<TouchableOpacity 
  style={[styles.card, styles.accountingCardSmall]} 
  onPress={() => setExpenseModalVisible(true)}
>
  <View style={{ flex: 1 }}>
    <Text style={styles.accountingTitle}>記帳</Text>
    
    <View style={{ marginTop: 10 }}>
      {/* 個人實際花費 (2.0 升級版) */}
<Text style={styles.accountingLabel}>我的總花費 ${Math.round(myShare)}</Text>
      
      {/* 結餘：顯示應收回或需支付 */}
      <Text style={[
        styles.accountingLabel, 
        { color: myBalance >= 0 ? '#4ECDC4' : '#FF6B6B', fontWeight: 'bold' }
      ]}>
        {myBalance >= 0 ? `應收回 $${myBalance.toFixed(0)}` : `需支付 $${Math.abs(myBalance).toFixed(0)}`}
      </Text>
    </View>
  </View>

  {/* 底部白色「記一筆」按鈕 */}
  <View style={styles.recordButton}>
    <Ionicons name="add" size={18} color="#4E84A7" />
    <Text style={styles.recordButtonText}>記一筆</Text>
  </View>
</TouchableOpacity>
        </View>

        {/* 交通 */}
        <View style={styles.sectionCard}>
          <Text style={styles.sectionTitle}>交通直達</Text>
          <View style={styles.iconRow}>
            {['Uber', 'Ubike', '公車', 'iRent', 'goShare'].map((item) => (<TouchableOpacity key={item} style={styles.transportIcon} onPress={() => handleTransportPress(item)}><Text style={styles.iconText}>{item}</Text></TouchableOpacity>))}
          </View>
        </View>

        {/* 景點 */}
        <View style={styles.sectionContainer}>
          <Text style={styles.sectionTitle}>🔥 熱門景點 / 美食</Text>
          {recommendations.length === 0 ? (<View style={[styles.card, {alignItems: 'center', padding: 20}]}><Text style={{color: '#666'}}>正在搜尋附近的景點...</Text></View>) : (
             <ScrollView horizontal showsHorizontalScrollIndicator={false} snapToInterval={width - 30} decelerationRate="fast" contentContainerStyle={{ paddingHorizontal: 0 }}>
              {recommendations.map((item, index) => (
                <TouchableOpacity key={item.id} style={[styles.spotCard, { width: width - 30, marginLeft: index === 0 ? 0 : 15 }]} activeOpacity={0.9} onPress={() => handleNavigate(item.lat, item.lon, item.title)}>
                  <ImageBackground source={{ uri: item.image }} style={styles.spotImage} imageStyle={{ borderRadius: 15 }}>
                    <View style={styles.spotOverlay}>
                      <View style={{flexDirection:'row', justifyContent:'space-between', alignItems:'flex-start'}}>
                          <View style={{flex: 1}}>
                            <Text style={styles.spotTitle} numberOfLines={1}>{item.title}</Text>
                            <Text style={styles.spotAddress} numberOfLines={1}><Ionicons name="location" size={12}/>{item.address}</Text>
                          </View>
                          <View style={styles.spotRating}><FontAwesome5 name="star" size={14} color="#FFD700" solid /><Text style={styles.spotRatingText}>{item.rating}</Text></View>
                      </View>
                      <View style={styles.navButton}><Text style={{color:'#fff', fontWeight:'bold', fontSize:12}}>點擊導航</Text><Ionicons name="navigate" color="#fff" size={12} /></View>
                    </View>
                  </ImageBackground>
                </TouchableOpacity>
              ))}
            </ScrollView>
          )}
        </View>
        
        {/* 下一站 & 分享/集合 */}
        <View style={styles.row}>
          <TouchableOpacity style={[styles.card, styles.squareCard, {justifyContent: 'space-between', alignItems: 'flex-start'}]} onPress={() => nextStop ? handleNavigate(nextStop.lat, nextStop.lon, nextStop.title) : Alert.alert("行程資訊", "今天沒有更多行程囉！")}>
              <View>
                <Text style={styles.cardTitle}>下一站 <Ionicons name="walk" size={14} color="#4E84A7"/></Text>
                {nextStop ? (
                    <View>
                        <Text style={{fontSize: 20, fontWeight: 'bold', color: '#333', marginTop: 5}} numberOfLines={1}>{nextStop.title}</Text>
                        <Text style={{fontSize: 14, color: '#FBC02D', fontWeight: 'bold'}}>{nextStop.time}<Text style={{color:'#999', fontSize:12}}> 預定</Text></Text>
                    </View>
                ) : (<Text style={{color: '#aaa', marginTop: 10}}>今日行程已結束 💤</Text>)}
              </View>
              {nextStop && (<View style={{flexDirection:'row', alignItems:'center', backgroundColor:'#E3F2FD', padding:8, borderRadius:20, alignSelf:'flex-end'}}><Text style={{color:'#4E84A7', fontSize:12, fontWeight:'bold', marginRight:4}}>開始導航</Text><Ionicons name="navigate" size={12} color="#4E84A7"/></View>)}
          </TouchableOpacity>

          <View style={[styles.card, styles.squareCard, {backgroundColor: meetingPoint ? '#FFF3E0' : '#fff'}]}>
              <View style={[styles.cardHeader, {marginBottom: 5}]}>
                <Text style={styles.cardTitle}>{meetingPoint ? "集合中" : "定位分享"}</Text>
                <Switch
                    trackColor={{ false: "#767577", true: "#81b0ff" }}
                    thumbColor={isSharingLocation ? "#4E84A7" : "#f4f3f4"}
                    ios_backgroundColor="#3e3e3e"
                    onValueChange={toggleSharing}
                    value={isSharingLocation}
                    style={{ transform: [{ scaleX: 0.7 }, { scaleY: 0.7 }] }}
                />
              </View>

              {meetingPoint ? (
                  <View style={{flex: 1, justifyContent:'space-between'}}>
                      <TouchableOpacity onPress={handleMeetingCardPress}>
                          <Text style={{fontSize: 12, color: '#666'}}>目標：{meetingPoint.title}</Text>
                          <Text style={{fontSize: 18, fontWeight: 'bold', color: '#FF9800'}}>{meetingPoint.time}</Text>
                          <Text style={{fontSize: 10, color: '#999', marginTop:2}}>點擊管理行程</Text>
                      </TouchableOpacity>
                      <TouchableOpacity 
                          style={{flexDirection:'row', alignItems:'center', backgroundColor:'#FFE0B2', padding:8, borderRadius:20, alignSelf:'flex-end'}}
                          onPress={() => handleNavigate(meetingPoint.lat, meetingPoint.lon, meetingPoint.title)}
                      >
                          <Text style={{color:'#E65100', fontSize:12, fontWeight:'bold', marginRight:4}}>導航</Text>
                          <Ionicons name="navigate" size={12} color="#E65100"/>
                      </TouchableOpacity>
                  </View>
              ) : (
                  <TouchableOpacity style={{flex: 1, justifyContent:'space-between'}} onPress={handleOpenMeetingMap}>
                      <View>
                        <View style={{flexDirection:'row', justifyContent: 'space-between', alignItems: 'center'}}>
                            <Text style={styles.cardSubTitle}>
                                {isSharingLocation ? `目前群組：${activeTrip?.members?.length || 0} 人` : "👻 隱身模式"}
                            </Text>
                        </View>
<View style={{flexDirection:'row', marginTop: 10, gap: -8, opacity: isSharingLocation ? 1 : 0.3}}>
    
    {/* 確保它絕對是一個陣列，才讓它執行 .slice() */}
    {(Array.isArray(activeTrip?.members) ? activeTrip.members : []).slice(0, 3).map((member: any, index: number) => (
        <Image 
            key={index} 
            source={{ uri: member.avatar_url || 'https://via.placeholder.com/150' }}
            style={{width:30, height:30, borderRadius:15, borderWidth:2, borderColor:'#fff', backgroundColor: '#eee'}} 
        />
    ))}

    {/* 確保長度計算不會出錯 */}
    {(Array.isArray(activeTrip?.members) ? activeTrip.members.length : 0) > 3 && (
        <View style={{width:30, height:30, borderRadius:15, backgroundColor:'#888', borderWidth:2, borderColor:'#fff', justifyContent:'center', alignItems:'center'}}>
            <Text style={{color:'#fff', fontSize:10}}>
                +{(activeTrip.members.length) - 3}
            </Text>
        </View>
    )}
</View>
                        <Text style={{fontSize:12, color:'#4E84A7', marginTop:5, fontWeight:'bold'}}>發起集合！</Text>
                      </View>
                  </TouchableOpacity>
              )}
          </View>
        </View>
        
        {/* 翻譯 & 匯率 */}
        <View style={styles.row}>
          <View style={[styles.card, styles.squareCard, {padding: 12, justifyContent:'space-between'}]}>
              <View style={{flexDirection:'row', justifyContent:'space-between', alignItems:'center', marginBottom: 5}}>
                <Text style={styles.cardTitle}>翻譯</Text>
                <TouchableOpacity onPress={() => setTransModalVisible(true)}><Ionicons name="expand-outline" size={16} color="#4E84A7"/></TouchableOpacity>
              </View>
              <View style={{alignItems:'center', justifyContent:'center', flex:1}}>{isListening ? (<View style={{alignItems:'center'}}><ActivityIndicator size="large" color="#F44336"/><Text style={{fontSize:12, color:'#F44336', marginTop:5}}>收聽中...</Text></View>) : (<TouchableOpacity style={{width:60, height:60, borderRadius:30, backgroundColor:'#E3F2FD', alignItems:'center', justifyContent:'center', elevation:2}} onPress={handleCardVoice}><Ionicons name="mic" size={32} color="#4E84A7"/></TouchableOpacity>)}</View>
              <View style={{minHeight:30, justifyContent:'flex-end'}}><Text style={styles.miniTransResult} numberOfLines={2} adjustsFontSizeToFit>{isTranslating ? "翻譯中..." : (transResult || (transInput ? `"${transInput}"` : "點擊說話..."))}</Text></View>
          </View>
          <FunctionCard title={`匯率 (${targetInfo.currency})`} subTitle={exchangeRate ? `1 TWD ≈ ${exchangeRate.toFixed(2)}` : "定位中..."} loading={exchangeRate === null} icon="coins" onPress={() => { setModalVisible(true); setIsSelectingCountry(false); }} style={styles.squareCard} />
        </View>
        <View style={{ height: 100 }} />
      </ScrollView>

      {/* --- 集合地圖 Modal --- */}
      <Modal animationType="slide" transparent={true} visible={meetingModalVisible} onRequestClose={() => setMeetingModalVisible(false)}>
        <View style={styles.modalOverlay}>
            <View style={[styles.modalContent, {width: '90%', height: '80%', padding: 0, overflow: 'hidden'}]}>
                <View style={styles.mapHeader}>
                    <Text style={styles.modalTitle}>📍 設定集合地點</Text>
                    <TouchableOpacity onPress={() => setMeetingModalVisible(false)}><Ionicons name="close-circle" size={30} color="#ccc" /></TouchableOpacity>
                </View>
                
                <View style={{flex: 1, width: '100%'}}>
                    {Platform.OS === 'web' ? (
                        <View style={{flex: 1, justifyContent: 'center', alignItems: 'center', backgroundColor: '#f0f0f0'}}>
                            <Ionicons name="map-outline" size={50} color="#ccc" />
                            <Text style={{color: '#666', marginTop: 10, fontWeight: 'bold'}}>地圖功能僅支援手機版 App</Text>
                            <Text style={{color: '#999', fontSize: 12}}>請使用 iOS/Android 模擬器或實機測試</Text>
                        </View>
                    ) : (
                        <MapView 
    style={{flex: 1}}
    initialRegion={mapRegion}
    provider={PROVIDER_GOOGLE}
    onPress={(e: any) => {
        setTempMeetingCoord(e.nativeEvent.coordinate);
        setTempPlaceName("地圖選點");
    }}
    onPoiClick={(e: any) => {
        setTempMeetingCoord(e.nativeEvent.coordinate);
        setTempPlaceName(e.nativeEvent.name);
    }}
>
    {/* 1. 自己的位置標記 (你原本寫的) */}
    {isSharingLocation && (
        <Marker coordinate={{latitude: mapRegion.latitude, longitude: mapRegion.longitude}} title="我">
            <TouchableOpacity activeOpacity={0.8} onPress={handlePickAvatar}>
                <View style={styles.avatarMarkerContainer}>
                    <Image source={{uri: userAvatar}} style={styles.avatarMarkerImage} />
                </View>
            </TouchableOpacity>
        </Marker>
    )}

    {/* 💡 2. 新增：渲染其他群組成員的即時位置 */}
    {Object.values(othersLocations).map((person: any) => {
        // 避免重複畫出自己 (因為你在 emit 時暫時寫死了 'user_me')
        if (person.userId === 'user_me') return null;
        
        return (
            <Marker
                key={person.userId}
                coordinate={{ latitude: person.latitude, longitude: person.longitude }}
                title={person.userName}
                zIndex={1} // 讓其他人的圖示保持在地圖上層
            >
                <View style={{alignItems: 'center', justifyContent: 'center'}}>
                    {/* 金色邊框的大頭貼 */}
                    <Image 
                        source={{ uri: person.avatar_url }} 
                        style={{width: 40, height: 40, borderRadius: 20, borderWidth: 3, borderColor: '#FFD700', backgroundColor: '#eee'}} 
                    />
                    {/* 名字小標籤 */}
                    <View style={{backgroundColor: 'rgba(0,0,0,0.6)', paddingHorizontal: 6, paddingVertical: 2, borderRadius: 10, marginTop: 2}}>
                        <Text style={{color: '#fff', fontSize: 10, fontWeight: 'bold'}}>{person.userName}</Text>
                    </View>
                </View>
            </Marker>
        );
    })}

    {/* 3. 集合點標記 (你原本寫的) */}
    {tempMeetingCoord && <Marker coordinate={tempMeetingCoord} title={tempPlaceName || "集合點"} pinColor="red" />}
</MapView>
                    )}
                    {Platform.OS !== 'web' && (
                        <View style={styles.mapOverlayInstruction}>
                            <Text style={{color: '#fff', fontWeight: 'bold'}}>請點選地標或任意位置</Text>
                        </View>
                    )}
                </View>

                <View style={styles.mapFooter}>
                    <View style={{alignItems:'center', marginBottom:15}}><Text style={{fontSize:14, color:'#666'}}>📍 已選地點：<Text style={{fontWeight:'bold', color:'#333'}}>{tempPlaceName || "尚未選擇"}</Text></Text></View>
                    <View style={{flexDirection: 'row', alignItems: 'center', marginBottom: 15, justifyContent: 'center'}}>
                        <Text style={{fontSize: 16, fontWeight: 'bold', marginRight: 10}}>集合時間：</Text>
                        
                        <View style={styles.pickerColumn}>
                            <ScrollView showsVerticalScrollIndicator={false}>
                                {HOURS.map(h => (
                                    <TouchableOpacity 
                                        key={h} 
                                        onPress={() => setSelectedHour(h)}
                                        style={[styles.pickerItem, selectedHour === h && styles.pickerItemSelected]}
                                    >
                                        <Text style={[styles.pickerText, selectedHour === h && styles.pickerTextSelected]}>{h}</Text>
                                    </TouchableOpacity>
                                ))}
                            </ScrollView>
                        </View>

                        <Text style={{fontSize: 20, fontWeight: 'bold', marginHorizontal: 5}}>:</Text>

                        <View style={styles.pickerColumn}>
                            <ScrollView showsVerticalScrollIndicator={false}>
                                {MINUTES.map(m => (
                                    <TouchableOpacity 
                                        key={m} 
                                        onPress={() => setSelectedMinute(m)}
                                        style={[styles.pickerItem, selectedMinute === m && styles.pickerItemSelected]}
                                    >
                                        <Text style={[styles.pickerText, selectedMinute === m && styles.pickerTextSelected]}>{m}</Text>
                                    </TouchableOpacity>
                                ))}
                            </ScrollView>
                        </View>
                    </View>
                    <TouchableOpacity style={styles.confirmBtn} onPress={handleConfirmMeeting}>
                        <Text style={styles.confirmBtnText}>確認發起集合</Text>
                    </TouchableOpacity>
                </View>
            </View>
        </View>
      </Modal>

      {/* --- 天氣 Modal --- */}
      <Modal animationType="fade" transparent={true} visible={weatherModalVisible} onRequestClose={() => setWeatherModalVisible(false)}>
        <View style={styles.modalOverlay}>
          <View style={[styles.modalContent, { width: '90%', height: '70%', alignItems: 'stretch', padding: 0 }]}>
              <View style={{ flex: 1, padding: 20 }}>
              {isSelectingCity ? (
                <View style={{ flex: 1 }}>
                  <View style={styles.weatherModalHeader}>
                      <Text style={styles.modalTitle}>🔍 搜尋城市</Text>
                      <TouchableOpacity onPress={() => setIsSelectingCity(false)}><Ionicons name="close-circle" size={30} color="#ccc" /></TouchableOpacity>
                  </View>
                  <View style={styles.inputContainer}>
                      <TextInput style={[styles.input, {textAlign: 'left'}]} placeholder="輸入城市 (ex: Taipei)" value={citySearchText} onChangeText={setCitySearchText}/>
                      <TouchableOpacity onPress={() => fetchWeatherByName(citySearchText)}><Ionicons name="search" size={24} color="#4E84A7" /></TouchableOpacity>
                  </View>
                  <TouchableOpacity style={styles.myLocationButton} onPress={handleCurrentLocation}>
                    <Ionicons name="navigate-circle" size={20} color="#fff" />
                    <Text style={styles.myLocationText}>使用當前位置</Text>
                  </TouchableOpacity>
                  <Text style={{marginTop: 20, marginBottom: 10, fontWeight: 'bold', color: '#666'}}>熱門城市</Text>
                  <View style={{flexDirection: 'row', flexWrap: 'wrap', gap: 10}}>
                      {POPULAR_CITIES.map((city) => (<TouchableOpacity key={city.query} style={styles.cityChip} onPress={() => fetchWeatherByName(city.query)}><Text style={styles.cityChipText}>{city.name}</Text></TouchableOpacity>))}
                  </View>
                </View>
              ) : (
                <ScrollView style={{ flex: 1 }} showsVerticalScrollIndicator={false}>
                  <View style={styles.weatherModalHeader}>
                      <View>
                          <View style={{flexDirection:'row', alignItems:'center', gap: 5}}>
                            <Text style={styles.weatherCityName}><Ionicons name="location-sharp" size={18}/> {weatherData.locationName}</Text>
                            <TouchableOpacity style={styles.switchButton} onPress={() => setIsSelectingCity(true)}><Text style={styles.switchButtonText}>切換地點</Text></TouchableOpacity>
                          </View>
                          <Text style={styles.weatherDescBig}>{weatherData.desc}</Text>
                      </View>
                      <TouchableOpacity onPress={() => setWeatherModalVisible(false)}><Ionicons name="close-circle" size={30} color="#ccc" /></TouchableOpacity>
                  </View>
                  <View style={styles.weatherMainDisplay}><FontAwesome5 name={weatherData.icon as any} size={60} color="#FBC02D" /><Text style={styles.weatherTempBig}>{weatherData.temp}°</Text></View>
                  <Text style={styles.weatherHighLow}>最高 {weatherData.tempMax}° / 最低 {weatherData.tempMin}°</Text>
                  <View style={styles.divider} />
                  {weatherData.hourly.length > 0 && (<View style={{ width: '100%', minHeight: 100 }}><Text style={styles.subHeaderTitle}>🕰️ 24小時預報</Text><ScrollView horizontal showsHorizontalScrollIndicator={false} style={{marginBottom: 20}}>{weatherData.hourly.map((item, index) => (<View key={index} style={styles.hourlyItem}><Text style={styles.hourlyTime}>{item.time}</Text><FontAwesome5 name={item.icon as any} size={20} color="#4E84A7" style={{marginVertical: 8}}/><Text style={styles.hourlyTemp}>{item.temp}°</Text></View>))}</ScrollView></View>)}
                  {weatherData.daily.length > 0 && (<View style={{ width: '100%' }}><Text style={styles.subHeaderTitle}>📅 未來預報</Text><View style={styles.dailyListContainer}>{weatherData.daily.map((item, index) => (<View key={index} style={styles.dailyRow}><Text style={styles.dailyDay}>{item.day}</Text><FontAwesome5 name={item.icon as any} size={16} color="#4E84A7" /><View style={styles.dailyTempBar}><Text style={styles.dailyTempText}>{item.min}°</Text><View style={styles.tempBarLine} /><Text style={styles.dailyTempText}>{item.max}°</Text></View></View>))}</View></View>)}
                  <Text style={styles.subHeaderTitle}>📊 詳細資訊</Text>
                  <View style={styles.weatherDetailGrid}><WeatherDetailItem icon="temperature-high" label="體感" value={`${weatherData.feelsLike}°`} /><WeatherDetailItem icon="water" label="濕度" value={`${weatherData.humidity}%`} iconLib="MaterialCommunityIcons"/><WeatherDetailItem icon="wind" label="風速" value={`${weatherData.windSpeed} m/s`} /><WeatherDetailItem icon="gauge" label="氣壓" value={`${weatherData.pressure} hPa`} iconLib="MaterialCommunityIcons"/><WeatherDetailItem icon="sun" label="日出" value={weatherData.sunrise} /><WeatherDetailItem icon="moon" label="日落" value={weatherData.sunset} /><WeatherDetailItem icon="sun" label="紫外線" value="N/A" /></View>
                  <View style={{ height: 40 }} /> 
                </ScrollView>
              )}
              </View>
          </View>
        </View>
      </Modal>

      {/* --- 匯率 Modal --- */}
      <Modal animationType="slide" transparent={true} visible={modalVisible} onRequestClose={() => setModalVisible(false)}>
        <View style={styles.modalOverlay}>
          <View style={styles.modalContent}>
            <View style={styles.modalHeader}>
              <Text style={styles.modalTitle}>{isSelectingCountry ? "🌏 選擇國家" : "💱 匯率換算"}</Text>
              <TouchableOpacity onPress={() => setModalVisible(false)}><Ionicons name="close-circle" size={30} color="#ccc" /></TouchableOpacity>
            </View>
            {isSelectingCountry ? (
              <View style={styles.countryListContainer}>
                <ScrollView style={{width: '100%'}}>{SUPPORTED_CURRENCIES.map((item) => (<TouchableOpacity key={item.code} style={styles.countryItem} onPress={() => handleCountrySelect(item)}><Text style={{fontSize: 24}}>{item.flag}</Text><Text style={styles.countryName}>{item.name} ({item.currency})</Text>{targetInfo.code === item.code && <Ionicons name="checkmark" size={20} color="#4E84A7" />}</TouchableOpacity>))}</ScrollView>
                <TouchableOpacity style={styles.backButton} onPress={() => setIsSelectingCountry(false)}><Text style={styles.backButtonText}>返回計算機</Text></TouchableOpacity>
              </View>
            ) : (
              <View style={{width:'100%'}}>
                <View style={styles.locationRow}><Text style={styles.modalLabel}>當前匯率：{targetInfo.flag} {targetInfo.name}</Text><TouchableOpacity style={styles.switchButton} onPress={() => setIsSelectingCountry(true)}><Text style={styles.switchButtonText}>切換</Text></TouchableOpacity></View>
                <View style={styles.inputContainer}><Text style={styles.currencyLabel}>TWD</Text><TextInput style={styles.input} placeholder="輸入台幣" keyboardType="numeric" value={twdValue} onChangeText={handleTwdChange}/></View>
                <View style={styles.arrowContainer}><FontAwesome5 name="exchange-alt" size={20} color="#4E84A7" /></View>
                <View style={[styles.resultContainer, {backgroundColor: '#E8EAF6'}]}><Text style={styles.currencyLabel}>{targetInfo.currency}</Text><TextInput style={[styles.input, {color: '#1A237E'}]} placeholder="輸入外幣" keyboardType="numeric" value={foreignValue} onChangeText={handleForeignChange} placeholderTextColor="#9FA8DA"/></View>
                <Text style={styles.rateHint}>1 TWD ≈ {exchangeRate?.toFixed(3)} {targetInfo.currency}</Text>
              </View>
            )}
          </View>
        </View>
      </Modal>

      {/* --- 翻譯 Modal --- */}
      <Modal animationType="slide" transparent={true} visible={transModalVisible} onRequestClose={() => setTransModalVisible(false)}>
        <View style={[styles.modalOverlay, {justifyContent: 'flex-end', backgroundColor: 'rgba(0,0,0,0.5)'}]}>
          <View style={[styles.modalContent, {width: '100%', height: '90%', borderRadius: 0, borderTopLeftRadius: 20, borderTopRightRadius: 20, padding: 0}]}>
            <View style={styles.transHeader}>
                <TouchableOpacity onPress={() => setTransModalVisible(false)} style={{padding: 10}}><Ionicons name="close" size={24} color="#fff"/></TouchableOpacity>
                <View style={styles.langSelector}>
                    <TouchableOpacity onPress={() => setIsSelectingTransLang('source')} style={styles.langBtn}><Text style={styles.langText}>{sourceLang.name}</Text><Ionicons name="caret-down" color="#fff" size={12}/></TouchableOpacity>
                    <TouchableOpacity onPress={handleSwapLanguages} style={{paddingHorizontal: 15}}><Ionicons name="swap-horizontal" color="#fff" size={24}/></TouchableOpacity>
                    <TouchableOpacity onPress={() => setIsSelectingTransLang('target')} style={styles.langBtn}><Text style={styles.langText}>{targetLang.name}</Text><Ionicons name="caret-down" color="#fff" size={12}/></TouchableOpacity>
                </View>
                <View style={{width: 40}}/>
            </View>
            {isSelectingTransLang && (<View style={styles.langListContainer}><Text style={{padding: 15, fontWeight: 'bold', color: '#666'}}>選擇語言</Text><ScrollView>{LANGUAGES.map(lang => (<TouchableOpacity key={lang.code} style={styles.langItem} onPress={() => selectTransLang(lang)}><Text style={{fontSize: 16}}>{lang.name}</Text>{(isSelectingTransLang === 'source' ? sourceLang.code : targetLang.code) === lang.code && <Ionicons name="checkmark" size={20} color="#4E84A7"/>}</TouchableOpacity>))}</ScrollView><TouchableOpacity style={styles.closeLangBtn} onPress={() => setIsSelectingTransLang(null)}><Text style={{color: '#fff'}}>取消</Text></TouchableOpacity></View>)}
            <View style={{flex: 1, padding: 20, gap: 20}}>
                <View style={styles.transBox}><TextInput style={styles.transInput} placeholder="輸入文字..." multiline value={transInput} onChangeText={setTransInput}/>{transInput.length > 0 && (<TouchableOpacity style={{alignSelf: 'flex-end'}} onPress={() => setTransInput('')}><Ionicons name="close-circle" size={20} color="#ccc" /></TouchableOpacity>)}</View>
                <View style={[styles.transBox, {backgroundColor: '#E3F2FD', flex: 1}]}>{isTranslating ? (<ActivityIndicator color="#4E84A7" style={{marginTop: 20}} />) : (<View><View style={{flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center'}}><Text style={styles.transLabel}>{targetLang.name}</Text><TouchableOpacity onPress={handleCopyResult}><Ionicons name="copy-outline" size={18} color="#4E84A7"/></TouchableOpacity></View><Text style={styles.transResultText}>{transResult}</Text></View>)}</View>
                {capturedImage && (<View style={{height: 100, width: 100, marginBottom: 10}}><Image source={{uri: capturedImage}} style={{width: '100%', height: '100%', borderRadius: 10}} /><TouchableOpacity style={{position:'absolute', right:-5, top:-5, backgroundColor:'red', borderRadius:10}} onPress={() => setCapturedImage(null)}><Ionicons name="close-circle" color="#fff" size={20}/></TouchableOpacity></View>)}
            </View>
            <View style={styles.transBottomBar}><TouchableOpacity style={styles.toolBtn} onPress={handleCamera}><View style={styles.toolIconCircle}><Ionicons name="camera" size={24} color="#4E84A7"/></View><Text style={styles.toolText}>相機</Text></TouchableOpacity><TouchableOpacity style={styles.toolBtn} onPress={handleVoice}><View style={styles.toolIconCircle}><Ionicons name="mic" size={24} color="#4E84A7"/></View><Text style={styles.toolText}>語音</Text></TouchableOpacity></View>
          </View>
        </View>
      </Modal>

{/* 📝 LightSplit 專業記帳彈窗 (雙分頁切換版) */}
      <Modal visible={isExpenseModalVisible} animationType="slide" transparent={true}>
        <View style={{ flex: 1, backgroundColor: 'rgba(0,0,0,0.5)', justifyContent: 'flex-end' }}>
          <View style={{ backgroundColor: '#FFF', borderTopLeftRadius: 25, borderTopRightRadius: 25, padding: 20, height: '85%' }}>
            
            {/* 頂部控制列：Tab 切換與關閉按鈕 */}
            <View style={{ flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', marginBottom: 15 }}>
              <View style={{ flexDirection: 'row', gap: 15 }}>
                <TouchableOpacity onPress={() => setActiveTab('add')} style={{ borderBottomWidth: activeTab === 'add' ? 3 : 0, borderColor: '#4ECDC4', paddingBottom: 5 }}>
                  <Text style={{ fontSize: 20, fontWeight: 'bold', color: activeTab === 'add' ? '#333' : '#CCC' }}>
                    {editingExpenseId ? '✏️ 編輯花費' : '✍️ 記一筆'}
                  </Text>
                </TouchableOpacity>
                <TouchableOpacity onPress={() => setActiveTab('records')} style={{ borderBottomWidth: activeTab === 'records' ? 3 : 0, borderColor: '#4ECDC4', paddingBottom: 5 }}>
                  <Text style={{ fontSize: 20, fontWeight: 'bold', color: activeTab === 'records' ? '#333' : '#CCC' }}>
                    📋 記帳紀錄
                  </Text>
                </TouchableOpacity>
              </View>
              <TouchableOpacity onPress={() => { setExpenseModalVisible(false); resetExpenseForm(); }}>
                <Ionicons name="close-circle" size={32} color="#CCC" />
              </TouchableOpacity>
            </View>

            {/* 根據 Tab 切換顯示內容 */}
            {activeTab === 'records' ? (
              <ScrollView showsVerticalScrollIndicator={false}>
                {expenses.length === 0 ? (
                  <Text style={{ textAlign: 'center', color: '#999', marginTop: 50 }}>目前還沒有任何記帳紀錄喔！</Text>
                ) : (
                  expenses.map((exp: any) => (
                    <View key={exp.id} style={{ backgroundColor: '#F9F9F9', padding: 15, borderRadius: 15, marginBottom: 10, flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center' }}>
                      <View style={{ flex: 1 }}>
                        <Text style={{ fontSize: 16, fontWeight: 'bold', color: '#333' }}>{exp.title}</Text>
                        <Text style={{ fontSize: 12, color: '#888', marginTop: 5 }}>{exp.payer_name} 先付了 ${Number(exp.amount)}</Text>
                      </View>
                      <View style={{ flexDirection: 'row', gap: 10 }}>
                        <TouchableOpacity onPress={() => handleEditExpense(exp)} style={{ backgroundColor: '#E3F2FD', padding: 10, borderRadius: 10 }}>
                          <Ionicons name="pencil" size={18} color="#4E84A7" />
                        </TouchableOpacity>
                        <TouchableOpacity onPress={() => handleDeleteExpense(exp.id)} style={{ backgroundColor: '#FFEBEE', padding: 10, borderRadius: 10 }}>
                          <Ionicons name="trash" size={18} color="#FF5252" />
                        </TouchableOpacity>
                      </View>
                    </View>
                  ))
                )}
              </ScrollView>
            ) : (
              <>
                <ScrollView showsVerticalScrollIndicator={false}>
                  {/* 1. 品項輸入 */}
                  <View style={{ flexDirection: 'row', alignItems: 'center', backgroundColor: '#F5F5F5', borderRadius: 10, paddingHorizontal: 15, marginBottom: 15 }}>
                    <FontAwesome5 name="shopping-bag" size={18} color="#FFB300" />
                    <TextInput placeholder="品項" style={{ flex: 1, padding: 15, fontSize: 16 }} value={newExpenseTitle} onChangeText={setNewExpenseTitle} />
                  </View>

                  {/* 2. 金額輸入 */}
                  <View style={{ flexDirection: 'row', alignItems: 'center', backgroundColor: '#F5F5F5', borderRadius: 10, paddingHorizontal: 15, marginBottom: 15 }}>
                    <Text style={{ fontWeight: 'bold', color: '#666' }}>TWD (NT$)</Text>
                    <TextInput placeholder="金額" keyboardType="numeric" style={{ flex: 1, padding: 15, fontSize: 16, fontWeight: 'bold' }} value={newExpenseAmount} onChangeText={setNewExpenseAmount} />
                  </View>

                  {/* 3. 誰先付錢 */}
                  <Text style={{ marginBottom: 8, color: '#666', fontSize: 14 }}>誰先付錢</Text>
                  <View style={{ backgroundColor: '#F5F5F5', borderRadius: 10, marginBottom: 15 }}>
                    <View style={{ flexDirection: 'row', alignItems: 'center', padding: 5 }}>
                      <Image source={{ uri: userAvatar }} style={{ width: 30, height: 30, borderRadius: 15, marginLeft: 10 }} />
                      <View style={{ flex: 1 }}>
                        <ScrollView horizontal showsHorizontalScrollIndicator={false}>
                          {(activeTrip.members || []).map((m: any, idx: number) => (
                            <TouchableOpacity key={idx} onPress={() => setSelectedPayer(m.user_name)} style={{ paddingHorizontal: 15, paddingVertical: 10, backgroundColor: selectedPayer === m.user_name ? '#4ECDC4' : 'transparent', borderRadius: 20 }}>
                              <Text style={{ color: selectedPayer === m.user_name ? '#FFF' : '#333' }}>{m.user_name}</Text>
                            </TouchableOpacity>
                          ))}
                        </ScrollView>
                      </View>
                    </View>
                  </View>

                  {/* 4. 如何分 */}
                  <View style={{ marginBottom: 10, flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center' }}>
                    <Text style={{ fontWeight: 'bold', color: '#666', fontSize: 14 }}>如何分</Text>
                    <TouchableOpacity onPress={() => setSplitMode(splitMode === 'equal' ? 'custom' : 'equal')}>
                      <Text style={{ color: '#4ECDC4', fontSize: 12 }}>{splitMode === 'equal' ? '⚡ 切換自訂金額' : '👫 切換平均分攤'}</Text>
                    </TouchableOpacity>
                  </View>

                  <View style={{ backgroundColor: '#F9F9F9', borderRadius: 15, padding: 10, marginBottom: 15 }}>
                    {participants.map((item: any, index: number) => (
                      <View key={index} style={{ flexDirection: 'row', alignItems: 'center', paddingVertical: 10, borderBottomWidth: 1, borderBottomColor: '#EEE' }}>
                        <TouchableOpacity onPress={() => { const updated = [...participants]; updated[index].selected = !updated[index].selected; setParticipants(updated); }}>
                          <Ionicons name={item.selected ? "checkbox" : "square-outline"} size={24} color={item.selected ? "#4ECDC4" : "#CCC"} />
                        </TouchableOpacity>
                        <Text style={{ flex: 1, marginLeft: 10 }}>{item.name}</Text>
                        <View style={{ flexDirection: 'row', alignItems: 'center', width: 120, justifyContent: 'flex-end' }}>
                          <Text style={{ fontSize: 12, color: '#999', marginRight: 5 }}>NT$</Text>
                          {splitMode === 'equal' ? (
                            <Text style={{ color: item.selected ? '#333' : '#CCC', fontWeight: 'bold' }}>{item.selected ? getSplitAmount(index) : 0}</Text>
                          ) : (
                            <TextInput keyboardType="numeric" placeholder="0" style={{ backgroundColor: item.selected ? '#FFF' : '#F0F0F0', borderWidth: 1, borderColor: '#DDD', borderRadius: 5, width: 80, padding: 5, textAlign: 'right' }} editable={item.selected} value={item.amount ? item.amount.toString() : ''} onChangeText={(val) => { const updated = [...participants]; updated[index].amount = parseFloat(val) || 0; setParticipants(updated); }} />
                          )}
                        </View>
                      </View>
                    ))}
                    {splitMode === 'custom' && (
                      <View style={{ marginTop: 10, alignItems: 'flex-end' }}>
                        <Text style={{ fontSize: 12, color: participants.reduce((sum: number, p: any) => sum + (p.amount || 0), 0) === Number(newExpenseAmount) ? '#4ECDC4' : '#FF6B6B' }}>
                          目前小計: ${participants.reduce((sum: number, p: any) => sum + (p.amount || 0), 0)} / 總額: ${newExpenseAmount || 0}
                        </Text>
                      </View>
                    )}
                  </View>

                  {/* 5. 備註 */}
                  <TextInput placeholder="備註" multiline style={{ backgroundColor: '#F5F5F5', padding: 15, borderRadius: 10, height: 100, textAlignVertical: 'top' }} value={expenseNote} onChangeText={setExpenseNote} />
                </ScrollView>

                {/* 底部按鈕：自動判斷是新增還是更新 */}
                <TouchableOpacity 
                  onPress={async () => {
                    if (!newExpenseTitle || !newExpenseAmount) return Alert.alert("提示", "請輸入內容");
                    
                    const selectedCount = participants.filter((p: any) => p.selected).length;
                    const equalAmt = selectedCount > 0 ? (Number(newExpenseAmount) / selectedCount) : 0;

                    const finalParticipants = participants
                      .filter((p: any) => p.selected)
                      .map((p: any) => ({
                        name: p.name,
                        amount: splitMode === 'equal' ? equalAmt : Number(p.amount)
                      }));

                    const payload = {
                      trip_id: activeTrip.id,
                      title: newExpenseTitle,
                      amount: parseInt(newExpenseAmount),
                      payer_name: selectedPayer, 
                      note: expenseNote,
                      participants: finalParticipants
                    };

                    const url = editingExpenseId 
                      ? `http://172.20.112.231:3000/api/trips/${activeTrip.id}/expenses/${editingExpenseId}`
                      : `http://172.20.112.231:3000/api/trips/${activeTrip.id}/expenses`;
                    const method = editingExpenseId ? 'PUT' : 'POST';

                    const response = await fetch(url, {
                      method: method,
                      headers: { 'Content-Type': 'application/json' },
                      body: JSON.stringify(payload)
                    });

                    if (response.ok) {
                      fetchExpenses();
                      resetExpenseForm(); 
                      setActiveTab('records'); 
                    }
                  }}
                  style={{ backgroundColor: editingExpenseId ? '#FFA726' : '#4ECDC4', padding: 18, borderRadius: 15, alignItems: 'center', marginTop: 15 }}
                >
                  <Text style={{ color: '#FFF', fontWeight: 'bold', fontSize: 18 }}>
                    {editingExpenseId ? '儲存修改' : '新增'}
                  </Text>
                </TouchableOpacity>
              </>
            )}

          </View>
        </View>
      </Modal>

    </View>
    
)}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#F2F9FF' },
  topHeader: { paddingTop: 60, paddingBottom: 15, alignItems: 'center', backgroundColor: '#F2F9FF' },
  topHeaderText: { fontSize: 24, fontWeight: 'bold', color: '#333' },
  content: { padding: 15 },
  row: { flexDirection: 'row', justifyContent: 'space-between', gap: 10, marginBottom: 15 },
  card: { backgroundColor: '#fff', borderRadius: 20, padding: 15, shadowColor: '#000', shadowOpacity: 0.05, elevation: 2 },
  weatherCardWide: { flex: 2, backgroundColor: '#1A1A2E', padding: 15, justifyContent: 'space-between', minHeight: 160 },
  weatherCardLocation: { color: '#fff', fontSize: 14, fontWeight: 'bold' },
  weatherCardDesc: { color: '#ccc', fontSize: 12 },
  weatherCardTempBig: { color: '#fff', fontSize: 42, fontWeight: 'bold', lineHeight: 45 },
  weatherCardHighLow: { color: '#aaa', fontSize: 11, marginTop: 2 },
  weatherCardDivider: { height: 1, backgroundColor: 'rgba(255,255,255,0.2)', marginVertical: 8 },
  
  smallCard: { width: (width - 45) / 2 },
  largeCard: { width: '100%' }, 
  squareCard: { width: (width - 45) / 2, aspectRatio: 1, justifyContent: 'space-between', paddingVertical: 20 },
  cardHeader: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', marginBottom: 5 },
  cardTitle: { fontSize: 18, fontWeight: 'bold', color: '#000' },
  cardSubTitle: { fontSize: 12, color: '#4E84A7' },
  weatherCard: { width: (width - 45) / 2, backgroundColor: '#1A237E', justifyContent: 'center' },
  weatherTemp: { fontSize: 32, color: '#fff', fontWeight: 'bold' },
  weatherInfo: { color: '#ddd', fontSize: 13 },
  sectionCard: { backgroundColor: '#D4E9F7', borderRadius: 20, padding: 15, marginBottom: 15 },
  sectionTitle: { fontSize: 18, fontWeight: 'bold', marginBottom: 10, color:'#333' },
  iconRow: { flexDirection: 'row', justifyContent: 'space-between' },
  transportIcon: { backgroundColor: '#fff', width: 55, height: 55, borderRadius: 16, justifyContent: 'center', alignItems: 'center', shadowColor: '#000', shadowOpacity: 0.1, elevation: 2 },
  iconText: { color: '#4E84A7', fontSize: 11, fontWeight: 'bold' },
  sectionContainer: { marginBottom: 20 },
  spotCard: { height: 220, borderRadius: 15, backgroundColor: '#fff', shadowColor: '#000', shadowOpacity: 0.1, elevation: 4, overflow: 'hidden' },
  spotImage: { flex: 1, justifyContent: 'flex-end' },
  spotOverlay: { padding: 15, backgroundColor: 'rgba(0,0,0,0.5)' },
  spotTitle: { color: '#fff', fontWeight: 'bold', fontSize: 18, marginBottom: 4 },
  spotAddress: { color: '#ddd', fontSize: 12 },
  spotRating: { flexDirection: 'row', alignItems: 'center', backgroundColor: 'rgba(0,0,0,0.6)', paddingHorizontal: 8, paddingVertical: 4, borderRadius: 10 },
  spotRatingText: { color: '#FFD700', fontSize: 14, fontWeight: 'bold', marginLeft: 4 },
  navButton: { flexDirection:'row', alignItems:'center', gap:5, marginTop: 10, alignSelf: 'flex-start', backgroundColor: '#4E84A7', paddingHorizontal: 10, paddingVertical: 5, borderRadius: 20 },
  modalOverlay: { flex: 1, backgroundColor: 'rgba(0,0,0,0.5)', justifyContent: 'center', alignItems: 'center' },
  modalContent: { width: '85%', maxHeight: '85%', backgroundColor: '#fff', borderRadius: 20, padding: 25, alignItems: 'center', elevation: 5 },
  modalHeader: { width: '100%', flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', marginBottom: 20 },
  modalTitle: { fontSize: 20, fontWeight: 'bold', color: '#333' },
  weatherModalHeader: { width: '100%', flexDirection: 'row', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: 20 },
  weatherCityName: { fontSize: 18, fontWeight: 'bold', color: '#333', marginBottom: 4 },
  switchButton: { backgroundColor: '#E3F2FD', paddingHorizontal: 12, paddingVertical: 6, borderRadius: 15, marginLeft: 10 },
  switchButtonText: { color: '#4E84A7', fontSize: 12, fontWeight: 'bold' },
  weatherDescBig: { fontSize: 14, color: '#666' },
  weatherMainDisplay: { flexDirection: 'row', alignItems: 'center', gap: 20, marginBottom: 10 },
  weatherTempBig: { fontSize: 64, fontWeight: 'bold', color: '#333' },
  weatherHighLow: { fontSize: 14, color: '#888', marginBottom: 20 },
  divider: { height: 1, backgroundColor: '#eee', width: '100%', marginBottom: 15 },
  subHeaderTitle: { fontSize: 16, fontWeight: 'bold', color: '#333', marginBottom: 10, marginTop: 5 },
  hourlyItem: { alignItems: 'center', backgroundColor: '#F5F9FF', borderRadius: 12, padding: 10, marginRight: 10, width: 70 },
  hourlyTime: { fontSize: 12, color: '#666' },
  hourlyTemp: { fontSize: 16, fontWeight: 'bold', color: '#333' },
  dailyListContainer: { backgroundColor: '#F5F9FF', borderRadius: 12, padding: 15, marginBottom: 20 },
  dailyRow: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', marginBottom: 12 },
  dailyDay: { width: 50, fontSize: 14, fontWeight: 'bold', color: '#333' },
  dailyTempBar: { flexDirection: 'row', alignItems: 'center', width: 100, justifyContent: 'flex-end' },
  dailyTempText: { width: 30, textAlign: 'center', fontSize: 14, color: '#555' },
  tempBarLine: { width: 30, height: 3, backgroundColor: '#ddd', marginHorizontal: 5, borderRadius: 2 },
  weatherDetailGrid: { flexDirection: 'row', flexWrap: 'wrap', justifyContent: 'space-between', width: '100%' },
  weatherDetailItem: { width: '48%', backgroundColor: '#F5F9FF', borderRadius: 12, padding: 15, marginBottom: 15, alignItems: 'center' },
  weatherIconCircle: { width: 40, height: 40, borderRadius: 20, backgroundColor: '#fff', alignItems: 'center', justifyContent: 'center', marginBottom: 8 },
  weatherDetailLabel: { fontSize: 12, color: '#888', marginBottom: 2 },
  weatherDetailValue: { fontSize: 16, fontWeight: 'bold', color: '#333' },
  inputContainer: { flexDirection: 'row', alignItems: 'center', backgroundColor: '#F0F0F0', borderRadius: 12, paddingHorizontal: 15, height: 50, width: '100%' },
  input: { flex: 1, fontSize: 16, color: '#333' },
  myLocationButton: { flexDirection: 'row', alignItems: 'center', justifyContent: 'center', backgroundColor: '#4E84A7', paddingVertical: 12, borderRadius: 12, marginTop: 15, gap: 8, width: '100%', marginBottom: 20 },
  myLocationText: { color: '#fff', fontWeight: 'bold', fontSize: 16 },
  cityChip: { backgroundColor: '#E3F2FD', paddingHorizontal: 15, paddingVertical: 8, borderRadius: 20, marginBottom: 10 },
  cityChipText: { color: '#4E84A7', fontWeight: 'bold' },
  locationRow: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', width: '100%', marginBottom: 15 },
  modalLabel: { fontSize: 16, color: '#333', fontWeight: '500' },
  currencyLabel: { fontSize: 18, fontWeight: 'bold', color: '#555' },
  arrowContainer: { marginVertical: 10 },
  resultContainer: { flexDirection: 'row', alignItems: 'center', backgroundColor: '#E8EAF6', borderRadius: 12, paddingHorizontal: 15, height: 50, width: '100%' },
  rateHint: { marginTop: 15, fontSize: 12, color: '#999' },
  countryListContainer: { width: '100%', height: 300 },
  countryItem: { flexDirection: 'row', alignItems: 'center', paddingVertical: 15, borderBottomWidth: 1, borderBottomColor: '#f0f0f0' },
  countryName: { flex: 1, fontSize: 16, marginLeft: 10, color: '#333' },
  backButton: { marginTop: 15, padding: 12, backgroundColor: '#eee', borderRadius: 10, alignItems: 'center' },
  backButtonText: { color: '#666' },
  transHeader: { flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', backgroundColor: '#4285F4', paddingVertical: 15, paddingTop: 20 },
  langSelector: { flexDirection: 'row', alignItems: 'center', gap: 15 },
  langBtn: { flexDirection: 'row', alignItems: 'center', gap: 5 },
  langText: { color: '#fff', fontSize: 16, fontWeight: 'bold' },
  transBox: { backgroundColor: '#fff', borderRadius: 10, padding: 15, borderColor: '#eee', borderWidth: 1 },
  transInput: { fontSize: 22, color: '#333', textAlignVertical: 'top', minHeight: 80 },
  transLabel: { fontSize: 12, color: '#4285F4', marginBottom: 5, fontWeight: 'bold' },
  transResultText: { fontSize: 24, fontWeight: 'bold', color: '#333' },
  transBottomBar: { flexDirection: 'row', justifyContent: 'space-around', alignItems: 'center', padding: 20, borderTopWidth: 1, borderTopColor: '#eee', backgroundColor: '#fff' },
  toolBtn: { alignItems: 'center', gap: 5 },
  toolIconCircle: { width: 50, height: 50, borderRadius: 25, backgroundColor: '#E3F2FD', justifyContent: 'center', alignItems: 'center' },
  toolText: { fontSize: 12, color: '#666' },
  translateMainBtn: { backgroundColor: '#4285F4', paddingHorizontal: 40, paddingVertical: 15, borderRadius: 30, elevation: 5 },
  langListContainer: { position: 'absolute', top: 60, left: 0, right: 0, bottom: 0, backgroundColor: '#fff', zIndex: 10 },
  langItem: { flexDirection: 'row', justifyContent: 'space-between', padding: 15, borderBottomWidth: 1, borderBottomColor: '#eee' },
  closeLangBtn: { backgroundColor: '#4285F4', padding: 15, alignItems: 'center' },
  miniTransInput: { flex: 1, fontSize: 14, color: '#333', textAlignVertical: 'top', padding: 0 },
  miniTransResult: { fontSize: 16, fontWeight: 'bold', color: '#1A237E' },
  mapHeader: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', padding: 20, backgroundColor: '#fff', borderBottomWidth: 1, borderBottomColor: '#eee' },
  mapOverlayInstruction: { position: 'absolute', top: 20, alignSelf: 'center', backgroundColor: 'rgba(0,0,0,0.6)', paddingHorizontal: 20, paddingVertical: 10, borderRadius: 20 },
  mapFooter: { padding: 20, backgroundColor: '#fff', borderTopWidth: 1, borderTopColor: '#eee' },
  timeInput: { backgroundColor: '#f0f0f0', borderRadius: 10, paddingHorizontal: 15, paddingVertical: 8, minWidth: 100, fontSize: 16 },
  confirmBtn: { backgroundColor: '#FF9800', paddingVertical: 15, borderRadius: 12, alignItems: 'center', marginTop: 10 },
  confirmBtnText: { color: '#fff', fontSize: 18, fontWeight: 'bold' },
  avatarMarkerContainer: { borderWidth: 2, borderColor: '#fff', borderRadius: 20, overflow: 'hidden' },
  avatarMarkerImage: { width: 40, height: 40 },
  pickerColumn: { height: 100, width: 60, backgroundColor: '#f0f0f0', borderRadius: 10, overflow: 'hidden', alignItems: 'center' },
  pickerItem: { height: 40, justifyContent: 'center', alignItems: 'center', width: '100%' },
  pickerItemSelected: { backgroundColor: '#E3F2FD' },
  pickerText: { fontSize: 16, color: '#ccc' },
  pickerTextSelected: { fontSize: 20, fontWeight: 'bold', color: '#4E84A7' },
accountingCardSmall: {
  flex: 1,
  backgroundColor: '#D4E9F7',
  borderRadius: 25,
  padding: 18,
  minHeight: 165,
  justifyContent: 'space-between',
  elevation: 3,
},
accountingTitle: {
  fontSize: 22,
  fontWeight: 'bold',
  color: '#000',
},
accountingLabel: {
  fontSize: 14,
  color: '#333',
  marginTop: 4,
},
recordButton: {
  backgroundColor: '#FFF',
  borderRadius: 25,
  flexDirection: 'row',
  alignItems: 'center',
  justifyContent: 'center',
  paddingVertical: 10,
  width: '100%',
},
recordButtonText: {
  color: '#4E84A7',
  fontWeight: 'bold',
  marginLeft: 4,
},
});
