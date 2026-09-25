/// Planet + sign name tables for TR/EN/RU grounding sentinels.
library;

import 'yildizname_body_match.dart';

abstract final class YildiznameGroundingLexicon {
  YildiznameGroundingLexicon._();

  static const bodies = <String, List<String>>{
    'sun': ['güneş', 'gunes', 'sun', 'солнц'],
    'moon': ['moon', 'лун', 'ay'],
    'mercury': ['merkür', 'merkur', 'mercury', 'меркур'],
    'venus': ['venüs', 'venus', 'венеры', 'венера'],
    'mars': ['mars', 'марс'],
    'jupiter': ['jüpiter', 'jupiter', 'юпитер'],
    'saturn': ['satürn', 'saturn', 'сатурн'],
    'uranus': ['uranüs', 'uranus', 'уран'],
    'neptune': ['neptün', 'neptune', 'нептун'],
    'pluto': ['plüton', 'pluto', 'плутон'],
    'ascendant': [
      'yükselen',
      'yukselen',
      'rising',
      'ascendant',
      'асцендент',
    ],
    'midheaven': ['midheaven', 'gökyüzü ortası', 'середина неба'],
  };

  static const signs = <String, List<String>>{
    'aries': ['koç', 'koc', 'aries', 'овен'],
    'taurus': ['boğa', 'boga', 'taurus', 'телец', 'тельце'],
    'gemini': ['ikizler', 'gemini', 'близнец'],
    'cancer': ['yengeç', 'yengec', 'cancer', 'рак'],
    'leo': ['aslan', 'leo', 'лев'],
    'virgo': ['başak', 'basak', 'virgo', 'дева', 'деве'],
    'libra': ['terazi', 'libra', 'весы'],
    'scorpio': ['akrep', 'scorpio', 'скорпион'],
    'sagittarius': ['yay', 'sagittarius', 'стрелец'],
    'capricorn': ['oğlak', 'oglak', 'capricorn', 'козерог'],
    'aquarius': ['kova', 'aquarius', 'водолей'],
    'pisces': ['balık', 'balik', 'pisces', 'рыбы'],
  };

  static const aspectWords = <String, List<String>>{
    'conjunction': ['kavuşum', 'kavusum', 'conjunction', 'соединен'],
    'sextile': ['sekstil', 'sextile', 'секстиль'],
    'square': ['kare', 'square', 'квадрат'],
    'trine': ['üçgen', 'ucgen', 'trine', 'трин'],
    'opposition': ['karşıt', 'karsit', 'opposition', 'оппозиц'],
  };

  static bool hasBody(String prose, String body) {
    return YildiznameBodyMatch.has(prose, body, bodies[body] ?? const []);
  }
}
