/// Recent OR speech clips in memory only — never persisted conversation audio.
library;

import 'oracly_proxy_speech.dart';

class OraclySpeechCache {
  OraclySpeechCache({this.limit = 6});

  final int limit;
  final _clips = <String, OraclySpeechClip>{};

  OraclySpeechClip? take(String key) {
    final clip = _clips.remove(key);
    if (clip == null) return null;
    _clips[key] = clip;
    return clip;
  }

  void put(String key, OraclySpeechClip clip) {
    _clips.remove(key);
    _clips[key] = clip;
    while (_clips.length > limit) {
      _clips.remove(_clips.keys.first);
    }
  }

  void clear() => _clips.clear();
}
