# ORACLY Web tekil kahve falı — backend uygulama planı

Bu belge Aşama 2C'de yapılan salt okunur backend incelemesinin sonucudur. Bu aşamada `backend/` değiştirilmemiştir ve gerçek ödeme etkin değildir.

## Mevcut kritik açık

`POST /v1/reading-operations` Firebase Authentication ve App Check doğruluyor; ayrıca aktif işlem ve hız kotası uyguluyor. Ancak `readingType: coffee` için doğrulanmış bir sipariş veya tek kullanımlık fal hakkı aramıyor ve tüketmiyor. Bu nedenle geçerli Firebase/App Check token'ı olan bir web istemcisi arayüzdeki kapalı butonu atlayıp doğrudan operation oluşturabilir. İstemci bayrağı, gizli URL, CORS veya kapalı buton çözüm değildir.

## Zorunlu sunucu tasarımı

Firestore'da kalıcı ve transaction tabanlı bir `webCoffeeOrders` deposu eklenmeli. Kayıt, en az `orderId`, `ownerUserId`, sunucu katalog sürümü, `priceMinor`, `currency`, durum, iyzico token/payment ID özetleri, fal hakkı, bağlı `operationId`, zamanlar ve append-only denetim olaylarını içermeli. Ham kart verisi veya istemciden gelen fiyat saklanmamalı.

Önerilen durumlar: `created → payment_pending → payment_verified → entitlement_granted → entitlement_consumed`; ayrıca `failed` ve `refunded`. `payment_verified` ile hakkın verilmesi tek transaction içinde tamamlanmalı veya güvenli bir outbox/iş kuyruğu ile yeniden yürütülebilir olmalı.

Gerekli endpoint'ler:

- Auth + App Check korumalı `POST /v1/web/coffee-orders`: ürün kimliğini kabul eder, fiyatı sunucu kataloğundan seçer ve kullanıcı UID'sine bağlar.
- Auth + App Check korumalı checkout başlatma: iyzico CF Initialize çağrısını yalnızca sunucudan yapar; API/secret key hiçbir zaman web bundle'ına girmez.
- Genel HTTPS callback/webhook: ham gövde üzerinden `X-IYZ-SIGNATURE-V3` doğrular. Bildirime dayanarak doğrudan hak vermez; CF Retrieve ile token'ı iyzico'dan sunucudan sorgular.
- Auth + App Check korumalı sipariş durumu: yalnızca sipariş sahibi için allowlist DTO döndürür.

Sipariş doğrulamasında conversation/order ID, basket ID, ürün, para birimi, sunucu fiyatı, `paymentStatus`, fraud/transaction durumu ve benzersiz provider payment ID birlikte doğrulanmalı. Provider payment ID için global unique/transactional claim bulunmalı; yinelenen webhook idempotent olmalı.

## Reading-operation admission düzeltmesi

Web için hak tüketimi ile operation oluşturma ayrı çağrılar olmamalı. Aksi halde iki eşzamanlı istek aynı hakkı görebilir. `ReadingOperationRepository.create` transaction'ına tek kullanımlık web hakkı eklenmeli ve aynı transaction içinde:

1. hakkın sahibi Firebase UID ile eşleşmeli,
2. durum `entitlement_granted` olmalı,
3. hak `entitlement_consumed` durumuna geçirilmeli ve yeni `operationId` bağlanmalı,
4. reading operation yaratılmalı.

Mobil kullanıcıları korumak için mevcut mobil sözleşme sessizce değiştirilmemeli. Sunucu tarafından güvenilir bir admission kanalı kullanılmalı:

- yeni web endpoint'i (`POST /v1/web/coffee-orders/:orderId/reading-operation`) yalnızca sipariş hakkıyla atomik oluşturma yapabilir; veya
- `/v1/reading-operations` şemasına sunucu tarafından doğrulanan açık bir `orderId` eklenebilir ve yalnızca Web App Check App ID'leri için zorunlu kılınabilir.

App Check App ID tek başına kullanıcı/ödeme yetkisi değildir; yalnızca hangi istemci politikasının uygulanacağını seçmeye yardımcı olur. Mevcut iOS/Android App ID'leri eski admission politikasında tutulmalı, web App ID allowlist'i ayrı olmalı ve kademeli feature flag/telemetri ile devreye alınmalıdır. Uzun vadede mobil ücretsiz/premium politikasının da açık sunucu entitlement kurallarına taşınması önerilir.

## İyzico resmi sözleşmesi

- [CF Initialize](https://docs.iyzico.com/en/payment-methods/checkoutform/cf-implementation/cf-initialize): sunucu `price`, `paidPrice`, `currency`, `callbackUrl`, alıcı/adres ve sanal basket item gönderir; cevap token ve hosted `paymentPageUrl` sağlar.
- [CF Retrieve](https://docs.iyzico.com/en/payment-methods/checkoutform/cf-implementation/cf-retrieve): callback'e POST edilen token ikinci bir sunucu çağrısıyla sorgulanır; fiyat, para birimi, payment ID, fraud durumu, item transaction ve `paymentStatus` doğrulanır.
- [Webhook](https://docs.iyzico.com/en/advanced/webhook): hosted Checkout Form bildiriminde `X-IYZ-SIGNATURE-V3` kullanılmalı; eski V1/V2 imzaları kabul edilmemeli. Webhook gecikebilir veya tekrarlanabilir.

Hesap açılınca merchant portalda sandbox anahtarları secret manager'a girilmeli, HTTPS callback/webhook tanımlanmalı, Signature V3 iyzico ile etkinleştirilmeli, sandbox CF uçtan uca denenmeli ve ancak mutabakat/iade testlerinden sonra production anahtarları ayrı secret olarak eklenmelidir.

## Backend kabul testleri

- İstemci fiyatı, `paid=true` veya provider sonucu göndererek hak kazanamaz.
- İmzasız/yanlış imzalı, değiştirilmiş gövdeli ve replay webhook hak vermez.
- Callback başarılı görünse bile başarısız/pending/mismatched CF Retrieve hak vermez.
- Aynı webhook ve callback istenen sayıda yinelendiğinde tek hak oluşur.
- Aynı provider payment ID iki siparişe veya iki UID'ye bağlanamaz.
- İki eşzamanlı create isteğinden yalnızca biri hakkı tüketir ve tek operation oluşur.
- Başka UID siparişi okuyamaz veya kullanamaz; 404-benzeri cevap kimlik sızdırmaz.
- Failed/refunded sipariş hak vermez; kullanılmamış hak refund ile iptal edilir. Kullanılmış hakkın iadesi denetim ve finans politikasıyla açıkça ele alınır.
- Firestore kesintisi, iyzico zaman aşımı ve bilinmeyen durumlar fail-closed olur.
- Mevcut iOS/Android operation oluşturma, staging, sonuç ve toparlanma regresyon testleri değişmeden geçer.

## Bu worktree'deki sınır

`src/lib/orders` yalnızca çalıştırılabilir alan modeli, provider arayüzü ve sahte sağlayıcıdır. Kalıcı depo, gerçek Next route, iyzico SDK/anahtarları veya backend admission kontrolü değildir. Üretim kodu olarak etkinleştirilmemelidir.
