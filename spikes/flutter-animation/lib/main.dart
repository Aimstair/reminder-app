// Animation bake-off — Flutter prototype (docs/spikes/animation-bakeoff.md)
import 'package:flutter/material.dart';
import 'package:rive/rive.dart' as rive;

import 'feedback.dart';
import 'scenes/nudges_scene.dart';
import 'scenes/schedule_scene.dart';
import 'theme.dart';
import 'widgets/fps_meter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await rive.RiveNative.init();
  final feedback = AppFeedback();
  await feedback.init();
  runApp(BakeoffApp(feedback: feedback));
}

class BakeoffApp extends StatelessWidget {
  final AppFeedback feedback;
  const BakeoffApp({super.key, required this.feedback});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bakeoff Flutter',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(fontFamily: 'Inter', brightness: Brightness.light),
      darkTheme: ThemeData(fontFamily: 'Inter', brightness: Brightness.dark),
      home: Shell(feedback: feedback),
    );
  }
}

enum _Tab { nudges, schedule }

class Shell extends StatefulWidget {
  final AppFeedback feedback;
  const Shell({super.key, required this.feedback});
  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  _Tab _tab = _Tab.schedule;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Scaffold(
      backgroundColor: c.bgGrouped,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Space.l, vertical: Space.s),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(color: c.separator, borderRadius: BorderRadius.circular(Radii.chip)),
                        child: Row(
                          children: [
                            for (final t in _Tab.values)
                              GestureDetector(
                                onTap: () => setState(() => _tab = t),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  padding: const EdgeInsets.symmetric(horizontal: Space.m, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: _tab == t ? c.surface : Colors.transparent,
                                    borderRadius: BorderRadius.circular(Radii.chip - 2),
                                  ),
                                  child: Text(t == _Tab.nudges ? 'A · Nudges' : 'B–D · Schedule',
                                      style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w500, fontSize: 13, color: c.textPrimary)),
                                ),
                              ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          Text('Sound', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w500, fontSize: 13, color: c.textSecondary)),
                          Switch.adaptive(
                            value: widget.feedback.soundOn,
                            onChanged: (v) => setState(() => widget.feedback.soundOn = v),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _tab == _Tab.nudges
                      ? NudgesScene(onTick: widget.feedback.tick)
                      : ScheduleScene(feedback: widget.feedback),
                ),
              ],
            ),
            const Positioned(top: 4, right: 8, child: FpsMeter()),
          ],
        ),
      ),
    );
  }
}
