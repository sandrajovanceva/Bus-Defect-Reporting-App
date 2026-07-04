import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../models/defect_history_entry.dart';
import '../../models/defect_model.dart';
import '../../models/defect_type.dart';
import '../../services/auth_service.dart';
import '../../services/defect_service.dart';
import '../../widgets/widgets.dart';

class DefectDetailsScreen extends ConsumerWidget {
  const DefectDetailsScreen({super.key, required this.defectId});

  final String defectId;

  String _formatDate(DateTime dt) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(dt.day)}.${two(dt.month)}.${dt.year}  ${two(dt.hour)}:${two(dt.minute)}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.value;
    final defectsState = ref.watch(defectProvider);
    final defects = defectsState.value ?? const <DefectModel>[];
    final defect = defects.where((d) => d.id == defectId).firstOrNull;
    final t = AppLocalizations.of(context);

    if (authState.isLoading || defectsState.isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(t.detailsTitle),
          leading: IconButton(
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
          title: Text(t.detailsTitle),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, size: 20),
            onPressed: () => context.pop(),
          ),
        ),
        body: Center(child: Text(defectsState.error.toString())),
      );
    }

    if (defect == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(t.detailsTitle),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, size: 20),
            onPressed: () => context.pop(),
          ),
        ),
        body: Center(child: Text(t.detailsNotFound)),
      );
    }

    final isDispatcher = user?.role.isDispatcher ?? false;

    return Scaffold(
      appBar: AppBar(
        title: Text(defect.id),
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
                    _Row(
                      label: t.labelBus,
                      value: t.busNumbered(defect.busNumber),
                    ),
                    const SizedBox(height: 8),
                    _Row(label: t.labelType, value: defect.type.label(t)),
                    const SizedBox(height: 8),
                    _Row(
                      label: t.labelDepartment,
                      value: defect.department.label(t),
                    ),
                    const SizedBox(height: 8),
                    _Row(
                      label: t.labelSubmitted,
                      value: _formatDate(defect.submittedAt),
                    ),
                    const SizedBox(height: 8),
                    _Row(label: t.labelDriver, value: defect.driverName),
                    const SizedBox(height: 8),
                    _Row(
                      label: t.labelReportedBy,
                      value: defect.submittedByName,
                    ),
                    if (defect.hasLocation) ...[
                      const SizedBox(height: 8),
                      _Row(
                        label: t.labelLocation,
                        value:
                            '${defect.latitude!.toStringAsFixed(5)}, '
                            '${defect.longitude!.toStringAsFixed(5)}',
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 16),
                _SectionLabel(text: t.sectionDescription),
                const SizedBox(height: 8),
                _InfoCard(
                  children: [
                    Text(
                      defect.description,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(height: 1.5),
                    ),
                  ],
                ),
                if (isDispatcher) ...[
                  const SizedBox(height: 24),
                  _SectionLabel(text: t.sectionClassify),
                  const SizedBox(height: 10),
                  _ClassifyPanel(defect: defect),
                  const SizedBox(height: 24),
                  _SectionLabel(text: t.sectionChangeStatus),
                  const SizedBox(height: 10),
                  _StatusUpdatePanel(defect: defect),
                ],
                if (!isDispatcher) ...[
                  const SizedBox(height: 20),
                  _ReadOnlyNotice(),
                ],
                if (defect.history.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  _SectionLabel(text: t.sectionHistory),
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
  const _StatusUpdatePanel({required this.defect});
  final DefectModel defect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = ref.read(defectRepositoryProvider);
    final t = AppLocalizations.of(context);

    final options = [
      (DefectStatus.newReport, t.statusNew),
      (DefectStatus.armaturaReview, t.statusArmaturaReview),
      (DefectStatus.inProgress, t.statusInProgress),
      (DefectStatus.resolved, t.statusResolved),
      (DefectStatus.returnedToService, t.statusReturnedToService),
      (DefectStatus.rejected, t.statusRejected),
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
                  : () async {
                      await repository.updateStatus(
                        defectId: defect.id,
                        status: status,
                      );
                      ref.invalidate(defectProvider);
                    },
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
                          style: Theme.of(context).textTheme.bodyMedium
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

/// Lets a dispatcher (standing in for the Арматура department) confirm or
/// correct the defect's category. The reporter's initial pick is just a
/// guess from the driver's card / phone call — Арматура is the step that
/// actually pins it down to electrical / mechanical / bravari, which in
/// turn decides which department the repair gets routed to.
class _ClassifyPanel extends ConsumerStatefulWidget {
  const _ClassifyPanel({required this.defect});
  final DefectModel defect;

  @override
  ConsumerState<_ClassifyPanel> createState() => _ClassifyPanelState();
}

class _ClassifyPanelState extends ConsumerState<_ClassifyPanel> {
  // Null means "not chosen yet" — the case right after a report comes in
  // still marked unclassified, before Armatura has picked a real category.
  late DefectType? _selected = _initialSelection(widget.defect.type);
  bool _isSaving = false;

  static DefectType? _initialSelection(DefectType type) =>
      type == DefectType.unclassified ? null : type;

  @override
  void didUpdateWidget(covariant _ClassifyPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.defect.type != widget.defect.type) {
      _selected = _initialSelection(widget.defect.type);
    }
  }

  Future<void> _save() async {
    final selected = _selected;
    if (selected == null) return;
    setState(() => _isSaving = true);
    try {
      await ref
          .read(defectRepositoryProvider)
          .reclassify(defectId: widget.defect.id, type: selected);
      ref.invalidate(defectProvider);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final unchanged =
        _selected != null && _selected == widget.defect.type;
    final canSave = _selected != null && !unchanged;

    // Armatura always picks a real category — "unclassified" isn't a valid
    // classification outcome, just the pre-review default.
    final options = DefectType.values
        .where((type) => type != DefectType.unclassified)
        .map(
          (type) => AppDropdownOption<DefectType>(
            value: type,
            label: type.label(t),
            icon: type.icon,
          ),
        )
        .toList();

    return _InfoCard(
      children: [
        Text(
          t.classifyHelperNote,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(height: 1.4),
        ),
        const SizedBox(height: 14),
        AppDropdownField<DefectType>(
          label: t.fieldDefectType,
          hint: t.reportTypeHint,
          prefixIcon: Icons.category_outlined,
          value: _selected,
          options: options,
          enabled: !_isSaving,
          onChanged: (type) => setState(() => _selected = type),
        ),
        if (_selected != null) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(
                Icons.alt_route_rounded,
                size: 14,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 8),
              Text(
                _selected!.department.label(t),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 14),
        AppButton(
          label: t.classifySave,
          icon: Icons.check_rounded,
          isLoading: _isSaving,
          onPressed: canSave ? _save : null,
        ),
        if (unchanged) ...[
          const SizedBox(height: 8),
          Text(
            t.classifyUnchanged,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.textMuted,
            ),
          ),
        ],
      ],
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
          const Icon(
            Icons.info_outline_rounded,
            size: 16,
            color: AppColors.textMuted,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              AppLocalizations.of(context).readOnlyNotice,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
                height: 1.4,
              ),
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
                      child: Icon(
                        _icon(entry.type),
                        size: 14,
                        color: AppColors.textSecondary,
                      ),
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
