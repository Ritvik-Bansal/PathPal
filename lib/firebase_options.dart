// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
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
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static FirebaseOptions web = FirebaseOptions(
    apiKey: '${dotenv.env["FIREBASEWEB"]}',
    appId: '1:742216978719:web:18990b68ca27eac2d7202a',
    messagingSenderId: '742216978719',
    projectId: 'pathpal-d5503',
    authDomain: 'pathpal-d5503.firebaseapp.com',
    storageBucket: 'pathpal-d5503.appspot.com',
    measurementId: 'G-1SXEP8PW7R',
  );

  static FirebaseOptions android = FirebaseOptions(
    apiKey: '${dotenv.env["FIREBASEANDROID"]}',
    appId: '1:742216978719:android:b62b7f39c27cd864d7202a',
    messagingSenderId: '742216978719',
    projectId: 'pathpal-d5503',
    storageBucket: 'pathpal-d5503.appspot.com',
  );

  static FirebaseOptions ios = FirebaseOptions(
    apiKey: '${dotenv.env["FIREBASEIOS"]}',
    appId: '1:742216978719:ios:ca616d647631a15dd7202a',
    messagingSenderId: '742216978719',
    projectId: 'pathpal-d5503',
    storageBucket: 'pathpal-d5503.appspot.com',
    androidClientId:
        '742216978719-10gfiii6otqrekls515oc70l35a8bqee.apps.googleusercontent.com',
    iosClientId:
        '742216978719-q8m6e20462u25sosmi4ik2t9jfhtaiip.apps.googleusercontent.com',
    iosBundleId: 'com.example.pathpal',
  );

  static FirebaseOptions macos = FirebaseOptions(
    apiKey: '${dotenv.env["FIREBASEMACOS"]}',
    appId: '1:742216978719:ios:ca616d647631a15dd7202a',
    messagingSenderId: '742216978719',
    projectId: 'pathpal-d5503',
    storageBucket: 'pathpal-d5503.appspot.com',
    iosBundleId: 'com.example.pathpal',
  );

  static FirebaseOptions windows = FirebaseOptions(
    apiKey: '${dotenv.env["FIREBASEWINDOWS"]}',
    appId: '1:742216978719:web:7476def881986a65d7202a',
    messagingSenderId: '742216978719',
    projectId: 'pathpal-d5503',
    authDomain: 'pathpal-d5503.firebaseapp.com',
    storageBucket: 'pathpal-d5503.appspot.com',
    measurementId: 'G-4XG67RVD8R',
  );
}
