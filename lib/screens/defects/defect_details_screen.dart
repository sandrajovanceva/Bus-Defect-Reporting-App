import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../models/defect_history_entry.dart';
import '../../models/defect_model.dart';
import '../../models/defect_type.dart';
import '../../models/user_role.dart';
import '../../services/auth_service.dart';
import '../../services/defect_service.dart';
import '../../widgets/status_pill.dart';

class DefectDetailsScreen extends ConsumerWidget {
  const DefectDetailsScreen({super.key, required this.defectId});

  final String defectId;

  String _formatDate(DateTime dt) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(dt.day)}.${two(dt.month)}.${dt.year}  ${two(dt.hour)}:${two(dt.minute)}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider);
    final defects = ref.watch(defectProvider);
    final defect = defects.where((d) => d.id == defectId).firstOrNull;

    if (defect == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('ДЕТАЛИ'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, size: 20),
            onPressed: () => context.pop(),
          ),
        ),
        body: const Center(child: Text('Дефектот не е пронајден.')),
      );
    }

    final isDispatcher = user?.role.isDispatcher ?? false;
    final dispatcherName = user?.fullName ?? 'Диспечер';

    return Scaffold(
      appBar: AppBar(
        title: Text(defect.id),
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

                _InfoCard(
                  children: [
                    Row(
                      children: [
                        StatusPill(status: defect.status),
                        const SizedBox(width: 10),
                        _PriorityChip(defect: defect),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _Row(label: 'Автобус', value: 'Автобус #${defect.busNumber}'),
                    const SizedBox(height: 8),
                    _Row(label: 'Тип', value: defect.type.label),
                    const SizedBox(height: 8),
                    _Row(label: 'Оддел', value: defect.department.label),
                    const SizedBox(height: 8),
                    _Row(label: 'Поднесено', value: _formatDate(defect.submittedAt)),
                    const SizedBox(height: 8),
                    _Row(label: 'Возач', value: defect.submittedByName),
                  ],
                ),
                const SizedBox(height: 16),
                _SectionLabel(text: 'ОПИС'),
                const SizedBox(height: 8),
                _InfoCard(
                  children: [
                    Text(
                      defect.description,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            height: 1.5,
                          ),
                    ),
                  ],
                ),
                if (isDispatcher) ...[
                  const SizedBox(height: 24),
                  _SectionLabel(text: 'ПРОМЕНИ СТАТУС'),
                  const SizedBox(height: 10),
                  _StatusUpdatePanel(defect: defect, dispatcherName: dispatcherName),
                ],
                if (!isDispatcher) ...[
                  const SizedBox(height: 20),
                  _ReadOnlyNotice(),
                ],
                if (defect.history.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  _SectionLabel(text: 'ИСТОРИЈА НА ПРОМЕНИ'),
                  const SizedBox(height: 10),
                  _HistoryTimeline(entries: defect.history),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}


class _StatusUpdatePanel extends ConsumerWidget {
  const _StatusUpdatePanel({
    required this.defect,
    required this.dispatcherName,
  });
  final DefectModel defect;
  final String dispatcherName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(defectProvider.notifier);

    final options = [
      (DefectStatus.newReport, 'New'),
      (DefectStatus.inProgress, 'In Progress'),
      (DefectStatus.resolved, 'Resolved'),
      (DefectStatus.rejected, 'Rejected'),
    ];

    return Column(
      children: options.map((entry) {
        final (status, label) = entry;
        final isSelected = defect.status == status;
        final color = status.color;

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(4),
              onTap: isSelected
                  ? null
                  : () => notifier.updateStatus(defect.id, status, byName: dispatcherName),
              child: Ink(
                decoration: BoxDecoration(
                  color: isSelected
                      ? color.withValues(alpha: 0.08)
                      : AppColors.surface,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: isSelected ? color : AppColors.border,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: isSelected ? color : AppColors.border,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          label,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                                color: isSelected
                                    ? color
                                    : AppColors.textPrimary,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              ),
                        ),
                      ),
                      if (isSelected)
                        Icon(
                          Icons.check_circle_rounded,
                          size: 18,
                          color: color,
                        ),
                    ],
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

class _ReadOnlyNotice extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded,
              size: 16, color: AppColors.textMuted),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Само диспечерот може да го менува статусот на извештајот.',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: AppColors.textSecondary, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: AppColors.textMuted,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
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

class _HistoryTimeline extends StatelessWidget {
  const _HistoryTimeline({required this.entries});
  final List<DefectHistoryEntry> entries;

  String _formatDate(DateTime dt) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(dt.day)}.${two(dt.month)}.${dt.year}  ${two(dt.hour)}:${two(dt.minute)}';
  }

  IconData _icon(HistoryChangeType type) {
    switch (type) {
      case HistoryChangeType.created:
        return Icons.add_circle_outline_rounded;
      case HistoryChangeType.statusChange:
        return Icons.swap_horiz_rounded;
      case HistoryChangeType.priorityChange:
        return Icons.flag_outlined;
      case HistoryChangeType.departmentChange:
        return Icons.alt_route_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reversed = entries.reversed.toList();

    return Column(
      children: List.generate(reversed.length, (i) {
        final entry = reversed[i];
        final isLast = i == reversed.length - 1;

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              SizedBox(
                width: 28,
                child: Column(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceElevated,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Icon(_icon(entry.type),
                          size: 14, color: AppColors.textSecondary),
                    ),
                    if (!isLast)
                      Expanded(
                        child: Container(
                          width: 1,
                          color: AppColors.border,
                          margin: const EdgeInsets.symmetric(vertical: 2),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        entry.description,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.textPrimary,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${entry.changedByName}  ·  ${_formatDate(entry.changedAt)}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppColors.textMuted,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _PriorityChip extends StatelessWidget {
  const _PriorityChip({required this.defect});
  final DefectModel defect;

  @override
  Widget build(BuildContext context) {
    final color = defect.priority.color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(defect.priority.icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            defect.priority.labelEn,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
          ),
        ],
      ),
    );
  }
}
