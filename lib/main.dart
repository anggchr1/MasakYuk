import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    _repo = RecipeRepository();
    _auth = AuthProvider(_repo);
    _repo.load(); // NANTI M2: + Firebase.initializeApp + Auth gate
    _auth.muatSesi().then((_) {
      if (_auth.loggedIn) _repo.muatResepMilikku();
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
                  onLogout: _auth.logout,
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
  final VoidCallback onLogout;
  const HomeShell({super.key, required this.repo, required this.onLogout});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _tab = 0;
  // Diubah tiap tab Beranda diketuk ulang → HomeScreen dibangun fresh
  // (chip Semua, search kosong) sehingga selalu "kembali ke beranda".
  int _homeSalt = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: _tab,
          children: [
            HomeScreen(
              key: ValueKey(_homeSalt),
              repo: widget.repo,
              onNeedLogin: widget.onLogout,
            ),
            CookScreen(repo: widget.repo),
            FavoritesScreen(
              repo: widget.repo,
              onNeedLogin: widget.onLogout,
            ),
            ProfileScreen(
                repo: widget.repo, onLogout: widget.onLogout),
          ],
        ),
      ),
      bottomNavigationBar: BottomNav(
        index: _tab,
        onTap: (i) {
          if (i == 0 && _tab == 0) {
            setState(() => _homeSalt++); // ketuk Beranda 2x = reset
          } else {
            setState(() => _tab = i);
          }
        },
      ),
    );
  }
}
