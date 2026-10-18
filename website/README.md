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

Üretime dağıtım / canlı ödeme / mevcut mobil backend değişikliği: **yok**.
