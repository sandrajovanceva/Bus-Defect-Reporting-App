import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bus_defect_reporting_app/models/defect_priority.dart';
import 'package:bus_defect_reporting_app/models/defect_type.dart';
import 'package:bus_defect_reporting_app/services/defect_service.dart';
import 'package:bus_defect_reporting_app/widgets/status_pill.dart';

void main() {
  test('buildCreateData creates the Firestore defect document shape', () {
    const draft = DefectDraft(
      userId: 'user-123',
      userName: 'Test Driver',
      busNumber: ' 412 ',
      type: DefectType.brakes,
      priority: DefectPriority.high,
      description: ' Brake pedal feels soft. ',
      imageUrl: 'https://storage.example/defect.jpg',
      latitude: 41.9981,
      longitude: 21.4254,
    );

    final data = DefectRepository.buildCreateData(
      draft: draft,
      defectId: 'defect-123',
    );

    expect(data['id'], 'defect-123');
    expect(data['userId'], 'user-123');
    expect(data['submittedById'], 'user-123');
    expect(data['submittedByName'], 'Test Driver');
    expect(data['title'], 'brakes defect on bus 412');
    expect(data['description'], 'Brake pedal feels soft.');
    expect(data['busNumber'], '412');
    expect(data['type'], DefectType.brakes.name);
    expect(data['priority'], DefectPriority.high.name);
    expect(data['department'], DefectType.brakes.department.name);
    expect(data['status'], DefectStatus.newReport.name);
    expect(data['imageUrl'], 'https://storage.example/defect.jpg');
    expect(data['latitude'], 41.9981);
    expect(data['longitude'], 21.4254);
    expect(data['createdAt'], isA<FieldValue>());
    expect(data['updatedAt'], isA<FieldValue>());

    final history = data['history'] as List<Object?>;
    expect(history, hasLength(1));
    expect(history.single, isA<Map<String, Object?>>());
    expect(history.single, containsPair('description', 'Report submitted.'));
  });
}
