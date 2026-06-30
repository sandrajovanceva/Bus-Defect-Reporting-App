import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/defect_history_entry.dart';
import '../models/defect_model.dart';
import '../models/defect_priority.dart';
import '../models/defect_type.dart';
import '../models/maintenance_department.dart';
import '../models/user_model.dart';
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
    this.latitude,
    this.longitude,
  });

  final String userId;
  final String userName;
  final String busNumber;
  final DefectType type;
  final DefectPriority priority;
  final String description;
  final String? imageUrl;
  final double? latitude;
  final double? longitude;
}

class DefectRepository {
  DefectRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('defects');

  /// Streams defect reports. When [submittedById] is provided (drivers), the
  /// query is scoped to that user's own reports so it satisfies the Firestore
  /// security rules; dispatchers pass null and receive every report.
  Stream<List<DefectModel>> watchDefects({String? submittedById}) {
    if (!FirebaseService.isInitialized) return Stream.value(const []);

    if (submittedById != null) {
      // Scoped query: sort client-side to avoid requiring a composite index.
      return _collection
          .where('submittedById', isEqualTo: submittedById)
          .snapshots()
          .map((snapshot) {
            final defects = snapshot.docs.map(_fromSnapshot).toList();
            defects.sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
            return defects;
          });
    }

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

  /// Number of demo reports this user has already authored, so the demo-data
  /// action can avoid creating duplicates.
  Future<int> countOwnDefects(String userId) async {
    if (!FirebaseService.isInitialized) return 0;
    final snapshot = await _collection
        .where('submittedById', isEqualTo: userId)
        .count()
        .get();
    return snapshot.count ?? 0;
  }

  /// Seeds a batch of sample defect reports (with GPS coordinates around
  /// Skopje and varied statuses) authored by [user], so the lists and map can
  /// be demoed without manual data entry. DEV CONVENIENCE — remove for
  /// production.
  Future<int> seedSampleDefects(UserModel user) async {
    if (!FirebaseService.isInitialized) {
      throw const DefectFailure(
        'Firebase is not configured yet. Complete the setup steps in README.md.',
      );
    }

    final now = DateTime.now();
    final batch = _firestore.batch();

    for (var i = 0; i < _sampleDefects.length; i++) {
      final sample = _sampleDefects[i];
      final createdAt = now.subtract(Duration(hours: sample.hoursAgo));
      final doc = _collection.doc();

      final history = <Map<String, dynamic>>[
        {
          'type': HistoryChangeType.created.name,
          'description': 'Report submitted.',
          'changedByName': user.fullName,
          'changedAt': Timestamp.fromDate(createdAt),
        },
        if (sample.status != DefectStatus.newReport)
          {
            'type': HistoryChangeType.statusChange.name,
            'description':
                'Status changed: ${DefectStatus.newReport.label} -> '
                '${sample.status.label}.',
            'changedByName': 'Диспечер',
            'changedAt': Timestamp.fromDate(
              createdAt.add(const Duration(hours: 3)),
            ),
          },
      ];

      batch.set(doc, {
        'id': doc.id,
        'userId': user.id,
        'submittedById': user.id,
        'submittedByName': user.fullName,
        'title': '${sample.type.name} defect on bus ${sample.busNumber}',
        'description': sample.description,
        'busNumber': sample.busNumber,
        'type': sample.type.name,
        'priority': sample.priority.name,
        'department': sample.type.department.name,
        'status': sample.status.name,
        'imageUrl': null,
        'latitude': sample.latitude,
        'longitude': sample.longitude,
        'history': history,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(createdAt),
      });
    }

    await batch.commit();
    return _sampleDefects.length;
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
      'latitude': draft.latitude,
      'longitude': draft.longitude,
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
      latitude: _toDouble(data['latitude']),
      longitude: _toDouble(data['longitude']),
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

  double? _toDouble(Object? value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  T _parseEnum<T extends Enum>(List<T> values, String? name, T fallback) {
    return values.firstWhere(
      (value) => value.name == name,
      orElse: () => fallback,
    );
  }
}

class _SampleDefect {
  const _SampleDefect({
    required this.busNumber,
    required this.type,
    required this.priority,
    required this.status,
    required this.description,
    required this.latitude,
    required this.longitude,
    required this.hoursAgo,
  });

  final String busNumber;
  final DefectType type;
  final DefectPriority priority;
  final DefectStatus status;
  final String description;
  final double latitude;
  final double longitude;
  final int hoursAgo;
}

/// Demo reports positioned around Skopje so the lists and map have content.
const List<_SampleDefect> _sampleDefects = [
  _SampleDefect(
    busNumber: '412',
    type: DefectType.brakes,
    priority: DefectPriority.high,
    status: DefectStatus.inProgress,
    description: 'Кочниците реагираат бавно при сопирање на низок брзина.',
    latitude: 41.9965,
    longitude: 21.4314,
    hoursAgo: 30,
  ),
  _SampleDefect(
    busNumber: '305',
    type: DefectType.electrical,
    priority: DefectPriority.medium,
    status: DefectStatus.newReport,
    description: 'Контролната табла трепка повремено додека возилото работи.',
    latitude: 42.0041,
    longitude: 21.4090,
    hoursAgo: 4,
  ),
  _SampleDefect(
    busNumber: '118',
    type: DefectType.doors,
    priority: DefectPriority.low,
    status: DefectStatus.resolved,
    description: 'Задната врата не се затвора целосно од прв обид.',
    latitude: 41.9890,
    longitude: 21.4450,
    hoursAgo: 120,
  ),
  _SampleDefect(
    busNumber: '720',
    type: DefectType.mechanical,
    priority: DefectPriority.high,
    status: DefectStatus.inProgress,
    description: 'Чудни звуци од моторот при забрзување над 40 km/h.',
    latitude: 42.0102,
    longitude: 21.4201,
    hoursAgo: 52,
  ),
  _SampleDefect(
    busNumber: '233',
    type: DefectType.lights,
    priority: DefectPriority.medium,
    status: DefectStatus.newReport,
    description: 'Предните светла се значително послаби од нормално.',
    latitude: 41.9920,
    longitude: 21.4015,
    hoursAgo: 70,
  ),
  _SampleDefect(
    busNumber: '540',
    type: DefectType.climate,
    priority: DefectPriority.low,
    status: DefectStatus.rejected,
    description: 'Греењето не работи во задниот дел од автобусот.',
    latitude: 41.9788,
    longitude: 21.4377,
    hoursAgo: 168,
  ),
  _SampleDefect(
    busNumber: '401',
    type: DefectType.bodywork,
    priority: DefectPriority.low,
    status: DefectStatus.newReport,
    description: 'Оштетена надворешна страница веднаш до предниот влез.',
    latitude: 42.0008,
    longitude: 21.4502,
    hoursAgo: 26,
  ),
  _SampleDefect(
    busNumber: '612',
    type: DefectType.other,
    priority: DefectPriority.medium,
    status: DefectStatus.inProgress,
    description: 'Седиштето кај излезот во средината е расклатено.',
    latitude: 41.9850,
    longitude: 21.4150,
    hoursAgo: 90,
  ),
];

class DefectFailure implements Exception {
  const DefectFailure(this.message);
  final String message;
}

final defectRepositoryProvider = Provider<DefectRepository>((ref) {
  return DefectRepository(ref.watch(firestoreProvider));
});

final defectProvider = StreamProvider<List<DefectModel>>((ref) {
  final user = ref.watch(authProvider).value;
  if (user == null) return Stream.value(const <DefectModel>[]);

  // Dispatchers read every report; drivers are scoped to their own so the
  // query passes the Firestore security rules.
  final submittedById = user.role.isDispatcher ? null : user.id;
  return ref
      .watch(defectRepositoryProvider)
      .watchDefects(submittedById: submittedById);
});
