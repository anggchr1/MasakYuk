import 'package:flutter_test/flutter_test.dart';
import 'package:masakyuk/core/sapaan.dart';

void main() {
  test('sapaan mengikuti jam, termasuk batas pergantian', () {
    String jam(int h) => sapaanJam(DateTime(2026, 1, 1, h));
    expect(jam(3), 'Good Night');
    expect(jam(4), 'Good Morning');
    expect(jam(10), 'Good Morning');
    expect(jam(11), 'Good Afternoon');
    expect(jam(14), 'Good Afternoon');
    expect(jam(15), 'Good Evening');
    expect(jam(18), 'Good Evening');
    expect(jam(19), 'Good Night');
    expect(jam(23), 'Good Night');
  });
}
