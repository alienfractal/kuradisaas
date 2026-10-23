import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'kuradi_saased.dart';
import 'game/view/game_controls_overlay.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final game = KuradiSaased();
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'Kuradi Sääsed',
    theme: ThemeData.dark(useMaterial3: true),
    home: Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: Listener(
        onPointerDown: (_) => game.notifyUserGesture(),
        child: GameWidget<KuradiSaased>(
          game: game,
          overlayBuilderMap: {
            'controls': (context, game) => GameControlsOverlay(game: game)
          },
          initialActiveOverlays: const ['controls'],
          loadingBuilder: (_) => const Center(child: Text('LOADING SPRITES…')),
          errorBuilder: (_, error) =>
              Center(child: Text('Loading failed: $error')),
        ),
      ),
    ),
  ));
}
