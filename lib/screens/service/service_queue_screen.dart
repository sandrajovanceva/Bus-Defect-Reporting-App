import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/routes/app_routes.dart';
import '../../core/theme/glass_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../models/defect_model.dart';
import '../../models/defect_type.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/defect_service.dart';
import '../../widgets/glass_panel.dart';
import '../../widgets/language_menu_button.dart';
import '../../widgets/status_pill.dart';

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
    final user = ref.watch(authProvider).value;

    // The glass treatment is scoped to this screen; the rest of the app keeps
    // the light theme.
    return Theme(
      data: GlassTheme.data,
      child: GlassField(
        child: user == null
            ? const Scaffold(
                backgroundColor: Colors.transparent,
                body: Center(child: CircularProgressIndicator()),
              )
            : _Shell(user: user),
      ),
    );
  }
}

class _Shell extends ConsumerWidget {
  const _Shell({required this.user});

  final UserModel user;

  /// Department line + segmented control, which ride inside the frosted bar.
  static const double _headerHeight = 96;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final defectsState = ref.watch(defectProvider);

    final defects = defectsState.value ?? const <DefectModel>[];
    final queue = defects
        .where(
          (d) =>
              !d.isAssigned && ServiceQueueScreen._claimable.contains(d.status),
        )
        .toList();
    final mine = defects.where((d) => d.assignedToId == user.id).toList();

    final hasDepartment = user.department != null;

    // The list passes underneath the frosted bar rather than starting below
    // it, so it has to carry the bar's height as top padding itself.
    final topInset =
        MediaQuery.paddingOf(context).top +
        64 +
        (hasDepartment ? _headerHeight : 0);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
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
          // The frost. It sits behind the bar's own contents and spans the
          // tab strip too, so a job card dissolves as it slides under.
          flexibleSpace: const _Frost(),
          bottom: hasDepartment
              ? PreferredSize(
                  preferredSize: const Size.fromHeight(_headerHeight),
                  child: _Measure(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _DepartmentBar(user: user),
                        _Segmented(
                          queueLabel: t.serviceTabQueue,
                          mineLabel: t.serviceTabMine,
                          queueCount: queue.length,
                          mineCount: mine.length,
                        ),
                      ],
                    ),
                  ),
                )
              : null,
        ),
        body: !hasDepartment
            ? _Message(icon: Icons.badge_outlined, text: t.serviceNoDepartment)
            : defectsState.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => _Message(
                  icon: Icons.error_outline_rounded,
                  text: error is DefectFailure
                      ? error.message
                      : error.toString(),
                ),
                data: (_) => TabBarView(
                  children: [
                    _JobList(
                      defects: queue,
                      emptyText: t.serviceQueueEmpty,
                      isMine: false,
                      topInset: topInset,
                    ),
                    _JobList(
                      defects: mine,
                      emptyText: t.serviceMineEmpty,
                      isMine: true,
                      topInset: topInset,
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

/// The frosted plate behind the app bar and tab strip.
class _Frost extends StatelessWidget {
  const _Frost();

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
        child: const DecoratedBox(
          decoration: BoxDecoration(
            color: GlassColors.chromeFill,
            border: Border(bottom: BorderSide(color: GlassColors.edgeShade)),
          ),
          child: SizedBox.expand(),
        ),
      ),
    );
  }
}

/// Holds content to a readable measure and centres it, so a single work order
/// does not stretch into a band across a wide monitor.
class _Measure extends StatelessWidget {
  const _Measure({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: GlassTheme.contentWidth),
        child: child,
      ),
    );
  }
}

/// Whose bench this is.
class _DepartmentBar extends StatelessWidget {
  const _DepartmentBar({required this.user});

  final UserModel user;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          const Icon(
            Icons.handyman_outlined,
            size: 15,
            color: GlassColors.livery,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              user.department!.label(t).toUpperCase(),
              style: theme.textTheme.labelMedium?.copyWith(
                color: GlassColors.textPrimary,
                letterSpacing: 2,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 12),
          // The waiting count lives on the queue tab below, so it is not
          // repeated here — this line only answers "whose bench is this".
          Expanded(
            child: Container(height: 1, color: GlassColors.edgeShade),
          ),
        ],
      ),
    );
  }
}

/// Glass segmented control. Replaces the underlined Material tab bar, which
/// reads as a web page rather than a panel.
class _Segmented extends StatelessWidget {
  const _Segmented({
    required this.queueLabel,
    required this.mineLabel,
    required this.queueCount,
    required this.mineCount,
  });

