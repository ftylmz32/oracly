/// Gems and daily rewards extras — TR / EN / RU.
library;

import '../l10n_triple.dart';

const kL10nEconomy = <String, L10nTriple>{
  'gems.economy': L10nTriple('Mücevher akışı', 'Gem flow', 'Поток кристаллов'),
  'gems.starter_chip': L10nTriple('Bir kez', 'Once', 'Один раз'),
  'gems.daily_chip': L10nTriple('Her gün', 'Each day', 'Каждый день'),
  'gems.cost_chip': L10nTriple('Maliyet', 'Cost', 'Стоимость'),
  'gems.tarot_label': L10nTriple(
    'Üç kart ve üzeri tarot',
    'Three-card tarot and above',
    'Таро из трёх карт и больше',
  ),
  'gems.day_suffix': L10nTriple('/gün', '/day', '/день'),
  'gems.daily_hint': L10nTriple(
    'İstersen bugünün sessiz hediyesi',
    'If you wish, today’s quiet gift',
    'Если хочешь — тихое подношение на сегодня',
  ),
  'gems.shop_honesty': L10nTriple(
    'Satın alma paketi yok. Bakiye bu cihazda tutulur. Premium mücevher vermez.',
    'There is no purchase pack. Balance is kept on this device. Premium does not grant gems.',
    'Пакетов покупки нет. Баланс хранится на этом устройстве. Премиум кристаллы не даёт.',
  ),
  'gems.unit': L10nTriple('Mücevher', 'Gem', 'Кристалл'),
  'gems.what_title': L10nTriple('Mücevher nedir?', 'What is a gem?', 'Что такое кристалл?'),
  'gems.what_body': L10nTriple(
    'Mücevher, ORACLY’de görünen kristal bakiyendir. Üst çubuktaki sayı ile aynı değerdir.',
    'A gem is the crystal balance shown in ORACLY. It is the same number as the top bar.',
    'Кристалл — видимый баланс в ORACLY. То же число, что в верхней полосе.',
  ),
  'gems.earn_title': L10nTriple('Nasıl kazanılır?', 'How to earn?', 'Как получить?'),
  'gems.earn_body': L10nTriple(
    'İlk açılım için bir kez 20 mücevher verilir. Her gün Günlük Ödüller’den de 50 mücevher alabilirsin. Satın alma paketi yoktur.',
    'Twenty gems are given once for the first spread. You can also claim 50 gems from Daily rewards each day. There is no purchase pack.',
    'Двадцать кристаллов даются один раз за первый расклад. Каждый день в Ежедневных наградах можно взять 50. Пакетов покупки нет.',
  ),
  'gems.spend_title': L10nTriple('Nerede kullanılır?', 'Where is it used?', 'Где используется?'),
  'gems.spend_body': L10nTriple(
    'Üç kart ve üzeri tarot yorumu 20 mücevher — karşılığında derin bir okuma. Tek kart ücretsizdir. Kahve, el ve rüya mücevher istemez.',
    'Three-card tarot and above cost 20 gems — you receive a deeper reading. A single card is free. Coffee, palm, and dream do not ask for gems.',
    'Расклад из трёх карт и больше стоит 20 кристаллов — ты получаешь более глубокое чтение. Одна карта бесплатна. Кофе, ладонь и сон кристаллов не просят.',
  ),
  'gems.history': L10nTriple('Son hareketler', 'Recent movement', 'Последние движения'),
  'gems.history_empty': L10nTriple(
    'Henüz bir mücevher hareketi yok.',
    'There is no gem movement yet.',
    'Пока нет движения кристаллов.',
  ),
  'gems.daily_link': L10nTriple('Günlük Ödüller', 'Daily rewards', 'Ежедневные награды'),
  'gems.open': L10nTriple('Mücevherler', 'Gems', 'Кристаллы'),
  'gems.cost_n': L10nTriple('{n} Mücevher', '{n} gems', '{n} кристаллов'),
  'gems.confirm_title': L10nTriple(
    'Harcamayı onayla',
    'Confirm spend',
    'Подтвердить списание',
  ),
  'gems.confirm_body': L10nTriple(
    'Bu adımın maliyeti {cost}. Onaylamadan düşülmez.',
    'This step costs {cost}. Nothing is taken before you confirm.',
    'Этот шаг стоит {cost}. Без подтверждения ничего не списывается.',
  ),
  'gems.confirm_body_with_balance': L10nTriple(
    'Elindeki: {balance}. Maliyet: {cost}. Onaylamadan düşülmez.',
    'Your balance: {balance}. Cost: {cost}. Nothing is taken before you confirm.',
    'Ваш баланс: {balance}. Стоимость: {cost}. Без подтверждения ничего не списывается.',
  ),
  'gems.confirm_body_purpose': L10nTriple(
    '{reason} için {cost}. Elindeki: {balance}. Onaylamadan düşülmez.',
    '{cost} for {reason}. Your balance: {balance}. Nothing is taken before you confirm.',
    '{cost} за {reason}. Ваш баланс: {balance}. Без подтверждения ничего не списывается.',
  ),
  'gems.claim_received': L10nTriple(
    'Aldın: {amount}',
    'Received: {amount}',
    'Получено: {amount}',
  ),

  'gems.insufficient_cost': L10nTriple(
    'Bu keşif için en az {cost} gerekiyor.',
    'This discovery needs at least {cost}.',
    'Для этого открытия нужно минимум {cost}.',
  ),
  'gems.reason.daily': L10nTriple('Günlük Ödül', 'Daily reward', 'Ежедневная награда'),
  'gems.reason.starter': L10nTriple('İlk açılım', 'First spread', 'Первый расклад'),
  'gems.reason.tarot': L10nTriple('Tarot', 'Tarot', 'Таро'),
  'gems.reason.dream': L10nTriple('Rüya', 'Dream', 'Сон'),
  'gems.reason.coffee': L10nTriple('Kahve', 'Coffee', 'Кофе'),
  'gems.reason.palm': L10nTriple('El', 'Palm', 'Ладонь'),
  'gems.reason.soulmate': L10nTriple('Ruh Eşi', 'Soulmate', 'Родственная душа'),
  'gems.reason.refund': L10nTriple(
    'Sağlayıcı hatası iadesi',
    'Provider failure refund',
    'Возврат при ошибке сервиса',
  ),
  'rewards.subtitle': L10nTriple(
    'İstersen bugün için sessiz bir hediye.',
    'If you wish, a quiet gift for today.',
    'Если хочешь — тихое подношение на сегодня.',
  ),
  'rewards.gift': L10nTriple('Bugünkü Hediyen', "Today's gift", 'Подарок на сегодня'),
  'rewards.unit': L10nTriple('Mücevher', 'Gem', 'Кристалл'),
  'rewards.today': L10nTriple('Bugünün ödülü', "Today's reward", 'Награда за сегодня'),
  'rewards.claim_short': L10nTriple('Hediye', 'Receive', 'Принять'),
  'rewards.streak': L10nTriple('Bu hafta', 'This week', 'На этой неделе'),
  'rewards.streak_hint': L10nTriple(
    'Aldığın günler hatırlanır — kayıp yok, baskı yok.',
    'Days you claimed are remembered — nothing lost, no pressure.',
    'Дни, когда ты брал, помнятся — ничего не теряется, без давления.',
  ),
  'rewards.amount': L10nTriple('+{n} mücevher', '+{n} gems', '+{n} кристаллов'),
};
