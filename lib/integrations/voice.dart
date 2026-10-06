/// Voice capture (FL-3): speech → text, then the normal parse preview (CAP-7). On-device where the
/// phone supports it.
library;

import 'package:speech_to_text/speech_to_text.dart';

class VoiceInput {
  final _speech = SpeechToText();
  bool _ready = false;

  bool get listening => _speech.isListening;

  /// False when the phone has no speech recognizer or the microphone is denied.
  Future<bool> init() async {
    if (_ready) return true;
    try {
      _ready = await _speech.initialize();
    } catch (_) {
      _ready = false;
    }
    return _ready;
  }

  /// Streams partial text to [onText]; [onDone] gets the final text ('' if nothing was heard).
  Future<bool> listen({required void Function(String) onText, required void Function(String) onDone}) async {
    if (!await init()) return false;
    await _speech.listen(
      onResult: (r) {
        onText(r.recognizedWords);
        if (r.finalResult) onDone(r.recognizedWords);
      },
      listenOptions: SpeechListenOptions(
        partialResults: true,
        cancelOnError: true,
        listenFor: const Duration(seconds: 20),
        pauseFor: const Duration(seconds: 3),
      ),
    );
    return true;
  }

  Future<void> stop() => _speech.stop();
}
