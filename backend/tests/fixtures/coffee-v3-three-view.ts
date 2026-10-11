import type { CoffeeMultiViewObservationV3, CoffeeV3MapSlot } from '../../src/ai/reading/types.js';

/**
 * Re-expresses a frozen M1 / C3.1 fixture observation as the live three-photo
 * capture (cup_view_a, cup_view_b, saucer) WITHOUT editing the frozen
 * fixtures: cup_handle_far → cup_view_a, cup_turn_a → cup_view_b. Clocks are
 * frame-local (handle-relative), so every mark keeps its exact geometry.
 * A fixture with evidence on a third cup view cannot be expressed in three
 * photos; it throws rather than silently dropping evidence.
 */
const LIVE: Partial<Record<CoffeeV3MapSlot, CoffeeV3MapSlot>> = {
  cup_handle_far: 'cup_view_a',
  cup_turn_a: 'cup_view_b',
  saucer: 'saucer',
};

export function toThreeViewObservation(obs: CoffeeMultiViewObservationV3): CoffeeMultiViewObservationV3 {
  if (obs.sightings.some((s) => s.slot === 'cup_turn_b')) throw new Error('fixture needs a third cup view');
  const slot = (s: CoffeeV3MapSlot): CoffeeV3MapSlot => {
    const live = LIVE[s];
    if (!live) throw new Error(`no live view for ${s}`);
    return live;
  };
  return {
    ...obs,
    views: obs.views.filter((v) => v.slot !== 'cup_turn_b').map((v) => ({ ...v, slot: slot(v.slot) })),
    sightings: obs.sightings.map((s) => ({ ...s, slot: slot(s.slot) })),
  };
}
