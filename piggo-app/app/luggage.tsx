// app/luggage.tsx
import { Ionicons } from '@expo/vector-icons';
import { useRouter, useLocalSearchParams } from 'expo-router';
import React, { useState } from 'react';
import { StyleSheet, Text, View, TouchableOpacity, FlatList, TextInput, KeyboardAvoidingView, Platform } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';

// 🔥 加上型別定義，徹底消滅那 4 個 TypeScript 報錯！
type PersonalItem = {
    id: string;
    name: string;
    checked: boolean;
};

type SharedItem = {
    id: string;
    name: string;
    assignee: string | null; // 可以是字串，也可以是 null
    isSuggested: boolean;
    reason?: string;         // 加上 ? 代表這個是選填的
};

export default function LuggageScreen() {
    const router = useRouter();
    const { planId } = useLocalSearchParams();

    const [activeTab, setActiveTab] = useState<'personal' | 'shared'>('personal');
    const [newItemName, setNewItemName] = useState('');

    // 🔥 套用 <PersonalItem[]>
    const [personalItems, setPersonalItems] = useState<PersonalItem[]>([
        { id: 'p1', name: '換洗衣物 x3', checked: false },
        { id: 'p2', name: '牙刷 / 牙膏', checked: true },
        { id: 'p3', name: '手機充電線', checked: false },
        { id: 'p4', name: '隱形眼鏡', checked: false },
    ]);

    // 🔥 套用 <SharedItem[]>
    const [sharedItems, setSharedItems] = useState<SharedItem[]>([
        { id: 's1', name: '延長線', assignee: null, isSuggested: true, reason: '4人同行必備' },
        { id: 's2', name: '防曬乳', assignee: null, isSuggested: true, reason: '行程包含海邊' },
        { id: 's3', name: '吹風機', assignee: '小明', isSuggested: false },
        { id: 's4', name: '撲克牌 / 桌遊', assignee: '我', isSuggested: false },
    ]);

    const togglePersonalItem = (id: string) => {
        setPersonalItems(prev => prev.map(item => item.id === id ? { ...item, checked: !item.checked } : item));
    };

    const claimItem = (id: string) => {
        setSharedItems(prev => prev.map(item => item.id === id ? { ...item, assignee: '我' } : item));
    };

    const unclaimItem = (id: string) => {
        setSharedItems(prev => prev.map(item => item.id === id ? { ...item, assignee: null } : item));
    };

    const handleAddItem = () => {
        if (!newItemName.trim()) return;
        if (activeTab === 'personal') {
            setPersonalItems([...personalItems, { id: Date.now().toString(), name: newItemName, checked: false }]);
        } else {
            setSharedItems([...sharedItems, { id: Date.now().toString(), name: newItemName, assignee: null, isSuggested: false }]);
        }
        setNewItemName('');
    };

    return (
        <SafeAreaView style={styles.container}>
            <View style={styles.header}>
                <TouchableOpacity onPress={() => router.back()} style={styles.backBtn}>
                    <Ionicons name="chevron-back" size={24} color="#333" />
                </TouchableOpacity>
                <Text style={styles.headerTitle}>行李準備</Text>
                <View style={{ width: 40 }} /> 
            </View>

            <View style={styles.tabContainer}>
                <TouchableOpacity 
                    style={[styles.tabButton, activeTab === 'personal' && styles.tabActive]}
                    onPress={() => setActiveTab('personal')}
                >
                    <Ionicons name="lock-closed-outline" size={16} color={activeTab === 'personal' ? 'white' : '#666'} style={{marginRight: 6}} />
                    <Text style={[styles.tabText, activeTab === 'personal' && styles.tabTextActive]}>我的行李</Text>
                </TouchableOpacity>
                <TouchableOpacity 
                    style={[styles.tabButton, activeTab === 'shared' && styles.tabActive]}
                    onPress={() => setActiveTab('shared')}
                >
                    <Ionicons name="people-outline" size={18} color={activeTab === 'shared' ? 'white' : '#666'} style={{marginRight: 6}} />
                    <Text style={[styles.tabText, activeTab === 'shared' && styles.tabTextActive]}>群組共享</Text>
                </TouchableOpacity>
            </View>

            <View style={styles.listContainer}>
                {activeTab === 'personal' ? (
                    <FlatList 
                        data={personalItems}
                        keyExtractor={item => item.id}
                        renderItem={({ item }) => (
                            <TouchableOpacity style={styles.itemCard} onPress={() => togglePersonalItem(item.id)}>
                                <Ionicons 
                                    name={item.checked ? "checkmark-circle" : "ellipse-outline"} 
                                    size={28} 
                                    color={item.checked ? "#6CA6CC" : "#CCC"} 
                                />
                                <Text style={[styles.itemName, item.checked && styles.itemCheckedText]}>{item.name}</Text>
                            </TouchableOpacity>
                        )}
                    />
                ) : (
                    <FlatList 
                        data={sharedItems}
                        keyExtractor={item => item.id}
                        renderItem={({ item }) => {
                            if (item.isSuggested && !item.assignee) {
                                return (
                                    <View style={styles.suggestedCard}>
                                        <View style={{flex: 1}}>
                                            <View style={{flexDirection: 'row', alignItems: 'center'}}>
                                                <Ionicons name="bulb-outline" size={18} color="#FFB800" />
                                                <Text style={styles.suggestedTitle}>系統智能建議</Text>
                                            </View>
                                            <Text style={styles.itemName}>{item.name}</Text>
                                            <Text style={styles.reasonText}>原因：{item.reason}</Text>
                                        </View>
                                        <TouchableOpacity style={styles.claimBtn} onPress={() => claimItem(item.id)}>
                                            <Text style={styles.claimBtnText}>我來帶</Text>
                                        </TouchableOpacity>
                                    </View>
                                );
                            }

                            return (
                                <View style={styles.itemCard}>
                                    <View style={{flex: 1}}>
                                        <Text style={styles.itemName}>{item.name}</Text>
                                        {item.assignee ? (
                                            <Text style={styles.assigneeText}>負責人：{item.assignee}</Text>
                                        ) : (
                                            <Text style={styles.unassignedText}>尚未有人認領</Text>
                                        )}
                                    </View>
                                    
                                    {item.assignee === '我' ? (
                                        <TouchableOpacity style={styles.unclaimBtn} onPress={() => unclaimItem(item.id)}>
                                            <Text style={styles.unclaimBtnText}>取消認領</Text>
                                        </TouchableOpacity>
                                    ) : !item.assignee ? (
                                        <TouchableOpacity style={styles.claimBtn} onPress={() => claimItem(item.id)}>
                                            <Text style={styles.claimBtnText}>我來帶</Text>
                                        </TouchableOpacity>
                                    ) : (
                                        <View style={styles.otherAvatar}>
                                            <Text style={{color: 'white', fontSize: 12}}>{item.assignee?.[0]}</Text>
                                        </View>
                                    )}
                                </View>
                            );
                        }}
                    />
                )}
            </View>

            <KeyboardAvoidingView behavior={Platform.OS === "ios" ? "padding" : "height"} style={styles.inputContainer}>
                <TextInput 
                    style={styles.inputField} 
                    placeholder={activeTab === 'personal' ? "新增私人物品..." : "新增群組共用物品..."}
                    value={newItemName}
                    onChangeText={setNewItemName}
                />
                <TouchableOpacity style={styles.addBtn} onPress={handleAddItem}>
                    <Ionicons name="add" size={24} color="white" />
                </TouchableOpacity>
            </KeyboardAvoidingView>
        </SafeAreaView>
    );
}

