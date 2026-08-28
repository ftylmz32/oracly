/// Keşif karşılaştırma — TR / EN / RU.
library;

import '../l10n_triple.dart';

const kL10nDiscoveryComparison = <String, L10nTriple>{
  'compare.title': L10nTriple(
    'Keşif Karşılaştırma',
    'Discovery Comparison',
    'Сравнение открытий',
  ),
  'compare.before': L10nTriple('ÖNCE', 'BEFORE', 'РАНЬШЕ'),
  'compare.now': L10nTriple('ŞİMDİ', 'NOW', 'СЕЙЧАС'),
  'compare.action': L10nTriple(
    'Karşılaştır',
    'Compare',
    'Сравнить',
  ),
  'compare.unavailable': L10nTriple(
    'Bu iki keşif için anlamlı bir karşılaştırma çıkmadı.',
    'No meaningful comparison came through for these two discoveries.',
    'Для этих двух открытий не удалось составить содержательное сравнение.',
  ),
  'compare.stable': L10nTriple(
    'Her iki keşifte de {theme} teması görünür.',
    'The theme of {theme} is visible in both discoveries.',
    'Тема {theme} заметна в обоих открытиях.',
  ),
  'compare.shift.tarot': L10nTriple(
    'Önceki açılımda {earlier} öne çıkarken, son açılımda {later} daha belirgin.',
    'While {earlier} stood out in the earlier reading, {later} is clearer in the latest one.',
    'Когда в прошлом раскладе выделялось {earlier}, в последнем заметнее {later}.',
  ),
  'compare.shift.daily': L10nTriple(
    'Önceki mesajda {earlier} öne çıkarken, son mesajda {later} daha belirgin.',
    'While {earlier} stood out in the earlier message, {later} is clearer in the latest one.',
    'Когда в прошлом послании выделялось {earlier}, в последнем заметнее {later}.',
  ),
  'compare.shift.astrology': L10nTriple(
    'Önceki okumada {earlier} öne çıkarken, son okumada {later} daha belirgin.',
    'While {earlier} stood out in the earlier reading, {later} is clearer in the latest one.',
    'Когда в прошлом чтении выделялось {earlier}, в последнем заметнее {later}.',
  ),
  'compare.shift.star': L10nTriple(
    'Önceki yıldızname okumasında {earlier} öne çıkarken, son okumada {later} daha belirgin.',
    'While {earlier} stood out in the earlier star reading, {later} is clearer in the latest one.',
    'Когда в прошлом чтении звёзд выделялось {earlier}, в последнем заметнее {later}.',
  ),
  'compare.shift.or': L10nTriple(
    'Önceki yansımada {earlier} öne çıkarken, son yansımada {later} daha belirgin.',
    'While {earlier} stood out in the earlier reflection, {later} is clearer in the latest one.',
    'Когда в прошлом размышлении выделялось {earlier}, в последнем заметнее {later}.',
  ),
  'compare.obstacle_direction.tarot': L10nTriple(
    'Önceki açılımda engel öne çıkarken, son açılımda yön daha belirgin.',
    'In the earlier reading, obstacles stood out; in the latest, direction is clearer.',
    'В прошлом раскладе выделялись преграды; в последнем — направление.',
  ),
};
