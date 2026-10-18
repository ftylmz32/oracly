import Link from 'next/link';

const experiences = [
  { mark: '☕', title: 'Kahve Falı', desc: 'Fincandaki izlerden ilham alan dijital bir yorum deneyimi.', active: true },
  { mark: '✧', title: 'Tarot', desc: 'Kartların sembolleriyle farklı bir bakış açısı.', active: false },
  { mark: '☾', title: 'Astroloji', desc: 'Gökyüzünün diliyle kendine yeni sorular sor.', active: false },
  { mark: '✦', title: 'El Falı', desc: 'Avuç içindeki çizgileri keşfet.', active: false },
];
export default function Home() {
  return (
    <>
      <section className="hero">
        <div className="hero-glow" aria-hidden="true" />
        <div className="container hero-grid">
          <div className="hero-copy">
            <div className="eyebrow"><span className="tiny-star" aria-hidden="true">✦</span> MYSTICAL GUIDANCE <span className="hairline" /></div>
            <h1>Bir fincandan <em>başlayan</em> hikâye.</h1>
            <p>Kahven bittiğinde hikâyen başlayabilir. ORACLY ile fincanındaki izlere yepyeni bir gözle bak.</p>
            <div className="hero-actions">
              <Link className="button button-gold" href="/kahve-fali">Kahve Falını Keşfet <span aria-hidden="true">↗</span></Link>
              <Link className="text-link" href="/deneyimler">Tüm deneyimler <span aria-hidden="true">→</span></Link>
            </div>
            <div className="hero-footnote"><span className="status-dot" /> Web deneyimi hazırlanıyor. Şu an ödeme alınmıyor.</div>
          </div>
          <div className="hero-art" aria-hidden="true">
            <div className="orbit orbit-one" /><div className="orbit orbit-two" /><div className="orbit orbit-three" />
            <div className="sky-symbol symbol-one">✧</div><div className="sky-symbol symbol-two">⋆</div><div className="sky-symbol symbol-three">✦</div>
            <div className="coffee-art"><div className="coffee-rim"><div className="coffee-surface"><span className="coffee-swirl swirl-one" /><span className="coffee-swirl swirl-two" /><span className="coffee-swirl swirl-three" /></div></div><div className="coffee-handle" /><div className="coffee-shadow" /></div>
            <div className="hero-art-label"><span>ORACLY</span><small>YOUR STORY, YOUR SYMBOLS</small></div>
          </div>
        </div>
        <div className="hero-edge" aria-hidden="true">✦ &nbsp; FOLLOW YOUR CURIOSITY &nbsp; ✦</div>
      </section>

      <section className="section section-intro">
        <div className="container intro-grid">
          <div><div className="eyebrow">01 / DENEYİM</div><h2 className="section-heading">Merak, <em>bir fincan</em> kadar yakın.</h2></div>
          <p>Kahve falı ORACLY&apos;nin merkezinde. İki farklı açıdan fincanını ve tabağını fotoğraflayarak başlayacaksın. Şimdilik bu adımları ücretsiz bir önizleme olarak keşfedebilirsin.</p>
        </div>
        <div className="container steps-grid">
          <div className="step-card"><span className="step-number">01</span><div className="step-art">◖</div><h3>Fincanını hazırla</h3><p>Kahveni iç, fincanını kapat ve açılmasını bekle.</p></div>
          <div className="step-card"><span className="step-number">02</span><div className="step-art">◎</div><h3>Üç fotoğraf seç</h3><p>İki fincan fotoğrafı ve bir tabak fotoğrafı.</p></div>
          <div className="step-card"><span className="step-number">03</span><div className="step-art">✧</div><h3>Yoruma hazırlan</h3><p>Fal üretimi webde açıldığında sonucun burada olacak.</p></div>
        </div>
      </section>

      <section className="section experience-section">
        <div className="container section-row"><div><div className="eyebrow">02 / ORACLY EVRENİ</div><h2 className="section-heading">Sana özel <em>bir dünya.</em></h2></div><Link className="text-link" href="/deneyimler">Tümünü gör <span aria-hidden="true">↗</span></Link></div>
        <div className="container experience-grid">
          {experiences.map(e => <article className="experience-card" key={e.title}><div className="experience-mark" aria-hidden="true">{e.mark}</div><span className="availability">{e.active ? 'WEB ÖNİZLEME' : 'WEBDE YAKINDA'}</span><h3>{e.title}</h3><p>{e.desc}</p>{e.active ? <Link href="/kahve-fali" className="card-link">İncele <span aria-hidden="true">↗</span></Link> : <span className="card-link muted">Hazırlanıyor</span>}</article>)}
        </div>
      </section>

      <section className="section cta-section">
        <div className="container"><div className="cta-panel"><div className="eyebrow">ORACLY · MYSTICAL GUIDANCE</div><h2>Fincanın <em>anlatacakları</em> var.</h2><p>Üç fotoğrafla başlayan web deneyiminin ilk adımını gör.</p><Link href="/kahve-fali" className="button button-gold">Kahve Falı Ekranını Aç <span aria-hidden="true">→</span></Link></div></div>
      </section>
    </>
  );
}
