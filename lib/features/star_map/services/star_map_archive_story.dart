/// Four connected archive chapters. Never invents natal sky.
library;

import '../../../core/reading/human_reader.dart';
import '../../personal_discovery/copy/personal_theme_copy.dart';
import '../models/star_map_reading.dart';
import 'star_map_archive_beats.dart';

abstract final class StarMapArchiveStory {
  StarMapArchiveStory._();

  static String composeToday({
    required String sign,
    required String catalog,
    required String life,
    int seed = 0,
  }) {
    final mark = life.trim().isNotEmpty ? life : catalog;
    return HumanReader.guard(
      StarMapArchiveBeats.today(mark: mark, sign: sign, seed: seed),
    );
  }

  static String composeSky({
    required String sign,
    required String catalog,
    required String life,
    int seed = 0,
  }) {
    final mark = life.trim().isNotEmpty ? life : catalog;
    return HumanReader.guard(
      StarMapArchiveBeats.sky(mark: mark, sign: sign, seed: seed + 1),
    );
  }

  static String knot(StarMapReading reading, {int seed = 0}) {
    final inner = reading.innerThemesLine.trim();
    if (!_hasEvidence(inner)) {
      return HumanReader.guard(StarMapArchiveBeats.knot('', seed: seed));
    }
    final thread = _hasEvidence(reading.todayReflection)
        ? reading.todayReflection
        : inner;
    return HumanReader.guard(
      StarMapArchiveBeats.knot(thread, seed: seed),
    );
  }

  static String recent(StarMapReading reading, {int seed = 0}) {
    return HumanReader.guard(
      StarMapArchiveBeats.recent(reading.recurringThemesLine, seed: seed),
    );
  }

  static String threshold(StarMapReading reading, {int seed = 0}) {
    final life = _firstEvidence([
      reading.innerThemesLine,
      reading.recurringThemesLine,
      reading.todayReflection,
    ]);
    return HumanReader.guard(StarMapArchiveBeats.gate(life, seed));
  }

  static String leaveQuestion(StarMapReading reading, {int seed = 0}) {
    final life = _firstEvidence([
      reading.innerThemesLine,
      reading.recurringThemesLine,
      reading.todayReflection,
    ]);
    return HumanReader.guard(StarMapArchiveBeats.ask(life, seed));
  }

  static bool _hasEvidence(String line) {
    final text = line.trim();
    return text.isNotEmpty && text != PersonalThemeCopy.insufficient;
  }

  static String _firstEvidence(List<String> lines) {
    for (final line in lines) {
      if (_hasEvidence(line)) return line.trim();
    }
    return '';
  }
}
