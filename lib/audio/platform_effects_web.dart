import 'audio_player_wrapper.dart';
import 'effects_backend.dart';
import 'game_audio_backend.dart';
import 'recorded_effects.dart';
import 'midi/midi_effects.dart';
import 'midi/web_midi_synth.dart';

Map<EffectsMode, EffectsBackend> createEffects(AudioPlayerWrapper recordings) =>
    {
      EffectsMode.midi: MidiEffects(WebMidiSynth()),
      EffectsMode.mp3: RecordedEffects(recordings),
    };
