import 'midi_note.dart';

/// Renderer owns note-on/off scheduling and voice cleanup, including delayed notes.
abstract interface class MidiSynth {
  void unlock();
  void play(MidiNote note, {bool walking = false});
  void stopWalking();
  void stopEffects();
  void setVolume(double volume);
  void dispose();
}
