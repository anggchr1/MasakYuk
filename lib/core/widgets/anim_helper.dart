import 'package:flutter/material.dart';

/// Muncul satu per satu dari bawah dengan fade (staggered).
/// Cocok untuk daftar kartu di Home / Cook / Favorit / Places.
class StaggeredList extends StatelessWidget {
  final List<Widget> children;
  final Duration duration;
  final double slideY;

  const StaggeredList({
    super.key,
    required this.children,
    this.duration = const Duration(milliseconds: 650),
    this.slideY = 0.08,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(children.length, (i) {
        return SlideFade(
          delay: Duration(milliseconds: 80 * i),
          duration: duration,
          slideY: slideY,
          child: children[i],
        );
      }),
    );
  }
}

/// Satu widget yang geser ke atas sambil fade-in.
class SlideFade extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;
  final double slideY;

  const SlideFade({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 500),
    this.slideY = 0.08,
  });

  @override
  State<SlideFade> createState() => _SlideFadeState();
}

class _SlideFadeState extends State<SlideFade>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _fade = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
    _slide = Tween<Offset>(
      begin: Offset(0, widget.slideY),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: widget.child,
      ),
    );
  }
}

/// Route transisi geser dari kanan (modern app style).
class SlideRightRoute extends PageRouteBuilder {
  final Widget page;
  SlideRightRoute({required this.page})
      : super(
          pageBuilder: (_, _, _) => page,
          transitionsBuilder: (_, anim, _, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1, 0),
                end: Offset.zero,
              ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 300),
        );
}

/// PageTransitionBuilder supaya SEMUA route (Navigator.push) geser dari kanan.
class SlidePageTransitionsBuilder extends PageTransitionsBuilder {
  const SlidePageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(1, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
      child: child,
    );
  }
}
