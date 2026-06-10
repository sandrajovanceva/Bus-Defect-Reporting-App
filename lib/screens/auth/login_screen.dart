import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/routes/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../../services/auth_service.dart';
import '../../widgets/widgets.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _userIdController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isSubmitting = false;
  String? _serverError;

  @override
  void dispose() {
    _userIdController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _serverError = null);
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    setState(() => _isSubmitting = true);

    final error = await ref.read(authProvider.notifier).login(
          _userIdController.text,
          _passwordController.text,
        );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (error != null) {
      setState(() => _serverError = error);
      return;
    }

    context.go(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
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
                  Text('Sign in.', style: theme.textTheme.displayMedium),
                  const SizedBox(height: 12),
                  Text(
                    'Автентицирај се со твоите credentials за да поднесуваш '
                    'и следиш извештаи за дефекти.',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 40),
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AppTextField(
                          label: 'Корисничко ID',
                          hint: 'Пр. D-4827 или DISP-001',
                          controller: _userIdController,
                          prefixIcon: Icons.badge_outlined,
                          textInputAction: TextInputAction.next,
                          enabled: !_isSubmitting,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'ID-то е задолжително';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        AppTextField(
                          label: 'Лозинка',
                          hint: 'Внеси лозинка',
                          controller: _passwordController,
                          prefixIcon: Icons.lock_outline,
                          obscureText: true,
                          textInputAction: TextInputAction.done,
                          enabled: !_isSubmitting,
                          onSubmitted: (_) => _submit(),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Лозинката е задолжителна';
                            }
                            if (value.length < 4) {
                              return 'Лозинката е прекратка';
                            }
                            return null;
                          },
                        ),
                        if (_serverError != null) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.statusNew.withValues(alpha: 0.10),
                              border: Border.all(
                                color: AppColors.statusNew.withValues(alpha: 0.4),
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.warning_amber_rounded,
                                  color: AppColors.statusNew,
                                  size: 18,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _serverError!,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: AppColors.statusNew,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 32),
                        AppButton(
                          label: 'Автентицирај',
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
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          'НЕМАШ ПРИСТАП?',
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
                      'Контактирај ја диспечерницата за да добиеш акаунт.',
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
