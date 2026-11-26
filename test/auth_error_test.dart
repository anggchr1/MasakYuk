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

  test('akun dinonaktifkan membawa email untuk layar reaktivasi', () {
    final info = infoReaktivasiDariBody(
      '{"pesan":"Akun kamu sedang dinonaktifkan.","reaktivasi":true,'
      '"surel":"aku@example.com","url_reaktivasi":"https://web/reaktivasi"}',
    );

    expect(info.perlu, isTrue);
    expect(info.surel, 'aku@example.com');
    expect(info.url, 'https://web/reaktivasi');
  });

  test('verifikasi email biasa tidak dianggap reaktivasi', () {
    final info = infoReaktivasiDariBody(
      '{"pesan":"Akun kamu belum aktif.","reaktivasi":false}',
    );

    expect(info.perlu, isFalse);
    expect(info.surel, isNull);
    expect(info.url, isNull);
  });
}