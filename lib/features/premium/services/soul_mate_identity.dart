/// Shared portrait identity ? the same descriptors that shaped the image.
library;

class SoulMateIdentity {
  const SoulMateIdentity({
    required this.nonce,
    required this.presence,
    required this.mood,
    this.colorFamily = '',
    this.setting = '',
    this.lighting = '',
    this.wardrobe = '',
    this.composition = '',
    this.pose = '',
    this.expression = '',
    this.version = 0,
    this.ageBand = '',
    this.faceShape = '',
    this.hairFamily = '',
    this.eyePresentation = '',
    this.relationshipArchetype = '',
    this.stylingEnergy = '',
    this.expressionEnergy = '',
    this.contentHash = '',
  });

  final String nonce;
  final String presence;
  final String mood;
  final String colorFamily;
  final String setting;
  final String lighting;
  final String wardrobe;
  final String composition;
  final String pose;
  final String expression;
  final int version;
  final String ageBand;
  final String faceShape;
  final String hairFamily;
  final String eyePresentation;
  final String relationshipArchetype;
  final String stylingEnergy;
  final String expressionEnergy;
  final String contentHash;

  Map<String, String> toJson() => {
        'nonce': nonce,
        'presence': presence,
        'mood': mood,
        if (colorFamily.isNotEmpty) 'colorFamily': colorFamily,
        if (setting.isNotEmpty) 'setting': setting,
        if (lighting.isNotEmpty) 'lighting': lighting,
        if (wardrobe.isNotEmpty) 'wardrobe': wardrobe,
        if (composition.isNotEmpty) 'composition': composition,
        if (pose.isNotEmpty) 'pose': pose,
        if (expression.isNotEmpty) 'expression': expression,
        if (version > 0) 'version': '$version',
        if (ageBand.isNotEmpty) 'ageBand': ageBand,
        if (faceShape.isNotEmpty) 'faceShape': faceShape,
        if (hairFamily.isNotEmpty) 'hairFamily': hairFamily,
        if (eyePresentation.isNotEmpty) 'eyePresentation': eyePresentation,
        if (relationshipArchetype.isNotEmpty)
          'relationshipArchetype': relationshipArchetype,
        if (stylingEnergy.isNotEmpty) 'stylingEnergy': stylingEnergy,
        if (expressionEnergy.isNotEmpty) 'expressionEnergy': expressionEnergy,
        if (contentHash.isNotEmpty) 'contentHash': contentHash,
      };

  static SoulMateIdentity? fromMap(Object? raw) {
    if (raw is! Map) return null;
    final map = Map<String, dynamic>.from(raw);
    final nonce = map['nonce']?.toString().trim() ?? '';
    final presence = map['presence']?.toString().trim() ?? '';
    final mood = map['mood']?.toString().trim() ?? '';
    if (nonce.isEmpty || presence.isEmpty || mood.isEmpty) return null;
    return SoulMateIdentity(
      nonce: nonce,
      presence: presence,
      mood: mood,
      colorFamily: map['colorFamily']?.toString() ?? '',
      setting: map['setting']?.toString() ?? '',
      lighting: map['lighting']?.toString() ?? '',
      wardrobe: map['wardrobe']?.toString() ?? '',
      composition: map['composition']?.toString() ?? '',
      pose: map['pose']?.toString() ?? '',
      expression: map['expression']?.toString() ?? '',
      version: int.tryParse(map['version']?.toString() ?? '') ?? 0,
      ageBand: map['ageBand']?.toString() ?? '',
      faceShape: map['faceShape']?.toString() ?? '',
      hairFamily: map['hairFamily']?.toString() ?? '',
      eyePresentation: map['eyePresentation']?.toString() ?? '',
      relationshipArchetype: map['relationshipArchetype']?.toString() ?? '',
      stylingEnergy: map['stylingEnergy']?.toString() ?? '',
      expressionEnergy: map['expressionEnergy']?.toString() ?? '',
      contentHash: map['contentHash']?.toString() ?? '',
    );
  }
}
