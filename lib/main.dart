import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:timeago/timeago.dart' as timeago;

import 'core/theme/app_theme.dart';
import 'core/widgets/bottom_nav.dart';
import 'data/recipe_repository.dart';
import 'features/auth/auth_provider.dart';
import 'features/auth/login_view.dart';
import 'features/cook/cook_view.dart';
import 'features/splash/splash_view.dart';
import 'features/favorites/favorites_view.dart';
import 'features/home/home_view.dart';
import 'features/profile/profile_view.dart';

void main() {
  timeago.setLocaleMessages('id', timeago.IdMessages());
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    systemNavigationBarColor: Colors.white,
    systemNavigationBarIconBrightness: Brightness.dark,
  ));
  runApp(const MasakYukApp());
}

class MasakYukApp extends StatefulWidget {
  const MasakYukApp({super.key});

  @override
  State<MasakYukApp> createState() => _MasakYukAppState();
}

class _MasakYukAppState extends State<MasakYukApp> {
  late final RecipeRepository _repo;
  late final AuthProvider _auth;
  bool _splash = true;
  int _tabAwal = 0; // tab setelah login (3 = Profil)

  /// Tamu menekan "Masuk" di Profil: buka layar login, lalu kembali ke Profil.
  void _masukDariProfil() {
    setState(() => _tabAwal = 3);
    _auth.logout();
  }

  void _keluar() {
    setState(() => _tabAwal = 0);
    _auth.logout();
  }

  @override
  void initState() {
    super.initState();
    _repo = RecipeRepository();
    _repo.onNeedLogin = _masukDariProfil;
    _auth = AuthProvider(_repo);
    _repo.load(); // NANTI M2: + Firebase.initializeApp + Auth gate
    _auth.muatSesi().then((_) {
      if (_auth.loggedIn) {
        _repo.muatResepMilikku();
        _repo.muatFavorit();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MasakYuk',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: AnimatedBuilder(
        animation: _auth,
        builder: (_, _) {
          if (_splash) {
            return SplashScreen(
                onDone: () => setState(() => _splash = false));
          }
          if (!_auth.siap) {
            return const Scaffold(
                body: Center(child: CircularProgressIndicator()));
          }
          return _auth.loggedIn
              ? HomeShell(
                  repo: _repo,
                  initialTab: _tabAwal,
                  isGuest: _auth.isGuest,
                  onLogin: _masukDariProfil,
                  onLogout: _keluar,
                  onProfileSaved: _auth.simpanProfil,
                  onHapusAkun: _auth.hapusAkun,
                )
              : LoginScreen(
                  auth: _auth,
                  onGuest: _auth.loginAsGuest,
                );
        },
      ),
    );
  }

  @override
  void dispose() {
    _auth.dispose();
    super.dispose();
  }
}

/// Shell: 4 tab bawah sesuai desain (Home, Masak, Favorit, Profil).
class HomeShell extends StatefulWidget {
  final RecipeRepository repo;
  final int initialTab;
  final bool isGuest;
  final VoidCallback onLogin;
  final VoidCallback onLogout;
  final Future<void> Function()? onProfileSaved;
  final Future<void> Function()? onHapusAkun;
  const HomeShell(
      {super.key,
      required this.repo,
      this.initialTab = 0,
      this.isGuest = false,
      required this.onLogin,
      required this.onLogout,
      this.onProfileSaved,
      this.onHapusAkun});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  late int _tab = widget.initialTab;
  late int _prevTab;

  @override
  void initState() {
    super.initState();
    _prevTab = widget.initialTab;
  }

  Widget _pageAt(int i) {
    switch (i) {
      case 0:
        return HomeScreen(
          repo: widget.repo,
          onNeedLogin: widget.onLogout,
        );
      case 1:
        return CookScreen(repo: widget.repo);
      case 2:
        return FavoritesScreen(
          repo: widget.repo,
          onNeedLogin: widget.onLogout,
        );
      case 3:
        return ProfileScreen(
          repo: widget.repo,
          onLogout: widget.onLogout,
          isGuest: widget.isGuest,
          onLogin: widget.onLogin,
          onProfileSaved: widget.onProfileSaved,
          onHapusAkun: widget.onHapusAkun,
        );
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Arah slide: maju (tab naik) geser dari kanan, mundur geser dari kiri.
    final Offset slideFrom = _tab > _prevTab
        ? const Offset(1.0, 0.0)
        : const Offset(-1.0, 0.0);

    return Scaffold(
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          switchInCurve: Curves.easeInOut,
          switchOutCurve: Curves.easeInOut,
          transitionBuilder: (Widget child, Animation<double> animation) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: slideFrom,
                end: Offset.zero,
              ).animate(animation),
              child: FadeTransition(
                opacity: animation,
                child: child,
              ),
            );
          },
          child: IndexedStack(
            key: ValueKey(_tab),
            index: _tab,
            children: [
              _pageAt(0),
              _pageAt(1),
              _pageAt(2),
              _pageAt(3),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNav(
        index: _tab,
        onTap: (i) {
          if (i == _tab) return;
          setState(() {
            _prevTab = _tab;
            _tab = i;
          });
        },
      ),
    );
  }
}
