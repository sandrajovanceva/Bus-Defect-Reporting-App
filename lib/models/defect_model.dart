import '../widgets/status_pill.dart';
import 'defect_history_entry.dart';
import 'defect_priority.dart';
import 'defect_type.dart';
import 'maintenance_department.dart';

class DefectModel {
  const DefectModel({
    required this.id,
    required this.busNumber,
    required this.type,
    required this.priority,
    required this.status,
    required this.description,
    required this.department,
    required this.submittedAt,
    required this.submittedById,
    required this.submittedByName,
    required this.driverName,
    this.imageBase64,
    this.latitude,
    this.longitude,
    this.updatedAt,
    this.history = const [],
  });

  final String id;
  final String busNumber;
  final DefectType type;
  final DefectPriority priority;
  final DefectStatus status;
  final String description;
  final MaintenanceDepartment department;
  final DateTime submittedAt;
  final String submittedById;
  final String submittedByName;

  /// Name of the driver the defect is about — entered by whoever files the
  /// report (usually the dispatcher, from the driver's paper card / phone
  /// call), which may be a different person than [submittedByName].
  final String driverName;
  final String? imageBase64;
  final double? latitude;
  final double? longitude;
  final DateTime? updatedAt;
  final List<DefectHistoryEntry> history;

  bool get hasLocation => latitude != null && longitude != null;

  DefectModel copyWith({
    DefectStatus? status,
    String? imageBase64,
    DateTime? updatedAt,
    List<DefectHistoryEntry>? history,
  }) {
    return DefectModel(
      id: id,
      busNumber: busNumber,
      type: type,
      priority: priority,
      status: status ?? this.status,
      description: description,
      department: department,
      submittedAt: submittedAt,
      submittedById: submittedById,
      submittedByName: submittedByName,
      driverName: driverName,
      imageBase64: imageBase64 ?? this.imageBase64,
      latitude: latitude,
      longitude: longitude,
      updatedAt: updatedAt ?? this.updatedAt,
      history: history ?? this.history,
    );
  }
}
