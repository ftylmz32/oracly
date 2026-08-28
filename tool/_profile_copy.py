# -*- coding: utf-8 -*-
from pathlib import Path
p = Path(r"c:/Dev/oracly_new/lib/core/l10n/tables/table_profile.dart")
t = p.read_text(encoding="utf-8")
reps = [
(
"""  'profile.or_title': L10nTriple('OR', 'OR', 'OR'),""",
"""  'profile.or_title': L10nTriple('OR ile sohbet', 'Talk with OR', 'Разговор с OR'),""",
),
(
"""  'profile.space_whisper': L10nTriple(
    'Burası senin özel ORACLY odan.',
    'This is your private ORACLY room.',
    'Это твоя личная комната ORACLY.',
  ),""",
"""  'profile.space_whisper': L10nTriple(
    'Keşiflerin, anıların ve OR ile devamlılığın burada.',
    'Your discoveries, moments, and continuity with OR live here.',
    'Здесь живут твои открытия, моменты и непрерывность с OR.',
  ),""",
),
(
"""  'profile.observation_title': L10nTriple(
    "ORACLY'DEN BİR GÖZLEM",
    'AN ORACLY OBSERVATION',
    'НАБЛЮДЕНИЕ ORACLY',
  ),""",
"""  'profile.observation_title': L10nTriple(
    'OR İLE DEVAM',
    'CONTINUE WITH OR',
    'ПРОДОЛЖИТЬ С OR',
  ),""",
),
]
for old, new in reps:
    if old not in t:
        raise SystemExit("missing: " + old[:50])
    t = t.replace(old, new, 1)
p.write_bytes(t.encode("utf-8"))
print("ok")
# fix observation card if utf16
obs = Path(r"c:/Dev/oracly_new/lib/screens/profile/reference/profile_reference_or_observation_card.dart")
raw = obs.read_bytes()
if b"\x00" in raw[:100]:
    print("obs corrupt - need rewrite")
else:
    print("obs lines", len(obs.read_text(encoding="utf-8").splitlines()))
