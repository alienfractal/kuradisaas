import 'audio_player_wrapper.dart';
import 'effects_backend.dart';
import 'game_audio_backend.dart';
import 'recorded_effects.dart';

Map<EffectsMode, EffectsBackend> createEffects(AudioPlayerWrapper recordings) =>
    {
      EffectsMode.mp3: RecordedEffects(recordings),
    };
