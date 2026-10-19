# iyzico Checkout Form sandbox hazırlığı

Aşama 2G, mevcut `webCoffeeOrders` sipariş kaydını kullanır. Yeni bir sipariş sistemi
oluşturmaz.

Hazırlanan route'lar:

- `POST /api/orders/:orderId/checkout`: Firebase Auth ve App Check sonrasında, yalnız
  sipariş kaydındaki ürün/fiyat/para birimiyle Checkout Form başlatır.
- `POST /api/payments/iyzico/callback`: callback tokenini tek başına ödeme kanıtı saymaz;
  sipariş-token bağını ve CF Retrieve sonucunu doğrular.
- `POST /api/payments/iyzico/webhook`: ham HPP bildiriminin yalnız
  `X-IYZ-SIGNATURE-V3` imzasını kabul eder ve CF Retrieve ile uzlaştırır.

Initialize ve Retrieve çağrıları IYZWSv2 ile imzalanır. Başarılı provider cevaplarında
iyzico response signature doğrulanır. Alıcı ve fatura alanları yalnız initialize isteği
sırasında allowlist edilir; Firestore'a alıcı kimlik/adres veya kart verisi yazılmaz.

Checkout attempt, token ve hosted page URL mevcut siparişe transaction ile bağlanır.
Belirsiz ağ hatasında otomatik ikinci oturum açılmaz. Kesin initialize reddi token
oluşmadığı doğrulanarak yeni denemeye izin verir. Geç callback veya webhook, kullanıcı
sayfayı kapatsa bile aynı token üzerinden siparişi toparlayabilir.

Varsayılanlar kapalıdır:

```text
ORACLY_IYZICO_CHECKOUT_ENABLED=false
ORACLY_IYZICO_PRODUCTION_ENABLED=false
IYZICO_ENVIRONMENT=sandbox
```

Gerçek sandbox hesabı ve anahtarları bu çalışmada mevcut değildir. Bu nedenle gerçek
iyzico sandbox isteği yapılmamıştır; yalnız sahte HTTP cevapları ve yerel Firestore
Emulator kullanılmıştır.
