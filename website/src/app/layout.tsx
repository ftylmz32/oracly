import type { Metadata, Viewport } from 'next';
import './globals.css';
import SiteHeader from '@/components/SiteHeader';
import SiteFooter from '@/components/SiteFooter';

const site = process.env.NEXT_PUBLIC_SITE_URL?.trim();
export const metadata: Metadata = {
  ...(site ? { metadataBase: new URL(site) } : {}),
  title: { default: 'ORACLY — Mystical Guidance', template: '%s | ORACLY' },
  description: 'ORACLY: Kahve falı, tarot, astroloji ve mistik deneyimler için yeni bir dijital alan.',
  robots: site ? { index: true, follow: true } : { index: false, follow: false },
  openGraph: { title: 'ORACLY — Mystical Guidance', description: 'Bir fincandan başlayan hikâye.', type: 'website', locale: 'tr_TR' },
};
export const viewport: Viewport = { themeColor: '#02030A', width: 'device-width', initialScale: 1 };
export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  return <html lang="tr"><body><div className="site-shell"><SiteHeader /><main id="main-content">{children}</main><SiteFooter /></div></body></html>;
}
