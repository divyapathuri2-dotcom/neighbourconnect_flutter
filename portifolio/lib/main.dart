import 'dart:async';

import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'screens/welcome_screen.dart';

void main() {
  runApp(const NeighbourConnectApp());
}

class NeighbourConnectApp extends StatelessWidget {
  const NeighbourConnectApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'NeighbourConnect',
      theme: AppTheme.light,
      home: const AppOpeningScreen(),
    );
  }
}

class AppOpeningScreen extends StatefulWidget {
  const AppOpeningScreen({super.key});

  @override
  State<AppOpeningScreen> createState() => _AppOpeningScreenState();
}

class _AppOpeningScreenState extends State<AppOpeningScreen>
    with TickerProviderStateMixin {
  late final AnimationController _controller;
  late final AnimationController _entranceController;
  late final Animation<Offset> _leftNeighbor;
  late final Animation<Offset> _rightNeighbor;
  late final Animation<double> _heartScale;
  late final Animation<double> _entranceScale;
  late final Animation<double> _entranceFade;
  Timer? _timer;
  bool _showWelcome = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1150),
    )..repeat(reverse: true);

    final embraceCurve = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    );
    _leftNeighbor = Tween<Offset>(
      begin: const Offset(-0.42, 0),
      end: const Offset(-0.10, 0),
    ).animate(embraceCurve);
    _rightNeighbor = Tween<Offset>(
      begin: const Offset(0.42, 0),
      end: const Offset(0.10, 0),
    ).animate(embraceCurve);
    _heartScale = Tween<double>(
      begin: 0.65,
      end: 1.1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    )..forward();
    _entranceScale = Tween<double>(begin: 0.78, end: 1).animate(
      CurvedAnimation(parent: _entranceController, curve: Curves.easeOutBack),
    );
    _entranceFade = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOut,
    );

    _timer = Timer(const Duration(milliseconds: 2400), () {
      if (!mounted) return;
      setState(() => _showWelcome = true);
      _controller.stop();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    _entranceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 650),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: _showWelcome
          ? const WelcomeScreen(key: ValueKey('welcome'))
          : _buildSplash(),
    );
  }

  Widget _buildSplash() {
    return Scaffold(
      key: const ValueKey('splash'),
      body: Container(
        decoration: const BoxDecoration(color: AppColors.background),
        child: SafeArea(
          child: Center(
            child: FadeTransition(
              opacity: _entranceFade,
              child: ScaleTransition(
                scale: _entranceScale,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 166,
                      height: 166,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.primary, AppColors.lavender],
                        ),
                        borderRadius: BorderRadius.circular(48),
                        border: Border.all(
                          color: AppColors.highlight.withValues(alpha: 0.22),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.45),
                            blurRadius: 42,
                            spreadRadius: 2,
                          ),
                          BoxShadow(
                            color: AppColors.accent.withValues(alpha: 0.18),
                            blurRadius: 60,
                            offset: const Offset(20, 16),
                          ),
                        ],
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          const Icon(
                            Icons.people_alt_rounded,
                            color: AppColors.card,
                            size: 88,
                          ),
                          Positioned(
                            right: 15,
                            bottom: 14,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: AppColors.accent,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.favorite_rounded,
                                color: AppColors.card,
                                size: 21,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: 190,
                      height: 94,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SlideTransition(
                            position: _leftNeighbor,
                            child: const CircleAvatar(
                              radius: 32,
                              backgroundColor: AppColors.card,
                              child: Icon(
                                Icons.person_rounded,
                                size: 38,
                                color: AppColors.accent,
                              ),
                            ),
                          ),
                          SlideTransition(
                            position: _rightNeighbor,
                            child: const CircleAvatar(
                              radius: 32,
                              backgroundColor: AppColors.card,
                              child: Icon(
                                Icons.person_rounded,
                                size: 38,
                                color: AppColors.secondary,
                              ),
                            ),
                          ),
                          ScaleTransition(
                            scale: _heartScale,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: AppColors.highlight,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.favorite_rounded,
                                color: AppColors.card,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'NeighbourConnect',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 29,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Bringing neighbours closer',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
