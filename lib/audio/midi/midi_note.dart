/// Validated MIDI event data; program numbers are zero-based GM slots.
final class MidiNote {
  MidiNote({
    required this.note,
    required this.program,
    this.channel = 0,
    this.velocity = 90,
    this.duration = const Duration(milliseconds: 90),
    this.delay = Duration.zero,
  }) {
    RangeError.checkValueInInterval(channel, 0, 15, 'channel');
    RangeError.checkValueInInterval(note, 0, 127, 'note');
    RangeError.checkValueInInterval(program, 0, 127, 'program');
    RangeError.checkValueInInterval(velocity, 1, 127, 'velocity');
    RangeError.checkValueInInterval(
        duration.inMicroseconds, 1, 2000000, 'duration');
    RangeError.checkValueInInterval(delay.inMicroseconds, 0, 1000000, 'delay');
  }

  final int channel, note, program, velocity;
  final Duration duration, delay;
}
