// Things-style round checkbox: fill springs 1 → 1.15 → 1, checkmark draws in (design-direction §6 step 1)
import { useEffect } from 'react';
import { Pressable } from 'react-native';
import Svg, { Circle, Path } from 'react-native-svg';
import Animated, {
  useAnimatedProps,
  useAnimatedStyle,
  useSharedValue,
  withDelay,
  withSequence,
  withSpring,
  withTiming,
} from 'react-native-reanimated';
import { springs } from '../theme';

const AnimatedCircle = Animated.createAnimatedComponent(Circle);
const AnimatedPath = Animated.createAnimatedComponent(Path);
const CHECK_LEN = 16;

type Props = { checked: boolean; color: string; onPress: () => void; size?: number };

export function Checkbox({ checked, color, onPress, size = 26 }: Props) {
  const fill = useSharedValue(checked ? 1 : 0);
  const draw = useSharedValue(checked ? 1 : 0);
  const scale = useSharedValue(1);

  useEffect(() => {
    if (checked) {
      fill.value = withTiming(1, { duration: 160 });
      scale.value = withSequence(withSpring(1.15, springs.snappy), withSpring(1, springs.soft));
      draw.value = withDelay(90, withTiming(1, { duration: 220 }));
    } else {
      draw.value = withTiming(0, { duration: 120 });
      fill.value = withTiming(0, { duration: 160 });
    }
  }, [checked, draw, fill, scale]);

  const wrap = useAnimatedStyle(() => ({ transform: [{ scale: scale.value }] }));
  const fillProps = useAnimatedProps(() => ({ r: 10.5 * fill.value }));
  const checkProps = useAnimatedProps(() => ({ strokeDashoffset: CHECK_LEN * (1 - draw.value) }));

  return (
    <Pressable onPress={onPress} hitSlop={12} accessibilityRole="checkbox" accessibilityState={{ checked }}>
      <Animated.View style={wrap}>
        <Svg width={size} height={size} viewBox="0 0 24 24">
          <Circle cx={12} cy={12} r={10.5} stroke={color} strokeWidth={1.6} fill="none" />
          <AnimatedCircle cx={12} cy={12} fill={color} animatedProps={fillProps} />
          <AnimatedPath
            d="M7.2 12.4 L10.6 15.8 L17 9.2"
            stroke="#fff"
            strokeWidth={2.2}
            strokeLinecap="round"
            strokeLinejoin="round"
            fill="none"
            strokeDasharray={CHECK_LEN}
            animatedProps={checkProps}
          />
        </Svg>
      </Animated.View>
    </Pressable>
  );
}
