import 'dart:async';
import 'package:flutter/material.dart';
import '../main.dart';
import 'auth/auth_gate.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // ── quotes ────────────────────────────────────────────────────────────────
  int _quoteIndex = 0;
  final List<String> _quotes = [
    "Plan with energy.",
    "Focus on the next block.",
    "Review. Adjust. Continue.",
  ];

  static const int _quoteDurationMs = 900;
  static const int _totalDurationMs = 3 * _quoteDurationMs;

  // ── animation controllers ─────────────────────────────────────────────────
  late final AnimationController _entranceCtrl;
  late final AnimationController _progressCtrl;
  late final AnimationController _logoCtrl;

  late final Animation<double> _logoScale;
  late final Animation<double> _logoOpacity;
  late final Animation<double> _taglineOpacity;
  late final Animation<Offset> _taglineSlide;

  Timer? _quoteTimer;

  @override
  void initState() {
    super.initState();

    // logo pop-in
    _logoCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _logoScale = CurvedAnimation(parent: _logoCtrl, curve: Curves.elasticOut)
        .drive(Tween(begin: 0.6, end: 1.0));
    _logoOpacity = CurvedAnimation(parent: _logoCtrl, curve: Curves.easeOut)
        .drive(Tween(begin: 0.0, end: 1.0));

    // entrance slide for tagline
    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _taglineOpacity =
        CurvedAnimation(parent: _entranceCtrl, curve: const Interval(0.3, 1.0))
            .drive(Tween(begin: 0.0, end: 1.0));
    _taglineSlide = CurvedAnimation(
            parent: _entranceCtrl,
            curve: const Interval(0.3, 1.0, curve: Curves.easeOut))
        .drive(Tween(begin: const Offset(0, 0.4), end: Offset.zero));

    // progress bar
    _progressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: _totalDurationMs),
    );

    // start sequence
    _logoCtrl.forward().then((_) {
      _entranceCtrl.forward();
      _progressCtrl.forward();
      _startQuoteTimer();
    });
  }

  void _startQuoteTimer() {
    _quoteTimer = Timer.periodic(
      const Duration(milliseconds: _quoteDurationMs),
      (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }
        if (_quoteIndex < _quotes.length - 1) {
          setState(() => _quoteIndex++);
        } else {
          timer.cancel();
          _navigateToMain();
        }
      },
    );
  }

  void _navigateToMain() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const AuthGate(),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 900),
      ),
    );
  }

  @override
  void dispose() {
    _quoteTimer?.cancel();
    _logoCtrl.dispose();
    _entranceCtrl.dispose();
    _progressCtrl.dispose();
    super.dispose();
  }

  // ── UI ────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          _AmbientGlow(size: size),

          // ── logo block ────────────────────────────────────────────────────
          Positioned(
            top: size.height * 0.22,
            left: 0,
            right: 0,
            child: AnimatedBuilder(
              animation: _logoCtrl,
              builder: (_, __) => Opacity(
                opacity: _logoOpacity.value,
                child: Transform.scale(
                  scale: _logoScale.value,
                  child: Column(
                    children: [
                      Container(
                        width: 84,
                        height: 84,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [
                              AppColors.primaryOrange,
                              Color(0xFFFFB062)
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryOrange.withOpacity(0.45),
                              blurRadius: 34,
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          'E',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 34,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),
                      const Text(
                        'erten',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 46,
                          fontWeight: FontWeight.w800,
                          height: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── tagline (appears after logo) ──────────────────────────────────
          Positioned(
            top: size.height * 0.52,
            left: 32,
            right: 32,
            child: AnimatedBuilder(
              animation: _entranceCtrl,
              builder: (_, __) => FadeTransition(
                opacity: _taglineOpacity,
                child: SlideTransition(
                  position: _taglineSlide,
                  child: const Text(
                    'Personal time design',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF8A8A8A),
                      fontSize: 17,
                      fontWeight: FontWeight.w500,
                      height: 1.5,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── animated quote ────────────────────────────────────────────────
          Positioned(
            bottom: size.height * 0.18,
            left: 36,
            right: 36,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 700),
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: SlideTransition(
                  position: anim.drive(
                    Tween(
                      begin: const Offset(0, 0.15),
                      end: Offset.zero,
                    ),
                  ),
                  child: child,
                ),
              ),
              child: Text(
                _quotes[_quoteIndex],
                key: ValueKey<int>(_quoteIndex),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF4A4A4A),
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  height: 1.45,
                ),
              ),
            ),
          ),

          // ── thin progress bar at bottom ───────────────────────────────────
          Positioned(
            bottom: 52,
            left: 40,
            right: 40,
            child: AnimatedBuilder(
              animation: _progressCtrl,
              builder: (_, __) => _ProgressBar(value: _progressCtrl.value),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

class _AmbientGlow extends StatelessWidget {
  const _AmbientGlow({required this.size});
  final Size size;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // orange top-right
        Positioned(
          top: -60,
          right: -60,
          child: Container(
            width: 260,
            height: 260,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.primaryOrange.withOpacity(0.18),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        // teal bottom-left
        Positioned(
          bottom: -80,
          left: -60,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.secondaryTeal.withOpacity(0.10),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.value});
  final double value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: SizedBox(
            height: 2,
            child: LinearProgressIndicator(
              value: value,
              backgroundColor: Colors.white.withOpacity(0.08),
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.primaryOrange,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
