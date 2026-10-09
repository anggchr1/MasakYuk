import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/bottom_nav.dart';
import 'data/recipe_repository.dart';
import 'features/auth/auth_provider.dart';
import 'features/auth/login_view.dart';
import 'features/splash/splash_view.dart';
import 'features/detail/detail_view.dart';
import 'features/favorites/favorites_view.dart';
import 'features/home/home_view.dart';
import 'features/profile/profile_view.dart';
import 'features/recipe_form/add_recipe_view.dart';
import 'models/recipe.dart';

void main() {
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
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MasakYuk',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: _splash
          ? SplashScreen(
              onDone: () => setState(() => _splash = false))
          : AnimatedBuilder(
              animation: _auth,
              builder: (_, _) => _auth.loggedIn
                  ? HomeShell(
                repo: _repo,
                onLogout: _auth.logout,
              )
            : LoginScreen(
              onLogin: _auth.login,
              onGuest: _auth.loginAsGuest,
            ),
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
            ),
            _cookTab(),
            FavoritesScreen(repo: widget.repo),
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

  /// Tab "Masak": resep terakhir difavoritkan → langsung ke Detail.
  /// Kosong = ajak tulis resep. (Tambah resep juga via FAB di Favorit.)
  Widget _cookTab() {
    final favs = widget.repo.favorites;
    if (favs.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.soup_kitchen,
                  size: 64, color: AppColors.primary),
              const SizedBox(height: 12),
              const Text(
                'Belum ada resep dibuka.\nCari bahan di Home atau tulis resep sendiri.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          AddRecipeScreen(repo: widget.repo)),
                ),
                icon: const Icon(Icons.add),
                label: const Text('Tulis Resep'),
              ),
            ],
          ),
        ),
      );
    }
    final Recipe last = favs.last;
    return DetailScreen(repo: widget.repo, recipe: last);
  }
}
