// Generated placeholder Firebase options using provided google-services.json values.
// For complete and accurate config across platforms run `flutterfire configure`.
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      default:
        throw UnsupportedError('DefaultFirebaseOptions are not supported for this platform.');
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCGS_UmJZdVBmGELTDoVDAeheIUQBPOYcA',
    appId: '1:892795517944:android:b824c95055d595eaa5340d',
    messagingSenderId: '892795517944',
    projectId: 'signature-3d376',
    storageBucket: 'signature-3d376.firebasestorage.app',
    databaseURL: 'https://signature-3d376-default-rtdb.firebaseio.com',
  );

  // Web/iOS/macos placeholders. Replace with real values from FlutterFire CLI.
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCGS_UmJZdVBmGELTDoVDAeheIUQBPOYcA',
    appId: '1:892795517944:web:REPLACE_ME',
    messagingSenderId: '892795517944',
    projectId: 'signature-3d376',
    authDomain: 'signature-3d376.firebaseapp.com',
    storageBucket: 'signature-3d376.firebasestorage.app',
    measurementId: 'G-REPLACE_ME',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'REPLACE_ME',
    appId: 'REPLACE_ME',
    messagingSenderId: '892795517944',
    projectId: 'signature-3d376',
    storageBucket: 'signature-3d376.firebasestorage.app',
    databaseURL: 'https://signature-3d376-default-rtdb.firebaseio.com',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'REPLACE_ME',
    appId: 'REPLACE_ME',
    messagingSenderId: '892795517944',
    projectId: 'signature-3d376',
    storageBucket: 'signature-3d376.firebasestorage.app',
  );
}
