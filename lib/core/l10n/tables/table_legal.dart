/// Legal documents + Premium store policy disclosures — TR / EN / RU.
library;

import '../l10n_triple.dart';

const kL10nLegal = <String, L10nTriple>{
  'legal.section': L10nTriple(
    'Yasal',
    'Legal',
    'Правовое',
  ),
  'legal.opens_externally': L10nTriple(
    'Tarayıcıda açılır',
    'Opens in your browser',
    'Открывается в браузере',
  ),
  'legal.privacy_policy': L10nTriple(
    'Gizlilik Politikası',
    'Privacy Policy',
    'Политика конфиденциальности',
  ),
  'legal.terms_of_use': L10nTriple(
    'Kullanım Koşulları',
    'Terms of Use',
    'Условия использования',
  ),
  'legal.manage_subscription': L10nTriple(
    'Aboneliği yönet',
    'Manage subscription',
    'Управление подпиской',
  ),
  'legal.missing_url': L10nTriple(
    'Bu belge için genel bir bağlantı henüz yapılandırılmadı.',
    'A public link for this document is not configured yet.',
    'Публичная ссылка на этот документ ещё не настроена.',
  ),
  'legal.launch_failed': L10nTriple(
    'Bağlantı açılamadı. Biraz sonra yeniden dene.',
    'The link could not open. Please try again shortly.',
    'Не удалось открыть ссылку. Попробуй чуть позже.',
  ),
  'legal.manage_unavailable': L10nTriple(
    'Abonelik yönetimi bu platformda açılamıyor.',
    'Subscription management is not available on this platform.',
    'Управление подпиской недоступно на этой платформе.',
  ),
  'legal.store_billing_note': L10nTriple(
    'Ödeme App Store veya Google Play hesabın üzerinden alınır.',
    'Payment is charged through your App Store or Google Play account.',
    'Оплата списывается через аккаунт App Store или Google Play.',
  ),
  'legal.cancel_note': L10nTriple(
    'Otomatik yenilemeyi mağaza hesabından istediğin zaman kapatabilirsin.',
    'You can turn off auto-renewal anytime in your store account.',
    'Автопродление можно отключить в аккаунте магазина в любой момент.',
  ),
  'legal.restore_note': L10nTriple(
    'Daha önce satın aldıysan Satın Almaları Geri Yükle ile erişimi yenileyebilirsin.',
    'If you bought before, Restore purchases can renew access.',
    'Если покупка уже была, Восстановить покупки обновит доступ.',
  ),
  'legal.disclosure.monthly': L10nTriple(
    'Aylık otomatik yenilenen abonelik.',
    'Monthly auto-renewing subscription.',
    'Ежемесячная автопродлеваемая подписка.',
  ),
  'legal.disclosure.yearly': L10nTriple(
    'Yıllık otomatik yenilenen abonelik.',
    'Yearly auto-renewing subscription.',
    'Годовая автопродлеваемая подписка.',
  ),
  'legal.disclosure.lifetime': L10nTriple(
    'Tek seferlik ödeme — abonelik değildir, yenilenmez.',
    'One-time purchase — not a subscription, does not renew.',
    'Разовая покупка — не подписка, не продлевается.',
  ),
};