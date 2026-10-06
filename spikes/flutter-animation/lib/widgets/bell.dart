// Bell mascot placeholder. Same Rive file as the RN spike; code-animated bell fallback if Rive fails.
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:rive/rive.dart' as rive;

enum Mood { idle, nudge, happy, worried }

// Placeholder: Rive's public "avatar" example (state machine `avatar`, inputs isHappy / isSad).
// When spikes/assets/placeholder.riv is provided, switch to FileLoader.fromAsset(...).
const _riveUrl = 'https://public.rive.app/community/runtime-files/2195-4346-avatar-pack-use-case.riv';
const _artboard = 'Avatar 1';
const _stateMachine = 'avatar';

class Bell extends StatefulWidget {
  final Mood mood;
  final double size;
  const Bell({super.key, required this.mood, this.size = 120});

  @override
  State<Bell> createState() => _BellState();
}

class _BellState extends State<Bell> {
  late final rive.FileLoader _loader = rive.FileLoader.fromUrl(_riveUrl, riveFactory: rive.Factory.rive);
  rive.RiveWidgetController? _controller;
  bool _failed = false;

  @override
  void didUpdateWidget(covariant Bell old) {
    super.didUpdateWidget(old);
    if (old.mood != widget.mood) _applyMood();
  }

  void _applyMood() {
    final sm = _controller?.stateMachine;
    if (sm == null) return;
    sm.boolean('isHappy')?.value = widget.mood == Mood.happy || widget.mood == Mood.nudge;
    sm.boolean('isSad')?.value = widget.mood == Mood.worried;
  }

  @override
  void dispose() {
    _loader.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) return _CodeBell(mood: widget.mood, size: widget.size);
    return SizedBox.square(
      dimension: widget.size,
      child: rive.RiveWidgetBuilder(
        fileLoader: _loader,
        artboardSelector: rive.ArtboardSelector.byName(_artboard),
        stateMachineSelector: rive.StateMachineSelector.byName(_stateMachine),
        onLoaded: (state) {
          _controller = state.controller;
          _applyMood();
        },
        onFailed: (_, _) => setState(() => _failed = true),
        builder: (context, state) => switch (state) {
          rive.RiveLoaded() => rive.RiveWidget(controller: state.controller, fit: rive.Fit.contain),
          rive.RiveFailed() => _CodeBell(mood: widget.mood, size: widget.size),
          _ => const SizedBox.shrink(),
        },
      ),
    );
  }
}

/// Fallback: emoji bell that rings (swings) on nudge and hops when happy.
class _CodeBell extends StatefulWidget {
  final Mood mood;
  final double size;
  const _CodeBell({required this.mood, required this.size});

  @override
  State<_CodeBell> createState() => _CodeBellState();
}

class _CodeBellState extends State<_CodeBell> with TickerProviderStateMixin {
  late final _ring = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
  late final _hop = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));

  @override
  void didUpdateWidget(covariant _CodeBell old) {
    super.didUpdateWidget(old);
    if (widget.mood == Mood.nudge) _ring.forward(from: 0);
    if (widget.mood == Mood.happy) _hop.forward(from: 0);
  }

  @override
  void dispose() {
    _ring.dispose();
    _hop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: widget.size,
      child: AnimatedBuilder(
        animation: Listenable.merge([_ring, _hop]),
        builder: (context, child) {
          final r = math.sin(_ring.value * math.pi * 8) * (1 - _ring.value) * 0.32;
          final y = -math.sin(_hop.value * math.pi) * 24;
          return Transform.translate(offset: Offset(0, y), child: Transform.rotate(angle: r, child: child));
        },
        child: Center(
          child: Text(widget.mood == Mood.worried ? '🔕' : '🔔', style: TextStyle(fontSize: widget.size * 0.7)),
        ),
      ),
    );
  }
}
