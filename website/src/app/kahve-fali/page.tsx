import type { Metadata } from 'next';
import CoffeeCapture from '@/components/CoffeeCapture';

export const metadata: Metadata = { title: 'Kahve Falı', description: 'ORACLY Kahve Falı için iki fincan ve bir tabak fotoğrafı adımlarını keşfet.' };
export default function CoffeePage() {
  return <section className="section page-section"><div className="container page-container">
    <div className="eyebrow">ORACLY / KAHVE FALI</div>
    <h1 className="page-title">Fincanından <em>bir hikâye</em> doğsun.</h1>
    <p className="page-lead">Web deneyimimizin fotoğraf hazırlama adımını keşfet. Üç görsel seçebilirsin; bu önizlemede fotoğrafların hiçbir yere yüklenmez.</p>
    <CoffeeCapture />
  </div></section>;
}
