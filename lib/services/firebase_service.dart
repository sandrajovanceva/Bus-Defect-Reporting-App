import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FirebaseService {
  const FirebaseService._();

  static bool _isInitialized = false;
  static Object? _initializationError;

  static bool get isInitialized => _isInitialized;
  static Object? get initializationError => _initializationError;

  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }
      _isInitialized = true;
      _initializationError = null;
    } on Object catch (error) {
      _isInitialized = false;
      _initializationError = error;
    }
  }
}

final firebaseReadyProvider = Provider<bool>(
  (_) => FirebaseService.isInitialized,
);

final firebaseInitializationErrorProvider = Provider<Object?>(
  (_) => FirebaseService.initializationError,
);
