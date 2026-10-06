// Bell mascot placeholder. Uses a Rive file; falls back to a code-animated bell if Rive fails.
// Replace RIVE config with the real file once it exists (docs/spikes/animation-bakeoff.md "Shared assets").
import { useEffect, useRef, useState } from 'react';
import { StyleSheet, Text, View, type ViewStyle } from 'react-native';
import Rive, { Fit, type RiveRef } from 'rive-react-native';
import Animated, {
  useAnimatedStyle,
  useSharedValue,
  withRepeat,
  withSequence,
  withSpring,
  withTiming,
} from 'react-native-reanimated';

export type Mood = 'idle' | 'nudge' | 'happy' | 'worried';

// Placeholder: Rive's public "avatar" example (state machine with isHappy / isSad booleans).
// When spikes/assets/placeholder.riv is provided, switch to: source: require('../../assets/placeholder.riv')
const RIVE = {
  url: 'https://public.rive.app/community/runtime-files/2195-4346-avatar-pack-use-case.riv',
  artboard: 'Avatar 1',
  stateMachine: 'avatar',
  inputs: { happy: 'isHappy', sad: 'isSad' },
};

export function Bell({ mood, size = 120, style }: { mood: Mood; size?: number; style?: ViewStyle }) {
  const ref = useRef<RiveRef>(null);
  const [riveFailed, setRiveFailed] = useState(false);

  useEffect(() => {
    if (riveFailed || !ref.current) return;
    ref.current.setInputState(RIVE.stateMachine, RIVE.inputs.happy, mood === 'happy' || mood === 'nudge');
    ref.current.setInputState(RIVE.stateMachine, RIVE.inputs.sad, mood === 'worried');
  }, [mood, riveFailed]);

  if (riveFailed) return <CodeBell mood={mood} size={size} style={style} />;

  return (
    <View style={[{ width: size, height: size }, style]}>
      <Rive
        ref={ref}
        url={RIVE.url}
        artboardName={RIVE.artboard}
        stateMachineName={RIVE.stateMachine}
        fit={Fit.Contain}
        style={{ width: size, height: size }}
        onError={() => setRiveFailed(true)}
      />
    </View>
  );
}

// Fallback: emoji bell that rings (swings) on nudge and hops when happy
function CodeBell({ mood, size, style }: { mood: Mood; size: number; style?: ViewStyle }) {
  const rot = useSharedValue(0);
  const y = useSharedValue(0);

  useEffect(() => {
    if (mood === 'nudge') {
      rot.value = withSequence(
        withRepeat(withSequence(withTiming(-18, { duration: 70 }), withTiming(18, { duration: 70 })), 4),
        withSpring(0),
      );
    } else if (mood === 'happy') {
      y.value = withSequence(withSpring(-24, { damping: 8 }), withSpring(0, { damping: 10 }));
    } else {
      rot.value = withSpring(0);
    }
  }, [mood, rot, y]);

  const anim = useAnimatedStyle(() => ({
    transform: [{ translateY: y.value }, { rotate: `${rot.value}deg` }],
  }));

  return (
    <View style={[styles.center, { width: size, height: size }, style]}>
      <Animated.View style={anim}>
        <Text style={{ fontSize: size * 0.7 }}>{mood === 'worried' ? '🔕' : '🔔'}</Text>
      </Animated.View>
    </View>
  );
}

const styles = StyleSheet.create({ center: { alignItems: 'center', justifyContent: 'center' } });
