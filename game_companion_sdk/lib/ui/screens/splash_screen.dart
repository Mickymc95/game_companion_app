import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/map_providers.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final AnimationController _progressController;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _floatAnimation;
  late final Animation<double> _glowAnimation;
  late final Animation<double> _progressAnimation;

  String _statusText = 'Loading Los Santos map...';
  bool _navigated = false;

  @override
  void initState() {
    super.initState();

    // Pulse & floating icon animation
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.92, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOutSine),
    );

    _floatAnimation = Tween<double>(begin: -6.0, end: 6.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOutSine),
    );

    _glowAnimation = Tween<double>(begin: 0.3, end: 0.85).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Fast, crisp loading progress (1.4 seconds total)
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _progressAnimation = CurvedAnimation(
      parent: _progressController,
      curve: Curves.fastOutSlowIn,
    );

    _progressController.addListener(() {
      final v = _progressController.value;
      if (v < 0.45 && _statusText != 'Loading Los Santos map...') {
        setState(() => _statusText = 'Loading Los Santos map...');
      } else if (v >= 0.45 && v < 0.85 && _statusText != 'Syncing stunt jumps & collectibles...') {
        setState(() => _statusText = 'Syncing stunt jumps & collectibles...');
      } else if (v >= 0.85 && _statusText != 'Ready to explore!') {
        setState(() => _statusText = 'Ready to explore!');
      }
    });

    _progressController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _proceedToApp();
      }
    });

    // Start loading and pre-warm map providers
    _progressController.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(mapPoiProvider);
    });
  }

  void _proceedToApp() {
    if (_navigated || !mounted) return;
    _navigated = true;
    context.go('/map');
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1117),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _proceedToApp, // Instant tap-to-skip for power users
        child: Stack(
          children: [
            // Ambient background gradient glow
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(0, -0.15),
                    radius: 0.85,
                    colors: [
                      Color(0xFF1E2838),
                      Color(0xFF141722),
                      Color(0xFF0A0C10),
                    ],
                  ),
                ),
              ),
            ),

            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Animated glowing aura & 3D floating icon
                    AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(0, _floatAnimation.value),
                          child: Transform.scale(
                            scale: _scaleAnimation.value,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // Glowing background aura
                                Container(
                                  width: 140,
                                  height: 140,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF00E5FF)
                                            .withOpacity(0.22 * _glowAnimation.value),
                                        blurRadius: 40,
                                        spreadRadius: 10,
                                      ),
                                      BoxShadow(
                                        color: const Color(0xFF7C4DFF)
                                            .withOpacity(0.28 * _glowAnimation.value),
                                        blurRadius: 50,
                                        spreadRadius: 6,
                                      ),
                                    ],
                                  ),
                                ),
                                // Icon container with smooth shadow and rounded corners
                                Container(
                                  width: 110,
                                  height: 110,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(26),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.55),
                                        blurRadius: 20,
                                        offset: const Offset(0, 10),
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(26),
                                    child: Image.asset(
                                      'assets/icons/app_icon.png',
                                      width: 110,
                                      height: 110,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 38),

                    // Modern high-tech brand title
                    Text(
                      'GAMES COMPANION',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 3.5,
                          ),
                    ),

                    const SizedBox(height: 8),

                    // Modern subtitle tag
                    Text(
                      'Interactive Map • Wikis • 100% Tracking',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: const Color(0xFF8E9BAE),
                            letterSpacing: 0.8,
                            fontWeight: FontWeight.w500,
                          ),
                    ),

                    const SizedBox(height: 48),

                    // Modern animated progress bar with glowing cyan gradient
                    SizedBox(
                      width: 210,
                      height: 5,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: AnimatedBuilder(
                          animation: _progressAnimation,
                          builder: (context, child) {
                            return Stack(
                              children: [
                                Container(
                                  color: Colors.white.withOpacity(0.08),
                                ),
                                FractionallySizedBox(
                                  widthFactor: _progressAnimation.value.clamp(0.0, 1.0),
                                  child: Container(
                                    decoration: const BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Color(0xFF00E5FF),
                                          Color(0xFF7C4DFF),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Dynamic loading micro-status text
                    Text(
                      _statusText,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: const Color(0xFF5E6D82),
                            fontSize: 12,
                            letterSpacing: 0.4,
                          ),
                    ),
                  ],
                ),
              ),
            ),

            // Tap to skip hint at bottom
            Positioned(
              left: 0,
              right: 0,
              bottom: 24,
              child: Center(
                child: Text(
                  'Tap anywhere to skip',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.22),
                    fontSize: 11,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

