/// R7 — Firebase client-access security contract (backend-only deny-all).
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:yaml/yaml.dart';

void main() {
  test('firestore.rules and storage.rules exist as deny-all client contracts',
      () {
    final firestore = File('firestore.rules').readAsStringSync();
    final storage = File('storage.rules').readAsStringSync();
    expect(firestore.contains("rules_version = '2'"), isTrue);
    expect(storage.contains("rules_version = '2'"), isTrue);
    expect(firestore.contains('allow read, write: if false'), isTrue);
    expect(storage.contains('allow read, write: if false'), isTrue);
    expect(firestore.contains('allow read, write: if true'), isFalse);
    expect(storage.contains('allow read, write: if true'), isFalse);
    expect(firestore.contains('allow read: if true'), isFalse);
    expect(storage.contains('allow read: if true'), isFalse);
  });

  test('firebase.json references the deny-all rule files only', () {
    final json = jsonDecode(File('firebase.json').readAsStringSync())
        as Map<String, dynamic>;
    expect(json['firestore'], isA<Map>());
    expect(json['storage'], isA<Map>());
    expect((json['firestore'] as Map)['rules'], 'firestore.rules');
    expect((json['storage'] as Map)['rules'], 'storage.rules');
    expect(json.containsKey('hosting'), isFalse);
    expect(json.containsKey('functions'), isFalse);
    final raw = File('firebase.json').readAsStringSync();
    expect(raw.contains('oracly-7f613'), isFalse);
    expect(raw.toLowerCase().contains('private_key'), isFalse);
  });

  test('Flutter production deps exclude Firestore and Storage client SDKs', () {
    final doc = loadYaml(File('pubspec.yaml').readAsStringSync()) as YamlMap;
    final deps = Map<String, dynamic>.from(doc['dependencies'] as YamlMap);
    expect(deps.containsKey('cloud_firestore'), isFalse);
    expect(deps.containsKey('firebase_storage'), isFalse);
    expect(deps.containsKey('firebase_core'), isTrue);
    expect(deps.containsKey('firebase_auth'), isTrue);
  });

  test('production lib has no FirebaseFirestore / FirebaseStorage client use', () {
    final hits = <String>[];
    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final text = entity.readAsStringSync();
      if (text.contains('package:cloud_firestore/') ||
          text.contains('package:firebase_storage/') ||
          text.contains('FirebaseFirestore') ||
          text.contains('FirebaseStorage')) {
        hits.add(entity.path);
      }
    }
    expect(hits, isEmpty, reason: hits.join(', '));
  });
}
