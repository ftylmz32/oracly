/// Observational ritual lines keyed by real discovery themes.
library;

import '../../../core/l10n/l10n.dart';
import '../../personal_discovery/models/discovery_theme.dart';

abstract final class DailyRitualThemeLines {
  DailyRitualThemeLines._();

  static List<String> forTheme(String theme, {required bool hasDiscoveries}) {
    final label = theme.trim();
    if (label.isEmpty) return const [];
    final soft = [
      for (var i = 0; i < 4; i++)
        OraclyL10n.t('daily.theme.soft.$i').replaceAll('{theme}', label),
    ];
    // Non-TR: soft localized pool only (rich TR families stay TR-native).
    if (OraclyL10n.code != AppLocale.tr) {
      if (!hasDiscoveries) return soft;
      final backed = [
        for (var i = 0; i < 4; i++)
          OraclyL10n.t('daily.theme.backed.$i').replaceAll('{theme}', label),
      ];
      return [...backed, ...soft];
    }
    final family = _family(DiscoveryTheme.resolve(label));
    final filled = [
      for (final line in family) line.replaceAll('{theme}', label),
    ];
    if (!hasDiscoveries) return filled;
    final backed = [
      for (var i = 0; i < 4; i++)
        OraclyL10n.t('daily.theme.backed.$i').replaceAll('{theme}', label),
    ];
    return [...backed, ...filled];
  }

  static List<String> _family(DiscoveryTheme? id) {
    return switch (id) {
      DiscoveryTheme.communication => _talk,
      DiscoveryTheme.decision ||
      DiscoveryTheme.indecision ||
      DiscoveryTheme.uncertainty =>
        _choice,
      DiscoveryTheme.love || DiscoveryTheme.relationship => _close,
      DiscoveryTheme.career || DiscoveryTheme.money => _work,
      DiscoveryTheme.boundaries => _edge,
      DiscoveryTheme.change ||
      DiscoveryTheme.newBeginning ||
      DiscoveryTheme.redirection =>
        _shift,
      DiscoveryTheme.rest || DiscoveryTheme.inward => _rest,
      DiscoveryTheme.courage ||
      DiscoveryTheme.confidence ||
      DiscoveryTheme.creativity =>
        _fire,
      DiscoveryTheme.family => _kin,
      _ => _soft,
    };
  }

  static const _talk = [
    'Zihninde kalan o konuşma, acele edilmiş bir {theme} cevabından daha dürüst '
        'duruyor olabilir.',
    'Bir konuşmayı zorlamak değil, {theme} içinde onu içeride dinlemek daha doğru.',
    'Küçük bir sonraki adım: {theme} konusunda söylemediğin konuşmayı tek cümlede '
        'yazmak yeter.',
  ];

  static const _choice = [
    'Karar vermek istiyorsun ama sonucundan çok, yanlış karar verme ihtimali '
        'seni tutuyor gibi — {theme} burada duruyor.',
    'Bir kararı netleştirmek değil, {theme} hissini daha dürüstçe görmek daha doğru.',
    'Küçük bir sonraki adım: {theme} içinde tek bir seçeneği elemek yeter.',
  ];

  static const _close = [
    '{theme} hissi, zorlanmış bir kapanıştan daha doğru duruyor olabilir.',
    'Bir yakınlığı çözmek değil, {theme} için biraz yer bırakmak daha doğru.',
    'Küçük bir sonraki adım: {theme} konusunda kendine nazik bir sınır koymak yeter.',
  ];

  static const _work = [
    '{theme} baskısı, acele bir karardan daha fazla şey söylüyor olabilir.',
    'Bir işi bitirmek değil, {theme} alanına daha dürüst bir mesafe koymak daha doğru.',
    'Küçük bir sonraki adım: {theme} içinde tek görünür teslimi kapatmak yeter.',
  ];

  static const _edge = [
    '{theme} hissi yeniden belirdiğinde, evet demekten daha sakin duruyor olabilir.',
    'Bir sınırı büyütmek değil, {theme} içinde onu net görmek daha doğru.',
    'Küçük bir sonraki adım: {theme} konusunda küçük bir hayır söylemek yeter.',
  ];

  static const _shift = [
    '{theme} içinde neyin kıpırdadığını görmek, her şeyi değiştirmekten daha gerçek.',
    'Zihninde kalan {theme} hissi, zorlanmış bir başlangıçtan daha gerçek duruyor olabilir.',
    'Küçük bir sonraki adım: {theme} konusunda tek bir eski alışkanlığı bırakmak yeter.',
  ];

  static const _rest = [
    '{theme} ihtiyacı içeride duruyor; bu bir uyarı değil, yavaşlama daveti.',
    'Üretmek değil, biraz {theme} için durmak daha doğru durabilir.',
    'Küçük bir sonraki adım: {theme} için kısa bir boşluk bırakmak yeter.',
  ];

  static const _fire = [
    '{theme} kıvılcımı, büyük bir jestten daha gerçek duruyor olabilir.',
    'Cesur görünmek değil, {theme} konusunda durduğun yeri hissetmek daha doğru.',
    'Küçük bir sonraki adım: {theme} konusunda küçük bir görünür hareket yeter.',
  ];

  static const _kin = [
    '{theme} hissi, acele bir konuşmadan daha sakin duruyor olabilir.',
    'Bir {theme} ilişkisini düzeltmek değil, ona daha dürüst bakmak daha doğru.',
    'Küçük bir sonraki adım: {theme} konusunda dinlemek, konuşmaktan önce gelir.',
  ];

  static const _soft = [
    '{theme} konusu zihninde duruyor; acele bir yorumdan daha dürüst bakmak yeter.',
    'Bir {theme} sorusunu çözmek değil, onu görmek daha doğru durabilir.',
    'Küçük bir sonraki adım: {theme} konusunda yeni anlam aramadan durmak yeter.',
    '{theme} için bugün ayrılmış yer, onu zorla netleştirmekten daha sakin.',
  ];
}
