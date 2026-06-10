import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/theme/app_theme.dart';
import '../../models/defect_priority.dart';
import '../../models/defect_type.dart';
import '../../models/maintenance_department.dart';
import '../../widgets/widgets.dart';

class DefectReportScreen extends StatefulWidget {
  const DefectReportScreen({super.key});

  @override
  State<DefectReportScreen> createState() => _DefectReportScreenState();
}

class _DefectReportScreenState extends State<DefectReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _busNumberController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _imagePicker = ImagePicker();

  DefectType? _selectedType;
  DefectPriority _selectedPriority = DefectPriority.medium;
  XFile? _attachment;
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
      if (!mounted || picked == null) return;
      setState(() => _attachment = picked);
    } on Exception catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Не можеше да се отвори сликата: $e')),
      );
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
                title: const Text('Сликај со камера'),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Избери од галерија'),
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
      await _fakeSubmit();
      if (!mounted) return;

      await _showSuccessSheet();
      if (!mounted) return;
      context.pop();
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
        _submitError =
            'Дојде до неочекувана грешка. Обидете се повторно.';
      });
    }
  }

  Future<void> _fakeSubmit() async {
    await Future<void>.delayed(const Duration(milliseconds: 900));
    final busNumber = _busNumberController.text.trim();
    if (busNumber == '0000') {
      throw const _SubmitException(
        'Серверот не е достапен. Проверете ја интернет '
        'врската и обидете се повторно.',
      );
    }
    if (math.Random().nextInt(50) == 0) {
      throw const _SubmitException(
        'Извештајот не можеше да биде испратен. Обидете се повторно.',
      );
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

    final dropdownOptions = DefectType.values
        .map(
          (type) => AppDropdownOption<DefectType>(
            value: type,
            label: type.label,
            icon: type.icon,
          ),
        )
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('ПРИЈАВИ ДЕФЕКТ'),
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
                          const SectionHeader(title: 'Возило'),
                          AppTextField(
                            label: 'Број на автобус',
                            hint: 'пр. 412 или АА-1234-БВ',
                            controller: _busNumberController,
                            prefixIcon: Icons.directions_bus_filled_rounded,
                            keyboardType: TextInputType.text,
                            textInputAction: TextInputAction.next,
                            enabled: !_isSubmitting,
                            validator: (value) {
                              final v = value?.trim() ?? '';
                              if (v.isEmpty) {
                                return 'Внесете го бројот на автобусот';
                              }
                              if (v.length < 2) {
                                return 'Бројот на автобусот е премногу краток';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 28),
                          const SectionHeader(title: 'Дефект'),
                          AppDropdownField<DefectType>(
                            label: 'Тип на дефект',
                            hint: 'Изберете категорија',
                            prefixIcon: Icons.category_outlined,
                            value: _selectedType,
                            options: dropdownOptions,
                            enabled: !_isSubmitting,
                            onChanged: (type) =>
                                setState(() => _selectedType = type),
                            validator: (type) => type == null
                                ? 'Изберете тип на дефект'
                                : null,
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
                            label: 'Опис',
                            hint: 'Опишете го дефектот накратко…',
                            controller: _descriptionController,
                            maxLines: 5,
                            keyboardType: TextInputType.multiline,
                            enabled: !_isSubmitting,
                            validator: (value) {
                              final v = value?.trim() ?? '';
                              if (v.isEmpty) {
                                return 'Внесете опис на дефектот';
                              }
                              if (v.length < 8) {
                                return 'Описот е премногу краток';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 28),
                          const SectionHeader(title: 'Прилог'),
                          _AttachmentPicker(
                            attachment: _attachment,
                            enabled: !_isSubmitting,
                            onPick: _showAttachmentSheet,
                            onClear: () =>
                                setState(() => _attachment = null),
                          ),
                          const SizedBox(height: 16),
                          const _HelperNote(
                            text:
                                'Извештајот ќе биде препратен до диспечерот веднаш по поднесувањето.',
                          ),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Text(
                  'НОВ ИЗВЕШТАЈ',
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
          Text(
            'Пополнете го формуларот',
            style: theme.textTheme.headlineMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'Внесете ги основните податоци за возилото и опишете го '
            'дефектот за да биде препратен до сервисот.',
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _AttachmentPicker extends StatelessWidget {
  const _AttachmentPicker({
    required this.attachment,
    required this.onPick,
    required this.onClear,
    required this.enabled,
  });

  final XFile? attachment;
  final VoidCallback onPick;
  final VoidCallback onClear;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (attachment == null) {
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
                          'ДОДАДИ СЛИКА',
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontSize: 12,
                            letterSpacing: 1.4,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Опционално · од камера или галерија',
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
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(4),
            ),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.file(
                File(attachment!.path),
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
                    attachment!.name,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                TextButton.icon(
                  onPressed: enabled ? onPick : null,
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: const Text('Замени'),
                ),
                IconButton(
                  tooltip: 'Отстрани',
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

class _InlineErrorBanner extends StatelessWidget {
  const _InlineErrorBanner({
    required this.message,
    required this.onDismiss,
  });

  final String message;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
                  'ГРЕШКА ПРИ ИСПРАЌАЊЕ',
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
            tooltip: 'Затвори',
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
            'ПОДНЕСЕНО',
            style: theme.textTheme.labelMedium?.copyWith(
              color: AppColors.statusResolved,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.8,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Извештајот е испратен',
            style: theme.textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            'Диспечерот ќе го прегледа и ќе ве извести за статусот.',
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
                  'ДОДЕЛЕН ОДДЕЛ',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.textMuted,
                    fontSize: 9,
                    letterSpacing: 1.4,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  department.label,
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Приоритет',
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
                        color: isSelected
                            ? color
                            : AppColors.border,
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
              label: 'Откажи',
              variant: AppButtonVariant.outline,
              onPressed: isSubmitting ? null : onCancel,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: AppButton(
              label: 'Поднеси',
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
