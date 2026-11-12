import 'effects_backend.dart';
import 'game_audio_backend.dart';

/// Owns mode changes and transfers volume/walking intent without replaying hits.
class SelectableEffects implements EffectsBackend {
  SelectableEffects(Map<EffectsMode, EffectsBackend> backends)
      : _backends = Map.unmodifiable(backends),
        _mode = backends.keys.first,
        _active = backends.values.first;

  final Map<EffectsMode, EffectsBackend> _backends;
  EffectsBackend _active;
  EffectsMode _mode;
  Future<void> _pending = Future.value();
  int _revision = 0;
  bool _ready = true, _walking = false, _disposed = false;
  double _volume = 1;

  EffectsMode get mode => _mode;
  Set<EffectsMode> get supportedModes => Set.unmodifiable(_backends.keys);

  Future<void> select(EffectsMode mode) {
    if (_disposed) return Future.value();
    if (!_backends.containsKey(mode)) {
      return Future.error(UnsupportedError('Unavailable effects mode: $mode'));
    }
    if (_mode == mode) return _pending;
    _mode = mode;
    _ready = false;
    final revision = ++_revision;
    // Stop immediately, before queued preparation, including scheduled MIDI notes.
    final stopped = _active.stop();
    _pending = Future.wait([_pending.catchError((Object _) {}), stopped])
        .then((_) async {
      if (_disposed || revision != _revision) return;
      final next = _backends[mode]!;
      await next.setVolume(_volume);
      await next.preload();
      if (_disposed || revision != _revision) return;
      _active = next;
      _ready = true;
      if (_walking) next.startWalking();
    }).catchError((Object error, StackTrace stack) {
      if (!_disposed && revision == _revision) {
        _mode =
            _backends.entries.firstWhere((entry) => entry.value == _active).key;
        _ready = true;
        if (_walking) _active.startWalking();
      }
      Error.throwWithStackTrace(error, stack);
    });
    return _pending;
  }

  @override
  Future<void> preload() => _active.preload();
  @override
  void play(SoundCue cue) {
    if (!_disposed && _ready) _active.play(cue);
  }

  @override
  void startWalking() {
    if (_disposed) return;
    _walking = true;
    if (_ready) _active.startWalking();
  }

  @override
  void stopWalking() {
    _walking = false;
    _active.stopWalking();
  }

  @override
  Future<void> stop() {
    _walking = false;
    return _active.stop();
  }

  @override
  Future<void> setVolume(double volume) async {
    if (_disposed) return;
    if (!volume.isFinite) throw ArgumentError.value(volume, 'volume');
    _volume = volume.clamp(0.0, 1.0);
    // Apply to every renderer so a pending selection always sees the latest gain.
    await Future.wait(
        _backends.values.map((backend) => backend.setVolume(_volume)));
  }

  @override
  void notifyUserGesture() {
    if (_disposed) return;
    for (final backend in _backends.values) {
      backend.notifyUserGesture();
    }
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _revision++;
    _walking = false;
    await Future.wait(_backends.values.map((backend) => backend.dispose()));
  }
}
