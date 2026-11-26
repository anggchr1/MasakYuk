import 'package:flutter_test/flutter_test.dart';
import 'package:masakyuk/features/auth/auth_provider.dart';

void main() {
  test('pesan akun tertahan dari server dipakai apa adanya', () {
    expect(
      pesanApiDariBody(
          '{"pesan":"Akun kamu belum aktif. Link aktivasi sudah dikirim."}'),
      'Akun kamu belum aktif. Link aktivasi sudah dikirim.',
    );
  });

  test('body Laravel standar memakai field message', () {
    expect(
      pesanApiDariBody('{"message":"Akun dinonaktifkan."}'),
      'Akun dinonaktifkan.',
    );
  });

  test('body bukan JSON tidak dianggap pesan', () {
    expect(pesanApiDariBody('<html>404 Not Found</html>'), isNull);
  });
}
