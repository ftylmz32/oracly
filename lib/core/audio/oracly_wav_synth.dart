/// EPIC-015 — Procedural WAV synthesis for subtle mystical SFX.
library;

import 'dart:math';
import 'dart:typed_data';

import 'oracly_atmosphere_palette.dart';
import 'oracly_sound_chamber.dart';
import '../../features/birth_chart/models/zodiac_sign_id.dart';

abstract final class OraclyWavSynth {
  OraclyWavSynth._();

  static const _sampleRate = 22050;

  static Uint8List softTap({double detune = 1.0}) {
    // Warm low soft pad — audible on device, still not a UI "click".
    return tone(
      frequencyHz: 248 * detune,
      durationMs: 110,
      volume: 0.17,
      attackMs: 10,
      releaseMs: 78,
    );
  }

  static Uint8List paperRustle({double detune = 1.0}) {
    final samples = (_sampleRate * 0.22).round();
    return _pcm(
      samples,
      (i, t) {
        final p = samples <= 1 ? 0.0 : i / (samples - 1);
        final env = sin(pi * p) * 0.10;
        final grain = sin(2 * pi * (92 * detune) * t) * 0.38 +
            sin(2 * pi * (168 * detune + 40 * sin(t * 28)) * t) * 0.28 +
            sin(2 * pi * 54 * t) * 0.22;
        return grain * env;
      },
    );
  }

  static Uint8List selectionTick({double detune = 1.0}) {
    return tone(
      frequencyHz: 312 * detune,
      durationMs: 70,
      volume: 0.15,
      attackMs: 5,
      releaseMs: 48,
    );
  }

  static Uint8List tone({
    required double frequencyHz,
    required int durationMs,
    double volume = 0.11,
    double attackMs = 8,
    double releaseMs = 60,
  }) {
    final samples = (_sampleRate * durationMs / 1000).round();
    return _pcm(
      samples,
      (i, t) {
        final attack = min(1.0, i / (_sampleRate * attackMs / 1000));
        final release = min(1.0, (samples - i) / (_sampleRate * releaseMs / 1000));
        return sin(2 * pi * frequencyHz * t) * volume * attack * release;
      },
    );
  }

  static Uint8List sweep({
    required double fromHz,
    required double toHz,
    required int durationMs,
    double volume = 0.09,
  }) {
    final samples = (_sampleRate * durationMs / 1000).round();
    return _pcm(
      samples,
      (i, t) {
        final p = i / max(1, samples - 1);
        final freq = fromHz + (toHz - fromHz) * p;
        final env = sin(pi * p);
        return sin(2 * pi * freq * t) * volume * env;
      },
    );
  }

  static Uint8List chime({
    required List<double> frequencies,
    required int durationMs,
    double volume = 0.1,
  }) {
    final samples = (_sampleRate * durationMs / 1000).round();
    return _pcm(
      samples,
      (i, t) {
        var mix = 0.0;
        for (final f in frequencies) {
          final partial = sin(2 * pi * f * t);
          final decay = exp(-3.2 * i / samples);
          mix += partial * decay;
        }
        return (mix / frequencies.length) * volume;
      },
    );
  }

  static Uint8List ambientLoop(OraclySoundChamber chamber) {
    final freqs = switch (chamber) {
      OraclySoundChamber.home => [98.0, 147.2, 196.0],
      OraclySoundChamber.tarot => [110.0, 164.8, 220.0],
      OraclySoundChamber.reading => [87.3, 130.8, 174.6],
      OraclySoundChamber.silence => <double>[],
    };
    return _droneLoop(freqs, bedVolume: 0.035);
  }

  /// Personal burç atmosphere — soft looping bed, no loud attack.
  static Uint8List zodiacAtmosphere(ZodiacSignId sign) {
    return _droneLoop(
      OraclyAtmospherePalette.frequencies(sign),
      bedVolume: OraclyAtmospherePalette.bedVolume,
    );
  }

  static Uint8List _droneLoop(
    List<double> freqs, {
    required double bedVolume,
  }) {
    if (freqs.isEmpty) return Uint8List(0);

    const loopMs = 4800;
    final samples = (_sampleRate * loopMs / 1000).round();
    return _pcm(
      samples,
      (i, t) {
        var mix = 0.0;
        for (var n = 0; n < freqs.length; n++) {
          final drift = sin(2 * pi * (0.035 + n * 0.012) * t) * 0.35;
          mix += sin(2 * pi * (freqs[n] + drift) * t);
        }
        final breathe = 0.84 + 0.16 * sin(2 * pi * t / 7.2);
        // Soft edge so loop joins without a click.
        final edge = min(1.0, i / (_sampleRate * 0.08)) *
            min(1.0, (samples - i) / (_sampleRate * 0.08));
        return (mix / freqs.length) * bedVolume * breathe * edge;
      },
    );
  }

  static Uint8List _pcm(
    int samples,
    double Function(int index, double timeSec) generator,
  ) {
    final dataSize = samples * 2;
    final bytes = ByteData(44 + dataSize);
    _writeHeader(bytes, dataSize);

    for (var i = 0; i < samples; i++) {
      final t = i / _sampleRate;
      final sample = generator(i, t).clamp(-1.0, 1.0);
      bytes.setInt16(
        44 + i * 2,
        (sample * 32767).round().clamp(-32768, 32767),
        Endian.little,
      );
    }
    return bytes.buffer.asUint8List();
  }

  static void _writeHeader(ByteData bytes, int dataSize) {
    void ascii(int offset, String value) {
      for (var i = 0; i < value.length; i++) {
        bytes.setUint8(offset + i, value.codeUnitAt(i));
      }
    }

    ascii(0, 'RIFF');
    bytes.setUint32(4, 36 + dataSize, Endian.little);
    ascii(8, 'WAVE');
    ascii(12, 'fmt ');
    bytes.setUint32(16, 16, Endian.little);
    bytes.setUint16(20, 1, Endian.little);
    bytes.setUint16(22, 1, Endian.little);
    bytes.setUint32(24, _sampleRate, Endian.little);
    bytes.setUint32(28, _sampleRate * 2, Endian.little);
    bytes.setUint16(32, 2, Endian.little);
    bytes.setUint16(34, 16, Endian.little);
    ascii(36, 'data');
    bytes.setUint32(40, dataSize, Endian.little);
  }
}
