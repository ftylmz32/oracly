import type { Metadata } from 'next';
import AccountDashboard from '@/components/AccountDashboard';

export const metadata: Metadata = { title: 'Hesabım', description: 'ORACLY hesabınızı ve satın aldığınız kahve falı haklarını yönetin.' };
export default function AccountPage() { return <section className="page-section"><div className="container account-page"><div className="eyebrow">ORACLY / HESABIM</div><h1 className="page-title">Hesabım ve <em>satın aldıklarım</em></h1><AccountDashboard /></div></section>; }
