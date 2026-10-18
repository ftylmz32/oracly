import type { Metadata } from 'next';
import Image from 'next/image';
import CoffeeCapture from '@/components/CoffeeCapture';

export const metadata: Metadata = { title: 'Kahve Falı', description: 'ORACLY Kahve Falı için iki fincan ve bir tabak fotoğrafı adımlarını keşfet.' };
export default function CoffeePage() {
  return <>
    <section className="coffee-page-hero"><div className="container coffee-page-grid"><div className="coffee-page-copy"><div className="eyebrow">ORACLY / KAHVE FALI</div><h1 className="page-title">Fincanından<br /><em>bir hikâye</em> doğsun.</h1><p className="page-lead">İki fincan açısı ve bir tabak fotoğrafıyla ritüelini hazırla. Bu önizlemede fotoğrafların yalnızca tarayıcında kalır.</p><div className="privacy-pill"><span aria-hidden="true">✦</span> Yerel önizleme · Yükleme ve ödeme yok</div></div><div className="coffee-page-art"><Image src="/images/home_coffee.webp" alt="Kahve falı için hazırlanmış fincan" fill priority sizes="(max-width: 760px) 100vw, 45vw" /></div></div></section>
    <section className="section capture-section"><div className="container page-container"><CoffeeCapture /></div></section>
  </>;
}
