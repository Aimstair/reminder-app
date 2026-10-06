// Scene A — onboarding "Nudged before it matters" demo (design-direction §5, step 3)
import { useEffect, useRef, useState } from 'react';
import { type LayoutChangeEvent, Pressable, StyleSheet, Text, View } from 'react-native';
import { Gesture, GestureDetector } from 'react-native-gesture-handler';
import Animated, {
  FadeOut,
  LinearTransition,
  SlideInUp,
  useAnimatedReaction,
  useAnimatedStyle,
  useSharedValue,
  withSpring,
} from 'react-native-reanimated';
import { scheduleOnRN } from 'react-native-worklets';
import { Bell, type Mood } from '../components/Bell';
import { font, radius, space, springs, type, useTheme } from '../theme';

const KNOB = 28;
const DAYS = ['Oct 5', '6', '7', '8', '9', '10', '11', 'Oct 12'];

type Card = { stage: number; title: string; body: string; prep: boolean };
const CARDS: Card[] = [
  { stage: 1, title: "Mom's birthday", body: 'In 1 week · Mon, Oct 12', prep: true },
  { stage: 2, title: "Mom's birthday", body: 'In 1 day · Tomorrow', prep: true },
  { stage: 3, title: "Mom's birthday", body: 'Today 🎂', prep: false },
];

export function NudgesScene({ onTick }: { onTick: () => void }) {
  const t = useTheme();
  const [trackW, setTrackW] = useState(0);
  const [stage, setStage] = useState(0);
  const [prepared, setPrepared] = useState(false);
  const [mood, setMood] = useState<Mood>('idle');
  const moodTimer = useRef<ReturnType<typeof setTimeout> | null>(null);
  const x = useSharedValue(0);
  const startX = useSharedValue(0);
  const max = useSharedValue(1);

  const onLayout = (e: LayoutChangeEvent) => {
    const w = e.nativeEvent.layout.width;
    setTrackW(w);
    max.value = Math.max(1, w - KNOB);
  };

  const pan = Gesture.Pan()
    .onBegin(() => {
      startX.value = x.value;
    })
    .onUpdate((e) => {
      x.value = Math.min(max.value, Math.max(0, startX.value + e.translationX));
    })
    .onEnd(() => {
      // snap to nearest day
      const step = max.value / 7;
      x.value = withSpring(Math.round(x.value / step) * step, springs.snappy);
    });

  useAnimatedReaction(
    () => {
      const p = x.value / max.value;
      return p < 0.03 ? 0 : p < 6 / 7 - 0.02 ? 1 : p < 0.985 ? 2 : 3;
    },
    (s, prev) => {
      if (s !== prev) scheduleOnRN(setStage, s);
    },
  );

  useEffect(() => {
    if (stage === 0) return;
    onTick();
    if (prepared && stage < 3) return;
    setMood('nudge');
    if (moodTimer.current) clearTimeout(moodTimer.current);
    moodTimer.current = setTimeout(() => setMood(prepared ? 'happy' : 'idle'), 900);
  }, [stage]); // eslint-disable-line react-hooks/exhaustive-deps

  const knobStyle = useAnimatedStyle(() => ({ transform: [{ translateX: x.value }] }));
  const fillStyle = useAnimatedStyle(() => ({ width: x.value + KNOB / 2 }));

  const visible = CARDS.filter((c) => c.stage <= stage && !(prepared && c.prep));

  const prepare = () => {
    setPrepared(true);
    setMood('happy');
  };

  const reset = () => {
    setPrepared(false);
    setMood('idle');
    x.value = withSpring(0, springs.soft);
  };

  return (
    <View style={[styles.flex, { backgroundColor: t.bgGrouped }]}>
      <Text style={[type.largeTitle, styles.title, { color: t.textPrimary }]}>Nudged before it matters.</Text>
      <Text style={[type.body, styles.sub, { color: t.textSecondary }]}>
        Drag through the week. For big days, you get a heads-up early — not just on the day.
      </Text>

      <View style={[styles.phone, { backgroundColor: t.surface, borderColor: t.separator }]}>
        <Bell mood={mood} size={110} style={styles.bell} />
        <Animated.View layout={LinearTransition.springify()} style={styles.cards}>
          {visible.map((c) => (
            <Animated.View
              key={c.stage}
              entering={SlideInUp.springify().damping(16)}
              exiting={FadeOut.duration(220)}
              layout={LinearTransition.springify()}
              style={[styles.card, { backgroundColor: t.bgGrouped }]}
            >
              <Text style={[type.headline, { color: t.textPrimary }]}>{c.title}</Text>
              <Text style={[type.subheadline, { color: t.textSecondary }]}>{c.body}</Text>
              {c.prep && !prepared && (
                <Pressable onPress={prepare} style={[styles.prepBtn, { backgroundColor: t.kind.occasion }]}>
                  <Text style={styles.prepText}>I'm prepared</Text>
                </Pressable>
              )}
            </Animated.View>
          ))}
          {prepared && stage < 3 && (
            <Animated.Text entering={SlideInUp.springify()} style={[type.footnote, { color: t.textSecondary, textAlign: 'center' }]}>
              Prepared? We'll stop the early nudges.
            </Animated.Text>
          )}
        </Animated.View>
      </View>

      <View style={styles.sliderWrap}>
        <View onLayout={onLayout} style={[styles.track, { backgroundColor: t.separator }]}>
          <Animated.View style={[styles.fill, { backgroundColor: t.kind.occasion }, fillStyle]} />
          <GestureDetector gesture={pan}>
            <Animated.View style={[styles.knob, knobStyle]} hitSlop={16} />
          </GestureDetector>
        </View>
        <View style={styles.days}>
          {DAYS.map((d, i) => (
            <Text key={i} style={[type.caption, { color: t.textSecondary, width: trackW / 8, textAlign: 'center' }]}>
              {d}
            </Text>
          ))}
        </View>
        <Pressable onPress={reset} style={styles.reset}>
          <Text style={{ color: t.accent, fontFamily: font.semibold }}>Reset</Text>
        </Pressable>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  flex: { flex: 1, paddingHorizontal: space.l },
  title: { marginTop: space.s },
  sub: { marginTop: space.s },
  phone: { flex: 1, marginTop: space.xl, borderRadius: 36, borderWidth: 1, padding: space.l, alignItems: 'center' },
  bell: { marginTop: space.s },
  cards: { alignSelf: 'stretch', gap: space.s, marginTop: space.l },
  card: { borderRadius: radius.card, padding: space.m, gap: 2 },
  prepBtn: { alignSelf: 'flex-start', marginTop: space.s, borderRadius: radius.chip, paddingHorizontal: space.m, paddingVertical: 6 },
  prepText: { color: '#fff', fontFamily: font.semibold, fontSize: 13 },
  sliderWrap: { paddingVertical: space.xl },
  track: { height: 6, borderRadius: 3, justifyContent: 'center' },
  fill: { position: 'absolute', left: 0, height: 6, borderRadius: 3 },
  knob: { position: 'absolute', width: KNOB, height: KNOB, borderRadius: KNOB / 2, backgroundColor: '#fff', elevation: 3, shadowColor: '#000', shadowOpacity: 0.25, shadowRadius: 4, shadowOffset: { width: 0, height: 2 } },
  days: { flexDirection: 'row', marginTop: space.m },
  reset: { alignSelf: 'center', marginTop: space.s, padding: space.s },
});
