import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user_model.dart';
import '../models/user_role.dart';
import 'firebase_service.dart';

class AuthRepository {
  AuthRepository({
    required firebase_auth.FirebaseAuth auth,
    required FirebaseFirestore firestore,
  }) : _auth = auth,
       _firestore = firestore;

  final firebase_auth.FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  firebase_auth.User? get currentFirebaseUser => _auth.currentUser;

  Future<UserModel?> currentUser() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    return _syncUserDocument(user);
  }

  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    final cleanEmail = email.trim();
    firebase_auth.UserCredential credential;
    try {
      credential = await _auth.signInWithEmailAndPassword(
        email: cleanEmail,
        password: password,
      );
    } on firebase_auth.FirebaseAuthException catch (error) {
      // DEV CONVENIENCE: when the account doesn't exist yet, provision it on
      // the fly so the app can be demoed without Firebase Console access.
      // Remove this fallback (keep only the sign-in call) for production.
      if (error.code == 'user-not-found' ||
          error.code == 'invalid-credential') {
        credential = await _auth.createUserWithEmailAndPassword(
          email: cleanEmail,
          password: password,
        );
      } else {
        rethrow;
      }
    }

    final user = credential.user;
    if (user == null) {
      throw const AuthFailure('Authentication failed. Please try again.');
    }

    return _syncUserDocument(user);
  }

  Future<void> signOut() => _auth.signOut();

  Future<UserModel> _syncUserDocument(firebase_auth.User firebaseUser) async {
    final ref = _firestore.collection('users').doc(firebaseUser.uid);
    final snapshot = await ref.get();
    final data = snapshot.data() ?? <String, dynamic>{};
    final now = FieldValue.serverTimestamp();

    final displayName = firebaseUser.displayName?.trim();
    final email = firebaseUser.email?.trim();
    final fallbackName = displayName?.isNotEmpty == true
        ? displayName!
        : (email?.split('@').first ?? 'Transit user');

    // DEV CONVENIENCE: infer the role from the email for auto-provisioned
    // accounts (e.g. "dispatcher@..." becomes a dispatcher) so both roles can
    // be demoed without editing Firestore by hand. Existing docs keep their
    // stored role.
    final inferredRole = (email ?? '').toLowerCase().contains('dispatch')
        ? UserRole.dispatcher.name
        : UserRole.driver.name;
    final roleName = (data['role'] as String?) ?? inferredRole;

    await ref.set({
      'uid': firebaseUser.uid,
      'email': email,
      'displayName': data['displayName'] ?? fallbackName,
      'role': roleName,
      'assignedBus': data['assignedBus'],
      'assignedRoute': data['assignedRoute'],
      if (!snapshot.exists) 'createdAt': now,
      'updatedAt': now,
    }, SetOptions(merge: true));

    final role = UserRole.values.firstWhere(
      (value) => value.name == roleName,
      orElse: () => UserRole.driver,
    );

    return UserModel(
      id: firebaseUser.uid,
      fullName: (data['displayName'] as String?) ?? fallbackName,
      email: email,
      role: role,
      assignedBus: data['assignedBus'] as String?,
      assignedRoute: data['assignedRoute'] as String?,
    );
  }
}

class AuthFailure implements Exception {
  const AuthFailure(this.message);
  final String message;
}

class AuthNotifier extends AsyncNotifier<UserModel?> {
  AuthRepository get _repository => ref.read(authRepositoryProvider);

  @override
  Future<UserModel?> build() async {
    if (!ref.read(firebaseReadyProvider)) return null;
    return _repository.currentUser();
  }

  Future<String?> login(String email, String password) async {
    if (!ref.read(firebaseReadyProvider)) {
      return 'Firebase is not configured yet. Complete the setup steps in README.md.';
    }

    state = const AsyncLoading();
    try {
      final user = await _repository.signIn(email: email, password: password);
      state = AsyncData(user);
      return null;
    } on firebase_auth.FirebaseAuthException catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      return _mapAuthError(error);
    } on AuthFailure catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      return error.message;
    } on Object catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      return 'Unable to sign in. Please check your connection and try again.';
    }
  }

  Future<void> logout() async {
    if (ref.read(firebaseReadyProvider)) {
      await _repository.signOut();
    }
    state = const AsyncData(null);
  }

  String _mapAuthError(firebase_auth.FirebaseAuthException error) {
    switch (error.code) {
      case 'invalid-email':
        return 'Enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled. Contact dispatch.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Email or password is incorrect.';
      case 'email-already-in-use':
        return 'Email or password is incorrect.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'too-many-requests':
        return 'Too many attempts. Wait a moment and try again.';
      case 'network-request-failed':
        return 'Network error. Check your connection and try again.';
      default:
        return error.message ?? 'Unable to sign in. Please try again.';
    }
  }
}

final firebaseAuthProvider = Provider<firebase_auth.FirebaseAuth>(
  (_) => firebase_auth.FirebaseAuth.instance,
);

final firestoreProvider = Provider<FirebaseFirestore>(
  (_) => FirebaseFirestore.instance,
);

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    auth: ref.watch(firebaseAuthProvider),
    firestore: ref.watch(firestoreProvider),
  );
});

final authProvider = AsyncNotifierProvider<AuthNotifier, UserModel?>(
  AuthNotifier.new,
);
