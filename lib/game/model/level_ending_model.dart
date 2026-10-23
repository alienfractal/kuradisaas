import 'campaign_model.dart';

enum LevelEndingPhase { playing, finishing, popup, complete }

/// The session clock owns the ending. Rendering never advances its phases.
class LevelEndingModel {
  static const minimumFinishTime = .9;
  static const popupDuration = 1.6;
  LevelEndingPhase phase = LevelEndingPhase.playing;
  LevelResult? result;
  double elapsed = 0;
  bool get active => phase != LevelEndingPhase.playing;
  bool get showPopup => phase == LevelEndingPhase.popup;
  bool get complete => phase == LevelEndingPhase.complete;

  void begin(LevelResult outcome) {
    if (active) return;
    result = outcome;
    elapsed = 0;
    phase = LevelEndingPhase.finishing;
  }

  void update(double dt, {required bool animationsFinished}) {
    if (!active || complete) return;
    elapsed += dt;
    if (phase == LevelEndingPhase.finishing &&
        elapsed >= minimumFinishTime &&
        animationsFinished) {
      phase = LevelEndingPhase.popup;
      elapsed = 0;
    } else if (showPopup && elapsed >= popupDuration) {
      phase = LevelEndingPhase.complete;
    }
  }

  void reset() {
    phase = LevelEndingPhase.playing;
    result = null;
    elapsed = 0;
  }
}
