import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:receipto/core/constants/constants.dart';
import 'package:receipto/core/services/app_lock_provider.dart';
import 'package:receipto/core/services/app_lock_service.dart';
import 'package:receipto/core/widgets/nebula_background.dart';

class AppLockScreen extends ConsumerStatefulWidget {
  const AppLockScreen({super.key});

  @override
  ConsumerState<AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends ConsumerState<AppLockScreen>
    with SingleTickerProviderStateMixin {
  String _enteredPin = '';
  String _errorMessage = '';
  int _failedAttempts = 0;
  int _cooldownSeconds = 0;
  Timer? _cooldownTimer;
  bool _isAuthenticatingBiometric = false;

  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 12)
        .chain(CurveTween(curve: Curves.elasticIn))
        .animate(_shakeController);

    // Auto-trigger biometric unlock on screen launch if enabled
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _triggerBiometricIfEnabled();
    });
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _shakeController.dispose();
    super.dispose();
  }

  Future<void> _triggerBiometricIfEnabled() async {
    final lockState = ref.read(appLockProvider);
    if (lockState.isBiometricEnabled && lockState.isBiometricAvailable) {
      await _authenticateBiometric();
    }
  }

  Future<void> _authenticateBiometric() async {
    if (_isAuthenticatingBiometric) return;
    setState(() => _isAuthenticatingBiometric = true);

    final lockService = ref.read(appLockServiceProvider);
    final success = await lockService.authenticateBiometricsOnly(
      reason: 'Scan fingerprint or face to unlock Receipto',
    );

    if (mounted) {
      setState(() => _isAuthenticatingBiometric = false);
      if (success) {
        ref.read(appLockProvider.notifier).unlock();
      }
    }
  }

  void _onKeyPress(String value) {
    if (_cooldownSeconds > 0) return;
    if (_enteredPin.length < 4) {
      setState(() {
        _enteredPin += value;
        _errorMessage = '';
      });
      if (_enteredPin.length == 4) {
        _verifyPin();
      }
    }
  }

  void _onDelete() {
    if (_enteredPin.isNotEmpty) {
      setState(() {
        _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
        _errorMessage = '';
      });
    }
  }

  Future<void> _verifyPin() async {
    final lockService = ref.read(appLockServiceProvider);
    final success = await lockService.verifyCustomPin(_enteredPin);

    if (success) {
      ref.read(appLockProvider.notifier).unlock();
    } else {
      _shakeController.forward(from: 0);
      _failedAttempts++;
      setState(() {
        _enteredPin = '';
        if (_failedAttempts >= 5) {
          _startCooldown();
        } else {
          _errorMessage = 'Incorrect PIN (${5 - _failedAttempts} attempts left)';
        }
      });
    }
  }

  void _startCooldown() {
    setState(() {
      _cooldownSeconds = 30;
      _errorMessage = 'Too many failed attempts. Wait 30s.';
    });

    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_cooldownSeconds <= 1) {
        timer.cancel();
        setState(() {
          _cooldownSeconds = 0;
          _failedAttempts = 0;
          _errorMessage = '';
        });
      } else {
        setState(() {
          _cooldownSeconds--;
          _errorMessage = 'Too many failed attempts. Wait ${_cooldownSeconds}s.';
        });
      }
    });
  }

  Future<void> _handleForgotPin() async {
    final lockState = ref.read(appLockProvider);
    if (!lockState.isBiometricEnabled || !lockState.isBiometricAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Fingerprint/Face unlock must be enabled to reset forgotten PIN.'),
        ),
      );
      return;
    }

    final lockService = ref.read(appLockServiceProvider);
    final success = await lockService.authenticateBiometricsOnly(
      reason: 'Authenticate using fingerprint or face to reset PIN',
    );

    if (success && mounted) {
      _showCreateNewPinDialog();
    }
  }

  void _showCreateNewPinDialog() {
    String newPin = '';
    String confirmPin = '';
    String dialogError = '';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.cardSurface,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.lg,
            side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
          ),
          title: Text(
            'Reset Custom PIN',
            style: GoogleFonts.hankenGrotesk(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Enter a new 4-digit PIN:',
                style: GoogleFonts.inter(color: AppColors.onSurfaceVariant, fontSize: 13),
              ),
              const SizedBox(height: 10),
              TextField(
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 4,
                onChanged: (val) => newPin = val,
                style: GoogleFonts.inter(color: Colors.white, fontSize: 18, letterSpacing: 8),
                decoration: const InputDecoration(counterText: '', hintText: 'New PIN'),
              ),
              const SizedBox(height: 10),
              Text(
                'Confirm new 4-digit PIN:',
                style: GoogleFonts.inter(color: AppColors.onSurfaceVariant, fontSize: 13),
              ),
              const SizedBox(height: 10),
              TextField(
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 4,
                onChanged: (val) => confirmPin = val,
                style: GoogleFonts.inter(color: Colors.white, fontSize: 18, letterSpacing: 8),
                decoration: const InputDecoration(counterText: '', hintText: 'Confirm PIN'),
              ),
              if (dialogError.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(dialogError, style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              onPressed: () async {
                if (newPin.length != 4) {
                  setDialogState(() => dialogError = 'PIN must be 4 digits.');
                  return;
                }
                if (newPin != confirmPin) {
                  setDialogState(() => dialogError = 'PINs do not match.');
                  return;
                }
                await ref.read(appLockProvider.notifier).setCustomPin(newPin);
                if (context.mounted) {
                  Navigator.of(context).pop();
                  ref.read(appLockProvider.notifier).unlock();
                }
              },
              child: const Text('Save PIN', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lockState = ref.watch(appLockProvider);
    final canShowBiometricButton = lockState.isBiometricEnabled && lockState.isBiometricAvailable;

    return PopScope(
      canPop: false, // Strict: Prevent physical back button bypass
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Stack(
          children: [
            const Positioned.fill(
              child: AnimatedNebulaBackground(opacity: 0.6),
            ),
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // App Logo & Security Badge
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: AppGradients.primaryBlueCyan,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.35),
                              blurRadius: 20,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.lock_rounded,
                          color: Colors.white,
                          size: 36,
                        ),
                      ),
                      const SizedBox(height: 20),

                      Text(
                        'Welcome Back',
                        style: GoogleFonts.hankenGrotesk(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Enter your App PIN to continue',
                        style: GoogleFonts.inter(
                          color: AppColors.onSurfaceVariant,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // 4 Circular PIN Indicators
                      AnimatedBuilder(
                        animation: _shakeAnimation,
                        builder: (context, child) {
                          return Transform.translate(
                            offset: Offset(
                              _shakeAnimation.value * ( (_shakeController.value * 10).floor() % 2 == 0 ? 1 : -1 ),
                              0,
                            ),
                            child: child,
                          );
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(4, (index) {
                            final isFilled = index < _enteredPin.length;
                            return Container(
                              margin: const EdgeInsets.symmetric(horizontal: 10),
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isFilled ? AppColors.primary : Colors.white.withValues(alpha: 0.15),
                                border: Border.all(
                                  color: isFilled ? AppColors.primary : Colors.white.withValues(alpha: 0.3),
                                  width: 1.5,
                                ),
                                boxShadow: isFilled
                                    ? [
                                        BoxShadow(
                                          color: AppColors.primary.withValues(alpha: 0.5),
                                          blurRadius: 8,
                                        )
                                      ]
                                    : null,
                              ),
                            );
                          }),
                        ),
                      ),
                      const SizedBox(height: 16),

                      if (_errorMessage.isNotEmpty)
                        Text(
                          _errorMessage,
                          style: GoogleFonts.inter(
                            color: Colors.redAccent,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      const SizedBox(height: 24),

                      // Glass Numeric Keypad
                      SizedBox(
                        width: 280,
                        child: Column(
                          children: [
                            for (var i = 0; i < 3; i++)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    for (var j = 1; j <= 3; j++)
                                      _buildKeypadButton('${i * 3 + j}'),
                                  ],
                                ),
                              ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                // Biometric unlock button (if enabled)
                                if (canShowBiometricButton)
                                  _buildKeypadIconButton(
                                    Icons.fingerprint_rounded,
                                    _authenticateBiometric,
                                  )
                                else
                                  const SizedBox(width: 64, height: 64),
                                _buildKeypadButton('0'),
                                _buildKeypadIconButton(
                                  Icons.backspace_outlined,
                                  _onDelete,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      TextButton(
                        onPressed: _handleForgotPin,
                        child: Text(
                          'Forgot PIN?',
                          style: GoogleFonts.inter(
                            color: AppColors.primary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKeypadButton(String label) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.surfaceVariant.withValues(alpha: 0.3),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () => _onKeyPress(label),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.hankenGrotesk(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildKeypadIconButton(IconData icon, VoidCallback onTap) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.surfaceVariant.withValues(alpha: 0.3),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Center(
            child: Icon(
              icon,
              color: AppColors.onSurface,
              size: 22,
            ),
          ),
        ),
      ),
    );
  }
}
