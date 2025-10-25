import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/router/app_router.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/three_circles_logo.dart';
import 'package:flutter/services.dart';
import '../../../shared/widgets/primary_button.dart';
import '../application/auth_controller.dart';
import '../../../shared/providers/shared_providers.dart';

class LoginView extends ConsumerStatefulWidget {
  const LoginView({super.key});

  @override
  ConsumerState<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends ConsumerState<LoginView> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Demo account autofill removed.

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final auth = ref.read(authControllerProvider.notifier);
    try {
      await auth.login(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
    } catch (_) {
      // Errors are surfaced via state; nothing else to do.
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.status == AuthStatus.loading;

    return Scaffold(
      backgroundColor: const Color(0xFF2563EB), // solid modern blue
      body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                // Exit button (Android) in the top-right of the auth panel
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    tooltip: 'Exit',
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () {
                      SystemNavigator.pop();
                    },
                  ),
                ),
                const ThreeCirclesLogo(size: 72, color: Colors.white, strokeWidth: 5, overlap: 16),
                const SizedBox(height: 16),
                Text(
                  'Wellness Circle',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Welcome back — let’s continue your journey',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withOpacity(0.85),
                  ),
                ),
                const SizedBox(height: 24),
                Theme(
                  data: theme.copyWith(
                    inputDecorationTheme: theme.inputDecorationTheme.copyWith(
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.12),
                      labelStyle: const TextStyle(color: Colors.white70),
                      hintStyle: const TextStyle(color: Colors.white70),
                      prefixIconColor: Colors.white70,
                      suffixIconColor: Colors.white70,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Colors.white54),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Colors.white, width: 1.5),
                      ),
                    ),
                    textTheme: theme.textTheme.apply(
                      bodyColor: Colors.white,
                      displayColor: Colors.white,
                    ),
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Sign in',
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _emailController,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Email is required';
                            }
                            if (!value.contains('@')) {
                              return 'Please enter a valid email address';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Password is required';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 8),
                        if (authState.errorMessage != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              authState.errorMessage!,
                              style: const TextStyle(
                                color: AppColors.danger,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        const SizedBox(height: 16),
                        PrimaryButton(
                          label: 'Log In',
                          isLoading: isLoading,
                          onPressed: isLoading ? null : _submit,
                          backgroundColor: const Color(0xFF16A34A), // solid green
                        ),
                        const SizedBox(height: 10),
                        FutureBuilder<bool>(
                          future: ref.read(biometricServiceProvider).isAvailable(),
                          builder: (context, snapshot) {
                            final available = snapshot.data ?? false;
                            if (!available) return const SizedBox.shrink();
                            return OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: const BorderSide(color: Colors.white70),
                              ),
                              icon: const Icon(Icons.fingerprint),
                              onPressed: isLoading
                                  ? null
                                  : () async {
                                      final bio = ref.read(biometricServiceProvider);
                                      final ok = await bio.authenticate(reason: 'Login with biometrics');
                                      if (!ok) {
                                        if (!mounted) return;
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Biometric authentication was canceled or unavailable.')),
                                        );
                                        return;
                                      }
                                      final unlocked = await ref.read(authControllerProvider.notifier).unlockWithBiometrics();
                                      if (!unlocked && context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('No saved session found. Please log in once.')),
                                        );
                                      }
                                    },
                              label: const Text('Login with biometrics'),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => context.go(AppRoute.register.path),
                  child: const Text(
                    'Need an account? Create one',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
