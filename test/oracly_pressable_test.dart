import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/theme/oracly_brand_signature.dart';

void main() {
  test('OraclySignatureMotion press tokens stay subtle', () {
    expect(OraclySignatureMotion.pressScale, greaterThan(0.97));
    expect(OraclySignatureMotion.pressScale, lessThan(1.0));
    expect(OraclySignatureMotion.pressOpacity, greaterThan(0.9));
    expect(OraclySignatureMotion.pressOpacity, lessThan(1.0));
    expect(OraclySignatureMotion.pressDepth, lessThan(2.0));
  });
}
