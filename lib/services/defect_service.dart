import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/defect_history_entry.dart';
import '../models/defect_model.dart';
import '../models/defect_priority.dart';
import '../models/defect_type.dart';
import '../models/maintenance_department.dart';
import '../widgets/status_pill.dart';
import 'api_client.dart';
import 'auth_service.dart';

class DefectDraft {
  const DefectDraft({
    required this.busNumber,
    required this.type,
    required this.priority,
    required this.description,
    this.imageBase64,
    this.latitude,
    this.longitude,
  });

  final String busNumber;
  final DefectType type;
  final DefectPriority priority;
  final String description;
  final String? imageBase64;
  final double? latitude;
  final double? longitude;
}

/// Result of a demo-data seed request.
typedef SeedResult = ({int seeded, int existing});

class DefectRepository {
  DefectRepository(this._api);

  final ApiClient _api;

  Future<List<DefectModel>> fetchDefects() async {
    final res = await _api.dio.get<List<dynamic>>('/defects');
    return (res.data ?? const [])
        .map((item) => parseDefect(item as Map<String, dynamic>))
        .toList();
  }

  Future<DefectModel> fetchDefect(String id) async {
    final res = await _api.dio.get<Map<String, dynamic>>('/defects/$id');
    return parseDefect(res.data!);
  }

  Future<String> createDefect(DefectDraft draft) async {
    final res = await _api.dio.post<Map<String, dynamic>>(
      '/defects',
      data: buildCreatePayload(draft),
    );
    return res.data!['id'] as String;
  }

  Future<void> updateStatus({
    required String defectId,
    required DefectStatus status,
  }) async {
    await _api.dio.patch<Map<String, dynamic>>(
      '/defects/$defectId/status',
      data: {'status': status.name},
    );
  }

  Future<SeedResult> seedSampleDefects() async {
    final res = await _api.dio.post<Map<String, dynamic>>('/defects/seed');
    final data = res.data ?? const {};
    return (
      seeded: (data['seeded'] as num?)?.toInt() ?? 0,
      existing: (data['existing'] as num?)?.toInt() ?? 0,
    );
  }

  static Map<String, dynamic> buildCreatePayload(DefectDraft draft) {
    return {
      'bus_number': draft.busNumber.trim(),
      'type': draft.type.name,
      'priority': draft.priority.name,
      'description': draft.description.trim(),
      'image_base64': draft.imageBase64,
      'latitude': draft.latitude,
      'longitude': draft.longitude,
    };
  }

  static DefectModel parseDefect(Map<String, dynamic> data) {
    final type = _parseEnum(
      DefectType.values,
      data['type'] as String?,
      DefectType.other,
    );

    return DefectModel(
      id: data['id'] as String,
      busNumber: (data['bus_number'] as String?) ?? '',
      type: type,
      priority: _parseEnum(
        DefectPriority.values,
        data['priority'] as String?,
        DefectPriority.medium,
      ),
      status: _parseEnum(
        DefectStatus.values,
        data['status'] as String?,
        DefectStatus.newReport,
      ),
      description: (data['description'] as String?) ?? '',
      department: _parseEnum(
        MaintenanceDepartment.values,
        data['department'] as String?,
        type.department,
      ),
      submittedAt: _parseDate(data['created_at']) ?? DateTime.now(),
      submittedById: (data['submitted_by_id'] as String?) ?? '',
      submittedByName: (data['submitted_by_name'] as String?) ?? 'Transit user',
      imageBase64: data['image_base64'] as String?,
      latitude: _toDouble(data['latitude']),
      longitude: _toDouble(data['longitude']),
      updatedAt: _parseDate(data['updated_at']),
      history: _historyFromData(data['history']),
    );
  }

  static List<DefectHistoryEntry> _historyFromData(Object? value) {
    if (value is! List) return const [];

    return value.whereType<Map>().map((entry) {
      return DefectHistoryEntry(
        type: _parseEnum(
          HistoryChangeType.values,
          entry['type'] as String?,
          HistoryChangeType.created,
        ),
        description: (entry['description'] as String?) ?? '',
        changedByName: (entry['changed_by_name'] as String?) ?? 'Transit user',
        changedAt: _parseDate(entry['changed_at']) ?? DateTime.now(),
      );
    }).toList();
  }

  static DateTime? _parseDate(Object? value) {
    if (value is String) return DateTime.tryParse(value)?.toLocal();
    return null;
  }

  static double? _toDouble(Object? value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static T _parseEnum<T extends Enum>(List<T> values, String? name, T fallback) {
    return values.firstWhere(
      (value) => value.name == name,
      orElse: () => fallback,
    );
  }
}

class DefectFailure implements Exception {
  const DefectFailure(this.message);
  final String message;
}

final defectRepositoryProvider = Provider<DefectRepository>((ref) {
  return DefectRepository(ref.watch(apiClientProvider));
});

/// Fetches defect reports for the signed-in user. The backend scopes the list
/// by role (dispatchers see all, drivers see their own). Invalidate this
/// provider after creating or updating a defect to refresh.
final defectProvider = FutureProvider<List<DefectModel>>((ref) async {
  final user = ref.watch(authProvider).value;
  if (user == null) return const <DefectModel>[];
  return ref.watch(defectRepositoryProvider).fetchDefects();
});
