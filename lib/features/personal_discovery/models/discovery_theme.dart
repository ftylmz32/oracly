/// Observational symbolic themes — never a diagnosis.
library;

import '../../../core/l10n/l10n.dart';

enum DiscoveryTheme {
  love('aşk'),
  relationship('ilişki'),
  career('kariyer'),
  money('para'),
  change('değişim'),
  newBeginning('yeni başlangıç'),
  family('aile'),
  inward('içe dönüş'),
  confidence('özgüven'),
  decision('karar verme'),
  uncertainty('belirsizlik'),
  communication('iletişim'),
  creativity('yaratıcılık'),
  indecision('kararsızlık'),
  boundaries('sınırlar'),
  courage('cesaret'),
  rest('dinlenme'),
  redirection('yön değiştirme');

  const DiscoveryTheme(this.label);
  final String label;

  String get localized => OraclyL10n.t('theme.$name');

  static DiscoveryTheme? resolve(String raw) {
    final v = raw.trim().toLowerCase();
    for (final t in values) {
      if (t.name.toLowerCase() == v || t.label.toLowerCase() == v) {
        return t;
      }
    }
    return null;
  }
}
