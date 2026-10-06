// Animation bake-off — React Native prototype (docs/spikes/animation-bakeoff.md)
import { useState } from 'react';
import { Pressable, StyleSheet, Switch, Text, View } from 'react-native';
import { StatusBar } from 'expo-status-bar';
import { GestureHandlerRootView } from 'react-native-gesture-handler';
import { BottomSheetModalProvider } from '@gorhom/bottom-sheet';
import { SafeAreaProvider, useSafeAreaInsets } from 'react-native-safe-area-context';
import { Inter_400Regular, Inter_500Medium, Inter_600SemiBold, Inter_700Bold, useFonts } from '@expo-google-fonts/inter';
import { FpsMeter } from './src/components/FpsMeter';
import { useFeedback } from './src/feedback';
import { NudgesScene } from './src/scenes/NudgesScene';
import { ScheduleScene } from './src/scenes/ScheduleScene';
import { font, radius, space, useTheme } from './src/theme';

type Tab = 'nudges' | 'schedule';

export default function App() {
  const [loaded] = useFonts({ Inter_400Regular, Inter_500Medium, Inter_600SemiBold, Inter_700Bold });
  if (!loaded) return null;
  return (
    <GestureHandlerRootView style={styles.flex}>
      <SafeAreaProvider>
        <BottomSheetModalProvider>
          <Shell />
        </BottomSheetModalProvider>
      </SafeAreaProvider>
    </GestureHandlerRootView>
  );
}

function Shell() {
  const t = useTheme();
  const insets = useSafeAreaInsets();
  const [tab, setTab] = useState<Tab>('schedule');
  const [soundOn, setSoundOn] = useState(true);
  const feedback = useFeedback(soundOn);

  return (
    <View style={[styles.flex, { backgroundColor: t.bgGrouped, paddingTop: insets.top }]}>
      <StatusBar style="auto" />
      <View style={styles.topBar}>
        <View style={[styles.segment, { backgroundColor: t.separator }]}>
          {(['nudges', 'schedule'] as Tab[]).map((k) => (
            <Pressable
              key={k}
              onPress={() => setTab(k)}
              style={[styles.segBtn, tab === k && { backgroundColor: t.surface }]}
            >
              <Text style={[styles.segText, { color: t.textPrimary }]}>{k === 'nudges' ? 'A · Nudges' : 'B–D · Schedule'}</Text>
            </Pressable>
          ))}
        </View>
        <View style={styles.sound}>
          <Text style={[styles.segText, { color: t.textSecondary }]}>Sound</Text>
          <Switch value={soundOn} onValueChange={setSoundOn} />
        </View>
      </View>
      {tab === 'nudges' ? <NudgesScene onTick={feedback.tick} /> : <ScheduleScene feedback={feedback} />}
      <FpsMeter />
    </View>
  );
}

const styles = StyleSheet.create({
  flex: { flex: 1 },
  topBar: { flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', paddingHorizontal: space.l, paddingVertical: space.s },
  segment: { flexDirection: 'row', borderRadius: radius.chip, padding: 2 },
  segBtn: { paddingHorizontal: space.m, paddingVertical: 6, borderRadius: radius.chip - 2 },
  segText: { fontFamily: font.medium, fontSize: 13 },
  sound: { flexDirection: 'row', alignItems: 'center', gap: 4 },
});
