/// Dream scaffolding joins, provider context heading + feeling words -
/// TR / EN / RU. Catalog.
library;

import '../l10n_triple.dart';

const kL10nDreamReadJoin = <String, L10nTriple>{
  'dream.read.join.image_place': L10nTriple(
    '{image}, {place} içinde',
    '{image} in {place}',
    '{image}: {place}',
  ),
  'dream.read.join.image_person': L10nTriple(
    '{image} ve {person}',
    '{image} and {person}',
    '{image} и {person}',
  ),
  'dream.read.join.person_place': L10nTriple(
    '{person}, {place} içinde',
    '{person} in {place}',
    '{person}: {place}',
  ),
  'dream.read.join.scene_fallback': L10nTriple(
    'bu sahne',
    'this scene',
    'эта сцена',
  ),
  'dream.read.join.context_heading': L10nTriple(
    '[Bağlam]',
    '[Context]',
    '[Контекст]',
  ),
  'dream.read.feeling_word.peaceful': L10nTriple('Huzurlu', 'peaceful', 'спокойный'),
  'dream.read.feeling_word.anxious': L10nTriple('Kaygılı', 'nervous', 'тревожный'),
  'dream.read.feeling_word.curious': L10nTriple('Meraklı', 'curious', 'любопытный'),
  'dream.read.feeling_word.fearful': L10nTriple('Korkulu', 'fearful', 'испуганный'),
  'dream.read.feeling_word.joyful': L10nTriple('Neşeli', 'joyful', 'радостный'),
  'dream.read.feeling_word.melancholic': L10nTriple('Hüzünlü', 'wistful', 'печальный'),
  'dream.read.feeling_word.surreal': L10nTriple('Garip', 'strange', 'странный'),
  'dream.read.feeling_word.vivid': L10nTriple('Canlı', 'vivid', 'яркий'),
};
