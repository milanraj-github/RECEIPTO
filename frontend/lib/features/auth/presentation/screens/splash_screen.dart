import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _navigationTimer;

  @override
  void initState() {
    super.initState();
    
    // Redirect to login after 3.5 seconds
    _navigationTimer = Timer(const Duration(milliseconds: 3500), () {
      if (mounted) {
        context.go('/login');
      }
    });
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Centered splash screen Image 2
          Positioned.fill(
            child: Center(
              child: Image.asset(
                'assets/images/splash.png',
                fit: BoxFit.contain,
              ),
            ),
          ),
          
          // Brightness reduction overlay (12%)
          Positioned.fill(
            child: Container(
              color: Colors.black.withValues(alpha: 0.12),
            ),
          ),
        ],
      ),
    );
  }
}
