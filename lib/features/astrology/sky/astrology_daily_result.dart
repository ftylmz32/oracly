/// Daily astrology writer result → [AstrologyDailyReading], fail-closed.
///
/// Mirrors backend `parseAstrologyDailyResult` so a response that slipped
/// past an older server is still refused on the device.
library;

import '../../../core/l10n/l10n.dart';
import '../../personal_discovery/copy/personal_theme_copy.dart';
import '../models/astrology_daily_reading.dart';
import 'astrology_natal_sky.dart';

const kAstrologyDailyResultVersion = 1;

const kAstrologyDailyFields = [
  'portrait',
  'overall',
  'love',
  'career',
  'money',
  'mood',
  'drive',
  'opportunity',
  'caution',
  'reflection',
];

class AstrologyDailyResultException implements Exception {
  const AstrologyDailyResultException(this.reason);
  final String reason;

  @override
  String toString() => 'AstrologyDailyResultException($reason)';
}

abstract final class AstrologyDailyResult {
  AstrologyDailyResult._();

  static int _ceiling(String field) => switch (field) {
        'portrait' => 420,
        'overall' => 900,
        'reflection' => 220,
        _ => 650,
      };

  static final _technique = RegExp(
    r'(kare açı|üçgen açı|karşıtlık|kavuşum|altmışlık|transit|\borb\b|derece|\d+\.\s*ev)',
    caseSensitive: false,
  );
  static final _refs =
      RegExp(r'(\bf\.\w+|\bhit\.\d|factRef|natalHouse|addressName|```|\{)');
  static final _timeOnly =
      RegExp(r'(yükselen|ascendant|\bMC\b|tepe noktası)', caseSensitive: false);
  static final _greeting =
      RegExp(r'(?<![\p{L}])(sevgili|merhaba)(?![\p{L}])', caseSensitive: false, unicode: true);
  /// The reading must not describe its own structure.
  static final _meta = RegExp(
    r'(bu alan|cephe|uyarı alanı|bulgu yok|doğuştan gelen)',
    caseSensitive: false,
  );
  static final _orders = RegExp(
    r'(?<![\p{L}])(dene|unutma|kendine izin ver|dikkat et|harekete geç|yapmalısın|etmelisin)(?![\p{L}])',
    caseSensitive: false,
    unicode: true,
  );
  static final _fixedFuture = [
    RegExp(r'(?<![\p{L}])(kesinlikle|mutlaka|garanti)(?![\p{L}])',
        caseSensitive: false, unicode: true),
    RegExp(r'(?<![\p{L}])\p{L}+(?:ecek|acak)s[ıi]n(?:[ıi]z)?(?![\p{L}])',
        caseSensitive: false, unicode: true),
  ];

  /// Validated fields keyed by [kAstrologyDailyFields].
  static final _pastReadings = RegExp(
    r'(son okuma|önceki okuma|geçmiş okuma|okumalarında)',
    caseSensitive: false,
  );

  /// [hasThemes]: real recurring themes were sent, so a light mention of
  /// past readings has evidence behind it.
  static Map<String, String> validate(
    Map<String, dynamic> raw, {
    required NatalSkyDepth depth,
    String? addressName,
    bool hasThemes = false,
  }) {
    if (raw['contractVersion'] != kAstrologyDailyResultVersion) {
      throw const AstrologyDailyResultException('version');
    }
    final out = <String, String>{};
    for (final f in kAstrologyDailyFields) {
      final v = raw[f];
      if (v is! String) throw AstrologyDailyResultException('missing $f');
      final t = v.trim();
      if (t.isEmpty || t.length > _ceiling(f)) {
        throw AstrologyDailyResultException('length $f');
      }
      out[f] = t;
    }
    final all = out.values.join('\n');
    void refuse(bool hit, String why) {
      if (hit) throw AstrologyDailyResultException(why);
    }

    refuse(_refs.hasMatch(all), 'refs');
    refuse(_technique.hasMatch(all), 'technique');
    refuse(_greeting.hasMatch(all), 'greeting');
    refuse(_meta.hasMatch(all), 'meta');
    refuse(_orders.hasMatch(all), 'orders');
    refuse(_fixedFuture.any((r) => r.hasMatch(all)), 'fixed future');
    refuse(depth == NatalSkyDepth.dayOnly && _timeOnly.hasMatch(all),
        'time-only layer');
    refuse(!hasThemes && _pastReadings.hasMatch(all), 'past readings');
    refuse(!out['reflection']!.endsWith('?'), 'reflection');

    final seen = <String>{};
    for (final f in const ['overall', 'love', 'career', 'money']) {
      for (final s in _sentences(out[f]!)) {
        refuse(!seen.add(s), 'repeated sentence');
      }
    }
    final name = addressName?.trim() ?? '';
    if (name.isNotEmpty) {
      final count = RegExp(
        r'(?<![\p{L}])' + RegExp.escape(name) + r'(?![\p{L}])',
        unicode: true,
      ).allMatches(all).length;
      refuse(count > 2, 'name repeated');
    }
    return out;
  }

  static AstrologyDailyReading toReading(
    Map<String, String> f, {
    required NatalSkyDepth depth,
    List<String> themes = const [],
  }) {
    final full = depth == NatalSkyDepth.full;
    return AstrologyDailyReading(
      personality: f['portrait']!,
      overall: f['overall']!,
      love: f['love']!,
      career: f['career']!,
      money: f['money']!,
      emotion: f['mood']!,
      energy: f['drive']!,
      opportunity: f['opportunity']!,
      caution: f['caution']!,
      advice: f['reflection']!,
      innerTheme: themes.isEmpty
          ? PersonalThemeCopy.insufficient
          : PersonalThemeCopy.crossModal(themes),
      lovePersonal: true,
      careerPersonal: true,
      basis: full
          ? AstrologyReadingBasis.skyFull
          : AstrologyReadingBasis.skyDayOnly,
      basisNote: OraclyL10n.t(full ? 'astro.basis_full' : 'astro.basis_day_only'),
    );
  }

  static Iterable<String> _sentences(String text) => text
      .split(RegExp(r'(?<=[^0-9][.!?…])\s+'))
      .map((s) => s.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' '))
      .where((s) => s.length > 12);
}
