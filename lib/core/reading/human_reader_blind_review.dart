/// Blind humanness review — text only, no feature labels.
library;

import '../copy/fortune_voice.dart';
import 'human_reader_guard.dart';
import 'robotic_language_detector.dart';

enum BlindFeature {
  coffee,
  palm,
  dream,
  tarot,
  astrology,
  starMap,
  soulMate,
  orCompanion,
}

class BlindTextMarks {
  const BlindTextMarks({
    required this.generic,
    required this.specific,
    required this.human,
    required this.robotic,
    required this.personal,
    required this.nonPersonal,
    required this.falseCertainty,
    required this.identityLeak,
  });

  final bool generic;
  final bool specific;
  final bool human;
  final bool robotic;
  final bool personal;
  final bool nonPersonal;
  final bool falseCertainty;
  final bool identityLeak;
}

class BlindSample {
  const BlindSample({
    required this.feature,
    required this.text,
    this.anchors = const [],
  });

  final BlindFeature feature;
  final String text;
  final List<String> anchors;
}

class BlindFeatureReport {
  const BlindFeatureReport({
    required this.feature,
    required this.total,
    required this.genericCount,
    required this.certaintyCount,
    required this.identityLeakCount,
    required this.samples,
  });

  final BlindFeature feature;
  final int total;
  final int genericCount;
  final int certaintyCount;
  final int identityLeakCount;
  final List<({String text, BlindTextMarks marks})> samples;

  double get genericRate => total == 0 ? 0 : genericCount / total;

  bool get passes =>
      genericRate <= 0.25 && certaintyCount == 0 && identityLeakCount == 0;
}

class BlindReviewReport {
  const BlindReviewReport({
    required this.features,
    required this.total,
    required this.genericCount,
  });

  final List<BlindFeatureReport> features;
  final int total;
  final int genericCount;

  bool get passes =>
      features.every((f) => f.passes) &&
      total >= 50 &&
      genericCount / total <= 0.25;
}

abstract final class HumanReaderBlindReview {
  HumanReaderBlindReview._();

  static const _anyone = [
    'genel rehberlik',
    'her şey yoluna',
    'pozitif enerji',
    'güzel gelişmeler',
    'harika bir dönem',
    'evren seninle',
    'sana ne hatırlatıyor',
  ];

  static String stripUi(String text) {
    var out = text.trim();
    out = out.replaceAll(RegExp(r'^\s*#{1,3}\s+', multiLine: true), '');
    out = out.replaceAll(
      RegExp(
        r'^(ÖZET|YORUM|SEMBOLLER|DUYGU|HAYAT|ADIM|SORU|RÜYA|KART)\b[^\n]*\n+',
        multiLine: true,
        caseSensitive: false,
      ),
      '',
    );
    return out.replaceAll(RegExp(r'\n{3,}'), '\n\n').trim();
  }

  static BlindTextMarks mark(
    String raw, {
    List<String> anchors = const [],
    BlindFeature? feature,
  }) {
    final text = stripUi(raw);
    final lower = text.toLowerCase();
    final report = RoboticLanguageDetector.analyze(text);
    final anchorHit = _anchorHit(lower, anchors);
    final robotic = report.score >= 3 || FortuneVoice.looksRobotic(text);
    final generic = _clearlyGeneric(text, lower, anchorHit, report, robotic);
    final specific = anchorHit || _hasConcreteDetail(lower);
    final personal = anchorHit || _looksPersonal(lower);
    final falseCertainty = _falseCertainty(lower);
    final identityLeak =
        feature == null ? false : _identityLeak(feature, lower);
    return BlindTextMarks(
      generic: generic,
      specific: specific,
      human: !robotic && !generic && text.length >= 40,
      robotic: robotic,
      personal: personal,
      nonPersonal: !personal,
      falseCertainty: falseCertainty,
      identityLeak: identityLeak,
    );
  }

  static BlindReviewReport review(List<BlindSample> samples) {
    final byFeature = <BlindFeature, List<({String text, BlindTextMarks marks})>>{};
    for (final sample in samples) {
      final marks = mark(
        sample.text,
        anchors: sample.anchors,
        feature: sample.feature,
      );
      byFeature.putIfAbsent(sample.feature, () => []).add((text: sample.text, marks: marks));
    }
    final features = BlindFeature.values
        .where(byFeature.containsKey)
        .map((feature) {
          final rows = byFeature[feature]!;
          return BlindFeatureReport(
            feature: feature,
            total: rows.length,
            genericCount: rows.where((r) => r.marks.generic).length,
            certaintyCount: rows.where((r) => r.marks.falseCertainty).length,
            identityLeakCount: rows.where((r) => r.marks.identityLeak).length,
            samples: rows,
          );
        })
        .toList();
    final genericCount = samples
        .where(
          (s) => mark(s.text, anchors: s.anchors, feature: s.feature).generic,
        )
        .length;
    return BlindReviewReport(
      features: features,
      total: samples.length,
      genericCount: genericCount,
    );
  }

