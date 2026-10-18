# ORACLY Web — Faz 1

ORACLY'nin mobil uygulamadan ayrı, **şimdilik ödeme ve fal üretimi yapmayan** Next.js web arayüzü.

## Başlatma (Windows PowerShell)

```powershell
cd D:\oracly-web-20261018\website
npm install
npm run dev
```

Tarayıcı: http://localhost:3000

## Doğrulama

```powershell
npm run typecheck
npm run lint
npm run build
```

## Sınırlar

- Bu paket **mevcut Flutter `web/` dizini değildir**; hiçbir mobil dosyayı değiştirmez.
- Kahve falı ekranı 2 fincan + 1 tabak görseli seçtirir. Görseller sadece tarayıcı belleğinde önizlenir. **Sunucuya gönderilmez; kalıcı saklanmaz.**
- AI, Firebase kimlik doğrulama, Web App Check ve ödeme henüz bağlı değildir. Web alışverişi kesinlikle çalışıyor gibi gösterilmez.
- Gizlilik / koşullar / iletişim sayfaları taslaktır. İşletme bilgileri, KVKK ve ödeme süreçleri doğrulanmadan yayına çıkma.
- Alan adı belli olunca HTTPS adresini `NEXT_PUBLIC_SITE_URL` üzerinden belirt. O zamana kadar arama motorları için `noindex` etkin.
- `npm install` paket kilit dosyasını üretecektir; geliştirme tamamlandığında commit'e eklenmelidir.

## Faz 2 önkoşulları (bu aşamada uygulanmadı)

1. Firebase için ayrı Web App Check uygulaması ve doğrulama; asla production App Check'i bypass etme.
2. Mevcut `backend/src/routes/reading-operations.ts` ve `reading-staged-image-routes.ts` sözleşmelerini test ederek web uyarlaması. Coffee V3 için `three_view_v3` (2 cup + 1 saucer) sözleşmesine sadık kal.
3. Türkiye'de hizmetimizi kabul eden ödeme kuruluşunun **sunucudan doğrulanan**, idempotent callback/webhook yapısı. İstemciden gelen `paid:true` gibi bir bilgi hiçbir hak kazandırmamalı.
4. Sipariş / okuma / ücret iadesi / hata / tekrar deneme kayıtları, fiyat ve AI maliyet kontrolü.
5. İşletme kimliği, satış ve iletişim bilgileri, KVKK, tüketici metinleri ve gerekli yasal onaylar.
6. Tam ödeme → yetki → 3 fotoğraf → fal sonucu ve başarısızlık senaryolarının otomatik ve gerçek cihaz testleri.

## Coffee V3 web entegrasyon temeli

Web istemcisi mevcut backend sözleşmesini değiştirmeden şu sabitleri kullanır:

- `readingType: coffee`, `language: tr`
- `coffeeInputContract: trusted_intention_v1`
- `coffeeCaptureContract: three_view_v3`
- İlk fincan: `v3_cup_view_a`
- İkinci fincan: `v3_cup_view_b`
- Tabak: `v3_saucer_view`

Canlı mod varsayılan olarak kapalıdır. Firebase Web App yapılandırması, Anonymous
Authentication ve reCAPTCHA Enterprise tabanlı Web App Check tamamlanmadan istemci
hazır görünmez. Korunan backend çağrıları hem `Authorization: Bearer <Firebase ID
token>` hem de `X-Firebase-AppCheck` başlığını gönderir. Production API adresi HTTPS
olmalıdır.

Firebase Console hazırlığı:

1. Mevcut Firebase projesine ayrı bir Web App kaydet.
2. Authentication altında Anonymous sağlayıcısını yalnız ürün kararı ve kötüye kullanım kontrolleri onaylandıysa etkinleştir.
3. App Check altında Web App'i reCAPTCHA Enterprise ile kaydet; enforcement'ı önce metrikleri izleyerek kademeli aç.
4. Backend `FIREBASE_APP_CHECK_APP_IDS` allowlist'ine yeni Web App ID'sini ekle.
5. `.env.example` içindeki public Firebase değerlerini deployment ortamına gir; gizli servis hesabı anahtarlarını asla `NEXT_PUBLIC_*` değişkenlerine koyma.
6. Backend URL'sini HTTPS olarak ayarla ve `NEXT_PUBLIC_ORACLY_COFFEE_LIVE_ENABLED=true` değerini ancak uçtan uca doğrulama sonrası kullan.

Yerel sahte akış `NEXT_PUBLIC_ORACLY_COFFEE_SERVICE=mock` veya development'ta
`?mockMode=1` ile açılır. Kod `NODE_ENV=production` olduğunda sahte sağlayıcıyı
reddeder. Demo sonucu açıkça sahte olarak işaretlenir. Ödeme butonu ve canlı gönderim,
doğrulanmış ödeme/yetkilendirme ile web sonuç teslim endpoint'i tamamlanana kadar kapalıdır.

Üretime dağıtım / canlı ödeme / mevcut mobil backend değişikliği: **yok**.
