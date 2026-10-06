// Completion feedback: sound (PRF-12, default on) + haptic
import * as Haptics from 'expo-haptics';
import { setAudioModeAsync, useAudioPlayer } from 'expo-audio';
import { useCallback, useEffect } from 'react';

export function useFeedback(soundOn: boolean) {
  const pop = useAudioPlayer(require('../assets/sounds/pop.wav'));
  const chime = useAudioPlayer(require('../assets/sounds/chime.wav'));

  useEffect(() => {
    // Respect silent mode on iOS; Android follows the media volume
    setAudioModeAsync({ playsInSilentMode: false }).catch(() => {});
  }, []);

  const complete = useCallback(() => {
    Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success).catch(() => {});
    if (soundOn) {
      pop.seekTo(0);
      pop.play();
    }
  }, [pop, soundOn]);

  const celebrate = useCallback(() => {
    if (soundOn) {
      chime.seekTo(0);
      chime.play();
    }
  }, [chime, soundOn]);

  const tick = useCallback(() => {
    Haptics.selectionAsync().catch(() => {});
  }, []);

  return { complete, celebrate, tick };
}
