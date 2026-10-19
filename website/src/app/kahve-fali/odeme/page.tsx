import PaymentStatus from '@/components/PaymentStatus';

export default async function PaymentResultPage({ searchParams }: { searchParams: Promise<{ orderId?: string; state?: string }> }) {
  const query = await searchParams;
  return <main className="payment-result-page"><div className="container"><PaymentStatus orderId={query.orderId} callbackState={query.state} /></div></main>;
}
