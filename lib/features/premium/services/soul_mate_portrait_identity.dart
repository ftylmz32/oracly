/// Stable Soulmate portrait identity. Seed stays internal. Not a face scan.
library;

import 'dart:convert';

import 'soul_mate_identity.dart';

const portraitIdentityVersion = 1;

class SoulMatePortraitCore {
  const SoulMatePortraitCore({
    required this.ageBand,
    required this.faceShape,
    required this.hairFamily,
    required this.eyePresentation,
    required this.skinToneRange,
    required this.stylingEnergy,
    required this.expressionEnergy,
    required this.visualMood,
    required this.relationshipArchetype,
  });

  final String ageBand;
  final String faceShape;
  final String hairFamily;
  final String eyePresentation;
  final String skinToneRange;
  final String stylingEnergy;
  final String expressionEnergy;
  final String visualMood;
  final String relationshipArchetype;

  String signature() => [
        ageBand,
        faceShape,
        hairFamily,
        eyePresentation,
        skinToneRange,
        stylingEnergy,
        relationshipArchetype,
      ].join('|');
}

class SoulMatePortraitIdentity {
  const SoulMatePortraitIdentity({
    required this.core,
    required this.presence,
    required this.renderNonce,
  });

  final SoulMatePortraitCore core;
  final String presence;
  final String renderNonce;

  SoulMateIdentity toIdentity() {
    return SoulMateIdentity(
      nonce: renderNonce,
      presence: presence,
      mood: core.visualMood,
      wardrobe: core.stylingEnergy,
      expression: core.expressionEnergy,
      ageBand: core.ageBand,
      faceShape: core.faceShape,
      hairFamily: core.hairFamily,
      eyePresentation: core.eyePresentation,
      relationshipArchetype: core.relationshipArchetype,
      stylingEnergy: core.stylingEnergy,
      expressionEnergy: core.expressionEnergy,
    );
  }

  static SoulMatePortraitIdentity derive({
    required String accountKey,
    required String presentation,
    String renderNonce = 'render-a',
  }) {
    final seed = _seed(accountKey, presentation);
    final core = _core(seed, presentation);
    return SoulMatePortraitIdentity(
      core: core,
      presence: _presence(presentation),
      renderNonce: renderNonce,
    );
  }
}

SoulMatePortraitCore _core(String seed, String presentation) {
  String pick(List<String> list, int at) {
    final byte = int.parse(seed.substring(at, at + 2), radix: 16);
    return list[byte % list.length];
  }

  return SoulMatePortraitCore(
    ageBand: pick(_age, 0),
    faceShape: pick(_face, 2),
    hairFamily: pick(_hair, 4),
    eyePresentation: pick(_eyes, 10),
    skinToneRange: pick(_skin, 14),
    stylingEnergy: pick(_style, 18),
    expressionEnergy: pick(_energy, 20),
    visualMood: pick(_mood, 22),
    relationshipArchetype: pick(_archetype, 26),
  );
}

String _seed(String accountKey, String presentation) {
  return _sha256(
    'oracly-soulmate-portrait-v$portraitIdentityVersion|$accountKey|$presentation',
  );
}

String _presence(String presentation) {
  if (presentation == 'feminine') return 'feminine-presenting adult';
  if (presentation == 'masculine') return 'masculine-presenting adult';
  return 'adult of unspecified presentation';
}

const _age = [
  'early twenties',
  'late twenties',
  'early thirties',
  'mid thirties',
  'early forties',
];
const _face = [
  'soft oval',
  'gently angular',
  'rounded rectangular',
  'heart-leaning oval',
  'long oval',
  'quiet square',
];
const _hair = [
  'dark brown',
  'deep black',
  'warm chestnut',
  'ash brown',
  'black-brown',
  'copper brown',
];
const _eyes = [
  'deep brown',
  'warm hazel',
  'cool grey-green',
  'amber brown',
  'muted green',
  'dark brown',
];
const _skin = [
  'warm medium',
  'cool fair',
  'golden olive',
  'deep warm brown',
  'light olive',
  'neutral beige',
];
const _style = [
  'quiet linen ease',
  'muted knit ease',
  'tailored dark layer',
  'soft cotton everyday',
  'understated wool coat',
  'minimal dark knit',
];
const _energy = [
  'inward calm',
  'quiet warmth',
  'concentrated stillness',
  'gentle reserve',
  'open thoughtfulness',
];
const _mood = [
  'reserved',
  'tender',
  'clear',
  'grounded',
  'luminous',
  'reflective',
];
const _archetype = [
  'steady listener',
  'quietly curious companion',
  'grounded presence',
  'softly playful reserve',
  'reserved warmth',
  'attentive calm',
];

