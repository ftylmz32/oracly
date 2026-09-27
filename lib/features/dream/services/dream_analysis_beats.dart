/// Seeded dream-reading turns. Curious, grounded, never a dictionary.
library;

import '../../../core/l10n/l10n.dart';
import 'dream_analysis_facts.dart';

abstract final class DreamAnalysisBeats {
  DreamAnalysisBeats._();

  static String feeling(DreamAnalysisFacts facts, int seed) {
    if (facts.isEmpty) return _t(facts, 'dream.read.feeling.empty');
    final emotion = facts.emotion;
    if (emotion != null) {
      final slot = facts.scene.isEmpty ? 0 : seed % 3;
      return _fill(facts, 'dream.read.feeling.emotion.$slot', {
        'emotion': _soft(emotion),
        'scene': facts.scene,
      });
    }
    if (facts.scene.isEmpty) {
      return _t(facts, 'dream.read.feeling.empty');
    }
    return _fill(facts, 'dream.read.feeling.scene.${seed % 2}', {
      'scene': facts.scene,
    });
  }

  static String detail(DreamAnalysisFacts facts, int seed) {
    final detail = facts.detail;
    if (detail == null || detail.isEmpty) {
      return _t(facts, 'dream.read.detail.empty');
    }
    return _fill(facts, 'dream.read.detail.${seed % 3}', {'detail': detail});
  }

  static String symbolic(DreamAnalysisFacts facts, int seed) {
    if (facts.isEmpty) return _t(facts, 'dream.read.symbol.empty');
    final image = facts.image;
    if (image == null) {
      if (facts.scene.isEmpty) {
        return _t(facts, 'dream.read.symbol.empty');
      }
      return _fill(facts, 'dream.read.symbol.fog.0', {'scene': facts.scene});
    }
    if (facts.companion != null &&
        seed % 3 == 2 &&
        facts.companion!.toLowerCase() != image.toLowerCase()) {
      return _fill(facts, 'dream.read.symbol.image.2', {
        'image': image,
        'companion': facts.companion!,
      });
    }
    if (facts.place != null &&
        seed % 3 == 1 &&
        facts.place!.toLowerCase() != image.toLowerCase()) {
      return _fill(facts, 'dream.read.symbol.image.1', {
        'image': image,
        'place': facts.place!,
      });
    }
    return _fill(facts, 'dream.read.symbol.image.0', {
      'image': image,
      'scene': facts.scene.isEmpty ? image : facts.scene,
    });
  }

  static String you({
    required DreamAnalysisFacts facts,
    required String? date,
    required List<String> sharedSymbols,
  }) {
    if (date != null && sharedSymbols.isNotEmpty) {
      return _fill(facts, 'dream.read.you.pattern', {
        'date': date,
        'symbols': sharedSymbols.join(', '),
      });
    }
    final tag = facts.tag;
    if (tag == null) return '';
    return _fill(facts, 'dream.read.you.tag', {
      'tag': tag,
      'image': facts.image ?? facts.detail ?? 'bu sahne',
    });
  }

  static String ask(DreamAnalysisFacts facts, int seed) {
    final image = facts.image ?? facts.person;
    if (image == null) {
      return _t(facts, 'dream.read.ask.open.${seed % 2}');
    }
    return _fill(facts, 'dream.read.ask.image.${seed % 2}', {'image': image});
  }

  static String _soft(String emotion) => emotion.trim().toLowerCase();

  static String _t(DreamAnalysisFacts facts, String key) =>
      OraclyL10n.t(key, languageCode: facts.language);

  static String _fill(
    DreamAnalysisFacts facts,
    String key,
    Map<String, String> vars,
  ) {
    var out = _t(facts, key);
    for (final entry in vars.entries) {
      out = out.replaceAll('{${entry.key}}', entry.value);
    }
    return out.replaceAll(RegExp(r'\s{2,}'), ' ').trim();
  }
}
