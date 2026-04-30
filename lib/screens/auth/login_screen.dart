import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/routes/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/widgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    setState(() => _isSubmitting = true);
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;

    context.go(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Icon(
                          Icons.directions_bus_filled,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'CITY TRANSIT',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: AppColors.accent,
                              letterSpacing: 2.4,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Defect Reporting',
                            style: theme.textTheme.titleMedium,
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 56),
                  Text(
                    'Sign in.',
                    style: theme.textTheme.displayMedium,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Authenticate with your driver credentials to '
                    'submit and track defect reports.',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 40),
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AppTextField(
                          label: 'Driver ID',
                          hint: 'e.g. D-4827',
                          controller: _usernameController,
                          prefixIcon: Icons.badge_outlined,
                          textInputAction: TextInputAction.next,
                          enabled: !_isSubmitting,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Driver ID is required';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        AppTextField(
                          label: 'Password',
                          hint: 'Enter password',
                          controller: _passwordController,
                          prefixIcon: Icons.lock_outline,
                          obscureText: true,
                          textInputAction: TextInputAction.done,
                          enabled: !_isSubmitting,
                          onSubmitted: (_) => _submit(),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Password is required';
                            }
                            if (value.length < 4) {
                              return 'Password is too short';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 32),
                        AppButton(
                          label: 'Authenticate',
                          icon: Icons.arrow_forward_rounded,
                          isLoading: _isSubmitting,
                          onPressed: _submit,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      const Expanded(
                        child: Divider(color: AppColors.border, height: 1),
                      ),
                      Padding(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          'NEED ACCESS?',
                          style: theme.textTheme.labelSmall,
                        ),
                      ),
                      const Expanded(
                        child: Divider(color: AppColors.border, height: 1),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: Text(
                      'Contact dispatch to provision a driver account.',
                      style: theme.textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
