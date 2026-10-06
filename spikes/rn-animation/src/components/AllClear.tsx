// Scene D — "All clear" milestone: bell happy + confetti, ≤ 1.5 s, tap to skip (design-direction §6)
import { useEffect, useMemo } from 'react';
import { Dimensions, Pressable, StyleSheet, Text } from 'react-native';
import Animated, {
  Easing,
  FadeIn,
  FadeOut,
  useAnimatedStyle,
  useSharedValue,
  withDelay,
  withTiming,
} from 'react-native-reanimated';
import { type, useTheme } from '../theme';
import { Bell } from './Bell';

const { width: W, height: H } = Dimensions.get('window');
const PIECES = 48;

export function AllClear({ onDone }: { onDone: () => void }) {
  const t = useTheme();
  const colors = [t.kind.task, t.kind.meeting, t.kind.event, t.kind.occasion, t.success, '#FFCC00'];

  useEffect(() => {
    const id = setTimeout(onDone, 1500);
    return () => clearTimeout(id);
  }, [onDone]);

  const pieces = useMemo(
    () =>
      Array.from({ length: PIECES }, (_, i) => ({
        x: W / 2 + (Math.random() - 0.5) * 60,
        dx: (Math.random() - 0.5) * W * 1.1,
        dy: H * (0.45 + Math.random() * 0.5),
        rot: (Math.random() - 0.5) * 720,
        delay: Math.random() * 120,
        color: colors[i % colors.length],
        w: 6 + Math.random() * 6,
      })),
    // eslint-disable-next-line react-hooks/exhaustive-deps
    [],
  );

  return (
    <Animated.View entering={FadeIn.duration(150)} exiting={FadeOut.duration(200)} style={styles.overlay}>
      <Pressable style={StyleSheet.absoluteFill} onPress={onDone} accessibilityLabel="Skip celebration" />
      {pieces.map((p, i) => (
        <Confetti key={i} {...p} />
      ))}
      <Bell mood="happy" size={160} />
      <Text style={[type.largeTitle, { color: t.textPrimary }]}>All clear!</Text>
      <Text style={[type.body, { color: t.textSecondary }]}>Nothing left for today.</Text>
    </Animated.View>
  );
}

function Confetti(p: { x: number; dx: number; dy: number; rot: number; delay: number; color: string; w: number }) {
  const prog = useSharedValue(0);
  useEffect(() => {
    prog.value = withDelay(p.delay, withTiming(1, { duration: 1300, easing: Easing.out(Easing.quad) }));
  }, [p.delay, prog]);

  const style = useAnimatedStyle(() => {
    const v = prog.value;
    return {
      opacity: 1 - v * v,
      transform: [
        { translateX: p.dx * v },
        { translateY: -H * 0.25 * Math.sin(Math.PI * v) + p.dy * v * v },
        { rotate: `${p.rot * v}deg` },
      ],
    };
  });

  return (
    <Animated.View
      pointerEvents="none"
      style={[{ position: 'absolute', left: p.x, top: H * 0.35, width: p.w, height: p.w * 1.6, backgroundColor: p.color, borderRadius: 2 }, style]}
    />
  );
}

const styles = StyleSheet.create({
  overlay: {
    position: 'absolute', top: 0, left: 0, right: 0, bottom: 0,
    alignItems: 'center',
    justifyContent: 'center',
    gap: 8,
    backgroundColor: 'rgba(127,127,127,0.12)',
    zIndex: 50,
  },
});
