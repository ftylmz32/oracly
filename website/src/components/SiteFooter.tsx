import Link from 'next/link';

export default function SiteFooter() {
  return (
    <footer className="site-footer">
      <div className="container footer-inner">
        <div><Link href="/" className="brand footer-brand"><span className="brand-sigil" aria-hidden="true">✦</span>ORACLY</Link><p>Mystical Guidance</p><small>Yorumlar eğlence ve kişisel keşif amaçlıdır.</small></div>
        <nav aria-label="Alt menü" className="footer-links">
          <Link href="/kahve-fali">Kahve Falı</Link>
          <Link href="/deneyimler">Deneyimler</Link>
          <Link href="/gizlilik">Gizlilik</Link>
          <Link href="/kullanim-kosullari">Kullanım Koşulları</Link>
          <Link href="/iletisim">İletişim</Link>
        </nav>
      </div>
      <div className="container footer-bottom">© {new Date().getFullYear()} ORACLY · Mystical Guidance</div>
    </footer>
  );
}
