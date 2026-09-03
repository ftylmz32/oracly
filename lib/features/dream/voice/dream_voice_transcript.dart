/// Accumulates dream narration across STT partials, finals, and pauses.
library;

class _CommittedSegment {
  _CommittedSegment(this.text, this.generation);

  final String text;
  final int generation;
}

class DreamVoiceTranscript {
  final List<_CommittedSegment> _segments = [];
  String _partial = '';
  var _generation = 0;

  int get segmentCount => _segments.length;
  int get partialLength => _partial.length;
  int get generation => _generation;

  String get text {
    if (_partial.isEmpty) {
      return _segments.map((s) => s.text).join(' ').trim();
    }
    if (_segments.isEmpty) return _partial;
    return '${_segments.map((s) => s.text).join(' ')} $_partial'.trim();
  }

  bool get isEmpty => _segments.isEmpty && _partial.isEmpty;

  void reset() {
    _segments.clear();
    _partial = '';
    _generation = 0;
  }

  /// Seal partial from the ending generation, then open the next one.
  void beginNextGeneration() {
    finalizeActiveSegment();
    _generation += 1;
    _partial = '';
  }

  void applyResult(String raw, bool isFinal, {required int generation}) {
    if (generation < _generation) return;
    if (generation > _generation) _generation = generation;
    final incoming = raw.trim();
    if (incoming.isEmpty) return;
    if (!isFinal) {
      _partial = incoming;
      return;
    }
    _commitFinal(incoming, generation: generation);
    _partial = '';
  }

  void finalizeActiveSegment() {
    if (_partial.isEmpty) return;
    _commitFinal(_partial, generation: _generation);
    _partial = '';
  }

  void _commitFinal(String incoming, {required int generation}) {
    final segment = _mergeWithPartial(incoming);
    if (segment.isEmpty) return;
    if (_segments.isEmpty) {
      _segments.add(_CommittedSegment(segment, generation));
      return;
    }
    final last = _segments.last;
    if (segment == last.text && last.generation == generation) return;
    if (last.generation == generation &&
        _extendsWithinGeneration(last.text, segment)) {
      _segments[_segments.length - 1] =
          _CommittedSegment(segment, generation);
      return;
    }
    if (last.generation == generation &&
        _extendsWithinGeneration(segment, last.text)) {
      return;
    }
    _segments.add(_CommittedSegment(segment, generation));
  }

  String _mergeWithPartial(String incoming) {
    if (_partial.isEmpty) return incoming;
    if (incoming == _partial) return incoming;
    if (incoming.startsWith(_partial)) return incoming;
    if (_partial.startsWith(incoming)) return _partial;
    return incoming;
  }

  /// Refinement only when [later] clearly continues [earlier] in the same breath.
  bool _extendsWithinGeneration(String earlier, String later) {
    if (later == earlier) return true;
    return later.startsWith('$earlier ');
  }
}