const styles = StyleSheet.create({
    container: { flex: 1, backgroundColor: '#F2F9FF' },
    header: { flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', paddingHorizontal: 15, paddingVertical: 10 },
    backBtn: { width: 40, height: 40, borderRadius: 20, backgroundColor: 'white', justifyContent: 'center', alignItems: 'center', elevation: 2, shadowColor: '#000', shadowOffset: {width:0, height:1}, shadowOpacity:0.1, shadowRadius:2 },
    headerTitle: { fontSize: 20, fontWeight: 'bold', color: '#333' },
    
    tabContainer: { flexDirection: 'row', backgroundColor: '#E0EEF8', marginHorizontal: 20, borderRadius: 25, padding: 5, marginTop: 15 },
    tabButton: { flex: 1, flexDirection: 'row', paddingVertical: 10, justifyContent: 'center', alignItems: 'center', borderRadius: 20 },
    tabActive: { backgroundColor: '#6CA6CC', elevation: 2, shadowColor: '#000', shadowOffset: {width:0, height:2}, shadowOpacity:0.1, shadowRadius:2 },
    tabText: { fontSize: 15, fontWeight: 'bold', color: '#666' },
    tabTextActive: { color: 'white' },

    listContainer: { flex: 1, paddingHorizontal: 20, paddingTop: 15 },
    
    itemCard: { flexDirection: 'row', alignItems: 'center', backgroundColor: 'white', padding: 15, borderRadius: 15, marginBottom: 12, elevation: 2, shadowColor: '#000', shadowOffset: {width:0, height:1}, shadowOpacity:0.05, shadowRadius:3 },
    itemName: { fontSize: 16, color: '#333', marginLeft: 10, fontWeight: '500' },
    itemCheckedText: { textDecorationLine: 'line-through', color: '#999' },
    
    suggestedCard: { flexDirection: 'row', alignItems: 'center', backgroundColor: '#FFF9E6', padding: 15, borderRadius: 15, marginBottom: 12, borderWidth: 1, borderColor: '#FFE499' },
    suggestedTitle: { fontSize: 12, color: '#FFB800', fontWeight: 'bold', marginLeft: 4 },
    reasonText: { fontSize: 12, color: '#888', marginLeft: 10, marginTop: 4 },
    
    assigneeText: { fontSize: 12, color: '#6CA6CC', marginLeft: 10, marginTop: 4, fontWeight: 'bold' },
    unassignedText: { fontSize: 12, color: '#FF8888', marginLeft: 10, marginTop: 4 },
    claimBtn: { backgroundColor: '#6CA6CC', paddingVertical: 8, paddingHorizontal: 15, borderRadius: 20 },
    claimBtnText: { color: 'white', fontWeight: 'bold', fontSize: 14 },
    unclaimBtn: { backgroundColor: '#EEEEEE', paddingVertical: 8, paddingHorizontal: 15, borderRadius: 20 },
    unclaimBtnText: { color: '#666', fontWeight: 'bold', fontSize: 14 },
    otherAvatar: { width: 34, height: 34, borderRadius: 17, backgroundColor: '#FFB800', justifyContent: 'center', alignItems: 'center' },

    inputContainer: { flexDirection: 'row', padding: 15, backgroundColor: 'white', borderTopWidth: 1, borderColor: '#EEE' },
    inputField: { flex: 1, backgroundColor: '#F2F9FF', paddingHorizontal: 15, borderRadius: 25, fontSize: 16, marginRight: 10 },
    addBtn: { width: 50, height: 50, borderRadius: 25, backgroundColor: '#6CA6CC', justifyContent: 'center', alignItems: 'center', elevation: 2 }
});