/// Provider-backed coffee cups for the fortune engine gold gate.
library;

import 'package:oracly_new/features/coffee/models/coffee_symbol.dart';

class CoffeeFortuneEngineCup {
  const CoffeeFortuneEngineCup({
    required this.id,
    required this.observation,
    required this.symbols,
    this.overall = 'Kuş = haber. Yol = yolculuk.',
    this.themes = const [],
    this.trust = CoffeeMarkTrust.high,
  });

  final String id;
  final String observation;
  final List<String> symbols;
  final String overall;
  final List<String> themes;
  final CoffeeMarkTrust trust;
}

const coffeeFortuneEngineCups = [
  CoffeeFortuneEngineCup(
    id: 'v-bird-road',
    observation:
        'Ağızda kuşa benzeyen bir şekil, hemen yanında ince açık bir çizgi.',
    symbols: ['kuş', 'yol'],
  ),
  CoffeeFortuneEngineCup(
    id: 'v-heart-ring',
    observation: 'Duvarda kalbe benzeyen küme; yanında halka izi.',
    symbols: ['kalp', 'yüzük'],
  ),
  CoffeeFortuneEngineCup(
    id: 'v-road-key',
    observation: 'Ağızda yol gibi açıklık, kulpa yakın anahtara benzeyen iz.',
    symbols: ['yol', 'anahtar'],
    themes: ['değişim'],
  ),
  CoffeeFortuneEngineCup(
    id: 'v-mountain',
    observation: 'Dipte dağ gibi duran yoğun telve.',
    symbols: ['dağ'],
  ),
  CoffeeFortuneEngineCup(
    id: 'v-bird',
    observation: 'Ağızda uçan bir forma benzeyen telve.',
    symbols: ['kuş'],
  ),
  CoffeeFortuneEngineCup(
    id: 'v-eye-road',
    observation: 'Duvarda göze benzeyen açıklık, yanında açık çizgi.',
    symbols: ['göz', 'yol'],
  ),
  CoffeeFortuneEngineCup(
    id: 'v-tree-road',
    observation: 'Dipte ağaca benzeyen küme, ondan çıkan ince yol.',
    symbols: ['ağaç', 'yol'],
  ),
  CoffeeFortuneEngineCup(
    id: 'v-letter',
    observation: 'Ağızda mektuba benzeyen kırık çizgiler.',
    symbols: ['mektup'],
  ),
  CoffeeFortuneEngineCup(
    id: 'v-heart',
    observation: 'Kulpa yakın kalbe benzeyen küçük küme.',
    symbols: ['kalp'],
  ),
  CoffeeFortuneEngineCup(
    id: 'v-key',
    observation: 'Duvarda anahtara benzeyen bir iz, net değil kapalı.',
    symbols: ['anahtar'],
    trust: CoffeeMarkTrust.mid,
  ),
];
