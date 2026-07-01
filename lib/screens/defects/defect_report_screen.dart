import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../models/defect_priority.dart';
import '../../models/defect_type.dart';
import '../../models/maintenance_department.dart';
import '../../services/auth_service.dart';
import '../../services/defect_service.dart';
import '../../services/location_service.dart';
import '../../widgets/widgets.dart';

class DefectReportScreen extends ConsumerStatefulWidget {
  const DefectReportScreen({super.key});

  @override
  ConsumerState<DefectReportScreen> createState() => _DefectReportScreenState();
}

class _DefectReportScreenState extends ConsumerState<DefectReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _busNumberController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _imagePicker = ImagePicker();

  DefectType? _selectedType;
  DefectPriority _selectedPriority = DefectPriority.medium;
  XFile? _attachment;
  Uint8List? _attachmentBytes;
  DefectLocation? _location;
  bool _isLocating = false;
  bool _isSubmitting = false;
  String? _submitError;

  @override
  void dispose() {
    _busNumberController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _imagePicker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1920,
      );
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      if (!mounted) return;
      setState(() {
        _attachment = picked;
        _attachmentBytes = bytes;
      });
    } on Exception catch (e) {
      if (!mounted) return;
      final t = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.reportImageOpenError('$e'))),
      );
    }
  }

  String _locationErrorText(AppLocalizations t, LocationErrorCode code) {
    switch (code) {
      case LocationErrorCode.servicesDisabled:
        return t.locationServicesOff;
      case LocationErrorCode.denied:
        return t.locationDenied;
      case LocationErrorCode.deniedForever:
        return t.locationDeniedForever;
      case LocationErrorCode.unknown:
        return t.locationError;
    }
  }

  Future<void> _captureLocation() async {
    final t = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _isLocating = true);
    try {
      final location = await ref
          .read(locationServiceProvider)
          .getCurrentLocation();
      if (!mounted) return;
      setState(() {
        _location = location;
        _isLocating = false;
      });
    } on LocationFailure catch (e) {
      if (!mounted) return;
      setState(() => _isLocating = false);
      messenger.showSnackBar(
        SnackBar(content: Text(_locationErrorText(t, e.code))),
      );
    } on Exception {
      if (!mounted) return;
      setState(() => _isLocating = false);
      messenger.showSnackBar(SnackBar(content: Text(t.locationError)));
    }
  }

  void _showAttachmentSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: Text(AppLocalizations.of(context).sheetCamera),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: Text(AppLocalizations.of(context).sheetGallery),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _pickImage(ImageSource.gallery);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Future<void> _submit() async {
    setState(() => _submitError = null);

    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    setState(() => _isSubmitting = true);
    try {
      final user = ref.read(authProvider).value;
      if (user == null) {
        throw _SubmitException(AppLocalizations.of(context).reportSignInFirst);
      }

      final imageBase64 = _attachmentBytes != null
          ? base64Encode(_attachmentBytes!)
          : null;

      await ref
          .read(defectRepositoryProvider)
          .createDefect(
            DefectDraft(
              busNumber: _busNumberController.text,
              type: _selectedType!,
              priority: _selectedPriority,
              description: _descriptionController.text,
              imageBase64: imageBase64,
              latitude: _location?.latitude,
              longitude: _location?.longitude,
            ),
          );

      ref.invalidate(defectProvider);
      if (!mounted) return;

      await _showSuccessSheet();
      if (!mounted) return;
      context.pop();
    } on DefectFailure catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _submitError = e.message;
      });
    } on _SubmitException catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _submitError = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _submitError = AppLocalizations.of(context).reportSubmitError;
      });
    }
  }

  Future<void> _showSuccessSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
      ),
      builder: (sheetContext) {
        Future<void>.delayed(const Duration(milliseconds: 1600), () {
          if (sheetContext.mounted) Navigator.of(sheetContext).pop();
        });
        return const _SuccessSheet();
      },
    );
  }

  String _formatTimestamp(DateTime now) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(now.day)}.${two(now.month)}.${now.year} · '
        '${two(now.hour)}:${two(now.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final t = AppLocalizations.of(context);

    final dropdownOptions = DefectType.values
        .map(
          (type) => AppDropdownOption<DefectType>(
            value: type,
            label: type.label(t),
            icon: type.icon,
          ),
        )
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(t.reportTitle),
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
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _ReportHeader(timestamp: _formatTimestamp(now)),
                          if (_submitError != null) ...[
                            const SizedBox(height: 16),
                            _InlineErrorBanner(
                              message: _submitError!,
                              onDismiss: () =>
                                  setState(() => _submitError = null),
                            ),
                          ],
                          const SizedBox(height: 28),
                          SectionHeader(title: t.sectionVehicle),
                          AppTextField(
                            label: t.fieldBusNumber,
                            hint: t.reportBusHint,
                            controller: _busNumberController,
                            prefixIcon: Icons.directions_bus_filled_rounded,
                            keyboardType: TextInputType.text,
                            textInputAction: TextInputAction.next,
                            enabled: !_isSubmitting,
                            validator: (value) {
                              final v = value?.trim() ?? '';
                              if (v.isEmpty) {
                                return t.validationBusRequired;
                              }
                              if (v.length < 2) {
                                return t.validationBusShort;
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 28),
                          SectionHeader(title: t.sectionDefect),
                          AppDropdownField<DefectType>(
                            label: t.fieldDefectType,
                            hint: t.reportTypeHint,
                            prefixIcon: Icons.category_outlined,
                            value: _selectedType,
                            options: dropdownOptions,
                            enabled: !_isSubmitting,
                            onChanged: (type) =>
                                setState(() => _selectedType = type),
                            validator: (type) =>
                                type == null ? t.validationTypeRequired : null,
                          ),
                          if (_selectedType != null) ...[
                            const SizedBox(height: 10),
                            _DepartmentBadge(
                              department: _selectedType!.department,
                            ),
                          ],
                          const SizedBox(height: 20),
                          _PrioritySelector(
                            selected: _selectedPriority,
                            enabled: !_isSubmitting,
                            onChanged: (p) =>
                                setState(() => _selectedPriority = p),
                          ),
                          const SizedBox(height: 20),
                          AppTextField(
                            label: t.fieldDescription,
                            hint: t.reportDescriptionHint,
                            controller: _descriptionController,
                            maxLines: 5,
                            keyboardType: TextInputType.multiline,
                            enabled: !_isSubmitting,
                            validator: (value) {
                              final v = value?.trim() ?? '';
                              if (v.isEmpty) {
                                return t.validationDescRequired;
                              }
                              if (v.length < 8) {
                                return t.validationDescShort;
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 28),
                          SectionHeader(title: t.sectionAttachment),
                          _AttachmentPicker(
                            bytes: _attachmentBytes,
                            name: _attachment?.name,
                            enabled: !_isSubmitting,
                            onPick: _showAttachmentSheet,
                            onClear: () => setState(() {
                              _attachment = null;
                              _attachmentBytes = null;
                            }),
                          ),
                          const SizedBox(height: 28),
                          SectionHeader(title: t.sectionLocation),
                          _LocationPicker(
                            location: _location,
                            isLocating: _isLocating,
                            enabled: !_isSubmitting,
                            onCapture: _captureLocation,
                            onClear: () => setState(() => _location = null),
                          ),
                          const SizedBox(height: 16),
                          _HelperNote(text: t.reportHelperNote),
                        ],
                      ),
                    ),
                  ),
                  _SubmitBar(
                    isSubmitting: _isSubmitting,
                    onSubmit: _submit,
                    onCancel: () => context.pop(),
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

class _SubmitException implements Exception {
  const _SubmitException(this.message);
  final String message;
}

class _ReportHeader extends StatelessWidget {
  const _ReportHeader({required this.timestamp});

  final String timestamp;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Text(
                  t.reportBadgeNew,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 10,
                    letterSpacing: 1.6,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  timestamp,
                  style: theme.textTheme.labelSmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(t.reportFillForm, style: theme.textTheme.headlineMedium),
          const SizedBox(height: 4),
          Text(t.reportFormIntro, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _AttachmentPicker extends StatelessWidget {
  const _AttachmentPicker({
    required this.bytes,
    required this.name,
    required this.onPick,
    required this.onClear,
    required this.enabled,
  });

  final Uint8List? bytes;
  final String? name;
  final VoidCallback onPick;
  final VoidCallback onClear;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context);

    if (bytes == null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onPick : null,
          borderRadius: BorderRadius.circular(4),
          child: Ink(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: AppColors.border, width: 1.5),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.accentSurface,
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: const Icon(
                      Icons.add_a_photo_outlined,
                      color: AppColors.accent,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t.attachmentAdd,
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontSize: 12,
                            letterSpacing: 1.4,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          t.attachmentOptional,
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 22,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.memory(
                bytes!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: AppColors.surfaceElevated,
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.broken_image_outlined,
                    size: 32,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
            child: Row(
              children: [
                const Icon(
                  Icons.image_outlined,
                  size: 18,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    name ?? t.attachmentImageFallback,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                TextButton.icon(
                  onPressed: enabled ? onPick : null,
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: Text(t.actionReplace),
                ),
                IconButton(
                  tooltip: t.actionRemove,
                  onPressed: enabled ? onClear : null,
                  icon: const Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: AppColors.textSecondary,
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

class _LocationPicker extends StatelessWidget {
  const _LocationPicker({
    required this.location,
    required this.isLocating,
    required this.enabled,
    required this.onCapture,
    required this.onClear,
  });

  final DefectLocation? location;
  final bool isLocating;
  final bool enabled;
  final VoidCallback onCapture;
  final VoidCallback onClear;

  String _format(double value) => value.toStringAsFixed(5);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context);
    final loc = location;

    if (loc == null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled && !isLocating ? onCapture : null,
          borderRadius: BorderRadius.circular(4),
          child: Ink(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: AppColors.border, width: 1.5),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.accentSurface,
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: isLocating
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(
                            Icons.my_location_rounded,
                            color: AppColors.accent,
                            size: 20,
                          ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isLocating ? t.locationLocating : t.locationAdd,
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontSize: 12,
                            letterSpacing: 1.4,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          t.locationOptional,
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 22,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.statusResolved.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(2),
            ),
            child: const Icon(
              Icons.place_rounded,
              color: AppColors.statusResolved,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.locationSaved,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.statusResolved,
                    fontSize: 9,
                    letterSpacing: 1.4,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_format(loc.latitude)}, ${_format(loc.longitude)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: enabled && !isLocating ? onCapture : null,
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: Text(t.actionRefresh),
          ),
          IconButton(
            tooltip: t.actionRemove,
            onPressed: enabled ? onClear : null,
            icon: const Icon(
              Icons.close_rounded,
              size: 18,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineErrorBanner extends StatelessWidget {
  const _InlineErrorBanner({required this.message, required this.onDismiss});

  final String message;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.accentSurface,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.accent, width: 1),
      ),
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 20,
            color: AppColors.accentDark,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.reportErrorTitle,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: AppColors.accentDark,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.6,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.accentDark,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: t.actionClose,
            iconSize: 18,
            visualDensity: VisualDensity.compact,
            color: AppColors.accentDark,
            onPressed: onDismiss,
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
    );
  }
}

class _SuccessSheet extends StatelessWidget {
  const _SuccessSheet();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 22),
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.statusResolved.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: AppColors.statusResolved.withValues(alpha: 0.4),
              ),
            ),
            child: const Icon(
              Icons.check_rounded,
              size: 32,
              color: AppColors.statusResolved,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            t.successSubmitted,
            style: theme.textTheme.labelMedium?.copyWith(
              color: AppColors.statusResolved,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.8,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            t.successTitle,
            style: theme.textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            t.successSubtitle,
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _HelperNote extends StatelessWidget {
  const _HelperNote({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.accentSurface,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.accentMuted, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 18,
            color: AppColors.accentDark,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.accentDark,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DepartmentBadge extends StatelessWidget {
  const _DepartmentBadge({required this.department});

  final MaintenanceDepartment department;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.alt_route_rounded,
            size: 16,
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.assignedDepartment,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.textMuted,
                    fontSize: 9,
                    letterSpacing: 1.4,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  department.label(t),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
            child: Text(
              department.code,
              style: theme.textTheme.labelSmall?.copyWith(
                fontSize: 9,
                letterSpacing: 1.4,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrioritySelector extends StatelessWidget {
  const _PrioritySelector({
    required this.selected,
    required this.onChanged,
    required this.enabled,
  });

  final DefectPriority selected;
  final ValueChanged<DefectPriority> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t.fieldPriority,
          style: theme.textTheme.labelSmall?.copyWith(
            color: AppColors.textSecondary,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: DefectPriority.values.map((priority) {
            final isSelected = priority == selected;
            final color = priority.color;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: priority != DefectPriority.values.last ? 8 : 0,
                ),
                child: GestureDetector(
                  onTap: enabled ? () => onChanged(priority) : null,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? color.withValues(alpha: 0.10)
                          : AppColors.surface,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: isSelected ? color : AppColors.border,
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          priority.icon,
                          size: 18,
                          color: isSelected ? color : AppColors.textMuted,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          priority.labelEn,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: isSelected ? color : AppColors.textMuted,
                            fontSize: 9,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _SubmitBar extends StatelessWidget {
  const _SubmitBar({
    required this.isSubmitting,
    required this.onSubmit,
    required this.onCancel,
  });

  final bool isSubmitting;
  final VoidCallback onSubmit;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(top: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: AppButton(
              label: t.submitCancel,
              variant: AppButtonVariant.outline,
              onPressed: isSubmitting ? null : onCancel,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: AppButton(
              label: t.submitSend,
              icon: Icons.send_rounded,
              isLoading: isSubmitting,
              onPressed: onSubmit,
            ),
          ),
        ],
      ),
    );
  }
}
