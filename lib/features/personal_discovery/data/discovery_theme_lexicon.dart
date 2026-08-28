/// Keyword lexicon for symbolic theme detection. Catalogue only.
library;

import '../models/discovery_theme.dart';

abstract final class DiscoveryThemeLexicon {
  DiscoveryThemeLexicon._();

  static const map = <DiscoveryTheme, List<String>>{
    DiscoveryTheme.love: ['aşk', 'sevgi', 'romant', 'kalp bağı'],
    DiscoveryTheme.relationship: [
      'ilişki',
      'yakınlık',
      'bağ',
      'partner',
      'birlikte',
      'relationship focus',
    ],
    DiscoveryTheme.career: [
      'kariyer',
      'iş hayat',
      'meslek',
      'çalışma',
      'iş alanı',
      'işinde',
    ],
    DiscoveryTheme.money: ['para', 'maddi', 'finans', 'kazanç', 'bütçe'],
    DiscoveryTheme.change: [
      'değişim',
      'dönüşüm',
      'kapanış',
      'geçiş',
      'değiş',
      'hareket',
      'yer değiştir',
    ],
    DiscoveryTheme.newBeginning: [
      'yeni başlangıç',
      'yeniden başla',
      'yeni bir sayfa',
      'sıfırdan',
    ],
    DiscoveryTheme.family: ['aile', 'anne', 'baba', 'kardeş', 'ev halk'],
    DiscoveryTheme.inward: [
      'içe dön',
      'içine',
      'sessizlik',
      'yalnız kal',
      'kendine dön',
      'içsel',
      'introspection',
    ],
    DiscoveryTheme.confidence: [
      'özgüven',
      'kendine güven',
      'güven duy',
      'kendinden emin',
      'kendine değer',
      'öz değer',
    ],
    DiscoveryTheme.decision: [
      'karar',
      'karar ver',
      'karar alma',
      'seçim yap',
      'netleştir',
    ],
    DiscoveryTheme.uncertainty: [
      'belirsiz',
      'net değil',
      'bulanık',
      'muğlak',
    ],
    DiscoveryTheme.communication: [
      'iletişim',
      'konuşmak',
      'anlatmak',
      'dinlemek',
      'diyaloğ',
    ],
    DiscoveryTheme.creativity: ['yarat', 'ifade', 'üret', 'hayal', 'sanat'],
    DiscoveryTheme.indecision: [
      'kararsız',
      'tereddüt',
      'ikilem',
      'emin değil',
      'bilemiyor',
      'seçmekte zor',
    ],
    DiscoveryTheme.boundaries: [
      'sınır',
      'hayır demek',
      'alan tut',
      'mesafe',
      'koru',
    ],
    DiscoveryTheme.courage: [
      'cesaret',
      'cesur',
      'adım at',
      'göze al',
      'korkuya rağmen',
      'decisiveness',
    ],
    DiscoveryTheme.rest: [
      'dinlen',
      'nefes',
      'yavaşla',
      'durul',
      'mola',
      'sakinleş',
    ],
    DiscoveryTheme.redirection: [
      'yön değiştir',
      'yönünü',
      'başka yol',
      'rotanı',
      'yol ayır',
    ],
  };
}
