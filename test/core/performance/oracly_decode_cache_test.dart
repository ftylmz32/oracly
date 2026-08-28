import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/performance/oracly_decode_cache.dart';

void main() {
  test('decode cache matches display pixels and caps invalid sizes', () {
    expect(oraclyDecodeCachePx(100, 3), 300);
    expect(oraclyDecodeCachePx(72, 2.625), 189);
    expect(oraclyDecodeCachePx(double.infinity, 3), 2048);
    expect(oraclyDecodeCachePx(0, 3), 2048);
    expect(oraclyDecodeCachePx(-8, 3), 2048);
    expect(oraclyDecodeCachePx(double.infinity, 3, maxPx: 960), 960);
    expect(oraclyDecodeCachePx(4000, 3), 2048);
    expect(oraclyDecodeCachePx(4000, 3, maxPx: 512), 512);
  });
}
