import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../models/defect_model.dart';
import '../../models/maintenance_department.dart';
import '../../services/defect_service.dart';
import '../../widgets/status_pill.dart';

class ManagementScreen extends ConsumerWidget {
  const ManagementScreen({super.key});

  static bool _isActiveStatus(DefectStatus status) =>
      status == DefectStatus.newReport ||
      status == DefectStatus.armaturaReview ||
      status == DefectStatus.inProgress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final defectsState = ref.watch(defectProvider);
    final defects = defectsState.value ?? const <DefectModel>[];
    final t = AppLocalizations.of(context);

    if (defectsState.isLoading && defects.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text(t.managementTitle),
          leading: IconButton(
            tooltip: t.actionBack,
            icon: const Icon(Icons.arrow_back_rounded, size: 20),
            onPressed: () => context.pop(),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (defectsState.hasError && defects.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text(t.managementTitle),
          leading: IconButton(
            tooltip: t.actionBack,
            icon: const Icon(Icons.arrow_back_rounded, size: 20),
            onPressed: () => context.pop(),
          ),
        ),
        body: Center(child: Text(defectsState.error.toString())),
      );
    }
    final statusCounts = {
      for (final s in DefectStatus.values)
        s: defects.where((d) => d.status == s).length,
    };
    final active = defects.where((d) => _isActiveStatus(d.status)).toList();
    final Map<String, int> busTotal = {};
    final Map<String, int> busActive = {};
    for (final d in defects) {
      busTotal[d.busNumber] = (busTotal[d.busNumber] ?? 0) + 1;
      if (_isActiveStatus(d.status)) {
        busActive[d.busNumber] = (busActive[d.busNumber] ?? 0) + 1;
      }
    }
    final sortedBuses = busTotal.keys.toList()
      ..sort((a, b) => (busActive[b] ?? 0).compareTo(busActive[a] ?? 0));
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
        title: Text(t.managementTitle),
        leading: IconButton(
          tooltip: t.actionBack,
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
                _SectionLabel(text: t.mgmtStatusOverview),
                const SizedBox(height: 10),
                _StatusGrid(statusCounts: statusCounts, total: defects.length),
                const SizedBox(height: 24),
                Row(
                  children: [
                    _SectionLabel(text: t.mgmtFleet),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.accentSurface,
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: Text(
                        t.mgmtBuses(sortedBuses.length),
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
                _SectionLabel(text: t.mgmtDepartments),
                const SizedBox(height: 10),
                _Card(
                  child: Column(
                    children: [
                      for (
                        int i = 0;
                        i < MaintenanceDepartment.values.length;
                        i++
                      ) ...[
                        if (i > 0)
                          const Divider(height: 1, color: AppColors.border),
                        _DeptRow(
                          dept: MaintenanceDepartment.values[i],
                          active:
                              deptActive[MaintenanceDepartment.values[i]] ?? 0,
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

class _StatusGrid extends StatelessWidget {
  const _StatusGrid({required this.statusCounts, required this.total});

  final Map<DefectStatus, int> statusCounts;
  final int total;

  String _labelFor(DefectStatus status, AppLocalizations t) {
    switch (status) {
      case DefectStatus.newReport:
        return t.statusNew;
      case DefectStatus.armaturaReview:
        return t.statusArmaturaReview;
      case DefectStatus.inProgress:
        return t.statusInProgress;
      case DefectStatus.resolved:
        return t.statusResolved;
      case DefectStatus.returnedToService:
        return t.statusReturnedToService;
      case DefectStatus.rejected:
        return t.statusRejected;
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final items = DefectStatus.values
        .map(
          (status) => (
            status,
            _labelFor(status, t),
            statusCounts[status] ?? 0,
          ),
        )
        .toList();

    return Column(
      children: [
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
                  Text(
                    t.mgmtTotalDefects,
                    style: const TextStyle(
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
        for (var i = 0; i < items.length; i += 2) ...[
          if (i > 0) const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  status: items[i].$1,
                  label: items[i].$2,
                  count: items[i].$3,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: i + 1 < items.length
                    ? _StatCard(
                        status: items[i + 1].$1,
                        label: items[i + 1].$2,
                        count: items[i + 1].$3,
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ],
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
    final t = AppLocalizations.of(context);
    final hasActive = active > 0;
    final statusColor = hasActive
        ? AppColors.statusNew
        : AppColors.statusResolved;

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
                  t.busNumbered(busNumber),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  t.mgmtBusTotal(total),
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(2),
              border: Border.all(color: statusColor.withValues(alpha: 0.35)),
            ),
            child: Text(
              hasActive ? t.mgmtBusActive(active) : t.mgmtBusOk,
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
      case MaintenanceDepartment.unassigned:
        return Icons.pending_outlined;
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
    final t = AppLocalizations.of(context);
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
                  dept.label(t),
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
            active > 0 ? t.mgmtDeptActive(active) : t.mgmtDeptNone,
            style: TextStyle(
              fontSize: 10,
              color: active > 0 ? AppColors.textSecondary : AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

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
