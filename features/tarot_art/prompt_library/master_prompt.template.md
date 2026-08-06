# ORACLY Tarot — Master Illustration Prompt Template

Use this template for every card. Replace `{{VARIABLE}}` tokens from the card brief and category style rules. Do not remove fixed style anchors.

**Permanent style authority:** [`../art_direction/MASTER_STYLE.md`](../art_direction/MASTER_STYLE.md)

---

## PROMPT

```
ORACLY Tarot original artwork — proprietary dark-fantasy luxury oracle deck.
NOT Rider-Waite. NOT any published tarot deck. 100% original ORACLY visual identity.

CARD: {{CARD_NAME}}
ARCANA: {{ARCANA}}
ELEMENT: {{ELEMENT}}
NUMERAL: {{NUMERAL}}

── STYLE ANCHORS (fixed — see MASTER_STYLE.md) ──
Luxury mystical fantasy, cinematic concept art, ultra premium digital painting, collector edition, AAA game art quality.
Photorealistic fantasy characters, Hollywood cinematic lighting, golden rim light, mystical purple ambience, god rays, soft bloom.
Royal purple, deep violet, obsidian black, champagne gold, moon silver, soft cyan highlights, rich indigo, deep midnight blue.
Floating magical particles, ancient celestial symbols, subtle sacred geometry, golden runes, cosmic dust, nebula atmosphere — elegant, never overloaded.
Dreamlike ethereal backgrounds, hero centered, strong silhouette, large breathing space, 8K collector detail.
NOT cartoon, NOT anime, NOT comic, NOT watercolor, NOT Rider-Waite clone.
Digital painting, volumetric fog, crystal reflections, gold accents, deep purple void atmosphere (#0B0615 ground),
OR purple magic glow (#9B6DFF), ceremonial gold filigree frame (frame is composited separately — do not paint border),
minimum 4 depth planes, 15% negative space, moonlit skin tones, premium luxury fantasy.

── CATEGORY RULES ──
{{CATEGORY_STYLE_BLOCK}}

── CARD-SPECIFIC ──
Mood: {{MOOD}}
Lighting: {{LIGHTING}}
Dominant colors: {{DOMINANT_COLORS}}
Character: {{CHARACTER}}
Environment: {{ENVIRONMENT}}
Symbols: {{SYMBOLS}}
Magic effects: {{MAGIC_EFFECTS}}
Camera: {{CAMERA}}
Composition: {{COMPOSITION}}
Border style (reference only, locked asset): {{BORDER_STYLE}}
Particle style: {{PARTICLE_STYLE}}

── COMPOSITION CONSTRAINT ──
Paint ONLY the central illustration area. No text. No numerals. No card title.
No frame. No nameplate. Aspect-safe vertical composition 902×1219 equivalent.
Key light upper-left 45° warm gold rim. Cool purple fill from lower-right at 15%.

── ORACLY SIGNATURE ELEMENTS ──
Include at least 2 of: faceted OR crystal, sacred geometry lattice, distant stars/nebula,
gold particle dust, volumetric light shaft, element-colored magic emission.

Single cohesive painting — must match ORACLY Tarot deck as if painted by one master artist.
```

---

## VARIABLE DEFINITIONS

| Variable | Source | Example |
|----------|--------|---------|
| `{{CARD_NAME}}` | registry | The Star |
| `{{ARCANA}}` | registry | Major Arcana |
| `{{ELEMENT}}` | registry + rules | Air |
| `{{NUMERAL}}` | registry | XVII |
| `{{MOOD}}` | brief | Hopeful, serene, cosmic renewal |
| `{{LIGHTING}}` | brief + category | Strong rim light, god-ray from above |
| `{{DOMINANT_COLORS}}` | brief + palette | Void purple, celestial gold, soft cyan accent |
| `{{CHARACTER}}` | brief | Androgynous oracle figure pouring OR energy |
| `{{ENVIRONMENT}}` | brief | Star field pool, floating rock arch |
| `{{SYMBOLS}}` | brief | OR Prism, eight-point star, water ripples |
| `{{MAGIC_EFFECTS}}` | brief | Upward purple-gold energy stream |
| `{{CAMERA}}` | brief + category | Low hero angle, 65mm intimate |
| `{{COMPOSITION}}` | brief | Central iconic, triangular ascent |
| `{{BORDER_STYLE}}` | template | ORACLY locked gold filigree v1 |
| `{{PARTICLE_STYLE}}` | category rules | Gold dust + purple embers, 12 count |
| `{{CATEGORY_STYLE_BLOCK}}` | `style_rules/{category}.yaml` → `prompt_block` | (auto-injected) |

---

## ASSEMBLY SCRIPT (Manual)

1. Load card brief JSON
2. Load matching `style_rules/*.yaml`
3. Copy `prompt_block` into `{{CATEGORY_STYLE_BLOCK}}`
4. Replace all variables
5. Append `negative_prompt.txt`
6. Save to `briefs/{card_id}/prompt.md`

---

## QUALITY GATE

Prompt is valid when:
- All `{{VARIABLE}}` tokens replaced (zero remaining)
- `CATEGORY_STYLE_BLOCK` matches arcana/suit
- Negative prompt appended
- Art Director approved brief status = `brief_approved`
