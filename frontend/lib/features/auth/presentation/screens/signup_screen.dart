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
import 'package:receipto/core/services/firebase_auth_service.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
      });

      try {
        final authService = ref.read(firebaseAuthServiceProvider);
        
        // 1. Create Firebase user
        final userCredential = await authService.signUpWithEmailAndPassword(
          _emailController.text.trim(),
          _passwordController.text,
        );

        final user = userCredential.user;
        if (user != null) {
          // 2. Immediately save displayName using updateDisplayName()
          await user.updateDisplayName(_nameController.text.trim());
          
          // 3. Reload current user to reflect the display name change locally
          await user.reload();
        }

        if (mounted) {
          // 5. Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Account created successfully! Welcome to Receipto.'),
              backgroundColor: AppColors.tertiary,
            ),
          );

          // 4. Navigate to Dashboard
          context.go('/dashboard');
        }
      } on Exception catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString().replaceAll('Exception: ', '')),
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

          // Main Signup Layout
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
                    const SizedBox(height: 24),
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
                    const SizedBox(height: 32),

                    // Signup Form Card
                    GlassCard(
                      borderRadius: AppRadius.lg,
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Create Account',
                              style: GoogleFonts.hankenGrotesk(
                                color: AppColors.onSurface,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Full Name Field
                            CustomTextField(
                              controller: _nameController,
                              hintText: 'Enter your full name',
                              prefixIcon: Icons.person_outline,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Full name is required';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

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
                            const SizedBox(height: 16),

                            // Confirm Password Field
                            CustomTextField(
                              controller: _confirmPasswordController,
                              hintText: 'Confirm your password',
                              prefixIcon: Icons.lock_outline,
                              isPassword: true,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Confirm your password';
                                }
                                if (value != _passwordController.text) {
                                  return 'Passwords do not match';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 24),

                            // Sign Up Button
                            GradientButton(
                              text: 'Sign Up',
                              isLoading: _isLoading,
                              onPressed: _handleSignup,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Signin Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Already have an account? ",
                          style: GoogleFonts.inter(
                            color: AppColors.onSurfaceVariant,
                            fontSize: 14,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            context.go('/login');
                          },
                          child: Text(
                            'Sign In',
                            style: GoogleFonts.inter(
                              color: AppColors.primary,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
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
