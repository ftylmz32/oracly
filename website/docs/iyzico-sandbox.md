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

## Firebase ve iyzico sandbox etkinleştirme kontrol listesi

- Firebase Console Authentication bölümünde Email/Password sağlayıcısını etkinleştir;
  yetkili web domainlerini gerçek HTTPS alan adıyla sınırla.
- Firebase Web App kimliği, `NEXT_PUBLIC_FIREBASE_*` değerleri ve
  `FIREBASE_APP_CHECK_WEB_APP_ID` aynı Firebase projesine ait olmalı.
- App Check için reCAPTCHA Enterprise anahtarını doğru HTTPS alan adına bağla ve
  token enforcement açılmadan önce test metriklerini gözden geçir.
- Firestore Security Rules dosyasının istemci erişimine `allow read, write: if false`
  uyguladığını koru. Sipariş sorguları yalnız Firebase Admin ile sunucu route'larından
  ve doğrulanmış UID filtresiyle yapılmalı.
- iyzico merchant portalında sandbox API key ve secret oluştur; bunları yalnız sunucu
  secret manager'ına `IYZICO_API_KEY` ve `IYZICO_SECRET_KEY` olarak gir. Kaynak koda,
  tarayıcı değişkenlerine veya `NEXT_PUBLIC_*` alanlarına koyma.
- `IYZICO_CALLBACK_URL` herkese açık, sabit bir HTTPS callback olmalı. Webhook için
  `/api/payments/iyzico/webhook` HTTPS URL'sini kaydet ve Signature V3'ü etkinleştir.
- Sandbox callback/webhook alan adının TLS sertifikasını, ters proxy ham gövde
  aktarımını ve `X-IYZ-SIGNATURE-V3` başlığının korunmasını doğrula.
- Önce sandbox CF Initialize/Retrieve, gecikmiş callback, yinelenen webhook, başarısız
  ödeme ve iade/mutabakat senaryolarını tamamla. Ancak bundan sonra sandbox doğrulama
  bayraklarını kontrollü olarak değerlendir; production bayrakları ayrı ve kapalı kalsın.
