/** Calendar-derived visual traits — photoreal atmosphere, not costume fantasy. */

export type SoulmateVisualProfile = {
  colorFamily: string;
  mood: string;
  setting: string;
  lighting: string;
  wardrobe: string;
  composition: string;
};

type MonthLook = {
  colorFamily: string;
  mood: string;
  setting: string;
};

const MONTH_LOOK: MonthLook[] = [
  {
    colorFamily: 'cool silver-blue and pale gold',
    mood: 'still and reserved',
    setting: 'quiet winter interior, frosted window light, photoreal room',
  },
  {
    colorFamily: 'soft rose-quartz and dove grey',
    mood: 'tender and inward',
    setting: 'modern apartment corner with dried flowers, natural daylight',
  },
  {
    colorFamily: 'mist lilac and young-leaf green',
    mood: 'awakening and gentle',
    setting: 'early-spring park path at first light, soft haze',
  },
  {
    colorFamily: 'rain-washed teal and cream',
    mood: 'clear and thoughtful',
    setting: 'open city terrace after rain, wet stone, distant skyline soft',
  },
  {
    colorFamily: 'warm sage and honey gold',
    mood: 'open and hopeful',
    setting: 'late-spring garden terrace, real foliage, shallow depth of field',
  },
  {
    colorFamily: 'sunlit wheat and sky blue',
    mood: 'easy and luminous',
    setting: 'high-summer meadow edge, natural sun, soft bokeh',
  },
  {
    colorFamily: 'warm citrus and sea-glass',
    mood: 'bright and unhurried',
    setting: 'shaded courtyard at noon, stone and plant shadows',
  },
  {
    colorFamily: 'deep amber and terracotta',
    mood: 'warm and grounded',
    setting: 'late-summer dusk courtyard, warm practical lamps',
  },
  {
    colorFamily: 'burnished copper and olive',
    mood: 'reflective and rich',
    setting: 'early-autumn reading nook by a real window',
  },
  {
    colorFamily: 'ember red and smoke grey',
    mood: 'quiet and concentrated',
    setting: 'evening lounge with a single warm practical light',
  },
  {
    colorFamily: 'muted plum and pewter',
    mood: 'solemn and intimate',
    setting: 'dusk city interior, low lamps, violet night ambient outside',
  },
  {
    colorFamily: 'deep indigo and candle gold',
    mood: 'hushed and contemplative',
    setting: 'night city balcony, soft violet night air, distant lights',
  },
];

const LIGHTING = [
  'soft key light from camera-left, subtle warm rim on hair and shoulder',
  'cool soft key with gentle gold rim, controlled highlights on skin',
  'late-afternoon key with violet ambient fill, soft shadow falloff',
  'warm interior key lamp, faint rim separating subject from background',
  'soft window key, quiet rim, warm-violet environmental balance',
];

const WARDROBE = [
  'contemporary linen shirt, clean collar, no costume',
  'modern knit sweater in a muted tone, everyday fit',
  'simple dark blazer over a plain tee, believable streetwear',
  'soft cotton blouse, understated jewelry only if natural',
  'contemporary wool coat, open, real fabric texture',
  'minimal black turtleneck, quiet premium everyday style',
];

const COMPOSITION = [
  'vertical portrait, head and upper chest, generous headroom, face fully in frame',
  'three-quarter portrait with breathing space above the head, eyes in upper third',
  'seated near a window, hands relaxed and anatomically correct if visible',
  'standing in shallow depth, slight shoulder turn, face clear of frame edges',
];

export function visualProfileFromBirthDate(
  iso: string,
): SoulmateVisualProfile {
  const parsed = parseIsoDate(iso);
  const month = MONTH_LOOK[(parsed.m - 1 + 12) % 12] ?? MONTH_LOOK[0]!;
  return {
    colorFamily: month.colorFamily,
    mood: month.mood,
    setting: month.setting,
    lighting: LIGHTING[parsed.d % LIGHTING.length] ?? LIGHTING[0]!,
    wardrobe:
      WARDROBE[(parsed.y + parsed.d) % WARDROBE.length] ?? WARDROBE[0]!,
    composition:
      COMPOSITION[(parsed.y * 12 + parsed.m) % COMPOSITION.length] ??
      COMPOSITION[0]!,
  };
}

export function profilesDiffer(
  a: SoulmateVisualProfile,
  b: SoulmateVisualProfile,
): boolean {
  return (
    a.colorFamily !== b.colorFamily ||
    a.mood !== b.mood ||
    a.setting !== b.setting ||
    a.lighting !== b.lighting ||
    a.wardrobe !== b.wardrobe ||
    a.composition !== b.composition
  );
}

function parseIsoDate(iso: string): { y: number; m: number; d: number } {
  const match = /^(\d{4})-(\d{2})-(\d{2})$/.exec(iso.trim());
  if (!match) return { y: 2000, m: 1, d: 1 };
  return {
    y: Number(match[1]),
    m: Number(match[2]),
    d: Number(match[3]),
  };
}
