import 'package:flutter/material.dart';

import 'spike/alarm_spike_page.dart';

/// v0: the app currently boots straight into the alarm reliability spike (ROADMAP v0).
void main() {
  runApp(const ReminderApp());
}

class ReminderApp extends StatelessWidget {
  const ReminderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Reminder App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: const Color(0xFF007AFF), useMaterial3: true),
      darkTheme: ThemeData(colorSchemeSeed: const Color(0xFF0A84FF), brightness: Brightness.dark, useMaterial3: true),
      home: const AlarmSpikePage(),
    );
  }
}
