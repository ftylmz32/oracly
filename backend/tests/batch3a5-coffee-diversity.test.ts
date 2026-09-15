/**
 * BATCH 3A.5 — coffee insight diversity and evidence concentration.
 * Palm fixtures stay on the 3A.4 contract and are not rewritten here.
 */

import { readFileSync } from "node:fs";
import { describe, expect, it } from "vitest";
import {
  coffeeSemanticCollapse,
  evaluateCoffeeQuality,
} from "../src/ai/human-quality.js";
import { bindCoffeeNarrative } from "../src/ai/reading/evidence-bind.js";
import {
  coffeeEvidenceConcentration,
  coffeeRepairFocus,
} from "../src/ai/reading/coffee-diversity.js";
import { coffeeWriterSystem, repairWriterSystem, repairWriterUser } from "../src/ai/reading/writer-prompts.js";
import type { CoffeeNarrative, CoffeeObservation, ReadingEvidenceItem } from "../src/ai/reading/types.js";

function load(name: string) {
  return JSON.parse(readFileSync(`./tests/fixtures/batch3a/${name}.json`, "utf8"));
}

function coffeeInput(n: CoffeeNarrative) {
  return {
    visualObservation: n.visualObservation.text,
    overall: n.overall.text,
    love: n.love.text,
    career: n.career.text,
    money: n.money.text,
    nearFuture: n.nearFuture.text,
    takeaway: n.takeaway.text,
    language: "tr" as const,
  };
}

const GROUNDING = new Set([
  "unusable",
  "insufficient_evidence",
  "unknown_evidence_id",
  "missing_evidence_ids",
  "empty_required",
  "human_quality",
]);

describe("BATCH 3A.5 — coffee distinct insights", () => {
  it("rejects the live 3A.4 reading for insight concentration, not grounding", () => {
    const live = load("coffee_live_3a4");
    const n = live.narrative as CoffeeNarrative;
    expect(coffeeSemanticCollapse(n.overall.text, n.nearFuture.text, n.takeaway.text)).toBe(true);
    expect(evaluateCoffeeQuality(coffeeInput(n))).toBe("insight_collapse");
    const bound = bindCoffeeNarrative(n, live.observation, "tr", { firstName: "Fatih" });
    expect(bound).toBe("insight_collapse");
    expect(GROUNDING.has(bound ?? "")).toBe(false);
  });

  it("accepts additive insights on the same observer evidence", () => {
    const good = load("coffee_good_3a5");
    expect(evaluateCoffeeQuality(coffeeInput(good.narrative))).toBeNull();
    expect(bindCoffeeNarrative(good.narrative, good.observation, "tr", { firstName: "Fatih" })).toBeNull();
    expect(good.narrative.overall.text.includes("Fatih")).toBe(false);
  });

  it("allows the same evidence to be synthesized without verbatim repetition", () => {
    const good = load("coffee_good_3a5");
    const n = structuredClone(good.narrative) as CoffeeNarrative;
    n.nearFuture = { text: "", evidenceIds: [] };
    n.takeaway = { text: good.narrative.takeaway.text, evidenceIds: ["e1"] };
    expect(n.overall.evidenceIds).toEqual(["e1"]);
    expect(n.takeaway.evidenceIds).toEqual(["e1"]);
    expect(coffeeEvidenceConcentration(n, good.observation.evidence)).toBe(false);
    expect(bindCoffeeNarrative(n, good.observation, "tr")).toBeNull();
  });

  it("does not force extra lanes when observer evidence is thin", () => {
    const thin: CoffeeObservation = {
      usable: true,
      reason: "",
      checks: {
        cupInteriorVisible: true,
        adequateFocusLight: true,
        residueVisible: true,
        milkFoamObstruction: false,
        usefulRegionsVisible: true,
      },
      evidence: [
        {
          id: "e1",
          region: "base",
          description: "A single dense mass at the base.",
          confidence: "high",
          visibility: "clear",
          resemblance: null,
        },
      ],
    };
    const base = load("coffee_good_3a5").narrative as CoffeeNarrative;
    const shared = {
      visualObservation: { text: base.visualObservation.text, evidenceIds: ["e1"] },
      overall: { text: base.overall.text, evidenceIds: ["e1"] },
      love: { text: "", evidenceIds: [] },
      career: { text: "", evidenceIds: [] },
      money: { text: "", evidenceIds: [] },
      nearFuture: { text: "", evidenceIds: [] },
      takeaway: { text: base.takeaway.text, evidenceIds: ["e1"] },
    } satisfies CoffeeNarrative;
    expect(bindCoffeeNarrative(shared, thin, "tr")).toBeNull();

    const stretched: CoffeeNarrative = {
      ...shared,
      nearFuture: { text: base.nearFuture.text, evidenceIds: ["e1"] },
    };
    expect(coffeeEvidenceConcentration(stretched, thin.evidence)).toBe(true);
    expect(bindCoffeeNarrative(stretched, thin, "tr")).toBe("insight_collapse");
  });

  it("repair focus asks for unused grounded evidence and names the collapsed cluster", () => {
    const live = load("coffee_live_3a4");
    const focus = coffeeRepairFocus(live.narrative, live.observation.evidence as ReadingEvidenceItem[]);
    expect(focus).toContain("unused grounded evidence");
    expect(focus).toMatch(/upper|handle|base/);
    expect(focus).toContain("Do not return to speaking");
    expect(repairWriterSystem("coffee")).toContain("If insight_collapse");
    expect(repairWriterUser({
      evidenceJson: "{}",
      rejectedJson: "{}",
      violations: ["insight_collapse"],
      guidance: focus,
    })).toContain("Repair focus:");
    expect(coffeeWriterSystem("tr")).toContain("OVERALL:");
    expect(coffeeWriterSystem("tr")).toContain("NEAR FUTURE:");
    expect(coffeeWriterSystem("tr")).toContain("Do not insert firstName");
    expect(coffeeWriterSystem("tr")).toContain("short secondary caption");
  });
});
