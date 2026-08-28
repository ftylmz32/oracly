const MONTHS = [
  'Ocak',
  'Şubat',
  'Mart',
  'Nisan',
  'Mayıs',
  'Haziran',
  'Temmuz',
  'Ağustos',
  'Eylül',
  'Ekim',
  'Kasım',
  'Aralık',
];

export function prepareSpokenNumbers(raw: string): string {
  let text = raw;
  text = text.replace(/(?<!yüzde )%(\d+(?:[.,]\d+)?)/g, 'yüzde $1');
  text = text.replace(/(?<!yüzde )(\d+(?:[.,]\d+)?)\s*%/g, 'yüzde $1');
  text = text.replace(
    /\b(\d{1,2})[./](\d{1,2})[./](\d{4})\b/g,
    (_, d: string, m: string, y: string) => {
      const day = Number(d);
      const month = Number(m);
      if (day < 1 || day > 31 || month < 1 || month > 12) return _;
      return `${day} ${MONTHS[month - 1]} ${y}`;
    },
  );
  text = text.replace(/\b(\d{1,2}):(\d{2})\b/g, 'saat $1.$2');
  text = text.replace(/\bvs\.\b/gi, 'vesaire');
  text = text.replace(/\bvb\.\b/gi, 've benzeri');
  text = text.replace(/\bö[rR]n\.\b/g, 'örneğin');
  return text;
}
