/// OR-1150 — Oracle wisdom messages catalogue.
library;

import '../models/oracle_message_content.dart';

abstract final class OracleContentCatalogue {
  OracleContentCatalogue._();

  static List<OracleMessageContent> get all => _messages;

  static OracleMessageContent randomByTheme(OracleMessageTheme theme) {
    final filtered = _messages.where((m) => m.theme == theme).toList();
    return filtered.isNotEmpty ? filtered.first : _messages.first;
  }

  static const _messages = [
    OracleMessageContent(
      id: 'oracle_001',
      title: 'Sessizlik',
      body: 'Cevap gürültüde değil, derin sessizlikte saklıdır.',
      theme: OracleMessageTheme.reflection,
      source: 'OR Oracle',
    ),
    OracleMessageContent(
      id: 'oracle_002',
      title: 'Adım',
      body: 'Evren büyük adımları değil, bilinçli küçük adımları ödüllendirir.',
      theme: OracleMessageTheme.action,
      source: 'OR Oracle',
    ),
    OracleMessageContent(
      id: 'oracle_003',
      title: 'Işık',
      body: 'Karanlık seni yutmaz; yalnızca kendi ışığını hatırlamanı ister.',
      theme: OracleMessageTheme.blessing,
      source: 'OR Oracle',
    ),
    OracleMessageContent(
      id: 'oracle_004',
      title: 'Denge',
      body: 'Aşırılık her kapıyı kapatır; orta yol kalbin kapısını açık tutar.',
      theme: OracleMessageTheme.guidance,
      source: 'OR Oracle',
    ),
    OracleMessageContent(
      id: 'oracle_005',
      title: 'Bırakış',
      body: 'Tutunduğun şey seni tutar; özgürlük bırakmakla başlar.',
      theme: OracleMessageTheme.warning,
      source: 'OR Oracle',
    ),
  ];
}
