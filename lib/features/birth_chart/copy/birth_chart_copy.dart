/// SPRINT-002 — Birth Chart user-facing copy.
library;

abstract final class BirthChartCopy {
  BirthChartCopy._();

  static const screenTitle = 'Doğum Haritası';
  static const onboardingHeadline = 'Doğum anın';
  static const onboardingDescription =
      'Gökyüzünün o andaki düzenini anlamak için birkaç bilgi yeterli.';
  static const birthDateLabel = 'Doğum tarihi';
  static const birthTimeLabel = 'Doğum saati';
  static const birthTimeUnknown = 'Saati bilmiyorum';
  static const birthTimeUnknownNote =
      'Saat bilinmediğinde Yükselen burcun ve ev yerleşimlerin '
      'daha az kesin olabilir. Yine de anlamlı bir yolculuk sunuyoruz.';
  static const birthPlaceLabel = 'Doğum yeri';
  static const birthPlaceHint = 'Örn. İstanbul, Ankara…';
  static const birthDateRequired = 'Doğum tarihini seç.';
  static const birthPlaceRequired = 'Doğum yerini yaz.';
  static const generateChart = 'Haritamı oluştur';
  static const continueJourney = 'Devam et';
  static const finishJourney = 'Tamamla';
  static const stepOf = 'Adım';

  static const generating = 'Haritan hesaplanıyor…';
  static const translating = 'Anlamlandırılıyor…';

  static const bigThreeTitle = 'Büyük Üçlü';
  static const bigThreeSubtitle =
      'Güneş, Ay ve Yükselen — haritanın üç temel rengi.';
  static const sunLabel = 'Güneş';
  static const sunGlossary =
      'Güneş burcu, özünü ve vitrini temsil eder — dışarıya '
      'nasıl parladığını anlatır.';
  static const moonLabel = 'Ay';
  static const moonGlossary =
      'Ay burcu, duygusal dünyanı ve içsel ihtiyaçlarını yansıtır.';
  static const risingLabel = 'Yükselen';
  static const risingGlossary =
      'Yükselen, tanışıldığında görünen yüzün — ilk izlenim '
      've yaşam yaklaşımınla ilişkilidir.';
  static const risingUnavailable =
      'Saat bilinmediği için Yükselen hesaplanamadı.';

  static const corePersonalityTitle = 'Temel kişilik';
  static const strengthsTitle = 'Güçlü yönler';
  static const growthTitle = 'Gelişim alanları';
  static const relationshipsTitle = 'İlişkiler';
  static const careerTitle = 'Kariyer ve amaç';
  static const emotionalTitle = 'Duygusal kalıplar';
  static const lifeThemesTitle = 'Yaşam temaları';

  static const closingNote =
      'Bu harita bir etiket değil; kendini tanımak için bir ayna. '
      'En doğru yorumu zamanla sen yazarsın.';
}
