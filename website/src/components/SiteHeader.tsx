import Image from 'next/image';
import Link from 'next/link';

export default function SiteHeader() {
  return (
    <>
      <a className="skip-link" href="#main-content">İçeriğe geç</a>
      <header className="site-header">
        <div className="container nav-inner">
          <Link href="/" className="brand brand-image" aria-label="ORACLY ana sayfa"><Image src="/images/oracly_logo.png" alt="" width={42} height={42} priority /><span>ORACLY</span></Link>
          <nav className="nav-links" aria-label="Ana menü"><Link href="/kahve-fali">Kahve Falı</Link><Link href="/deneyimler">Deneyimler</Link><Link href="/iletisim">İletişim</Link></nav>
          <Link href="/kahve-fali" className="nav-cta">Keşfet <span aria-hidden="true">↗</span></Link>
        </div>
      </header>
    </>
  );
}
