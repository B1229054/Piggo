// app/_layout.tsx
import { Stack } from 'expo-router';

import { GestureHandlerRootView } from 'react-native-gesture-handler';
import { PlanProvider } from '../components/PlanContext';

export default function RootLayout() {
  return (
    
    <GestureHandlerRootView style={{ flex: 1 }}>
      <PlanProvider>
        <Stack screenOptions={{ headerShown: false }}>
          <Stack.Screen name="(tabs)" />
          <Stack.Screen name="new-plan" options={{ presentation: 'modal', headerShown: false }} />
          <Stack.Screen name="group-chat" options={{ headerShown: false }} />
        </Stack>
      </PlanProvider>
    </GestureHandlerRootView>
  );
}