  static bool _falseCertainty(String lower) {
    const banned = [
      'kesinlikle',
      'mutlaka olacak',
      'kesin olacak',
      'kaçınılmaz',
      'garanti',
      'yüzde yüz',
      'başınıza gelecek',
      'kesin gelecek',
      'mutlaka başına',
    ];
    return banned.any(lower.contains);
  }

  static bool _identityLeak(BlindFeature feature, String lower) {
    return switch (feature) {
      BlindFeature.coffee =>
        lower.contains('avuç çizgi') || lower.contains('kalp çizgisi'),
      BlindFeature.palm =>
        lower.contains('fincan') || lower.contains('telve'),
      BlindFeature.dream =>
        lower.contains('fincan') || lower.contains('tarot kart'),
      BlindFeature.tarot =>
        lower.contains('fincan') || lower.contains('avuç çizgi'),
      BlindFeature.astrology =>
        lower.contains('fincan') || lower.contains('tarot kart'),
      BlindFeature.starMap =>
        lower.contains('fincan') || lower.contains('telve'),
      BlindFeature.soulMate =>
        lower.contains('fincan') || lower.contains('avuç çizgi'),
      BlindFeature.orCompanion => false,
    };
  }

  static bool _clearlyGeneric(
    String text,
    String lower,
    bool anchorHit,
    RoboticLanguageReport report,
    bool robotic,
  ) {
    if (text.trim().length < 28) return true;
    if (anchorHit &&
        _genericOnlyFromImplementation(text) &&
        !report.isHeavilyRepetitive) {
      return false;
    }
    if (anchorHit && !HumanReaderGuard.looksGeneric(text) && !report.isHeavilyRepetitive) {
      return false;
    }
    // Short reflective probe that still names a concrete image stays human.
    if (_reflectiveProbe(lower) && _hasConcreteDetail(lower)) return false;
    if (_anyone.any(lower.contains) && !anchorHit) return true;
    if (HumanReaderGuard.looksGeneric(text) && !anchorHit) return true;
    if (report.isHeavilyRepetitive && !anchorHit) return true;
    if (robotic && !anchorHit && text.length < 160) return true;
    final sentences =
        text.split(RegExp(r'[.!?]+')).where((s) => s.trim().length > 10).length;
    return sentences <= 1 && !anchorHit;
  }

  static bool _reflectiveProbe(String lower) {
    return lower.contains('?') &&
        (lower.contains('ne zamandır') ||
            lower.contains('hangi') ||
            lower.contains('nerede') ||
            lower.contains('ne oldu'));
  }

  static bool _anchorHit(String lower, List<String> anchors) {
    if (anchors.isEmpty) return _hasConcreteDetail(lower);
    return anchors.any((a) => a.isNotEmpty && lower.contains(a.toLowerCase()));
  }

  static bool _hasConcreteDetail(String lower) {
    const tokens = [
      'kuş', 'yol', 'kalp', 'yüzük', 'dağ', 'anahtar', 'göz', 'ağaç',
      'yılan', 'kapı', 'kedi', 'deniz', 'koç', 'ikizler', 'akrep', 'boğa',
      'eşik', 'tren', 'peron', 'ayna', 'köprü', 'anahtar', 'okul', 'yağmur',
      'mektup', 'ses', 'korku', 'karar',
    ];
    return tokens.any(lower.contains);
  }

  static bool _looksPersonal(String lower) {
    return RegExp(r'\b(ayşe|deniz|ali|selin|senin|son keşif|ilişki|iş)\b')
        .hasMatch(lower);
  }

  static bool _genericOnlyFromImplementation(String text) {
    if (!HumanReaderGuard.looksGeneric(text)) return false;
    var scrubbed = text.toLowerCase();
    for (final phrase in HumanReaderGuard.implementation) {
      scrubbed = scrubbed.replaceAll(phrase.toLowerCase(), '');
    }
    scrubbed = scrubbed.replaceAll(RegExp(r'\s{2,}'), ' ').trim();
    return !HumanReaderGuard.looksGeneric(scrubbed);
  }
}
