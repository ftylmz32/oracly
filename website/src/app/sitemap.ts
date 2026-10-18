import type { MetadataRoute } from 'next';
export default function sitemap(): MetadataRoute.Sitemap {
  const site = process.env.NEXT_PUBLIC_SITE_URL?.trim();
  if (!site) return [];
  return ['', '/kahve-fali', '/deneyimler', '/gizlilik', '/kullanim-kosullari', '/iletisim'].map((route) => ({
    url: `${site.replace(/\/$/, '')}${route}`,
    lastModified: new Date(),
    changeFrequency: route === '' ? 'weekly' as const : 'monthly' as const,
    priority: route === '' ? 1 : 0.6,
  }));
}
