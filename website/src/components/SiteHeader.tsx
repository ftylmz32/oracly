import Link from 'next/link';

export default function SiteHeader() {
  return (
    <>
      <a className="skip-link" href="#main-content">İçeriğe geç</a>
      <header className="site-header">
        <div className="container nav-inner">
          <Link href="/" className="brand" aria-label="ORACLY ana sayfa"><span className="brand-sigil" aria-hidden="true">✦</span><span>ORACLY</span></Link>
          <nav className="nav-links" aria-label="Ana menü">
            <Link href="/kahve-fali">Kahve Falı</Link>
            <Link href="/deneyimler">Deneyimler</Link>
            <Link href="/iletisim">İletişim</Link>
          </nav>
          <Link href="/kahve-fali" className="nav-cta">Keşfet <span aria-hidden="true">↗</span></Link>
        </div>
      </header>
    </>
  );
}
