import 'package:flutter_test/flutter_test.dart';
import 'package:kuradi_saased/game/model/campaign_model.dart';
import 'package:kuradi_saased/game/model/level_ending_model.dart';

void main() {
  const win =
      LevelResult(cleared: true, hits: 3, defeated: 1, healthRemaining: 8);
  const loss =
      LevelResult(cleared: false, hits: 1, defeated: 0, healthRemaining: 0);
  test('ending requires both the minimum hold and finished animations', () {
    final ending = LevelEndingModel();
    ending.begin(win);
    ending.update(.5, animationsFinished: true);
    expect(ending.showPopup, isFalse);
    ending.update(.5, animationsFinished: false);
    expect(ending.showPopup, isFalse);
    ending.begin(loss);
    expect(ending.result, same(win));
    ending.update(.01, animationsFinished: true);
    expect(ending.showPopup, isTrue);
    ending.update(1.5, animationsFinished: true);
    expect(ending.complete, isFalse);
    ending.update(.11, animationsFinished: true);
    expect(ending.complete, isTrue);
    ending.update(5, animationsFinished: true);
    expect(ending.result, same(win));
  });
  test('a new level clears the outcome, popup and ending timer', () {
    final ending = LevelEndingModel()..begin(loss);
    ending.update(1, animationsFinished: true);
    expect(ending.showPopup, isTrue);
    ending.reset();
    expect(ending.active, isFalse);
    expect(ending.result, isNull);
    expect(ending.elapsed, 0);
    ending.update(5, animationsFinished: true);
    expect(ending.phase, LevelEndingPhase.playing);
  });
}
