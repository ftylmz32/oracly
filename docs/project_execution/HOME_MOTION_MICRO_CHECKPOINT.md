# HOME MICRO-INTERACTION + MOTION — Checkpoint

**Date:** 2026-08-25

## HOME MOTION STATUS = BLOCKED — DEVICE VERIFICATION

Home layout / artwork / copy / routes / backend / Premium logic were **not** redesigned.

### Implemented (code)

| Surface | Motion |
|---------|--------|
| Hero | Stable portrait; atmosphere light drifts + quiet shimmer (`HomeReferenceHeroAtmosphere`) |
| OR | Occasional living sweep (`HomeLivingSweep`) + existing glass/CTA press |
| Bugunun Izi | Existing drift + glass press + occasional sweep |
| Discovery | Refined doorway press (scale 1.018) |
| Premium | Occasional sweep + understated crown glow |
| Bottom nav | Selected icon `AnimatedScale` + existing pill |
| Enter reveal | Fast stagger via `HomeMasterReveal` (42ms × index, 320ms enter) |
| Reduced motion | Entrances snap complete; ambient freezes via `OraclyQuietMotion` |
| Scroll | Still zero-scroll |

### Verify

```
flutter analyze (touched paths) → No issues found
flutter test home_motion_micro + home_master_zero_scroll → passed
```

### TECNO KN8

| Check | Result |
|-------|--------|
| Launch / taps / nav feel | **BLOCKED** — no adb |
| Jank / stuck controllers | **BLOCKED** |
| Excessive vs weak motion judgment | **BLOCKED** |

### Exact remaining issue

Without device observation, cannot confirm the feel is alive-but-restrained rather than invisible or busy. Ambient loops are frozen on QuietMotion-constrained devices (KN8-class may rest-pose hero/sweeps by design).

**STOP.**
