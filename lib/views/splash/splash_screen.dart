import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/notification_service.dart';
import '../../core/services/update_service.dart';
import '../../core/theme/colors.dart';
import '../../widgets/app_scaffold.dart';
import '../update/update_screen.dart';

class AnimatedSplashScreen extends ConsumerStatefulWidget {
  const AnimatedSplashScreen({super.key});

  @override
  ConsumerState<AnimatedSplashScreen> createState() => _AnimatedSplashScreenState();
}

class _AnimatedSplashScreenState extends ConsumerState<AnimatedSplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _textFadeAnimation;

  AppReleaseInfo? _availableUpdate;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _scaleAnimation = Tween<double>(begin: 0.75, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.65, curve: Curves.easeOutBack),
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.45, curve: Curves.easeOut),
      ),
    );

    _glowAnimation = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 1.0, curve: Curves.easeInOut),
      ),
    );

    _textFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.45, 0.9, curve: Curves.easeOut),
      ),
    );

    _controller.forward();

    // Start background bootstrap (permissions + update check)
    _bootstrapApp();
  }

  Future<void> _bootstrapApp() async {
    final startTime = DateTime.now();

    // 1. Notification initialization & permissions
    try {
      await NotificationService.instance.initialize();
      await NotificationService.instance.requestPermissions();
    } catch (_) {}

    // 2. Check for app updates with safe fallback
    try {
      _availableUpdate = await UpdateService.instance
          .checkForUpdate()
          .timeout(const Duration(seconds: 4), onTimeout: () => null);
    } catch (_) {
      _availableUpdate = null;
    }

    // Ensure splash animation plays smoothly for at least 1600ms
    final elapsed = DateTime.now().difference(startTime).inMilliseconds;
    final remainingWait = 1600 - elapsed;
    if (remainingWait > 0) {
      await Future.delayed(Duration(milliseconds: remainingWait));
    }

    if (mounted) {
      _navigateToNextScreen();
    }
  }

  void _navigateToNextScreen() {
    if (!mounted) return;

    final targetScreen = _availableUpdate != null
        ? UpdateScreen(
            releaseInfo: _availableUpdate!,
            onProceedAnyway: () {
              Navigator.of(context).pushReplacement(
                PageRouteBuilder(
                  pageBuilder: (_, __, ___) => const AppScaffold(),
                  transitionsBuilder: (_, animation, __, child) =>
                      FadeTransition(opacity: animation, child: child),
                  transitionDuration: const Duration(milliseconds: 400),
                ),
              );
            },
          )
        : const AppScaffold();

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => targetScreen,
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? BotanicalColors.darkPrimary : BotanicalColors.lightPrimary;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF131715) : const Color(0xFFFAF9F6),
      body: Stack(
        children: [
          // Ambient background glow reflecting Workbench ribbon colors (Violet & Orange)
          Positioned(
            top: MediaQuery.of(context).size.height * 0.28,
            left: MediaQuery.of(context).size.width * 0.2,
            right: MediaQuery.of(context).size.width * 0.2,
            height: 220,
            child: AnimatedBuilder(
              animation: _glowAnimation,
              builder: (context, child) {
                return Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFF8B5CF6).withValues(alpha: isDark ? 0.25 : 0.15),
                        const Color(0xFFF97316).withValues(alpha: isDark ? 0.18 : 0.10),
                        Colors.transparent,
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          Center(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Animated App Logo
                    Transform.scale(
                      scale: _scaleAnimation.value,
                      child: Opacity(
                        opacity: _fadeAnimation.value,
                        child: Container(
                          width: 104,
                          height: 104,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF8B5CF6).withValues(alpha: isDark ? 0.4 : 0.2),
                                blurRadius: 28,
                                offset: const Offset(0, 10),
                              ),
                              BoxShadow(
                                color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(28),
                            child: Image.asset(
                              'assets/images/app_logo.png',
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: primaryColor,
                                child: const Center(
                                  child: Text(
                                    'W',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 48,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Title: Workbench
                    Opacity(
                      opacity: _textFadeAnimation.value,
                      child: Column(
                        children: [
                          Text(
                            'Workbench',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                              color: isDark ? BotanicalColors.darkTextPrimary : BotanicalColors.lightTextPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Calm, tactile productivity',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: isDark ? BotanicalColors.darkTextSecondary : BotanicalColors.lightTextSecondary,
                            ),
                          ),
                          const SizedBox(height: 28),
                          // Gentle loading indicator
                          SizedBox(
                            width: 120,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                minHeight: 3,
                                backgroundColor: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.06),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  primaryColor.withValues(alpha: 0.75),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          // Bottom Version Tag
          Positioned(
            bottom: 24,
            left: 0,
            right: 0,
            child: Center(
              child: Opacity(
                opacity: _textFadeAnimation.value * 0.7,
                child: Text(
                  'v1.1.0 · Ready for Deployment',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isDark ? BotanicalColors.darkTextSecondary : BotanicalColors.lightTextSecondary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
