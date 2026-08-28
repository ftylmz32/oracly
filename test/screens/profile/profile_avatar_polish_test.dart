/// Profile avatar polish — real initials; photo only when provided.
library;

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/screens/profile/reference/profile_avatar_geometry.dart';
import 'package:oracly_new/screens/profile/reference/profile_avatar_nebula.dart';
import 'package:oracly_new/screens/profile/reference/profile_avatar_sparkles.dart';
import 'package:oracly_new/screens/profile/reference/profile_reference_avatar.dart';

void main() {
  testWidgets('shows monogram initial when no photo', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(child: ProfileReferenceAvatar(initials: 'F')),
        ),
      ),
    );
    expect(find.text('F'), findsOneWidget);
    expect(find.byType(Image), findsNothing);
    expect(find.byType(ProfileAvatarNebula), findsOneWidget);
    expect(find.byType(ProfileAvatarGeometry), findsOneWidget);
    expect(find.byType(ProfileAvatarSparkleLayer), findsOneWidget);
  });

  testWidgets('same initial, different names yield different nebula seeds', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Row(
            children: [
              ProfileReferenceAvatar(initials: 'F', identity: 'Fatih'),
              ProfileReferenceAvatar(initials: 'F', identity: 'Ferhat'),
            ],
          ),
        ),
      ),
    );
    final nebulae = tester.widgetList<ProfileAvatarNebula>(
      find.byType(ProfileAvatarNebula),
    );
    expect(nebulae, hasLength(2));
    expect(nebulae.first.seed, isNot(nebulae.last.seed));
  });

  testWidgets('shows real photo when ImageProvider is given', (tester) async {
    final photo = MemoryImage(
      // 1x1 PNG
      Uint8List.fromList(<int>[
        0x89,
        0x50,
        0x4E,
        0x47,
        0x0D,
        0x0A,
        0x1A,
        0x0A,
        0x00,
        0x00,
        0x00,
        0x0D,
        0x49,
        0x48,
        0x44,
        0x52,
        0x00,
        0x00,
        0x00,
        0x01,
        0x00,
        0x00,
        0x00,
        0x01,
        0x08,
        0x02,
        0x00,
        0x00,
        0x00,
        0x90,
        0x77,
        0x53,
        0xDE,
        0x00,
        0x00,
        0x00,
        0x0C,
        0x49,
        0x44,
        0x41,
        0x54,
        0x08,
        0xD7,
        0x63,
        0xF8,
        0xCF,
        0xC0,
        0x00,
        0x00,
        0x00,
        0x03,
        0x00,
        0x01,
        0x00,
        0x05,
        0xFE,
        0xD4,
        0xEF,
        0x00,
        0x00,
        0x00,
        0x00,
        0x49,
        0x45,
        0x4E,
        0x44,
        0xAE,
        0x42,
        0x60,
        0x82,
      ]),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: ProfileReferenceAvatar(initials: 'F', photo: photo),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.byType(Image), findsOneWidget);
    expect(find.text('F'), findsNothing);
    expect(find.byType(ProfileAvatarNebula), findsNothing);
    expect(find.byType(ProfileAvatarGeometry), findsNothing);
  });
}
