import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_theme.dart';
import 'auth_provider.dart';

/// Layar aktivasi kembali akun yang dinonaktifkan, langsung di aplikasi.
///
/// Dua langkah: masukkan email akun → kode 6 digit dikirim → masukkan kode.
/// Bila kode benar, akun aktif lagi dan pengguna langsung masuk ke beranda
/// (AuthProvider menyimpan sesi sehingga tidak perlu login Google ulang).
class ReaktivasiScreen extends StatefulWidget {
  final AuthProvider auth;
  const ReaktivasiScreen({super.key, required this.auth});

  @override
  State<ReaktivasiScreen> createState() => _ReaktivasiScreenState();
}

class _ReaktivasiScreenState extends State<ReaktivasiScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _surel;
  final _kode = TextEditingController();

  /// Langkah 2 (masukkan kode) aktif setelah kode dikirim.
  bool _kodeTerkirim = false;

  @override
  void initState() {
    super.initState();
    _surel = TextEditingController(text: widget.auth.surelTertahan ?? '');
  }

  @override
  void dispose() {
    _surel.dispose();
    _kode.dispose();
    super.dispose();
  }

  Future<void> _kirimUlang() async {
    // Di langkah kode, kolom email sudah tidak tampil — jangan validasi form
    // (kolom kode yang sedang kosong akan dianggap salah).
    final ok = await widget.auth.kirimOtp(_surel.text.trim());
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kode baru sudah dikirim.')),
      );
    }
  }

  Future<void> _kirimKode() async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await widget.auth.kirimOtp(_surel.text.trim());
    if (!mounted) return;
    if (ok) {
      setState(() => _kodeTerkirim = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kode 6 digit sudah dikirim ke email kamu.')),
      );
    }
  }

  Future<void> _verifikasi() async {
    if (!_formKey.currentState!.validate()) return;
    final berhasil = await widget.auth.verifikasiOtp(
      _surel.text.trim(),
      _kode.text.trim(),
    );
    if (!mounted) return;
    if (berhasil) {
      // AuthProvider.loggedIn = true → MasakYukApp otomatis menampilkan Home.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Akun kamu aktif kembali. Selamat datang, '
            '${widget.auth.repo.userName}.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.auth,
      builder: (context, _) {
        final auth = widget.auth;
        return Scaffold(
          backgroundColor: AppColors.cream,
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _lencana(),
                        const SizedBox(height: 20),
                        const Text(
                          'Aktifkan Kembali Akun',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                            color: AppColors.chocolate,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _kodeTerkirim
                              ? 'Masukkan kode 6 digit yang kami kirim ke email kamu.'
                              : 'Akun kamu sedang dinonaktifkan. Masukkan email akun ini, '
                                  'lalu kami kirim kode 6 digit untuk mengaktifkannya kembali.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 14,
                            height: 20 / 14,
                            color: AppColors.chocolateMuted,
                          ),
                        ),
                        const SizedBox(height: 24),
                        if (!_kodeTerkirim) ..._formEmail(auth) else ..._formKode(auth),
                        if (auth.error != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            auth.error!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.error,
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: auth.busy
                              ? null
                              : () => widget.auth.batalkanReaktivasi(),
                          child: const Text('Kembali ke login'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _lencana() {
    return Center(
      child: Container(
        width: 72,
        height: 72,
        decoration: const BoxDecoration(
          color: Color(0xFFE3F3E8),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.lock_reset, size: 34, color: Color(0xFF166534)),
      ),
    );
  }

  List<Widget> _formEmail(AuthProvider auth) {
    return [
      _label('Email akun'),
      const SizedBox(height: 6),
      TextFormField(
        controller: _surel,
        keyboardType: TextInputType.emailAddress,
        autofillHints: const [AutofillHints.email],
        textInputAction: TextInputAction.done,
        decoration: _gayaInput('nama@email.com'),
        validator: (v) {
          final t = (v ?? '').trim();
          if (t.isEmpty) return 'Email wajib diisi.';
          if (!t.contains('@') || !t.contains('.')) {
            return 'Format email tidak valid.';
          }
          return null;
        },
        onFieldSubmitted: (_) => _kirimKode(),
      ),
      const SizedBox(height: 8),
      const Text(
        'Kode berlaku 10 menit. Akun bisa dipulihkan sampai 30 hari sejak dihapus.',
        style: TextStyle(fontSize: 12, color: AppColors.chocolateMuted),
      ),
      const SizedBox(height: 20),
      _tombol(
        label: 'Kirim Kode OTP',
        sibuk: auth.busy,
        onPressed: _kirimKode,
      ),
    ];
  }

  List<Widget> _formKode(AuthProvider auth) {
    return [
      _label('Kode OTP 6 digit'),
      const SizedBox(height: 6),
      TextFormField(
        controller: _kode,
        keyboardType: TextInputType.number,
        autofillHints: const [AutofillHints.oneTimeCode],
        textAlign: TextAlign.center,
        maxLength: 6,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w800,
          letterSpacing: 10,
        ),
        decoration: _gayaInput('000000').copyWith(counterText: ''),
        validator: (v) {
          final t = (v ?? '').trim();
          if (t.length != 6) return 'Kode terdiri dari 6 angka.';
          return null;
        },
        onFieldSubmitted: (_) => _verifikasi(),
      ),
      const SizedBox(height: 8),
      Text(
        'Kode dikirim ke ${_surel.text.trim()}.',
        style: const TextStyle(fontSize: 12, color: AppColors.chocolateMuted),
      ),
      const SizedBox(height: 20),
      _tombol(
        label: 'Aktifkan Akun',
        sibuk: auth.busy,
        onPressed: _verifikasi,
      ),
      const SizedBox(height: 4),
      TextButton(
        onPressed: auth.busy ? null : _kirimUlang,
        child: const Text('Kirim ulang kode'),
      ),
    ];
  }

  Widget _label(String teks) => Align(
        alignment: Alignment.centerLeft,
        child: Text(
          teks,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.chocolate,
          ),
        ),
      );

  InputDecoration _gayaInput(String hint) => InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFDEC0B7)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFDEC0B7)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      );

  Widget _tombol({
    required String label,
    required bool sibuk,
    required Future<void> Function() onPressed,
  }) {
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: sibuk ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: const StadiumBorder(),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
        child: sibuk
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(label),
      ),
    );
  }
}