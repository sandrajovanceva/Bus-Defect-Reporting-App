enum HistoryChangeType { created, statusChange, priorityChange, departmentChange }

class DefectHistoryEntry {
  const DefectHistoryEntry({
    required this.type,
    required this.description,
    required this.changedByName,
    required this.changedAt,
  });

  final HistoryChangeType type;
  final String description;
  final String changedByName;
  final DateTime changedAt;
}