  final String queueLabel;
  final String mineLabel;
  final int queueCount;
  final int mineCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      // No blur of its own — it already rides on the frosted bar, and a second
      // BackdropFilter here would only cost a save layer.
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: const Color(0x0F1A1815),
          border: Border.all(color: GlassColors.edgeShade),
        ),
        child: TabBar(
          dividerHeight: 0,
          indicatorSize: TabBarIndicatorSize.tab,
          overlayColor: WidgetStateProperty.all(Colors.transparent),
          // Red on the active tab, as everywhere else in the app.
          labelColor: GlassColors.livery,
          unselectedLabelColor: GlassColors.textMuted,
          labelStyle: theme.textTheme.labelMedium?.copyWith(
            color: GlassColors.livery,
          ),
          unselectedLabelStyle: theme.textTheme.labelMedium,
          indicator: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1A1815).withValues(alpha: 0.10),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          tabs: [
            Tab(height: 38, text: '${queueLabel.toUpperCase()}  $queueCount'),
            Tab(height: 38, text: '${mineLabel.toUpperCase()}  $mineCount'),
          ],
        ),
      ),
    );
  }
}

class _JobList extends StatelessWidget {
  const _JobList({
    required this.defects,
    required this.emptyText,
    required this.isMine,
    required this.topInset,
  });

  final List<DefectModel> defects;
  final String emptyText;
  final bool isMine;
  final double topInset;

  @override
  Widget build(BuildContext context) {
    if (defects.isEmpty) {
      return Padding(
        padding: EdgeInsets.only(top: topInset),
        child: _Message(icon: Icons.inbox_outlined, text: emptyText),
      );
    }
    return _Measure(
      child: ListView.separated(
        padding: EdgeInsets.fromLTRB(16, topInset + 14, 16, 28),
        itemCount: defects.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) => _Rise(
          index: i,
          child: _JobCard(defect: defects[i], isMine: isMine),
        ),
      ),
    );
  }
}

/// Cards settle into place on load. One effect, no more.
class _Rise extends StatelessWidget {
  const _Rise({required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return child;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 320 + (index.clamp(0, 6) * 70)),
      curve: Curves.easeOutCubic,
      builder: (_, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 14 * (1 - value)),
          child: child,
        ),
      ),
      child: child,
    );
  }
}

class _JobCard extends ConsumerWidget {
  const _JobCard({required this.defect, required this.isMine});

  final DefectModel defect;
  final bool isMine;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final status = defect.status;

    return GlassPanel(
      glow: status.glassColor,
      padding: const EdgeInsets.fromLTRB(18, 16, 12, 16),
      onTap: () => context.push(AppRoutes.defectDetails(defect.id)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Fleet number: the first thing a mechanic looks for, so it is
              // set as a plate rather than a line of body text.
              Text(
                defect.busNumber,
                style: theme.textTheme.displaySmall,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        defect.type.label(t),
                        style: theme.textTheme.titleMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        defect.id,
                        style: theme.textTheme.labelSmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
              _StatusChip(status: status),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            defect.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 14),
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
              const SizedBox(width: 8),
              if (!isMine)
                _ClaimButton(
                  label: t.serviceClaim,
                  onPressed: () => _claim(context, ref),
                )
              else
                _MyJobActions(defect: defect),
            ],
          ),
        ],
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

/// The one opaque, full-contrast element on the screen. Actions do not get to
/// be translucent — a mechanic has to be able to hit this in a lit workshop.
class _ClaimButton extends StatelessWidget {
  const _ClaimButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: GlassColors.livery,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.pan_tool_alt_outlined,
                size: 15,
                color: Colors.white,
              ),
              const SizedBox(width: 8),
              Text(
                label.toUpperCase(),
                style: theme.textTheme.labelMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final DefectStatus status;

  @override
  Widget build(BuildContext context) {
    final color = status.glassColor;
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        status.label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
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
        Icons.more_horiz_rounded,
        size: 20,
        color: GlassColors.textSecondary,
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
      builder: (dialogContext) => Theme(
        data: GlassTheme.data,
        child: AlertDialog(
          title: Text(hint, style: GlassTheme.data.textTheme.titleMedium),
          content: TextField(
            controller: controller,
            autofocus: true,
            maxLines: 3,
            style: GlassTheme.data.textTheme.bodySmall?.copyWith(
              color: GlassColors.textPrimary,
            ),
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
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 42, color: GlassColors.textMuted),
            const SizedBox(height: 16),
            Text(
              text,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
