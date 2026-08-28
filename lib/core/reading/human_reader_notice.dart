/// Real, already-known facts. Never invented memory.
library;

enum HumanReaderLength { brief, deep }

class HumanReaderNotice {
  const HumanReaderNotice({
    required this.seed,
    this.name = '',
    this.seen = '',
    this.companion = '',
    this.meaning = '',
    this.lifeThread = '',
    this.evidence = '',
    this.vessel = '',
    this.length = HumanReaderLength.brief,
  });

  final int seed;
  final String name;
  final String seen;
  final String companion;
  final String meaning;
  final String lifeThread;
  final String evidence;
  final String vessel;
  final HumanReaderLength length;

  String get _n => name.trim();
  String get _s => seen.trim();
  String get _c => companion.trim();
  String get _m => meaning.trim();
  String get _l => lifeThread.trim();
  String get _e => evidence.trim();
  String get _v => vessel.trim();

  bool get hasName => _n.isNotEmpty;
  bool get hasSeen => _s.isNotEmpty;
  bool get hasCompanion => _c.isNotEmpty;
  bool get hasMeaning => _m.isNotEmpty;
  bool get hasLife => _l.isNotEmpty;
  bool get hasEvidence =>
      _e.isNotEmpty && _e != _s && !_m.contains(_e);
  bool get hasVessel => _v.isNotEmpty;
}
