import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../../../core/constants/app_theme.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../shared/widgets/offline_drop_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _isOffline = false;

  @override
  void initState() {
    super.initState();
    _checkNetworkAndNavigate();
  }

  Future<bool> _hasInternet() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
  }

  Future<void> _checkNetworkAndNavigate() async {
    debugPrint('🔍 SplashScreen: Checking network...');

    // Check basic interface connectivity first
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult.contains(ConnectivityResult.none)) {
      debugPrint('🔻 SplashScreen: Connectivity says NONE. Offline.');
      if (mounted) setState(() => _isOffline = true);
      return;
    }

    // Check actual internet access (DNS lookup)
    // This catches "Connected to Wifi but no Internet"
    debugPrint('🔍 SplashScreen: Pinging google.com...');
    final hasNet = await _hasInternet();
    if (!hasNet) {
      debugPrint('🔻 SplashScreen: DNS lookup failed. Offline.');
      if (mounted) setState(() => _isOffline = true);
      return;
    }

    debugPrint('✅ SplashScreen: Internet verified. Navigating...');
    _navigateAfterSplash();
  }

  Future<void> _retryConnection() async {
    if (mounted) setState(() => _isOffline = false); // Show loader again

    // Check network again
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult.contains(ConnectivityResult.none)) {
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) setState(() => _isOffline = true);
      return;
    }

    // Check DNS
    final hasNet = await _hasInternet();
    if (!hasNet) {
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) setState(() => _isOffline = true);
      return;
    }

    // Network is back, retry auth
    if (!mounted) return;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.retryAuth();

    _navigateAfterSplash();
  }

  Future<void> _navigateAfterSplash() async {
    // Minimum splash time for branding
    await Future.delayed(const Duration(milliseconds: 2000));

    if (!mounted) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Wait for auth check to complete (with timeout)
    int attempts = 0;
    while (authProvider.status == AuthStatus.initial ||
        authProvider.status == AuthStatus.loading) {
      await Future.delayed(const Duration(milliseconds: 200));
      attempts++;

      // Check network periodically during long loads (every 1 second)
      if (attempts % 5 == 0) {
        final connectivityResult = await Connectivity().checkConnectivity();
        if (connectivityResult.contains(ConnectivityResult.none)) {
          if (mounted) setState(() => _isOffline = true);
          return;
        }

        // Also check real internet if taking too long (> 2 seconds)
        if (attempts > 10) {
          final hasNet = await _hasInternet();
          if (!hasNet) {
            if (mounted) setState(() => _isOffline = true);
            return;
          }
        }
      }

      // Timeout after 10 seconds (increased for slow networks)
      if (attempts > 50 || !mounted) break;
    }

    if (!mounted) return;

    if (authProvider.isAuthenticated) {
      context.go('/home');
    } else {
      context.go('/onboarding');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isOffline) {
      return OfflineDropScreen(onRetry: _retryConnection);
    }

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(gradient: AppGradients.heroGradient),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo Icon
              Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.water_drop,
                      size: 60,
                      color: AppColors.primary,
                    ),
                  )
                  .animate()
                  .fadeIn(duration: 600.ms)
                  .scale(
                    begin: const Offset(0.5, 0.5),
                    end: const Offset(1, 1),
                  ),

              const SizedBox(height: 32),

              // App Name
              Text(
                    'BloodReq',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                  .animate(delay: 300.ms)
                  .fadeIn(duration: 600.ms)
                  .slideY(begin: 0.3, end: 0),

              const SizedBox(height: 8),

              // Tagline
              Text(
                'Save Lives. Be a Hero.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ).animate(delay: 500.ms).fadeIn(duration: 600.ms),

              const SizedBox(height: 48),

              // Loading indicator
              const SizedBox(
                width: 30,
                height: 30,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ).animate(delay: 800.ms).fadeIn(duration: 400.ms),
            ],
          ),
        ),
      ),
    );
  }
}