String _sha256(String value) {
  final bytes = utf8.encode(value);
  var h0 = 0x6a09e667;
  var h1 = 0xbb67ae85;
  var h2 = 0x3c6ef372;
  var h3 = 0xa54ff53a;
  var h4 = 0x510e527f;
  var h5 = 0x9b05688c;
  var h6 = 0x1f83d9ab;
  var h7 = 0x5be0cd19;
  final bitLen = bytes.length * 8;
  final withPad = [...bytes, 0x80];
  while ((withPad.length % 64) != 56) {
    withPad.add(0);
  }
  for (var i = 7; i >= 0; i--) {
    withPad.add((bitLen >> (i * 8)) & 0xff);
  }
  for (var offset = 0; offset < withPad.length; offset += 64) {
    final w = List<int>.filled(64, 0);
    for (var i = 0; i < 16; i++) {
      final j = offset + i * 4;
      w[i] = (withPad[j] << 24) |
          (withPad[j + 1] << 16) |
          (withPad[j + 2] << 8) |
          withPad[j + 3];
    }
    for (var i = 16; i < 64; i++) {
      final s0 = _rot(w[i - 15], 7) ^ _rot(w[i - 15], 18) ^ (w[i - 15] >>> 3);
      final s1 = _rot(w[i - 2], 17) ^ _rot(w[i - 2], 19) ^ (w[i - 2] >>> 10);
      w[i] = (w[i - 16] + s0 + w[i - 7] + s1) & 0xffffffff;
    }
    var a = h0, b = h1, c = h2, d = h3, e = h4, f = h5, g = h6, h = h7;
    for (var i = 0; i < 64; i++) {
      final s1 = _rot(e, 6) ^ _rot(e, 11) ^ _rot(e, 25);
      final ch = (e & f) ^ ((~e & 0xffffffff) & g);
      final temp1 = (h + s1 + ch + _k[i] + w[i]) & 0xffffffff;
      final s0 = _rot(a, 2) ^ _rot(a, 13) ^ _rot(a, 22);
      final maj = (a & b) ^ (a & c) ^ (b & c);
      final temp2 = (s0 + maj) & 0xffffffff;
      h = g;
      g = f;
      f = e;
      e = (d + temp1) & 0xffffffff;
      d = c;
      c = b;
      b = a;
      a = (temp1 + temp2) & 0xffffffff;
    }
    h0 = (h0 + a) & 0xffffffff;
    h1 = (h1 + b) & 0xffffffff;
    h2 = (h2 + c) & 0xffffffff;
    h3 = (h3 + d) & 0xffffffff;
    h4 = (h4 + e) & 0xffffffff;
    h5 = (h5 + f) & 0xffffffff;
    h6 = (h6 + g) & 0xffffffff;
    h7 = (h7 + h) & 0xffffffff;
  }
  return [h0, h1, h2, h3, h4, h5, h6, h7].map(_hex32).join();
}

int _rot(int value, int bits) =>
    ((value >>> bits) | (value << (32 - bits))) & 0xffffffff;

String _hex32(int value) => value.toRadixString(16).padLeft(8, '0');

const _k = [
  0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1,
  0x923f82a4, 0xab1c5ed5, 0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3,
  0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174, 0xe49b69c1, 0xefbe4786,
  0x0fc19dc6, 0x240ca1cc, 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
  0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7, 0xc6e00bf3, 0xd5a79147,
  0x06ca6351, 0x14292967, 0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13,
  0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85, 0xa2bfe8a1, 0xa81a664b,
  0xc24b8b70, 0xc76c51a3, 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
  0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a,
  0x5b9cca4f, 0x682e6ff3, 0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208,
  0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2,
];
