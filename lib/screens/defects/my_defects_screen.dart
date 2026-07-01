import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/routes/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../models/defect_model.dart';
import '../../models/defect_priority.dart';
import '../../models/defect_type.dart';
import '../../services/auth_service.dart';
import '../../services/defect_service.dart';
import '../../widgets/status_pill.dart';

class _FilterState {
  const _FilterState({
    this.status,
    this.type,
    this.priority,
    this.busNumber = '',
  });

  final DefectStatus? status;
  final DefectType? type;
  final DefectPriority? priority;
  final String busNumber;

  bool get isActive =>
      status != null ||
      type != null ||
      priority != null ||
      busNumber.isNotEmpty;

  _FilterState copyWith({
    Object? status = _sentinel,
    Object? type = _sentinel,
    Object? priority = _sentinel,
    String? busNumber,
  }) {
    return _FilterState(
      status: status == _sentinel ? this.status : status as DefectStatus?,
      type: type == _sentinel ? this.type : type as DefectType?,
      priority: priority == _sentinel
          ? this.priority
          : priority as DefectPriority?,
      busNumber: busNumber ?? this.busNumber,
    );
  }

  List<DefectModel> apply(List<DefectModel> input) {
    return input.where((d) {
      if (status != null && d.status != status) return false;
      if (type != null && d.type != type) return false;
      if (priority != null && d.priority != priority) return false;
      if (busNumber.isNotEmpty &&
          !d.busNumber.toLowerCase().contains(busNumber.toLowerCase())) {
        return false;
      }
      return true;
    }).toList();
  }
}

const _sentinel = Object();

class MyDefectsScreen extends ConsumerStatefulWidget {
  const MyDefectsScreen({super.key});

  @override
  ConsumerState<MyDefectsScreen> createState() => _MyDefectsScreenState();
}

class _MyDefectsScreenState extends ConsumerState<MyDefectsScreen> {
  _FilterState _filter = const _FilterState();
  final _busController = TextEditingController();

  @override
  void dispose() {
    _busController.dispose();
    super.dispose();
  }

  void _clearFilters() {
    _busController.clear();
    setState(() => _filter = const _FilterState());
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.value;
    final defectsState = ref.watch(defectProvider);
    final allDefects = defectsState.value ?? const <DefectModel>[];
    final isDispatcher = user?.role.isDispatcher ?? false;

    final base = isDispatcher
        ? allDefects
        : allDefects.where((d) => d.submittedById == user?.id).toList();

    final defects = _filter.apply(base);

    final t = AppLocalizations.of(context);
    final title = isDispatcher ? t.myDefectsTitleAll : t.myDefectsTitleMine;

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        leading: IconButton(
          tooltip: t.actionBack,
          icon: const Icon(Icons.arrow_back_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (_filter.isActive)
            TextButton(
              onPressed: _clearFilters,
              child: Text(
                t.filterClear,
                style: TextStyle(
                  color: AppColors.accent,
                  fontSize: 11,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          _FilterBar(
            filter: _filter,
            busController: _busController,
            onChanged: (f) => setState(() => _filter = f),
          ),
          Expanded(
            child: defectsState.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => _LoadError(message: error.toString()),
              data: (_) => defects.isEmpty
                  ? _EmptyState(isFiltered: _filter.isActive)
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: defects.length,
                      separatorBuilder: (_, __) =>
                          const Divider(height: 1, color: AppColors.border),
                      itemBuilder: (_, i) => _DefectTile(defect: defects[i]),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.filter,
    required this.busController,
    required this.onChanged,
  });

  final _FilterState filter;
  final TextEditingController busController;
  final ValueChanged<_FilterState> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);

    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 38,
            child: TextField(
              controller: busController,
              onChanged: (v) => onChanged(filter.copyWith(busNumber: v)),
              style: theme.textTheme.bodySmall,
              decoration: InputDecoration(
                hintText: loc.searchBusHint,
                hintStyle: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textMuted,
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  size: 18,
                  color: AppColors.textMuted,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                filled: true,
                fillColor: AppColors.surfaceElevated,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: const BorderSide(
                    color: AppColors.accent,
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ...DefectStatus.values.map(
                  (s) => _FilterChip(
                    label: s.label,
                    selected: filter.status == s,
                    color: s.color,
                    onTap: () => onChanged(
                      filter.copyWith(status: filter.status == s ? null : s),
                    ),
                  ),
                ),
                const _Divider(),
                ...DefectPriority.values.map(
                  (p) => _FilterChip(
                    label: p.labelEn,
                    selected: filter.priority == p,
                    color: p.color,
                    onTap: () => onChanged(
                      filter.copyWith(
                        priority: filter.priority == p ? null : p,
                      ),
                    ),
                  ),
                ),
                const _Divider(),
                ...[
                  DefectType.brakes,
                  DefectType.electrical,
                  DefectType.mechanical,
                  DefectType.doors,
                  DefectType.other,
                ].map(
                  (type) => _FilterChip(
                    label: type.label(loc),
                    selected: filter.type == type,
                    onTap: () => onChanged(
                      filter.copyWith(type: filter.type == type ? null : type),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.color,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = color ?? AppColors.textSecondary;

    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: selected
                ? c.withValues(alpha: 0.12)
                : AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(2),
            border: Border.all(
              color: selected ? c : AppColors.border,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: selected ? c : AppColors.textSecondary,
              fontSize: 10,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              letterSpacing: 0.8,
            ),
          ),
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) => Container(
    width: 1,
    height: 18,
    color: AppColors.border,
    margin: const EdgeInsets.only(right: 8),
  );
}

class _DefectTile extends StatelessWidget {
  const _DefectTile({required this.defect});
  final DefectModel defect;

  String _formatDate(DateTime dt) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(dt.day)}.${two(dt.month)}.${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context);

    return InkWell(
      onTap: () => context.push(AppRoutes.defectDetails(defect.id)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Icon(
                defect.type.icon,
                size: 20,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        defect.id,
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '· ${t.busShort(defect.busNumber)}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    defect.type.label(t),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      StatusPill(status: defect.status, dense: true),
                      const SizedBox(width: 8),
                      Text(
                        _formatDate(defect.submittedAt),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppColors.textMuted,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          message,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppColors.statusNew,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.isFiltered});
  final bool isFiltered;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isFiltered ? Icons.filter_list_off_rounded : Icons.inbox_outlined,
            size: 48,
            color: AppColors.textMuted,
          ),
          const SizedBox(height: 16),
          Text(
            isFiltered ? t.emptyFiltered : t.emptyNoDefects,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
