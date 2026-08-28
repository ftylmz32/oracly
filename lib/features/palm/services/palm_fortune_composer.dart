/// Grounds palm copy in vision lines. Never invents medical facts.
library;

import '../data/palm_observation.dart';
import '../models/palm_reading.dart';
import 'palm_fortune_story.dart';

abstract final class PalmFortuneComposer {
  PalmFortuneComposer._();

  static PalmReading compose(
    PalmReading raw, {
    List<String> themes = const [],
  }) {
    return PalmReading(
      id: raw.id,
      createdAt: raw.createdAt,
      hand: raw.hand,
      imagePath: raw.imagePath,
      overall: PalmFortuneStory.build(raw, themes: themes),
      heartLine: PalmObservation.line(raw.heartLine),
      headLine: PalmObservation.line(raw.headLine),
      lifeLine: PalmObservation.line(raw.lifeLine),
      fateLine: PalmObservation.line(raw.fateLine),
      takeaway: PalmObservation.line(raw.takeaway),
      symbols: PalmObservation.marks(raw.symbols),
      themes: raw.themes,
    );
  }
}
