import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../models/user_role.dart';
import '../../services/user_service.dart';
import '../../widgets/widgets.dart';

String _errorText(Object error, String fallback) {
  if (error is DioException) {
    final data = error.response?.data;
    if (data is Map && data['detail'] is String) {
      return data['detail'] as String;
    }
  }
  return fallback;
}

class StaffScreen extends ConsumerWidget {
  const StaffScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final staffState = ref.watch(staffProvider);
    final t = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(t.staffTitle),
        leading: IconButton(
          tooltip: t.actionBack,
          icon: const Icon(Icons.arrow_back_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            tooltip: t.actionRefresh,
            icon: const Icon(Icons.refresh_rounded, size: 20),
            onPressed: () => ref.invalidate(staffProvider),
          ),
          const SizedBox(width: 4),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
        onPressed: () => _openAddSheet(context, ref),
        icon: const Icon(Icons.person_add_alt_1_rounded, size: 20),
        label: Text(t.staffNewUser),
      ),
      body: staffState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              _errorText(error, t.staffGenericError),
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.statusNew),
            ),
          ),
        ),
        data: (staff) => staff.isEmpty
            ? Center(child: Text(t.staffEmpty))
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
                itemCount: staff.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) => _StaffTile(user: staff[i]),
              ),
      ),
    );
  }

  Future<void> _openAddSheet(BuildContext context, WidgetRef ref) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
      ),
      builder: (_) => const _AddUserSheet(),
    );
  }
}

class _StaffTile extends ConsumerWidget {
  const _StaffTile({required this.user});

  final StaffUser user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context);
    final isDispatcher = user.role.isDispatcher;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: isDispatcher
                  ? AppColors.accentSurface
                  : AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(2),
            ),
            child: Icon(
              isDispatcher
                  ? Icons.headset_mic_outlined
                  : Icons.directions_bus_outlined,
              size: 20,
              color: isDispatcher ? AppColors.accent : AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        user.fullName,
                        style: theme.textTheme.titleMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _RoleTag(role: user.role),
                    if (!user.isActive) ...[
                      const SizedBox(width: 6),
                      _InactiveTag(),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  user.email,
                  style: theme.textTheme.bodySmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            tooltip: t.staffOptions,
            icon: const Icon(
              Icons.more_vert_rounded,
              size: 20,
              color: AppColors.textSecondary,
            ),
            onSelected: (value) => _onAction(context, ref, value),
            itemBuilder: (_) => [
              PopupMenuItem(
                value: user.isActive ? 'deactivate' : 'activate',
                child: Text(
                  user.isActive ? t.staffDeactivate : t.staffActivate,
                ),
              ),
              PopupMenuItem(value: 'delete', child: Text(t.staffDelete)),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _onAction(
    BuildContext context,
    WidgetRef ref,
    String action,
  ) async {
    final repo = ref.read(userRepositoryProvider);
    final messenger = ScaffoldMessenger.of(context);
    final t = AppLocalizations.of(context);
    try {
      switch (action) {
        case 'activate':
          await repo.setActive(user.id, isActive: true);
        case 'deactivate':
          await repo.setActive(user.id, isActive: false);
        case 'delete':
          await repo.deleteUser(user.id);
      }
      ref.invalidate(staffProvider);
    } on Object catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text(_errorText(error, t.staffGenericError))),
      );
    }
  }
}

class _RoleTag extends StatelessWidget {
  const _RoleTag({required this.role});
  final UserRole role;

  @override
  Widget build(BuildContext context) {
    final isDispatcher = role.isDispatcher;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: isDispatcher ? AppColors.accent : AppColors.textPrimary,
        borderRadius: BorderRadius.circular(2),
      ),
      child: Text(
        role.label(AppLocalizations.of(context)),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _InactiveTag extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        AppLocalizations.of(context).staffInactive,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: AppColors.textMuted,
          fontSize: 9,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _AddUserSheet extends ConsumerStatefulWidget {
  const _AddUserSheet();

  @override
  ConsumerState<_AddUserSheet> createState() => _AddUserSheetState();
}

class _AddUserSheetState extends ConsumerState<_AddUserSheet> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _busController = TextEditingController();
  final _routeController = TextEditingController();

  UserRole _role = UserRole.driver;
  bool _isSaving = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _nameController.dispose();
    _passwordController.dispose();
    _busController.dispose();
    _routeController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _error = null);
    if (!_formKey.currentState!.validate()) return;

    final t = AppLocalizations.of(context);
    setState(() => _isSaving = true);
    try {
      await ref
          .read(userRepositoryProvider)
          .createUser(
            email: _emailController.text,
            password: _passwordController.text,
            fullName: _nameController.text,
            role: _role,
            assignedBus: _role.isDriver ? _busController.text : null,
            assignedRoute: _role.isDriver ? _routeController.text : null,
          );
      ref.invalidate(staffProvider);
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(t.staffCreated)));
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _error = _errorText(error, t.staffGenericError);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final t = AppLocalizations.of(context);

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              SectionHeader(title: t.staffCreateTitle),
              const SizedBox(height: 8),
              _RoleToggle(
                role: _role,
                onChanged: (r) => setState(() => _role = r),
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: t.fieldFullName,
                hint: t.staffNameHint,
                controller: _nameController,
                prefixIcon: Icons.badge_outlined,
                enabled: !_isSaving,
                textInputAction: TextInputAction.next,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? t.validationNameRequired
                    : null,
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: t.fieldEmail,
                hint: t.staffEmailHint,
                controller: _emailController,
                prefixIcon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                enabled: !_isSaving,
                textInputAction: TextInputAction.next,
                validator: (v) {
                  final email = v?.trim() ?? '';
                  if (email.isEmpty) return t.validationEmailRequired;
                  if (!email.contains('@') || !email.contains('.')) {
                    return t.validationEmailInvalid;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: t.fieldPassword,
                hint: t.staffPasswordHint,
                controller: _passwordController,
                prefixIcon: Icons.lock_outline,
                obscureText: true,
                enabled: !_isSaving,
                validator: (v) {
                  if (v == null || v.isEmpty) {
                    return t.validationPasswordRequired;
                  }
                  if (v.length < 8) return t.validationPasswordMin8;
                  return null;
                },
              ),
              if (_role.isDriver) ...[
                const SizedBox(height: 16),
                AppTextField(
                  label: t.fieldBusOptional,
                  hint: t.reportBusHint,
                  controller: _busController,
                  prefixIcon: Icons.directions_bus_filled_rounded,
                  enabled: !_isSaving,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: t.fieldRouteOptional,
                  hint: t.routeHint,
                  controller: _routeController,
                  prefixIcon: Icons.alt_route_rounded,
                  enabled: !_isSaving,
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 14),
                Text(
                  _error!,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.statusNew),
                ),
              ],
              const SizedBox(height: 22),
              AppButton(
                label: t.staffCreateButton,
                icon: Icons.check_rounded,
                isLoading: _isSaving,
                onPressed: _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleToggle extends StatelessWidget {
  const _RoleToggle({required this.role, required this.onChanged});

  final UserRole role;
  final ValueChanged<UserRole> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: UserRole.values.map((option) {
        final selected = option == role;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: option != UserRole.values.last ? 8 : 0,
            ),
            child: GestureDetector(
              onTap: () => onChanged(option),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(vertical: 12),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.accent.withValues(alpha: 0.10)
                      : AppColors.surface,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: selected ? AppColors.accent : AppColors.border,
                    width: selected ? 1.5 : 1,
                  ),
                ),
                child: Text(
                  option.label(AppLocalizations.of(context)),
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: selected ? AppColors.accent : AppColors.textSecondary,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
