import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/defect_history_entry.dart';
import '../models/defect_model.dart';
import '../models/defect_priority.dart';
import '../models/defect_type.dart';
import '../models/maintenance_department.dart';
import '../widgets/status_pill.dart';
import 'auth_service.dart';
import 'firebase_service.dart';

class DefectDraft {
  const DefectDraft({
    required this.userId,
    required this.userName,
    required this.busNumber,
    required this.type,
    required this.priority,
    required this.description,
    this.imageUrl,
  });

  final String userId;
  final String userName;
  final String busNumber;
  final DefectType type;
  final DefectPriority priority;
  final String description;
  final String? imageUrl;
}

class DefectRepository {
  DefectRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('defects');

  Stream<List<DefectModel>> watchDefects() {
    if (!FirebaseService.isInitialized) return Stream.value(const []);

    return _collection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(_fromSnapshot).toList());
  }

  Future<String> createDefect(DefectDraft draft) async {
    if (!FirebaseService.isInitialized) {
      throw const DefectFailure(
        'Firebase is not configured yet. Complete the setup steps in README.md.',
      );
    }

    final doc = _collection.doc();
    await doc.set(
      DefectRepository.buildCreateData(draft: draft, defectId: doc.id),
    );

    return doc.id;
  }

  @visibleForTesting
  static Map<String, dynamic> buildCreateData({
    required DefectDraft draft,
    required String defectId,
  }) {
    final history = {
      'type': HistoryChangeType.created.name,
      'description': 'Report submitted.',
      'changedByName': draft.userName,
      'changedAt': Timestamp.now(),
    };

    return {
      'id': defectId,
      'userId': draft.userId,
      'submittedById': draft.userId,
      'submittedByName': draft.userName,
      'title': '${draft.type.name} defect on bus ${draft.busNumber.trim()}',
      'description': draft.description.trim(),
      'busNumber': draft.busNumber.trim(),
      'type': draft.type.name,
      'priority': draft.priority.name,
      'department': draft.type.department.name,
      'status': DefectStatus.newReport.name,
      'imageUrl': draft.imageUrl,
      'history': [history],
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  Future<void> updateStatus({
    required String defectId,
    required DefectStatus status,
    required String changedByName,
  }) async {
    if (!FirebaseService.isInitialized) {
      throw const DefectFailure(
        'Firebase is not configured yet. Complete the setup steps in README.md.',
      );
    }

    final doc = _collection.doc(defectId);
    final snapshot = await doc.get();
    final data = snapshot.data();
    final previousStatus = _parseEnum(
      DefectStatus.values,
      data?['status'] as String?,
      DefectStatus.newReport,
    );

    await doc.update({
      'status': status.name,
      'updatedAt': FieldValue.serverTimestamp(),
      'history': FieldValue.arrayUnion([
        {
          'type': HistoryChangeType.statusChange.name,
          'description':
              'Status changed: ${previousStatus.label} -> ${status.label}.',
          'changedByName': changedByName,
          'changedAt': Timestamp.now(),
        },
      ]),
    });
  }

  DefectModel _fromSnapshot(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final type = _parseEnum(
      DefectType.values,
      data['type'] as String?,
      DefectType.other,
    );
    final createdAt = _dateFromTimestamp(data['createdAt']) ?? DateTime.now();

    return DefectModel(
      id: (data['id'] as String?) ?? doc.id,
      busNumber: (data['busNumber'] as String?) ?? '',
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
      submittedAt: createdAt,
      submittedById:
          (data['submittedById'] as String?) ??
          (data['userId'] as String?) ??
          '',
      submittedByName: (data['submittedByName'] as String?) ?? 'Transit user',
      imageUrl: data['imageUrl'] as String?,
      updatedAt: _dateFromTimestamp(data['updatedAt']),
      history: _historyFromData(data['history']),
    );
  }

  List<DefectHistoryEntry> _historyFromData(Object? value) {
    if (value is! List) return const [];

    return value.whereType<Map>().map((entry) {
      return DefectHistoryEntry(
        type: _parseEnum(
          HistoryChangeType.values,
          entry['type'] as String?,
          HistoryChangeType.created,
        ),
        description: (entry['description'] as String?) ?? '',
        changedByName: (entry['changedByName'] as String?) ?? 'Transit user',
        changedAt: _dateFromTimestamp(entry['changedAt']) ?? DateTime.now(),
      );
    }).toList();
  }

  DateTime? _dateFromTimestamp(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }

  T _parseEnum<T extends Enum>(List<T> values, String? name, T fallback) {
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
  return DefectRepository(ref.watch(firestoreProvider));
});

final defectProvider = StreamProvider<List<DefectModel>>((ref) {
  return ref.watch(defectRepositoryProvider).watchDefects();
});
