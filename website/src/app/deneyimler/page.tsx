import type { Metadata } from 'next';
import Link from 'next/link';
export const metadata: Metadata = { title: 'Deneyimler', description: 'ORACLY dünyasındaki mistik deneyimleri keşfet.' };
const experiences = [
  ['☕','Kahve Falı','Fincanının izlerini keşfet.','Fotoğraf adımları açık','/kahve-fali'],
  ['✧','Tarot','Sembollerin yeni sorulara açtığı kapı.','Webde yakında',null],
  ['☾','Astroloji','Gökyüzünden ilham alan bir bakış.','Webde yakında',null],
  ['✦','El Falı','Avuç içindeki işaretlerin hikâyesi.','Webde yakında',null],
  ['✶','Yıldızname','Geleneksel sembollerden ilham alan bir deneyim.','Webde yakında',null],
  ['♡','Ruh Eşi','Hayal gücünün görselle buluştuğu alan.','Webde yakında',null],
];
export default function Experiences() {
  return <section className="section page-section"><div className="container"><div className="eyebrow">ORACLY EVRENİ</div><h1 className="page-title">Her sembolde <em>yeni bir kapı.</em></h1><p className="page-lead">Mobildeki deneyimlerimizi web için aşama aşama hazırlıyoruz. Şimdilik yalnızca kahve falının fotoğraf adımları önizlenebilir.</p>
  <div className="experience-grid experience-list">{experiences.map(([symbol,title,desc,status,href])=><article className="experience-card" key={title}><div className="experience-mark" aria-hidden="true">{symbol}</div><span className="availability">{status}</span><h2>{title}</h2><p>{desc}</p>{href ? <Link href={href} className="card-link">Önizlemeye geç <span aria-hidden="true">↗</span></Link> : <span className="card-link muted">Hazırlanıyor</span>}</article>)}</div></div></section>;
}
