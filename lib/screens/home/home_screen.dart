import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/routes/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../../models/user_model.dart';
import '../../models/user_role.dart';
import '../../services/auth_service.dart';
import '../../services/defect_service.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  static const List<String> _days = [
    'ПОНЕДЕЛНИК',
    'ВТОРНИК',
    'СРЕДА',
    'ЧЕТВРТОК',
    'ПЕТОК',
    'САБОТА',
    'НЕДЕЛА',
  ];

  static const List<String> _months = [
    'ЈАНУАРИ',
    'ФЕВРУАРИ',
    'МАРТ',
    'АПРИЛ',
    'МАЈ',
    'ЈУНИ',
    'ЈУЛИ',
    'АВГУСТ',
    'СЕПТЕМВРИ',
    'ОКТОМВРИ',
    'НОЕМВРИ',
    'ДЕКЕМВРИ',
  ];

  String _greeting(DateTime now) {
    final h = now.hour;
    if (h < 12) return 'ДОБРО УТРО';
    if (h < 18) return 'ДОБАР ДЕН';
    return 'ДОБРА ВЕЧЕР';
  }

  String _formatDate(DateTime now) =>
      '${_days[now.weekday - 1]}, ${now.day} ${_months[now.month - 1]}';

  Future<void> _seedDemoData(
    BuildContext context,
    WidgetRef ref,
    UserModel user,
  ) async {
    final repo = ref.read(defectRepositoryProvider);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final existing = await repo.countOwnDefects(user.id);
      if (existing > 0) {
        messenger.showSnackBar(
          SnackBar(content: Text('Веќе имате $existing пријавени дефекти.')),
        );
        return;
      }
      final count = await repo.seedSampleDefects(user);
      messenger.showSnackBar(
        SnackBar(content: Text('Внесени се $count демо дефекти.')),
      );
    } on Object {
      messenger.showSnackBar(
        const SnackBar(content: Text('Не можеше да се внесат демо податоци.')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.value;
    final theme = Theme.of(context);
    final now = DateTime.now();

    if (authState.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => context.go(AppRoutes.login),
      );
      return const Scaffold(body: SizedBox.shrink());
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('ГЛАВЕН ЕКРАН'),
        actions: [
          IconButton(
            tooltip: 'Внеси демо податоци',
            icon: const Icon(Icons.dataset_outlined, size: 20),
            onPressed: () => _seedDemoData(context, ref, user),
          ),
          IconButton(
            tooltip: 'Одјави се',
            icon: const Icon(Icons.logout_rounded, size: 20),
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) context.go(AppRoutes.login);
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          const Positioned(
            top: -10,
            right: -40,
            child: IgnorePointer(child: _CornerStripes()),
          ),
          SafeArea(
            top: false,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            color: AppColors.accent,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            _greeting(now),
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: AppColors.accent,
                              letterSpacing: 2.4,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      Text(
                        user.firstName,
                        style: theme.textTheme.displayLarge?.copyWith(
                          fontSize: 52,
                          height: 0.95,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        user.lastName,
                        style: theme.textTheme.displayMedium?.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 28,
                          height: 1.0,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 18),

                      Row(
                        children: [
                          _RoleBadge(role: user.role),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _formatDate(now),
                              style: theme.textTheme.labelSmall,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),

                      if (user.role.isDriver &&
                          (user.assignedBus != null ||
                              user.assignedRoute != null)) ...[
                        const SizedBox(height: 10),
                        _AssignmentInfo(user: user),
                      ],
                      const SizedBox(height: 28),
                      if (user.role.isDriver) ..._driverActions(context),
                      if (user.role.isDispatcher)
                        ..._dispatcherActions(context),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 14,
            child: Center(
              child: Text(
                'DISPATCH  ·  CITY TRANSIT',
                style: theme.textTheme.labelSmall,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _driverActions(BuildContext context) => [
    _ActionCard(
      title: 'Пријави дефект',
      subtitle: 'Поднеси нов извештај',
      icon: Icons.add_rounded,
      primary: true,
      onTap: () => context.push(AppRoutes.defectReport),
    ),
    const SizedBox(height: 12),
    _ActionCard(
      title: 'Мои дефекти',
      subtitle: 'Прегледај претходни извештаи',
      icon: Icons.list_alt_rounded,
      primary: false,
      onTap: () => context.push(AppRoutes.myDefects),
    ),
    const SizedBox(height: 12),
    _ActionCard(
      title: 'Мапа на дефекти',
      subtitle: 'Прегледај дефекти на мапа',
      icon: Icons.map_outlined,
      primary: false,
      onTap: () => context.push(AppRoutes.defectMap),
    ),
  ];

  List<Widget> _dispatcherActions(BuildContext context) => [
    _ActionCard(
      title: 'Сите дефекти',
      subtitle: 'Прегледај сите пријавени дефекти',
      icon: Icons.dashboard_rounded,
      primary: true,
      onTap: () => context.push(AppRoutes.myDefects),
    ),
    const SizedBox(height: 12),
    _ActionCard(
      title: 'Мапа на дефекти',
      subtitle: 'Прегледај дефекти на мапа',
      icon: Icons.map_outlined,
      primary: false,
      onTap: () => context.push(AppRoutes.defectMap),
    ),
    const SizedBox(height: 12),
    _ActionCard(
      title: 'Управување',
      subtitle: 'Статуси, возачи и линии',
      icon: Icons.tune_rounded,
      primary: false,
      onTap: () => context.push(AppRoutes.management),
    ),
  ];
}

class _RoleBadge extends StatelessWidget {
  const _RoleBadge({required this.role});
  final UserRole role;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDispatcher = role.isDispatcher;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isDispatcher ? AppColors.accent : AppColors.textPrimary,
        borderRadius: BorderRadius.circular(2),
      ),
      child: Text(
        role.label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: AppColors.background,
          fontWeight: FontWeight.w700,
          fontSize: 10,
          letterSpacing: 1.6,
        ),
      ),
    );
  }
}

class _AssignmentInfo extends StatelessWidget {
  const _AssignmentInfo({required this.user});
  final UserModel user;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final parts = <String>[
      if (user.assignedBus != null) user.assignedBus!,
      if (user.assignedRoute != null) user.assignedRoute!,
    ];
    return Row(
      children: [
        const Icon(
          Icons.directions_bus_outlined,
          size: 14,
          color: AppColors.textSecondary,
        ),
        const SizedBox(width: 6),
        Text(
          parts.join('  ·  '),
          style: theme.textTheme.labelSmall?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.primary,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool primary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = primary ? AppColors.accent : AppColors.surface;
    final fg = primary ? Colors.white : AppColors.textPrimary;
    final subtleColor = primary
        ? Colors.white.withValues(alpha: 0.82)
        : AppColors.textSecondary;
    final iconBg = primary
        ? Colors.white.withValues(alpha: 0.18)
        : AppColors.accentSurface;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Ink(
          decoration: BoxDecoration(
            color: bg,
            border: Border.all(
              color: AppColors.accent,
              width: primary ? 0 : 1.5,
            ),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Stack(
            children: [
              if (primary)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(4),
                        bottomLeft: Radius.circular(4),
                      ),
                    ),
                    child: Text(
                      'ОСНОВНО',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.6,
                      ),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 20, 16, 18),
                child: Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: iconBg,
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: Icon(icon, color: fg, size: 22),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title.toUpperCase(),
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: fg,
                              fontSize: 14,
                              letterSpacing: 1.4,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: subtleColor,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_forward_rounded, color: fg, size: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CornerStripes extends StatelessWidget {
  const _CornerStripes();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      height: 200,
      child: CustomPaint(painter: _StripesPainter()),
    );
  }
}

class _StripesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.accent.withValues(alpha: 0.08)
      ..strokeWidth = 14;

    for (double i = -size.width; i < size.width * 2; i += 28) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i + size.height, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
