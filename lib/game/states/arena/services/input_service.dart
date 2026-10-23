/// Keyboard and touch feed the same intent; neither directly mutates fighters.
class InputService {
  final Set<String> keyboard = {};
  final Set<String> touch = {};
  bool _punch = false;
  bool _kick = false;
  bool _jump = false;
  bool held(String key) => keyboard.contains(key) || touch.contains(key);
  double get x => (held('right') ? 1.0 : 0) - (held('left') ? 1.0 : 0);
  double get y => (held('down') ? 1.0 : 0) - (held('up') ? 1.0 : 0);
  void punch() => _punch = true;
  void kick() => _kick = true;
  void jump() => _jump = true;
  bool consumeKick() {
    final result = _kick;
    _kick = false;
    return result;
  }

  bool consumeJump() {
    final result = _jump;
    _jump = false;
    return result;
  }

  bool consumePunch() {
    final result = _punch;
    _punch = false;
    return result;
  }

  void clear() {
    keyboard.clear();
    touch.clear();
    _punch = false;
    _kick = false;
    _jump = false;
  }
}
