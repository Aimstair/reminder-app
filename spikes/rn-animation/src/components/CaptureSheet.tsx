// Scene C — capture sheet: spring open, chips pop in one by one, save → row flies into the list.
// Stub parser only (keyword match) — the real parser is specified in docs/parser-test-set.md.
import { forwardRef, useCallback, useMemo, useRef, useState } from 'react';
import { Pressable, StyleSheet, Text, View } from 'react-native';
import {
  BottomSheetBackdrop,
  BottomSheetModal,
  BottomSheetTextInput,
  BottomSheetView,
  type BottomSheetBackdropProps,
} from '@gorhom/bottom-sheet';
import Animated, { LinearTransition, ZoomIn, ZoomOut } from 'react-native-reanimated';
import type { Kind } from '../theme';
import { font, radius, space, type, useTheme } from '../theme';

export type Parsed = { title: string; when: string; kind: Kind; chips: { key: string; label: string; warn?: boolean }[] };

const MONTHS = /\b(jan|feb|mar|apr|may|jun|jul|aug|sep|sept|oct|nov|dec)[a-z]*\.?\s+(\d{1,2})(st|nd|rd|th)?\b/i;
const TIME = /\b(\d{1,2})(:\d{2})?\s?(am|pm)\b/i;
const DAYS = /\b(today|tomorrow|monday|tuesday|wednesday|thursday|friday|saturday|sunday)\b/i;

export function stubParse(text: string): Parsed {
  let rest = text;
  const chips: Parsed['chips'] = [];
  let when = 'Tomorrow';
  const date = text.match(MONTHS) ?? text.match(DAYS);
  if (date) {
    when = date[0].replace(/\b\w/g, (c) => c.toUpperCase());
    rest = rest.replace(date[0], '');
  }
  const time = text.match(TIME);
  if (time) {
    when += ` · ${time[0].toUpperCase()}`;
    rest = rest.replace(time[0], '');
  }
  const kind: Kind = /birthday|anniversary|bday/i.test(text)
    ? 'occasion'
    : /meeting|standup|call with|1:1/i.test(text)
      ? 'meeting'
      : /dinner|lunch|party|dentist|flight|concert/i.test(text)
        ? 'event'
        : 'task';
  const title = rest.replace(/\s+/g, ' ').trim().replace(/^\w/, (c) => c.toUpperCase());
  if (title) chips.push({ key: 'title', label: title });
  chips.push({ key: 'date', label: date ? date[0].replace(/\b\w/g, (c) => c.toUpperCase()) : 'Tomorrow' });
  if (time) chips.push({ key: 'time', label: time[0].toUpperCase() });
  chips.push({ key: 'kind', label: kind[0].toUpperCase() + kind.slice(1) });
  if (kind === 'occasion') {
    chips.push({ key: 'repeat', label: 'Every year' });
    chips.push({ key: 'alerts', label: '1 week, 1 day, on the day' });
  }
  return { title, when, kind, chips };
}

type Props = { onSave: (p: Parsed) => void };

export const CaptureSheet = forwardRef<BottomSheetModal, Props>(function CaptureSheet({ onSave }, ref) {
  const t = useTheme();
  const [text, setText] = useState('');
  const parsed = useMemo(() => stubParse(text), [text]);
  const typing = useRef<ReturnType<typeof setInterval> | null>(null);

  const backdrop = useCallback(
    (p: BottomSheetBackdropProps) => <BottomSheetBackdrop {...p} appearsOnIndex={0} disappearsOnIndex={-1} />,
    [],
  );

  // Auto-type a fixed phrase so measurements are repeatable (bake-off M1)
  const demoType = () => {
    const phrase = "Mom's birthday Oct 12";
    let i = 0;
    setText('');
    if (typing.current) clearInterval(typing.current);
    typing.current = setInterval(() => {
      i += 1;
      setText(phrase.slice(0, i));
      if (i >= phrase.length && typing.current) clearInterval(typing.current);
    }, 70);
  };

  const save = () => {
    if (!parsed.title) return;
    onSave(parsed);
    setText('');
  };

  return (
    <BottomSheetModal
      ref={ref}
      snapPoints={['50%']}
      enableDynamicSizing={false}
      backdropComponent={backdrop}
      backgroundStyle={{ backgroundColor: t.surfaceElevated, borderRadius: radius.sheet }}
      handleIndicatorStyle={{ backgroundColor: t.separator }}
      keyboardBehavior="interactive"
    >
      <BottomSheetView style={styles.body}>
        <BottomSheetTextInput
          value={text}
          onChangeText={setText}
          placeholder="Try “Mom's birthday Oct 12”"
          placeholderTextColor={t.textSecondary}
          style={[styles.input, { color: t.textPrimary, backgroundColor: t.bgGrouped }]}
          onSubmitEditing={save}
        />
        <Animated.View layout={LinearTransition.springify()} style={styles.chips}>
          {text.length > 0 &&
            parsed.chips.map((c, i) => (
              <Animated.View
                key={c.key}
                entering={ZoomIn.springify().damping(14).delay(i * 60)}
                exiting={ZoomOut.duration(120)}
                layout={LinearTransition.springify()}
                style={[styles.chip, { backgroundColor: c.key === 'kind' ? t.kind[parsed.kind] + '22' : t.bgGrouped }]}
              >
                <Text style={[type.caption, { color: c.key === 'kind' ? t.kind[parsed.kind] : t.textPrimary }]}>{c.label}</Text>
              </Animated.View>
            ))}
        </Animated.View>
        <View style={styles.actions}>
          <Pressable onPress={demoType} style={[styles.btn, { backgroundColor: t.bgGrouped }]}>
            <Text style={[styles.btnText, { color: t.textPrimary }]}>Type demo</Text>
          </Pressable>
          <Pressable onPress={save} style={[styles.btn, { backgroundColor: parsed.title ? t.accent : t.separator }]}>
            <Text style={[styles.btnText, { color: '#fff' }]}>Save</Text>
          </Pressable>
        </View>
      </BottomSheetView>
    </BottomSheetModal>
  );
});

const styles = StyleSheet.create({
  body: { padding: space.l, gap: space.l },
  input: { fontFamily: font.regular, fontSize: 17, borderRadius: radius.row, paddingHorizontal: space.l, paddingVertical: space.m },
  chips: { flexDirection: 'row', flexWrap: 'wrap', gap: space.s, minHeight: 32 },
  chip: { borderRadius: radius.chip, paddingHorizontal: space.m, paddingVertical: 6 },
  actions: { flexDirection: 'row', justifyContent: 'flex-end', gap: space.s },
  btn: { borderRadius: radius.row, paddingHorizontal: space.xl, paddingVertical: space.m },
  btnText: { fontFamily: font.semibold, fontSize: 15 },
});
