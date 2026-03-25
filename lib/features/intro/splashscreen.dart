import 'dart:math' as math;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/widget/Main_bottom_nav.dart';
import '../auth/screens/LoginScreen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // ── Design tokens ──────────────────────────────────────────────
  static const _bg        = Color(0xFF07070D);
  static const _gold      = Color(0xFFD4A843);
  static const _goldDeep  = Color(0xFF9A721C);
  static const _goldLight = Color(0xFFF5D07A);
  static const _white     = Color(0xFFF2F0E8);
  static const _dim       = Color(0xFF7A7A8C);

  // ── Animation controllers ──────────────────────────────────────
  late final AnimationController _orbCtrl;
  late final AnimationController _ringCtrl;
  late final AnimationController _entryCtrl;
  late final AnimationController _shimmerCtrl;
  late final AnimationController _exitCtrl;

  // Entry animations
  late final Animation<double> _logoScale;
  late final Animation<double> _logoOpacity;
  late final Animation<Offset> _taglineSlide;
  late final Animation<double> _taglineOpacity;
  late final Animation<double> _lineWidth;
  late final Animation<double> _subtitleOpacity;
  late final Animation<double> _dotsOpacity;

  // Exit
  late final Animation<double> _exitOpacity;

  @override
  void initState() {
    super.initState();

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    _setupControllers();
    _setupAnimations();

    // ✅ Chờ frame đầu tiên render xong rồi mới bắt đầu
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _runSplash();
    });
  }

  // ── Setup controllers ──────────────────────────────────────────
  void _setupControllers() {
    _orbCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);

    _ringCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 8000),
    )..repeat();

    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    _exitCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
  }

  // ── Setup animations ───────────────────────────────────────────
  void _setupAnimations() {
    _logoScale = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryCtrl,
        curve: const Interval(0.0, 0.55, curve: Curves.elasticOut),
      ),
    );
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryCtrl,
        curve: const Interval(0.0, 0.35, curve: Curves.easeOut),
      ),
    );
    _taglineSlide = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entryCtrl,
      curve: const Interval(0.35, 0.7, curve: Curves.easeOutCubic),
    ));
    _taglineOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryCtrl,
        curve: const Interval(0.35, 0.65, curve: Curves.easeOut),
      ),
    );
    _lineWidth = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryCtrl,
        curve: const Interval(0.5, 0.75, curve: Curves.easeOut),
      ),
    );
    _subtitleOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryCtrl,
        curve: const Interval(0.65, 0.85, curve: Curves.easeOut),
      ),
    );
    _dotsOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryCtrl,
        curve: const Interval(0.8, 1.0, curve: Curves.easeOut),
      ),
    );
    _exitOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _exitCtrl, curve: Curves.easeIn),
    );
  }

  // ── Hàm duy nhất điều khiển toàn bộ flow ──────────────────────
  Future<void> _runSplash() async {
    // Bước 1: Delay 600ms cho app khởi động xong hẳn
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;

    // Bước 2: Chạy animation entry
    await _entryCtrl.forward();
    if (!mounted) return;

    // Bước 3: Check login ngay sau animation (đồng bộ, không tốn thêm thời gian)
    final user = FirebaseAuth.instance.currentUser;

    // Bước 4: Dừng 800ms cho user nhìn splash
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;

    // Bước 5: Fade out
    await _exitCtrl.forward();
    if (!mounted) return;

    // Bước 6: Navigate 1 lần duy nhất
    Navigator.pushReplacement(
        context,
        PageRouteBuilder(
        pageBuilder: (_, __, ___) => user == null
        ? const LoginScreen()
        : const MainNavigationScreen(),
    transitionDuration: Duration.zero,      // ← không transition
    reverseTransitionDuration: Duration.zero,
    )
    );
  }

  @override
  void dispose() {
    _orbCtrl.dispose();
    _ringCtrl.dispose();
    _entryCtrl.dispose();
    _shimmerCtrl.dispose();
    _exitCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _exitOpacity,
      builder: (_, child) => Opacity(
        opacity: _exitOpacity.value,
        child: child,
      ),
      child: Scaffold(
        backgroundColor: _bg,
        body: Stack(
          fit: StackFit.expand,
          children: [
            _buildOrbs(),
            _buildRings(),
            _buildParticles(),
            _buildCenter(),
            _buildBottom(),
          ],
        ),
      ),
    );
  }

  // ── Background orbs ────────────────────────────────────────────
  Widget _buildOrbs() {
    return AnimatedBuilder(
      animation: _orbCtrl,
      builder: (_, __) {
        final t = _orbCtrl.value;
        return Stack(
          children: [
            Positioned(
              top: -120.h + t * 20.h,
              right: -80.w,
              child: Container(
                width: 320.w,
                height: 320.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [
                    _gold.withOpacity(0.22 + t * 0.06),
                    _gold.withOpacity(0.0),
                  ]),
                ),
              ),
            ),
            Positioned(
              top: 250.h - t * 15.h,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  width: 280.w,
                  height: 280.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [
                      _gold.withOpacity(0.10 + t * 0.04),
                      Colors.transparent,
                    ]),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -60.h,
              left: -60.w,
              child: Container(
                width: 240.w,
                height: 240.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [
                    const Color(0xFF2A3F7F).withOpacity(0.25 - t * 0.05),
                    Colors.transparent,
                  ]),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ── Rotating arc rings ──────────────────────────────────────────
  Widget _buildRings() {
    return AnimatedBuilder(
      animation: _ringCtrl,
      builder: (_, __) {
        return Center(
          child: SizedBox(
            width: 260.w,
            height: 260.w,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Transform.rotate(
                  angle: _ringCtrl.value * 2 * math.pi,
                  child: CustomPaint(
                    size: Size(260.w, 260.w),
                    painter: _ArcPainter(
                      color: _gold.withOpacity(0.18),
                      strokeWidth: 1.0,
                      sweepRatio: 0.65,
                    ),
                  ),
                ),
                Transform.rotate(
                  angle: -_ringCtrl.value * 2 * math.pi * 1.6,
                  child: CustomPaint(
                    size: Size(200.w, 200.w),
                    painter: _ArcPainter(
                      color: _gold.withOpacity(0.28),
                      strokeWidth: 1.5,
                      sweepRatio: 0.4,
                    ),
                  ),
                ),
                Transform.rotate(
                  angle: _ringCtrl.value * 2 * math.pi * 2.5,
                  child: CustomPaint(
                    size: Size(148.w, 148.w),
                    painter: _ArcPainter(
                      color: _goldLight.withOpacity(0.35),
                      strokeWidth: 1.0,
                      sweepRatio: 0.25,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Floating particles ──────────────────────────────────────────
  Widget _buildParticles() {
    return AnimatedBuilder(
      animation: _orbCtrl,
      builder: (_, __) {
        final t = _orbCtrl.value;
        return Stack(
          children: _particleData.map((p) {
            final dy = math.sin((t + p.phase) * math.pi * 2) * p.amplitude;
            return Positioned(
              left: p.x.w,
              top: p.y.h + dy,
              child: Opacity(
                opacity: p.opacity * (0.5 + t * 0.5),
                child: Container(
                  width: p.size.w,
                  height: p.size.w,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: _gold,
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  // ── Center logo + name ──────────────────────────────────────────
  Widget _buildCenter() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Logo mark
          AnimatedBuilder(
            animation: Listenable.merge([_entryCtrl, _shimmerCtrl]),
            builder: (_, __) {
              return Opacity(
                opacity: _logoOpacity.value,
                child: Transform.scale(
                  scale: _logoScale.value,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 110.w,
                        height: 110.w,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(colors: [
                            _gold.withOpacity(0.3),
                            Colors.transparent,
                          ]),
                        ),
                      ),
                      Container(
                        width: 86.w,
                        height: 86.w,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF111118),
                          border: Border.all(
                            color: _gold.withOpacity(0.7),
                            width: 1.5.w,
                          ),
                        ),
                        child: Center(child: _buildLogoGlyph()),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          SizedBox(height: 28.h),

          // App name
          AnimatedBuilder(
            animation: _entryCtrl,
            builder: (_, __) {
              return Opacity(
                opacity: _taglineOpacity.value,
                child: SlideTransition(
                  position: _taglineSlide,
                  child: Column(
                    children: [
                      Text(
                        'DOCTOR',
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w300,
                          color: _white.withOpacity(0.6),
                          letterSpacing: 8,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [_goldDeep, _goldLight, _gold, _goldDeep],
                          stops: [0.0, 0.3, 0.6, 1.0],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ).createShader(bounds),
                        child: Text(
                          'ĐỒNG',
                          style: TextStyle(
                            fontSize: 46.sp,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 4,
                            height: 1.0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          SizedBox(height: 20.h),

          // Ornamental divider
          AnimatedBuilder(
            animation: _entryCtrl,
            builder: (_, __) {
              return Opacity(
                opacity: _lineWidth.value,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: (60 * _lineWidth.value).w,
                      height: 1.h,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [
                          Colors.transparent,
                          _gold.withOpacity(0.6),
                        ]),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10.w),
                      child: Container(
                        width: 5.w,
                        height: 5.w,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _gold.withOpacity(0.8),
                        ),
                      ),
                    ),
                    Container(
                      width: (60 * _lineWidth.value).w,
                      height: 1.h,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [
                          _gold.withOpacity(0.6),
                          Colors.transparent,
                        ]),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          SizedBox(height: 16.h),

          // Subtitle
          AnimatedBuilder(
            animation: _entryCtrl,
            builder: (_, __) {
              return Opacity(
                opacity: _subtitleOpacity.value,
                child: Text(
                  'Quản lý chi tiêu thông minh',
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: _dim,
                    fontWeight: FontWeight.w300,
                    letterSpacing: 1.5,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ── Logo glyph shimmer ──────────────────────────────────────────
  Widget _buildLogoGlyph() {
    return AnimatedBuilder(
      animation: _shimmerCtrl,
      builder: (_, __) {
        final shift = _shimmerCtrl.value * 2 - 0.5;
        return ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: const [_goldDeep, _goldLight, _gold],
            stops: [
              (shift - 0.3).clamp(0.0, 1.0),
              shift.clamp(0.0, 1.0),
              (shift + 0.3).clamp(0.0, 1.0),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(bounds),
          child: Text(
            '₫',
            style: TextStyle(
              fontSize: 38.sp,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              height: 1,
            ),
          ),
        );
      },
    );
  }

  // ── Bottom loading dots ─────────────────────────────────────────
  Widget _buildBottom() {
    return Positioned(
      bottom: 56.h,
      left: 0,
      right: 0,
      child: AnimatedBuilder(
        animation: _dotsOpacity,
        builder: (_, __) {
          return Opacity(
            opacity: _dotsOpacity.value,
            child: Column(
              children: [
                const _LoadingDots(),
                SizedBox(height: 16.h),
                Text(
                  'v1.0.0',
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: _dim.withOpacity(0.4),
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ── Animated loading dots ───────────────────────────────────────────
class _LoadingDots extends StatefulWidget {
  const _LoadingDots();

  @override
  State<_LoadingDots> createState() => _LoadingDotsState();
}

class _LoadingDotsState extends State<_LoadingDots>
    with TickerProviderStateMixin {
  static const _gold = Color(0xFFD4A843);

  late final List<AnimationController> _ctrls;
  late final List<Animation<double>> _anims;

  @override
  void initState() {
    super.initState();
    _ctrls = List.generate(3, (i) {
      final c = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 600),
      );
      Future.delayed(Duration(milliseconds: i * 160), () {
        if (mounted) c.repeat(reverse: true);
      });
      return c;
    });
    _anims = _ctrls
        .map((c) => Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: c, curve: Curves.easeInOut),
    ))
        .toList();
  }

  @override
  void dispose() {
    for (final c in _ctrls) c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (i) {
        return AnimatedBuilder(
          animation: _anims[i],
          builder: (_, __) => Container(
            margin: EdgeInsets.symmetric(horizontal: 4.w),
            width: 5.w,
            height: 5.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _gold.withOpacity(_anims[i].value),
            ),
          ),
        );
      }),
    );
  }
}

// ── Arc ring painter ────────────────────────────────────────────────
class _ArcPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double sweepRatio;

  const _ArcPainter({
    required this.color,
    required this.strokeWidth,
    required this.sweepRatio,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(
        center: Offset(size.width / 2, size.height / 2),
        radius: size.width / 2,
      ),
      0,
      sweepRatio * 2 * math.pi,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(_ArcPainter old) => false;
}

// ── Particle data ───────────────────────────────────────────────────
class _Particle {
  final double x, y, size, opacity, phase, amplitude;
  const _Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.opacity,
    required this.phase,
    required this.amplitude,
  });
}

const _particleData = [
  _Particle(x: 40,  y: 120, size: 2.5, opacity: 0.5,  phase: 0.0, amplitude: 8),
  _Particle(x: 80,  y: 300, size: 1.5, opacity: 0.3,  phase: 0.2, amplitude: 12),
  _Particle(x: 300, y: 80,  size: 2.0, opacity: 0.4,  phase: 0.4, amplitude: 10),
  _Particle(x: 330, y: 220, size: 1.5, opacity: 0.3,  phase: 0.6, amplitude: 6),
  _Particle(x: 50,  y: 500, size: 2.0, opacity: 0.35, phase: 0.1, amplitude: 14),
  _Particle(x: 310, y: 480, size: 1.5, opacity: 0.25, phase: 0.7, amplitude: 9),
  _Particle(x: 170, y: 60,  size: 2.5, opacity: 0.4,  phase: 0.3, amplitude: 7),
  _Particle(x: 200, y: 620, size: 1.5, opacity: 0.3,  phase: 0.8, amplitude: 11),
  _Particle(x: 20,  y: 400, size: 1.5, opacity: 0.2,  phase: 0.5, amplitude: 10),
  _Particle(x: 340, y: 360, size: 2.0, opacity: 0.3,  phase: 0.9, amplitude: 8),
];