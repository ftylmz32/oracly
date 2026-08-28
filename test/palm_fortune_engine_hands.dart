/// Provider-backed palm visions for the final engine test.
library;

import 'package:oracly_new/features/palm/models/palm_hand.dart';
import 'package:oracly_new/features/palm/models/palm_reading.dart';

class PalmEngineHand {
  const PalmEngineHand({
    required this.id,
    required this.hand,
    required this.overall,
    this.heart = '',
    this.head = '',
    this.life = '',
    this.fate = '',
    this.symbols = const [],
    this.themes = const [],
    this.mustContain = const [],
    this.mustNot = const [],
  });

  final String id;
  final PalmHand hand;
  final String overall;
  final String heart;
  final String head;
  final String life;
  final String fate;
  final List<String> symbols;
  final List<String> themes;
  final List<String> mustContain;
  final List<String> mustNot;

  PalmReading toReading() => PalmReading(
        id: id,
        createdAt: DateTime(2026, 8, 18),
        hand: hand,
        overall: overall,
        heartLine: heart,
        headLine: head,
        lifeLine: life,
        fateLine: fate,
        symbols: symbols,
        themes: themes,
      );
}

const palmFortuneEngineHands = <PalmEngineHand>[
  PalmEngineHand(
    id: 'h0',
    hand: PalmHand.right,
    overall: 'Kalp = aşk. Zihin = zeka. El açık ve sakin duruyor.',
    heart: 'Kalp çizgisi belirgin.',
    head: 'Zihin çizgisi net.',
    mustContain: ['açık', 'belirgin', 'net'],
    mustNot: ['=', 'temsil', 'ömür', 'hastal'],
  ),
  PalmEngineHand(
    id: 'h1',
    hand: PalmHand.right,
    overall: 'Avuç geniş, çizgiler seçilir.',
    heart: 'Kalp çizgisi yakınlık temasını taşıyor.',
    head: 'Zihin çizgisi karar anlarını hatırlatıyor.',
    life: 'Yaşam çizgisi kavisli.',
    fate: 'Yön çizgisi zayıf.',
    symbols: ['yıldız'],
    mustContain: ['geniş', 'kavisli', 'yıldız'],
    mustNot: ['kırık', 'dallan', 'ömür'],
  ),
  PalmEngineHand(
    id: 'h2',
    hand: PalmHand.left,
    overall: 'Avuçta duruluk var.',
    mustContain: ['duruluk'],
    mustNot: ['kalp çizgisi', 'kırık', 'uzun'],
  ),
  PalmEngineHand(
    id: 'h3',
    hand: PalmHand.right,
    overall: 'Yaşam çizgisi uzun ömür demektir.',
    life: 'Yaşam çizgisi kavisli ve sakin.',
    mustContain: ['kavisli'],
    mustNot: ['ömür', 'hastal', '='],
  ),
  PalmEngineHand(
    id: 'h4',
    hand: PalmHand.right,
    overall: 'El yumuşak, çizgiler derin değil.',
    heart: 'Kalp çizgisinin belirgin yapısı.',
    head: 'Zihin çizgisi biraz daha sakin.',
    themes: ['ilişki'],
    mustContain: ['belirgin', 'ilişki'],
    mustNot: ['vazgeçmeyen', 'temsil'],
  ),
  PalmEngineHand(
    id: 'h5',
    hand: PalmHand.left,
    overall: 'Avuç dik, parmaklar uzun duruyor.',
    fate: 'Yön çizgisi ince ve seçilir.',
    themes: ['kariyer'],
    mustContain: ['dik', 'yön', 'kariyer'],
    mustNot: ['kalp çizgisi', 'kırık'],
  ),
  PalmEngineHand(
    id: 'h6',
    hand: PalmHand.right,
    overall: 'Avuç loş, bazı izler silik.',
    heart: 'Kalp çizgisi net değil.',
    mustContain: ['net değil'],
    mustNot: ['temsil eder', 'sadakat', '=', 'alışkanlık', 'korumak'],
  ),
  PalmEngineHand(
    id: 'h7',
    hand: PalmHand.left,
    overall: 'Sol avuç biraz daha toplanmış duruyor.',
    head: 'Zihin çizgisi düz ve sakin.',
    fate: 'Yön çizgisi orta yerde duruyor.',
    themes: ['değişim'],
    mustContain: ['toplanmış', 'düz', 'değişim'],
    mustNot: ['hastal', 'ömür', 'kalp çizgisi'],
  ),
  PalmEngineHand(
    id: 'h8',
    hand: PalmHand.right,
    overall: 'El sıcak bir ritim taşıyor.',
    heart: 'Kalp çizgisi avucun üstünde seçilir.',
    life: 'Yaşam çizgisi kavisli.',
    mustContain: ['sıcak', 'üstünde', 'kavisli'],
    mustNot: ['dallanma', 'kırık', '='],
  ),
  PalmEngineHand(
    id: 'h9',
    hand: PalmHand.right,
    overall: 'Kalp = aşk. Zihin = zeka. Yaşam = enerji. Yön = kader.',
    heart: 'Kalp çizgisi kısa durmuyor; belirgin bir yay.',
    head: 'Zihin çizgisi net bir ritim okutuyor.',
    life: 'Yaşam çizgisi dengeli görünüyor.',
    fate: 'Yön teması bir sapmayı ima ediyor.',
    mustContain: ['belirgin', 'ritim', 'dengeli'],
    mustNot: ['=', 'temsil', 'ömür', 'hastal'],
  ),
];
