import { Feather, Ionicons, MaterialCommunityIcons, SimpleLineIcons } from '@expo/vector-icons';
import { useRouter } from 'expo-router';
import React from 'react';
import { Alert, Dimensions, Image, SafeAreaView, StyleSheet, Text, TouchableOpacity, View } from 'react-native';

const { width } = Dimensions.get('window');

export default function SettingsScreen() {
  const router = useRouter();

  const menuItems = [
    {
      id: 1,
      title: '管理帳號',
      icon: <Ionicons name="person-circle-outline" size={28} color="#8BA0B2" />,
      route: '/settings/account',
    },
    {
      id: 2,
      title: '隱私設定',
      icon: <SimpleLineIcons name="lock" size={24} color="#8BA0B2" />,
      route: '/settings/privacy',
    },
    {
      id: 3,
      title: '語言設定',
      icon: <Ionicons name="globe-outline" size={26} color="#8BA0B2" />,
      route: '/settings/language',
    },
    {
      id: 4,
      title: '分享QRcode',
      icon: <MaterialCommunityIcons name="qrcode-scan" size={24} color="#8BA0B2" />,
      route: '/settings/qrcode',
    },
  ];

  const handleLogout = () => {
    Alert.alert("登出", "確定要登出 Piggo 嗎？", [
      { text: "取消", style: "cancel" },
      { 
        text: "確定登出", 
        style: 'destructive',
        onPress: () => {
          router.replace('/');
        }
      }
    ]);
  };

  return (
    <SafeAreaView style={styles.container}>
      <View style={styles.header}>
        <TouchableOpacity onPress={() => router.back()} style={styles.backButton}>
          <Feather name="arrow-left" size={26} color="#333" />
        </TouchableOpacity>
        <Text style={styles.headerTitle}>設定</Text>
        <View style={{ width: 26 }} />
      </View>

      <View style={styles.content}>
        <View style={styles.menuList}>
          {menuItems.map((item) => (
            <TouchableOpacity 
              key={item.id} 
              style={styles.menuItem}
              onPress={() => router.push(item.route as any)} 
            >
              <View style={styles.menuLeft}>
                <View style={styles.iconContainer}>
                  {item.icon}
                </View>
                <Text style={styles.menuText}>{item.title}</Text>
              </View>
              <Feather name="chevron-right" size={24} color="#CCC" />
            </TouchableOpacity>
          ))}
        </View>

        <TouchableOpacity style={styles.logoutButton} onPress={handleLogout}>
          <Text style={styles.logoutText}>登出</Text>
        </TouchableOpacity>
      </View>

      <TouchableOpacity style={styles.aiFab}>
        <Image 
            source={require('../../assets/piggy/pig_login0.png')} 
            style={{ width: 30, height: 30 }}
        />
      </TouchableOpacity>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#F2F9FF' },
  
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingHorizontal: 20,
    paddingVertical: 15,
    backgroundColor: '#F2F9FF',
  },
  headerTitle: {
    fontSize: 18,
    fontWeight: 'bold',
    color: '#333',
  },
  backButton: {
    padding: 5,
  },

  content: {
    flex: 1,
    paddingHorizontal: 20,
    paddingTop: 10,
    justifyContent: 'space-between',
    paddingBottom: 100,
  },

  menuList: {
    marginTop: 10,
  },
  menuItem: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingVertical: 18,
    borderBottomWidth: 1,
    borderBottomColor: '#EEE',
    backgroundColor: 'transparent',
  },
  menuLeft: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  iconContainer: {
    width: 40,
    alignItems: 'flex-start',
  },
  menuText: {
    fontSize: 16,
    color: '#666',
    fontWeight: '500',
  },

  logoutButton: {
    backgroundColor: '#007AFF',
    paddingVertical: 15,
    borderRadius: 10,
    alignItems: 'center',
    marginTop: 40,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 4,
    elevation: 3,
  },
  logoutText: {
    color: 'white',
    fontSize: 16,
    fontWeight: 'bold',
  },

  aiFab: {
    position: 'absolute',
    bottom: 30,
    right: 20,
    width: 50,
    height: 50,
    borderRadius: 25,
    backgroundColor: '#6CA6CC',
    justifyContent: 'center',
    alignItems: 'center',
    elevation: 5,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.3,
    shadowRadius: 3,
    zIndex: 999,
  }
});