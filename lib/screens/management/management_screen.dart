import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../models/maintenance_department.dart';
import '../../services/defect_service.dart';
import '../../widgets/status_pill.dart';

class ManagementScreen extends ConsumerWidget {
  const ManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final defects = ref.watch(defectProvider);

    // ── Status counts ──────────────────────────────────────────────
    final statusCounts = {
      for (final s in DefectStatus.values)
        s: defects.where((d) => d.status == s).length,
    };

    // ── Active = New + In Progress ─────────────────────────────────
    final active = defects
        .where((d) =>
            d.status == DefectStatus.newReport ||
            d.status == DefectStatus.inProgress)
        .toList();

    // ── Fleet: busNumber → {total, active} ─────────────────────────
    final Map<String, int> busTotal = {};
    final Map<String, int> busActive = {};
    for (final d in defects) {
      busTotal[d.busNumber] = (busTotal[d.busNumber] ?? 0) + 1;
      if (d.status == DefectStatus.newReport ||
          d.status == DefectStatus.inProgress) {
        busActive[d.busNumber] = (busActive[d.busNumber] ?? 0) + 1;
      }
    }
    final sortedBuses = busTotal.keys.toList()
      ..sort((a, b) => (busActive[b] ?? 0).compareTo(busActive[a] ?? 0));

    // ── Department workload ────────────────────────────────────────
    final Map<MaintenanceDepartment, int> deptActive = {};
    final Map<MaintenanceDepartment, int> deptTotal = {};
    for (final d in defects) {
      deptTotal[d.department] = (deptTotal[d.department] ?? 0) + 1;
    }
    for (final d in active) {
      deptActive[d.department] = (deptActive[d.department] ?? 0) + 1;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('УПРАВУВАЊЕ'),
        leading: IconButton(
          tooltip: 'Назад',
          icon: const Icon(Icons.arrow_back_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              children: [
                // ── Overview ──────────────────────────────────────
                const _SectionLabel(text: 'СТАТУС ПРЕГЛЕД'),
                const SizedBox(height: 10),
                _StatusGrid(
                  statusCounts: statusCounts,
                  total: defects.length,
                ),
                const SizedBox(height: 24),

                // ── Fleet ─────────────────────────────────────────
                Row(
                  children: [
                    const _SectionLabel(text: 'ФЛОТА'),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.accentSurface,
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: Text(
                        '${sortedBuses.length} автобуси',
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.accent,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _Card(
                  child: Column(
                    children: [
                      for (int i = 0; i < sortedBuses.length; i++) ...[
                        if (i > 0)
                          const Divider(height: 1, color: AppColors.border),
                        _BusRow(
                          busNumber: sortedBuses[i],
                          total: busTotal[sortedBuses[i]]!,
                          active: busActive[sortedBuses[i]] ?? 0,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ── Departments ───────────────────────────────────
                const _SectionLabel(text: 'ОДДЕЛИ'),
                const SizedBox(height: 10),
                _Card(
                  child: Column(
                    children: [
                      for (int i = 0;
                          i < MaintenanceDepartment.values.length;
                          i++) ...[
                        if (i > 0)
                          const Divider(height: 1, color: AppColors.border),
                        _DeptRow(
                          dept: MaintenanceDepartment.values[i],
                          active: deptActive[MaintenanceDepartment.values[i]] ??
                              0,
                          total:
                              deptTotal[MaintenanceDepartment.values[i]] ?? 0,
                        ),
                      ],
                    ],
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

// ─────────────────────────────────────────────────────────────────
// Status grid
// ─────────────────────────────────────────────────────────────────

class _StatusGrid extends StatelessWidget {
  const _StatusGrid({
    required this.statusCounts,
    required this.total,
  });

  final Map<DefectStatus, int> statusCounts;
  final int total;

  @override
  Widget build(BuildContext context) {
    final items = [
      (DefectStatus.newReport, 'New', statusCounts[DefectStatus.newReport] ?? 0),
      (DefectStatus.inProgress, 'In Progress',
          statusCounts[DefectStatus.inProgress] ?? 0),
      (DefectStatus.resolved, 'Resolved',
          statusCounts[DefectStatus.resolved] ?? 0),
      (DefectStatus.rejected, 'Rejected',
          statusCounts[DefectStatus.rejected] ?? 0),
    ];

    return Column(
      children: [
        // Total pill at top
        _Card(
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$total',
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'вкупно дефекти',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              const Icon(
                Icons.bar_chart_rounded,
                size: 40,
                color: AppColors.border,
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        // 2-column grid
        Row(
          children: [
            Expanded(child: _StatCard(status: items[0].$1, label: items[0].$2, count: items[0].$3)),
            const SizedBox(width: 8),
            Expanded(child: _StatCard(status: items[1].$1, label: items[1].$2, count: items[1].$3)),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _StatCard(status: items[2].$1, label: items[2].$2, count: items[2].$3)),
            const SizedBox(width: 8),
            Expanded(child: _StatCard(status: items[3].$1, label: items[3].$2, count: items[3].$3)),
          ],
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.status,
    required this.label,
    required this.count,
  });

  final DefectStatus status;
  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    final color = status.color;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$count',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: color,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color.withValues(alpha: 0.85),
              fontWeight: FontWeight.w500,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Fleet row
// ─────────────────────────────────────────────────────────────────

class _BusRow extends StatelessWidget {
  const _BusRow({
    required this.busNumber,
    required this.total,
    required this.active,
  });

  final String busNumber;
  final int total;
  final int active;

  @override
  Widget build(BuildContext context) {
    final hasActive = active > 0;
    final statusColor =
        hasActive ? AppColors.statusNew : AppColors.statusResolved;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: AppColors.border),
            ),
            child: const Icon(
              Icons.directions_bus_rounded,
              size: 18,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Автобус #$busNumber',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$total дефект${total == 1 ? '' : 'и'} вкупно',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          // Active defect badge
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(2),
              border: Border.all(color: statusColor.withValues(alpha: 0.35)),
            ),
            child: Text(
              hasActive ? '$active активни' : 'Уредно',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: statusColor,
                letterSpacing: 0.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Department row
// ─────────────────────────────────────────────────────────────────

class _DeptRow extends StatelessWidget {
  const _DeptRow({
    required this.dept,
    required this.active,
    required this.total,
  });

  final MaintenanceDepartment dept;
  final int active;
  final int total;

  IconData get _icon {
    switch (dept) {
      case MaintenanceDepartment.electrical:
        return Icons.bolt_rounded;
      case MaintenanceDepartment.mechanical:
        return Icons.build_rounded;
      case MaintenanceDepartment.bodywork:
        return Icons.directions_bus_filled_rounded;
      case MaintenanceDepartment.general:
        return Icons.handyman_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final fraction = total == 0 ? 0.0 : active / total;
    final barColor = active > 0 ? AppColors.accent : AppColors.border;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_icon, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  dept.label,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Text(
                '$active / $total',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: fraction,
              minHeight: 4,
              backgroundColor: AppColors.border,
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            active > 0
                ? '$active активн${active == 1 ? 'и' : 'и'} дефект${active == 1 ? '' : 'и'}'
                : 'Нема активни дефекти',
            style: TextStyle(
              fontSize: 10,
              color: active > 0
                  ? AppColors.textSecondary
                  : AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Shared primitives
// ─────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: AppColors.textMuted,
            letterSpacing: 1.4,
          ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }
}
