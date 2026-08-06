/// OR-1160 — Prompt engine domain identifiers.
library;

enum PromptDomain {
  tarot('tarot'),
  dream('dream'),
  astrology('astrology'),
  dailyEnergy('daily_energy'),
  compatibility('compatibility'),
  numerology('numerology');

  const PromptDomain(this.id);
  final String id;
}
