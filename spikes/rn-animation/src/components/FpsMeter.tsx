// UI-thread frame meter: FPS and janky frames (> 25 ms) per second.
// Supplements adb gfxinfo for side-by-side screen recordings (bake-off M1).
import { useState } from 'react';
import { StyleSheet, Text, View } from 'react-native';
import { useFrameCallback } from 'react-native-reanimated';
import { scheduleOnRN } from 'react-native-worklets';

export function FpsMeter() {
  const [stats, setStats] = useState({ fps: 0, jank: 0 });

  useFrameCallback((info) => {
    'worklet';
    const g = globalThis as unknown as { __fm?: { t: number; n: number; j: number } };
    if (!g.__fm) g.__fm = { t: info.timestamp, n: 0, j: 0 };
    const s = g.__fm;
    s.n += 1;
    if ((info.timeSincePreviousFrame ?? 0) > 25) s.j += 1;
    if (info.timestamp - s.t >= 1000) {
      scheduleOnRN(setStats, { fps: s.n, jank: s.j });
      s.t = info.timestamp;
      s.n = 0;
      s.j = 0;
    }
  });

  return (
    <View pointerEvents="none" style={styles.box}>
      <Text style={styles.text}>
        {stats.fps} fps · {stats.jank} jank
      </Text>
    </View>
  );
}

const styles = StyleSheet.create({
  box: {
    position: 'absolute',
    top: 4,
    right: 8,
    backgroundColor: 'rgba(0,0,0,0.6)',
    borderRadius: 6,
    paddingHorizontal: 6,
    paddingVertical: 2,
    zIndex: 100,
  },
  text: { color: '#fff', fontSize: 11, fontVariant: ['tabular-nums'] },
});
