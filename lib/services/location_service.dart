import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

/// A captured geographic coordinate for a defect report.
class DefectLocation {
  const DefectLocation({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;
}

class LocationService {
  const LocationService();

  /// Resolves the device's current position, requesting permission and
  /// surfacing a [LocationFailure] with a user-facing message when it cannot.
  Future<DefectLocation> getCurrentLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const LocationFailure(
        'Локациските услуги се исклучени. Вклучете ги и обидете се повторно.',
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw const LocationFailure(
        'Пристапот до локацијата е одбиен.',
      );
    }

    if (permission == LocationPermission.deniedForever) {
      throw const LocationFailure(
        'Пристапот до локацијата е трајно одбиен. Овозможете го од подесувањата.',
      );
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );

    return DefectLocation(
      latitude: position.latitude,
      longitude: position.longitude,
    );
  }
}

class LocationFailure implements Exception {
  const LocationFailure(this.message);
  final String message;
}

final locationServiceProvider = Provider<LocationService>(
  (_) => const LocationService(),
);
