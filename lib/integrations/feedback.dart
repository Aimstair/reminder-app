/// Completion feedback (design-direction §6, PRF-12): haptic + chime. Uses the notification audio
/// stream, so it stays silent when the phone is on silent or vibrate.
library;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

class CompletionFeedback {
  AudioPlayer? _player;

  Future<void> done({required bool sound}) async {
    await HapticFeedback.mediumImpact();
    if (!sound) return;
    try {
      final p = _player ??= AudioPlayer()
        ..setAudioContext(
          AudioContext(
            android: const AudioContextAndroid(
              usageType: AndroidUsageType.notificationEvent,
              contentType: AndroidContentType.sonification,
              audioFocus: AndroidAudioFocus.gainTransientMayDuck,
            ),
          ),
        );
      await p.stop();
      await p.play(AssetSource('sounds/chime.wav'), volume: 0.6);
    } catch (_) {
      // Sound is a nicety; never fail the action because of it.
    }
  }

  Future<void> tap() => HapticFeedback.selectionClick();
}
