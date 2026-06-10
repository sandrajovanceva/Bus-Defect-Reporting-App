import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/defect_history_entry.dart';
import '../models/defect_model.dart';
import '../models/defect_priority.dart';
import '../models/defect_type.dart';
import '../models/maintenance_department.dart';
import '../widgets/status_pill.dart';

DefectHistoryEntry _created(String byName, DateTime at) => DefectHistoryEntry(
      type: HistoryChangeType.created,
      description: 'Извештајот е поднесен.',
      changedByName: byName,
      changedAt: at,
    );

final _mockDefects = <DefectModel>[
  DefectModel(
    id: 'DEF-001',
    busNumber: '42',
    type: DefectType.brakes,
    priority: DefectPriority.high,
    status: DefectStatus.newReport,
    description: 'Кочниците не реагираат правилно при брзо запирање. '
        'Потребна итна проверка.',
    department: MaintenanceDepartment.mechanical,
    submittedAt: DateTime.now().subtract(const Duration(hours: 2)),
    submittedById: 'D-4827',
    submittedByName: 'Стефан Илиевски',
    history: [
      _created('Стефан Илиевски', DateTime.now().subtract(const Duration(hours: 2))),
    ],
  ),
  DefectModel(
    id: 'DEF-002',
    busNumber: '42',
    type: DefectType.electrical,
    priority: DefectPriority.medium,
    status: DefectStatus.inProgress,
    description: 'Предните светла трепкаат при возење по рамен терен.',
    department: MaintenanceDepartment.electrical,
    submittedAt: DateTime.now().subtract(const Duration(days: 1)),
    submittedById: 'D-4827',
    submittedByName: 'Стефан Илиевски',
    history: [
      _created('Стефан Илиевски', DateTime.now().subtract(const Duration(days: 1))),
      DefectHistoryEntry(
        type: HistoryChangeType.statusChange,
        description: 'Статусот е сменет: New → In Progress.',
        changedByName: 'Сандра Јованчева',
        changedAt: DateTime.now().subtract(const Duration(hours: 20)),
      ),
    ],
  ),
  DefectModel(
    id: 'DEF-003',
    busNumber: '07',
    type: DefectType.doors,
    priority: DefectPriority.low,
    status: DefectStatus.resolved,
    description: 'Задната врата не се затвора целосно автоматски.',
    department: MaintenanceDepartment.bodywork,
    submittedAt: DateTime.now().subtract(const Duration(days: 3)),
    submittedById: 'D-1193',
    submittedByName: 'Марко Петровски',
    history: [
      _created('Марко Петровски', DateTime.now().subtract(const Duration(days: 3))),
      DefectHistoryEntry(
        type: HistoryChangeType.statusChange,
        description: 'Статусот е сменет: New → In Progress.',
        changedByName: 'Сандра Јованчева',
        changedAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
      DefectHistoryEntry(
        type: HistoryChangeType.statusChange,
        description: 'Статусот е сменет: In Progress → Resolved.',
        changedByName: 'Сандра Јованчева',
        changedAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ],
  ),
  DefectModel(
    id: 'DEF-004',
    busNumber: '07',
    type: DefectType.climate,
    priority: DefectPriority.low,
    status: DefectStatus.rejected,
    description: 'Климатизацијата не работи на максимално ладење.',
    department: MaintenanceDepartment.electrical,
    submittedAt: DateTime.now().subtract(const Duration(days: 5)),
    submittedById: 'D-1193',
    submittedByName: 'Марко Петровски',
    history: [
      _created('Марко Петровски', DateTime.now().subtract(const Duration(days: 5))),
      DefectHistoryEntry(
        type: HistoryChangeType.statusChange,
        description: 'Статусот е сменет: New → Rejected.',
        changedByName: 'Сандра Јованчева',
        changedAt: DateTime.now().subtract(const Duration(days: 4)),
      ),
    ],
  ),
];

class DefectNotifier extends Notifier<List<DefectModel>> {
  @override
  List<DefectModel> build() => List.from(_mockDefects);

  void updateStatus(
    String defectId,
    DefectStatus newStatus, {
    String byName = 'Диспечер',
  }) {
    state = [
      for (final d in state)
        if (d.id == defectId)
          d.copyWith(
            status: newStatus,
            history: [
              ...d.history,
              DefectHistoryEntry(
                type: HistoryChangeType.statusChange,
                description:
                    'Статусот е сменет: ${d.status.label} → ${newStatus.label}.',
                changedByName: byName,
                changedAt: DateTime.now(),
              ),
            ],
          )
        else
          d,
    ];
  }

  List<DefectModel> byUser(String userId) =>
      state.where((d) => d.submittedById == userId).toList();
}

final defectProvider =
    NotifierProvider<DefectNotifier, List<DefectModel>>(DefectNotifier.new);
