// Tokens from docs/design-direction.md §3 (spike copy — not the real design system)
import { useColorScheme } from 'react-native';

export type Kind = 'task' | 'meeting' | 'event' | 'occasion';

const light = {
  bgGrouped: '#F2F2F7',
  surface: '#FFFFFF',
  surfaceElevated: '#FFFFFF',
  textPrimary: '#000000',
  textSecondary: 'rgba(60,60,67,0.6)',
  separator: 'rgba(60,60,67,0.29)',
  accent: '#007AFF',
  danger: '#FF3B30',
  success: '#34C759',
  warning: '#FF9500',
  kind: { task: '#007AFF', meeting: '#5856D6', event: '#FF9500', occasion: '#FF2D55' } as Record<Kind, string>,
};

const dark: typeof light = {
  bgGrouped: '#000000',
  surface: '#1C1C1E',
  surfaceElevated: '#2C2C2E',
  textPrimary: '#FFFFFF',
  textSecondary: 'rgba(235,235,245,0.6)',
  separator: 'rgba(84,84,88,0.6)',
  accent: '#0A84FF',
  danger: '#FF453A',
  success: '#30D158',
  warning: '#FF9F0A',
  kind: { task: '#0A84FF', meeting: '#5E5CE6', event: '#FF9F0A', occasion: '#FF375F' },
};

export type Theme = typeof light;

export function useTheme(): Theme {
  return useColorScheme() === 'dark' ? dark : light;
}

export const font = {
  regular: 'Inter_400Regular',
  medium: 'Inter_500Medium',
  semibold: 'Inter_600SemiBold',
  bold: 'Inter_700Bold',
};

export const type = {
  largeTitle: { fontFamily: font.bold, fontSize: 34 },
  title2: { fontFamily: font.bold, fontSize: 22 },
  headline: { fontFamily: font.semibold, fontSize: 17 },
  body: { fontFamily: font.regular, fontSize: 17 },
  subheadline: { fontFamily: font.regular, fontSize: 15 },
  footnote: { fontFamily: font.regular, fontSize: 13 },
  caption: { fontFamily: font.medium, fontSize: 12 },
};

export const space = { xs: 4, s: 8, m: 12, l: 16, xl: 20, xxl: 24, xxxl: 32 };
export const radius = { chip: 10, row: 12, card: 16, sheet: 24 };

// Spring presets (Things-like: soft, settles quickly)
export const springs = {
  snappy: { damping: 14, stiffness: 260, mass: 0.6 },
  soft: { damping: 18, stiffness: 160, mass: 0.8 },
};
