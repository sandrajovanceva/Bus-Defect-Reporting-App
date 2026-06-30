import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../core/routes/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../../models/defect_model.dart';
import '../../models/defect_type.dart';
import '../../services/auth_service.dart';
import '../../services/defect_service.dart';
import '../../widgets/status_pill.dart';

class DefectMapScreen extends ConsumerWidget {
  const DefectMapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.value;
    final defectsState = ref.watch(defectProvider);
    final isDispatcher = user?.role.isDispatcher ?? false;

    final allDefects = defectsState.value ?? const <DefectModel>[];
    final visible = isDispatcher
        ? allDefects
        : allDefects.where((d) => d.submittedById == user?.id).toList();
    final located = visible.where((d) => d.hasLocation).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('МАПА НА ДЕФЕКТИ'),
        leading: IconButton(
          tooltip: 'Назад',
          icon: const Icon(Icons.arrow_back_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: defectsState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _MapMessage(
          icon: Icons.error_outline_rounded,
          message: error.toString(),
        ),
        data: (_) => located.isEmpty
            ? const _MapMessage(
                icon: Icons.location_off_outlined,
                message: 'Нема дефекти со зачувана локација.',
              )
            : _DefectMap(located: located),
      ),
    );
  }
}

class _DefectMap extends StatelessWidget {
  const _DefectMap({required this.located});

  final List<DefectModel> located;

  LatLng get _center {
    final sumLat = located.fold<double>(0, (sum, d) => sum + d.latitude!);
    final sumLng = located.fold<double>(0, (sum, d) => sum + d.longitude!);
    return LatLng(sumLat / located.length, sumLng / located.length);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        FlutterMap(
          options: MapOptions(
            initialCenter: _center,
            initialZoom: 12,
            minZoom: 3,
            maxZoom: 18,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.bus_defect_reporting_app',
            ),
            MarkerLayer(
              markers: located
                  .map(
                    (defect) => Marker(
                      point: LatLng(defect.latitude!, defect.longitude!),
                      width: 44,
                      height: 44,
                      alignment: Alignment.topCenter,
                      child: _DefectMarker(defect: defect),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
        Positioned(
          left: 16,
          right: 16,
          bottom: 16,
          child: _MapLegend(count: located.length),
        ),
      ],
    );
  }
}

class _DefectMarker extends StatelessWidget {
  const _DefectMarker({required this.defect});

  final DefectModel defect;

  @override
  Widget build(BuildContext context) {
    final color = defect.status.color;
    return GestureDetector(
      onTap: () => context.push(AppRoutes.defectDetails(defect.id)),
      child: Tooltip(
        message: 'Автобус #${defect.busNumber} · ${defect.type.label}',
        child: Icon(
          Icons.location_on,
          color: color,
          size: 40,
          shadows: const [Shadow(color: Colors.black45, blurRadius: 4)],
        ),
      ),
    );
  }
}

class _MapLegend extends StatelessWidget {
  const _MapLegend({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          const Icon(
            Icons.place_rounded,
            size: 18,
            color: AppColors.accent,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '$count ${count == 1 ? 'дефект' : 'дефекти'} на мапата · допрете маркер за детали',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MapMessage extends StatelessWidget {
  const _MapMessage({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: AppColors.textMuted),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
