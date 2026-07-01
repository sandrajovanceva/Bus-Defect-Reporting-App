import 'package:flutter_test/flutter_test.dart';

import 'package:bus_defect_reporting_app/models/defect_priority.dart';
import 'package:bus_defect_reporting_app/models/defect_type.dart';
import 'package:bus_defect_reporting_app/services/defect_service.dart';
import 'package:bus_defect_reporting_app/widgets/status_pill.dart';

void main() {
  test('buildCreatePayload maps a draft to the API request body', () {
    const draft = DefectDraft(
      busNumber: ' 412 ',
      type: DefectType.brakes,
      priority: DefectPriority.high,
      description: ' Brake pedal feels soft. ',
      imageBase64: 'abc123',
      latitude: 41.9981,
      longitude: 21.4254,
    );

    final payload = DefectRepository.buildCreatePayload(draft);

    expect(payload['bus_number'], '412');
    expect(payload['type'], DefectType.brakes.name);
    expect(payload['priority'], DefectPriority.high.name);
    expect(payload['description'], 'Brake pedal feels soft.');
    expect(payload['image_base64'], 'abc123');
    expect(payload['latitude'], 41.9981);
    expect(payload['longitude'], 21.4254);
  });

  test('parseDefect builds a model from the API response', () {
    final defect = DefectRepository.parseDefect({
      'id': 'D-ABC123',
      'bus_number': '412',
      'type': 'brakes',
      'priority': 'high',
      'status': 'inProgress',
      'description': 'Brake pedal feels soft.',
      'department': 'mechanical',
      'submitted_by_id': 'user-123',
      'submitted_by_name': 'Test Driver',
      'latitude': 41.9981,
      'longitude': 21.4254,
      'created_at': '2026-07-01T10:00:00',
      'updated_at': '2026-07-01T10:00:00',
      'history': [
        {
          'type': 'created',
          'description': 'Report submitted.',
          'changed_by_name': 'Test Driver',
          'changed_at': '2026-07-01T10:00:00',
        },
      ],
    });

    expect(defect.id, 'D-ABC123');
    expect(defect.busNumber, '412');
    expect(defect.type, DefectType.brakes);
    expect(defect.priority, DefectPriority.high);
    expect(defect.status, DefectStatus.inProgress);
    expect(defect.submittedById, 'user-123');
    expect(defect.submittedByName, 'Test Driver');
    expect(defect.hasLocation, isTrue);
    expect(defect.latitude, 41.9981);
    expect(defect.history, hasLength(1));
    expect(defect.history.single.description, 'Report submitted.');
  });
}
