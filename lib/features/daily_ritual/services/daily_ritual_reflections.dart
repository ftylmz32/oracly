/// EPIC-011 — Thoughtful daily reflections tied to living universe state.
library;

import '../../../core/universe/oracly_living_event.dart';
import '../../../core/universe/oracly_moon_phase.dart';
import '../../../core/universe/oracly_ritual_time.dart';
import '../../../core/universe/oracly_season.dart';
import '../../../core/universe/oracly_universe_state.dart';

/// Deterministic, atmosphere-aware copy — never predictive, never urgent.
abstract final class DailyRitualReflections {
  DailyRitualReflections._();

  static String welcome(OraclyUniverseState state) => switch (state.ritualTime) {
        OraclyRitualTime.morning => 'Gözlemevi sabah ışığıyla açılıyor.',
        OraclyRitualTime.afternoon => 'Gün ortasında bir nefes molası.',
        OraclyRitualTime.evening => 'Akşamın yumuşak eşiğindesin.',
        OraclyRitualTime.night => 'Gece sakinliği seni karşılıyor.',
      };

  static String teaser(OraclyUniverseState state) {
    if (state.livingEvent != null) {
      return 'Bugün gökyüzünde nadir bir an var. Bir düşünce seni bekliyor.';
    }
    return 'Bugün için sessiz bir düşünce hazır.';
  }

  static String reflection(OraclyUniverseState state) {
    final dayKey =
        state.moment.year * 10000 + state.moment.month * 100 + state.moment.day;
    final pool = _poolFor(state);
    return pool[dayKey % pool.length];
  }

  static String closing() =>
      'Gözlemevi sakinleşiyor. Döndüğünde yine burada olacak.';

  static List<String> _poolFor(OraclyUniverseState state) {
    final ritual = state.ritualTime;
    final season = state.season;
    final moon = state.moonPhase;

    if (state.livingEvent?.kind == OraclyLivingEventKind.shootingStar) {
      return _shootingStar;
    }
    if (moon == OraclyMoonPhase.fullMoon) {
      return _fullMoon;
    }

    return switch (ritual) {
      OraclyRitualTime.morning => switch (season) {
          OraclySeason.spring => _morningSpring,
          OraclySeason.summer => _morningSummer,
          OraclySeason.autumn => _morningAutumn,
          OraclySeason.winter => _morningWinter,
        },
      OraclyRitualTime.afternoon => _afternoon,
      OraclyRitualTime.evening => _evening,
      OraclyRitualTime.night => _night,
    };
  }

  static const _morningSpring = [
    'Sabahın ilk ışığı acele etmeden dinlemeni ister. Bugün küçük bir adım yeter — kendine nazik ol.',
    'Yeni bir gün, temiz bir sayfa değil; devam eden bir hikâye. Nerede kaldığını fark etmen yeterli.',
    'Baharın nefesi gibi: büyümek için baskı gerekmez. Sadece açılmak.',
  ];

  static const _morningSummer = [
    'Gün parlak olsa da iç sesin fısıltı kadar değerli. Bir an durup dinle.',
    'Sabah enerjisi dağılmadan önce, kendine bir cümle ayır. Bu yeter.',
    'Bugün her şeyi çözmek zorunda değilsin. Sadece ne hissettiğini fark et.',
  ];

  static const _morningAutumn = [
    'Sonbahar gibi: bırakmak da bir tür büyümek. Bugün neyi hafifletebilirsin?',
    'Sabah sessizliği, dünün yükünü taşımadan başlaman için bir davet.',
    'Değişim korkutucu olabilir — ama sen değişimin içindesin, dışında değil.',
  ];

  static const _morningWinter = [
    'Kış sabahları yavaşlatır. Bu yavaşlık bir eksiklik değil, bir lütuf.',
    'Soğuk hava dışarıda; sıcaklık içeride aranır. Bugün kendine sığınak ol.',
    'Kısa günler uzun düşüncelere yer açar. Bir nefes al, gerisi bekleyebilir.',
  ];

  static const _afternoon = [
    'Günün ortasında durmak lüks değil, ihtiyaç. Şu an tam buradasın — bu yeterli.',
    'Öğleden sonra yorgunluğu normal. Kendini zorlamadan bir an geri çekil.',
    'Bugün şimdiye kadar ne yaptığın kadar, ne hissettiğin de önemli.',
    'Gün devam ediyor ama sen durabilirsin. Bir dakika bile fark yaratır.',
  ];

  static const _evening = [
    'Akşam, günü yargılamak için değil, anlamak için gelir. Nazikçe bak.',
    'Gün biterken ne kaldığını değil, ne öğrendiğini düşün — küçük de olsa.',
    'Alacakaranlık geçişlerin rengidir. Sen de bir geçişin içindesin.',
    'Bugün mükemmel olmak zorunda değildi. Yeterince insandın.',
  ];

  static const _night = [
    'Gece, cevap aramak için değil — dinlenmek için. Zihnin yavaşlayabilir.',
    'Karanlık bir tehdit değil; düşüncelerin sakinleştiği bir örtü.',
    'Uyumadan önce bir cümle yazmak, zihni hafifletir. Zorunlu değil — davet.',
    'Gece geç saatlerde burada olmak da bir tercih. Kendine yargı yok.',
  ];

  static const _fullMoon = [
    'Dolunay aydınlatır ama kör etmez. Bugün gördüklerine güven — ama acele etme.',
    'Dolunay geceleri duygular yükselir. Bu dalga seni sürüklemek zorunda değil.',
    'Parlak bir gece; iç sesin de duyulabilir. Dinle, ama karar vermek zorunda değilsin.',
  ];

  static const _shootingStar = [
    'Nadir bir an: gökyüzü kısa bir selam verdi. Bugün küçük mucizelere açık ol.',
    'Kayan yıldızlar geçicidir — tıpkı bu an gibi. Burada olman yeterli.',
    'Evren bugün fısıldıyor. Cevap beklemek zorunda değilsin; sadece fark et.',
  ];
}
