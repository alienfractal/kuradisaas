import 'package:kuradi_saased/gen/fonts.gen.dart';
import 'dart:ui' show ViewFocusEvent, ViewFocusState;
import 'package:flutter/material.dart';
import '../../kuradi_saased.dart';
import '../../gamefsm/game_fsm.dart';
import 'cga_palette.dart';

/// Flutter hosts touch controls and focus handling. Global screens are Flame worlds.
class GameControlsOverlay extends StatefulWidget {
  final KuradiSaased game;
  const GameControlsOverlay({super.key, required this.game});
  @override
  State<GameControlsOverlay> createState() => _GameControlsOverlayState();
}

class _GameControlsOverlayState extends State<GameControlsOverlay>
    with WidgetsBindingObserver {
  KuradiSaased get game => widget.game;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _pauseIfPlaying() {
    if (game.fsm.phase == GlobalGameState.level) game.togglePause();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) _pauseIfPlaying();
  }

  @override
  void didChangeViewFocus(ViewFocusEvent event) {
    if (event.state == ViewFocusState.unfocused) _pauseIfPlaying();
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<GlobalGameState>(
        valueListenable: game.phase,
        builder: (context, phase, _) {
          if (phase != GlobalGameState.level) return const SizedBox.shrink();
          return ValueListenableBuilder<bool>(
            valueListenable: game.combatInputEnabled,
            builder: (context, enabled, _) {
              if (!enabled) return const SizedBox.shrink();
              return Stack(children: [
                Positioned(
                    top: 32,
                    right: 12,
                    child: _HoldButton(
                        label: const _ControlGlyph('pause'),
                        semanticLabel: 'Pause',
                        onDown: game.togglePause,
                        onUp: () {},
                        width: 36,
                        height: 28)),
                Positioned(
                    left: 14,
                    bottom: 12,
                    child: Column(children: [
                      _direction('up'),
                      Row(children: [
                        _direction('left'),
                        _direction('down'),
                        _direction('right')
                      ]),
                    ])),
                Positioned(
                    right: 12,
                    bottom: 12,
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          _action('JUMP', game.input.jump),
                          Row(mainAxisSize: MainAxisSize.min, children: [
                            _action('PUNCH', game.input.punch),
                            _action('KICK', game.input.kick),
                          ]),
                        ])),
              ]);
            },
          );
        },
      );
  Widget _action(String label, VoidCallback onDown) => _HoldButton(
      label: Text(label,
          style: const TextStyle(
              fontFamily: FontFamily.arcade,
              fontSize: 8,
              color: CgaPalette.white)),
      semanticLabel: label,
      onDown: onDown,
      onUp: () {},
      width: 62,
      height: 36);
  Widget _direction(String direction) => _HoldButton(
      label: _ControlGlyph(direction),
      semanticLabel: direction,
      onDown: () => game.input.touch.add(direction),
      onUp: () => game.input.touch.remove(direction));
}

class _HoldButton extends StatefulWidget {
  final Widget label;
  final VoidCallback onDown, onUp;
  final double width, height;
  final String? semanticLabel;
  const _HoldButton(
      {required this.label,
      required this.onDown,
      required this.onUp,
      this.semanticLabel,
      this.width = 42,
      this.height = 35});
  @override
  State<_HoldButton> createState() => _HoldButtonState();
}

class _HoldButtonState extends State<_HoldButton> {
  final Set<int> pointers = {};
  void release(PointerEvent event) {
    pointers.remove(event.pointer);
    if (pointers.isEmpty) {
      widget.onUp();
      setState(() {});
    }
  }

  @override
  void dispose() {
    if (pointers.isNotEmpty) widget.onUp();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
      button: true,
      label: widget.semanticLabel,
      child: Listener(
        onPointerDown: (event) {
          pointers.add(event.pointer);
          widget.onDown();
          setState(() {});
        },
        onPointerUp: release,
        onPointerCancel: release,
        child: Container(
            width: widget.width,
            height: widget.height,
            margin: const EdgeInsets.all(2),
            alignment: Alignment.center,
            decoration: BoxDecoration(
                color: pointers.isEmpty ? CgaPalette.black : CgaPalette.magenta,
                border: Border.all(color: CgaPalette.cyan)),
            child: widget.label),
      ));
}

/// Integer pixel glyphs avoid Material icon shades and antialiased edges.
class _ControlGlyph extends StatelessWidget {
  const _ControlGlyph(this.symbol);
  final String symbol;
  @override
  Widget build(BuildContext context) => SizedBox(
      width: 20,
      height: 20,
      child: CustomPaint(painter: _GlyphPainter(symbol)));
}

class _GlyphPainter extends CustomPainter {
  const _GlyphPainter(this.symbol);
  final String symbol;
  static const patterns = {
    'up': [
      '0001000',
      '0011100',
      '0111110',
      '1111111',
      '0001000',
      '0001000',
      '0001000'
    ],
    'down': [
      '0001000',
      '0001000',
      '0001000',
      '1111111',
      '0111110',
      '0011100',
      '0001000'
    ],
    'left': [
      '0001000',
      '0011000',
      '0111000',
      '1111111',
      '0111000',
      '0011000',
      '0001000'
    ],
    'right': [
      '0001000',
      '0001100',
      '0001110',
      '1111111',
      '0001110',
      '0001100',
      '0001000'
    ],
    'pause': [
      '0110110',
      '0110110',
      '0110110',
      '0110110',
      '0110110',
      '0110110',
      '0110110'
    ],
  };
  @override
  void paint(Canvas canvas, Size size) {
    final rows = patterns[symbol]!;
    final paint = Paint()
      ..color = CgaPalette.white
      ..isAntiAlias = false;
    for (var y = 0; y < 7; y++) {
      for (var x = 0; x < 7; x++) {
        if (rows[y][x] == '1') {
          canvas.drawRect(Rect.fromLTWH(3 + x * 2.0, 3 + y * 2.0, 2, 2), paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _GlyphPainter old) => old.symbol != symbol;
}
