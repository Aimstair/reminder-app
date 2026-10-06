// Frame meter: FPS and janky frames (> 25 ms) per second (bake-off M1, matches the RN meter).
import 'package:flutter/scheduler.dart';
import 'package:flutter/material.dart';

class FpsMeter extends StatefulWidget {
  const FpsMeter({super.key});
  @override
  State<FpsMeter> createState() => _FpsMeterState();
}

class _FpsMeterState extends State<FpsMeter> with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  Duration _windowStart = Duration.zero;
  Duration _last = Duration.zero;
  int _frames = 0, _jank = 0, _fps = 0, _jankShown = 0;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
  }

  void _onTick(Duration now) {
    if (_last != Duration.zero && (now - _last).inMilliseconds > 25) _jank++;
    _last = now;
    _frames++;
    if ((now - _windowStart).inMilliseconds >= 1000) {
      setState(() {
        _fps = _frames;
        _jankShown = _jank;
      });
      _frames = 0;
      _jank = 0;
      _windowStart = now;
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(6)),
        child: Text('$_fps fps · $_jankShown jank',
            style: const TextStyle(color: Colors.white, fontSize: 11, fontFeatures: [FontFeature.tabularFigures()])),
      ),
    );
  }
}
