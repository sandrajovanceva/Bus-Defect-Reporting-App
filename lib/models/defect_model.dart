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
    this.imageUrl,
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
  final String? imageUrl;
  final DateTime? updatedAt;
  final List<DefectHistoryEntry> history;

  DefectModel copyWith({
    DefectStatus? status,
    String? imageUrl,
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
      imageUrl: imageUrl ?? this.imageUrl,
      updatedAt: updatedAt ?? this.updatedAt,
      history: history ?? this.history,
    );
  }
}
