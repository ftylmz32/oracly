'use client';

import Image from 'next/image';
import { useEffect, useRef, useState } from 'react';

type Slot = 'cup-primary' | 'cup-secondary' | 'saucer';
type Selected = { name: string; url: string };
type Selection = Partial<Record<Slot, Selected>>;
const MAX_BYTES = 10 * 1024 * 1024;
const ALLOWED_TYPES = ['image/jpeg', 'image/png', 'image/webp'];
const slots: { id: Slot; number: string; title: string; detail: string }[] = [
  { id: 'cup-primary', number: '01', title: 'Fincan — ilk açı', detail: 'Fincanın içini net göreceğimiz bir fotoğraf.' },
  { id: 'cup-secondary', number: '02', title: 'Fincan — ikinci açı', detail: 'Fincanı çevirip başka açıdan fotoğraflandır.' },
  { id: 'saucer', number: '03', title: 'Tabak', detail: 'Fincanın tabağının tamamını gösteren fotoğraf.' },
];

export default function CoffeeCapture() {
  const [selected, setSelected] = useState<Selection>({});
  const ref = useRef<Selection>({});
  const [error, setError] = useState('');
  const [reviewed, setReviewed] = useState(false);
  useEffect(() => () => { Object.values(ref.current).forEach(p => p && URL.revokeObjectURL(p.url)); }, []);

  const count = slots.filter(s => Boolean(selected[s.id])).length;
  function pick(slot: Slot, file: File) {
    setReviewed(false);
    if (!ALLOWED_TYPES.includes(file.type)) {
      setError('Yalnızca JPG, PNG veya WebP fotoğrafı seçebilirsin.');
      return;
    }
    if (file.size === 0 || file.size > MAX_BYTES) {
      setError('Fotoğraf boyutu 0 MB’dan büyük, 10 MB’dan küçük olmalı.');
      return;
    }
    const old = ref.current[slot];
    if (old) URL.revokeObjectURL(old.url);
    const next = { ...ref.current, [slot]: { name: file.name, url: URL.createObjectURL(file) } };
    ref.current = next;
    setSelected(next);
    setError('');
  }
  function remove(slot: Slot) {
    const old = ref.current[slot];
    if (old) URL.revokeObjectURL(old.url);
    const next = { ...ref.current };
    delete next[slot];
    ref.current = next;
    setSelected(next);
    setReviewed(false);
    setError('');
  }
  return (
    <div className="capture-panel">
      <div className="capture-top">
        <div><div className="eyebrow">FOTOĞRAF HAZIRLIĞI</div><h2>Üç kare, tek fincan.</h2><p>2 fincan + 1 tabak. Her kare farklı olmalı.</p></div>
        <div className="capture-counter" aria-live="polite"><strong>{count}<span>/3</span></strong><small>fotoğraf</small></div>
      </div>
      <div className="progress-track" role="progressbar" aria-valuenow={count} aria-valuemin={0} aria-valuemax={3} aria-label="Seçilen fotoğraf sayısı"><span style={{ width: `${(count / 3) * 100}%` }} /></div>
      <div className="capture-grid">
        {slots.map(slot => {
          const photo = selected[slot.id];
          const inputId = `upload-${slot.id}`;
          return <div key={slot.id} className={`capture-slot ${photo ? 'has-photo' : ''}`}>
            <span className="capture-slot-number">{slot.number}</span>
            <div className="capture-slot-preview">
              {photo ? <Image src={photo.url} alt={`${slot.title} için seçilen fotoğraf`} fill sizes="(max-width: 700px) 80vw, 250px" unoptimized /> : <span className="slot-placeholder" aria-hidden="true">{slot.id === 'saucer' ? '◉' : '☕'}</span>}
            </div>
            <h3>{slot.title}</h3><p>{slot.detail}</p>
            <input id={inputId} className="sr-only-file" type="file" accept="image/jpeg,image/png,image/webp" aria-label={`${slot.title} fotoğrafı seç`} onChange={e => { const file = e.currentTarget.files?.[0]; if (file) pick(slot.id, file); e.currentTarget.value = ''; }} />
            <div className="capture-actions"><label htmlFor={inputId} className="capture-upload">{photo ? 'Değiştir' : 'Fotoğraf seç'} <span aria-hidden="true">+</span></label>{photo && <button type="button" onClick={() => remove(slot.id)} className="remove-photo" aria-label={`${slot.title} fotoğrafını kaldır`}>Kaldır</button>}</div>
            {photo && <small className="file-name" title={photo.name}>{photo.name}</small>}
          </div>;
        })}
      </div>
      {error && <p role="alert" className="form-error">{error}</p>}
      <div className="capture-summary">
        <div><strong>{count === 3 ? 'Fotoğrafların seçildi' : 'Fotoğraflarını hazırlıyoruz'}</strong><p>{count === 3 ? 'Bu aşama yalnızca yerel önizlemedir.' : 'Devam etmek için üç farklı fotoğraf seç.'}</p></div>
        <button type="button" className="button button-gold" disabled={count !== 3} onClick={() => setReviewed(true)}>Seçimi Kontrol Et <span aria-hidden="true">→</span></button>
      </div>
      {reviewed && <div className="preview-notice" role="status"><strong>3 fotoğraf hazır.</strong> Webde fal üretimi ve ödeme henüz etkin değil. Hiçbir fotoğraf yüklenmedi, ödeme alınmadı.</div>}
      <p className="capture-disclaimer">Güvenlik notu: Fotoğraflar yalnızca bu sayfa açıkken tarayıcında önizlenir. Gerçek fal ve ödeme sistemi bu sürümde bağlı değildir.</p>
    </div>
  );
}
