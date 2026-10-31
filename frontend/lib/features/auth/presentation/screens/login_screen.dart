import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:receipto/core/constants/constants.dart';
import 'package:receipto/app/config/theme.dart';
import 'package:receipto/core/widgets/brand_logo.dart';
import 'package:receipto/core/widgets/custom_textfield.dart';
import 'package:receipto/core/widgets/glass_card.dart';
import 'package:receipto/core/widgets/gradient_button.dart';
import 'package:receipto/core/widgets/nebula_background.dart';
import 'package:receipto/features/auth/presentation/widgets/google_sign_in_button.dart';
import 'package:receipto/core/services/firebase_auth_service.dart';
import 'package:receipto/core/utils/auth_error_handler.dart';


class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignIn() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
      });

      try {
        final authService = ref.read(firebaseAuthServiceProvider);
        await authService.signInWithEmailAndPassword(
          _emailController.text.trim(),
          _passwordController.text,
        );
        if (mounted) {
          context.go('/dashboard');
        }
      } catch (e) {
        if (mounted) {
          final errorMsg = AuthErrorHandler.getErrorMessage(e);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMsg),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authService = ref.read(firebaseAuthServiceProvider);
      final userCredential = await authService.signInWithGoogle();
      if (userCredential != null && mounted) {
        context.go('/dashboard');
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sign in aborted by user or failed.'),
            backgroundColor: Colors.orangeAccent,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final errorMsg = AuthErrorHandler.getErrorMessage(e);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleForgotPassword() async {
    final emailText = _emailController.text.trim();
    final textController = TextEditingController(text: emailText);
    
    final email = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.background,
          title: Text(
            'Reset Password',
            style: GoogleFonts.hankenGrotesk(
              color: AppColors.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Enter your email address to receive a password reset link.',
                style: AppFonts.geist(
                  color: AppColors.onSurfaceVariant,
                  fontSize: 14,
                  fontWeight: FontWeight.normal,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: textController,
                hintText: 'Enter your email address',
                prefixIcon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: GoogleFonts.inter(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                final input = textController.text.trim();
                if (input.isNotEmpty && RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(input)) {
                  Navigator.of(context).pop(input);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a valid email address'),
                      backgroundColor: Colors.orangeAccent,
                    ),
                  );
                }
              },
              child: Text(
                'Send Link',
                style: GoogleFonts.inter(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (email != null && email.isNotEmpty) {
      setState(() {
        _isLoading = true;
      });

      try {
        final authService = ref.read(firebaseAuthServiceProvider);
        await authService.sendPasswordResetEmail(email);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Password reset link sent! Check your inbox.'),
              backgroundColor: AppColors.tertiary,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          final errorMsg = AuthErrorHandler.getErrorMessage(e);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMsg),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Background Nebula shader animation
          const Positioned.fill(
            child: AnimatedNebulaBackground(opacity: 0.6),
          ),
          
          // Vignette overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    Colors.transparent,
                    AppColors.background.withValues(alpha: 0.4),
                    AppColors.background.withValues(alpha: 0.8),
                  ],
                  stops: const [0.0, 0.6, 1.0],
                ),
              ),
            ),
          ),

          // Main Login Layout
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
              child: Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Brand Identity
                    const BrandLogoIcon(size: 64),
                    const SizedBox(height: 12),
                    Text(
                      'Receipto',
                      style: GoogleFonts.hankenGrotesk(
                        color: AppColors.primary,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Secure Financial Intelligence Vault',
                      style: AppFonts.geist(
                        color: AppColors.onSurfaceVariant.withValues(alpha: 0.6),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.5,
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Login glass card Form
                    GlassCard(
                      borderRadius: AppRadius.lg,
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Access Account',
                              style: GoogleFonts.hankenGrotesk(
                                color: AppColors.onSurface,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Email Field
                            CustomTextField(
                              controller: _emailController,
                              hintText: 'Enter your email address',
                              prefixIcon: Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Email is required';
                                }
                                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                                  return 'Enter a valid email address';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // Password Field
                            CustomTextField(
                              controller: _passwordController,
                              hintText: 'Enter your password',
                              prefixIcon: Icons.lock_outline,
                              isPassword: true,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Password is required';
                                }
                                if (value.length < 6) {
                                  return 'Password must be at least 6 characters';
                                }
                                return null;
                              },
                            ),
                            
                            // Forgot Password Link
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: _handleForgotPassword,
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: const Size(0, 36),
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text(
                                  'Forgot Password?',
                                  style: GoogleFonts.inter(
                                    color: AppColors.primary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Sign In Button
                            GradientButton(
                              text: 'Sign In',
                              isLoading: _isLoading,
                              onPressed: _handleSignIn,
                            ),
                            const SizedBox(height: 24),

                            // OR separator
                            Row(
                              children: [
                                Expanded(child: Divider(color: AppColors.outline.withValues(alpha: 0.2))),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  child: Text(
                                    'OR',
                                    style: AppFonts.geist(
                                      color: AppColors.onSurfaceVariant.withValues(alpha: 0.5),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      height: 1.0,
                                    ),
                                  ),
                                ),
                                Expanded(child: Divider(color: AppColors.outline.withValues(alpha: 0.2))),
                              ],
                            ),
                            const SizedBox(height: 24),

                            // Google Login Button (Custom Glass button)
                            GoogleSignInButton(
                              onPressed: _handleGoogleSignIn,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Signup Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Don't have an account? ",
                          style: GoogleFonts.inter(
                            color: AppColors.onSurfaceVariant,
                            fontSize: 14,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            context.go('/signup');
                          },
                          child: Text(
                            'Sign Up',
                            style: GoogleFonts.inter(
                              color: AppColors.primary,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
