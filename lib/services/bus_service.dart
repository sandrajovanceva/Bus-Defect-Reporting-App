import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api_client.dart';

/// The JSP depot (автобаза) a bus is kept at. Wire names are the API's.
enum BusDepot {
  avtokomanda('avtokomanda'),
  gjorchePetrov('gjorche_petrov');

  const BusDepot(this.wireName);

  final String wireName;
}

/// A bus in the fleet registry.
///
/// A defect can only be filed against one of these — the backend rejects any
/// other number, which is what stops "22", "22 " and "бус 22" becoming three
/// different buses.
class BusModel {
  const BusModel({
    required this.id,
    required this.number,
    required this.depot,
    required this.isActive,
    this.notes,
  });

  final String id;
  /// Garage number (гаражен број) — the vehicle, not the line it runs.
  final String number;
  final BusDepot? depot;
  final bool isActive;
  final String? notes;

  static BusModel fromJson(Map<String, dynamic> json) {
    final depotName = json['depot'] as String?;
    return BusModel(
      id: json['id'] as String,
      number: (json['number'] as String?) ?? '',
      depot: BusDepot.values
          .where((value) => value.wireName == depotName)
          .firstOrNull,
      isActive: (json['is_active'] as bool?) ?? true,
      notes: json['notes'] as String?,
    );
  }
}

class BusRepository {
  BusRepository(this._api);

  final ApiClient _api;

  /// Buses in service. Retired ones are excluded: a driver must not be able
  /// to file against a bus that is off the road.
  Future<List<BusModel>> fetchBuses() async {
    final res = await _api.dio.get<List<dynamic>>('/buses');
    return (res.data ?? const [])
        .map((item) => BusModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}

final busRepositoryProvider = Provider<BusRepository>((ref) {
  return BusRepository(ref.watch(apiClientProvider));
});

/// The fleet list. Fetched once and kept, since it changes when a bus is
/// bought or retired rather than during a shift.
final busesProvider = FutureProvider<List<BusModel>>((ref) async {
  return ref.watch(busRepositoryProvider).fetchBuses();
});
