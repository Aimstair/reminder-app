// Scene B (list + completion), C (capture sheet), D (All clear) — docs/spikes/animation-bakeoff.md
import { useCallback, useMemo, useRef, useState } from 'react';
import { Pressable, StyleSheet, Text, View } from 'react-native';
import type { BottomSheetModal } from '@gorhom/bottom-sheet';
import Animated, {
  FadeInDown,
  FadeOut,
  LinearTransition,
  SlideInDown,
  SlideOutDown,
  useReducedMotion,
} from 'react-native-reanimated';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { AllClear } from '../components/AllClear';
import { CaptureSheet, type Parsed } from '../components/CaptureSheet';
import { ReminderRow } from '../components/ReminderRow';
import { GROUPS, makeReminders, type Reminder } from '../data';
import { font, radius, space, type, useTheme } from '../theme';

type Item = { type: 'header'; id: string; label: string } | { type: 'row'; id: string; item: Reminder };

type Props = { feedback: { complete: () => void; celebrate: () => void } };

export function ScheduleScene({ feedback }: Props) {
  const t = useTheme();
  const insets = useSafeAreaInsets();
  const reduceMotion = useReducedMotion();
  const [list, setList] = useState<Reminder[]>(() => makeReminders(200));
  const [lastRemoved, setLastRemoved] = useState<{ item: Reminder; index: number } | null>(null);
  const [newId, setNewId] = useState<string | null>(null);
  const [celebrating, setCelebrating] = useState(false);
  const [autoIds, setAutoIds] = useState<Set<string>>(new Set());
  const sheet = useRef<BottomSheetModal>(null);

  const items = useMemo<Item[]>(() => {
    const out: Item[] = [];
    for (const g of GROUPS) {
      const rows = list.filter((r) => r.group === g);
      if (!rows.length) continue;
      out.push({ type: 'header', id: `h-${g}`, label: g });
      rows.forEach((r) => out.push({ type: 'row', id: r.id, item: r }));
    }
    return out;
  }, [list]);

  const listRef = useRef(list);
  listRef.current = list;

  const onCompleted = useCallback(
    (item: Reminder) => {
      const prev = listRef.current;
      const index = prev.findIndex((r) => r.id === item.id);
      if (index < 0) return;
      const next = prev.filter((r) => r.id !== item.id);
      listRef.current = next;
      setList(next);
      setLastRemoved({ item, index });
      const todayLeft = next.some((r) => r.group === 'Today');
      if (item.group === 'Today' && !todayLeft && !reduceMotion) {
        setCelebrating(true);
        feedback.celebrate();
      }
    },
    [feedback, reduceMotion],
  );

  const undo = () => {
    if (!lastRemoved) return;
    setList((prev) => {
      const next = [...prev];
      next.splice(lastRemoved.index, 0, lastRemoved.item);
      return next;
    });
    setNewId(lastRemoved.item.id);
    setLastRemoved(null);
  };

  const onSave = (p: Parsed) => {
    const r: Reminder = { id: `new-${Date.now()}`, title: p.title, when: p.when, kind: p.kind, group: 'Today', work: false };
    setNewId(r.id);
    setList((prev) => [r, ...prev]);
    sheet.current?.dismiss();
  };

  // Rapid test: complete the next 10 rows, one every 400 ms (bake-off Scene B)
  const rapid = () => {
    const ids = list.slice(0, 10).map((r) => r.id);
    ids.forEach((id, i) => setTimeout(() => setAutoIds((s) => new Set(s).add(id)), i * 400));
  };

  const renderItem = ({ item }: { item: Item }) =>
    item.type === 'header' ? (
      <Text style={[type.headline, styles.header, { color: item.label === 'Overdue' ? t.danger : t.textPrimary }]}>
        {item.label}
      </Text>
    ) : (
      <Animated.View entering={item.id === newId ? FadeInDown.springify().damping(15) : undefined} exiting={FadeOut.duration(180)}>
        <ReminderRow
          item={item.item}
          onCompleted={onCompleted}
          onFeedback={feedback.complete}
          autoComplete={autoIds.has(item.id)}
        />
      </Animated.View>
    );

  return (
    <View style={[styles.flex, { backgroundColor: t.bgGrouped }]}>
      <Animated.FlatList
        data={items}
        keyExtractor={(i) => i.id}
        renderItem={renderItem}
        itemLayoutAnimation={LinearTransition.springify().damping(18)}
        contentContainerStyle={{ paddingBottom: 120 + insets.bottom }}
        ListHeaderComponent={
          <View style={styles.titleRow}>
            <Text style={[type.largeTitle, { color: t.textPrimary }]}>Schedule</Text>
            <Pressable onPress={rapid} style={[styles.smallBtn, { backgroundColor: t.surface }]}>
              <Text style={[styles.smallBtnText, { color: t.accent }]}>Rapid ×10</Text>
            </Pressable>
          </View>
        }
      />

      <Pressable
        onPress={() => sheet.current?.present()}
        style={[styles.fab, { backgroundColor: t.accent, bottom: 24 + insets.bottom }]}
        accessibilityLabel="New reminder"
      >
        <Text style={styles.fabPlus}>+</Text>
      </Pressable>

      {lastRemoved && (
        <Animated.View
          key={lastRemoved.item.id}
          entering={SlideInDown.springify().damping(16)}
          exiting={SlideOutDown.duration(160)}
          style={[styles.snack, { bottom: 96 + insets.bottom }]}
        >
          <Text style={styles.snackText}>Done</Text>
          <Pressable onPress={undo} hitSlop={10}>
            <Text style={[styles.snackText, { color: '#0A84FF', fontFamily: font.semibold }]}>Undo</Text>
          </Pressable>
        </Animated.View>
      )}

      <CaptureSheet ref={sheet} onSave={onSave} />
      {celebrating && <AllClear onDone={() => setCelebrating(false)} />}
    </View>
  );
}

const styles = StyleSheet.create({
  flex: { flex: 1 },
  titleRow: { flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', paddingHorizontal: space.l, paddingTop: space.s, paddingBottom: space.s },
  header: { paddingHorizontal: space.l + 4, paddingTop: space.xl, paddingBottom: space.s },
  smallBtn: { borderRadius: radius.chip, paddingHorizontal: space.m, paddingVertical: 6 },
  smallBtnText: { fontFamily: font.semibold, fontSize: 13 },
  fab: { position: 'absolute', right: 20, width: 58, height: 58, borderRadius: 29, alignItems: 'center', justifyContent: 'center', elevation: 4, shadowColor: '#000', shadowOpacity: 0.2, shadowRadius: 8, shadowOffset: { width: 0, height: 4 } },
  fabPlus: { color: '#fff', fontSize: 32, lineHeight: 34, fontFamily: font.regular },
  snack: { position: 'absolute', left: space.l, right: space.l, flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', backgroundColor: '#1C1C1E', borderRadius: radius.row, paddingHorizontal: space.l, paddingVertical: space.m },
  snackText: { color: '#fff', fontFamily: font.regular, fontSize: 15 },
});
