import '../states/arena/model/arena_config.dart';

class LevelDefinition {
  final String title;
  final int enemyCount;
  final ArenaConfig arena;
  const LevelDefinition(
      {required this.title,
      required this.enemyCount,
      this.arena = const ArenaConfig()});
}

class LevelResult {
  final bool cleared;
  final int hits, defeated, healthRemaining;
  const LevelResult(
      {required this.cleared,
      required this.hits,
      required this.defeated,
      required this.healthRemaining});
  int get healthBonus => cleared ? healthRemaining * 25 : 0;
  int get score => hits * 10 + defeated * 100 + healthBonus;
}

/// Run progress survives level worlds. A score is recorded once per level.
class CampaignModel {
  final List<LevelDefinition> levels;
  int levelIndex = 0;
  int totalScore = 0;
  LevelResult? result;
  CampaignModel({List<LevelDefinition>? levels})
      : levels = List.unmodifiable(levels ??
            const [
              LevelDefinition(title: 'NIGHT STREET / 01', enemyCount: 5),
              LevelDefinition(title: 'NIGHT STREET / 02', enemyCount: 7),
            ]) {
    if (this.levels.isEmpty || this.levels.any((l) => l.enemyCount < 1)) {
      throw ArgumentError('A campaign needs levels with at least one enemy.');
    }
  }
  LevelDefinition get level => levels[levelIndex];
  bool get hasNextLevel => levelIndex + 1 < levels.length;
  bool get canAdvance => result?.cleared == true && hasNextLevel;
  bool get completed => result?.cleared == true && !hasNextLevel;
  void reset() {
    levelIndex = 0;
    totalScore = 0;
    result = null;
  }

  void recordResult(LevelResult value) {
    if (result != null) return;
    result = value;
    totalScore += value.score;
  }

  bool advance() {
    if (!canAdvance) return false;
    levelIndex++;
    result = null;
    return true;
  }
}
