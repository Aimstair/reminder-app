// Reminder row: completion animation (checkbox → strike-through → 600 ms hold → removal)
// and swipe right to complete (design-direction §6, VW swipe rules)
import { memo, useCallback, useEffect, useRef, useState } from 'react';
import { StyleSheet, Text, View } from 'react-native';
import { Gesture, GestureDetector } from 'react-native-gesture-handler';
import Animated, {
  interpolate,
  useAnimatedStyle,
  useSharedValue,
  withDelay,
  withSpring,
  withTiming,
} from 'react-native-reanimated';
import { scheduleOnRN } from 'react-native-worklets';
import type { Reminder } from '../data';
import { radius, space, springs, type, useTheme } from '../theme';
import { Checkbox } from './Checkbox';

const SWIPE_DONE = 90;
const HOLD_MS = 600;

type Props = {
  item: Reminder;
  onCompleted: (item: Reminder) => void; // called after the hold → parent removes the row
  onFeedback: () => void;
  autoComplete?: boolean; // rapid test trigger
};

export const ReminderRow = memo(function ReminderRow({ item, onCompleted, onFeedback, autoComplete }: Props) {
  const t = useTheme();
  const [done, setDone] = useState(false);
  const strike = useSharedValue(0);
  const tx = useSharedValue(0);
  const timer = useRef<ReturnType<typeof setTimeout> | null>(null);

  useEffect(() => () => {
    if (timer.current) clearTimeout(timer.current);
  }, []);

  const complete = useCallback(() => {
    if (done) return;
    setDone(true);
    onFeedback();
    strike.value = withDelay(120, withTiming(1, { duration: 200 }));
    timer.current = setTimeout(() => onCompleted(item), 320 + HOLD_MS);
  }, [done, item, onCompleted, onFeedback, strike]);

  useEffect(() => {
    if (autoComplete) complete();
  }, [autoComplete, complete]);

  const pan = Gesture.Pan()
    .activeOffsetX([-12, 12])
    .failOffsetY([-10, 10])
    .onUpdate((e) => {
      tx.value = Math.max(0, e.translationX);
    })
    .onEnd(() => {
      if (tx.value > SWIPE_DONE) scheduleOnRN(complete);
      tx.value = withSpring(0, springs.soft);
    });

  const rowStyle = useAnimatedStyle(() => ({ transform: [{ translateX: tx.value }] }));
  const bgStyle = useAnimatedStyle(() => ({ opacity: interpolate(tx.value, [0, SWIPE_DONE], [0, 1], 'clamp') }));
  const strikeStyle = useAnimatedStyle(() => ({ width: `${strike.value * 100}%` }));

  return (
    <View style={styles.outer}>
      <Animated.View style={[styles.swipeBg, { backgroundColor: t.success }, bgStyle]}>
        <Text style={styles.swipeLabel}>✓ Done</Text>
      </Animated.View>
      <GestureDetector gesture={pan}>
        <Animated.View style={[styles.row, { backgroundColor: t.surface }, rowStyle]}>
          <Checkbox checked={done} color={t.kind[item.kind]} onPress={complete} />
          <View style={styles.texts}>
            <View style={styles.titleWrap}>
              <Text
                numberOfLines={1}
                style={[type.body, { color: done ? t.textSecondary : t.textPrimary }]}
              >
                {item.title}
              </Text>
              <Animated.View style={[styles.strike, { backgroundColor: t.textSecondary }, strikeStyle]} />
            </View>
            <Text style={[type.subheadline, { color: item.group === 'Overdue' ? t.danger : t.textSecondary }]}>
              {item.when}
              {item.work ? '  · Work' : ''}
            </Text>
          </View>
          <View style={[styles.kindDot, { backgroundColor: t.kind[item.kind] }]} />
        </Animated.View>
      </GestureDetector>
    </View>
  );
});

const styles = StyleSheet.create({
  outer: { marginHorizontal: space.l, marginVertical: 3 },
  swipeBg: {
    position: 'absolute', top: 0, left: 0, right: 0, bottom: 0,
    borderRadius: radius.row,
    justifyContent: 'center',
    paddingLeft: space.xl,
  },
  swipeLabel: { color: '#fff', fontFamily: 'Inter_600SemiBold', fontSize: 15 },
  row: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: space.m,
    paddingHorizontal: space.l,
    paddingVertical: space.m,
    borderRadius: radius.row,
  },
  texts: { flex: 1, gap: 2 },
  titleWrap: { alignSelf: 'flex-start', maxWidth: '100%', justifyContent: 'center' },
  strike: { position: 'absolute', left: 0, height: 1.5, top: '52%' },
  kindDot: { width: 8, height: 8, borderRadius: 4 },
});
