import Image from 'next/image';
import Link from 'next/link';

const experiences = [
  { image: '/images/home_coffee.webp', eyebrow: 'WEB ÖNİZLEME', title: 'Kahve Falı', desc: 'Fincanındaki izlerden ilham alan, üç fotoğrafla başlayan ritüel.', href: '/kahve-fali' },
  { image: '/images/home_or_guide.webp', eyebrow: 'OR REHBERİN', title: 'Sana eşlik eden bir ses', desc: 'Sorularına alan açan, sakin ve kişisel bir keşif deneyimi.' },
  { image: '/images/home_hero_moon.webp', eyebrow: 'WEBDE YAKINDA', title: 'Gökyüzü ve semboller', desc: 'Astroloji, tarot ve daha fazlasıyla kendi evrenine yaklaş.' },
];

export default function Home() {
  return (
    <>
      <section className="cinematic-hero">
        <div className="hero-noise" aria-hidden="true" />
        <div className="container cinematic-hero-grid">
          <div className="cinematic-copy">
            <div className="eyebrow"><span className="tiny-star" aria-hidden="true">✦</span> ORACLY · MYSTICAL GUIDANCE</div>
            <h1>Sezgilerinle<br /><em>buluştuğun yer.</em></h1>
            <p>Kahve fincanındaki izlerden gökyüzündeki sembollere uzanan kişisel bir keşif alanı.</p>
            <div className="hero-actions">
              <Link className="button button-gold" href="/kahve-fali">Kahve Falını Keşfet <span aria-hidden="true">→</span></Link>
              <Link className="text-link" href="/deneyimler">Tüm deneyimler <span aria-hidden="true">↗</span></Link>
            </div>
            <div className="trust-line"><span className="status-dot" /> Ücretsiz web önizlemesi · Ödeme alınmıyor</div>
          </div>
          <div className="moon-stage" aria-label="Altın hilal üzerinde ORACLY rehber figürü">
            <div className="moon-halo" aria-hidden="true" />
            <Image src="/images/home_hero_moon.webp" alt="Altın hilal ve ORACLY rehber figürü" fill priority sizes="(max-width: 760px) 100vw, 52vw" />
            <div className="moon-caption"><span>ORACLY</span><small>YOUR STORY, YOUR SYMBOLS</small></div>
          </div>
        </div>
        <div className="hero-edge" aria-hidden="true">✦ &nbsp; FOLLOW YOUR CURIOSITY &nbsp; ✦</div>
      </section>

      <section className="section ritual-section">
        <div className="container split-heading">
          <div><div className="eyebrow">01 / İLK RİTÜEL</div><h2 className="section-heading">Bir fincan.<br /><em>Üç küçük adım.</em></h2></div>
          <p>Kahveni tamamla, fincanını kapat ve izlerin sakinleşmesine izin ver. Web önizlemesinde iki fincan açısı ve bir tabak fotoğrafıyla deneyimi keşfet.</p>
        </div>
        <div className="container ritual-showcase">
          <div className="ritual-image">
            <Image src="/images/home_coffee.webp" alt="Mor ve altın atmosferde kahve falı fincanı" fill sizes="(max-width: 760px) 100vw, 48vw" />
            <div className="image-badge"><strong>01</strong><span>FİNCANIN HAZIR</span></div>
          </div>
          <div className="ritual-steps">
            <article><span>01</span><div><h3>Fincanını hazırla</h3><p>Kahveni iç, fincanını kapat ve açılmasını bekle.</p></div></article>
            <article><span>02</span><div><h3>Üç fotoğraf seç</h3><p>İki farklı fincan açısı ve tabağın tamamını gösteren bir kare.</p></div></article>
            <article><span>03</span><div><h3>Hikâyene yaklaş</h3><p>Seçimlerini tarayıcında güvenle gözden geçir.</p></div></article>
            <Link className="button button-outline" href="/kahve-fali">Ritüeli Başlat <span aria-hidden="true">→</span></Link>
          </div>
        </div>
      </section>

      <section className="section universe-section">
        <div className="container section-row"><div><div className="eyebrow">02 / ORACLY EVRENİ</div><h2 className="section-heading">Her merakın<br /><em>bir kapısı var.</em></h2></div><Link className="text-link" href="/deneyimler">Tümünü gör <span aria-hidden="true">↗</span></Link></div>
        <div className="container cinematic-card-grid">
          {experiences.map((experience, index) => (
            <article className={`cinematic-card card-${index + 1}`} key={experience.title}>
              <Image src={experience.image} alt="" fill sizes="(max-width: 760px) 100vw, 33vw" />
              <div className="card-shade" />
              <div className="cinematic-card-content"><span>{experience.eyebrow}</span><h3>{experience.title}</h3><p>{experience.desc}</p>{experience.href ? <Link href={experience.href}>Deneyimi aç <b aria-hidden="true">↗</b></Link> : <small>Yakında</small>}</div>
            </article>
          ))}
        </div>
      </section>

      <section className="section guide-section">
        <div className="container guide-panel">
          <div className="guide-visual"><Image src="/images/home_or_guide.webp" alt="ORACLY rehberinin yıldız küresi" fill sizes="(max-width: 760px) 100vw, 45vw" /></div>
          <div className="guide-copy"><div className="eyebrow">03 / OR İLE TANIŞ</div><h2>Yalnızca cevap değil,<br /><em>yeni bir bakış.</em></h2><p>ORACLY; merakına eşlik eden sakin, dürüst ve sembollerle düşünen bir rehber deneyimi için tasarlandı.</p><Link href="/deneyimler" className="text-link">ORACLY dünyasını keşfet <span aria-hidden="true">→</span></Link></div>
        </div>
      </section>
    </>
  );
}
