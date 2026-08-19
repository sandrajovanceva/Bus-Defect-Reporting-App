import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/routes/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../models/defect_model.dart';
import '../../models/defect_type.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/defect_service.dart';
import '../../widgets/widgets.dart';

/// Service worker home: the defects waiting for their department, and the
/// jobs they have claimed. The backend already scopes [defectProvider] to the
/// worker's department, so this screen only splits queue vs. mine.
class ServiceQueueScreen extends ConsumerWidget {
  const ServiceQueueScreen({super.key});

  static const _claimable = {
    DefectStatus.newReport,
    DefectStatus.armaturaReview,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final user = ref.watch(authProvider).value;

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(t.serviceQueueTitle),
          leading: IconButton(
            tooltip: t.actionBack,
            icon: const Icon(Icons.arrow_back_rounded, size: 20),
            onPressed: () => context.pop(),
          ),
          actions: [
            const LanguageMenuButton(),
            IconButton(
              tooltip: t.actionRefresh,
              icon: const Icon(Icons.refresh_rounded, size: 20),
              onPressed: () => ref.invalidate(defectProvider),
            ),
            const SizedBox(width: 4),
          ],
          bottom: TabBar(
            labelColor: AppColors.accent,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.accent,
            tabs: [
              Tab(text: t.serviceTabQueue.toUpperCase()),
              Tab(text: t.serviceTabMine.toUpperCase()),
            ],
          ),
        ),
        body: user.department == null
            ? _Message(icon: Icons.badge_outlined, text: t.serviceNoDepartment)
            : _QueueBody(user: user),
      ),
    );
  }
}

class _QueueBody extends ConsumerWidget {
  const _QueueBody({required this.user});

  final UserModel user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final defectsState = ref.watch(defectProvider);

    return defectsState.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _Message(
        icon: Icons.error_outline_rounded,
        text: error is DefectFailure ? error.message : error.toString(),
      ),
      data: (defects) {
        final queue = defects
            .where(
              (d) =>
                  !d.isAssigned &&
                  ServiceQueueScreen._claimable.contains(d.status),
            )
            .toList();
        final mine = defects
            .where((d) => d.assignedToId == user.id)
            .toList();

        return Column(
          children: [
            _DepartmentBanner(user: user),
            Expanded(
              child: TabBarView(
                children: [
                  _JobList(
                    defects: queue,
                    emptyText: t.serviceQueueEmpty,
                    isMine: false,
                  ),
                  _JobList(
                    defects: mine,
                    emptyText: t.serviceMineEmpty,
                    isMine: true,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _DepartmentBanner extends StatelessWidget {
  const _DepartmentBanner({required this.user});

  final UserModel user;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Row(
        children: [
          const Icon(Icons.handyman_outlined, size: 16, color: AppColors.accent),
          const SizedBox(width: 8),
          Text(
            '${t.fieldDepartment}: ',
            style: theme.textTheme.labelSmall,
          ),
          Expanded(
            child: Text(
              user.department!.label(t),
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _JobList extends StatelessWidget {
  const _JobList({
    required this.defects,
    required this.emptyText,
    required this.isMine,
  });

  final List<DefectModel> defects;
  final String emptyText;
  final bool isMine;

  @override
  Widget build(BuildContext context) {
    if (defects.isEmpty) {
      return _Message(icon: Icons.inbox_outlined, text: emptyText);
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: defects.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _JobTile(defect: defects[i], isMine: isMine),
    );
  }
}

class _JobTile extends ConsumerWidget {
  const _JobTile({required this.defect, required this.isMine});

  final DefectModel defect;
  final bool isMine;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return InkWell(
      onTap: () => context.push(AppRoutes.defectDetails(defect.id)),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  defect.id,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '· ${t.busShort(defect.busNumber)}',
                    style: theme.textTheme.labelSmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                StatusPill(status: defect.status, dense: true),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              defect.type.label(t),
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              defect.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Text(
                    isMine
                        ? '${t.labelAssignedTo}: ${defect.assignedToName ?? ''}'
                        : '${t.labelDriver}: ${defect.driverName}',
                    style: theme.textTheme.labelSmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (!isMine)
                  AppButton(
                    label: t.serviceClaim,
                    icon: Icons.pan_tool_alt_outlined,
                    fullWidth: false,
                    onPressed: () => _claim(context, ref),
                  )
                else
                  _MyJobActions(defect: defect),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _claim(BuildContext context, WidgetRef ref) async {
    final t = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(defectRepositoryProvider).claimDefect(defect.id);
      ref.invalidate(defectProvider);
      messenger.showSnackBar(SnackBar(content: Text(t.serviceClaimed)));
    } on DefectFailure catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }
}

class _MyJobActions extends ConsumerWidget {
  const _MyJobActions({required this.defect});

  final DefectModel defect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final status = defect.status;

    // Nothing left for the worker once it's resolved — the dispatcher signs
    // the bus back into service from here.
    final canWork =
        status == DefectStatus.inProgress || status == DefectStatus.onHold;
    if (!canWork) return const SizedBox.shrink();

    return PopupMenuButton<String>(
      tooltip: t.staffOptions,
      icon: const Icon(
        Icons.more_vert_rounded,
        size: 20,
        color: AppColors.textSecondary,
      ),
      onSelected: (value) => _onAction(context, ref, value),
      itemBuilder: (_) => [
        if (status == DefectStatus.onHold)
          PopupMenuItem(value: 'resume', child: Text(t.serviceResume))
        else
          PopupMenuItem(value: 'hold', child: Text(t.serviceHold)),
        PopupMenuItem(value: 'resolve', child: Text(t.serviceResolve)),
        PopupMenuItem(value: 'release', child: Text(t.serviceRelease)),
      ],
    );
  }

  Future<void> _onAction(
    BuildContext context,
    WidgetRef ref,
    String action,
  ) async {
    final t = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final repo = ref.read(defectRepositoryProvider);

    try {
      switch (action) {
        case 'resume':
          await repo.updateStatus(
            defectId: defect.id,
            status: DefectStatus.inProgress,
          );
        case 'hold':
          final note = await _askNote(context, t.serviceHoldReason);
          if (note == null) return;
          await repo.updateStatus(
            defectId: defect.id,
            status: DefectStatus.onHold,
            note: note,
          );
        case 'resolve':
          final note = await _askNote(context, t.serviceResolveNote);
          if (note == null) return;
          await repo.updateStatus(
            defectId: defect.id,
            status: DefectStatus.resolved,
            note: note,
          );
        case 'release':
          await repo.releaseDefect(defect.id);
      }
      ref.invalidate(defectProvider);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            action == 'release' ? t.serviceReleased : t.serviceStatusUpdated,
          ),
        ),
      );
    } on DefectFailure catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  /// Returns the entered note, or null when the dialog is dismissed.
  Future<String?> _askNote(BuildContext context, String hint) {
    final controller = TextEditingController();
    final t = AppLocalizations.of(context);

    return showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(hint, style: Theme.of(context).textTheme.titleMedium),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 3,
          decoration: InputDecoration(hintText: t.serviceResolveNote),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(t.actionCancel),
          ),
          TextButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(controller.text.trim()),
            child: Text(t.serviceConfirm),
          ),
        ],
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: AppColors.textMuted),
            const SizedBox(height: 16),
            Text(
              text,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
