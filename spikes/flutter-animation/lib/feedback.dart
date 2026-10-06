// Completion feedback: sound (PRF-12, default on) + haptic
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

class AppFeedback {
  final _pop = AudioPlayer()..setPlayerMode(PlayerMode.lowLatency);
  final _chime = AudioPlayer()..setPlayerMode(PlayerMode.lowLatency);
  bool soundOn = true;

  Future<void> init() async {
    await _pop.setSource(AssetSource('sounds/pop.wav'));
    await _chime.setSource(AssetSource('sounds/chime.wav'));
  }

  void complete() {
    HapticFeedback.mediumImpact();
    if (soundOn) {
      _pop.stop();
      _pop.resume();
    }
  }

  void celebrate() {
    if (soundOn) {
      _chime.stop();
      _chime.resume();
    }
  }

  void tick() => HapticFeedback.selectionClick();
}
