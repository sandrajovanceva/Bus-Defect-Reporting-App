# Bus Defect Reporting App

Flutter app for reporting bus defects and tracking maintenance follow-up.

## Firebase setup

The app uses Firebase Authentication, Cloud Firestore, and Firebase Storage. Create and connect a Firebase project outside this repository before running against live services.

1. Create a Firebase project in Firebase Console.
2. Add Android and iOS apps to the Firebase project.
3. Enable Authentication > Sign-in method > Email/Password.
4. Create a Cloud Firestore database.
5. Enable Firebase Storage.
6. Install the Firebase CLI and FlutterFire CLI if needed:

```sh
npm install -g firebase-tools
dart pub global activate flutterfire_cli
```

7. Configure the Flutter app for your Firebase project:

```sh
flutterfire configure
```

This creates local Firebase configuration such as `lib/firebase_options.dart`, `android/app/google-services.json`, and `ios/Runner/GoogleService-Info.plist`. These files are ignored by git so project-specific config stays out of the repository.

8. If `flutterfire configure` generates `DefaultFirebaseOptions`, update `lib/services/firebase_service.dart` to initialize Firebase with those options:

```dart
await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);
```

Without local Firebase config, the app still starts and shows a setup error.

## Firestore data

The app uses these collections:

- `users/{uid}`: `uid`, `email`, `displayName`, `role`, `assignedBus`, `assignedRoute`, `createdAt`, `updatedAt`
- `defects/{defectId}`: `userId`, `submittedById`, `submittedByName`, `title`, `description`, `busNumber`, `type`, `priority`, `department`, `status`, `imageUrl`, `history`, `createdAt`, `updatedAt`

User documents are created or updated after successful login. Defect reports are saved to the `defects` collection and optional images are uploaded to `defect-images/{uid}/...` in Firebase Storage.

## Security rules

Firestore and Storage rules are included:

- `firestore.rules`
- `storage.rules`
- `firebase.json`

Deploy them with:

```sh
firebase login
firebase use <your-project-id>
firebase deploy --only firestore:rules,storage
```

The rules allow users to access their own user document, allow authenticated users to create their own defect reports, and allow dispatchers to read/update reports when their `users/{uid}.role` is `dispatcher`.

## Development

```sh
flutter pub get
flutter analyze
flutter test
```
