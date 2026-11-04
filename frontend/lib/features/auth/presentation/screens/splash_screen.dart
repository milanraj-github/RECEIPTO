import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _navigationTimer;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    
    // Smooth transition after 1.8 seconds (or immediately on screen tap)
    _navigationTimer = Timer(const Duration(milliseconds: 1800), () {
      _navigateToNext();
    });
  }

  void _navigateToNext() {
    if (_navigated || !mounted) return;
    _navigated = true;
    _navigationTimer?.cancel();

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      context.go('/dashboard');
    } else {
      context.go('/login');
    }
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _navigateToNext,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            // Centered splash screen Image
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
      ),
    );
  }
}
